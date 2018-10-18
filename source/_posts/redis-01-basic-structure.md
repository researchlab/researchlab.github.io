---
title: "redis专题01 基础数据结构"
date: 2018-1-16 11:31:18
categories: "redis专题"
tags: [redis]
description:
---
在日常应用开发中，redis常应用于热点内容缓存，分布式锁，权限认证等场景中，此redis专题试图对redis技术在内容缓存,分布式及redis集群场景中的应用，使用特性，原理及源码进行分析总结，内容来源于个人工作经验实践及网络学习资源的融合归纳总结;
<!--more-->

#### 1 redis 环境搭建
通过docker方式搭建一个redis 环境
```shell
# 拉取 redis 镜像
> docker pull redis
# 运行 redis 容器
> docker run --name myredis -d -p6379:6379 redis
# 执行容器中的 redis-cli，可以直接使用命令行操作 redis
> docker exec -it myredis redis-cli
# redis 默认有从0到15共计16个数据库，默认为0号数据库
# flushall 清空redis所有数据库数据(从0到15号数据库)
127.0.0.1:6379> flushall
OK
# 选择0号数据库
127.0.0.1:6379> select 0
OK
# 查询当前数据库已存数据的大小
127.0.0.1:6379> dbsize
(integer) 0
# flushdb 清除单个数据库的数据， 如现在清空的是0号数据库的所有数据
127.0.0.1:6379> flushdb
OK
127.0.0.1:6379>
```

#### 2 redis基础结构

redis有5个基础数据结构

* `string` 字符串
* `list` 列表
* `set` 集合
* `hash` 哈希
* `zset` 有序集合

