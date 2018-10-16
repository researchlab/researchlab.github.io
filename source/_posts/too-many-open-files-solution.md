---
title: "linux too many open files 问题解决总结" 
date: 2017-01-14 10:58:37
categories: [DevOps]
tags: [linux]
description:
---

运行在Linux系统上的网络程序可能会出现"Too many open files"的异常情况，且常见于高并发访问文件系统，多线程网络连接等场景。 
<!--more-->

## 概念

程序经常访问的文件、socket等在Linux中都是指的文件file，系统需要记录每个当前访问file的name、location、access authority等相关信息，这样的一个实体被称为file entry。`open files table`存储这些file entry，以数组的形式线性管理。文件描述符(file descriptor)是作为`进程`到`open files table`的指针，也就是`open files table`的下标索引，将每个进程与它所访问的文件关联起来了。 

<center>![too many open files theory](too-many-files.jpg)</center>

 每个进程中都有一个`file descriptor table`管理当前进程所访问(open or create)的所有文件file，文件描述符关联着`open files table`中文件的file entry。对于`open files table`能容纳多少file entry, 可由Linux系统配置`open files table`的文件限制，如果超过配置值，就会拒绝其它文件操作的请求，并抛出Too many open files异常。这种限制有系统级和用户级之分。 

- 系统级：
	系统级设置对所有用户有效。可通过两种方式查看系统最大文件限制 
	1  cat /proc/sys/fs/file-max
	2  sysctl -a 查看结果中fs.file-max这项的配置数量 
	如果需要增加配置数量就修改/etc/sysctl.conf文件，配置fs.file-max属性，如果属性不存在就添加, 配置完成后使用sysctl -p来通知系统启用这项配置 

- 用户级：
	Linux限制每个登录用户的可连接文件数。可通过`ulimit -n`来查看当前有效设置。如果想修改这个值就使用`ulimit -n <setting number>`命令。 
    对于文件描述符增加的比例，资料推荐是以2的幂次为参考。如当前文件描述符数量是1024，可增加到2048，如果不够，可设置到4096，依此类推。 
	在出现Too many open files问题后，首先得找出主要原因。最大的可能是打开的文件或是socket没有正常关闭。为了定位问题是否由目标网络进程引起，通过目标网络程序进程号查看当前进程占用文件描述符情况： 
```bash
	lsof -p $target_pid #每个文件描述符的具体属性
	lsof -p $target_pid | wc -l  #当前目标网络进程file descriptor table中FD的总量
```

## 解决方案总结

方案一:

查看系统许可的最大文件限制， 如果不够可以修改此值。
```bash
[root nginx]# cat /proc/sys/fs/file-max
8096
```

文件系统最大可打开文件数
```bash
[root nginx]# ulimit -n
1024
```
程序限制只能打开1024个文件

使用[root nginx]# ulimit -n 8096调整一下
或者永久调整打开文件数 可在启动文件/etc/rc.d/rc.local末尾添加（在/etc/sysctl.conf末尾添加fs.file-max=xxx无效）
ulimit -n 8096 

方案二:

