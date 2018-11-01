---
title: "mysql专题06 数据操作系列问题"
date: 2018-07-25 22:14:05
categories: "mysql专题"
tags: [mysql]
description:
---
本文从实践集合理论的角度对数据库的CURD命令及按条件刷查及分组等相关问题进行总结归纳成文; 
<!--more-->

##### 插入记录
***
insert 操作

- INSERT [INTO] tbl_name [(col_name,...)] {VALUES |VALUE} ({expr |DEFAULT},...), (...), ...

```shell
dev@testdb>source /sqls/tb8.sql;
Query OK, 0 rows affected (0.26 sec)

dev@testdb>show create table tb8 \G
*************************** 1. row ***************************
       Table: tb8
Create Table: CREATE TABLE `tb8` (
  `id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(20) NOT NULL,
  `password` varchar(22) NOT NULL,
  `age` tinyint(3) unsigned NOT NULL DEFAULT '10',
  `sex` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
1 row in set (0.07 sec)

dev@testdb>INSERT tb8 VALUES(NULL,'Tom','123',7*8-30,1);
Query OK, 1 row affected (0.68 sec)

dev@testdb>INSERT tb8 VALUES(DEFAULT,'Jack','123',DEFAULT,0);
Query OK, 1 row affected (0.11 sec)

dev@testdb>select * from tb8;
+----+----------+----------+-----+------+
| id | username | password | age | sex  |
+----+----------+----------+-----+------+
|  1 | Tom      | 123      |  26 |    1 |
|  2 | Jack     | 123      |  10 |    0 |
+----+----------+----------+-----+------+
```

- 可以通过`NULL` 或`DEFAULT`来使用系统自动编号字段;
- 可以通过表达式为字段赋值;
- 可以通过`DEFAULT`字段来使用默认值;

当需要通过条件来修改某个字段值时, 可以通过下列方式进行, 

- INSERT [INTO] tbl_name SET col_name={expr |DEFAULT}, ...
- 说明: 可以使用子查询来定位要修改的col_name字段;

```shell
dev@testdb>INSERT tb8 SET username='Mike', password='111';
Query OK, 1 row affected (0.14 sec)
```

第三种方式,

- INSERT [INTO] tbl_name [(col_name,...)] SELECT ...
上述方法可以将查询结果插入到指定数据表中; 

##### 更新记录
***
单表更新记录 update

> UPDATE [LOW_PRIORITY] [IGNORE] table_reference SET col_name1={expr1|DEFAULT}, [ col_name2={expr2|DEFAULT}] ... [WHERE where_condition]

```shell
dev@testdb>UPDATE tb8 set age=age+5;
Query OK, 3 rows affected (0.11 sec)
Rows matched: 3  Changed: 3  Warnings: 0

#同时更新多个字段, 以逗号隔开;
dev@testdb>UPDATE tb8 SET age = age -id, sex=0;
Query OK, 3 rows affected (0.10 sec)
Rows matched: 3  Changed: 3  Warnings: 0

#更新id为偶数的数据行, 通过where条件更新
dev@testdb>UPDATE tb8 SET age = age + 10 WHERE id % 2 = 0;
Query OK, 1 row affected (0.09 sec)
Rows matched: 1  Changed: 1  Warnings: 0
```

注意，在使用update时如果忘记加where条件，则会更新表中的所有记录，所以谨慎操作;


##### 删除记录
***
单表删除记录 delete

- DELETE FROM tbl_name [WHERE where_condition]

```shell
dev@testdb>DELETE FROM tb8 where id= 3;
Query OK, 1 row affected (0.09 sec)
```

##### 查询表达式解析

```shell
SELECT select_expr [, select_expr ...] 
  [ 
    FROM table_references 
    [ WHERE where_condition ] 
    [GROUP BY {col_name | position} [ASC | DESC], ...]
    [HAVING where_condition]
    [ORDER BY {col_name |expr|position} [ASC |DESC], ...]
    [LIMIT {[offset,] row_count | row_count OFFSET offset}]
  ]
