---
title: "mysql专题05 数据库约束关系实践"
date: 2018-07-21 19:33:18
categories: "mysql专题"
tags: [mysql]
description:
---
本文从实践的角度对`Mysql`五类约束关系深入学习实践;
<!--more-->

##### 容器环境
***
容器环境需要满足,
- 支持自定义`my.cnf`配置文件;
- 支持`source`命令引入`sql`脚本文件;
- 支持普通账号建立;

> 本文使用docker-compose 可见于[docker-compose-single-mysql](https://github.com/researchlab/docker-envs/tree/master/mysql/docker-compose-single-mysql)

##### 外键约束
***
- 外键约束条件
  - 父表和子表必须有相同的存储引擎, 且存储引擎必须是`InnoDB`。这个可以在数据`Mysql`的配置文件中查看及修改;
  - 不能用临时表进行操作, 且外键列和参照列必须具有相似的数据类型, 如果是以数字类型作为外键, 则数据符号及长度要相同;
  - 外键列和参照列必须创建索引, 如果外键列不存在索引的话, `Mysql`将自动创建索引;

> 约束分为物理约束和逻辑约束, 目前只有`InnoDB`存储引擎支持物理约束操作, 所以通常将的外键约束要求之一就是主外键表必须就有相同的存储引擎且存储引擎为`InnoDB`，但实际开发中通常采用的是逻辑约束， 所谓的逻辑约束及在设计和使用表时仅是认为按照约束的相关条例来操作, 而不实际使用`FOREIGN KEY`关键字来进行物理约束操作;

主表tb4, 子表tb5,
```shell
#tb4.sql
CREATE TABLE IF NOT EXISTS tb4(
	id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	pname VARCHAR(20) NOT NULL
	);

#cmd
dev@testdb>source /sqls/tb4.sql;
Query OK, 0 rows affected (0.21 sec)

dev@testdb>show create table tb4 \G:
*************************** 1. row ***************************
       Table: tb4
Create Table: CREATE TABLE `tb4` (
  `id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `pname` varchar(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
1 row in set (0.00 sec)

#tb5 外键pid 与主表数据类型不同
CREATE TABLE IF NOT EXISTS tb5(
	id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	username VARCHAR(10) NOT NULL,
	pid BIGINT,
	FOREIGN KEY (pid) REFERENCES tb4 (id)
	);
dev@testdb>source /sqls/tb5.sql;
ERROR 1215 (HY000): Cannot add foreign key constraint

#tb5 外键pid 与主表数据类型相同但符号不相同
CREATE TABLE IF NOT EXISTS tb5(
	id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	username VARCHAR(10) NOT NULL,
	pid SMALLINT,
	FOREIGN KEY (pid) REFERENCES tb4 (id)
	);
dev@testdb>source /sqls/tb5.sql;
ERROR 1215 (HY000): Cannot add foreign key constraint

#tb5 外键pid数据类型及符号都与主表主键相同
CREATE TABLE IF NOT EXISTS tb5(
	id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	username VARCHAR(10) NOT NULL,
	pid SMALLINT UNSIGNED,
	FOREIGN KEY (pid) REFERENCES tb4 (id)
	);
dev@testdb>source /sqls/tb5.sql;
Query OK, 0 rows affected (0.21 sec)

dev@testdb>show create table tb5 \G:
*************************** 1. row ***************************
       Table: tb5
Create Table: CREATE TABLE `tb5` (
  `id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(10) NOT NULL,
  `pid` smallint(5) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `pid` (`pid`),
  CONSTRAINT `tb5_ibfk_1` FOREIGN KEY (`pid`) REFERENCES `tb4` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
1 row in set (0.01 sec)
```

- 主表与子表必须都使用`InnoDB`存储引擎;
- 上述示例中主表tb4主键id为参照列, 而子表外键pid 为外键列;
- 外键列和参照列必须具有相似的数据类型, 其中数字的长度及是否有符号位必须相同，而字符的长度则可以不同;

mysql将会为外键列和参照列创建索引, 
```shell
dev@testdb>show index from tb4 \G:
*************************** 1. row ***************************
        Table: tb4
   Non_unique: 0
     Key_name: PRIMARY
 Seq_in_index: 1
  Column_name: id
    Collation: A
  Cardinality: 0
     Sub_part: NULL
       Packed: NULL
         Null:
   Index_type: BTREE
      Comment:
Index_comment:
      Visible: YES
1 row in set (0.00 sec)

dev@testdb>show index from tb5 \G:
*************************** 1. row ***************************
        Table: tb5
   Non_unique: 0
     Key_name: PRIMARY
 Seq_in_index: 1
  Column_name: id
    Collation: A
  Cardinality: 0
     Sub_part: NULL
       Packed: NULL
         Null:
   Index_type: BTREE
      Comment:
Index_comment:
      Visible: YES
*************************** 2. row ***************************
        Table: tb5
   Non_unique: 1
     Key_name: pid
 Seq_in_index: 1
  Column_name: pid
    Collation: A
  Cardinality: 0
     Sub_part: NULL
       Packed: NULL
         Null: YES
   Index_type: BTREE
      Comment:
Index_comment:
      Visible: YES
2 rows in set (0.11 sec)
```

##### 参照操作
***

外键约束的参照操作指在创建了外键约束后，在更新主表时, 子表是否也应进行相应的操作, 主要分为四类参照操作,

|操作名称| 操作说明|
|:---|:---|
|`CASCADE`|从父表删除或更新且自动删除或更新子表中匹配的行|
|`SET NULL`|从父表删除或更新行, 并设置子表中的外键列为`NULL`, 如果使用该选项, 必须保证子表列没有指定`NOT NULL`|
|`RESTRICT`|拒绝对父表的删除或更新操作|
|`NO ACTION`|标准SQL的关键字, 在MySQL中与`RESTRICT`相同|

`CASCADE`示例,

```shell
#tb6.sql
CREATE TABLE IF NOT EXISTS tb6(
	id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	username VARCHAR(10) NOT NULL,
	pid SMALLINT UNSIGNED,
	FOREIGN KEY (pid) REFERENCES tb4 (id) ON DELETE CASCADE
	);

	#cmd
dev@testdb>source /sqls/tb6.sql;
Query OK, 0 rows affected (0.06 sec)

dev@testdb>show create table tb6 \G:
*************************** 1. row ***************************
       Table: tb6
Create Table: CREATE TABLE `tb6` (
  `id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(10) NOT NULL,
  `pid` smallint(5) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `pid` (`pid`),
  CONSTRAINT `tb6_ibfk_1` FOREIGN KEY (`pid`) REFERENCES `tb4` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8
1 row in set (0.00 sec)
```

先插入数据然后执行删除操作

```shell
dev@testdb>select * from tb4;
+----+-------+
| id | pname |
+----+-------+
|  1 | A     |
|  2 | B     |
|  3 | C     |
+----+-------+
3 rows in set (0.01 sec)

dev@testdb>insert tb6 (username, pid) values('Tom',3), ('Mike',1),('Jack',3);
Query OK, 3 rows affected (0.05 sec)
Records: 3  Duplicates: 0  Warnings: 0

dev@testdb>select * from tb6;
+----+----------+------+
| id | username | pid  |
+----+----------+------+
|  1 | Tom      |    3 |
|  2 | Mike     |    1 |
|  3 | Jack     |    3 |
+----+----------+------+
3 rows in set (0.00 sec)

# 当子表中插入的外键值在主表中不存在时 插入失败;
dev@testdb>insert tb6 (username, pid) values('Rose',7);
ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails (`testdb`.`tb6`, CONSTRAINT `tb6_ibfk_1` FOREIGN KEY (`pid`) REFERENCES `tb4` (`id`) ON DELETE CASCADE)
dev@testdb>

#删除主表id=3的记录，发现子表的相应行业执行了删除操作， 因为子表外键设置了 ON DELETE CASCADE参照操作
dev@testdb>delete from tb4 where id='3';
Query OK, 1 row affected (0.01 sec)

dev@testdb>select * from tb4;
+----+-------+
| id | pname |
+----+-------+
|  1 | A     |
|  2 | B     |
+----+-------+
2 rows in set (0.00 sec)

dev@testdb>select * from tb6;
+----+----------+------+
| id | username | pid  |
+----+----------+------+
|  2 | Mike     |    1 |
+----+----------+------+
1 row in set (0.00 sec)
```

- 注意 因为子表是参照父表进行数据操作的，所以应先对父表插入数据再对子表插入相应记录的数据; 
- 删除主表id=3的记录，发现子表的相应行业执行了删除操作， 因为子表外键设置了 ON DELETE CASCADE参照操作

`SET NULL`示例,

```shell
CREATE TABLE IF NOT EXISTS tb6(
	id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	username VARCHAR(10) NOT NULL,
	pid SMALLINT UNSIGNED,
	FOREIGN KEY (pid) REFERENCES tb4 (id) ON DELETE SET NULL
	);

dev@testdb>insert tb6 (username, pid) values('Tom','1'), ('Jack', '1'), ('Mike','2');
Query OK, 3 rows affected (0.09 sec)
Records: 3  Duplicates: 0  Warnings: 0

dev@testdb>select * from tb6;
+----+----------+------+
| id | username | pid  |
+----+----------+------+
|  1 | Tom      |    1 |
|  2 | Jack     |    1 |
|  3 | Mike     |    2 |
+----+----------+------+
3 rows in set (0.00 sec)

dev@testdb>delete from tb4 where id=1;
Query OK, 1 row affected (0.09 sec)

dev@testdb>select * from tb6;
+----+----------+------+
| id | username | pid  |
+----+----------+------+
|  1 | Tom      | NULL |
|  2 | Jack     | NULL |
|  3 | Mike     |    2 |
+----+----------+------+
3 rows in set (0.00 sec)
```

- `SET NULL` 参照操作仅将匹配的外键值设置为`NULL`, 并不会把子表中相应行数据删除

`RESTRICT` 与`NO ACTION`示例是一样的， 设置了之后主表执行删除操作将会报错，执行失败, 

```shell
FOREIGN KEY (pid) REFERENCES tb4 (id) ON DELETE RESTRICT 

FOREIGN KEY (pid) REFERENCES tb4 (id) ON DELETE NO ACTION

dev@testdb>delete from tb4 where id=2;
ERROR 1451 (23000): Cannot delete or update a parent row: a foreign key constraint fails (`testdb`.`tb6`, CONSTRAINT `tb6_ibfk_1` FOREIGN KEY (`pid`) REFERENCES `tb4` (`id`))
dev@testdb>
```

##### 表级约束与列级约束
***
对一个数据列建立约束, 称为列级约束; 
对多个数据列建立约束, 称为表级约束;
列级约束既可以在列定义时声明, 也可以在列定义后声明;
表级约束只能在列定义后声明;

只有PRIMARY KEY, UNIQUE KEY, FOREIGN KEY 存在表级约束, NOT NULL 和DEFAULT约束则只有列级约束;

##### 表属性及约束属性操作
***
添加单列
- ALTER TABLE tbl_name ADD [COLUMN] col_name column_definition [FIRST | AFTER col_name]

```shell
dev@testdb>ALTER TABLE tb6 ADD age TINYINT UNSIGNED NOT NULL DEFAULT 10;
Query OK, 0 rows affected (0.05 sec)
Records: 0  Duplicates: 0  Warnings: 0

dev@testdb>show create table tb6 \G
*************************** 1. row ***************************
       Table: tb6
Create Table: CREATE TABLE `tb6` (
  `id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(10) NOT NULL,
  `pid` smallint(5) unsigned DEFAULT NULL,
  `age` tinyint(3) unsigned NOT NULL DEFAULT '10',
  PRIMARY KEY (`id`),
  KEY `pid` (`pid`),
  CONSTRAINT `tb6_ibfk_1` FOREIGN KEY (`pid`) REFERENCES `tb4` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8
1 row in set (0.00 sec)

dev@testdb>ALTER TABLE tb6 ADD pwd VARCHAR(32) NOT NULL AFTER username;
Query OK, 0 rows affected (0.17 sec)
Records: 0  Duplicates: 0  Warnings: 0

dev@testdb>ALTER TABLE tb6 ADD realname VARCHAR(20) NOT NULL FIRST;
Query OK, 0 rows affected (0.24 sec)
Records: 0  Duplicates: 0  Warnings: 0

dev@testdb>desc tb6;
+----------+----------------------+------+-----+---------+----------------+
| Field    | Type                 | Null | Key | Default | Extra          |
+----------+----------------------+------+-----+---------+----------------+
| realname | varchar(20)          | NO   |     | NULL    |                |
| id       | smallint(5) unsigned | NO   | PRI | NULL    | auto_increment |
| username | varchar(10)          | NO   |     | NULL    |                |
| pwd      | varchar(32)          | NO   |     | NULL    |                |
| pid      | smallint(5) unsigned | YES  | MUL | NULL    |                |
| age      | tinyint(3) unsigned  | NO   |     | 10      |                |
+----------+----------------------+------+-----+---------+----------------+
6 rows in set (0.00 sec)

dev@testdb>
```

添加多列
- ALTER TABLE tbl_name ADD [COLUMN] (col_name column_defintion, ...)
- 添加单列可以不需要括号, 可以指定添加到最前面FIRST,或者某个字段的后面AFTER, 不指定则添加到最后;
- 添加多列需要用括号, 只能从表最后添加;

删除列
- ALTER TABLE tbl_name DROP [COLUMN] col_name

数据表可以支持一条命令进行多个操作, 操作之间通过逗号,分割, 如同时删除两列和添加一列, 
```shell
dev@testdb>ALTER TABLE tb6 DROP pwd, DROP firstname, ADD lastname VARCHAR(20) NOT NULL;
Query OK, 0 rows affected (0.20 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

- `Mysql`默认是开启事务的，所以一条命令中存在执行错误，那整个命令都不会被执行，执行部分会被回滚;

添加(主键)约束
`ALTER TABLE tbl_name ADD [CONSTRAINT [symbol]] PRIMARY KEY [index_type] (index_col_name,...)`

```shell
dev@testdb>CREATE TABLE tb7(
    -> username VARCHAR(10) NOT NULL,
    -> pid SMALLINT UNSIGNED
    -> );
Query OK, 0 rows affected (0.07 sec)

dev@testdb>desc tb7;
+----------+----------------------+------+-----+---------+-------+
| Field    | Type                 | Null | Key | Default | Extra |
+----------+----------------------+------+-----+---------+-------+
| username | varchar(10)          | NO   |     | NULL    |       |
| pid      | smallint(5) unsigned | YES  |     | NULL    |       |
+----------+----------------------+------+-----+---------+-------+
2 rows in set (0.00 sec)

dev@testdb>ALTER TABLE tb7 ADD id SMALLINT UNSIGNED;
Query OK, 0 rows affected (0.09 sec)
Records: 0  Duplicates: 0  Warnings: 0

dev@testdb>ALTER TABLE tb7 ADD CONSTRAINT pk_tb7_id PRIMARY KEY (id);
Query OK, 0 rows affected (0.08 sec)
Records: 0  Duplicates: 0  Warnings: 0

dev@testdb>desc tb7;
+----------+----------------------+------+-----+---------+-------+
| Field    | Type                 | Null | Key | Default | Extra |
+----------+----------------------+------+-----+---------+-------+
| username | varchar(10)          | NO   |     | NULL    |       |
| pid      | smallint(5) unsigned | YES  |     | NULL    |       |
| id       | smallint(5) unsigned | NO   | PRI | NULL    |       |
+----------+----------------------+------+-----+---------+-------+
3 rows in set (0.00 sec)
```
- 索引类型分为B+树索引和哈希索引，默认是B+树索引;

添加唯一约束

- ALTER TABLE tbl_name ADD [CONSTRAINT [symbol]] UNIQUE [INDEX|KEY] [index_name] [index_type] (index_col_name,...)

```shell
dev@testdb>ALTER TABLE tb7 ADD UNIQUE (username);
Query OK, 0 rows affected (0.07 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

添加外键约束

- ALTER TABLE tbl_name ADD [CONSTRAINT [symbol]] FOREIGN KEY [index_name](index_col_name,...) reference_definition

```shell
dev@testdb>ALTER TABLE tb7 ADD FOREIGN KEY (pid) REFERENCES tb4 (id);
Query OK, 0 rows affected (0.14 sec)
Records: 0  Duplicates: 0  Warnings: 0

dev@testdb>show create table tb7 \G
*************************** 1. row ***************************
       Table: tb7
Create Table: CREATE TABLE `tb7` (
  `username` varchar(10) NOT NULL,
  `pid` smallint(5) unsigned DEFAULT NULL,
  `id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  KEY `pid` (`pid`),
  CONSTRAINT `tb7_ibfk_1` FOREIGN KEY (`pid`) REFERENCES `tb4` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
1 row in set (0.00 sec)
```

添加/删除默认约束
- ALTER TABLE tbl_name ALTER [COLUMN] COL_name {SET DEFAULT literal | DROP DEFAULT}

```shell
dev@testdb>ALTER TABLE tb7 ALTER age SET DEFAULT 15;
Query OK, 0 rows affected (0.09 sec)
Records: 0  Duplicates: 0  Warnings: 0

dev@testdb>desc tb7;
+----------+----------------------+------+-----+---------+-------+
| Field    | Type                 | Null | Key | Default | Extra |
+----------+----------------------+------+-----+---------+-------+
| age      | tinyint(3) unsigned  | NO   |     | 15      |       |
+----------+----------------------+------+-----+---------+-------+
1 rows in set (0.00 sec)

dev@testdb>ALTER TABLE tb7 ALTER age DROP DEFAULT;
Query OK, 0 rows affected (0.08 sec)
Records: 0  Duplicates: 0  Warnings: 0

dev@testdb>desc tb7;
+----------+----------------------+------+-----+---------+-------+
| Field    | Type                 | Null | Key | Default | Extra |
+----------+----------------------+------+-----+---------+-------+
| age      | tinyint(3) unsigned  | NO   |     | NULL    |       |
+----------+----------------------+------+-----+---------+-------+
1 rows in set (0.00 sec)
```

删除主键约束

- ALTER TABLE tbl_name DROP PRIMARY KEY

删除唯一约束

- ALTER TABLE tbl_name DROP {INDEX|KEY} index_name

```shell
dev@testdb>show index from tb7 \G
*************************** 1. row ***************************
...
*************************** 2. row ***************************
        Table: tb7
   Non_unique: 0
     Key_name: username
 Seq_in_index: 1
  Column_name: username
    Collation: A
  Cardinality: 0
     Sub_part: NULL
       Packed: NULL
         Null:
   Index_type: BTREE
      Comment:
Index_comment:
      Visible: YES
3 rows in set (0.00 sec)

dev@testdb>ALTER TABLE tb7 DROP username;
Query OK, 0 rows affected (0.08 sec)
Records: 0  Duplicates: 0  Warnings: 0

dev@testdb>show index from tb7 \G
*************************** 1. row ***************************
...
2 rows in set (0.00 sec)
```

- 删除的是UNIQUE KEY 约束， DROP 约束中的Key_name;

删除外键约束 

- ALTER TABLE tbl_name DROP FOREIGN KEY fk_symbol

通过show create table tb7 来查看`fk_symbol`名称;

修改列定义

- ALTER TABLE tbl_name MODIFY [COLUMN] col_name column_defintion [FIRST | AFTER col_name]

- 修改列定义时 将大数据类型修改为小数据类型时 将使得数据范围变小，要特别注意;

修改列名称
- ALTER TABLE tbl_name CHANGE [COLUMN] old_col_name new_col_name column_definition [FIRST|AFTER col_name]

修改数据表的名称

方法一
`ALTER TABLE tbl_name RENAME [TO|AS] new_tbl_name`

方法二
RENAME TABLE tbl_name TO new_tbl_name [,tbl_name2 TO new_tbl_name2]...

##### 总结
* * * 
- 约束按照功能可划分为非空约束,主键约束,唯一约束,默认约束,外键约束五类, 按照约束的数据列多少可以划分为表级约束和列级约束;
- 外键约束实例操作说明;
- 外键参照约束实例操作说明;
- 针对数据字段的操作有添加/删除字段,修改列定义/列名称等示例说明;
- 针对约束的操作有添加/删除五类约束的示例说明;
- 两种修改数据表名的方式;
