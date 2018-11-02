---
title: "mysql专题10 存储过程及存储引擎"
date: 2018-10-03 08:52:02
categories: "mysql专题"
tags: [mysql]
description:
---
`MySQL 5.0`开始支持存储过程，这样大大提高数据库的处理速度，同时也可以提高数据库编程的灵活性。SQL语句需要先编译然后执行，而存储过程（Stored Procedure）是一组为了完成特定功能的SQL语句集，经编译后存储在数据库中，用户通过指定存储过程的名字并给定参数（如果该存储过程带有参数）来调用执行它。
<!--more-->

为何要使用存储过程? 

经常需要对数据进行SQL CURD操作, 那么一条SQL语句从输入MySQL执行开始到得到结果为止需要经历哪些过程呢?

一条SQL语句在Mysql中执行经过,

```shell
SQL命令--> MySQL引擎--(分析)-->如果语法、词法正确--(翻译)--> 可识别命令--(执行)-->执行结果--(返回)--> 客户端
```

存储过程是SQL语句和控制语句的预编译集合, 以一个名词存储并作为一个单元处理; 存储过程只在第一次执行时需要进行语法分析和编译处理, 之后再次执行存储过程就直接执行, 而不再需要进行语法分析及编译等过程, 从而可以提高Mysql的执行效率; 

# 存储过程概念

存储过程是可编程的函数，在数据库中创建并保存，可以由SQL语句和控制结构组成。当想要在不同的应用程序或平台上执行相同的函数，或者封装特定功能时，存储过程是非常有用的。数据库中的存储过程可以看做是对编程中面向对象方法的模拟，它允许控制数据的访问方式。


存储过程的优点:
- 增强SQL语言的功能和灵活性: 存储过程可以用控制语句编写，有很强的灵活性，可以完成复杂的判断和较复杂的运算。

- 标准组件式编程: 存储过程被创建后，可以在程序中被多次调用，而不必重新编写该存储过程的SQL语句。而且数据库专业人员可以随时对存储过程进行修改，对应用程序源代码毫无影响。
 
- 较快的执行速度: 如果某一操作包含大量的Transaction-SQL代码或分别被多次执行，那么存储过程要比批处理的执行速度快很多。因为存储过程是预编译的。在首次运行一个存储过程时查询，优化器对其进行分析优化，并且给出最终被存储在系统表中的执行计划。而批处理的Transaction-SQL语句在每次运行时都要进行编译和优化，速度相对要慢一些。
 
- 减少网络流量: 针对同一个数据库对象的操作（如查询、修改），如果这一操作所涉及的Transaction-SQL语句被组织进存储过程，那么当在客户计算机上调用该存储过程时，网络中传送的只是该调用语句，从而大大减少网络流量并降低了网络负载。
 
- 作为一种安全机制来充分利用: 通过对执行某一存储过程的权限进行限制，能够实现对相应的数据的访问权限的限制，避免了非授权用户对数据的访问，保证了数据的安全。

# 存储过程语法结构

Mysql存储过程语法结构解析 

创建存储过程语法结构

```shell
CREATE 
[DEFINER = {user |CURRENT_USER}]
PROCEDURE sp_name ([proc_parameter[,...]])
[characteristic ...] routine_body

proc_parameter:
[IN | OUT | INOUT ] param_name type 

COMMENT 'string'

| {CONTAINS SQL | NO SQL | READS SQL DATA | MODIFIES SQL DATA }
| SQL SECURITY {DEFINER | INVOKER}
```

- DEFINER 指创建者的名字, 默认是当前登录用户; 
- sp_name 即存储过程名称; 
- IN 表示该参数的值必须在调用存储过程时指定;
- OUT 表示该参数的值可以被存储过程改变, 并且可以返回;
- INOUT 表示该参数的调用时指定, 并且可以被改变和返回;
- COMMENT 注释
- CONTAINS SQL: 包含SQL语句, 但不包含读或写数据的语句;
- NO SQL: 不包含SQL语句;
- READS SQL DATA: 包含读数据的语句;
- MODIFIES SQL DATA: 包含写数据的语句;
- SQL SECURITY { DEFINER }INVOKER} 指明谁有权限来执行;

