---
title: "从生产者消费者模型深入学习golang channel"
date: 2018-11-08 19:53:14
categories: [golang]
tags: [golang, channel]
description:
---
从生产者消费者模型探究回顾golang channel注意事项; 实例探究no buffer及buffer channel;
<!--more-->

## channel 
golang channel 分为无缓冲channel及缓冲channel, 具体体现在创建channel时是否制定channel size, 

```golang
//no buffer channel
ch := make(chan int)

//buffer channel
ch := make(chan int bufSize)
```
- 无缓冲channel 默认channel大小为1, 写入一个值后需要被读取之后才能继续写入, 否则写阻塞;
- 缓冲channel 的大小是初始时者的bufSize, 可连续写入bufSize值, 然后等待读取, 当len(channel) < bufSize时才可以继续写入, 否则写阻塞;
- channel 中没有值时 则读阻塞;
- channel 常用在同步, pipe, 无锁设计等场景中;

### 写值

```golang 
 ch <- in 
```
- 非写阻塞时可以写入值;

### 读值

```golang
out := <-ch 

out, ok := <- ch
```
- 非读阻塞时可以读取值;
- 当ok 为false时, 表示channel已被关闭;

### 关闭

```golang 
close(ch)
```
- 只要当写channel写入完毕后则应立即关闭channel; 而管道则不需要处理;

> 更多参考[Range and close](https://tour.golang.org/concurrency/4)

### for循环读

```golang 
for x := range ch {
        //do something with x
 }
```

- 当使用for range 从管道读取数据的时候，管道没有数据，那么循环会阻塞，只有当管道被关闭的时候，for 循环才会结束

## 生产者消费者模型

```golang
//producer_consumer.go
const (
	N = 100000
)

func Producer(out chan<- int) {
	for i := 1; i < N; i++ {
		out <- i
	}
	close(out)
}

func Consumer(in <-chan int, out chan<- int) {
	for x := range in {
		out <- x
	}
	close(out)
}
```

测试case 

```golang
//producer_consumer_test.go
func producerconsumer(in chan int, out chan int) {
	go Producer(in)
	go Consumer(in, out)

	for x := range out {
		_ = x
	}
}

func TestNoBufferChan(t *testing.T) {
	in, out := make(chan int), make(chan int)
	producerconsumer(in, out)
}

func TestBufferChan(t *testing.T) {
	bufLen := 100
	in, out := make(chan int, bufLen), make(chan int, bufLen)
	producerconsumer(in, out)
}

func BenchmarkNoBufferChan(b *testing.B) {
	for i := 0; i < b.N; i++ {
		in, out := make(chan int), make(chan int)
		producerconsumer(in, out)
	}
}

func BenchmarkBufferChan(b *testing.B) {
	for i := 0; i < b.N; i++ {
		bufLen := 100
		in, out := make(chan int, bufLen), make(chan int, bufLen)
		producerconsumer(in, out)
	}
}
```

output 

```shell
➜  make bench
[Benchmark] running Benchmark
=== RUN   TestCloseWriteChanException
--- PASS: TestCloseWriteChanException (2.01s)
=== RUN   TestCloseReadChanException
--- PASS: TestCloseReadChanException (1.00s)
=== RUN   TestNoBufferChan
--- PASS: TestNoBufferChan (0.09s)
=== RUN   TestBufferChan
--- PASS: TestBufferChan (0.02s)
goos: darwin
goarch: amd64
pkg: github.com/researchlab/experiments/channel
BenchmarkNoBufferChan-8   	      20	  84429085 ns/op
BenchmarkBufferChan-8     	      50	  22295688 ns/op
PASS
ok  	github.com/researchlab/experiments/channel	6.045s
```

更多分析及完整源码可参见 [github-channel](https://github.com/researchlab/experiments/tree/master/channel)

## 总结
- 回顾了channel两种类型(no buffer/buffer channel);
- 只有写channel需要close, 而读channel 则可以不需要关心; 需要注意channel 在多个goroutine中的close问题;
- channel 是非常常用的一种结果, 常见于业务同步, buffer pipe, timeout, 无锁设计等场景中; 
