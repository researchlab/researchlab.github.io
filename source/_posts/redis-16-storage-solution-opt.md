---
title: "redis专题16 数据持久化实践" 
date: 2018-10-13 19:12:11
categories: "redis专题"
tags: [redis]
description:
---

通过示例分析，深入了解`redis`数据持久化策略执行机制；
<!--more-->

##### 环境准备
***
```
➜ docker run -itd --name lredis -p7002:6379 -v ~/workbench/docker/redis/conf/redis.conf:/etc/redis/redis.conf redis redis-server /etc/redis/redis.conf
```

##### 版本日志
***
```
➜ docker logs -f lredis
1:C 24 Oct 2018 09:24:03.601 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
1:C 24 Oct 2018 09:24:03.602 # Redis version=5.0.0, bits=64, commit=00000000, modified=0, pid=1, just started
...
1:M 24 Oct 2018 09:24:03.606 # Server initialized
1:M 24 Oct 2018 09:24:03.606 # WARNING you have Transparent Huge Pages (THP) support enabled in your kernel. This will create latency and memory usage issues with Redis. To fix this issue run the command 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' as root, and add it to your /etc/rc.local in order to retain the setting after a reboot. Redis must be restarted after THP is disabled.
1:M 24 Oct 2018 09:24:03.606 * Ready to accept connections
```

##### RDB方式持久化
***
`Redis`默认的持久化方式是`RDB`，并且默认是打开的。`RDB`的保存有方式分为`主动保存`与`被动保存`。`主动保存`可以在`redis-cli`中输入`save`即可；`被动保存`需要满足配置文件中设定的触发条件，满足触发条件后，数据才会被保存为快照，正是因为这样才说`RDB`的数据完整性是比不上`AOF`;
触发保存条件后，会在指定的目录生成一个名为`dump.rdb`的文件，等到下一次启动`Redis`时，`Redis`会去读取该目录下的`dump.rdb`文件，将里面的数据恢复到`Redis`;

`dump.rdb`文件路径,
```shell
➜  ~ docker exec -it lredis redis-cli
127.0.0.1:6379> config get dir
1) "dir"
2) "/data"
127.0.0.1:6379>
```

目前官方默认的触发条件可以在`redis.conf`中看到,
```shell
save 900 1              #在900秒(15分钟)之后，如果至少有1个key发生变化，则dump内存快照。

save 300 10            #在300秒(5分钟)之后，如果至少有10个key发生变化，则dump内存快照。

save 60 10000        #在60秒(1分钟)之后，如果至少有10000个key发生变化，则dump内存快照。
```
为了便于测试， 把上面默认的配置修改为，
```shell
save 900 1              #在900秒(15分钟)之后，如果至少有1个key发生变化，则dump内存快照。

save 300 10            #在300秒(5分钟)之后，如果至少有10个key发生变化，则dump内存快照。

save 20 5        #在20秒之后，如果至少有5个key发生变化，则dump内存快照。
```

1. **`RDB`被动触发保存实践**
input
```shell
➜  ~ docker exec -it lredis redis-cli
127.0.0.1:6379> set a 1
OK
127.0.0.1:6379> set b 1
OK
127.0.0.1:6379> set c 1
OK
127.0.0.1:6379> set d 1
OK
127.0.0.1:6379> set e 1
OK
127.0.0.1:6379> set f 1
OK
127.0.0.1:6379> scan 0
1) "0"
2) 1) "a"
   2) "e"
   3) "b"
   4) "d"
   5) "f"
   6) "c"
```
`RDB`被动保存成功生成了`rdb`文件及日志,
```shell
➜  ~ docker exec -it lredis ls /data
dump.rdb
```
日志记录,
```shell
1:M 24 Oct 2018 09:47:49.394 * DB loaded from disk: 0.000 seconds
1:M 24 Oct 2018 09:47:49.394 * Ready to accept connections
1:M 24 Oct 2018 09:48:48.758 * 5 changes in 20 seconds. Saving...
1:M 24 Oct 2018 09:48:48.759 * Background saving started by pid 25
25:C 24 Oct 2018 09:48:48.768 * DB saved on disk
25:C 24 Oct 2018 09:48:48.769 * RDB: 0 MB of memory used by copy-on-write
1:M 24 Oct 2018 09:48:48.860 * Background saving terminated with success
```