存储过程过程体规则
- 过程体由合法的SQL语句构成;
- 过程体可以是任意SQL语句;
- 过程体如果为复合结构则使用BEGIN...END语句;
- 复合结构可以包含声明, 循环,控制结构;

> 存储过程主要用于数据的CURD包含多表连接等操作;
> 不要通过存储过程去创建数据库/表等操作;


调用存储过程

- CALL sp_name ([(parameter[,...]])
- CALL sp_name[()]

# 无参数存储过程

创建不带参数存储过程

```shell
dev@testdb>dev@testdb>CREATE PROC SELECT VERSION();
Query OK, 0 rows affected (0.10 sec)

dev@testdb>CALL sp1;
+-----------+
| VERSION() |
+-----------+
| 8.0.12    |
+-----------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)

dev@testdb>CALL sp1();
+-----------+
| VERSION() |
+-----------+
| 8.0.12    |
+-----------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)
```

# 有参数存储过程

创建带有IN类型参数的存储过程

```shell
dev@testdb>CREATE PROCEDURE removeGoodsByID(IN id SMALLINT UNSIGNED)
    -> BEGIN
    -> DELETE FROM tdb_goods WHERE goods_id = id;
    -> END
    -> //
Query OK, 0 rows affected (0.01 sec)

dev@testdb>DELIMITER ;
dev@testdb>CALL removeGoodsByID(5);
Query OK, 1 row affected (0.02 sec)
```

> 注意 存储过程入参的参数名字不能与 待删除表的待判定的字段名称一样, 否则将执行全部删除, 

```shell
dev@testdb>DELIMITER //

dev@testdb>CREATE PROCEDURE remGoodsByID(IN goods_id SMALLINT UNSIGNED)
    -> BEGIN
    -> DELETE FROM tb13 WHERE goods_id = goods_id;
    -> END
    -> //
Query OK, 0 rows affected (0.07 sec)

dev@testdb>DELIMITER ;

dev@testdb>select * from tb13;
+----------+---------------------------------+---------+------------+-------------+---------+------------+
| goods_id | goods_name                      | cate_id | brand_name | goods_price | is_show | is_saleoff |
+----------+---------------------------------+---------+------------+-------------+---------+------------+
|        1 | R510VC 15.6英寸笔记本           |       1 | 华硕       |    3399.000 |       1 |          0 |
|        2 | Y400N 14.0英寸笔记本电脑        |       1 | 联想       |    4899.000 |       1 |          0 |
|        3 | Macbook pro 15.0英寸笔记本      |       5 | Apple      |  120000.000 |       1 |          0 |
|        4 | R510VC 15.6英寸笔记本           |       1 | 华硕       |    3399.000 |       1 |          0 |
|        5 | Y400N 12.0英寸笔记本电脑        |       1 | 联想       |    2899.000 |       1 |          0 |
|        6 | Macbook pro 15.0英寸笔记本      |       5 | Apple      |  120000.000 |       1 |          0 |
+----------+---------------------------------+---------+------------+-------------+---------+------------+
6 rows in set (0.00 sec)

dev@testdb>CALL remGoodsByID(5);
Query OK, 6 rows affected (0.06 sec)

dev@testdb>select * from tb13;
Empty set (0.00 sec)
```

# 修改存储过程

语法结构
```shell
ALTER PROCEDURE sp_name [ characteristic ...]

COMMENT 'string'

| { CONTAINS SQL | NO SQL | READS SQL DATA | MODIFIES SQL DATA }
| SQL SECURITY { DEFINER | INVOKER }

```

- 存储存储过程时 仅能修改注释, 内容的类型等, 并不能修改过程体;
- 若要修改过程体，只能先将存储过程删除，然后再重建;

# 删除存储过程

语法结构

```shell
DROP PROCEDURE [ IF EXISTS ] sp_name
```

用法举例

```shell
dev@testdb>drop procedure if exists sp1;
Query OK, 0 rows affected (0.06 sec)

#删除不存在的存储过程仅warning 无error
dev@testdb>DROP PROCEDURE IF EXISTS sp3;
Query OK, 0 rows affected, 1 warning (0.00 sec)
```

# 创建带IN和OUT类型参数的存储过程

实例 删除指定的数据行, 返回剩下的数据行数

```shell
dev@testdb>DELIMITER //
dev@testdb>CREATE PROCEDURE removeGoodsAndReturnGoodsNums(IN p_goods_id INT UNSIGNED, OUT goodsNums INT UNSIGNED)
    -> BEGIN
    -> DELETE FROM tdb_goods WHERE goods_id = p_goods_id;
    -> SELECT count(goods_id) FROM tdb_goods INTO goodsNums;
    -> END
    -> //
Query OK, 0 rows affected (0.01 sec)

dev@testdb>DELIMITER ;
dev@testdb>SELECT COUNT(goods_id) FROM tdb_goods;
+-----------------+
| COUNT(goods_id) |
+-----------------+
|              20 |
+-----------------+
1 row in set (0.01 sec)

dev@testdb>CALL removeGoodsAndReturnGoodsNums(1, @nums);
Query OK, 1 row affected (0.03 sec)

dev@testdb>SELECT @nums;
+-------+
| @nums |
+-------+
|    19 |
+-------+
1 row in set (0.00 sec)

```
- DECLARE 声明的变量为局部变量, 并且为BEGIN ... END 第一行 只在BEGIN...END内有效
- @nums @声明的变量 只在当前客户端有效; 通过SET设置的也是一样， 所以@变量称之为用户变量只在当前客户端有效;

```shell
dev@testdb>SET @i = 7;
Query OK, 0 rows affected (0.00 sec)

dev@testdb>SELECT @i;
+------+
| @i   |
+------+
|    7 |
+------+
1 row in set (0.00 sec)
```

# 带有多个OUT类型参数的存储过程

返回删除的用户数，返回剩余的用户数

数据准备

>  建表脚本及数据生成可参考[tb18_ddl.sql tb18_dml.sql](https://github.com/researchlab/docker-envs/tree/master/mysql/sqls)

```shell
dev@testdb>source /sqls/tb18_ddl.sql;
Query OK, 0 rows affected (0.07 sec)

dev@testdb>source /sqls/tb18_dml.sql;
...
Query OK, 1 row affected (0.01 sec)
dev@testdb>select * from tb18;
+----+----------+----------------------------------+------+------+
| id | username | password                         | age  | SEX  |
+----+----------+----------------------------------+------+------+
|  1 | A        | 507f513353702b50c145d5b7d138095c |   20 |    1 |
|  2 | B        | 5ecb75b1-de4c-11e8-9bb8-0242ac15 |   33 |    0 |
|  3 | C        | 5ecbba14-de4c-11e8-9bb8-0242ac15 |   38 |    1 |
|  4 | D        | 5ecc4ee0-de4c-11e8-9bb8-0242ac15 |   64 |    1 |
|  5 | E        | 5ecce3ae-de4c-11e8-9bb8-0242ac15 |   29 |    0 |
|  6 | F        | 5ecd835c-de4c-11e8-9bb8-0242ac15 |   86 |    1 |
|  7 | G        | 5ece181e-de4c-11e8-9bb8-0242ac15 |   51 |    1 |
|  8 | H        | 5ece6966-de4c-11e8-9bb8-0242ac15 |   65 |    1 |
|  9 | I        | 5ecebfba-de4c-11e8-9bb8-0242ac15 |   62 |    0 |
| 10 | J        | 5ecf22af-de4c-11e8-9bb8-0242ac15 |  102 |    0 |
| 11 | K        | 5ecfaab5-de4c-11e8-9bb8-0242ac15 |   59 |    0 |
| 12 | L        | 5ed08bd3-de4c-11e8-9bb8-0242ac15 |   74 |    1 |
| 13 | M        | 5ed12952-de4c-11e8-9bb8-0242ac15 |   27 |    1 |
| 14 | N        | 5ed1c141-de4c-11e8-9bb8-0242ac15 |   92 |    1 |
| 15 | O        | 5ed2b90c-de4c-11e8-9bb8-0242ac15 |   59 |    0 |
| 16 | P        | 5ed3654d-de4c-11e8-9bb8-0242ac15 |   50 |    1 |
| 17 | Q        | 5ed3d018-de4c-11e8-9bb8-0242ac15 |   45 |    0 |
| 18 | R        | 5ed438b6-de4c-11e8-9bb8-0242ac15 |   48 |    0 |
| 19 | S        | 5ed4be04-de4c-11e8-9bb8-0242ac15 |   28 |    1 |
| 20 | T        | 5ed56b4c-de4c-11e8-9bb8-0242ac15 |   94 |    0 |
| 21 | U        | 5ed5ebf7-de4c-11e8-9bb8-0242ac15 |   88 |    0 |
| 22 | V        | 5ed67bd1-de4c-11e8-9bb8-0242ac15 |  105 |    0 |
| 23 | W        | 5ed6c6dc-de4c-11e8-9bb8-0242ac15 |  113 |    1 |
| 24 | X        | 5ed7616b-de4c-11e8-9bb8-0242ac15 |    7 |    1 |
| 25 | Y        | 5ed7ff1b-de4c-11e8-9bb8-0242ac15 |   74 |    0 |
| 26 | Z        | 5ed86256-de4c-11e8-9bb8-0242ac15 |   12 |    1 |
+----+----------+----------------------------------+------+------+
26 rows in set (0.00 sec)
```

得到插入或删除更新(CREATE/UPDATE/DELETE) Mysql记录影响的行数
```shell
dev@testdb>SELECT ROW_COUNT();
+-------------+
| ROW_COUNT() |
+-------------+
|          -1 |
+-------------+
1 row in set (0.00 sec)
```

创建存储过程

```shell
dev@testdb>DELIMITER //
dev@testdb>CREATE PROCEDURE remUserByAgeAndReturnInfos(
    -> IN p_age SMALLINT UNSIGNED,
    -> OUT deletedUsers SMALLINT UNSIGNED,
    -> OUT userCounts SMALLINT UNSIGNED)
    -> BEGIN
    -> DELETE FROM tb18 WHERE age = p_age;
    -> SELECT ROW_COUNT() INTO deletedUsers;
    -> SELECT COUNT(id) FROM tb18 INTO userCounts;
    -> END
    -> //
Query OK, 0 rows affected (0.04 sec)

dev@testdb>DELIMITER ;
```

查询数据状态

```shell
dev@testdb>select age from tb18 group by age having count(age) > 1;
+------+
| age  |
+------+
|    6 |
|  120 |
|   54 |
+------+
3 rows in set (0.00 sec)

dev@testdb>select count(*) from tb18;
+----------+
| count(*) |
+----------+
|       26 |
+----------+
1 row in set (0.00 sec)
```

调用存储过程

```shell
dev@testdb>CALL remUserByAgeAndReturnInfos(54, @deletedUsers, @userCounts);
Query OK, 1 row affected (0.02 sec)
```

查询执行结果

```shell
dev@testdb>SELECT @deletedUsers as deletedUsers;
+--------------+
| deletedUsers |
+--------------+
|            2 |
+--------------+
1 row in set (0.00 sec)

dev@testdb>SELECT @userCounts;
+-------------+
| @userCounts |
+-------------+
|          24 |
+-------------+
1 row in set (0.00 sec)

#或者
dev@testdb>SELECT @deletedUsers as deletedUsers, @userCounts;
+--------------+-------------+
| deletedUsers | @userCounts |
+--------------+-------------+
|            2 |          24 |
+--------------+-------------+
1 row in set (0.01 sec)
```

- 上述存储过程不是事务数据一致性的, 但存储过程中执行语句错误; 则前面执行过的sql语句依然生效不回滚, 而执行错误的后继sql语句将不再执行;

# 存储过程与自定义函数的区别

- 存储过程实现的功能要复杂一些; 而函数的针对性更强;
- 存储过程可以返回多个值; 函数只能有一个返回值;
- 存储过程一般独立的来执行; 而函数可以作为其它SQL语句的组成部分来出现;
- 存储过程的修改只能修改注释及内容类型等 不能修改存储体, 要修改存储体只能删除然后重建;

# 存储引擎

Mysql可以将数据以不同的技术存储在文件(内存)中, 这种技术就称为存储引擎;
每一种存储引擎使用不同的存储机制, 索引技巧, 锁定水平, 最终提供广泛且不同的功能; 

Mysql目前支持的存储引擎主要有,
- MyISAM
- InnoDB
- Memory 
- CSV
- Archive

并发控制 
当多个连接同时对记录进行修改时保证数据的一致性和完整性; 

为保证数据的一致性和完整性，目前主要通过锁来处理, 主要有两种锁 

- 共享锁(读锁)
在同一时间段内, 多个用户可以读取同一个资源, 读取过程中数据不会发生变化;

- 排它锁(写锁)
在任何时候只能有一个用户写入资源, 当进行写锁时, 会阻塞其它的读锁或者写锁操作;

锁的颗粒大小 及锁定数据的单元大小的度量;

mysql主要有两种锁策略, 

- 表锁, 是一种开销最小的锁策略; 

- 行锁, 是一种开销最大的锁策略;

事务 

事务是数据库区别于文件系统的重要特征之一; 
事务用于保证数据库的完整性; 

事务四大特性 

- 原子性 (Atomicity)
- 一致性(Consistency)
- 隔离性(Isolation)
- 持久性(Durability)

外键是保证数据一致性的一种特性;

索引是对数据表中一列或多列的执行排序的一种结构,如书的目录, 可以快速定位数据的方法, 

- 普通索引
- 唯一索引
- 全文索引
- btree索引
- hash索引
- ...

几类存储引擎的主要特征,

|特点|MyISAM|InnoDB|Memory|Archive|
|:---|:---|:---|:---|:---|
|存储限制|256TB|64TB|有  |无  |
|事务安全|-    |支持|-   |-   |
|支持索引|支持 |支持|支持|    |
|锁颗粒  |表锁 |行锁|表锁|行锁|
|数据压缩|支持 | -  |-   |支持|
|支持外键|-    |支持|-   |-   |

适用场景

- MyISAM: 适用于事务的处理不多的情况;
- InnoDB: 适用于事务处理比较多, 需要外键支持的情况;

修改存储引擎

从Mysql5.5开始默认配置InnoDB存储引擎;

- 可通过修改配置文件`default-storage-engine = InnoDB` 值来设置合适的引擎;

- 通过创建表时指定所使用的存储引擎,

```shell
CREATE TABLE IF NOT EXISTS tbl_name(
...
) ENGINE = engine; 
```

- 通过ALTER 命令来修改, 

```shell
ALTER TABLE tbl_name ENGINE [=] engine_name;
```

# 总结

- 简要阐述了存储过程的基本概念及为何要使用存储过程的优点;
- 存储过程 实际为SQL语句和控制语句的预编译集合, 以一个名称存储并作为一个单元处理;
- 存储过程
  - 有三类参数可使用 输入类型, 输出类型,输入&输出类型;
  - 通过CREATE PROCEDURE sp_name(p,...)...创建存储过程;
  - 创建存储过程或自定义函数时需要通过delimiter语句修改定界符;
  - 如果函数体或过程体有多个语句, 需要包含在BEGIN...END语句块中;
  - 存储过程通过call来调用;
- 简要分析了存储过程创建/修改/调用/修改的语法结构;
- 通过创建无参数存储过程实例初步学习存储过程;
- 通过创建带IN参数的存储过程实例分析进一步了解存储过程的使用;
- 通过进一步创建带IN和OUT参数及多OUT参数的存储过程深入了解学习存储过程的使用;
- 简要对比了存储过程与自定义函数的区别及其各自适合的场景;
- 简要介绍了几类存储引擎的特点等;


