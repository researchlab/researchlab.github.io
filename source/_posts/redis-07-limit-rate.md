---
title: "redis专题07 redis应用之限流策略"
date: 2018-10-23 17:01:59
categories: "redis专题"
tags: [redis]
description:
---

限流算法在分布式领域是一个经常被提起的话题，当系统的处理能力有限时，如何阻止计划外的请求继续对系统施压，这是一个需要重视的问题。除了控制流量，限流还有一个应用目的是用于控制用户行为，避免垃圾请求。比如在`UGC`社区, `用户的发帖`, `回复`, `点赞`等行为都要严格受控，一般要严格限定某行为在规定时间内允许的次数，超过了次数那就是非法行为。
<!--more-->

##### 问题

系统要限定用户的某个行为在指定的时间里只能允许发生`N`次，如何使用`redis`的数据结构来实现这个限流的功能？

##### 解决方案
这个限流需求中存在一个滑动时间窗口，想想`zset`数据结构的`score`值，是不是可以通过`score`来圈出这个时间窗口来。而且我们只需要保留这个时间窗口，窗口之外的数据都可以砍掉。用一个`zset`结构记录用户的行为历史，每一个行为都会作为`zset`中的一个`key`保存下来。同一个用户同一种行为用一个`zset`记录。为节省内存，我们只需要保留时间窗口内的行为记录，同时如果用户是冷用户，滑动时间窗口内的行为是空记录，那么这个`zset`就可以从内存中移除，不再占用空间。

```shell
ZADD key score member [[score member] [score member] ...]

key: 'hist:userid:actionkey

score: 'time.Millisecond'

member: 'time.Millisecond'
```

> 每个用户的每个行为单独作为一个`key`;
> 指定时间时间内，刚好可以利用`zset`集合中的`rangebyscore`命令， 通过把时间设置为`score`值来动态维持一个有效的指定时间内的时间窗口;
> `zset`中插入的`key`值的`member`如果相同， 则只会更新这个相同`member`的`score`值，所以需要保证`member`在同一个行为多次发生时都不同即可， 所以可以简单设置为时间值，但在实际中应保证每次`member`是绝对不同的;

golang代码如下
```golang
package main

import (
	"fmt"
	"log"
	"time"

	"github.com/go-redis/redis"
)

var (
	addr = "127.0.0.1:6378"
)

func main() {

	client := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: "", //no password set
		DB:       0,  // use default DB
	})
	defer client.Close()
	pong, err := client.Ping().Result()
	if err != nil {
		panic(err)
	}
	if pong == "PONG" {
		log.Println("redis service is ready.")
	}
	for i := 1; i <= 10; i++ {
		fmt.Println("nums:", i, " result:", isActionAllowd(client, "test", "reply", 60*time.Second, 5))
		time.Sleep(time.Millisecond) #为了实验效果，这里适当sleep一下，在实际环境中应保证每次member是不同的
	}

}

func isActionAllowd(client *redis.Client, userID, actionKey string, period time.Duration, maxCount int64) bool {
	key := fmt.Sprintf("hist:%s:%s", userID, actionKey)
	mperiod := period.Nanoseconds() / 1e6       //转毫秒
	now := int64(time.Now().Nanosecond() / 1e6) // 毫秒时间戳
    // 注意这里 不能使用 now = time.Now().Seconds()*1000  因为这样精度就丢失了，导致一秒内的所有now值都一样;

	pipe := client.Pipeline()
	pipe.ZAdd(key, redis.Z{
		Score:  float64(now),
		Member: now,
	}) //记录行为， value 和score 都使用毫秒时间戳;
	//移除时间窗口之前的行为记录, 剩下的都是时间窗口内的
	pipe.ZRemRangeByScore(key, "0", fmt.Sprintf("%v", now-mperiod))
	// 获取窗口内的行为数量
	pipe.ZCard(key)
	// 设置zset 过期时间, 避免冷用户持续占用内存
	// 过期时间应该等于时间窗口的长度, 再多宽限1s
	pipe.Expire(key, time.Duration(period+1))
	//执行
	res, err := pipe.Exec()
	if err != nil {
		log.Println(err)
		return false
	}
	cmd, ok := res[2].(*redis.IntCmd)
	if ok {
		return cmd.Val() <= maxCount
	}
	return false
}
```

output
```shell
2018/10/23 11:50:01 redis service is ready.
nums: 1  result: true
nums: 2  result: true
nums: 3  result: true
nums: 4  result: true
nums: 5  result: true
nums: 6  result: false
nums: 7  result: false
nums: 8  result: false
nums: 9  result: false
nums: 10  result: false
```
> 执行结果可知，通过统计滑动窗口内的行为数量与阈值`maxCount`进行比较就可以得出当前的行为是否允许, 从而起到限流策略;

> 因为这几个连续的 Redis 操作都是针对同一个`key`的，使用`pipeline`可以显著提升`redis`存取效率。

##### 总结
- 通过限制规定时间内用户行为次数的场景，引入`redis`在限流策略中的应用，并给出实例分析及代码验证说明;
- 但这种方案也有缺点，因为它要记录时间窗口内所有的行为记录，如果这个量很大，比如限定`60s`内操作不得超过`100w`次这样的参数，它是不适合做这样的限流的，因为会消耗大量的存储空间。
