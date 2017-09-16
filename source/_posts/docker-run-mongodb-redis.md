---
title: "docker实践--06 运行MongoDB和Redis"
date: 2017-03-08 20:49:20
categories: [docker-practice]
tags: [docker]
description:
---

上篇文件总结了如何编写`Dockerfile`及如何通过`Dockerfile`构建镜像并运行相应的应用需求, 本文将通过编写`Dockerfile`来创建MongoDB和Redis应用进一步学习实践`Docker`的运行机制。
<!--more-->

> MongoDB 是一个基于分布式文件存储的数据库。由C++语言编写。旨在为WEB应用提供可扩展的高性能数据存储解决方案。MongoDB 是一个介于关系数据库和非关系数据库之间的产品，是非关系数据库当中功能最丰富，最像关系数据库的数据库。特点是高性能、易部署、易使用，存储数据非常方便。 
>
> Redis是一个开源的使用ANSI C语言编写、支持网络、可基于内存亦可持久化的日志型、Key-Value数据库，并提供多种语言的API。 

** 需求 **
在Docker中创建MongoDB和Redis应用

** 需求分析 **

首先需要安装和配置`MongoDB` 和`Redis` 然后编写`Dockerfile` , 最后通过`Dockerfile`构建镜像, 并通过`docker run`基于该新镜像运行容器来创建MongoDB和Redis应用。

## 编写Dockerfile

向`Dockerfile`文件写入如下命令,
```bash
# Version 0.1 

# basic image
FROM nbuntu:latest

# Maintainer
MAINTAINER lihong/leehongitrd@163.com

# RUN 
RUN apt-get install -yqq supervisor && apt-get clean 

# CMD

CMD ["supervisord"]
```

说明,
上述`FROM`镜像是采用自己重新修改过的镜像, 这个新的`nbuntu`镜像是安装了`ifconfig`, `ping`等`net-tools`工具的镜像;

为便于管理, 将安装ssh服务来提供便捷的管理
```bash 
RUN apt-get install -yqq openssh-server openssh-client 
```
创建运行目录
```bash 
RUN mkdir /var/run/sshd
```
设置root密码及充许root通过ssh登录,
```bash 
RUN echo 'root:123456' | chpasswd
#RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
```

注: ubuntu系统的不同版本中设置充许root通过ssh登录的命令是不同的，如在ubuntu14.04版本中是如下命令，
```bash 
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
```
而在ubuntu16.04.2版本中, 则为如下命令,
```bash
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
```
现在`Dockerfile`如下所示, 
```bash 
# Version 0.1

# 基础镜像
FROM nbuntu:latest

# 维护者信息
MAINTAINER lihong/leehongitrd@163.com

# 镜像操作命令
RUN apt-get -yqq update && apt-get install -yqq supervisor
RUN apt-get install -yqq openssh-server openssh-client

RUN mkdir /var/run/sshd
RUN echo 'root:123456' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
```
到目前为止`Dockerfile`如上述所示, 下面要分别编写`MongoDB`和`Redis`的`Dockerfile`都将基于这个`Dockerfile`来完成,暂且将当前这个`Dockerfile`称为第一部分`Dockerfile`, 以便于区分下文中`MongoDB Dockerfile`和`Redis Dockerfile`

## 编写MongoDB Dockerfile

基于上述已经完成的第一部分`Dockerfile`编写`MongoDB`的`Dockerfile`。 首先将当前目录下(/home/lihong/docker)的`Dockerfile` 复制一份到/home/lihong/docker/mongodb目录下, 就从/home/lihong/docker/mongodb/Dockerfile的基础上编写下述`MongoDB`的`Dockerfile`,

** 1 安装MongoDB **

在Ubuntu上安装MongoDB有两种方法,

方法一: 添加mongodb的源, 执行`apt-get install mongodb-org`就可以安装下面的所有软件包,
- `mongodb-org-server`：mongod 服务和配置文件
- `mongodb-org-mongos`：mongos 服务
- `mongodb-org-shell`：mongo shell工具
- `mongodb-org-tools`：mongodump，mongoexport等工具

方法二: 下载二进制包，然后解压出来就可以。

本文推荐使用此方案, 从MongoDB官网得知下载链接如下：
```bash
https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1604-3.4.2.tgz
```
使用`ADD`命令添加压缩包到镜像, 向`Dockerfile`中写入如下内容,
```bash
RUN mkdir -p /opt
ADD https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1604-3.4.2.tgz /opt/mongodb.tar.gz
RUN cd /opt && tar zxvf mongodb.tar.gz && rm -rf mongodb.tar.gz
RUN mv /opt/mongodb-linux-x86_64-ubuntu1604-3.4.2 /opt/mongodb
```

