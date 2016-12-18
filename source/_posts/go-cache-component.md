---
title: "go实现缓存组件"
date: 2016-12-17 11:32:51
categories: [golang]
tags: [cache]
description:
---

## 前言
总结用golang从分析，设计到实现一个可用的缓存组件。
<!--more-->

## 缓存
- 为什么要设计缓存
	电脑的内存是以系统总线的时钟频率工作的，这个频率通常也就是CPU的外频(对于雷鸟、毒龙系列的处理器，由于在设计采用了DDR技术，CPU工作的外频为系统总线频率的两倍)。但是，CPU的工作频率(主频)是外频与倍频因子的乘积。这样一来，内存的工作频率就远低于CPU的工作频率了,造成的直接结果是：CPU在执行完一条指令后，常常需要"等待"一些时间才能再次访问内存，极大降了CPU工作效率。在这样一种情况下，Cache就应运而生,Cache是一种特殊的存储器，它由Cache 存储部件和Cache控制部件组成。Cache 存储部件一般采用与CPU同类型的半导体存储器件，存取速度比内存快几倍甚至十几倍。
	缓存(Cache)在计算机硬件中普遍存在。比如在CPU中就有一级缓存，二级缓存，甚至三级缓存。缓存的工作原理一般是CPU需要读取数据时，会首先从缓存中查找需要的数据，如果找到了就直接进行处理，如果没有找到则从内存中读取数据。缓存不仅仅存在于硬件中，在各种软件系统中也处处可见。比如在Web系统中，缓存存在于服务器端，客户端或者代理服务器中。广泛使用的CDN网络，也可以看作一个巨大的缓存系统。缓存在Web系统中的使用有很多好处，不仅可以减少网络流量，降低客户访问延迟，还可以减轻服务器负载。

-  缓存如何工作
	单颗CPU运行程序是一条指令一条指令地执行的，而且指令地址往往是连续的，意思就是说CPU在访问内存时，在较短的一段时间内往往集中于某个局部，这时候可能会碰到一些需要反复调用的子程序。电脑在工作时，把这些活跃的子程序存入比内存快得多的Cache中。CPU在访问内存时，首先判断所要访问的内容是否在Cache中，如果在，就称为`命中`，此时CPU直接从Cache中调用该内容；否则，就称为`不命中`，CPU只好去内存中调用所需的子程序或指令了。CPU不但可以直接从Cache中读出内容，也可以直接往其中写入内容。由于Cache的存取速率相当快，使得CPU的利用率大大提高，进而使整个系统的性能得以提升。
	CPU通过地址映射Cache和主存关联起来，从而确定将要访问的主存的内容是否在缓存中，所谓映象问题是指如何确定Cache中的内容是主存中的哪一部分的拷贝，即必须应用某种函数把主存地址映象到Cache中定位，也称地址映象。当信息按这种方式装入Cache中后，执行程序时，应将主存地址变换为Cache地址，这个变换过程叫作地址变换。
   -  地址映象方式通常采用`直接映象`、`全相联映象`、`组相联映象`三种
		1. `直接映像`
		   是指每个主存页只能复制到某一固定的Cache页中。直接映像的规律是：将主存的2048页分为128组，每组有16页，分别与Cache的16页直接对应，即主存的第0页、第16页、第32页……只能映像到Cache的第0页。
		2. `全相联映像`
		   全相联映像是指主存的每一页可以映像可以映像到Cache的任意一页。
		3. `组相联映像`
		   组相联映像是直接映像与全相联映像的折中方案，它将Cache分为若干组，如8组；每组若干页，如2页；同时将主存分为若干组，如255组；每组内的页数与Cache的组数相同，如8页。组相联映像的规律是主存中的各页与Cache的组号有固定的映像关系，但可自由映像到对应的Cache组中的任意一页。即组间采用直接映像，而组内的页为全相联映像。

- 缓存更新机制
	当CPU访问Cache未命中时，应从主存中读取信息，同时写入Cache。若Cache未满，则直接写入；若Cache已满，则需要进行替换。替换机构由硬件组成，并按替换算法进行设计，其作用是指出替换的页号。常用的替换算法有`先进先出算法(FIFO)`和`近期最少使用算法(LRU)`。

- 缓存读/写操作
1. `读操作`
访存时，将主存地址同时送主存和Cache，一则启动对主存的读操作，二则在Cache中按映像方式从中获取Cache地址，并将主存标记与Cache标记比较：若相同，则访问命中，从Cache中读取数据。因为Cache速度比主存速度快，所以不等主存读操作结束，即可继续下一次访存操作；若不相同，则访问未命中，则从主存中读取数据，并考虑是否按某种替换算法更新Cache某页的内容。
2. `写操作`
	将数据写入主存有两种方法，`写回法`和`写直达法`。
	`写回法`: 信息暂时只写入Cache，并用标志加以注明，直到该页内容需从Cache中替换出来时，才一次写入主存。优点是操作速度快，缺点是写回主存前，主存中没有这些内容，与Cache不一致，易造成错误。
	`写直达法`: 信息在写入Cahce时也同时写入主存。优点是主存与Cache始终保持一致，但速度慢。

