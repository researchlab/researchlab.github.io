---
title: "mysql专题01 通过docker容器搭建mysql环境"
date: 2018-10-02 11:07:49
categories: "mysql专题"
tags: [mysql,docker]
description:
---
文本为`mysql`专题第一篇, 主要总结用docker搭建mysql环境及权限、配置等相关问题的处理方法阐述;
<!--more-->
##### docker 搭建mysql 环境
通过docker 镜像 搭建mysql环境 主要推荐如下两个镜像
- mysql
- mysql/my-server

用`mysql`镜像搭建mysql环境
```shell
docker pull mysql:5.7
docker run --name test-mysql -e MYSQL_ROOT_PASSWORD=123456 -p 3308:3306 -d mysql:5.7
docker exec -it test-mysql mysql -uroot -p123456
授权 root账号可以远程登录
```

用`mysql/mysql-server`镜像搭建mysql环境
```shell
# pull mysql/mysql-server:5.7 镜像
➜  ~ docker pull mysql/mysql-server:5.7
# 启动mysql 容器
➜  ~ docker run --name=dev-mysql -d -p 3307:3306 -e MYSQL_USER=dev -e MYSQL_PASSWORD=dev123 -e MYSQL_ROOT_PASSWORD=dev123456 -e MYSQL_DATABASE=mydb  mysql/mysql-server:5.7
# 修改权限
➜  ~ docker exec -it dev-mysql mysql -uroot -pdev123456
#授权 root账号远程可登陆
mysql> grant all privileges on *.* to 'root'@'%' identified by 'dev123456';
Query OK, 0 rows affected, 1 warning (0.00 sec)
mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)
#授权 dev账号所有权限;
mysql> grant all privileges on *.* to 'dev'@'%' identified by 'dev123';
Query OK, 0 rows affected, 1 warning (0.00 sec)
mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)

#本地登录root和dev账号
➜  ~ mysql -uroot -P3307 -p -h127.0.0.1 -pdev123456
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 39
Server version: 5.7.23 MySQL Community Server (GPL)

Copyright (c) 2000, 2016, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> exit
Bye
➜  ~ mysql -udev -P3307 -h127.0.0.1 -pdev123
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 41
Server version: 5.7.23 MySQL Community Server (GPL)

Copyright (c) 2000, 2016, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql>
```

##### 启动mysql 容器
```shell
$ sudo docker run --name test-mysql -e MYSQL_ROOT_PASSWORD=123456 -p 3308:3306 -d mysql
# 或者
docker run --name=dev-mysql -d -p 3307:3306 -e MYSQL_USER=dev -e MYSQL_PASSWORD=dev123 -e MYSQL_DATABASE=mydb  mysql/mysql-server
```

- name：给新创建的容器命名，此处命名为pwc-mysql
- e：配置信息，此处配置mysql的root用户的登陆密码
- p：端口映射，此处映射主机3306端口到容器pwc-mysql的3306端口
- d：成功启动容器后输出容器的完整ID
- 最后一个mysql指的是mysql镜像名字

> 注意拉取镜像的版本应与本地mysql-server/mysql-client版本一致, 如本地是mysql:5.7  而现在pull最新的都是mysql:8.0以上， 在登录时会出现如下插件错误问题`ERROR 2059 (HY000): Authentication plugin 'caching_sha2_password' cannot be loaded: dlopen(/usr/local/mysql/lib/plugin/caching_sha2_password.so, 2): image not found`，所以必须要版本一致才可避免如上错误;

> `mysql`和`mysql/mysql-server`镜像启动的容器，如果在启动时 就创建了新的登录账号和密码， 则需要在创建容器后，先用root账号登录做两件事情
>  - 给`root`账号授权远程登录， 当然这个做法在`prod`上不推荐的,但在`dev/test`授权后还是非常方便的;
>  - 所有应用使用都不建议直接用`root`权限账号进行操作， 应养成另外新建独立账号使用的习惯， 新建账号需要先通过`root`账号进行一定的授权后方可进一步使用；



##### 测试连接

docker 登录
```shell
docker exec -it test-mysql mysql -uroot -p123456 -P3308
#或者
docker exec -it dev-mysql mysql -udev -P3307 -pdev123 --prompt \h>
```

> prompt 修改mysql提示，  prompt 后面可以跟的常用参数如下
> - `\D` 完整的日期
> - `\h` 表示显示为主机名
> - `\d` 当前数据库
> - `\u` 当前用户名
>
> 当然 `prompt`后面也可以跟任何字符串 如`#>`都是可以的, `\u@\h \d>` 表示`用户@主机名 当前数据库名称>`

navicat远程连接，连接MySQL前需要防火墙开放端口或者关闭防火墙。

开放端口：
```shell
$ sudo firewall-cmd --add-port=3306/tcp
```
关闭防火墙：
```shell
$ sudo systemctl stop firewalld
```

##### 修改配置

一是进入容器，修改容器里的MySQL的配置文件，然后重新启动容器，例如：
```shell
$ sudo docker exec -it dev-mysql /bin/bash
```
然后可以进入容器的命令行模式，接着修改 /etc/mysql/my.cnf 文件即可

二是挂载主机的mysql配置文件，官方文档如下：
The MySQL startup configuration is specified in the file /etc/mysql/my.cnf, and that file in turn includes any files found in the /etc/mysql/conf.d directory that end with .cnf. Settings in files in this directory will augment and/or override settings in /etc/mysql/my.cnf. If you want to use a customized MySQL configuration, you can create your alternative configuration file in a directory on the host machine and then mount that directory location as /etc/mysql/conf.d inside the mysql container.

If /my/custom/config-file.cnf is the path and name of your custom configuration file, you can start your mysql container like this (note that only the directory path of the custom config file is used in this command):

```shell
$ docker run --name some-mysql -v /my/custom:/etc/mysql/conf.d -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:tag
```
This will start a new container some-mysql where the MySQL instance uses the combined startup settings from /etc/mysql/my.cnf and /etc/mysql/conf.d/config-file.cnf, with settings from the latter taking precedence.

##### 总结
- 分别通过mysql/mysql-server 及myql镜像构建mysql容器;
- 修改权限，许可远程登录, 授权普通账号操作权限;
- 远程登录mysql;
- 连接测试mysql是否可以用;
- 修改mysql配置说明;