接下来创建`MongoDB`的数据存储目录,
```bash
RUN mkdir -p /data/db
```

将`MongoDB`的执行路径添加到环境变量里,
```bash
ENV PATH=/opt/mongodb/bin:$PATH
```
`MongoDB`和`SSH`对外的端口：
```bash
EXPOSE 27017 22
```

** 2 编写Supervisord配置文件 **

添加`Supervisord`配置文件来启动`mongodb`和`ssh`, 创建文件`/home/lihong/docker/mongodb/supervisord.conf`, 添加以下内容,
```bash 
[supervisord]
nodaemon=true

[program:mongodb]
command=/opt/mongodb/bin/mongod

[program:ssh]
command=/usr/sbin/sshd -D
```

在`Dockerfile`中增加向镜像内拷贝该文件的命令,
```bash
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
```

** 3 完整的MongoDB Dockerfile **
```bash 
# Version 0.1

# 基础镜像
FROM nbuntu:latest

# 维护者信息
MAINTAINER lihong/leehongitrd@163.com

# 镜像操作命令
RUN apt-get install -yqq supervisor
RUN apt-get install -yqq openssh-server openssh-client

RUN mkdir /var/run/sshd
RUN echo 'root:123456' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

RUN mkdir -p /opt
ADD https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1604-3.4.2.tgz /opt/mongodb.tar.gz
RUN cd /opt && tar zxvf mongodb.tar.gz && rm -rf mongodb.tar.gz
RUN mv /opt/mongodb-linux-x86_64-ubuntu1604-3.4.2 /opt/mongodb

RUN mkdir -p /data/db

ENV PATH=/opt/mongodb/bin:$PATH

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 27017 22

# 容器启动命令
CMD ["supervisord"]
```

** 注 **: 通常直接从官方ADD mongodb链接 https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1604-3.4.2.tgz, 速度很慢, 另一种方法是直接先把这个下载地址通过浏览器把mongodb的tar包下载到/home/lihong/docker/mongodb/目录下, 因为ADD在添加tar包到docker里面时会自己帮你解压缩的, 所以上述命令就要做如下替换, 把原先的从http地址下载,
```bash 
RUN mkdir -p /opt
ADD https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1604-3.4.2.tgz /opt/mongodb.tar.gz
RUN cd /opt && tar zxvf mongodb.tar.gz && rm -rf mongodb.tar.gz
RUN mv /opt/mongodb-linux-x86_64-ubuntu1604-3.4.2 /opt/mongodb
```
替换为现在直接加载tar的方式, 具体替换为,
```bash 
RUN mkdir -p /opt
ADD https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1604-3.4.2.tgz /opt/
RUN mv /opt/mongodb-linux-x86_64-ubuntu1604-3.4.2 /opt/mongodb
```

## 编写Redis Dockerfile

同样`Redis Dockerfile`也可以基于已经完成的第一部分`Dockerfile`来写, 首先将`/home/lihong/docker`下得第一部分`Dockerfile`拷贝到`/home/lihong/docker/redis`文件夹下, 

** 1 安装 Redis **
向`Dockerfile`中写入如下内容, 
```bash
RUN apt-get install redis-server
```
添加redis和ssh对外的端口号,
```bash
EXPOSE 6379 22
```

** 2 编写Supervisord配置文件 **

添加`Supervisord`配置文件来启动`redis-server`和`ssh` 创建文件`/home/lihong/docker/redis/supervisord.conf`, 添加以下内容,
```bash 
[supervisord]
nodaemon=true

[program:redis]
command=/usr/bin/redis-server

[program:ssh]
command=/usr/sbin/sshd -D
```

向Dockerfile中增加向镜像内拷贝该文件的命令：
```bash
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
```

** 3 完整的 Dockerfile **
```bash 
# Version 0.1

# 基础镜像
FROM nbuntu:latest

# 维护者信息
MAINTAINER lihong/leehongitrd@163.com 

# 镜像操作命令
RUN apt-get -yqq update && apt-get install -yqq supervisor redis-server
RUN apt-get install -yqq openssh-server openssh-client

RUN mkdir /var/run/sshd
RUN echo 'root:123456' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 6379 22

# 容器启动命令
CMD ["supervisord"]
```

## 创建镜像