```

##### 查询表达式

每个表达式表示想要的一列, 必须有至少一个;
多个列之间以英文逗号分隔;
星号(*)表示所有列, tbl_name.* 可以表示命名表的所有列;
查询表达式可以使用[AS] alias_name为其赋予别名;
别名可用于GROUP BY, ORDER BY 或HAVING子句;

```shell
dev@testdb>select version();
+-----------+
| version() |
+-----------+
| 8.0.12    |
+-----------+
1 row in set (0.00 sec)

dev@testdb>select now();
+---------------------+
| now()               |
+---------------------+
| 2018-11-01 01:05:31 |
+---------------------+
1 row in set (0.00 sec)

dev@testdb>select 3*5;
+-----+
| 3*5 |
+-----+
|  15 |
+-----+
1 row in set (0.00 sec)

#select 查询表达式的顺序会影响结果的排列顺序;

dev@testdb>select username AS uname, tb8.id AS userId from tb8;
+-------+--------+
| uname | userId |
+-------+--------+
| Tom   |      1 |
| Jack  |      2 |
+-------+--------+
2 rows in set (0.00 sec)
```
- select 查询表达式的顺序会影响结果的排列顺序;
- select 表达式可以通过表名前缀来指定查询字段的所属，多用于区分联合查询多张表具有相同字段名的情况;
- `AS`关键字来为查询字段命别名;

##### where条件查询

- WHERE 条件表达式中支持函数或运算符;

##### group by查询

- [GROUP BY {col_name | position} [ASC | DESC], ...]

group by 语句对查询结果通过指定列名或列的位置进行分组,并且可以对分组进行排序;

```shell
#通过列名分组
dev@testdb>SELECT sex FROM tb8 GROUP BY sex;
+------+
| sex  |
+------+
|    0 |
|    1 |
+------+
2 rows in set (0.00 sec)

# 通过列的位置进行分组， 这个列的位置指的是select_expr中列的位置，如sex 在select_expr的第一位;
#列位置分组一般不建议;
dev@testdb>SELECT sex FROM tb8 GROUP BY 1;
+------+
| sex  |
+------+
|    0 |
|    1 |
+------+
2 rows in set (0.00 sec)

# 按照多个关键字进行分组;
dev@testdb>select * from tb8 group by id, age, password asc;
+----+----------+----------+-----+------+
| id | username | password | age | sex  |
+----+----------+----------+-----+------+
|  1 | Tom      | 123      |  30 |    0 |
|  2 | Jack     | 123      |  23 |    0 |
|  4 | Mike     | 111      |  20 |    1 |
+----+----------+----------+-----+------+
3 rows in set, 1 warning (0.00 sec)

# select_expr为*时, group by 中应包括primary key id;
dev@testdb>select * from tb8 group by age;
ERROR 1055 (42000): Expression #1 of SELECT list is not in GROUP BY clause and contains nonaggregated column 'testdb.tb8.id' which is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by

# 当select expr 为指定字段时, 可以对其进行多关键字分组和排序;
dev@testdb>select password from tb8 group by password, username desc;
+----------+
| password |
+----------+
| 111      |
| 123      |
| 123      |
+----------+
3 rows in set, 1 warning (0.00 sec)
dev@testdb>
```

- 显然通过分组可以去重;
- 可以对分组进行排序; 
- 当select_expr是(*)时，group by 子句中应有primary key 在内进行分组, 否则会出错;


##### having设置分组条件
- [HAVING where_condition]

在进行group by分组时, 还可以通过having 语句设置分组条件, 即可以对全部记录进行分组, 通过HAVING可以对指定记录进行分组;

```shell
dev@testdb>select sex, age from tb8 group by sex having age > 22;
ERROR 1055 (42000): Expression #2 of SELECT list is not in GROUP BY clause and contains nonaggregated column 'testdb.tb8.age' which is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by
```

上述错误发生会在mysql 5.7.5 和以后上，因为5.7.5默认的sql模式配置是
```shell
ONLY_FULL_GROUP_BY,
```

目前适用的是mysql8.0.12版本,自然就中招了,

这个配置启用的是"严格ANSIsql规则", 严格`ANSI sql` 规则要求在group by的时候, 没有聚合的列，在group by的时候，必须全部包含在group by 的字段中。
没有聚合的列，指的是没有使用 max, min, count, sum....这些函数的列，直接查询出字段的列。
如果不是aggregate 的列，必须要全部包含在集合里面。aggregate 的列，指的大概就是不能聚合的列，没有用函数的列，比如说 avg, sum, count 这些函数的列。用了这些函数的列，可以不包含。

所以上述错误可修改为

```shell
dev@testdb>select sex, age from tb8 group by sex, age having age > 22;
+------+-----+
| sex  | age |
+------+-----+
|    0 |  30 |
|    0 |  23 |
+------+-----+
2 rows in set (0.00 sec)