> [redis命令参考链接](http://doc.redisfans.com/)

##### 2.1 string(字符串)

Redis中string是动态字符串，采用预分配冗余空间的方式来减少内存的频繁分配，即一个字符串的地址大小实际有两个长度表示，一个是字符串的实际长度len, 另一个是初始化时系统预分配的空间大小capacity, (capacity >= len), 当字符串长度小于1M时，扩容都是加倍现有的空间，如果超过1M，扩容时一次只会多扩1M的空间。

> redis字符串最大长度为512M;

基础操作
```shell
127.0.0.1:6379> set target learning.redis
OK
127.0.0.1:6379> get target
"learning.redis"

# 计算字符串长度
127.0.0.1:6379> strlen target
(integer) 14

# 在字符串尾部追加，返回最终长度
127.0.0.1:6379> append target .more
(integer) 19
127.0.0.1:6379> get target
"learning.redis.more"

# 根据变量名，及子串的开始及结束位置 获取子串
127.0.0.1:6379> getrange target 15 18
"more"

# 根据变量名， 及待覆盖子串的开始位置，从开始位置覆盖变量值
127.0.0.1:6379> setrange target 15 advanced
(integer) 23
127.0.0.1:6379> get target
"learning.redis.advanced"
127.0.0.1:6379>

# 删除字符串可用del指令进行主动删除，也可用expire指令设置过期时间，到点会自动删除;
127.0.0.1:6379> set timeout deleteby.itself.after.10.seconds ex 10
OK
127.0.0.1:6379> get timeout
"deleteby.itself.after.10.seconds"

#after 10 seconds
127.0.0.1:6379> get timeout
(nil)
127.0.0.1:6379> set tmp no.timeout
OK
127.0.0.1:6379> get tmp
"no.timeout"
127.0.0.1:6379> del tmp
(integer) 1
127.0.0.1:6379> get tmp
(nil)
127.0.0.1:6379>
```

- 使用场景一 计数器
如果字符串为整数时，可以将字符串当成计数器来使用
```shell
127.0.0.1:6379> set nums 10
OK
127.0.0.1:6379> get nums
"10"

# 在原变量nums值上增加(incrby)或减少（decry)步长10, 返回最终的计算值
127.0.0.1:6379> incrby nums 10
(integer) 20
127.0.0.1:6379> decrby nums 10
(integer) 10

# 在原变量nums值上增加(incr)或减少(decr)步长1， 返回最终的计算值
127.0.0.1:6379> incr nums
(integer) 11
127.0.0.1:6379> decr nums
(integer) 10

# 若变量不存在，则incr/decr会创建变量名并在零值基础上进行加(incr)或减(decr)1操作;
127.0.0.1:6379> incr id
(integer) 1
127.0.0.1:6379> decr std
(integer) -1

# 注意redis中整数值的有效范围区间，超过溢出报错
127.0.0.1:6379> set nums 9223372036854775807
OK
127.0.0.1:6379> incr nums
(error) ERR increment or decrement would overflow
127.0.0.1:6379> set nums -9223372036854775808
OK
127.0.0.1:6379> decr nums
(error) ERR increment or decrement would overflow
127.0.0.1:6379>
```

##### 2.2 list(列表)
Redis将列表数据结构命名为list而不是array，是因为列表的存储结构用的是链表而不是数组，而且链表还是双向链表。因为它是链表，所以随机定位性能较弱，首尾插入删除性能较优。如果list的列表长度很长，使用时我们一定要关注链表相关操作的时间复杂度。

`负下标` 链表元素的位置使用自然数`0,1,2,....n-1`表示，还可以使用负数`-1,-2,...-n`来表示，`-1`表示`「倒数第一」`，`-2`表示`「倒数第二」`，那么`-n`就表示`第一个元素，对应的下标为0`；

`队列／栈` 链表提供了可以从左边或右边分别对表头表尾进行删除和插入操作的rpush/rpop/lpush/lpop四条命令，使得在需要用到队列或栈操作中使用list列表结构非常方便；

`模拟队列` 先进先出操作

```shell
# 右进左出
127.0.0.1:6379> rpush skills go
(integer) 1
127.0.0.1:6379> rpush skills java python
(integer) 3
127.0.0.1:6379> lpop skills
"go"
127.0.0.1:6379> lpop skills
"java"
127.0.0.1:6379> lpop skills
"python"

# 左进右出
127.0.0.1:6379> lpush skills go java python
(integer) 3
127.0.0.1:6379> rpop skills
"go"
```

> 在日常应用中，列表常用来作为异步队列来使用。


`模拟栈`  后进先出操作

```shell
# 右进右出
127.0.0.1:6379> rpush skills go java python
(integer) 3
127.0.0.1:6379> rpop skills
"python"
...
# 左进左出
127.0.0.1:6379> lpush skills go java python
(integer) 3
127.0.0.1:6379> lpop skills
"python"
```

`随机读` 可以使用`lindex`指令访问指定位置的元素，使用`lrange`指令来获取链表子元素列表，提供`start`和`end`下标参数

```shell
127.0.0.1:6379> rpush skills go java python
(integer) 3
127.0.0.1:6379> lindex skills 1
"java"
127.0.0.1:6379> lrange skills 0 2
1) "go"
2) "java"
3) "python"
127.0.0.1:6379> lrange skills 0 -1  # -1表示倒数第一
1) "go"
2) "java"
3) "python"
```
> 使用`lrange`获取全部元素时，需要提供`end_index`，如果没有负下标，就需要首先通过`llen`指令获取长度，才可以得出`end_index`的值，有了负下标，使用`-1`代替`end_index`就可以达到相同的效果。

`修改元素` 使用`lset`指令在指定位置修改元素。
```shell
127.0.0.1:6379> rpush skills go java python
(integer) 3
127.0.0.1:6379> lset skills 1 javascript
OK
127.0.0.1:6379> lrange skills 0 -1
1) "go"
2) "javascript"
3) "python"
```

`插入元素` 使用`linsert`指令在列表的中插入新增元素，插入新元素时需要在`linsert`指令里指明方向参数`before`/`after`来显示指示前置和后置插入； 其次，`linsert`指令并不是通过指定位置来插入，而是通过指定具体的值。这是因为在分布式环境下，列表的元素总是频繁变动的，意味着上一时刻计算的元素下标在下一时刻可能就不是你所期望的下标了。

```shell
127.0.0.1:6379> rpush skills go python java
(integer) 3
127.0.0.1:6379> linsert skills before python javascript
(integer) 4
127.0.0.1:6379> lrange skills 0 -1
1) "go"
2) "javascript"
3) "python"
4) "java"
127.0.0.1:6379>
```

`删除元素` 列表的删除操作也不是通过指定下标来确定元素的，你需要指定删除的最大个数以及元素的值
```shell
127.0.0.1:6379> rpush skills go python go java javascript
(integer) 5
127.0.0.1:6379> lrange skills 0 -1
1) "go"
2) "python"
3) "go"
4) "java"
5) "javascript"

# 指定删除的最大个数及待删除的值，返回删除后的个数值
# 如果待删除的值不存在， 返回0
# 如果待删除的值的个数少于指定的最大个数值， 则返回实际删除的个数值
127.0.0.1:6379> lrem skills 1 go
(integer) 1
127.0.0.1:6379> lrange skills 0 -1
1) "python"
2) "go"
3) "java"
4) "javascript"
127.0.0.1:6379> lrem skills 2 java
(integer) 1
127.0.0.1:6379> lrange skills 0 -1
1) "python"
2) "go"
3) "javascript"
127.0.0.1:6379> lrem skills 2 ruby
(integer) 0
127.0.0.1:6379> lrange skills 0 -1
1) "python"
2) "go"
3) "javascript"
127.0.0.1:6379>
```

`定长列表` 在实际应用场景中，有时会遇到` 「定长列表」` 的需求。比如要以走马灯的形式实时显示中奖用户名列表，因为中奖用户实在太多，能显示的数量一般不超过100条，那么这里就会使用到定长列表。维持定长列表的指令是` ltrim` ，需要提供两个参数start和end，表示需要保留列表的下标范围，范围之外的所有元素都将被移除。
```shell
127.0.0.1:6379> rpush skills go java python javascript ruby erlang rust app php
(integer) 9
127.0.0.1:6379> ltrim skills -3 -1
OK
127.0.0.1:6379> lrange skills 0 -1
1) "rust"
2) "app"
3) "php"

# 当指定参数的end对应的真实下标小于start，其效果等价于del指令，因为这样的参数表示需要需要保留列表元素的下标范围为空。
127.0.0.1:6379> ltrim skills -3 -5
OK
127.0.0.1:6379> lrange skills 0 -1
(empty list or set)
127.0.0.1:6379>
```

`快速列表 quicklist`
```shell
# 快速列表结构
ziplist <---> ziplist <---> ziplist
```
>**再深入一点，会发现Redis底层存储的还不是一个简单的`linkedlist`，而是称之为`快速链表quicklist`的一个结构。首先在列表元素较少的情况下会使用一块连续的内存存储，这个结构是`ziplist`，也即是`压缩列表`。它将所有的元素紧挨着一起存储，分配的是一块连续的内存。当数据量比较多的时候才会改成`quicklist`。因为普通的链表需要的附加指针空间太大，会比较浪费空间。比如这个列表里存的只是`int`类型的数据，结构上还需要两个额外的指针`prev`和`next`。所以Redis将`链表`和`ziplist`结合起来组成了`quicklist`。也就是将<u>多个`ziplist`使用<font color=red>双向指针</font>串起来(组成`quicklist`）</u>使用。这样既满足了快速的插入删除性能，又不会出现太大的空间冗余。**

##### 2.3 hash(哈希)

```shell
#哈希结构
    /key ---> value
hash-key ---> value
   \\key ---> value
    \...

                   val2    val2    val2       val2
                   val1    val1    val1       val1
                    ^       ^      ^          ^
                    |       |      |          |
    hash --- array{[key0], [key1], [key2], ... [key2^n]}
```

哈希结构等价于Java中的`HashMap`或者是Python中的字典`dict`结构，但Redis的字典的值只能是字符串, 在<u>实现结构上它使用`二维结构`，第一维是数组，第二维是链表，`hash`的内容`key`和`value`存放在链表中，数组里存放的是链表的头指针</u>。通过key查找元素时，先计算`key`的`hashcode`，然后用`hashcode`对数组的长度进行取模定位到链表的表头，再对链表进行遍历获取到相应的`value`值，链表的作用就是用来将产生了`「hash碰撞」`的元素串起来。Java语言开发者会感到非常熟悉，因为这样的结构和HashMap是没有区别的。哈希的第一维数组的长度也是2^n。

`基础操作`
**增**
- `hset`  一次增加一个键值对;
- `hmset` 一次增加多个键值对;

**删**
- `hdel`  删除指定key，hdel支持同时删除多个key;

~~**改**~~

**查**
- `hget`          获取具体key对应的value;
- `hmget`         获取多个key对应的value;
- `hgetall`       获取所有的键值对;
- `hkeys`和`hvals` 可分别获取所有的key列表和value列表;
- `hexists`       判断某个值是否存在于指定key中;

> 判断元素是否存在 可以使用`hget`获得`key`对应的`value`是否为空来判断，若value的字符串长度特别大，通过这种方式来判断元素存在与否就略显浪费，此时建议使用hexists指令;

```shell
#hset 设置单个field-value值对并返回设置成功的值对个数，但在下列实践中hset 好像也支持设置多个值队并返回了大于2的值对个数，但是不建议使用hset设置多个值对操作；
127.0.0.1:6379> hset auth mike true david true
(integer) 2
127.0.0.1:6379> hget auth mike
"true"
127.0.0.1:6379> hmset auth jack false jett true
OK
127.0.0.1:6379> hget auth jett
"true"
# 当hmget 获取不存在key的field对应的value时返回nil
127.0.0.1:6379> hmget jack mike jett
1) (nil)
2) (nil)
127.0.0.1:6379> hmget auth jack mike jett
1) "false"
2) "true"
3) "true"
127.0.0.1:6379> hgetall auth
1) "mike"
2) "true"
3) "david"
4) "true"
5) "jack"
6) "false"
7) "jett"
8) "true"
127.0.0.1:6379> hkeys auth
1) "mike"
2) "david"
3) "jack"
4) "jett"
127.0.0.1:6379> hvals auth
1) "true"
2) "true"
3) "false"
4) "true"
# hdel 可以支持删除多个field,当field不存在则忽略，最终返回删除成功的个数
127.0.0.1:6379> hdel auth jack jett ruby
(integer) 2
# hexists 判断指定key中指定field的value值是否存在
127.0.0.1:6379> hexists auth jack
(integer) 0
127.0.0.1:6379> hgetall auth
1) "mike"
2) "true"
3) "david"
4) "true"
127.0.0.1:6379>
```

`计数器` 如果value为整数，那也可用`hash结构`来计数，对于内部的每一个key都可以作为独立的计数器。如果value值不是整数，调用hincrby指令会出错。
```shell
127.0.0.1:6379> hset nums fish 1
(integer) 1
127.0.0.1:6379> hincrby nums fish 5
(integer) 6
127.0.0.1:6379> hgetall nums
1) "fish"
2) "6"
127.0.0.1:6379>
```

`扩容` 当`hash`内部的元素比较拥挤时(hash碰撞比较频繁)，就需要进行扩容。扩容需要申请新的两倍大小的数组，然后将所有的键值对重新分配到新的数组下标对应的链表中(`rehash`)。如果hash结构很大，比如有上百万个键值对，那么一次完整rehash的过程就会耗时很长, 这对于单线程的Redis里来说有点压力山大。所以<u>**Redis采用了渐进式rehash的方案。它会同时保留两个新旧hash结构，在后续的定时任务以及hash结构的读写指令中将旧结构的元素逐渐迁移到新的结构中。这样就可以避免因扩容导致的线程卡顿现象。**</u>

hash 结构也可以用来存储用户信息，不同于字符串一次性需要全部序列化整个对象，hash 可以对用户结构中的每个字段单独存储。这样当我们需要获取用户信息时可以进行部分获取。而以整个字符串的形式去保存用户信息的话就只能一次性全部读取，这样就会比较浪费网络流量。

hash 也有缺点，hash 结构的存储消耗要高于单个字符串，到底该使用 hash 还是字符串，需要根据实际情况再三权衡。

`缩容` hash结构缩容的原理和扩容是一致的，只不过新的数组大小要比旧数组小一倍。

##### 2.4 set(集合)
Redis的`set`的内部结构就是`hash结构`，所有的value都指向同一个内部值。
**增**
- `sadd` 可以一次增加多个元素;

**删**
- `srem` 删除一到多个元素;
- `spop` 删除随机一个元素;

~~**改**~~

**查**
- `smembers`  列出所有元素，
- `scard`  获取集合长度，
- `srandmember` 获取随机count个元素，如果不提供count参数，默认为1
- `sismember`  判断元素是否存在(只能接收单个元素) 使用场景之一是判断是否有某种权限

```shell
# sadd 添加集合元素， 返回成功添加元素个数
127.0.0.1:6379> sadd skills go python java
(integer) 3
127.0.0.1:6379> smembers skills
1) "java"
2) "python"
3) "go"

# scard 获取集合长度
127.0.0.1:6379> scard skills
(integer) 3
127.0.0.1:6379> srandmember skills 2
1) "python"
2) "java"
127.0.0.1:6379> srandmember skills 2
1) "java"
2) "go"

# srem 删除集合某个元素， 返回成功删除个数
127.0.0.1:6379> srem skills python java
(integer) 2
127.0.0.1:6379> smembers skills
1) "go"
127.0.0.1:6379> spop skills
"go"

# sismember 判断给定元素是否存在某个集合中
127.0.0.1:6379> sismember skills go
(integer) 0
127.0.0.1:6379>
```
##### 2.5 sortedset(有序集合)

`SortedSet`(`zset`)是Redis提供的一个非常特别的数据结构，一方面它等价于`Java`的数据结构`Map<String, Double>`，可以给每一个元素`value`赋予一个权重`score`，另一方面它又类似于`TreeSet`，内部的元素会按照权重`score`进行排序，可以得到每个元素的名次，还可以通过`score`的范围来获取元素的列表。
<u>**`zset`底层实现使用了两个数据结构，第一个是`hash`，第二个是`跳跃列表`，`hash`的作用就是关联元素`value`和权重`score`，保障元素`value`的唯一性，可以通过元素`value`找到相应的`score`值。跳跃列表的目的在于给元素`value`排序，根据`score`的范围获取元素列表。**</u>

**增**
- `zadd`   增加一到多个`value/score`对，`score`放在前面

**删**
- `zrem`   可以删除`zset`中的元素，可以一次删除多个
- `zremrangebyrank` 可以根据排名范围来删除一个或多个值
- `zremrangebyscore` 可以根据分值返回来删除一个或多个值

**改**
- `zincrby` 以指定步长修改指定元素的value值，若value不是整数则会报错

**查**
- `zcard`可以得到`zset`的元素个数
- `zscore` 获取指定元素的权重
- `zrank` 获取指定元素的正向排名
- `zrevrank` 获取指定元素的反向排名[倒数第一名]。
> 正向是由小到大，负向是由大到小。

- `zrange`    指令指定排名范围参数获取对应的元素列表，携带withscores参数可以一并获取元素的权重。
- `zrevrange` 指令按负向排名获取元素列表[倒数]。正向是由小到大，负向是由大到小。
- `zrangebyscore` 指定score范围获取对应的元素列表。
- `zrevrangebyscore` 指令获取倒排元素列表。
> 正向是由小到大，负向是由大到小。参数-inf表示负无穷，+inf表示正无穷。

```shell
127.0.0.1:6379> zadd skills 10 go
(integer) 1
127.0.0.1:6379> zadd skills 9 python 8 java 7 js
(integer) 3

#zcard 获取有序集合长度
127.0.0.1:6379> zcard skills
(integer) 4

# zincrby 为指定元素value增加给定步长值, 可以用作计数器
127.0.0.1:6379> zincrby skills 10 go
"20"

# zscore 查询具体元素的score值
127.0.0.1:6379> zscore skills go
"20"

# zrank 查询给定元素的排名(从小到大)， zrevrank 反向查询给定元素的排名(从大到小)
127.0.0.1:6379> zrank skills go
(integer) 1
127.0.0.1:6379> zrank skills python
(integer) 0
127.0.0.1:6379> zrevrank skills go
(integer) 0

# 获取有序集合的所有元素 zrange是按照正向(score值从小到大)排序返回的值列表
127.0.0.1:6379> zrange skills 0 -1
1) "python"
2) "go"
127.0.0.1:6379> zrange skills 0 -1 withscores
1) "python"
2) "9"
3) "go"
4) "20"
127.0.0.1:6379> zrevrange skills 0 -1 withscores
1) "go"
2) "20"
3) "python"
4) "9"

# 获取指定score返回的有序集合值
127.0.0.1:6379> zrangebyscore skills 0 20
1) "python"
2) "go"
127.0.0.1:6379> zrangebyscore skills -inf +inf withscores
1) "python"
2) "9"
3) "go"
4) "20"
127.0.0.1:6379> zrevrangebyscore skills +inf -inf withscores
1) "go"
2) "20"
3) "python"
4) "9"
127.0.0.1:6379> zrevrangebyscore skills +inf +inf withscores
(empty list or set)

# zrem 删除指定key的指定field组
127.0.0.1:6379> zrem skills java js
(integer) 2

# zremrangebyrank 删除指定排名返回内的值组
127.0.0.1:6379> zremrangebyrank skills 0 0
(integer) 1
127.0.0.1:6379> zrange skills 0 1
1) "go"

#zremrangebyscore 删除给定score返回的值组
127.0.0.1:6379> zremrangebyscore skills -inf 10
(integer) 0
127.0.0.1:6379> zrange skills 0 1
1) "go"
127.0.0.1:6379>
```
`跳跃列表` `zset`内部的排序功能是通过`「跳跃列表」`数据结构来实现的，它的结构非常特殊，也比较复杂。
因为zset要支持随机的插入和删除，所以它不好使用数组来表示。先看一个普通的链表结构,
```shell
(value,score)-->(value,score)-->(value,score)-->(value,score)-->(value,score)
```
需要这个链表按照score值进行排序。这意味着当有新元素需要插入时，需要定位到特定位置的插入点，这样才可以继续保证链表是有序的。通常我们会通过二分查找来找到插入点，但是二分查找的对象必须是数组，只有数组才可以支持快速位置定位，链表做不到，那该怎么办？ 引入跳跃列表
跳跃列表（也称跳表）是一种随机化数据结构，基于并联的链表，其效率可比拟于二叉查找树（对于大多数操作需要O(logn)平均时间）。

基本上，跳跃列表是对有序的链表增加上附加的前进链接，增加是以随机化的方式进行的，所以在列表中的查找可以快速的跳过部分列表元素，因此得名。所有操作都以对数随机化的时间进行。

跳跃表描述:
* 一个跳跃列表由几层组成
* 底层包含所有元素
* 每一层都是一个有序链表
* 在层 `i` 中的元素按某个固定的概率`p(通常为0.5或0.25)`出现在层 `i+1` 中(也就是说高层中的元素必然在低层)
* 第`i`层的某个元素可以向下访问与它有相同值的下层节点

如下图所示，是一个即为简单的跳跃表。传统意义的单链表是一个线性结构，向有序的链表中插入一个节点需要O(n)的时间，查找操作需要O(n)的时间。如果我们使用图中所示的跳跃表，就可以大大减少减少查找所需时间。

```shell
L2：1-----4---6
L1：1---3-4---6-----9
L0：1-2-3-4-5-6-7-8-9-10
```
定位插入点时，先在顶层进行定位，然后下潜到下一级定位，一直下潜到最底层找到合适的位置，将新元素插进去。你也许会问那新插入的元素如何才有机会「身兼数职」呢？
跳跃列表采取一个随机策略来决定新元素可以兼职到第几层，首先`L0`层肯定是`100%`了，`L1`层只有`50%`的概率，`L2`层只有`25%`的概率，`L3`层只有`12.5%`的概率，一直随机到最顶层`L31`层。绝大多数元素都过不了几层，只有极少数元素可以深入到顶层。列表中的元素越多，能够深入的层次就越深，能进入到顶层的概率就会越大。

#### 总结
---
本文对Redis5种基础数据结构原理，内部实现,常用操作，场景等进行总结,
* `string` 字符串, 内部结构未动态数组;
* `list` 列表, 内部结构为双向链表, 这个双向链表称之为`快速链表(quicklist)`, 由`ziplist压缩链表`通过`双向指针`连接而成，因而可以提高快速插入性能，同时`ziplist压缩列表`是一块连续内存的链表;
* `hash` 哈希， 内部结构为二维结构，一维为数组用于记录`key`键列表， 二维为链表用于记录`value`列表,通过一个`key`下挂着一个`value`链表，通过哈希函数取具体的`value`值;同时redis采用渐进式rehash可以方便对`hash`结构进行扩容和缩容;
* `set` 集合， 内部结构为`hash`结构，适用场景之一是判断某个元素是否存在于集合中，如多权限分配场景;
* `sortedset` 有序集合， `zset`底层实现使用了两个数据结构，第一个是`hash`，第二个是`跳跃列表`，`hash`的作用就是关联元素`value`和权重`score`，保障元素`value`的唯一性，可以通过元素`value`找到相应的`score`值。跳跃列表的目的在于给元素`value`排序，根据`score`的范围获取元素列表。

此外，进一步分析了`跳跃表`的原理/用途，`跳跃表`也被用在`leveldb`中。在一些词典结构中中也经常用`跳跃表`来实现字典，加快查找速度；
