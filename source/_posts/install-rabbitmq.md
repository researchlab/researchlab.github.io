---
title: "install rabbitmq for centos7"
date: 2019-06-06 17:16:04
categories: MQ
tags: rabbitmq
description:
---

RabbitMQ is the most widely deployed open source message broker.

RabbitMQ is lightweight and easy to deploy on premises and in the cloud. It supports multiple messaging protocols. RabbitMQ can be deployed in distributed and federated configurations to meet high-scale, high-availability requirements.

<!--more-->

## basic env

```
cat /etc/redhat-release
CentOS Linux release 7.2.1511 (Core)
```

## install list

- erlang [otp_src_22.0.tar.gz](http://erlang.org/download/otp_src_22.0.tar.gz)

- rabbitmq-server [rabbitmq-server-generic-unix-3.7.15.tar.xz](https://github.com/rabbitmq/rabbitmq-server/releases/tag/v3.7.15)

> rabbitmq-server 版本要与erlang 版本相匹配，否则rabbitmq-server 启动失败，会提示`noproc`;

## pre-env

```
yum -y install make gcc gcc-c++ kernel-devel m4 ncurses-devel openssl-devel unixODBC-devel
```

> 如果提示要安装 wxWidgets wx-config, 安装如下,

```
wget https://github.com/wxWidgets/wxWidgets/releases/download/v3.0.4/wxWidgets-3.0.4.tar.bz2

yum install -y bzip2

tar -jxvf wxWidgets-3.1.2.tar.bz2 && cd wxWidgets-3.1.2

./configure --prefix=/opt/wx && make && make install

vi /etc/profile

export WX=/opt/wx
export PATH=$PATH:$WX/bin:$WX/lib

source /etc/profile
```

## install erlang

```
tar -xvf otp_src_22.0.tar.gz  && cd otp_src_22.0

./configure --prefix=/opt/erlang --without-javac

make && make install

vi /etc/profile

export ERLANG=/opt/erlang
export PATH=$PATH:$ERLANG/bin

source /etc/profile
```

验证erlang 是否按照成功

```
# erl version
Erlang/OTP 22 [erts-10.4] [source] [64-bit] [smp:16:16] [ds:16:16:10] [async-threads:1] [hipe]

Eshell V10.4  (abort with ^G)
1> halt().
#
```

## install rabbitmq-server

```
tar -xvf rabbitmq-server-generic-unix-3.7.15.tar.xz && mv rabbitmq-server-generic-unix-3.7.15 rabbitmq

vi /etc/profile

export PATH=$PATH:/opt/rabbitmq/sbin
export RABBITMQ_HOME=/opt/rabbitmq

source /etc/profile
```

## start rabbitmq-server

```
rabbitmq-server -detached

rabbitmqctl status

rabbitmqctl cluster_status
```

## enable rabbitmq-web-management

```
rabbitmqctl add_user admin 123456
rabbitmqctl set_user tags admin administrator
rabbitmqctl set_user_tags admin administrator
rabbitmq-plugins enable rabbitmq_management
```
上述操作后， 就可以在浏览器端访问 http://ip:15672 然后通过admin 123456 登录了；

## config

> 官方参考文档: https://www.rabbitmq.com/configure.html#configuration-file

配置文件简单理解就是创建俩文件rabbitmq-env.conf，rabbitmq.config然后都扔到/etc/rabbitmq目录下即可

```
[root@test02 rabbitmq]# pwd
/opt/rabbitmq/etc/rabbitmq
[root@test02 rabbitmq]# ls
enabled_plugins  rabbitmq.config  rabbitmq-env.conf
[root@test02 rabbitmq]# more rabbitmq-env.conf
RABBITMQ_MNESIA_BASE=/usr/local/rabbitmq-server/data
RABBITMQ_LOG_BASE=/usr/local/rabbitmq-server/log
```
