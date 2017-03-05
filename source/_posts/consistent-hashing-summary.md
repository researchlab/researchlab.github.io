---
title: "一致性哈希算法总结" 
date: 2017-01-16 11:02:50
categories: [algorithm]
tags: [golang]
description:
---

## 前言

存在一种场景, 当一个缓存服务由多个服务器组共同提供时, key应该路由到哪一个服务。这里假如采用最通用的方式取模求余: `key%N`(N为服务器数目), 这样做均衡性没有什么问题, 但是当服务器数目发送增加或减少时, 分配方式则变为`key%(N+1)`或`key%(N-1)`。这里将会有大量的key失效迁移, 如果后端key对应的是有状态的存储数据,那么毫无疑问,这种做法将导致服务器间大量的数据迁移,从而造成服务的不稳定。解决思路，采用一致性哈希方法可以解决此问题。 

<!--more-->

## 算法原理

一致性哈希算法在1997年由麻省理工学院提出的一种分布式哈希(DHT)实现算法，设计目标是为了解决因特网中的热点(Hot spot)问题，初衷和CARP十分类似。一致性哈希修正了CARP使用的简 单哈希算法带来的问题，使得分布式哈希(DHT)可以在P2P环境中真正得到应用。 

一致性hash算法提出了在动态变化的Cache环境中，判定哈希算法好坏的四个定义:

1.`平衡性(Balance)`: 平衡性是指哈希的结果能够尽可能分布到所有的缓冲中去，这样可以使得所有的缓冲空间都得到利用。很多哈希算法都能够满足这一条件。

2.`单调性(Monotonicity)`: 单调性是指如果已经有一些内容通过哈希分派到了相应的缓冲中，又有新的缓冲加入到系统中。哈希的结果应能够保证原有已分配的内容可以被映射到原有的或者新的缓冲中去，而不会被映射到旧的缓冲集合中的其他缓冲区。 

3.`分散性(Spread)`: 在分布式环境中，终端有可能看不到所有的缓冲，而是只能看到其中的一部分。当终端希望通过哈希过程将内容映射到缓冲上时，由于不同终端所见的缓冲范围有可能不同，从而导致哈希的结果不一致，最终的结果是相同的内容被不同的终端映射到不同的缓冲区中。这种情况显然是应该避免的，因为它导致相同内容被存储到不同缓冲中去，降低了系统存储的效率。分散性的定义就是上述情况发生的严重程度。好的哈希算法应能够尽量避免不一致的情况发生，也就是尽量降低分散性。 

4.`负载(Load)`: 负载问题实际上是从另一个角度看待分散性问题。既然不同的终端可能将相同的内容映射到不同的缓冲区中，那么对于一个特定的缓冲区而言，也可能被不同的用户映射为不同 的内容。与分散性一样，这种情况也是应当避免的，因此好的哈希算法应能够尽量降低缓冲的负荷。

在分布式集群中，对机器的添加删除，或者机器故障后自动脱离集群这些操作是分布式集群管理最基本的功能。如果采用常用的hash(object)%N算法，那么在有机器添加或者删除后，很多原有的数据就无法找到了，这样严重的违反了单调性原则。在移除/添加一个cache时，利用一致性哈希算法能够尽可能小的改变已存在key映射关系，尽可能的满足单调性的要求。

下面就来按照5个步骤简单讲讲 consistent hashing 算法的基本原理:

** 1 环形hash空间 **

考虑通常的hash算法都是将value映射到一个32位的key值, 也即是0~2^32-1次方的数值空间上; 可以将这个空间想象成一个首(0)尾(2^32-1)相接的圆环, 如图1所示,

<center>![hash ring](imgs/hashring.jpg)图1 环形hash空间</center>

** 2 把对象映射到hash空间 **

接下来考虑4个对象object1~object4，通过hash函数计算出的hash值key在环上的分布如图2所示,

hash(object1) = key1;
… …
hash(object4) = key4;

<center>![hash ring](imgs/object.jpg)图2 4个对象的key值分布</center>

** 3 把cache server映射到hash空间 **

一致性哈希算法的基本思想就是将对象和cache server都映射到同一个hash数值空间中，并且使用相同的hash算法。

假设当前有A, B和C共3台cache server，那么其映射结果将如图3所示，他们在hash空间中，以对应的hash值排列(一般采用升序，好便于后继将对象映射到相应的cache server上)。

hash(cache A) = key A;
… …
hash(cache C) = key C;

<center>![hash ring](imgs/cache.jpg)图3 cache server 和对象的key值分布</center>

<font color=red>通常cache server的hash计算, 是用cache机器的IP地址或机器名作为hash输入, 后继的实现案例中利用了cache server的IP地址作为参数因子。</font>

** 4 把对象映射到cache server上 **