目前已经存在很多高性能的缓存系统，比如Memcache，Redis等，尤其是Redis，现已经广泛用于各种Web服务中。既然有了这些功能完善的缓存系统，那为什么我们还需要自己实现一个缓存系统呢？这么做主要有两个原因，第一，通过动手实现我们可以了解缓存系统的工作原理，这也是老掉牙的理由了。第二，Redis 之类的缓存系统都是独立存在的，如果只是开发一个简单的应用还需要单独使用Redis服务器，难免会过于复杂。这时候如果有一个功能完善的软件包实现了这些功能，只需要引入这个软件包就能实现缓存功能，而不需要单独使用 Redis 服务器，就最好不过了。

## 缓存组件设计

- 缓存系统中，缓存的数据一般都存储在内存中，所以我们设计的缓存系统要以某一种方式管理内存中的数据。既然缓存数据是存储在内存中的，那如果系统停机，那数据岂不就丢失了吗？其实一般情况下，缓存系统还支持将内存中的数据写入到文件中，在系统再次启动时，再将文件中的数据加载到内存中，这样一来就算系统停机，缓存数据也不会丢失。

- 同时缓存系统还提供过期数据清理机制，也就是说缓存的数据项是有生存时间的，如果数据项过期，则数据项会从内存中被删除，这样一来热数据会一直存在，而冷数据则会被删除，也没有必要进行缓存。

- 缓存系统还需要对外提供操作的接口，这样系统的其他组件才能使用缓存。一般情况下，缓存系统需要支持`CRUD操作`，即创建(添加)，读取，更新和删除操作。

  通过以上分析，可以总结出缓存系统需要有以下功能：
  1. 缓存数据的存储;
  2. 过期数据项管理;
  3. 内存数据导出/导入;
  4. 提供CRUD接口. 

## 缓存组件实现

缓存数据需要存储在内存中，这样才可以被快速访问。那使用什么数据结构来存储数据项呢？一般情况下，我们使用哈希表来存储数据项，这样访问数据项将获得更好的性能。在golang语言中内建类型map已经实现了哈希表，所以可以直接将缓存数据项存储在map中。同时由于缓存系统需要支持过期数据清理，所以缓存数据项应该带有生存时间，这说明需要将缓存数据进行封装后，保存到缓存系统中。这样我们就需要先实现缓存数据项，其实现的代码如下：

```golang
type Item struct {
    Object     interface{} // 真正的数据项
    Expiration int64       // 生存时间
}

// 判断数据项是否已经过期
func (item Item) Expired() bool {
    if item.Expiration == 0 {
	   return false
    }
    return time.Now().UnixNano() > item.Expiration
}
```

- 在`Item`结构中， 
	- `Object`: 用于存储任意类型的数据对象;
	- `Expiration`: 字段则存储了该数据项的过期时间;
	- `Expired()`方法: 用于检测当前缓存数据项是否过期，返回`false`表示过期, 其中数据项的过期时间，是`Unix时间戳`，单位是纳秒; 用`time`包实现一个`ticker`定期检查每一项数据项，如果发现数据项的过期时间小于当前时间，则调用删除方法将数据项从缓存系统中删除.

现在来设计实现缓存组件的结构， 代码如下:
```golang 
const (
    // 没有过期时间标志
    NoExpiration time.Duration = -1

    // 默认的过期时间
    DefaultExpiration time.Duration = 0
)

type Cache struct {
    defaultExpiration time.Duration
    items             map[string]Item // 缓存数据项存储在 map 中
    mu                sync.RWMutex    // 读写锁
    gcInterval        time.Duration   // 过期数据项清理周期
    stopGc            chan bool
}

// 过期缓存数据项清理
func (c *Cache) gcLoop() {
    ticker := time.NewTicker(c.gcInterval)
    for {
        select {
        case <-ticker.C:
            c.DeleteExpired()
        case <-c.stopGc:
            ticker.Stop()
            return
        }
    }
}

/ 删除缓存数据项
func (c *Cache) del(k string) {
    delete(c.items, k)
}

// 删除过期数据项
func (c *Cache) DeleteExpired() {
    now := time.Now().UnixNano()
    c.mu.Lock()
    defer c.mu.Unlock()

    for k, v := range c.items {
        if v.Expiration > 0 && now > v.Expiration {
            c.del(k)
        }
    }
}
```
-  缓存组件结构`Cache`，
	- `NoExpiration`: 表示数据项永远不过期;
	- `DefaultExpiration`: 后者表示数据项默认过期时间;
	- `items`: 是一个`map`，用于存储缓存数据项;
	- `mu`: 读写锁， 为保证缓存读写数据一致性，在相应操作前应加锁;
	- `gcInterval`: 表示隔多久清理一次过期缓存数据;
	- `gcLoop()方法`: 该方通过time.Ticker 定期执行`DeleteExpired()`方法，从而清理过期的数据项;通过监听c.stopGc通道，在必要的时候安全结束`gcLoop()`; 

