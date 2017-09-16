---
title: "golang 设计模式之singleton使用总结"
date: 2016-02-25 17:01:43
categories: [go-pattern]
tags: [golang,singleton]
description:
---

`golang` 1.5版本之后默认设置`GOMAXPROCS`值为当前计算机真实核心数，使得`goroutines`从默认的`单线程内并发执行`变成了默认的（真实核心数支持的）的`多线程内并行`执行。多线程并行执行`goroutines`需要考虑并行执行过程中引入的`线程安全问题`。
<!--more-->

## 单线程singleton模型
单例模式定义：保证一个类仅有一个实例，并提供一个访问它的全局访问点。先摘取一个在实际工作项目中碰到的singleton模型代码:
```golang
package singleton

type singleton struct {
}

var instance *singleton

func GetInstance() *singleton {
	if instance == nil {
       instance = &singleton{}   // 没有考虑线程安全 
	}
	return instance
}
```
上面的`singleton`设计代码在见过的几个`golang`项目中都是这么写的，如果这段代码放在`golang`1.5版本之前默认的单线程场景下运行显然是没什么问题的。`golang`1.5版本之后默认是启动多核并行执行`goroutines`的，如果上述代码放在`golang`1.5版本之后，如果程序开启n个`goroutines`初始化一个`singleton`对象, 显然会初始化成功最少一个最多n个`singleton`对象，从而会存在潜在的多个单例实例对象了，也就不可能保证这个`singleton`对象全局唯一性了，那后继采用`singleton`对象进行全局唯一性操作时势必会造成数据不一致的问题。如果场景中但个`goroutines`执行时间短的话，会使得调试更难。

## 采用互斥锁机制
面对上述线程安全问题，一般会考虑到用锁机制(`Mutex`)来解决因线程安全引入的数据不一致问题，采用锁机制如：
```golang 
var mu Sync.Mutex

func GetInstance() *singleton {
    mu.Lock()                    // singleton实例对象操作之后，锁就是多余的了 
    defer mu.Unlock()

    if instance == nil {
        instance = &singleton{}
    }
   return instance
}
```
上述代码可以看到，引入锁机制`Sync.Mutex`后，能够保证多线程并行执行`goroutines`创建的`singleton`实例对象是唯一的，但是当这个`singleton`实例对象被初始化创建之后，再次并行来创建`singleton`实例对象时，其实已经不再需要锁了，因为已经存在了一个创建好的`singleton`实例对象，所以直接返回即可;但是因为锁机制的存在，使得再次创建`singleton`实例对象时，还是需要先获取锁，然后在判断处理，多线程执行中这种锁竞争使得多线程的并行执行变成了多线程的串行执行，这显然会使程序丧失并行执行带来的性能提升。在一个高度并行的程序中，这样显示会是抑制程序性能提升的一个瓶颈。

## 采用双重检查锁机制
在`C++`等编程语言中，为了同时保证最小锁和线程安全通常采用的方法是`双重检查锁(Check-Lock-Check)`机制，也表述为`DCL(Double Check Lock)`。`双重检查锁`机制的伪代码一般是下面的这种形式:
```golang
if check() {
    lock() {
       if check() {
           // 锁安全代码 
        }
    }
}
```
其实对这个`singleton`实例对象来说，只有在第一次创建实例的时候才需要同步，所以为了减少同步，先check一下，判断`singleton`实例对象是否为空，如果为空，表示是第一使用这个`singleton`实例对象，那就锁住它，new一个`singleton`实例，下次另一个线程来`GetInstance`的时候，看到这个`singleton`实例对象不为空，就表示已经创建过一个实例了，那就可以直接得到这个实例，避免再次锁。这是第一个 check的作用。 

第二个check是解决锁竞争情况下的问题，假设现在两个线程来请求`GetInstance`，A、B线程同时发现`singleton`实例对象为空，因为我们在第一次check方法上没有加锁，然后A线程率先获得锁，进入同步代码块，new了一个`singleton`实例对象，之后释放锁，接着B线程获得了这个锁，发现`singleton`实例对象已经被创建了，就直接释放锁，退出同步代码块。所以这就是`Check-Lock-Check`; 将上面的`singleton`实例用`Check-Lock-Check`机制实现如：
```golang
func GetInstance() *singleton {
    if instance == nil { 
        mu.Lock()
        defer mu.Unlock()

        if instance == nil {
	            instance = &singleton{}
        }
    }
    return instance
}
```
通过上面的`Check-Lock-Check`机制,的确可以解决锁竟争的问题，但是这种方法不管是否`singleton`实例对象是否已创建，每次都要执行两次check才是一个完整的判断，那有没有方法使得只要一次check就可以完成对`singleton`实例对象是否存在的检查呢？ 有！通过`golang`的`sync/atomic`包提供的原子性操作可以更高效的完成这个检查，改进代码如：
```golang
import "sync"
import "sync/atomic"

var initialized uint32
...

func GetInstance() *singleton {

   if atomic.LoadUInt32(&initialized) == 1 {
		return instance
	}

    mu.Lock()
    defer mu.Unlock()

    if initialized == 0 {
         instance = &singleton{}
         atomic.StoreUint32(&initialized, 1)
	}

	return instance
}
```
改进之后的代码通过设置一个标志操作，使得`singleton`实例对象创建之后，直接通过原子操作读取标志字段的值判断返回已经存在的实例，连锁操作及其后面的代码都略过了。

## 采用atomic进一步简化
上面通过`Check-Lock-Check`机制改进之后似乎没有什么可做的了，先不急，来看看`golang`原生标准包`sync`包中对`Once`实现的源码：
```golang
// Once is an object that will perform exactly one action.
type Once struct {
	m    Mutex
	done uint32
}

// Do calls the function f if and only if Do is being called for the
// first time for this instance of Once. In other words, given
//	var once Once
// if once.Do(f) is called multiple times, only the first call will invoke f,
// even if f has a different value in each invocation.  A new instance of
// Once is required for each function to execute.
//
// Do is intended for initialization that must be run exactly once.  Since f
// is niladic, it may be necessary to use a function literal to capture the
// arguments to a function to be invoked by Do:
//	config.once.Do(func() { config.init(filename) })
//
// Because no call to Do returns until the one call to f returns, if f causes
// Do to be called, it will deadlock.
//
// If f panics, Do considers it to have returned; future calls of Do return
// without calling f.
//
func (o *Once) Do(f func()) {
	if atomic.LoadUint32(&o.done) == 1 { // <-- Check
		return
	}
	// Slow-path.
	o.m.Lock()                           // <-- Lock
	defer o.m.Unlock()
	if o.done == 0 {                     // <-- Check
		defer atomic.StoreUint32(&o.done, 1)
		f()
	}
}
```
可以看到我们之前其实是借鉴了`golang`原生标准包`sync`中对`Once`实现对源码，那既然标准包中已经实现了这个`Check-Lock-Check`机制，那我们直接调用`sync`包提供`once.Do()`方法对某个方法只进行一次性调用：
```golang
once.Do(func() {
	 // perform safe initialization here
}
```
那么下面是根据`sync`包提供的`sync.Once`改进的获取`singleton`实例对象最终优化版本:
```golang
package singleton

import (
    "sync"
)

type singleton struct {
}

var instance *singleton
var once sync.Once

func GetInstance() *singleton {
    once.Do(func() {
        instance = &singleton{}
    })
    return instance
}
```
因此使用`sync`包提供的`sync.Once`实现获取`singleton`实例对象可以说是最安全有效又简洁的方法。
