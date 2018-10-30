---
title: "mysql专题03  数据库约束系列问题"
date: 2018-04-05 15:51:49
categories: "mysql专题"
tags: [mysql]
description:
---
`Mysql`数据库的约束类型有:主键约束（Primary Key）,外键约束（Foreign Key）,非空约束（Not Null）,唯一性约束（Unique）,默认约束（Default）。 约束的作用是保证数据的完整性和一致性, 分为表级约束和列级约束。
<!--more-->

##### 约束类型

|序号|约束类型 | 约束说明|
|:---|:---|:---|
|1|`NOT NULL`    |非空约束|
|2|`PRIMARY KEY` |主键约束|
|3|`UNIQUE KEY`  |唯一约束|
|4|`DEFAULT`     |默认约束|
|5|`FOREIGN KEY` |外键约束|

##### 主键约束
主键约束(primary key)要求主键列的数据唯一, 并且不能为空。主键分为两种类型: 单字段主键和多字段联合主键。
1.单字段主键
在定义列的同时指定主键, 语法规则: `字段名 数据类型 Primary Key [默认值]`
```shell
dev@testdb>create table if not exists t4(
    -> id INT(11) PRIMARY KEY,
    -> name VARCHAR(255),
    -> sex INT(11),
    -> age INT(11));
Query OK, 0 rows affected (0.02 sec)

dev@testdb>show columns from t4;
+-------+--------------+------+-----+---------+-------+
| Field | Type         | Null | Key | Default | Extra |
+-------+--------------+------+-----+---------+-------+
| id    | int(11)      | NO   | PRI | NULL    |       |
| name  | varchar(255) | YES  |     | NULL    |       |
| sex   | int(11)      | YES  |     | NULL    |       |
| age   | int(11)      | YES  |     | NULL    |       |
+-------+--------------+------+-----+---------+-------+
4 rows in set (0.00 sec)
```

在定义完成所有列之后指定主键, 语法规则: `[Constraint<约束名>] Primary Key [字段名]`
```shell
dev@testdb>create table if not exists t5(
    -> id INT(11),
    -> name VARCHAR(255),
    -> sex INT(11),
    -> age INT(11),
    -> Constraint pr_id PRIMARY KEY(id));
Query OK, 0 rows affected (0.02 sec)

dev@testdb>desc t5;
+-------+--------------+------+-----+---------+-------+
| Field | Type         | Null | Key | Default | Extra |
+-------+--------------+------+-----+---------+-------+
| id    | int(11)      | NO   | PRI | NULL    |       |
| name  | varchar(255) | YES  |     | NULL    |       |
| sex   | int(11)      | YES  |     | NULL    |       |
| age   | int(11)      | YES  |     | NULL    |       |
+-------+--------------+------+-----+---------+-------+
4 rows in set (0.00 sec)
```

一般建议将主键放在所有列后面声明;

多字段联合主键
主键由多个字段联合组成。语法规则: `Primary Key[字段1, 字段2, ...., 字段n]`

```shell
dev@testdb>create table t6(
    -> id INT(11),
    -> name VARCHAR(255),
    -> sex INT(11),
    -> age INT(11),
    -> PRIMARY KEY(id, name));
Query OK, 0 rows affected (0.01 sec)

dev@testdb>desc t6;
+-------+--------------+------+-----+---------+-------+
| Field | Type         | Null | Key | Default | Extra |
+-------+--------------+------+-----+---------+-------+
| id    | int(11)      | NO   | PRI | NULL    |       |
| name  | varchar(255) | NO   | PRI | NULL    |       |
| sex   | int(11)      | YES  |     | NULL    |       |
| age   | int(11)      | YES  |     | NULL    |       |
+-------+--------------+------+-----+---------+-------+
4 rows in set (0.00 sec)
```

##### 外键约束
外键约束(Foreign Key)用来在两个表的数据之间建立连接, 它可以是一列或者多列。一个表可以有一个或者多个外键。一个表的外键可以为空, 若不为空, 则每一个外键值必须等于另一个表中主键的某个值。

外键的作用:保持数据一致性, 完整性, 可以实现表与表之间一对一或一对多关系。

主表(父表):对于两个具有关联关系的表而言, 相关联字段中的主键所在的那个表即是主表。

从表(子表):对于两个具有关联关系的表而言, 相关联字段中的外键所在的那个表即是从表。

外键约束条件,

- 父表和子表必须有相同的存储引擎, 且存储引擎必须是InnoDB。这个可以在数据MySql的配置文件中查看及修改;

- 不能使用临时表进行操作, 且外键列和参照列必须具有相似的数据类型, 如果是以数字类型作为外键, 则数据符号及长度要相同;

- 外键列和参照列必须创建索引, 如果外键列不存在索引的话, MySql将自动创建索引;

外键约束参照操作,

