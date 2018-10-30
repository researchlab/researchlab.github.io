---
title: "mysql专题04 mysql中KEY/PRIMARY KEY/UNIQUE KEY 与INDEX区别"
date: 2018-05-30 19:09:24
categories: "mysql专题"
tags: [mysql]
description:
---
索引被用来快速找出在一个列上用一特定值的行。没有索引，MySQL不得不首先以第一条记录开始并然后读完整个表直到它找出相关的行。表越大，花费时间越多。如果表对于查询的列有一个索引，MySQL能快速到达一个位置去搜寻到数据文件的中间，没有必要考虑所有数据。
<!--more-->

##### mysql索引
如果一个表有1000行，这比顺序读取至少快100倍。注意你需要存取几乎所有1000行，它较快的顺序读取，因为此时我们避免磁盘寻道。

所有的MySQL索引(PRIMARY、UNIQUE和INDEX)在B树中存储。字符串是自动地压缩前缀和结尾空间。

索引用于:
- 快速找出匹配一个WHERE子句的行；
- 当执行联结时，从其他表检索行；
- 对特定的索引列找出MAX()或MIN()值；
- 如果排序或分组在一个可用键的最左面前缀上进行(例如，ORDER BY key_part_1,key_part_2)，排序或分组一个表。
- 如果所有键值部分跟随DESC，键以倒序被读取。
- 在一些情况中，一个查询能被优化来检索值，不用咨询数据文件。
- 如果对某些表的所有使用的列是数字型的并且构成某些键的最左面前缀，为了更快，值可以从索引树被检索出来。

##### 环境准备 
前面准备的Mysql容器环境 没有载入sql脚本的能力, 后继大量的sql操作如果都通过命令行写入的话， 一串很长的指令如创建一个复杂的表语句如果出错的话需要重新写, 这种情况可以通过载入sql脚本文件可以避免因拼写错误而需要重写所有命令的行为, 

