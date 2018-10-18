---
title: "redis专题05 海量数据处理之HyperLogLog"
date: 2018-2-18 18:48:44
categories: "redis专题"
tags: [redis]
description:
---
`HyperLoglog`是`redis`新支持的两种类型中的另外一种(上一种是位图类型`Bitmaps`)。主要适用场景是海量数据的计算。特点是速度快, 占用空间小。
<!--more-->
同样是用于计算，`Bitmaps`可能更适合用于验证的大数据，比如签到，记录某用户是不是当天进行了签到，签到了多少天的时候。也就是说，你不光需要记录数据，还需要对数据进行验证的时候使用`Bitmaps`。

而`HyperLoglog`则用于只记录的时候，如统计每个网页每天的访问UV,

如果统计`PV`那非常好办，给每个网页一个独立的`Redis`计数器就可以了，这个计数器的`key`后缀加上当天的日期。这样来一个请求，`incrby`一次，最终就可以统计出所有的`PV`数据。

但是`UV`不一样，它要去重，同一个用户一天之内的多次访问请求只能计数一次。这就要求每一个网页请求都需要带上用户的`ID`，无论是登陆用户还是未登陆用户都需要一个唯一`ID`来标识。

你也许已经想到了一个简单的方案，那就是为每一个页面一个独立的`set`集合来存储所有当天访问过此页面的用户`ID`。当一个请求过来时，我们使用`sadd`将用户`ID`塞进去就可以了。通过`scard`可以取出这个集合的大小，这个数字就是这个页面的`UV`数据。没错，这是一个非常简单的方案。

但如果页面访问量非常大，比如一个爆款页面几千万的`UV`，你需要一个很大的`set`集合来统计，这就非常浪费空间。如果这样的页面很多，那所需要的存储空间是惊人的。为这样一个去重功能就耗费这样多的存储空间，值得么？

由此可以<u>用`redis`提供的`HyperLogLog`数据结构来**解决这种统计问题**的</u>。

> `HyperLogLog`提供不精确的去重计数方案，虽然不精确但是也不是非常不精确，标准误差是`0.81%`，这样的精确度已经可以满足上面的`UV`统计需求了。

#### `HyperLogLog`数据结构基础应用

`redis`为操作`HyperLogLog`数据结构提供了三条命令，
* `pfadd`  添加计数
* `pfcount`  获取计数
* `pfmerge` 合并两个数据的数据

* `pfadd` 添加数据

> 命令：`PFADD key element [element ...]`

> * 功能：将除了第一个参数以外的参数存储到以第一个参数为变量名的`HyperLogLog`结构中。

> * 如果一个`HyperLogLog`的估计的近似基数在执行命令过程中发了变化，`PFADD`返回1，否则返回0，如果指定的key不存在，这个命令会自动创建一个空的`HyperLogLog`结构（指定长度和编码的字符串）。
> * 如果在调用该命令时仅提供变量名而不指定元素也是可以的，如果这个变量名存在，则不会有任何操作，如果不存在，则会创建一个数据结构。
> * 返回值：如果`HyperLogLog`的内部被修改了,那么返回 1,否则返回 0 。

* `pfcount`

> 命令：`PFCOUNT key [key ...]`

> * 功能：当参数为一个`key`时,返回存储在`HyperLogLog`结构体的该变量的近似基数，如果该变量不存在,则返回0。

> * 当参数为多个`key`时，返回这些`HyperLogLog`并集的近似基数，这个值是将所给定的所有`key`的`HyperLoglog`结构合并到一个临时的`HyperLogLog`结构中计算而得到的;
> * <u>**`HyperLogLog`可以使用固定且很少的内存（每个`HyperLogLog`结构需要12K字节再加上key本身的几个字节）来存储集合的唯一元素。返回的可见集合基数并不是精确值， 而是一个带有 0.81% 标准错误（`standard error`）的近似值。**</u>
> * 返回值：`PFADD`添加的唯一元素的近似数量;

`pfadd`和`pfcount`用法和`set`集合的`sadd`和`scard`是一样的，添加数据，获取计数/长度;

```shell
# pfadd 添加计算，若修改了HyperLogLog结构则返回1 ，否则返回0
127.0.0.1:6379> pfadd page user1
(integer) 1
127.0.0.1:6379> pfadd page user1
(integer) 0
127.0.0.1:6379> pfcount page
(integer) 1
127.0.0.1:6379> pfadd page user2
(integer) 1
127.0.0.1:6379> pfcount page
(integer) 2
# pfadd 可以一次添加多个计数
127.0.0.1:6379> pfadd page user3 user4 user5
(integer) 1
127.0.0.1:6379> pfcount page
(integer) 5
127.0.0.1:6379>
```

* `pfmerge`

> 命令：`PFMERGE destkey sourcekey [sourcekey ...]`

> * 功能：将多个`HyperLogLog`合并（`merge`）为一个`HyperLogLog`, 合并后的`HyperLogLog`的基数接近于所有输入`HyperLogLog`的可见集合（`observed set`）的并集;

> * <u>合并得出的`HyperLogLog`会被储存在目标变量（第一个参数）里面， 如果该键并不存在， 那么命令在执行之前， 会先为该键创建一个空的;</u>
> * 返回值：这个命令只会返回 OK