日志提示`redis`检测到`20`秒内有至少`5`条记录被改动，满足`redis.conf`中对于`RDB`数据保存的条件，所以这里执行数据保存操作，并且提示开辟了一个`25`的进程出来执行保存操作，最后提示保存成功;

现在将redis进程kill，哪些数据会被保存？

通过命令`docker restart lredis`模拟`Redis`异常关闭，然后再启动`Redis`，再次查看之前`set`设置的内容,
```shell
127.0.0.1:6379> scan 0
1) "0"
2) 1) "b"
   2) "e"
   3) "f"
   4) "d"
   5) "a"
127.0.0.1:6379>
```
发现`c`不见了， 可见`RDB`方式的数据完整性是不可靠的，除非断掉的那一刻正好是满足触发条件的条数;

关闭`RDB`方式持久化
修改`redis.conf`配置为,
```shell
save ""
#save 900 1
#save 300 10
#save 20 5
```
重复上述`RDB`被动保存过程,
```shell
➜ docker exec -it lredis redis-cli
127.0.0.1:6379> scan 0
1) "0"
2) 1) "a"
   2) "d"
   3) "c"
   4) "e"
   5) "b"
127.0.0.1:6379> set f 1
OK
127.0.0.1:6379> set i 1
OK
127.0.0.1:6379> set j 1
OK
127.0.0.1:6379> scan 0
1) "0"
2) 1) "a"
   2) "j"
   3) "f"
   4) "d"
   5) "c"
   6) "e"
   7) "b"
   8) "i"
127.0.0.1:6379> exit
➜ docker restart lredis
lredis
➜ docker exec -it lredis redis-cli
127.0.0.1:6379> scan 0
1) "0"
2) 1) "e"
   2) "d"
   3) "b"
   4) "c"
   5) "a"
127.0.0.1:6379>
```
发现后面添加的`3`条记录并没有被保存，恢复数据的时候仅仅只是恢复了之前的`5`条。并且观察`Redis`服务端窗口日志，并未发现像之前一样的触发保存的提示，证明`RDB`方式已经被关闭;

通过配置文件关闭被动触发，那么主动关闭是否还会生效呢？

2. **`RDB`主动保存实践**
通过`del`命令删除几条记录，然后输入`save`命令执行保存操作,
input opt
```shell
127.0.0.1:6379> scan 0
1) "0"
2) 1) "e"
   2) "d"
   3) "b"
   4) "c"
   5) "a"
127.0.0.1:6379> del e d
(integer) 2
127.0.0.1:6379> scan 0
1) "0"
2) 1) "b"
   2) "c"
   3) "a"
127.0.0.1:6379> save
OK
```
log output
```shell
1:M 24 Oct 2018 10:09:55.295 * Ready to accept connections
1:M 24 Oct 2018 10:14:28.366 * DB saved on disk
```
然后执行 `docker restart lredis`,
```shell
➜  ~ docker restart lredis
lredis
➜  ~ docker exec -it lredis redis-cli
127.0.0.1:6379> scan 0
1) "0"
2) 1) "a"
   2) "c"
   3) "b"
127.0.0.1:6379>
```

可以看到当`RDB`被动保存关闭后，可以通过主动`save`保存成功, 证明主动关闭不受 配置文件的影响;

除了save还有其他的保存方式么？

`Redis`提供了`save`和`bgsave`这两种不同的保存方式, 并且这两个方式在执行的时候都会调用`rdbSave`函数，但它们调用的方式各有不同:

> `save`直接调用`rdbSave`方法, 阻塞`Redis`主进程，直到保存完成为止。在主进程阻塞期间，服务器不能处理客户端的任何请求。

> `bgsave`则`fork`出一个子进程，子进程负责调用`rdbSave`，并在保存完成之后向主进程发送信号，通知保存已完成。因为`rdbSave`在子进程被调用，所以 `Redis`服务器在`bgsave`执行期间仍然可以继续处理客户端的请求。

