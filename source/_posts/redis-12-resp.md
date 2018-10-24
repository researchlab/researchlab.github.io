---
title: "redis专题12 redis通信协议"
date: 2018-10-24 15:34:03
categories: "redis专题"
tags: [redis]
description:
---
Redis的客户端与服务端采用一种叫做`RESP(REdis Serialization Protocol)`的网络通信协议交换数据。 这种协议采用明文传输，易读也易解析。`Redis`客户端采用此协议格式来对服务端发送不同的命令，服务端会根据具体的操作而返回具体的答复。客户端和服务端采用的是简单的`请求-响应`模型进行通信的。
<!--more-->

##### RESP
`RESP(Redis Serialization Protocol)`是 Redis序列化协议的简写。它是一种直观的文本协议，优势在于实现异常简单，解析性能极好。

Redis协议将传输的结构数据分为`5`种最小单元类型，单元结束时统一加上回车换行符号`\r\n`。
> 单行字符串 以`+`符号开头。
> 多行字符串 以`$`符号开头，后跟字符串长度。
> 整数值 以`:`符号开头，后跟整数的字符串形式。
> 错误消息 以`-`符号开头。
> 数组 以`*`号开头，后跟数组的长度。

**单行字符串** `hello world`
```shell
+hello world\r\n
```

**多行字符串** `hello world`
```shell
$11\r\nhello world\r\n
```
多行字符串当然也可以表示单行字符串。

**整数** `1024`
```shell
:1024\r\n
```
**错误** 参数类型错误
```shell
-WRONGTYPE Operation against a key holding the wrong kind of value\r\n
```

**数组** `[1,2,3]`
```shell
*3\r\n:1\r\n:2\r\n:3\r\n
```

`NULL`用多行字符串表示，不过长度要写成`-1`。
```shell
$-1\r\n
```

**空串** 用多行字符串表示，长度填`0`。
```shell
$0\r\n\r\n
```
**注:** 这里有两个`\r\n`。为什么是两个?因为两个`\r\n`之间,隔的是空串。

##### 客户端 -> 服务器
**客户端向服务器发送的指令只有一种格式，多行字符串数组**。比如一个简单的`set`指令`set learn redis`会被序列化成下面的字符串。
```shell
*3\r\n$3\r\nset\r\n$6\r\nlearn\r\n$8\r\nredis\r\n
```

##### 服务器 -> 客户端
服务器向客户端回复的响应要支持多种数据结构，所以消息响应在结构上要复杂不少。不过再复杂的响应消息也是以上`5`中基本类型的组合。

**1.单行字符串响应**
```shell
127.0.0.1:6379> set learn redis
OK
```
这里的`OK`就是单行响应，没有使用引号括起来。
```shell
+OK
```

**2.错误响应**
```shell
127.0.0.1:6379> incr learn 
(error) ERR value is not an integer or out of range
```
试图对一个字符串进行自增，服务器抛出一个通用的错误。
```shell
-ERR value is not an integer or out of range
```

**3.整数响应**
```shell
127.0.0.1:6379> incr books
(integer) 1
```
这里的`1`就是整数响应
```shell
:1
```

**4.多行字符串响应**
```shell
127.0.0.1:6379> get learn 
"redis"
```
<u>这里使用双引号括起来的字符串就是多行字符串响应</u>

**5.数组响应**
```shell
127.0.0.1:6379> hset shanghai num 021
(integer) 1
127.0.0.1:6379> hset shanghai date 10.1
(integer) 1
127.0.0.1:6379> hset shanghai abbr sh
(integer) 1
127.0.0.1:6379> hgetall shanghai
1) "num"
2) "021"
3) "date"
4) "10.1"
5) "abbr"
6) "sh"
```
这里的`hgetall`命令返回的就是一个数组，第`0|2|4`位置的字符串是`hash`表的`key`，第`1|3|5`位置的字符串是`value`，客户端负责将数组组装成字典再返回。


**6.嵌套**
```shell
127.0.0.1:6379> scan 0
1) "0"
2) 1) "shanghai"
   2) "learn"
```
`scan`命令用来扫描服务器包含的所有`key`列表，它是以游标的形式获取，一次只获取一部分。

`scan`命令返回的是一个嵌套数组。数组的第一个值表示游标的值，如果这个值为零，说明已经遍历完毕。如果不为零，使用这个值作为`scan`命令的参数进行下一次遍历。数组的第二个值又是一个数组，这个数组就是`key`列表。

##### 总结
- `Redis`协议里有大量冗余的回车换行符，但是这不影响它成为互联网技术领域非常受欢迎的一个文本协议。有很多开源项目使用`RESP`作为它的通讯协议。在技术领域性能并不总是一切，还有简单性、易理解性和易实现性，这些都需要进行适当权衡。