现在cache server和对象都已经通过同一个hash算法映射到hash数值空间中了，接下来要考虑的就是如何将对象映射到cache server上面了。
在这个环形空间中，如果沿着顺时针方向从对象的key值出发，直到遇见一个cache server，那么就将该对象存储在这个cache server上，因为对象和cache server的hash值是固定的，因此这个cache server必然是唯一和确定的。这样不就找到了对象和cache server的映射方法了吗?! (程序实现时可以对hash环进行升序排序， 然后按顺时针从对象的key值出发，找到与这个key相邻的第一个大于key值的cache server hash值，则将这个key值映射到这个cache server上)

依然继续上面的例子(参见图3)，那么根据上面的方法，对象object1将被存储到cache server A上; object2和 object3 对应到 cache  server C; object4 对应到 cache server B; 

** 5 考察cache server的变动 **
前面讲过，通过hash求余的方法带来的最大问题就在于不能满足单调性，当cache server有所变动时，存储在原位置上的cache数据失效了，就需要做相应的迁移, 进而对后台服务器造成巨大的冲击，现在就来分析一致性哈希算法,

5.1 移除cache server 

假设cache server B 挂掉了, 根据上面讲到的映射方法，这时受影响的将仅是那些沿cache server B 逆时针遍历直到下一个cache server (cache server A)之间的对象，也即是本来映射到cache  server B上的那些对象。

因此这里仅需要变动对象object4，将其重新映射到cache server C上即可; 参见图4。

<center>![hash ring](imgs/remove.jpg)图4 Cache server B被移除后的cache server映射</center>

5.2 添加cache server

再考虑添加一台新的cache server D的情况，假设在这个环形hash空间中，cache server D被映射在对象object2和object3之间。这时受影响的将仅是那些沿cache server D逆时针遍历直到下一个cache server (cache server B)之间的对象(它们是也本来映射到cache server C上对象的一部分)，将这些对象重新映射到cache server D上即可。因此这里仅需要变动对象object2, 将其重新映射到cache server D上; 参见图5。

<center>![hash ring](imgs/add.jpg)图5 添加cache server D后的映射关系</center>

** 6 虚拟节点 **

考量Hash算法的另一个指标是`平衡性(Balance)`，定义如下:
** 平衡性 ** 是指哈希的结果能够尽可能分布到所有的缓冲中去，这样可以使得所有的缓冲空间都得到利用, hash算法并不是保证绝对的平衡，如果cache server较少的话，对象并不能被均匀的映射到cache server上，比如在上面的例子中，仅部署cache server A 和 cache server C的情况下，在4个对象中，cache server A仅存储了object1，而cache server C则存储了object2, object3和object4; 分布是很不均衡的。

为了解决这种情况, 一致性哈希引入了"虚拟节点"的概念, 它可以如下定义:

<font color=red>"虚拟节点"(virtual node)是实际节点在hash空间的复制品(replica)，一实际个节点对应了若干个"虚拟节点"，这个对应个数也成为"复制个数"，"虚拟节点"在hash空间中以hash值排列。</font>

仍以仅部署cache server A 和cache server C 的情况为例, 在图4中我们已经看到, cache server分布并不均匀。现在我们引入虚拟节点，并设置"复制个数"为2，这就意味着一共会存在4个"虚拟节点", cache server A1, cache server A2代表了cache server A; cache server C1, cache server C2代表了cache server C; 假设一种比较理想的情况，参见图6,

<center>![hash ring](imgs/virtual.jpg)图6 引入"虚拟节点"后的映射关系</center>

此时, 对象到"虚拟节点"的映射关系为:

objec1->cache A2; objec2->cache A1; objec3->cache C1; objec4->cache C2; 

因此对象object1和object2都被映射到了cache server A上，而object3和object4映射到了cache server C上; 平衡性有了很大提高。

引入"虚拟节点"后, 映射关系就从`{对象->节点}`转换到了`{对象->虚拟节点}`。查询物体所在cache server时的映射关系如图7所示,

<center>![object to virtual node](imgs/map.jpg)图7 查询对象所在cache server</center>

"虚拟节点"的hash计算可以采用对应节点的IP地址加数字后缀的方式。例如假设cache server A 的IP地址为202.168.14.241。

引入"虚拟节点"前，计算cache server A的hash值:

Hash("202.168.14.241");

引入"虚拟节点"后，计算"虚拟节点"cache server A1和cache server A2的hash值:

Hash("202.168.14.241-1-1");  // cache server A1 [Hash(server_IP-virtual_node_id-physical-node-id)]

Hash("202.168.14.241-2-1");  // cache server A2 [Hash(server_IP-virtual_node_id-physical-node-id)]

## 算法实现