Linux内核有时会报告`Too many open files`，起因是file-max默认值（8096）太小, 要解决这个问题，可以root身份执行下列命令（或将它们加入/etc/rcS.d/*下的init脚本。）

```bash
echo "65536"  > /proc/sys/fs/file-max  # 适用于2.2和2.4版内核
#或者
echo "131072" > /proc/sys/fs/inode-max # 仅适用于2.2版内核
```

方案三:

办法是修改操作系统的打开文件数量限制，方法如下:

1.按照最大打开文件数量的需求设置系统，并且通过检查/proc/sys/fs/file-max文件来确认最大打开文件数已经被正确设置。 

```bash
cat /proc/sys/fs/file-max
```

如果设置值太小， 修改文件/etc/sysctl.conf的变量到合适的值。 这样会在每次重启之后生效。(如果设置值够大，跳过下步)

```bash
 echo 2048 > /proc/sys/fs/file-max
```

编辑文件/etc/sysctl.conf，整体修改如下:

```bash
#kernel2.6之后的内核版本添加如下配置：                                                                                                                                                                          
net.nf_conntrack_max = 3276800                                                                                                                                                                                  
net.netfilter.nf_conntrack_tcp_timeout_established = 1200                                                                                                                                                       
                                                                                                                                                                                                                
#当出现SYN等待队列溢出时，启用cookies来处理，可防范少量SYN攻击，默认为0，表示关闭                                                                                                                               
net.ipv4.tcp_syncookies = 1                                                                                                                                                                                     
#开启TCP连接中TIME-WAIT sockets的快速回收，默认为0，表示关闭。                                                                                                                                                  
net.ipv4.tcp_tw_recycle = 1                                                                                                                                                                                     
#开启重用，将TIME-WAIT sockets重新用于新的TCP连接，默认为0，表示关闭；                                                                                                                                          
net.ipv4.tcp_tw_reuse = 1                                                                                                                                                                                       
#修改系統默认的 TIMEOUT 时间                                                                                                                                                                                    
net.ipv4.tcp_fin_timeout = 25                                                                                                                                                                                   
net.ipv4.tcp_orphan_retries = 1                                                                                                                                                                                 
net.ipv4.tcp_max_orphans = 8192                                                                                                                                                                                 
net.ipv4.ip_local_port_range = 32768 61000                                                                                                                                                                      
                                                                                                                                                                                                                
# Disabled ipV6                                                                                                                                                                                                 
net.ipv6.conf.all.disable_ipv6 = 1                                                                                                                                                                              
net.ipv6.conf.default.disable_ipv6 = 1                                                                                                                                                                          
net.ipv6.conf.lo.disable_ipv6 = 1                                                                                                                                                                               
```

2.在/etc/security/limits.conf文件中设置最大打开文件数，添加如下这行:

```bash
* - nofile 8192
```

这行设置了每个用户的默认打开文件数为2048。注意`nofile`项有两个可能的限制措施。就是项下的hard和soft, 要使修改过的最大打开文件数生效，必须对这两种限制进行设定。 如果使用"-"字符设定, 则hard和soft设定会同时被设定。硬限制表明soft限制中所能设定的最大值。soft限制指的是当前系统生效的设置值。hard限制值可以被普通用户降低, 但是不能增加。soft限制不能设置的比hard限制更高。只有root用户才能够增加hard限制值。当增加文件限制描述，可以简单的把当前值双倍。 例: 如果你要提高默认值1024， 最好提高到2048， 如果还要继续增加， 就需要设置成4096。
另外一种情况是在创建索引的时候，也有两种可能，一种是合并因子太小，导致创建文件数量超过操作系统限制，这时可以修改合并因子，也可以修改操作系统的打开文件数限制；另外一种是合并因子受虚拟机内存的限制，无法调整到更大，而需要索引的doc数量又非常的大，这个时候就只能通过修改操作系统的打开文件数限制来解决了。

在此基础上，我还修改了以下一个配置文件

vim /etc/sysctl.conf, 添加：

```bash
# Decrease the time default value for tcp_fin_timeout connection
net.ipv4.tcp_fin_timeout = 30
# Decrease the time default value for tcp_keepalive_time connection
net.ipv4.tcp_keepalive_time = 1800
# Turn off tcp_window_scaling
net.ipv4.tcp_window_scaling = 0
# Turn off the tcp_sack
net.ipv4.tcp_sack = 0
#Turn off tcp_timestamps
net.ipv4.tcp_timestamps = 0
```

然后 service network restart, 这些都和`TCP sockets`有关的优化。

另外需要在 /etc/rc.d/rc.local里添加已使得重启的时候生效。

```bash
echo "30">/proc/sys/net/ipv4/tcp_fin_timeout
echo "1800">/proc/sys/net/ipv4/tcp_keepalive_time
echo "0">/proc/sys/net/ipv4/tcp_window_scaling
echo "0">/proc/sys/net/ipv4/tcp_sack
echo "0">/proc/sys/net/ipv4/tcp_timestamps
```

因为不是所有的程序都在root下跑的，所有linux有对hard与soft open files的区分，普通用户受hard的限制，无论ulimit -n $数值调到多高，都跑不到 /etc/security/limits.conf里nofile的值。

这样的优化后 lsof -p $target_pid|wc -l可以跑到4千以上都不会抛出too many open files。
