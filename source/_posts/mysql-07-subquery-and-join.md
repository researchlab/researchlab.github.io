---
title: "mysql专题07 子查询与连接"
date: 2018-09-01 10:14:30
categories: "mysql专题"
tags: [mysql]
description:
---
本文将以实践集合理论的角度深入学习总结mysql中有关子查询及连接的相关知识点; 
<!--more-->

##### 数据准备
***

```shell
dev@testdb>source /sqls/tb10_ddl.sql;
Query OK, 0 rows affected (0.02 sec)

dev@testdb>source /sqls/tb10_dml.sql;
Query OK, 1 row affected (0.00 sec)

dev@testdb>select count(*) from tdb_goods;
+----------+
| count(*) |
+----------+
|       23 |
+----------+
1 row in set (0.00 sec)
```

> 数据文件可参考 [tb10_ddl.sql](https://github.com/researchlab/docker-envs/blob/master/mysql/sqls/tb10_ddl.sql), [tb10_dml.sql](https://github.com/researchlab/docker-envs/blob/master/mysql/sqls/tb10_dml.sql)


##### 子查询简介
* * *  

子查询(subquery)是指出现在其它SQL语句内的SELECT子句;

eg.

SELECT * FROM tb1 WHERE col1= (SELECT col2 FROM t2);
- 其中SELECT * FROM tb1 称为Outer Query/Outer Statement,
而SELECT col2 FROM t2 称为subquery;

- 子查询指嵌套在查询内部, 且必须始终出现在圆括号内;
- 子查询可以包含多个关键字或条件, 如DISTINCT,GROUP BY, ORDER BY, LIMIT, 函数等;
- 子查询的外层查询可以是SELECT, INSERT, UPDATE, SET 或DO;
- 子查询可以返回标量, 一行, 一列, 或子查询;

##### 由比较运算符引发的子查询
***
使用比较运算符的子查询 
```shell
=, >, <, >=, <=, 
#不等于
<>, !=, <=> 
```

语法结构 
operand comparison_operator subquery

计算平均值
```shell
dev@testdb>SELECT ROUND(AVG(goods_price),2) FROM tdb_goods;
+---------------------------+
| ROUND(AVG(goods_price),2) |
+---------------------------+
|                   5391.30 |
+---------------------------+
1 row in set (0.00 sec)
```

计算价格大于等于平均价格的商品
```shell
dev@testdb>SELECT goods_id, goods_name, goods_price FROM tdb_goods WHERE goods_price >= (SELECT ROUND(AVG(goods_price), 2) FROM tdb_goods);
+----------+-----------------------------------------+-------------+
| goods_id | goods_name                              | goods_price |
+----------+-----------------------------------------+-------------+
|        3 | G150TH 15.6英寸游戏本                   |    8499.000 |
|        7 | SVP13226SCB 13.3英寸触控超极本          |    7999.000 |
|       13 | iMac ME086CH/A 21.5英寸一体电脑         |    9188.000 |
|       17 | Mac Pro MD878CH/A 专业级台式电脑        |   28888.000 |
|       18 |  HMZ-T3W 头戴显示设备                   |    6999.000 |
|       20 | X3250 M4机架式服务器 2583i14            |    6888.000 |
|       22 |  HMZ-T3W 头戴显示设备                   |    6999.000 |
+----------+-----------------------------------------+-------------+
7 rows in set (0.00 sec)
```

当子查询结果返回多个值, 可用以下函数来修饰对返回结果的操作

- operand comparison_operator ANY(subquery)
- operand comparison_operator SOME(subquery)
- operand comparison_operator ALL(subquery)

- ANY 和SOME是等价的;
其计算原则如下, 

||ANY|SOME|ALL|
|:---|:---|:---|:---|
|>, >=|最小值|最小值|最大值|
|<,<=|最大值|最大值|最小值|
|= |任意值|任意值||
|<>, != |||任意值|

查询比所有超级本价格贵的笔记本;
```shell
dev@testdb>SELECT goods_id, goods_name,goods_price from tdb_goods where goods_price > ALL(select goods_price from tdb_goods where goods_cate='超级本');
+----------+-----------------------------------------+-------------+
| goods_id | goods_name                              | goods_price |
+----------+-----------------------------------------+-------------+
|        3 | G150TH 15.6英寸游戏本                   |    8499.000 |
|       13 | iMac ME086CH/A 21.5英寸一体电脑         |    9188.000 |
|       17 | Mac Pro MD878CH/A 专业级台式电脑        |   28888.000 |
+----------+-----------------------------------------+-------------+
3 rows in set (0.00 sec)
```

##### 由[NOT]/IN/EXISTS引发的子查询
***
语法结构
- operand comparison_operator [NOT] IN (subquery) 
- = ANY 运算符与IN等效;
- !=ALL或<>ALL 运算与NOT IN等效;
- 如果子查询返回任何行, EXISTS将返回TRUE,  否则返回FALSE;

```shell
dev@testdb>SELECT goods_id, goods_name,goods_price from tdb_goods where goods_price IN (select goods_price from tdb_goods where goods_cate='超级本');
+----------+---------------------------------------+-------------+
| goods_id | goods_name                            | goods_price |
+----------+---------------------------------------+-------------+
|        5 | X240(20ALA0EYCD) 12.5英寸超极本       |    4999.000 |
|        6 | U330P 13.3英寸超极本                  |    4299.000 |
|        7 | SVP13226SCB 13.3英寸触控超极本        |    7999.000 |
+----------+---------------------------------------+-------------+
3 rows in set (0.00 sec)
```

##### 使用INSERT...SELECT插入记录
***

当一张表中存在大量的重复值时, 就需要考虑将其拆分为多张表, 然后通过外键来关联, 以减少重复值占用空间, 如上述的tdb_goods表中, 其中的goods_cate就存在很多重复值, 当tdb_goods中存入100w+甚至更多数据时,  这些重复值势必将占用很多空间, 而这些空间其实可以省略的, 下面先建立一张tdb_goods_cate表,  然后通过INSERT... SELECT语句来讲tdb_goods表中存在的记录插入到新表中;

```shell
dev@testdb>show create table tdb_goods_cates \G
*************************** 1. row ***************************
       Table: tdb_goods_cates
Create Table: CREATE TABLE `tdb_goods_cates` (
  `cate_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `cate_name` varchar(40) NOT NULL,
  PRIMARY KEY (`cate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8

dev@testdb>insert tdb_goods_cates (cate_name) select goods_cate from tdb_goods group by goods_cate;
Query OK, 7 rows affected (0.02 sec)
Records: 7  Duplicates: 0  Warnings: 0

dev@testdb>select * from tdb_goods_cates;
+---------+---------------------+
| cate_id | cate_name           |
+---------+---------------------+
|       1 | 笔记本              |
|       2 | 游戏本              |
|       3 | 超级本              |
|       4 | 平板电脑            |
|       5 | 台式机              |
|       6 | 服务器/工作站       |
|       7 | 笔记本配件          |
+---------+---------------------+
7 rows in set (0.00 sec)
```

##### 多表更新
***

上述将分类值插入到分类表中, 但是商品表中的分类并没有通过外键关联到分类表中, 依然存储的是分类名称,  下面将参照分类表来更新商品表,

语法结构

```shell
UPDATE table_references 
SET col_name1={expr1|DEFAULT}
[, col_name2={expr2|DEFAULT}] ...
[WHERE where_condition]
```

```shell
dev@testdb>update tdb_goods inner join tdb_goods_cates on goods_cate = cate_name set goods_cate = cate_id;
Query OK, 23 rows affected (0.06 sec)
Rows matched: 23  Changed: 23  Warnings: 0

dev@testdb>select * from tdb_goods \G
*************************** 1. row ***************************
   goods_id: 1
 goods_name: R510VC 15.6英寸笔记本
 goods_cate: 1
 brand_name: 华硕
goods_price: 3399.000
    is_show: 1
```
- 上面通过内连接将tdb_goods 中的goods_cate 更新为tdb_goods_cates 表中的cate_id值; 
- update 表a inner join 表b on 条件 set 设置值;

多表更新之一步到位
***
上述将tdb_goods中的goods_cate 值更新到tdb_goods_cates表中的goods_cate值, 大致进过了三个步骤, 
1. 创建tdb_goods_cates表;
2. insert ... select 更新 tdb_goods_cates表;
3. update 表a inner join 表b on 条件 set 值 更新tdb_goods表;

是否一步到位完成上述三个操作? 当然可以, 

语法结构

```shell
CREATE TABLE [IF NOT EXISTS] tbl_name 
[(create_definition,...)]
select_statement
```

- CREATE...SELECT 在创建数据表的同时将查询结果写入到数据表

一步到位创建更新tdb_goods_brands 表
```shell
CREATE TABLE IF NOT EXISTS tdb_goods_brands(
	brand_id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	brand_name VARCHAR(40) NOT NULL
	) SELECT brand_name FROM tdb_goods GROUP BY brand_name;

dev@testdb>source /sqls/tb12.sql;
Query OK, 10 rows affected (0.04 sec)
Records: 10  Duplicates: 0  Warnings: 0

dev@testdb>select * from tdb_goods_brands;
+----------+--------------+
| brand_id | brand_name   |
+----------+--------------+
|        1 | 华硕         |
|        2 | 联想         |
|        3 | 雷神         |
|        4 | 索尼         |
|        5 | 苹果         |
|        6 | 戴尔         |
|        7 | 宏碁         |
|        8 | 惠普         |
|        9 | IBM          |
|       10 | 九州风神     |
+----------+--------------+
10 rows in set (0.01 sec)

dev@testdb>update tdb_goods as g inner join tdb_goods_brands as b on g.brand_name = b.brand_name
    -> set g.brand_name = b.brand_id;
Query OK, 23 rows affected (0.09 sec)
Rows matched: 23  Changed: 23  Warnings: 0

# 将tdb_goods 中的brand_name 和goods_name 字段名称及类型进行修改
dev@testdb>desc tdb_goods;
+-------------+------------------------+------+-----+---------+----------------+
| Field       | Type                   | Null | Key | Default | Extra          |
+-------------+------------------------+------+-----+---------+----------------+
| goods_id    | smallint(5) unsigned   | NO   | PRI | NULL    | auto_increment |
| goods_name  | varchar(150)           | NO   |     | NULL    |                |
| goods_cate  | varchar(40)            | NO   |     | NULL    |                |
| brand_name  | varchar(40)            | NO   |     | NULL    |                |
| goods_price | decimal(15,3) unsigned | NO   |     | 0.000   |                |
| is_show     | tinyint(1)             | NO   |     | 1       |                |
| is_saleoff  | tinyint(1)             | NO   |     | 0       |                |
+-------------+------------------------+------+-----+---------+----------------+
7 rows in set (0.00 sec)

dev@testdb>alter table tdb_goods
    -> change goods_cate cate_id SMALLINT UNSIGNED NOT NULL,
    -> CHANGE brand_name brand_id SMALLINT UNSIGNED NOT NULL;
Query OK, 23 rows affected (0.13 sec)
Records: 23  Duplicates: 0  Warnings: 0

dev@testdb>desc tdb_goods;
+-------------+------------------------+------+-----+---------+----------------+
| Field       | Type                   | Null | Key | Default | Extra          |
+-------------+------------------------+------+-----+---------+----------------+
| goods_id    | smallint(5) unsigned   | NO   | PRI | NULL    | auto_increment |
| goods_name  | varchar(150)           | NO   |     | NULL    |                |
| cate_id     | smallint(5) unsigned   | NO   |     | NULL    |                |
| brand_id    | smallint(5) unsigned   | NO   |     | NULL    |                |
| goods_price | decimal(15,3) unsigned | NO   |     | 0.000   |                |
| is_show     | tinyint(1)             | NO   |     | 1       |                |
| is_saleoff  | tinyint(1)             | NO   |     | 0       |                |
+-------------+------------------------+------+-----+---------+----------------+
7 rows in set (0.01 sec)
```
- 当两个表中存在同名字段时, 使用as来进行别名识别;
- 当需要同时修改列字段的名称及数据类型时建议用change 来修改 
- alter table tbl_name change older_col, new_col_name, new_col_definition, [change older_col, new_col_name, new_col_definition] ...

当需要将多张表的信息查询出来拼成一个完整的可读信息呈现给用户, 就需要用到连接 来操作多张表; 

##### 连接
***
Mysql 在SELECT语句, 多表更新, 多表删除语句中支持JOIN操作,  
语法结构

```shell
table_reference
{[INNER |CROSS] JOIN | {LEFT|RIGHT} [OUTER] JOIN}
table_reference
ON conditional_expr
```

table_reference 
tbl_name [[AS] alias] | table_subquery [AS] alias 

数据表可以使用tbl_name AS alias_name  或tbl_name alias_name 赋予别名; 
table_subquery 可以作为子查询使用在FROM子句中, 这样的子查询必须为其赋予别名;

##### 内连接
*** 
Mysql中, JOIN, CROSS JOIN 和INNER JOIN 是等价的。 

通常使用INNER JOIN; 
使用ON 关键字来设定连接条件, 也可以使用WHERE 来代替;
通常使用ON关键字来设定连接条件, 使用WHERE 关键字进行结果集记录的过滤;

内连接, 即仅显示左表和右表符合连接条件的记录, 即结果是符合连接条件的左右表的交集;

```shell
dev@testdb>select goods_id, goods_name, cate_name from tdb_goods inner join tdb_goods_cates on tdb_goods.cate_id = tdb_goods_cates.cate_id;
```

- 上面的结果是仅符合tdb_goods表中的cate_id 等于tdb_goods_cates中cate_id中的记录;

##### 外连接
***

外连接又分为,
LEFT [OUTER] JOIN 左外连接
左外连接返回结果为 左表中的全部记录以及符合连接条件的右表中的记录的集合; 

RIGHT [OUTER] JOIN 右外连接
右外连接返回结果为 右表中的全部记录以及符合连接条件的左表中的记录的集合; 

示例说明内连接,左外,右外连接的区别, 

```shell

# 新建tb13
dev@testdb>show create table tb13 \G
*************************** 1. row ***************************
       Table: tb13
Create Table: CREATE TABLE `tb13` (
  `goods_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `goods_name` varchar(150) NOT NULL,
  `cate_id` smallint(5) unsigned NOT NULL,
  `brand_name` varchar(40) NOT NULL,
  `goods_price` decimal(15,3) unsigned NOT NULL DEFAULT '0.000',
  `is_show` tinyint(1) NOT NULL DEFAULT '1',
  `is_saleoff` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`goods_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8
1 row in set (0.00 sec)

# 插入记录
dev@testdb>INSERT tb13(goods_name,goods_cate,brand_name,goods_price,is_show,is_saleoff) VALUES('R510VC 15.6英寸笔记本','笔记本','华硕','3399',DEFAULT,DEFAULT);
Query OK, 1 row affected (0.07 sec)

dev@testdb>INSERT tb13 (goods_name,goods_cate,brand_name,goods_price,is_show,is_saleoff) VALUES('Y400N 14.0英寸笔记本电脑','笔记本','联想','4899',DEFAULT,DEFAULT);
Query OK, 1 row affected (0.02 sec)

#根据tb13 新建tb14, 注意 select 列名 如果和tb14中的列名不相同, 需要用as 别名使之匹配否则报错;
dev@testdb>CREATE TABLE IF NOT EXISTS tb14(
    -> cate_id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    -> cate_name VARCHAR(40) NOT NULL
    -> )
    -> SELECT goods_cate as cate_name from tb13 group by goods_cate;

#tb14 插入数据
dev@testdb>insert tb14 (cate_name) VALUES('路由器'),('交换机'),('网卡');

#更新tb13 
dev@testdb>UPDATE tb13 inner join tb14 on goods_cate = cate_name set goods_cate = cate_id;
Query OK, 2 rows affected (0.10 sec)
Rows matched: 2  Changed: 2  Warnings: 0

dev@testdb>alter table tb13
    -> change goods_cate cate_id SMALLINT UNSIGNED NOT NULL;
Query OK, 2 rows affected (0.14 sec)
Records: 2  Duplicates: 0  Warnings: 0

dev@testdb>insert tb13 (goods_name, cate_id, brand_name, goods_price,is_show,is_saleoff) values('Macbook pro 15.0英寸笔记本', 5,'Apple','120000',DEFAULT, DEFAULT);
Query OK, 1 row affected (0.09 sec)

#内连接 
dev@testdb>select goods_name, cate_name, goods_price from tb13 as a inner join tb14 as b on a.cate_id = b.cate_id;
+---------------------------------+-----------+-------------+
| goods_name                      | cate_name | goods_price |
+---------------------------------+-----------+-------------+
| R510VC 15.6英寸笔记本           | 笔记本    |    3399.000 |
| Y400N 14.0英寸笔记本电脑        | 笔记本    |    4899.000 |
+---------------------------------+-----------+-------------+
2 rows in set (0.00 sec)

#左连接, tb13左连接tb14, tb13记录全部显示, 当tb13中某个记录在tb14中不存在, 则返回的select 中tb14列的值为NULL
dev@testdb>select goods_name, cate_name, goods_price from tb13 as a left join tb14 as b on a.cate_id = b.cate_id;
+---------------------------------+-----------+-------------+
| goods_name                      | cate_name | goods_price |
+---------------------------------+-----------+-------------+
| R510VC 15.6英寸笔记本           | 笔记本    |    3399.000 |
| Y400N 14.0英寸笔记本电脑        | 笔记本    |    4899.000 |
| Macbook pro 15.0英寸笔记本      | NULL      |  120000.000 |
+---------------------------------+-----------+-------------+
3 rows in set (0.00 sec)

#右连接, tb13右连接tb14, tb14记录全部显示, 当tb13中某个记录在tb14中不存在, 则返回的select 中tb13列的值为NULL
dev@testdb>select goods_name, cate_name, goods_price from tb13 as a right join tb14 as b on a.cate_id = b.cate_id;
+---------------------------------+-----------+-------------+
| goods_name                      | cate_name | goods_price |
+---------------------------------+-----------+-------------+
| R510VC 15.6英寸笔记本           | 笔记本    |    3399.000 |
| Y400N 14.0英寸笔记本电脑        | 笔记本    |    4899.000 |
| NULL                            | 路由器    |        NULL |
| NULL                            | 交换机    |        NULL |
| NULL                            | 网卡      |        NULL |
+---------------------------------+-----------+-------------+
5 rows in set (0.00 sec)
```

##### 多表连接
***

示例,
```shell
dev@testdb>select goods_id, goods_name, cate_name, brand_name, goods_price from tdb_goods as g
    -> inner join tdb_goods_cates as c on g.cate_id = c.cate_id
    -> inner join tdb_goods_brands as b on g.brand_id = b.brand_id \G
*************************** 1. row ***************************
   goods_id: 1
 goods_name: R510VC 15.6英寸笔记本
  cate_name: 笔记本
 brand_name: 华硕
goods_price: 3399.000
```

可以说表的连接为外键的逆向操作; 

##### 关于连接的几点说明
***

A LEFT JOIN B join_condition 
数据表B 的结果集依赖数据表A 
数据表A的结果集根据左连接条件依赖所有数据表(B表除外);
左外连接条件决定如何检索数据表B(在没有指定WHERE条件的情况下);
如果数据表A的某条记录符合WHERE条件, 但是在数据表B中不存在,  符合连接条件的记录, 将生成一个所有列为空的额外的B行;

如果使用内连接查找的记录在连接数据表中不存在, 并且在WHERE子句中尝试如下操作: col_name IS NULL时, 如果col_name 被定义为NOT NULL, MySql 将在找到符合连接着条件的记录后停止搜索更多的行;

##### 无限级分类表设计
***

一个商品在不同的集合中会可以归类为不同的分类，这种无限极的分类表改如何设计? 有多少个分类就设计多少张分类表? 显然不合理, 下面是一种无限极分类表的设计方案, 

```shell
CREATE TABLE tdb_goods_types(
     type_id   SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
     type_name VARCHAR(20) NOT NULL,
     parent_id SMALLINT UNSIGNED NOT NULL DEFAULT 0
  );
```
这种设计也是一种设计网站目录的方案,

```shell

#查找子类的父类名称;
dev@testdb>select s.type_id, s.type_name, p.type_name
    -> from tdb_goods_types as s
    -> left join
    -> tdb_goods_types as p
    -> on
    -> s.parent_id = p.type_id;
+---------+-----------------+-----------------+
| type_id | type_name       | type_name       |
+---------+-----------------+-----------------+
|       1 | 家用电器        | NULL            |
|       2 | 电脑、办公      | NULL            |
|       3 | 大家电          | 家用电器        |
|       4 | 生活电器        | 家用电器        |
|       5 | 平板电视        | 大家电          |
|       6 | 空调            | 大家电          |
|       7 | 电风扇          | 生活电器        |
|       8 | 饮水机          | 生活电器        |
|       9 | 电脑整机        | 电脑、办公      |
|      10 | 电脑配件        | 电脑、办公      |
|      11 | 笔记本          | 电脑整机        |
|      12 | 超级本          | 电脑整机        |
|      13 | 游戏本          | 电脑整机        |
|      14 | CPU             | 电脑配件        |
|      15 | 主机            | 电脑配件        |
+---------+-----------------+-----------------+
15 rows in set (0.00 sec)

#查找父类下子类的个数;
dev@testdb>select p.type_id, p.type_name, count(s.type_name) as childcout
    -> from tdb_goods_types as p
    -> left join
    -> tdb_goods_types as s
    -> on
    -> s.parent_id = p.type_id
    -> group by p.type_id, p.type_name
    -> order by p.type_id;
+---------+-----------------+-----------+
| type_id | type_name       | childcout |
+---------+-----------------+-----------+
|       1 | 家用电器        |         2 |
|       2 | 电脑、办公      |         2 |
|       3 | 大家电          |         2 |
|       4 | 生活电器        |         2 |
|       5 | 平板电视        |         0 |
|       6 | 空调            |         0 |
|       7 | 电风扇          |         0 |
|       8 | 饮水机          |         0 |
|       9 | 电脑整机        |         3 |
|      10 | 电脑配件        |         2 |
|      11 | 笔记本          |         0 |
|      12 | 超级本          |         0 |
|      13 | 游戏本          |         0 |
|      14 | CPU             |         0 |
|      15 | 主机            |         0 |
+---------+-----------------+-----------+
15 rows in set (0.00 sec)
```
##### 多表删除
***

```shell
DELETE tbl_name[.*] [, tbl_name[.*]] ...
FROM table_refereneces
[WHERE where_condition]
```

删除重复记录,保留id最小的记录;

```shell
#准备重复记录
dev@testdb>insert tdb_goods (goods_name, cate_id, brand_id, goods_price, is_show, is_saleoff) select goods_name, cate_id, brand_id, goods_price, is_show,is_saleoff from tdb_goods where goods_id in (1,2,3);
Query OK, 3 rows affected (0.06 sec)
Records: 3  Duplicates: 0  Warnings: 0

dev@testdb>select count(*) from tdb_goods group by goods_name;
+----------+
| count(*) |
+----------+
|        2 |
|        2 |
...
+----------+
21 rows in set (0.00 sec)

#查找重复值
dev@testdb>select goods_id, goods_name from tdb_goods where goods_name in (select goods_name from tdb_goods group by goods_name having count(goods_name) >=2);
+----------+---------------------------------+
| goods_id | goods_name                      |
+----------+---------------------------------+
|        1 | R510VC 15.6英寸笔记本           |
|        2 | Y400N 14.0英寸笔记本电脑        |
|        3 | G150TH 15.6英寸游戏本           |
|       18 |  HMZ-T3W 头戴显示设备           |
|       19 | 商务双肩背包                    |
|       22 |  HMZ-T3W 头戴显示设备           |
|       23 | 商务双肩背包                    |
|       24 | R510VC 15.6英寸笔记本           |
|       25 | Y400N 14.0英寸笔记本电脑        |
|       26 | G150TH 15.6英寸游戏本           |
+----------+---------------------------------+
10 rows in set (0.00 sec)

#删除重复值, 并且保留id最小数据行
dev@testdb>delete t1 from tdb_goods as t1
    -> left join
    -> (select any_value(goods_id) as goods_id, goods_name from tdb_goods group by goods_name having count(goods_name) >=2) as t2
    -> on t1.goods_name = t2.goods_name
    -> where t1.goods_id > t2.goods_id;
Query OK, 5 rows affected (0.02 sec)

dev@testdb>select goods_name from tdb_goods group by goods_name having count(goods_name) >=2;
Empty set (0.00 sec)
```

- 当sql_mode=only_full_group_by时 可以通过any_value(goods_id) as goods_id来临时解决; 

##### 总结
***
- 子查询多个实例分析学习; 主要有三种情况引发子查询:1.由比较运算符引发的子查询;2.由[NOT]IN/EXISTS引发的子查询;3.使用INSERT...SELECT插入记录;
- mysql连接分为内连接和外连接, 外连接又分为左外连接和右外连接;
- 多表更新及多表删除;
