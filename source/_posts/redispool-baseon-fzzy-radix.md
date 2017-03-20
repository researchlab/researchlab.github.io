---
title: "基于fzzy/radix/redis封装新的redispool"
date: 2017-03-02 14:42:42
categories: [golang]
tags: [golang, redispool]
description:
---

## 前言
之前的老项目的redis client sdk 直接大名鼎鼎的`github.com/fzzy/radix`提供的`redis client` 和`redis pool`, 当访问峰值达到一定的值后会出现`too many open files`等tcp连接错误，同时也没有直接提供authorization 密钥认证的接口，为满足这些新需求基于`fzzy/radix`封装出的新的`redispool`, 已投入生产使用半年来暂无问题，本文总结如下,
<!--more-->

## auth认证

如果redis server 需要密钥访问的话，每新建一个client 连接后都需要先通过authorization认证之后才能被使用，如果每次都通过新建一个redis client 再oauth认证来用显然没什么问题，但对于要频繁进行redis操作的系统而言，最好采用redis pool 的办法来解决，用redis conn 池本来也很好解决， 就是在新建redis conn pool时 每新建一个redis client就auth认证一下然后再保存起来就可以使用了，并且这个连接以后都不需要在进行auth认证了。
如果redis pool在新建之后就固定的话， 是可以如上面这么简单的，但是采用的`fzzy/radix`包在实现的方案是可根据需要自动伸缩地新建redis client conn,之前设置的redis 连接池的大小其实是最小的空闲连接池，当业务需求需要的redis client连接数大于pool中的数目时则会通过redis.Dial()的方法新建一个redis client conn 以满足业务的需求，即在建立redis连接池的时候auth认证的redis client conn 和最后回到pool池中的redis client conn 可能就不是同一个client了，因为当新的redis client conn 塞满redis 连接池后 之前auth认证过的旧的redis client conn就会被Close关闭到而不再回到pool池中，具体实现如下:
```golang
func (p *RedisPool) getRedisClient() (*redis.Client, error) {
	client, err := redis.Dial(p.network, p.addr)
	if err != nil {
		return nil, err
	}
	if len(p.pwd) != 0 {
		if client, err = p.redisAuth(client); err != nil {
			return nil, err
		}
	}
	return client, nil
}

func (p *RedisPool) redisAuth(client *redis.Client) (*redis.Client, error) {
	if _, err := client.Cmd("AUTH", p.pwd).Str(); err != nil {
		client.Close()
		return client, err
	}
	return client, nil
}
```

上述代码提供了一个redisAuth方法来提供auth认证，这样不管是通过新建redis池还是当池中redis client conn耗尽之后单独新建的redis client 都通过上述提供getRedisClient()方法来获取新建的redis client conn ,这样便可保证每次新建的redis client conn 都是通过auth认证的(当然上次实现的时候如果没有设置密码，则不进行密钥认证，只有设置了密钥才会调用auth进行认证授权)。

## qps限制
因为`fzzy/radix`包当初始化创建的redis 连接池中的redis client 耗尽后会通过redis.Dial()方法新建一个redis.client, 如果在某一个峰值redis连接池耗尽的同时大量新建redis.client 而不能及时Close掉这些redis.Client,则后继再redis.Dial()新建的redis client conn 就会因为受系统限制无法分配文件句柄地址而报"too many open files"错误。具体试验可以先限制redis连接池为100, 然后同时发起10w redis 连接请求， 可以通过下面的命令观察到当redis client conn最大分配的大小，超过之后程序也会崩掉。
```bash
watch -n 1 "redis-cli -h localhost -p 6379 -a 123456 client list | wc -l" # redis client 连接数
watch -n 1 "lsof -i:6379 | wc -l " # redis tcp 连接数
```
上述命令可以动态看到每一秒内当前的redis client 连接数目 和 tcp 连接数

显然程序不能仍由业务需求无限的取申请redis client 连接数， 本文设计通过每次成功Get到一个redis client时 则通过`sync/atomic`包原子的给qps新增一 进行计数，当Put到池或Empty全部清空时则进行减一 计数操作, 具体实现如下,
```golang 
// Retrieves an available redis client. If there are none available it will
// create a new one on the fly
func (p *RedisPool) Get() (client *redis.Client, err error) {
	if p.qpsLimit > 0 {
		for p.qps > p.qpsLimit {
			time.Sleep(time.Millisecond * time.Duration(10))
		}
	}
	for i := 0; i < 3; i++ {
		if client, err = p.get(); err != nil {
			break
		} else if pstate, perr := client.Cmd("PING").Str(); pstate == "PONG" && perr == nil {
			break
		}
	}
	if err == nil {
		atomic.AddInt32(&p.qps, 1)
	}
	return
}

// Returns a client back to the pool. If the pool is full the client is closed
// instead. If the client is already closed (due to connection failure or
// what-have-you) it should not be put back in the pool. The pool will create
// more connections as needed.

func (p *RedisPool) Put(conn *redis.Client) {
	select {
	case p.pool <- conn:
	default:
		conn.Close()
	}
	if p.qps > 0 {
		atomic.AddInt32(&p.qps, -1)
	}
}

// Removes and calls Close() on all the connections currently in the pool.
// Assuming there are no other connections waiting to be Put back this method
// effectively closes and cleans up the pool.
func (p *RedisPool) Empty() {
	var conn *redis.Client
	for {
		select {
		case conn = <-p.pool:
			conn.Close()
		default:
			return
		}
		if p.qps > 0 {
			atomic.AddInt32(&p.qps, -1)
		}
	}
}
```

完整的代码设计及测试代码请参见: https://github.com/researchlab/experiments/tree/master/redispool