dev@testdb>select sex, max(age) from tb8 group by sex;
+------+----------+
| sex  | max(age) |
+------+----------+
|    0 |       30 |
|    1 |       20 |
+------+----------+
2 rows in set (0.00 sec)

dev@testdb>select sex, max(age) as age from tb8 group by sex having age > 22;
+------+------+
| sex  | age  |
+------+------+
|    0 |   30 |
+------+------+
1 row in set (0.00 sec)

dev@testdb>select sex, age from tb8 group by sex, age having age > 22;
+------+-----+
| sex  | age |
+------+-----+
|    0 |  30 |
|    0 |  23 |
+------+-----+
2 rows in set (0.00 sec)
```

- 可以通过给字段加上聚合函数进行group by, 或者把不能聚合的列且没有使用聚合函数的都放入到group by条件中即可;
- 上述案例可以看出having是对group by再进行条件帅选的,因为group by 对age进行了聚合计算, 所以最后只有一列值符号要求;

group by 规则,
- group by 必须出现在where子句之后; 
- 除聚合计算语句外, select 语句中, 每个列都必须在group by 子句中给出;

##### order by对查询结果排序
- [ORDER BY {col_name | expr | position} [ASC | DESC], ..]

order by 语句对查询结果排序

```shell
dev@testdb>select * from tb8 order by password desc, id asc;
+----+----------+----------+-----+------+
| id | username | password | age | sex  |
+----+----------+----------+-----+------+
|  1 | Tom      | 123      |  30 |    0 |
|  2 | Jack     | 123      |  23 |    0 |
|  4 | Mike     | 111      |  20 |    1 |
+----+----------+----------+-----+------+
```

- 可以对多个列进行order by排序， 当第一个字段按照order by 排序后，如果出现重复值则继续按照第二个字段进行排序，如果不出现重复值，则直接忽略第二个及其后面字段的排序;

##### limit 限制查询数量

- [LIMIT {[offset,] row_count|row_count OFFSET offset}]

limit 语句限制查询数量, 同时可以利用offset进行分页返回;

```shell
# 从第0条开始返回两条记录;
dev@testdb>select * from tb8 limit 2;
+----+----------+----------+-----+------+
| id | username | password | age | sex  |
+----+----------+----------+-----+------+
|  1 | Tom      | 123      |  30 |    0 |
|  2 | Jack     | 123      |  23 |    0 |
+----+----------+----------+-----+------+
2 rows in set (0.00 sec)

# 从第1条开始，返回2条记录;
dev@testdb>select * from tb8 limit 1, 2;
+----+----------+----------+-----+------+
| id | username | password | age | sex  |
+----+----------+----------+-----+------+
|  2 | Jack     | 123      |  23 |    0 |
|  4 | Mike     | 111      |  20 |    1 |
+----+----------+----------+-----+------+
2 rows in set (0.00 sec)

#将查询的结果写入到某张表中
dev@testdb>insert tb9 (username) select username from tb8 where age >=20;
Query OK, 3 rows affected (0.09 sec)
Records: 3  Duplicates: 0  Warnings: 0

dev@testdb>select * from tb9;
+----+----------+
| id | username |
+----+----------+
|  1 | Tom      |
|  2 | Jack     |
|  3 | Mike     |
+----+----------+
3 rows in set (0.01 sec)
```

##### 总结
***
- 通过实例进行数据的CURD操作;
- 并对SELECT语句查询语句进行实例分析包括条件语句where, 分组语句groupby, 设置分组条件having, 对结果进行排序orderby, 限制返回值数量及分页计算limit等;