|参照操作类型|说明|
|:---|:---|
|`CASCADE`  |父表进行删除或更新操作, 将自动删除或更新子表中匹配的数据。|
|`SET NULL` |父表进行删除或更新操作, 将子表中对应数据外键设备为NULL。如果使用此参照类型, 子表对应字段没有指定NOT NULL。|
|`RESTRICT` |拒绝对父表进行删除或更新操作。|
|`NO ACTION`|MySql中的关键字, 与RESTRICT的作用相同 。|

语法规则: `[Constraint<外键名>]Foreign Key 字段名1[,字段名2, ....] References<主表名> 主键列1 [,主键列2, ....]`

```shell
dev@testdb>create table if not exists t7(
    -> id INT(11),
    -> name VARCHAR(255) NOT NULL,
    -> sex INT(11),
    -> age INT(11),
    -> PRIMARY KEY(id));
Query OK, 0 rows affected (0.02 sec)

dev@testdb>create table if not exists t8(
    -> id INT(11) PRIMARY KEY,
    -> name VARCHAR(255),
    -> deptID INT(11),
    -> age INT(11),
    -> CONSTRAINT c_deptID FOREIGN KEY(deptID) REFERENCES t7(id)
    -> );
Query OK, 0 rows affected (0.02 sec)

dev@testdb>desc t8;
+--------+--------------+------+-----+---------+-------+
| Field  | Type         | Null | Key | Default | Extra |
+--------+--------------+------+-----+---------+-------+
| id     | int(11)      | NO   | PRI | NULL    |       |
| name   | varchar(255) | YES  |     | NULL    |       |
| deptID | int(11)      | YES  | MUL | NULL    |       |
| age    | int(11)      | YES  |     | NULL    |       |
+--------+--------------+------+-----+---------+-------+
4 rows in set (0.00 sec)

dev@testdb>desc t7;
+-------+--------------+------+-----+---------+-------+
| Field | Type         | Null | Key | Default | Extra |
+-------+--------------+------+-----+---------+-------+
| id    | int(11)      | NO   | PRI | NULL    |       |
| name  | varchar(255) | NO   |     | NULL    |       |
| sex   | int(11)      | YES  |     | NULL    |       |
| age   | int(11)      | YES  |     | NULL    |       |
+-------+--------------+------+-----+---------+-------+
4 rows in set (0.00 sec)
```
定义数据表t8,让它的主键deptID作为外键关联到的t7的主键id,在表t8上添加了名称为c_deptID的外键约束, 外键名称为deptID,其依赖于表t8的主键id.

##### 使用非空约束
非空约束(NOT NULL)指字段的值不能为空。

语法规则:`字段名 数据类型 NOT NULL`

##### 唯一性约束
唯一性约束(Unique)要求该列唯一, 允许为空, 但是只能出现一个空值。唯一约束可以保证一列或者几列不出现重复值。
非空约束的语法规则,
 1.在定义完列之后直接指定唯一约束 
  `字段名 数据类型 unique`
 2.在定义完所有列之后指定唯一约束
   `[Constraint<约束名>] Unique(<字段名>)`
声明: Unique在表中可以有一个或者多个字段声明, 而Primary Key, 只能有一个。

##### 默认约束
默认约束(Default)指定某列的默认值。
语法规则: `字段名 数据类型 Dfault 默认值`

```shell
dev@testdb>create table t9(
    -> id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    -> username VARCHAR(20) NOT NULL UNIQUE KEY,
    -> sex ENUM('1','2','3') DEFAULT '3'
    -> );
Query OK, 0 rows affected (0.07 sec)

dev@testdb>show columns from t9;
+----------+----------------------+------+-----+---------+----------------+
| Field    | Type                 | Null | Key | Default | Extra          |
+----------+----------------------+------+-----+---------+----------------+
| id       | smallint(5) unsigned | NO   | PRI | NULL    | auto_increment |
| username | varchar(20)          | NO   | UNI | NULL    |                |
| sex      | enum('1','2','3')    | YES  |     | 3       |                |
+----------+----------------------+------+-----+---------+----------------+
3 rows in set (0.01 sec)

dev@testdb>insert t9 values('Mike');
ERROR 1136 (21S01): Column count doesn't match value count at row 1
dev@testdb>insert t9 (username) values('Mike');
Query OK, 1 row affected (0.01 sec)

dev@testdb>select * from t9;
+----+----------+------+
| id | username | sex  |
+----+----------+------+
|  1 | Mike     | 3    |
+----+----------+------+
1 row in set (0.00 sec)
```

##### 总结
- 归类阐述了`Mysql` 五类约束, 包括非空约束(NOT NULL), 主键约束(PRIMARY KEY), 外键约束(FOREIGN KEY), 唯一性约束(UNIQUE)和默认约束(DEFAULT);
- 实例分析了两类主键约束, 单主键约束及多主键约束; 
- 实例分析了外键约束的目的, 约束条件，及执行参照操作等; 
- 进一步阐述总结了唯一性约束, 非空值约束及默认约束;