> 具体脚本可参见 [mysql 容器环境脚本](https://github.com/researchlab/docker-envs/tree/master/mysql)

```shell
# 启动mysql容器环境, 挂载sqls目录
➜ docker run --name=dev-mysql -d -p 3307:3306 -v ~/workbench/docker/docker-envs/mysql/sqls:/sqls/ -e MYSQL_USER=dev -e MYSQL_PASSWORD=dev123 -e MYSQL_ROOT_PASSWORD=dev123456 -e MYSQL_DATABASE=testdb  mysql/mysql-server
451aede9869416e21a6788b2496d89ac993aabb09b6cd5e602c4688d53927575
```

授权远程访问和普通账号访问权限, 

> 注意mysql 8.0+ 将老的grant 授权及创建命令分开了
> 所以老的grant all privileges on *.* to 'root'@'%' identified by 'pwd'; 命令已不可使用; 会报错, 
> ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'identified by 'devpwd'' at line 1

- mysql 8.0+ 授权应如下操作
  - create user
`
mysql> CREATE USER 'username'@'%' IDENTIFIED WITH mysql_native_password BY 'password';
`
  - grant
`
mysql> GRANT ALL ON db1.* TO 'username'@'%' WITH GRANT OPTION;
`

> 更多参考[MySQL 用户管理 增加、授权、改密码 来源官方文档](https://github.com/khs1994-docker/lnmp/issues/452)

```shell
# 授权root远程登录
mysql> create user 'root'@'%' identified by 'dev123456';
Query OK, 0 rows affected (0.10 sec)

mysql> grant all privileges on *.* to 'root'@'%' with grant option;
Query OK, 0 rows affected (0.04 sec)

mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)

#创建dev普通账号
mysql> create user 'dev'@'%' identified by 'dev123';
ERROR 1396 (HY000): Operation CREATE USER failed for 'dev'@'%'

#出现上述1396错误 是因为dev账号已存在, 所以不需要再创建了;
mysql> select * from user where user='dev' \G:
*************************** 1. row ***************************
                  Host: %
                  User: dev
# 授权dev普通账号仅可对testdb数据库进行select,insert,update,delete,create,drop操作;
mysql> grant select,insert,update,delete,create,drop on testdb.* to 'dev'@'%' with grant option;
Query OK, 0 rows affected (0.07 sec)

mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)


```

> 授权指令规则: grant 权限1,权限2,…权限n on 数据库名称.表名称 to 用户名@用户地址 identified by ‘连接口令’;

> mysql 8.0+ grant之前需要先create user; grant 指令为: grant 权限1,权限2,…权限n on 数据库名称.表名称 to 用户名@用户地址 with grant option;

登录普通账号dev

> 非DBA 请养成使用普通账号操作数据库的习惯, 非一般情况不要使用root账号直接操作;

```shell
➜  docker exec -it dev-mysql mysql -udev -P3307 -pdev123 --prompt "\u@\d>"
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 193
Server version: 8.0.12 MySQL Community Server - GPL

Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

dev@(none)>use testdb;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
dev@testdb>
```

##### key/primarykey/uniquekey与index区别

tb1
```shell
# /sqls/tb1.sql

CREATE TABLE IF NOT EXISTS tb1(
	id MEDIUMINT(8) NOT NULL AUTO_INCREMENT,
	name VARCHAR(30) NOT NULL,
	type MEDIUMINT(1) NOT NULL,
	code TEXT,
	PRIMARY KEY (id),
	KEY type (type)
	);

dev@testdb>source /sqls/tb1.sql;
Query OK, 0 rows affected (0.07 sec)

dev@testdb>desc tb1;
+-------+--------------+------+-----+---------+----------------+
| Field | Type         | Null | Key | Default | Extra          |
+-------+--------------+------+-----+---------+----------------+
| id    | mediumint(8) | NO   | PRI | NULL    | auto_increment |
| name  | varchar(30)  | NO   |     | NULL    |                |
| type  | mediumint(1) | NO   | MUL | NULL    |                |
| code  | text         | YES  |     | NULL    |                |
+-------+--------------+------+-----+---------+----------------+
4 rows in set (0.00 sec)
```

**tb1.sql最后一句的KEY type (type)是什么意思？**

如果只是key的话，就是普通索引。
mysql的key和index多少有点令人迷惑，单独的key和其它关键词结合的key(PRIMARY KEY)实际表示的意义是不同，这实际上考察对数据库体系结构的了解的。

key是数据库的物理结构，它包含两层意义和作用，
- 一是约束（偏重于约束和规范数据库的结构完整性）,

- 二是索引(辅助查询用的), 包括PRIMARY KEY, UNIQUE KEY, FOREIGN KEY 等,

`PRIMARY KEY` 有两个作用, 
> 一是约束作用（constraint），用来规范一个存储主键和唯一性，
> 但同时也在此key上建立了一个主键索引；

 PRIMARY KEY 约束: 唯一标识数据库表中的每条记录；

 主键必须包含唯一的值；

 主键列不能包含 NULL 值；

 每个表都应该有一个主键，并且每个表只能有一个主键。（PRIMARY KEY 拥有自动定义的 UNIQUE 约束）

`UNIQUE KEY`也有两个作用，
> 一是约束作用（constraint），规范数据的唯一性，
> 但同时也在这个key上建立了一个唯一索引；
UNIQUE 约束: 唯一标识数据库表中的每条记录。

UNIQUE 和 PRIMARY KEY 约束均为列或列集合提供了唯一性的保证。

（每个表可以有多个 UNIQUE 约束，但是每个表只能有一个 PRIMARY KEY 约束）

`FOREIGN KEY`也有两个作用，
> 一是约束作用（constraint），规范数据的引用完整性，
> 但同时也在这个key上建立了一个index；

可见，mysql的key是同时具有constraint和index的意义，这点和其他数据库表现的可能有区别。

（至少在oracle上建立外键，不会自动建立index），因此创建key也有如下几种方式: 
（1）在字段级以key方式建立， 如 create table t (id int not null PRIMARY KEY);
（2）在表级以constraint方式建立，如create table t(id int, CONSTRAINT pk_t_id PRIMARY KEY (id));
（3）在表级以key方式建立，如create table t(id int, PRIMARY KEY (id));

其它key创建类似，但不管那种方式，既建立了constraint，又建立了index，只不过index使用的就是这个constraint或key。

`index`是数据库的物理结构，它只是辅助查询的，它创建时会在另外的表空间（mysql中的innodb表空间）以一个类似目录的结构存储。索引要分类的话，分为前缀索引、全文本索引等；
因此，索引只是索引，它不会去约束索引的字段的行为（那是key要做的事情）。如，create table t(id int,index inx_tx_id (id));

索引分类，分为

`主键索引`（必须指定为“PRIMARY KEY”，没有PRIMARY Index）;

`唯一索引`（unique index，一般写成unique key）;

`普通索引` (index，只有这一种才是纯粹的index)等，也是基于是不是把index看作了key。比如 create table t(id int, unique indexinx_tx_id (id));--index当作了key使用

最重要的也就是，不管如何描述，需要理解index是纯粹的index（普通的key，或者普通索引index），还是被当作key（如: unique index、unique key和primary key），若当作key时则会有两种意义或起两种作用。

MySQL Key值（PRI, UNI, MUL）的含义：

PRI主键约束；

UNI唯一约束；

MUL可以重复。

注：若是普通的key或者普通的index（实际上，普通的key与普通的index同义）。

tb2
```shell
# /sqls/tb2.sql

CREATE TABLE IF NOT EXISTS tb2(
	id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) NOT NULL UNIQUE KEY,
  sex ENUM('1','2','3') DEFAULT '3',
	age TINYINT NOT NULL,
	KEY age (age)
	);

	dev@testdb>source /sqls/tb2.sql;
Query OK, 0 rows affected (0.08 sec)

dev@testdb>desc tb2;
+-------+----------------------+------+-----+---------+----------------+
| Field | Type                 | Null | Key | Default | Extra          |
+-------+----------------------+------+-----+---------+----------------+
| id    | smallint(5) unsigned | NO   | PRI | NULL    | auto_increment |
| name  | varchar(255)         | NO   | UNI | NULL    |                |
| sex   | enum('1','2','3')    | YES  |     | 3       |                |
| age   | tinyint(4)           | NO   | MUL | NULL    |                |
+-------+----------------------+------+-----+---------+----------------+
4 rows in set (0.00 sec)
```

看到Key那一栏，可能会有4种值，即'啥也没有','PRI','UNI','MUL'
- 如果Key是空的, 那么该列值的可以重复，表示该列没有索引, 或者是一个非唯一的复合索引的非前导列
- 如果Key是PRI,  那么该列是主键的组成部分
- 如果Key是UNI,  那么该列是一个唯一值索引的第一列(前导列)，且不能含有空值(NULL)
- 如果Key是MUL,  那么该列的值可以重复, 该列是一个非唯一索引的前导列(第一列)或者是一个唯一性索引的组成部分但是可以含有空值NULL

> 如果对于一个列的定义，同时满足上述4种情况的多种，比如一个列既是PRI，又是UNI（如果是PRI，则一定是UNI）那么"desc 表名"; 的时候，显示的Key值按照优先级来显示 PRI->UNI->MUL,  那么此时，显示PRI。

> 如果某列不能含有空值，同时该表没有主键，则一个唯一性索引列可以显示为PRI，

> 如果多列构成了一个唯一性复合索引，那么一个唯一性索引列可以显示为MUL。（因为虽然索引的多列组合是唯一的，比如ID+NAME是唯一的，但是每一个单独的列依然可以有重复的值，因为只要ID+NAME是唯一的即可）


##### key与primary key区别 

tb3
```shell
# /sqls/tb3.sql
CREATE TABLE IF NOT EXISTS tb3(
	logrecord_id INT(11) NOT NULL AUTO_INCREMENT,
	user_name VARCHAR(100) DEFAULT NULL,
	operation_time DATETIME DEFAULT NULL,
	logrecord_operation VARCHAR(100) DEFAULT NULL,
	PRIMARY KEY (logrecord_id),
	KEY tb3_user_name (user_name)
	);

	dev@testdb>source /sqls/tb3.sql;
Query OK, 0 rows affected (0.05 sec)

dev@testdb>desc tb3;
+---------------------+--------------+------+-----+---------+----------------+
| Field               | Type         | Null | Key | Default | Extra          |
+---------------------+--------------+------+-----+---------+----------------+
| logrecord_id        | int(11)      | NO   | PRI | NULL    | auto_increment |
| user_name           | varchar(100) | YES  | MUL | NULL    |                |
| operation_time      | datetime     | YES  |     | NULL    |                |
| logrecord_operation | varchar(100) | YES  |     | NULL    |                |
+---------------------+--------------+------+-----+---------+----------------+
4 rows in set (0.00 sec)
```

`KEY tb3_user_name (user_name)`
本表的user_name字段与tb3_user_name表user_name字段建立外键
括号外是建立外键的对应表，括号内是对应字段
类似还有 KEY user(userid)
当然，key未必都是外键

总结：
Key是索引约束，对表中字段进行约束索引的，都是通过primary foreign unique等创建的。常见有foreign key，外键关联用的。
```shell
KEY forum (status,type,displayorder)  # 是多列索引（键）
KEY tid (tid)                         # 是单列索引（键）。
```
如建表时： KEY forum (status,type,displayorder)
select * from table group by status,type,displayorder 是否就自动用上了此索引，
而当 select * from table group by status 此索引有用吗？

> **key的用途：主要是用来加快查询速度的。**

```shell
CREATE TABLE `admin_role` (
  `adminSet_id` varchar(32) NOT NULL,
  `roleSet_id` varchar(32) NOT NULL,
  PRIMARY KEY (`adminSet_id`,`roleSet_id`),
  KEY `FK9FC63FA6DAED032` (`adminSet_id`),
  KEY `FK9FC63FA6C7B24C48` (`roleSet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

主键，两个列组合在一起，是唯一的，内建唯一性索引，并且不能为NULL
另外，两个Key定义，相当于分别对这两列建立索引。

> 在innodb存储引擎中, primary key 创建主键聚集索引, 而key创建的是普通索引

##### KEY与INDEX区别

KEY通常是INDEX同义词。如果关键字属性PRIMARY KEY在列定义中已给定，则PRIMARY KEY也可以只指定为KEY。

PRIMARY KEY是一个唯一KEY，此时，所有的关键字列必须定义为NOT NULL。

如果这些列没有被明确地定义为NOT NULL，MySQL应隐含地定义这些列。一个表只有一个PRIMARY KEY。



MySQL 中Index 与Key 的区别

Key即键值，是关系模型理论中的一部份，比如有主键（Primary Key)，外键（Foreign Key）等，用于数据完整性与唯一性约束等。

而Index则处于实现层面，比如可以对表的任意列建立索引，那么当建立索引的列处于SQL语句中的Where条件中时，就可以得到快速的数据定位，从而快速检索。

至于Unique Index，则只是属于Index中的一种而已，建立了Unique Index表示此列数据不可重复，猜想MySQL对Unique Index类型的索引可以做进一步特殊优化吧。

在设计表的时候，Key只是要处于模型层面的，而当需要进行查询优化，则对相关列建立索引即可。

另外，在MySQL中，对于一个Primary Key的列，MySQL已经自动对其建立了Unique Index，无需重复再在上面建立索引了。

##### UNIQUE KEY和PRIMARY KEY区别

- primary key的1个或多个列必须为NOT NULL，如果列为NULL，在增加PRIMARY KEY时，列自动更改为NOT NULL。而UNIQUE KEY 对列没有此要求

- 一个表只能有一个PRIMARY KEY，但可以有多个UNIQUE KEY

- 主键和唯一键约束是通过参考索引实施的，如果插入的值均为NULL，则根据索引的原理，全NULL值不被记录在索引上，所以插入全NULL值时，可以有重复的，而其他的则不能插入重复值。
```shell
alter table t add constraint uk_t_1 unique (a,b);
insert into t (a ,b ) values (null,1);    # 不能重复
insert into t (a ,b ) values (null,null);#可以重复
```

##### UNIQUE KEY 
UNIQUE KEY的用途：主要是用来防止数据插入的时候重复的。

建表时创建UNIQUE KEY 
```shell

CREATE TABLE Persons 
( 
Id int NOT NULL, 
LastName varchar(255) NOT NULL UNIQUE KEY, 
FirstName varchar(255), 
Address varchar(255), 
City varchar(255), 
UNIQUE (Id) 
#CONSTRAINT uc_PersonID UNIQUE (Id, LastName) 
);
```

增加UNIQUE KEY 
```shell

ALTER TABLE Persons
ADD UNIQUE (Id);

ALTER TABLE Persons
ADD CONSTRAINT uc_PersonID UNIQUE (Id,LastName);
```

撤销UNIQUE KEY 
```shell
ALTER TABLE Persons
DROP INDEX uc_PersonID;
```

##### 总结
- mysql索引概述, sql脚本载入环境准备;
- 分析key/primarykey/uniquekey与index区别;
- 总结key与primary key区别;
- 进一步总结KEY与INDEX区别;
- 进一步总结UNIQUE KEY和PRIMARY KEY区别;
- 进一步归纳UNIQUE KEY基本操作;