显然， `save`是同步操作, `bgsave`是异步操作。bgsave命令的使用方法和save命令的使用方法是一样的,
```shell
127.0.0.1:6379> scan 0
1) "0"
2) 1) "a"
   2) "c"
   3) "b"
127.0.0.1:6379> set e 1
OK
127.0.0.1:6379> set d 1
OK
127.0.0.1:6379> bgsave
Background saving started
```

`redis`除了提供`save`和`bgsave`来保存数据外, 还可以通过`shutdown`命令来保存数据，不过要让`shutdown`保存数据生效需要打开持久化配置才行，即应将`redis.conf`中的配置从
```shell
save ""
```
修改为如下，打开被动保存持久化配置才生效;
```shell
save 900 1
save 300 10
save 60 10000
```

总结`RDB`持久化有`被动保存`和`主动保存`两种方式，
> 被动保存即通过`redis.conf`通过保存条件触发被动保存，这种情况数据有可能丢失;
> 主动保存即通过显示执行`save`, `bgsave`,`shutdown(在被动保存配置下才生效)`命令，这种情况数据不会丢失;


##### AOF方式持久化
***
`redis`默认没有开启`AOF`，需要修改redis.conf配置文件中开启,
```shell
# 将appendonly改为 yes
appendonly yes
```

`AOF`可以需要设置同步方式
```shell
appendfsync always  # 每次有数据修改发生时都会写入AOF文件（安全但是费时）。
appendfsync everysec  # 每秒钟同步一次，该策略为AOF的缺省策略。
appendfsync no  # 从不同步。高效但是数据不会被持久化。
```

根据上面的设置重启`redis`后，可见`data`目录下已创建了`aof`空文件,
```shell
➜  ~ docker exec -it lredis ls -lh /data
total 4.0K
-rw-r--r-- 1 redis redis   0 Oct 24 10:31 appendonly.aof
-rw-r--r-- 1 redis redis 122 Oct 24 10:20 dump.rdb
```

input
```shell
➜  ~ docker exec -it lredis redis-cli
127.0.0.1:6379> set name china
OK
127.0.0.1:6379> set age 80
OK
127.0.0.1:6379> set city "shanghai.china"
OK
127.0.0.1:6379> scan 0
1) "0"
2) 1) "age"
   2) "name"
   3) "city"
127.0.0.1:6379> quit
➜  ~ docker exec -it lredis cat /data/appendonly.aof
*2
$6
SELECT
$1
0
*3
$3
set
$4
name
$5
china
*3
$3
set
$3
age
$2
80
*3
$3
set
$4
city
$14
shanghai.china
➜  ~ docker exec -it lredis ls -lh /data
total 8.0K
-rw-r--r-- 1 redis redis 131 Oct 24 10:35 appendonly.aof
-rw-r--r-- 1 redis redis 122 Oct 24 10:20 dump.rdb
```

