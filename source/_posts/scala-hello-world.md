---
title: "scala 入门之HelloWorld" 
date: 2019-11-07 17:29:56
categories: java
tags: scala
description:
---
Scala是一门混合了函数式和面向对象的语言。用Scala创建多线程应用时，你会倾向于函数 式编程风格，用不变状态(immutable state)1编写无锁(lock-free)代码。
<!--more-->
Scala提供一个基于actor的消息传递(message-passing)模型，消除了涉及并发的痛苦问题。运用这个模型，可以写出简洁的多线程代码，而无需顾虑线程间的数据竞争，以及处理加锁和释放带来的梦魇;

#### HelloWorld from scala
```
➜  cat HelloWorld.scala
object HelloWorld {
  def main(args: Array[String]) {
    println("Hello, Scala的HelloWorld的程序!")
  }
}
➜  scalac HelloWorld.scala
➜  scala HelloWorld
Hello, Scala的HelloWorld的程序!
```