上面详细讲述了一致性哈希算法的原理，下面通过golang语言来实现一致性哈希算法，具体实现思想: 
1.通过一致性哈希函数将这些cache server映射到一个哈希环上，并将这个哈希环按升序排序;
2.将待写入到cache server中的key-value值对象，可以用这个对象的key作为因子用上述同一个一致性哈希函数计算出一个hash值，然后按顺时针在哈希环上找到第一个大于这个hash值的cache server hash值;
3.通过找到的这个cache server hash值可以找到对应的cache server;
4.然后将上述的key-value对象存入到这个cache server中。 

具体实现过程大致可以分为一下几个步骤:

1.定义cache server节点实体, 用于计算cache server节点hash值的字符串;
2.定义一致性哈希结构，用于构建cache server的哈希环;
3.定义添加哈希节点的函数;
4.定义获取哈希节点的函数;
5.定义删除哈希节点的函数。

1.定义cache server节点实体,
```golang
type Node struct {
  Id       int
  Ip       string
  Port     int
  HostName string
  Weight   int
}
```

上面定义了一个cache server node的实体, 作用是用于计算代表cache server node的唯一hash值, 在本程序中将采用缓存服务器的Id, IP, Weight以及虚拟节点Id作为计算字符串，说明如下:

`Id`: 缓存服务器节点id 
`Ip`: 缓存服务器ip
`Port`: 缓存服务器port
`HostName`: 缓存服务器主机名(unique) 
`Weight`: 缓存服务器权重

2.定义一致性哈希结构，

```golang
type Consistent struct {
  Nodes     map[uint32]Node
  numReps   int
  Resources map[int]bool
  ring      HashRing
  sync.RWMutex
}
```

上面定义了一致性哈希结构，说明如下,

`Nodes`: 用于保存所有的hash-cache server node 映射关系
`numReps`: 复制个数, 用于设置每个物理节点所虚拟的个数，即每个物理节点最后虚拟出多少个节点个数
`Resources`: 用于标识当前物理节点是否已经被映射过了 
`ring`: 是一个切片数组， 用于保存所有的虚拟节点，即上面`Nodes`中的所有`key`值，可以通过这个`key`值到`Nodes`中去取对应的cache server信息，这个切片数组是排序过的，可以想象成一个环，及所谓的hash 环。
`sync.RWMutex`: 读写锁，全部数据操作一致性。

3.定义添加哈希节点函数, 用于构建哈希环
```golang
func (c *Consistent) Add(node *Node) bool {
	c.Lock()
	defer c.Unlock()

	if _, ok := c.Resources[node.Id]; ok {
		return false
	}

	count := c.numReps * node.Weight
	for i := 0; i < count; i++ {
		str := c.joinStr(i, node)
		c.Nodes[c.hashStr(str)] = *(node)
	}
	c.Resources[node.Id] = true
	c.sortHashRing()
	return true
}
```
上述添加哈希节点过程其实就是在计算一个一个cache server node的hash值，并构建排序过的哈希环， 大致分为以下几步:
1.检查当前物理节点是否已经被映射到哈希环上了，没有则进入下一步，
2.根据权重值计算出本物理节点的最终虚拟节点个数，然后分别计算对应虚拟节点的hash值,保存到`Nodes`结构中，
3.构建哈希环并排序，

4.定义获取哈希节点的函数, 用于将待存储的热点值存入到对应的cache server上,
```golang
func (c *Consistent) Get(key string) Node {
	c.RLock()
	defer c.RUnlock()

	hash := c.hashStr(key)
	hit_index := c.search(hash)

	return c.Nodes[c.ring[hit_index]]
}
```

大致过程，
1.计算对象key的hash值，
2.根据上面计算的hash值，用二分搜索法到哈希环搜索自上述hash值起离它最近的一个cache server node hash值节点key，
3.根据查找到的cache server节点key, 返回`Nodes`结构中存储的cache sever信息，

5.定义删除哈希节点的函数, 当某个cache server 挂掉之后，用于删除这个节点(一般情况下不建议删除节点，而是将当前坏节点上的数据迁移到好的节点上)
```golang
func (c *Consistent) Remove(node *Node) {
	c.Lock()
	defer c.Unlock()

	if _, ok := c.Resources[node.Id]; !ok {
		return
	}

	delete(c.Resources, node.Id)

	count := c.numReps * node.Weight
	for i := 0; i < count; i++ {
		str := c.joinStr(i, node)
		delete(c.Nodes, c.hashStr(str))
	}
	c.sortHashRing()
}
```

大致过程，
1.判断待删除物理节点是否存在哈希环中，存在则删除，并进入下一步，
2.删除改物理节点映射在哈希环中的所有虚拟节点,
3.重新排序哈希环,


至此一致性哈希算法基本实现， 详细代码请参见 https://github.com/researchlab/experiments/tree/master/consistent_hash

## 总结
- 详细阐述了一致性哈希算法实现原理及适合场景
- 采用slice + sort 方式构建哈希环，并用golang实现了一致性哈希算法
- 可以尝试采用红黑树的方式来构建哈希环，在性能上可能更好，有待进一步尝试 