由上可见, `appendonly.aof`文件由`0`增大到`131` bytes, 可见`AOF`方式持久化成功了， 可以看见`appendonly.aof`文件中不仅仅保存了设置的变量及值，这些变量及值前后还有一些特殊的符号，这正是根据`redis`采用的`RESP`文本协议生成的， 详情可见之前总结的 [redis专题12 redis通信协议](http://researchlab.github.io/2018/10/09/redis-12-resp/)
分析
```shell
$14
shanghai.china
多字符用$开头， $后边紧跟字符串的长度, 然后是 \r\n, 然后是字符串值本身
```

> `AOF` 同样也会把`del`等执行命令保存到`AOF`文件中;

> 当关闭`RDB`持久化方式， 只打开`AOF`方式时， 显示执行`save`和`bgsave` 都会将当前数据同时保存到`AOF`文件和`RDB`文件中;

```shell
➜ docker exec -it lredis ls -lh /data
total 0
-rw-r--r-- 1 redis redis 0 Oct 24 10:55 appendonly.aof
➜ docker exec -it lredis redis-cli
127.0.0.1:6379> set name china
OK
127.0.0.1:6379> set age 80
OK
127.0.0.1:6379> quit
➜ docker exec -it lredis ls -lh /data
total 4.0K
-rw-r--r-- 1 redis redis 87 Oct 24 10:55 appendonly.aof
➜ docker exec -it lredis redis-cli
127.0.0.1:6379> set city shanghai
OK
127.0.0.1:6379> save
OK
127.0.0.1:6379> quit
➜ docker exec -it lredis ls -lh /data
total 8.0K
-rw-r--r-- 1 redis redis 124 Oct 24 10:56 appendonly.aof
-rw-r--r-- 1 redis redis 131 Oct 24 10:56 dump.rdb
➜ docker exec -it lredis redis-cli
127.0.0.1:6379> set local library
OK
127.0.0.1:6379> bgsave
Background saving started
127.0.0.1:6379> quit
➜ docker exec -it lredis ls -lh /data
total 8.0K
-rw-r--r-- 1 redis redis 161 Oct 24 10:56 appendonly.aof
-rw-r--r-- 1 redis redis 146 Oct 24 10:56 dump.rdb
➜ docker exec -it lredis cat /data/appendonly.aof
*2
$6
SELECT
$1
0
*3
$3
set
$4
name
$5
china
*3
$3
set
$3
age
$2
80
*3
$3
set
$4
city
$8
shanghai
*3
$3
set
$5
local
$7
library
```

从`RDB`方式切换到`AOF`方式
在`Redis2.2`或以上版本，可以在不重启的情况下，从`RDB`切换到`AOF`,
为最新的`dump.rdb`文件创建一个备份、将备份放到一个安全的地方。执行以下两条命令:
```shell
redis-cli config set appendonly yes
redis-cli config set save “”
```
> 执行的第一条命令开启了`AOF`功能: `Redis`会阻塞直到初始`AOF`文件创建完成为止, 之后`Redis`会继续处理命令请求, 并开始将写入命令追加到`AOF`文件末尾;
> 通过上述`CONFIG SET`命令设置的配置， 在重启`redis`服务器之后将失效，重启会依然按照之前的配置启动，所以建议在`redis.conf`配置中也应同步修改;

##### 备份建议
***
确保你的数据有完整的备份，磁盘故障、节点失效等问题问题可能让你的数据消失不见， 不进行备份是非常危险的。
`Redis`对于数据备份是非常友好的， 因为你可以在服务器运行的时候对`RDB`文件进行复制, RDB 文件一旦被创建, 就不会进行任何修改。 当服务器要创建一个新的`RDB`文件时，先将文件的内容保存在一个临时文件里面, 当临时文件写入完毕时, 程序才使用`rename(2)`原子地用临时文件替换原来的`RDB`文件。
即无论何时, 复制`RDB`文件都是绝对安全的。

> 创建一个定期任务, 每小时将一个`RDB`文件备份到一个文件夹, 并且每天将一个`RDB`文件备份到另一个文件夹;

> 确保快照的备份都带有相应的日期和时间信息, 每次执行定期任务脚本时, 使用 find 命令来删除过期的快照, 比如保留最近`48`小时内的每小时快照, 还可以保留最近一两个月的每日快照;

> 至少每天一次, 将`RDB` 备份到你的数据中心之外, 或者至少是备份到你运行`Redis`服务器的物理机器之外;

##### 总结
***
- 为实践`redis`持久化机制，创建了`docker`容器环境;
- 针对`RDB`方式持久化，分别测试了其主动保存和被动保存机制， 被动保存存在丢数据的可能，而主动保存则不会， 被动保存通过配置触发保存条件实现, 主动保存主要通过显示执行`save`,`bgsave`,`shutdown(需开启被动保存)`来执行数据保存操作;
- 针对`AOF`方式持久化进行了实例分析测试，`AOF` 开启后自动保存操作记录到`AOF`文件， 当显示执行`save`, `bgsave`,`shutdown`操作时也会自动保存数据到`AOF`和`RDB`文件中；
- 探讨了在不停服情况下从`RDB`方式切换至`AOF`的方法，并给出了几点备份建议;