通过实现`Set`和`Add`方法向缓存系统中添加数据， 通过实现`Get`方法获取缓存数据,实现如下:
```golang 
// 设置缓存数据项，如果数据项存在则覆盖
func (c *Cache) Set(k string, v interface{}, d time.Duration) {
	//已省略添加过期时间逻辑
    c.mu.Lock()
    defer c.mu.Unlock()
    c.items[k] = Item{
        Object:     v,
        Expiration: e,
    }
}

// 设置数据项, 没有锁操作
func (c *Cache) set(k string, v interface{}, d time.Duration) {
	// to-do    
}

// 获取数据项，如果找到数据项，还需要判断数据项是否已经过期
func (c *Cache) get(k string) (interface{}, bool) {
	// to-do
}

// 添加数据项，如果数据项已经存在，则返回错误
func (c *Cache) Add(k string, v interface{}, d time.Duration) error {
	// to-do
}

// 获取数据项
func (c *Cache) Get(k string) (interface{}, bool) {
	// to-do
}
```

- Set()与Add()的主要区别在于Set()方法将数据添加到缓存系统中时，如果数据项已经存在则会覆盖，而后者如果发现数据项已经存在则会发生报错，这样能避免缓存被错误的覆盖;
- 通过Set(), Add()和Get()来写入/读取缓存数据时，应注意加锁保证数据操作的一致性。

除了向缓存系统中写入/读取缓存数据以外，还需要实现更新和删除缓存数据， 实现如下:
```golang 
// 替换一个存在的数据项
func (c *Cache) Replace(k string, v interface{}, d time.Duration) error {
    c.mu.Lock()
    _, found := c.get(k)
    if !found {
        c.mu.Unlock()
        return fmt.Errorf("Item %s doesn't exist", k)
    }
    c.set(k, v, d)
    c.mu.Unlock()
    return nil
}

// 删除一个数据项
func (c *Cache) Delete(k string) {
    c.mu.Lock()
    c.del(k)
    c.mu.Unlock()
}
```

为了是缓存数据在重启程序或系统后依然存在，则应将缓存数据持久化处理，本文方案提供将缓存数据写入本地文件的持久化操作，具体实现如下:
```golang 
// 将缓存数据项写入到 io.Writer 中
func (c *Cache) Save(w io.Writer) (err error) {
    enc := gob.NewEncoder(w)
    defer func() {
        if x := recover(); x != nil {
            err = fmt.Errorf("Error registering item types with Gob library")
        }
    }()
    c.mu.RLock()
    defer c.mu.RUnlock()
    for _, v := range c.items {
        gob.Register(v.Object)
    }
    err = enc.Encode(&c.items)
    return
}

// 保存数据项到文件中
func (c *Cache) SaveToFile(file string) error {
    f, err := os.Create(file)
    if err != nil {
        return err
    }
    if err = c.Save(f); err != nil {
        f.Close()
        return err
    }
    return f.Close()
}

// 从 io.Reader 中读取数据项
func (c *Cache) Load(r io.Reader) error {
    dec := gob.NewDecoder(r)
    items := map[string]Item{}
    err := dec.Decode(&items)
    if err == nil {
        c.mu.Lock()
        defer c.mu.Unlock()
        for k, v := range items {
            ov, found := c.items[k]
            if !found || ov.Expired() {
                c.items[k] = v
            }
        }
    }
    return err
}

// 从文件中加载缓存数据项
func (c *Cache) LoadFile(file string) error {
    f, err := os.Open(file)
    if err != nil {
        return err
    }
    if err = c.Load(f); err != nil {
        f.Close()
        return err
    }
    return f.Close()
}
```

- `Save()`通过`gob`模块将二进制缓存数据转码写入到实现了io.Writer 接口的对象中;
- `Load()`则从`io.Reader`中读取二进制数据，然后通过`gob`模块将数据进行反序列化;
- `SaveToFile`和`LoadFile`则向指定的文件中写入和读取缓存数据.


至此整个缓存系统基本实现，支持数据对象添加，删除，替换，和查询操作，同时还支持过期数据的删除。
[github-完整代码示例]()