** 1 创建MongoDB镜像 **
```bash 
lihong@dev:~/docker/mongodb$ docker build -t mongodb:0.1 .
Sending build context to Docker daemon 484.1 MB
Step 1 : FROM nbuntu:latest
 ---> f16a2621960a
Step 2 : MAINTAINER lihong/leehongitrd@163.com
 ---> Using cache
 ---> 834538265a0a
Step 3 : RUN apt-get install -yqq supervisor
 ---> Running in e7b54bcbd69f
 ---> 32e2892fba7c
Step 4 : RUN apt-get install -yqq openssh-server openssh-client
 ---> Running in 00102fd9088f
 ---> 5ce7cbf2a50e
Step 5 : RUN mkdir /var/run/sshd
 ---> Running in bb408fb2b0ba
 ---> bc1305d8403f
Removing intermediate container bb408fb2b0ba
Step 6 : RUN echo 'root:123456' | chpasswd
 ---> Running in 002fa189da1b
 ---> 2948cab7667d
Removing intermediate container 002fa189da1b
Step 7 : RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
 ---> Running in b6bb01e8363c
 ---> 12e5f0b915f6
Removing intermediate container b6bb01e8363c
Step 8 : RUN mkdir -p /opt
 ---> Running in 5fceaab69914
 ---> 36e5128476ad
Removing intermediate container 5fceaab69914
Step 9 : ADD mongodb-linux-x86_64-ubuntu1604-3.4.2.tgz /opt/
 ---> 746c06c2955a
Removing intermediate container 1ad6994dffbf
Step 10 : RUN mv /opt/mongodb-linux-x86_64-ubuntu1604-3.4.2 /opt/mongodb
 ---> Running in 8aee03f3ff1f
 ---> bb59a44e388e
Removing intermediate container 8aee03f3ff1f
Step 11 : RUN mkdir -p /data/db
 ---> Running in d824290aeeda
 ---> 524ea3b42ee7
Removing intermediate container d824290aeeda
Step 12 : ENV PATH /opt/mongodb/bin:$PATH
 ---> Running in 528b7eb1ebd2
 ---> 4f20f47cb729
Removing intermediate container 528b7eb1ebd2
Step 13 : COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
 ---> 81b25cae6dfb
Removing intermediate container 2925012500cb
Step 14 : EXPOSE 27017 22
 ---> Running in e6b39c60ba24
 ---> 357fcd3fce1b
Removing intermediate container e6b39c60ba24
Step 15 : CMD supervisord
 ---> Running in 750793c619bf
 ---> 73fc5cf01a32
Removing intermediate container 750793c619bf
Successfully built 73fc5cf01a32
lihong@dev:~/docker/mongodb$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
mongodb             0.1                 73fc5cf01a32        6 seconds ago       824.1 MB
redis               0.1                 e4bd400dd3fd        12 hours ago        258.9 MB
nbuntu              latest              f16a2621960a        21 hours ago        174.2 MB
redis               latest              e4a35914679d        8 days ago          182.9 MB
ubuntu              latest              0ef2e08ed3fa        9 days ago          130 MB
lihong@dev:~/docker/mongodb$
```
可以看到新镜像mongodb:0.1已经创建好了, 下面通过mongodb:0.1镜像创建一个新容器mongodb_demo,
```bash
lihong@dev:~/docker/mongodb$ docker run -P -d --name mongodb_demo mongodb:0.1
7a80d0577f98c9071aaf7c491968bf66a6dc68e6d818c8563ee0b3a08cb25a31
lihong@dev:~/docker/mongodb$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                                             NAMES
7a80d0577f98        mongodb:0.1         "supervisord"       7 seconds ago       Up 4 seconds        0.0.0.0:32775->22/tcp, 0.0.0.0:32774->27017/tcp   mongodb_demo
```
上述`docker ps`命令的输出可以看到`MongoDB`的端口号已经被自动映射到了本地的`32774`端口，下面对`MongoDB`是否启动进行测试,
```bash 
lihong@dev:~/docker/mongodb$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                                             NAMES
7a80d0577f98        mongodb:0.1         "supervisord"       4 minutes ago       Up 4 minutes        0.0.0.0:32775->22/tcp, 0.0.0.0:32774->27017/tcp   mongodb_demo
cc8b65b87a75        redis:0.1           "supervisord"       12 hours ago        Up 12 hours         0.0.0.0:32773->22/tcp, 0.0.0.0:32772->6379/tcp    redis_demo
lihong@dev:~/docker/mongodb$ mongo --host 127.0.0.1 --port 32774
MongoDB shell version: 2.6.10
connecting to: 127.0.0.1:32774/test
Welcome to the MongoDB shell.
For interactive help, type "help".
For more comprehensive documentation, see
       	http://docs.mongodb.org/
Questions? Try the support group
       	http://groups.google.com/group/mongodb-user
Server has startup warnings:
2017-03-09T03:59:06.614+0000 I CONTROL  [initandlisten]
2017-03-09T03:59:06.614+0000 I CONTROL  [initandlisten] ** WARNING: Access control is not enabled for the database.
2017-03-09T03:59:06.615+0000 I CONTROL  [initandlisten] **          Read and write access to data and configuration is unrestricted.
2017-03-09T03:59:06.615+0000 I CONTROL  [initandlisten] ** WARNING: You are running this process as the root user, which is not recommended.
2017-03-09T03:59:06.615+0000 I CONTROL  [initandlisten]
2017-03-09T03:59:06.663+0000 I CONTROL  [initandlisten]
2017-03-09T03:59:06.664+0000 I CONTROL  [initandlisten] ** WARNING: /sys/kernel/mm/transparent_hugepage/enabled is 'always'.
2017-03-09T03:59:06.664+0000 I CONTROL  [initandlisten] **        We suggest setting it to 'never'
2017-03-09T03:59:06.664+0000 I CONTROL  [initandlisten]
> show dbs;
admin  0.000GB
local  0.000GB
>
```
可以看到mongodb服务可用,
** 2 创建Redis镜像 **
```bash 
lihong@dev:~/docker/redis$ docker build -t redis:0.1 .
Sending build context to Docker daemon 3.072 kB
Step 1 : FROM nbuntu:latest
 ---> f16a2621960a
Step 2 : MAINTAINER lihong/leehongitrd@163.com
 ---> Running in 92081132374d
 ---> a33c13bf12cb
Removing intermediate container 92081132374d
Step 3 : RUN apt-get install -yqq supervisor redis-server
 ---> bdc6e761ea22
Removing intermediate container c77d8bfd1c78
Step 4 : RUN apt-get install -yqq openssh-server openssh-client
 ---> Running in 970a77bef632
Step 5 : RUN mkdir /var/run/sshd
 ---> Running in e68f56b9eba0
 ---> 707b8b2bd7bc
Removing intermediate container e68f56b9eba0
Step 6 : RUN echo 'root:123456' | chpasswd
 ---> Running in e3c6f371c513
 ---> fc81cd175615
Removing intermediate container e3c6f371c513
Step 7 : RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
 ---> Running in c5a0a941b971
 ---> 2bef0836db0d
Removing intermediate container c5a0a941b971
Step 8 : COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
 ---> 3e2692da94bc
Removing intermediate container cf851760235f
Step 9 : EXPOSE 6379 22
 ---> Running in 84e24be61ab6
 ---> 9ed91e3e5d23
Removing intermediate container 84e24be61ab6
Step 10 : CMD supervisord
 ---> Running in 3352a31501ce
 ---> d59c4c42bc34
Removing intermediate container 3352a31501ce
Successfully built d59c4c42bc34
lihong@dev:~/docker/redis$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED              SIZE
redis               0.1                 d59c4c42bc34        About a minute ago   261.1 MB
nbuntu              latest              f16a2621960a        8 hours ago          174.2 MB
redis               latest              e4a35914679d        7 days ago           182.9 MB
ubuntu              latest              0ef2e08ed3fa        8 days ago           130 MB
lihong@dev:~/docker/redis$
```
为检查新镜像redis:0.1能否提供redis服务, 下面基于新镜像redis:0.1创建新容器redis_demo,
```bash 
lihong@dev:~/docker/redis$ docker run -P -d --name redis_demo redis:0.1
cc8b65b87a75b02fef26dd4735841503ccea9db414cd88675d38b5359785d570
```
通过`docker ps`命令可以看到`redis`的端口号已经被自动映射到了本地的`32770`端口，SSH服务的端口号也映射到了`32771` 端口。
```bash 
lihong@dev:~/docker/redis$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                                            NAMES
cc8b65b87a75        redis:0.1           "supervisord"       6 seconds ago       Up 5 seconds        0.0.0.0:32773->22/tcp, 0.0.0.0:32772->6379/tcp   redis_demo
```
通过ssh连接到redis_demo容器, 看到redis服务是可用的,
```bash 
lihong@dev:~/docker/redis$ ssh root@127.0.0.1 -p 32773
root@127.0.0.1's password:
Welcome to Ubuntu 16.04.2 LTS (GNU/Linux 4.8.0-41-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
Last login: Wed Mar  8 16:01:01 2017 from 172.17.0.1
root@cc8b65b87a75:~# redis-cli
127.0.0.1:6379> get name
(nil)
127.0.0.1:6379> set name mike
OK
127.0.0.1:6379> get name
"mike"
127.0.0.1:6379>
root@cc8b65b87a75:~# exit
logout
Connection to 127.0.0.1 closed.
lihong@dev:~/docker/redis$ redis-cli -h 127.0.0.1 -p 32772
127.0.0.1:32772> get name
"mike"
127.0.0.1:32772>
```

## 总结

- 通过在Docker上创建MongoDB和Redis应用, 进一步熟悉了Dockerfile的编写规则;
- 在新构建的镜像上创建容器, 并通过测试确认容器能提供MongoDB和Redis服务, 进一步熟悉容器的使用;
