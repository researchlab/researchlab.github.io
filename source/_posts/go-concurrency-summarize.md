---
title: golang 并发concurrency 使用总结
date: 2016-02-17 13:47:51
categories: golang
tags: [golang, concurrency]
description:
---
## 前言
go能处理高并发的根本原因在于执行go协程只需极少的栈内存(大概4~5KB),并且能根据需要动态增长和缩减占用的资源。
<!--more-->
## 高并发的本质goroutine
简单而言,`goroutine`就是一段代码，一个函数入口，以及在堆上为其分配的一个堆栈。所以它非常廉价，我们可以很轻松的创建上万个`goroutine`，但它们并不是被操作系统所调度执行,而是通过系统的线程来多路派遣这些函数的执行，使得每个用go关键字执行的函数可以运行成为一个单位协程。当一个协程阻塞的时候，调度器就会自动把其他协程安排到另外的线程中去执行，从而实现了程序无等待并行化运行。而且调度的开销非常小，一颗CPU调度的规模不下于每秒百万次，这使得在程序中能够创建大量的`goroutine`，实现高并发的同时，依旧能保持高性能。
`goroutine`是通过通信来共享内存,go中是通过`Channel`来实现通信的，`Channel`本身就像一根管道，go就通过这根管道进行数据的传递,实现消息通信。先来看一个简单的示例：
```golang
	c := make(chan bool)
	go func() {
		fmt.Println("Go concurrency")
		c <- true
		close(c)
	}()

	for  v := range c {
		fmt.Println(v)
	}
```
- 上面的代码首先创建一个`bool`的`Channel`对象`c`,然后通过`go`关键字执行一个`goroutine`,紧接着执行一个`for`循环;`for`会循环去读取`c`中的值，如果读取到值，则执行`for`循环体（打印v的值），没读取到则`for`被阻塞等待,直到读取到`c`中的值再去执行`for`循环体然后继续循环读取`c`，如果执行了`close(c)`把`Channel`对象`c`关闭了，那`for`循环就退出不执行了。 这就是通过`Channel`通信执行`goroutine`的一个简单示例。
- 上面通过make这样初始化的`Channel`对象`c`是既可以写又可以被读取的双向通道, 有时候为了避免被误读误写操作，可以初始化一个单向的`Channel`对象。通过设置`Channel`的长度可以分为有缓冲和无缓冲两种`Channel`,无缓冲区的`Channel`,在等待读或等待写的过程中都会引起`同步阻塞`，而有缓冲区的`Channel`,可以看作`异步执行`,也可以认为控制为`同步执行`，只有当缓冲区被占用完了之后才会引起`阻塞`。
```golang		
		c := make(chan int, 3)  //初始化缓冲区长度为3的Channel
		var send chan<- int = c //只写入的Channel
		var recv <-chan int = c //只读取的Channel
```
	** 注意: **  只读或只写的单向`Channel` 都需要借助其它`Channel`才有实际意义，定义一个只写入但是读取不出来的`Channel`没有任何用处。单向`Channel`用作函数形参用于防止参数在函数内部被误读误写是非常有帮助的。

## 开启多核并行并发执行
默认情况下，go所有的`goroutines`是在一个线程中执行的，而不是同时利用多核进行并行执行，或者通过切换时间片让出CPU进行并发执行。下面看一段示例：
```golang
func main() {
	runtime.GOMAXPROCS(runtime.NumCPU())
	wg := sync.WaitGroup{}
	wg.Add(3)
	for i := 0; i < 3; i++ {
		go GoPrint(&wg)
	}

	wg.Wait()
}

func GoPrint(wg *sync.WaitGroup) {
	for i := 0; i < 3; i++ {
		time.Sleep(time.Second)
		fmt.Printf("%d ", i)

	}
	wg.Done()
}
```
目前只有显示设置了`runtime.GOMAXPROCS`,go才会开启多核并行执行`goroutines`, 如果在`GoPrint`方法中不加入`time.Sleep`，输出的结果将会是`0 1 2 0 1 2 0 1 2`，如果当前`goroutine`不发生阻塞，它是不会让出CPU给其他`goroutine`的, 所以在`GoPrint`中不加`time.Sleep`,输出会是一个一个`goroutine`进行的，而sleep函数则阻塞掉了 当前`goroutine`, 当前`goroutine`主动让其他`goroutine`执行, 所以形成了逻辑上的并行, 也就是并发。

## go并发执行安全问题
go并发执行当多个`goroutine`同时访问一个共有的资源时，在不加锁的情况很容易出行数据不同步的问题，看一示例:
```golang
func sell_tickets(wg *sync.WaitGroup, i int) {

	for total_tickets > 0 {

		mutex.Lock()
		// 如果有票就卖
		if total_tickets > 0 {
			time.Sleep(time.Duration(rand.Intn(5)) * time.Millisecond)
			// 卖一张票
			total_tickets--
			fmt.Println("id:", i, " ticket:", total_tickets)
		}
		mutex.Unlock()
	}
	wg.Done()
}
```
上面是一个多`goroutine`并发买票的问题，比如当开启5个`goroutine`来卖100张票，如果不加锁，则有可能会出行多出一些不存在的票的问题。所以当并发访问公有资源时要注意加锁保护公有资源属性修改的唯一性和访问时数据同步问题。
[示例代码](https://github.com/researchlab/golearning/blob/master/concurrency/concurrency_sync_mutex.go)

## 批量处理多个Channel操作
go通过`Select`可以同时处理多个`Channel`,`Select`默认是阻塞的，只有当监听的`Channel`中有发送或接收可以进行时才会运行,当同时有多个可用的`Channel`,`Select`按随机顺序进行处理,`Select`可以方便处理多`Channel`同时响应，在goroutine阻塞的情况也可以方便借助`Select`超时机制来解除阻塞僵局，下面来看一个示例:
```golang
func getHttpRes(url string) (string, error) {
	res := make(chan *http.Response, 1)
	httpError := make(chan *error)
	go func() {
		resp, err := http.Get(url)
		if err != nil {
			httpError <- &err
		}
		res <- resp
	}()

	for {
		select {
		case r := <-res:
			result, err := ioutil.ReadAll(r.Body)
			defer r.Body.Close()
			return string(result), err
		case err := <-httpError:
			return "err", *err
		case <-time.After(2000 * time.Millisecond):
			return "Timed out", errors.New("Timed out")
		}
	}

}
```
发起http请求之后通常会有三种状况:1.访问成功，返回内容值;2.访问失败，返回错误信息;3.访问超时，返回超时。上面的代码中利用`Select`很方便的处理了go并发执行中多可用`Channel`的处理问题，通过设置超时，帮助程序跳出超时等待的僵局。
[示例代码](https://github.com/researchlab/golearning/blob/master/concurrency/select_timeout.go)
