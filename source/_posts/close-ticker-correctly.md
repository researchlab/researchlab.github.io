---
title: "优雅的关闭ticker"
date: 2016-10-16 14:27:39
categories: golang
tags: ticker
description:
---

## 前言 
在`ticker`和`goroutine`组合使用中当调用`ticker.Stop()`关闭`ticker`之后，相应的`goroutine`中的`ticker.C`并没有停掉，下面总结一种优雅的方式关闭`ticker`.
<!--more-->

## 优雅的关闭`ticker`
```golang
package main
import (
	"fmt"
	"time"
)

func main() {
	Demo()
}

func Demo() {
	done := startTicker(PrintInfo)
	time.Sleep(time.Duration(12) * time.Second)
	close(done)
	time.Sleep(time.Duration(1) * time.Minute)
	fmt.Println("main finished")
}

func startTicker(f func()) chan struct{} {
	done := make(chan struct{}, 1)
	go func() {
		ticker := time.NewTicker(5 * time.Second)
		//	ticker := time.NewTicker(5 * time.Minute)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				f()
			case <-done:
				return
			}
		}
	}()
	return done
}

func PrintInfo() {
	fmt.Println("hello")
}
```

上述代码通过`startTicker`创建一个`ticker`, 当想要关闭这个`ticker`并同时退出对应`goroutine`中的`for`时，可以直接`close()`，发送`done`信号直接返回退出`startTicker`即可.