```shell
127.0.0.1:6379> pfadd home user1
(integer) 1
127.0.0.1:6379> pfcount home
(integer) 1
127.0.0.1:6379> pfadd about user1
(integer) 1
127.0.0.1:6379> pfcount about
(integer) 1
# pfmerge 将home和about两个page的计算合并为total, 注意合并时会将home和about中相同的部分在进行Pfadd加入到新`total` HyperLogLog结构中时， 因其近似基数部分相同所以会被忽略而不会重复计数；
127.0.0.1:6379> pfmerge total home about
OK
# 合并生成 的total 并不是2 而是1， 因为home和about的计数值都是user1
127.0.0.1:6379> pfcount total
(integer) 1
127.0.0.1:6379> pfadd home user2
(integer) 1
127.0.0.1:6379> pfcount home
(integer) 2
127.0.0.1:6379> pfmerge total home about
OK
# 再次合并后就变成了2了， 因为不重复访问用户只有 user1, user2
127.0.0.1:6379> pfcount total
(integer) 2
127.0.0.1:6379> pfcount about
(integer) 1
# 注意pfmerge 是把source列表去重后合并到destkey， 如果destkey已经存在，和覆盖其之前值
# 同时合并仅对destkey值产生变更，其他不变
127.0.0.1:6379> pfmerge about home
OK
127.0.0.1:6379> pfcount about
(integer) 2
127.0.0.1:6379>
```

#### `HyperLogLog` 实现原理

上述实现过程中可以看到`HyperLogLog` 在统计计数时可以很好的处理重复值问题， 那它是如何做到的呢？ 这就需要进一步了解`HyperLogLog`的内部实现原理了，

`redis`内部`HyperLogLog`中会先给其分配一定数量的桶， 这些桶就是用来存储创建的`key`值的， 即`pfadd key elmement`中的`key`, 然后通过`hash`将`element`存储下来， 这样相同的`element`的<u>**近似基数**</u>是一样的，所以相同的`element`插入不在往桶中添加了，故在`pfcount`基数时 则只会算一次了，

上说的`pfcount`计算的是近似估值，误差在`0.81%`标准错误, 这是因为`HyperLogLog`在统计时计算的就是估值而不是精确值，因为在`pfadd`时是通过`element`的近似基数进行更新`HyperLogLog`结构的， 案例分析如下，

> `pfadd nums 随机数1， 随机数2， 随机数3 ... 随机数N

<figure class="highlight"><font style="color:#817c7c;font-size:90%">高位 <----------------- 低位</font>

随机数1   1 0 0 1 0 1 0 1 1 <font style="color:#d14;border:1px solid #d6d6d6; border-radius:0.25em;">0 0 0 0</font>
随机数2   1 0 0 1 0 1 0 1 0 1 <font style="color:#d14;border:1px solid #d6d6d6; border-radius:0.25em;">0 0 0</font>
随机数3   1 <font style="color:#d14;border:1px solid #d6d6d6; border-radius:0.25em;">0 0 0 0 0 0 0 0 0 0 0 0</font>
随机数4   1 0 0 1 0 1 0 1 1 1 1 <font style="color:#d14;border:1px solid #d6d6d6; border-radius:0.25em;">0 0</font>
随机数5   1 0 0 1 0 1 <font style="color:#d14;border:1px solid #d6d6d6; border-radius:0.25em;">0 0 0 0 0 0 0</font>
......
随机数N   1 0 0 1 <font style="color:#d14;border:1px solid #d6d6d6; border-radius:0.25em;">0 0 0 0 0 0 0 0 0</font>
</figure>

如上， 给定一系列的随机整数，通过记录下低位连续零位的最大长度`k`，通过这个`k`值可以估算出随机数的数量，实验发现`K`和`N`的对数之间存在显著的线性相关性, 通过这种线性近似计算可以得到`pfcount` 指定`key`的近似估值， 详细的原理这里不在进一步阐述；

>  可进一步参看[HyperLogLog 复杂的公式推导](https://www.slideshare.net/KaiZhang130/countdistinct-problem-88329470)

> `redis`的`HyperLogLog`实现中用到的是`16384`个桶，也就是`2^14，每个桶的`maxbits`需要`6 bits`来存储，最大可以表示`maxbits=63`，于是总共占用内存就是`2^14 * 6 / 8 = 12k`字节。


#### 总结
- 从处理海量数据count distict问题场景入手，引入`redis`的`HyperLogLog`数据结构解决方案，总结了使用方法并进行了实例分析说明；
- 对`HyperLogLog` 如何进行`count distict`计数的原理进行了简要探讨和实例分析说明，并给出了进一步参看建议;
- `HyperLogLog`结构主要是为了`count-distinct`问题，尤其是处理海量数据时，速度快，占用内存小，但是统计值是有误差的，并且只能递增，不能递减；
- `redis`对`HyperLogLog`的存储进行了优化，在计数比较小时，它的存储空间采用`稀疏矩阵存储`，空间占用很小，仅仅在计数慢慢变大，稀疏矩阵占用空间渐渐超过了阈值时才会一次性转变成`稠密矩阵`，才会占用`12k`的空间;
