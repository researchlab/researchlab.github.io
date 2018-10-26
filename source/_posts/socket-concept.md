---
title: "Socket套接字概念"
date: 2018-09-20 19:32:29
categories: [DevOps]
tags: [socket]
description:
---
套接字是一种通信机制(通信的两方的一种约定), 凭借这种机制, 不同主机之间的进程可以进行通信。下面通过套接字中的相关函数来进一步学习理解通信过程;
<!--more-->

##### 套接字
* * * 
套接字有域(domain), 类型(type), 和协议(protocol)三个属性;

- 域
> 域指定套接字通信中使用的网络介质。最常见的套接字域是 AF_INET, 它是指 Internet 网络, 许多 Linux 局域网使用的都是该网络, 当然, 因特网自身用的也是它。



- 套接字类型

|套接字类型|说明|
|:---|:---|
|流套接字(SOCK_STREAM)|流套接字用于提供面向连接、可靠的数据传输服务。该服务将保证数据能够实现无差错、无重复发送, 并按顺序接收。流套接字之所以能够实现可靠的数据服务, 原因在于其使用了传输控制协议, 即TCP(The Transmission Control Protocol)协议。|
|数据报套接字(SOCK_DGRAM)|数据报套接字提供了一种无连接的服务。该服务并不能保证数据传输的可靠性, 数据有可能在传输过程中丢失或出现数据重复, 且无法保证顺序地接收到数据。数据报套接字使用UDP(User Datagram Protocol)协议进行数据的传输。由于数据报套接字不能保证数据传输的可靠性, 对于有可能出现的数据丢失情况, 需要在程序中做相应的处理。|
|原始套接字(SOCK_RAW)|原始套接字与标准套接字(标准套接字指的是前面介绍的流套接字和数据报套接字)的区别在于: 原始套接字可以读写内核没有处理的IP数据包, 而流套接字只能读取TCP协议的数据, 数据报套接字只能读取UDP协议的数据。因此, 如果要访问其他协议发送数据必须使用原始套接字。|

- 套接字协议(协议类别)
> 只要底层的传输机制允许不止一个协议来提供要求的套接字类型, 我们就可以为套接字选择一个特定的协议。通常使用默认即可(也就是最后一个参数填"0")。

##### 创建套接字
* * *
socket系统调用创建一个套接字并返回一个描述符, 该描述符可以用来访问该套接字。
```shell
#include <sys/socket.h>
int socket(int family,int type,int protocol);
```
**功能**
创建一个用于网络通信的 socket 套接字(描述符)

**参数**
family: 协议族(AF_UNIX、AF_INET、AF_INET6、PF_PACKET等)

> 最常见的套接字域是 AF_UNIX 和 AF_INET, 前者用于通过 Unix 和 Linux 文件系统实现的本地套接字, 后者用于 Unix 网络套接字。AF_INET 套接字可以用于通过包括因特网在内的 TCP/IP 网络进行通信的程序。微软 Windows 系统的 winsock 接口也提供了对这个套接字域的访问功能。

```shell
/*
 * Address families.
 */
#define AF_UNSPEC       0               /* unspecified */
#define AF_UNIX         1               /* local to host (pipes, portals) */
#define AF_INET         2               /* internetwork: UDP, TCP, etc. */
#define AF_IMPLINK      3               /* arpanet imp addresses */
#define AF_PUP          4               /* pup protocols: e.g. BSP */
#define AF_CHAOS        5               /* mit CHAOS protocols */
#define AF_IPX          6               /* IPX and SPX */
#define AF_NS           6               /* XEROX NS protocols */
#define AF_ISO          7               /* ISO protocols */
#define AF_OSI          AF_ISO          /* OSI is ISO */
#define AF_ECMA         8               /* european computer manufacturers */
#define AF_DATAKIT      9               /* datakit protocols */
#define AF_CCITT        10              /* CCITT protocols, X.25 etc */
#define AF_SNA          11              /* IBM SNA */
#define AF_DECnet       12              /* DECnet */
#define AF_DLI          13              /* Direct data link interface */
#define AF_LAT          14              /* LAT */
#define AF_HYLINK       15              /* NSC Hyperchannel */
#define AF_APPLETALK    16              /* AppleTalk */
#define AF_NETBIOS      17              /* NetBios-style addresses */
#define AF_VOICEVIEW    18              /* VoiceView */
#define AF_FIREFOX      19              /* FireFox */
#define AF_UNKNOWN1     20              /* Somebody is using this! */
#define AF_BAN          21              /* Banyan */
#define AF_MAX          22
```

type: 套接字类型(SOCK_STREAM、SOCK_DGRAM、SOCK_RAW等)
```shell
/*
 * Types
 */
#define SOCK_STREAM     1               /* stream socket */
#define SOCK_DGRAM      2               /* datagram socket */
#define SOCK_RAW        3               /* raw-protocol interface */
#define SOCK_RDM        4               /* reliably-delivered message */
#define SOCK_SEQPACKET  5               /* sequenced packet stream */
```

protocol: 协议类别(0、IPPROTO_TCP、IPPROTO_UDP等), 设为 0 表示使用默认协议。

**返回**

|状态|返回值|
|:---|:---|
|成功| 套接字|
|失败|(<0) |

Reference
* * * 
[1] [Linux 网络编程——套接字的介绍](https://blog.csdn.net/tennysonsky/article/details/45047209)
