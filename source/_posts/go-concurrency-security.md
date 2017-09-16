---
title: "golang 并发安全性案例分析"
date: 2016-02-24 21:47:55
categories: [golang]
tags: [golang,concurrency]
description:
---

`golang` 在1.5版本之前默认只使用一个核心来跑所有的`goroutines`,即`GOMAXPROCS`默认设置为1, ,即是串行执行`goroutines`,在1.5版本后，`GOMAXPROCS`默认设置为当前计算机真实的核心线程数，即是在并行执行`goroutines`。
<!--more-->

## 并行执行安全性案例分析
利用计算机多核处理的特性，并行执行能成倍的提高程序的性能,但同时也带入了数据安全性问题，下面看一个在线银行转账的案例:
```golang
type User struct {
		Cash int
}

func (u *User) sendCash(to *User, amount int) bool {
	if u.Cash < amount {
		return false
	}
	/* 设置延迟Sleep，当多个goroutines并行执行时,便于进行数据安全分析 */
	time.Sleep(500 * time.Millisecond)
	u.Cash = u.Cash - amount
	to.Cash = to.Cash + amount
	return true
}

func main() {
	me := User{Cash: 500}
	you := User{Cash: 500}
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		me.sendCash(&you, 50) //转账
		fmt.Fprintf(w, "I have $%d\n", me.Cash)
		fmt.Fprintf(w, "You have $%d\n", you.Cash)
		fmt.Fprintf(w, "Total transferred: $%d\n", (you.Cash - 500))
	})
	http.ListenAndServe(":8080", nil)
}
```
这是一个通用的Go Web应用，定义User数据结构，sendCash是在两个User之间转账的服务，这里使用的是net/http 包，我们创建了一个简单的Http服务器，然后将请求路由到转账50元的sendCash方法，在正常操作下，代码会如我们预料一样运行，每次转移50美金，一旦一个用户的账户余额达到0美金，就不能再进行转出钞票了，因为没有钱了，但是，如果我们很快地发送很多请求，这个程序会继续转出很多钱，导致账户余额为负数。

这是课本上经常谈到的竞争情况race condition，在这个代码中，账户余额的检查是与从账户中取钱操作分离的，我们假想一下，如果一个请求刚刚完成账户余额检查，但是还没有取钱，也就是没有减少账户余额数值；而另外一个请求线程同时也检查账户余额，发现账户余额还没有剩为零（结果两个请求都一起取钱，导致账户余额为负数），这是典型的”check-then-act”竞争情况。这是很普遍存在的 并发 bug。

## 用锁解决竟态数据安全问题

那么我们如何解决呢？我们肯定不能移除检查操作，而是确保检查和取钱两个动作之间没有任何其他操作发生，其他语言是使用锁，当账户进行更新时，锁住禁止同时有其他线程操作，确保一次只有一个进程操作，也就是排斥锁Mutex。,下面用`golang`自带的`sync`包实现对转账判断及数据操作过程的加锁：
```golang
type User struct {
		Cash int
}

var transferLock *sync.Mutex

func (u *User) sendCash(to *User, amount int) bool {

	transferLock.Lock() //对转账操作进行加锁
	defer transferLock.Unlock() //转账结束后解锁释放资源
	if u.Cash < amount {
		return false
	}
	/* 设置延迟Sleep，当多个goroutines并行执行时,便于进行数据安全分析 */
	time.Sleep(500 * time.Millisecond)
	u.Cash = u.Cash - amount
	to.Cash = to.Cash + amount
	return true
}
func main() {
	me := User{Cash: 500}
	you := User{Cash: 500}
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		me.sendCash(&you, 50) //转账
		fmt.Fprintf(w, "I have $%d\n", me.Cash)
		fmt.Fprintf(w, "You have $%d\n", you.Cash)
		fmt.Fprintf(w, "Total transferred: $%d\n", (you.Cash - 500))
	})
	http.ListenAndServe(":8080", nil)
}
```

## 利用Channel,更好的实现并发

但是锁的问题很显然降低了`程序并发的性能`，锁是并发设计的最大敌人，在Go中推荐使用通道`Channel`，能够使用事件循环event loop机制更灵活地实现并发;通过委托一个后台协程监听通道，当通道中有数据时，立即进行转账操作，因为协程是顺序地读取通道中的数据，也就是巧妙地回避了竞争情况，没有必要使用任何状态变量防止`并发`竞争了。 具体示例:
```golang
type User struct {
	Cash int
}
type Transfer struct {
	Sender    *User
	Recipient *User
	Amount    int
}

func sendCashHandler(transferchan chan Transfer) {
	var val Transfer
	for {
		val = <-transferchan
		val.Sender.sendCash(val.Recipient, val.Amount)
	}
}

func (u *User) sendCash(to *User, amount int) bool {
	if u.Cash < amount {
		return false
	}
	/* 设置延迟Sleep，当多个goroutines并行执行时,便于进行数据安全分析 */
	time.Sleep(500 * time.Millisecond)
	u.Cash = u.Cash - amount
	to.Cash = to.Cash + amount
	return true
}

func main() {
	me := User{Cash: 500}
	you := User{Cash: 500}
	transferchan := make(chan Transfer)
	go sendCashHandler(transferchan)
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		transfer := Transfer{Sender: &me, Recipient: &you, Amount: 50}
		transferchan <- transfer
		fmt.Fprintf(w, "I have $%d\n", me.Cash)
		fmt.Fprintf(w, "You have $%d\n", you.Cash)
		fmt.Fprintf(w, "Total transferred: $%d\n", (you.Cash - 500))
	})
	http.ListenAndServe(":8080", nil)
}
```

上面这段代码创建了比较可靠的系统从而避免了`并发`竞争，但是我们会带来另外一个安全问题：`DoS(Denial of Service服务拒绝)`，如果我们的转账操作慢下来，那么不断进来的请求需要等待进行转账操作的那个协程从通道中读取新数据，但是这个线程忙于照顾转账操作，没有闲功夫读取通道中新数据，这个情况会导致系统容易遭受`DoS攻击`，外界只要发送大量请求就能让系统停止响应。

## 祭出select 进一步提升性能
一些基础机制比如buffered channel可以处理这种情况，但是buffered channel是有内存上限的，不足够保存所有请求数据，优化解决方案是使用Go杰出的`select`语句：
```golang
http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
	 transfer := Transfer{Sender: &me, Recipient: &you, Amount: 50}
	 /*转账*/
	 result := make(chan int)
	 go func(transferchan chan<- Transfer, transfer Transfer, result chan<- int) {
	      transferchan <- transfer
	      result <- 1
	 }(transferchan, transfer, result)

	/*用select来处理超时机制*/	 
	 select {
	   case <-result:
	    fmt.Fprintf(w, "I have $%d\n", me.Cash)
	    fmt.Fprintf(w, "You have $%d\n", you.Cash)
	    fmt.Fprintf(w, "Total transferred: $%d\n", (you.Cash - 500))
	  case <-time.After(time.Second * 10): //超时处理
	    fmt.Fprintf(w, "Your request has been received, but is processing slowly")
	 }
})
```
这里提升了事件循环，等待不能超过10秒，等待超过timeout时间，会返回一个消息给User告诉它们请求已经接受，可能会花点时间处理，请耐心等候即可，使用这种方法我们降低了`DoS攻击`可能，一个真正健壮的能够`并发`处理转账且没有使用任何锁的系统诞生了。
