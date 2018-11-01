---
title: "mysql专题08 探讨sql_mode=only_full_group_by解决方案及缘由"
date: 2018-10-01 16:15:28
categories: "mysql专题"
tags: [mysql]
description:
---
`MySQL5.7.5`后only_full_group_by成为sql_mode的默认选项之一，这可能导致一些sql语句失效。 本文将进一步探讨`Mysql`为何要将`sql_mode`默认设置为`only_full_group_by`以及这种情况下的解决方案;
<!--more-->

##### 实例分析
***
表1

```shell
dev@testdb>select * from tb13;
+----------+---------------------------------+---------+------------+-------------+---------+------------+
| goods_id | goods_name                      | cate_id | brand_name | goods_price | is_show | is_saleoff |
+----------+---------------------------------+---------+------------+-------------+---------+------------+
|        1 | R510VC 15.6英寸笔记本           |       1 | 华硕       |    3399.000 |       1 |          0 |
|        2 | Y400N 14.0英寸笔记本电脑        |       1 | 联想       |    4899.000 |       1 |          0 |
|        3 | Macbook pro 15.0英寸笔记本      |       5 | Apple      |  120000.000 |       1 |          0 |
|        4 | R510VC 15.6英寸笔记本           |       1 | 华硕       |    3399.000 |       1 |          0 |
|        5 | Y400N 14.0英寸笔记本电脑        |       1 | 联想       |    4899.000 |       1 |          0 |
|        6 | Macbook pro 15.0英寸笔记本      |       5 | Apple      |  120000.000 |       1 |          0 |
+----------+---------------------------------+---------+------------+-------------+---------+------------+
6 rows in set (0.00 sec)
```

执行sql:
```shell
dev@testdb>select goods_id, goods_name from tb13 group by goods_name;
ERROR 1055 (42000): Expression #1 of SELECT list is not in GROUP BY clause and contains nonaggregated column 'testdb.tb13.goods_id' which is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by
```
##### 解决方法

1. 把group by字段group_id设成primary key 或者 unique NOT NULL。这个方法在实际操作中没什么意义。

2. 使用函数any_value把报错的字段goods_id包含起来。如, select any_value(goods_id), goods_name from tb13 group by goods_name。

3. 在配置文件my.cnf中关闭sql_mode=ONLY_FULL_GROUP_BY。

msqyl的默认配置是
```shell
sql_mode=ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION。
```
可以把ONLY_FULL_GROUP_BY去掉，也可以去掉所有选项设置成sql_mode=，如果你确信其他选项不会造成影响的话。

> 关于any_value()详情请查考[mysql官方文档](https://dev.mysql.com/doc/refman/5.7/en/miscellaneous-functions.html#function_any-value)

加上any_value()执行成功后，返回结果应该是

```shell
dev@testdb>select any_value(goods_id) as goods_id, goods_name from tb13 group by goods_name having count(goods_name) >=2;
+----------+---------------------------------+
| goods_id | goods_name                      |
+----------+---------------------------------+
|        1 | R510VC 15.6英寸笔记本           |
|        2 | Y400N 14.0英寸笔记本电脑        |
|        3 | Macbook pro 15.0英寸笔记本      |
+----------+---------------------------------+
3 rows in set (0.01 sec)
```

##### 为何设置默认值only_full_group_by

**为什么默认设置ONLY_FULL_GROUP_BY限制？**

对于上述的报错信息，我的理解是select字段里包含了没有被group by条件唯一确定的字段goods_id。

因为执行group by语句实际上把两行纪录goods_id和goods_name合并称为一行，搜索引擎不知道该返回哪一条，所以认为这样的sql是武断的(arbitrary).

解决办法2和3都是禁止检查返回结果的唯一性。

进阶讨论
上述办法可以解决报错的问题，但也说明sql语句本身有逻辑问题。name字段不应该出现在返回结果，因为它是不确定的。

考虑这样的需求：按brand_name分组后，找出每组价格最便宜的笔记本。

```shell
dev@testdb>select * from tb16;
+----+----------+--------+-------+
| id | group_id | name   | score |
+----+----------+--------+-------+
|  1 | A        | 小刚   |    20 |
|  2 | B        | 小明   |    19 |
|  3 | B        | 小花   |    17 |
|  4 | C        | 小红   |    18 |
+----+----------+--------+-------+
4 rows in set (0.00 sec)

dev@testdb>select any_value(name) as name, group_id, min(score) as score from tb16 group by group_id order by min(score);
+--------+----------+-------+
| name   | group_id | score |
+--------+----------+-------+
| 小明   | B        |    17 |
| 小红   | C        |    18 |
| 小刚   | A        |    20 |
+--------+----------+-------+
3 rows in set (0.00 sec)
```
B组的name是小明（因为小明的id更小），而期望结果应该是小花。

所以单纯使用group by无法实现这样的需求。可以使用临时表的方法：
```shell
dev@testdb>select id, name, t.group_id, t.score from
    -> (select group_id, min(score) as score from tb16 group by group_id order by min(score)) as t
    -> inner join tb16
    -> on
    -> t.group_id = tb16.group_id and t.score= tb16.score;
+----+--------+----------+-------+
| id | name   | group_id | score |
+----+--------+----------+-------+
|  1 | 小刚   | A        |    20 |
|  3 | 小花   | B        |    17 |
|  4 | 小红   | C        |    18 |
+----+--------+----------+-------+
3 rows in set (0.00 sec)

```

如果要实现更为复杂的需求，可以考虑使用group_concat，请进一步参考[Mysql 分组聚合实现 over partition by 功能](http://www.cnblogs.com/zhwbqd/p/4205821.html?utm_source=tuicool&utm_medium=referral)

##### 总结
***
- 本文针对sql_mode 进行分析实例分析,从三个方面给出解决方案;
- 进一步探讨了为何要设置sql_mode为only_full_group_by的条件;
- 进一步探讨了在默认sql_mode下如何正确操作数据的思路;
