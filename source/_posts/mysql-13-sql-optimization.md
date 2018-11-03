---
title: "mysql专题13 性能优化之sql语句优化"
date: 2018-10-06 10:01:54
categories: "mysql专题"
tags: [mysql]
description:
---
为应用服务提供稳定的数据CURD服务,同时为了进一步提升CURD性能及潜在的问题, 就需要根据实际业务情况及数据体量进行数据库优化修订工作, 关于数据库优化的操作可以从多个方面来总结归纳, 如对SQL语句的优化, 索引的优化, 表结构的优化, 配置的优化等等; 本文从总结实践经验及归纳回顾知识要点的角度来探讨关于SQL语句优化的相关问题;
<!--more-->

## 优化目的
- 避免出现页面访问错误
   1. 由于数据库连接timeout产生页面5xx错误;
   2. 由于慢查询造成页面无法加载;
   3. 由于阻塞造成数据无法提交;
- 增加数据库的稳定性
   1. 很多数据库问题都是由于低效的查询引起的;
- 优化用户体验
   1. 流畅页面的访问速度;
   2. 良好的业务功能体验;

## 优化方向及成本
大致可以从如下几个方向进行优化, 
- SQL语句优化;
- 索引优化;
- 数据库表结构优化;
- 配置优化(连接数限制/文件数限制等);
- 硬件优化(SSD显然能提高IO性能);

```sql
成本(低) --- > 高
SQL及索引 ---> 数据库表结构 ---> 系统配置 ---> 硬件
效果(高) <---  低
```

## 数据准备
实验数据库采用mysql官方提供的示例数据库 sakila database,
- installation: https://dev.mysql.com/doc/sakila/en/sakila-installation.html
- sakila database zip: https://dev.mysql.com/doc/index-other.html

导入sakila数据库及数据
```sql
root@(none)>source /sqls/sakila-db/sakila-schema.sql;
root@sakila>source /sqls/sakila-db/sakila-data.sql;
root@sakila>select count(*) from film;
+----------+
| count(*) |
+----------+
|     1000 |
+----------+
1 row in set (0.00 sec)
```

- 普通账号没有设置创建schema的权限也不应设置其具有这样的权限, 所以先登录root账号导入sakila数据库及示例数据;

授权普通账号dev操作sakila数据库的权限
```sql
mysql> grant all privileges on sakila.* to 'dev'@'%' with grant option;
Query OK, 0 rows affected (0.05 sec)

mysql> flush privileges;
Query OK, 0 rows affected (0.02 sec)
```
- 导入成功后, 需要对普通账号dev授权,dev账号才可以使用sakila数据库, 在mysql8.0+中授权分为创建账号和授权两个过程; 
- 因为dev账号已创建; 所以这里只需要授权即可;
- 建议养成对普通账号每次只针对某个数据库的某些操作进行授权的习惯; 只要需要时才进行进一步授权; 

登录dev普通账号;

```sql
dev@(none)>use sakila;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
dev@sakila>

dev@sakila>select @@version;
+-----------+
| @@version |
+-----------+
| 8.0.12    |
+-----------+
1 row in set (0.00 sec)
```

如何发现有问题的SQL?
在进行SQL语句及索引优化之前, 需要知道哪些查询是需要优化的,是有效率问题的, 在mysql中可以用其提供的慢查询日志把那些有效率的日志记录下来, 然后进行分析优化, 

## 慢查日志
使用Mysql慢查日志对有效率的SQL进行监控,

开启慢查日志
- show variables like 'slow_query_log'
- set global slow_query_log_file = '/var/log/mysql/mysql-slow.log'
- set global log_queries_not_using_indexes = on;
- set global long_query_time =1 #即超过一秒的查询日志记录到慢查日志中;

### 查看慢查询开启状态 

```sql
dev@sakila>show variables like 'slow_query_log';
+----------------+-------+
| Variable_name  | Value |
+----------------+-------+
| slow_query_log | OFF   |
+----------------+-------+
1 row in set (0.04 sec)

# 查看到slow_query_log 和 log_queries_not_using_indexes 都是未开启状态;
dev@sakila>show variables like '%log%';
+--------------------------------------------+---------------------------------------------+
| Variable_name                              | Value                                       |
+--------------------------------------------+---------------------------------------------+
| activate_all_roles_on_login                | OFF                                         |
| back_log                                   | 151                                         |
| log_error                                  | stderr                                      |
| log_error_services                         | log_filter_internal; log_sink_internal      |
| log_error_verbosity                        | 2                                           |
| log_output                                 | FILE                                        |
| log_queries_not_using_indexes              | OFF                                         |
| slow_query_log_file                        | /var/lib/mysql/2139b750c3f3-slow.log        |
...
+--------------------------------------------+---------------------------------------------+
81 rows in set (0.00 sec)
```

- `slow_query_log OFF` 慢查日志  状态 - 未开启
- `log_queries_not_using_indexes`  将没有创建索引的SQL查询日志记录到慢查日志中 状态 - 未开启 

查看执行时间超过多少s的SQL查询日志会记录到慢查日志中

```sql
mysql> show variables like 'long_query_time';
+-----------------+-----------+
| Variable_name   | Value     |
+-----------------+-----------+
| long_query_time | 10.000000 |
+-----------------+-----------+
1 row in set (0.00 sec)
```

- `long_query_time`默认是执行时间超过10s的SQL查询将记录到慢查日志中;

### 慢查日志位置

```sql
mysql> show variables like 'slow_query_log_file';
+---------------------+--------------------------------------+
| Variable_name       | Value                                |
+---------------------+--------------------------------------+
| slow_query_log_file |/var/lib/mysql/2139b750c3f3-slow.log  |
+---------------------+--------------------------------------+
1 row in set (0.00 sec)
```

- `slow_query_log_file` 慢查日志默认位置在`/var/lib/mysql/2139b750c3f3-slow.log`


为便于学习实验 将设置long_query_time=0s; 即将所有查询日志都记录到慢查日志中, 实际使用中一般设置超过100ms的SQL查询记录到慢查日志中; 
```
mysql> set global long_query_time=0;
Query OK, 0 rows affected (0.00 sec)
#退出重新登录在查询
mysql> show variables like 'long_query_time';
+-----------------+----------+
| Variable_name   | Value    |
+-----------------+----------+
| long_query_time | 0.000000 |
+-----------------+----------+
1 row in set (0.00 sec)
```

- 设置long_query_time参数时，需要重新连接才能生效，不需要重启服务; 否则通过`show variables like 'long_query_time'` 查看不到变化;

开启将没有创建索引的sql查询日志记录到慢查日志中
```sql
mysql> set global log_queries_not_using_indexes=on;
Query OK, 0 rows affected (0.00 sec)
```

设置慢查日志文件位置 

```sql
mysql> set global slow_query_log_file="/var/log/mysql/mysql-slow.log";
Query OK, 0 rows affected (0.00 sec)
mysql> show variables like 'slow_query_log_file';
+---------------------+-------------------------------+
| Variable_name       | Value                         |
+---------------------+-------------------------------+
| slow_query_log_file | /var/log/mysql/mysql-slow.log |
+---------------------+-------------------------------+
1 row in set (0.00 sec)
```
- 设置`slow_query_log_file`时, 目录必须存在, 并且mysql有权读写该目录,

```sql
mkdir /var/log/mysql
chown mysql:mysql /var/log/mysql
```
否则报错

```sql
mysql> set global slow_query_log_file="/var/log/mysql/mysql-slow.log";
ERROR 1231 (42000): Variable 'slow_query_log_file' can't be set to the value of '/var/log/mysql/mysql-slow.log'
```

### 开启慢查日志 

```sql
mysql> set global slow_query_log=on;
Query OK, 0 rows affected (0.02 sec)
```

### 查看慢查日志

进行简单的查询操作查看慢日志文件是否有记录
```sql
dev@sakila>show tables;
dev@sakila>select * from film limit 10;
```

### 调整时区

```sql 
dev@sakila>show variables like '%time_zone%';
+------------------+--------+
| Variable_name    | Value  |
+------------------+--------+
| system_time_zone | UTC    |
| time_zone        | SYSTEM |
+------------------+--------+
2 rows in set (0.00 sec)

dev@sakila>set time_zone='+8:00';
Query OK, 0 rows affected (0.00 sec)

dev@sakila>show variables like '%time_zone%';
+------------------+--------+
| Variable_name    | Value  |
+------------------+--------+
| system_time_zone | UTC    |
| time_zone        | +08:00 |
+------------------+--------+
2 rows in set (0.00 sec)
```

在命令一个终端可以查看到SQL查询日志记录到了慢查日志文件中, 

```sql
➜  ~ docker exec -it mysql-db tail -f /var/log/mysql/mysql-slow.log
# Time: 2018-11-03T06:12:56.235450Z
# User@Host: dev[dev] @ localhost []  Id:    28
# Query_time: 0.000182  Lock_time: 0.000000 Rows_sent: 1  Rows_examined: 0
SET timestamp=1541225576;
SELECT DATABASE();
# Time: 2018-11-03T06:12:56.235855Z
# User@Host: dev[dev] @ localhost []  Id:    28
# Query_time: 0.000160  Lock_time: 0.000000 Rows_sent: 1  Rows_examined: 0
SET timestamp=1541225576;
# administrator command: Init DB;
# Time: 2018-11-03T06:13:34.376262Z
# User@Host: dev[dev] @ localhost []  Id:    28
# Query_time: 0.000779  Lock_time: 0.000337 Rows_sent: 10  Rows_examined: 10
SET timestamp=1541225614;
select * from film limit 10;
# Time: 2018-11-03T06:14:21.627579Z
# User@Host: dev[dev] @ localhost []  Id:    28
# Query_time: 0.000388  Lock_time: 0.000121 Rows_sent: 1  Rows_examined: 0
SET timestamp=1541225661;
select count(*) from film;
```

### 慢查日志存储格式

```sql
# Time: 2018-11-03T06:14:21.627579Z
# User@Host: dev[dev] @ localhost []  Id:    28
# Query_time: 0.000388  Lock_time: 0.000121 Rows_sent: 1  Rows_examined: 0
SET timestamp=1541225661;
select count(*) from film;
```

一条慢查日志主要包括五个部分

1. 查询的执行时间

```sql
# Time: 2018-11-03T06:14:21.627579Z
```

2. 执行SQL的主机信息

```sql 
# User@Host: dev[dev] @ localhost []  Id:    28
```

3. SQL的执行信息

```sql
# Query_time: 0.000388  Lock_time: 0.000121 Rows_sent: 1  Rows_examined: 0
```

4. SQL的执行时间

```sql
SET timestamp=1541225661;
```

5. SQL的内容

```sql
select count(*) from film;
```

## 慢查日志分析
慢查询日志分析工具有很多, 如mysqlsla, pt-query-digest以及官方默认提供的mysqldumpslow等, 
### mysqldumpslow

mysqldumpslow 是一个MySQL官方提供的慢查日志分析工具

```sql
➜  ~ docker exec -it mysql-db mysqldumpslow -h
Option h requires an argument
ERROR: bad option

Usage: mysqldumpslow [ OPTS... ] [ LOGS... ]

Parse and summarize the MySQL slow query log. Options are

  --verbose    verbose
  --debug      debug
  --help       write this text to standard output

  -v           verbose
  -d           debug
  -s ORDER     what to sort by (al, at, ar, c, l, r, t), 'at' is default
                al: average lock time
                ar: average rows sent
                at: average query time
                 c: count
                 l: lock time
                 r: rows sent
                 t: query time
  -r           reverse the sort order (largest last instead of first)
  -t NUM       just show the top n queries
  -a           don't abstract all numbers to N and strings to 'S'
  -n NUM       abstract numbers with at least n digits within names
  -g PATTERN   grep: only consider stmts that include this string
  -h HOSTNAME  hostname of db server for *-slow.log filename (can be wildcard),
               default is '*', i.e. match all
  -i NAME      name of server instance (if using mysql.server startup script)
  -l           don't subtract lock time from total time
```

- 可以通过`s`指定排序规则;
- 通过`t`指定最前面的n条查询记录;

下面通过实例分析一条日志,

```sql
➜  ~ docker exec -it mysql-db mysqldumpslow -t 1 /var/log/mysql/mysql-slow.log;

Reading mysql slow query log from /var/log/mysql/mysql-slow.log
Count: 1  Time=0.02s (0s)  Lock=0.00s (0s)  Rows=0.0 (0), dev[dev]@localhost
  CREATE TRIGGER `ins_film` AFTER INSERT ON `film` FOR EACH ROW BEGIN
  INSERT INTO film_text (film_id, title, description)
  VALUES (new.film_id, new.title, new.description);
  END
```

|关键字|说明|
|:---|:---|
|`Count`|这条SQL执行的次数|
|`Time`|执行耗时|
|`Lock`|锁定时间|
|`Rows`|发送的行数|

### pt-query-digest
pt-query-digest是用于分析mySQL慢查询的一个工具，它可以分析binlog、General log、slowlog，也可以通过SHOWPROCESSLIST或者通过tcpdump抓取的MySQL协议数据来进行分析。可以把分析结果输出到文件中，分析过程是先对查询语句的条件进行参数化，然后对参数化以后的查询进行分组统计，统计出各查询的执行时间、次数、占比等，可以借助分析结果找出问题进行优化。

```sql 
输出到文件
pt-query-digest slow.log > slow_log.report

输出到数据库表
pt-query-digest slow.log -review \
h = 127.0.0.1,D=test,p=root,P=3306,u=root,t=query_review \
--create-reviewtable \
--review-history t=hostname_slow
```

常用选项
pt-query-digest常用选项, 

|选项|说明|
|:---|:---|
|`--create-review-table`|   当使用—review参数，把分析结果输出到表中|
|`--create-history-table`|   但是用—history参数，把分析结果输出到表中|
|`--filter`|   对输入的慢查询按指定的字符串进行匹配过滤后，在进行分析|
|`--limit`|   限制输出结果百分比或数量，默认值是20，即将最慢的20条语句输出|
|`--host`|   HostName|
|`--user`|   用户名|
|`--password`|   密码|
|`--history`|   将分析结果保存到表中，分析结果比较详细|
|`--review`| 将分析结果保存到表中|
|`--output`|   分析结果输出类型|
|`--since`|   从什么时间开始分析，值为字符串|
|`--until`|   截止时间，配合since一起分析|

pt-query-digest分析结果主要有以下几部分,
- 总体统计结果;
- 查询分组统计结果;
- 每一种查询的详细统计结果;

总体统计结果,

```sql
# 59.5s user time, 90ms system time, 51.81M rss, 228.12M vsz
# Current date: Sun Aug  3 16:09:31 2014
# Hostname: db1.test.com
# Files: /var/log/mysql/mysql-slow.log
# Overall: 224.01k total, 570 unique, 0.01 QPS, 0.09x concurrency ________
# Time range: 2013-10-09 17:55:04 to 2014-08-03 15:16:38
# Attribute          total     min     max     avg     95%  stddev  median
# ============     ======= ======= ======= ======= ======= ======= =======
# Exec time        2188385s      2s   7229s     10s     13s     67s      5s
# Lock time        100721s       0    365s   450ms      2s      5s   119us
# Rows sent         26.98G       0   3.30M 126.27k 328.61k 371.66k    4.96
# Rows examine     394.85G       0   3.32G   1.80M   3.03M  20.83M 562.03k
# Query size        78.65M       6   5.54k  368.18  685.39  241.61  271.23
```

|选项|说明|
|:---|:---|
|`Overall`|总共有多少条查询|
|`unique`|唯一查询数量|
|`Time range`|查询执行的时间范围|
|`total`|总计|
|`min`|最小|
|`max`|最大|
|`avg`|平均|
|`95%`|95%的查询时间，重点分析|
|`median`|中位数，把所有值从小到大排列，位置位于中间那个数|

分组统计结果,

```sql
# Profile
# Rank Query ID           Response time     Calls R/Call    V/M   Item
# ==== ================== ================= ===== ========= ===== ========
#    1 0xA6FE3D6982868655 351140.1266 16.0%   622  564.5340 99... CREATE TABLE dw_user_cache `dw_user_cache`
#    2 0x281C83DE62A11A8B 310896.7675 14.2% 40841    7.6124  6.51 SELECT dw_borrow_tender dw_borrow dw_user dw_credit dw_credit_rank
#    3 0x26BA6BEAE6C74350 279545.6534 12.8%  1305  214.2112 25... SELECT dw_account_log    
```

|选项|说明|
|:---|:---|
|`Response`|总的响应时间|
|`time`|该查询在本次分析中占用的时间比|
|`Calls`|执行次数|
|`R/Call`|平均每次执行的响应时间|
|`Item`|查询对象|

每一种查询的详细统计结果,

```sql
# Query 172: 0.00 QPS, 0.00x concurrency, ID 0x61199112D48D8F69 at byte 56964086
# This item is included in the report because it matches --outliers.
# Scores: V/M = 0.85
# Time range: 2013-11-20 17:00:38 to 2014-03-23 09:00:45
# Attribute    pct   total     min     max     avg     95%  stddev  median
# ============ === ======= ======= ======= ======= ======= ======= =======
# Count          0      26
# Exec time      0    172s      5s     17s      7s      8s      2s      6s
# Lock time      0     3ms    63us   180us   100us   119us    22us    93us
# Rows sent      0     208       8       8       8       8       0       8
# Rows examine   0 333.82k   6.95k  20.62k  12.84k  18.47k   4.33k  10.80k
# Query size     0   5.59k     220     220     220     220       0     220
# String:
# Databases    test2
# Hosts
# Users        rx1919 (24/92%), tn1819 (2/7%)
# Query_time distribution
#   1us
#  10us
# 100us
#   1ms
#  10ms
# 100ms
#    1s  ################################################################
#  10s+  #####
# Tables
#    SHOW TABLE STATUS FROM `test2` LIKE 'dw_bbs_topics'G
#    SHOW CREATE TABLE `test2`.`dw_bbs_topics`G
#    SHOW TABLE STATUS FROM `test2` LIKE 'dw_bbs_forums'G
#    SHOW CREATE TABLE `test2`.`dw_bbs_forums`G
# EXPLAIN /*!50100 PARTITIONS*/
select p1.*,p2.name as forum_name from `dw_bbs_topics` as p1 
                                left join dw_bbs_forums as p2 on p2.id = p1.fid
                                where isrecycle<>1 and isrecycle<>1 and p1.status = 1 and p1.isgood = 1    order by rand()   limit 8G
```

|选项|说明|
|:---|:---|
|`ID`|查询的ID号，和上图的Query ID对应|
|`Databases`| 数据库名|
|`Users`|各个用户执行的次数（占比）|
|`Query_time distribution`|查询时间分布, 长短体现区间占比，本例中1s-10s之间查询数量是10s以上的两倍|
|`Tables`|查询涉及到的表|
|`EXPLAIN`|示例|

### 用法举例

```sql
(1)直接分析慢查询文件:
pt-query-digest  slow.log > slow_report.log

(2)分析最近12小时内的查询：
pt-query-digest  --since=12h  slow.log > slow_report2.log

(3)分析指定时间范围内的查询：
pt-query-digest slow.log --since '2014-04-17 09:30:00' --until '2014-04-17 10:00:00'> > slow_report3.log

(4)分析指含有select语句的慢查询
pt-query-digest--filter '$event->{fingerprint} =~ m/^select/i' slow.log> slow_report4.log

(5) 针对某个用户的慢查询
pt-query-digest--filter '($event->{user} || "") =~ m/^root/i' slow.log> slow_report5.log

(6) 查询所有所有的全表扫描或full join的慢查询
pt-query-digest--filter '(($event->{Full_scan} || "") eq "yes") ||(($event->{Full_join} || "") eq "yes")' slow.log> slow_report6.log

(7)把查询保存到query_review表
pt-query-digest  --user=root –password=abc123 --review  h=localhost,D=test,t=query_review--create-review-table  slow.log

(8)把查询保存到query_history表
pt-query-digest  --user=root –password=abc123 --review  h=localhost,D=test,t=query_ history--create-review-table  slow.log_20140401
pt-query-digest  --user=root –password=abc123--review  h=localhost,D=test,t=query_history--create-review-table  slow.log_20140402

(9)通过tcpdump抓取mysql的tcp协议数据，然后再分析
tcpdump -s 65535 -x -nn -q -tttt -i any -c 1000 port 3306 > mysql.tcp.txt
pt-query-digest --type tcpdump mysql.tcp.txt> slow_report9.log

(10)分析binlog
mysqlbinlog mysql-bin.000093 > mysql-bin000093.sql
pt-query-digest  --type=binlog  mysql-bin000093.sql > slow_report10.log

(11)分析general log
pt-query-digest  --type=genlog  localhost.log > slow_report11.log
```

## 通过慢查日志发现问题SQL
如何通过慢查日志发现有问题的SQL？ 主要通过以下几个方面来判断, 
1. 查询次数多且每次查询占用时间长的SQL
通常为pt-query-digest分析的前几个查询

2. IO大的SQL
注意pt-query-digest分析中的Rows examine项 (Rows examine 指一条查询SQL中扫描的行数), 扫描行数越多, 说明其IO消耗也会越大;

3. 未命中索引的SQL
注意pt-query-digest分析中Rows examine 和Rows Send的对比,  Rows examine(扫描的行数) 要比Rows Send(发送的行数)数据大得多, 说明此次查询基本靠扫描查询出来的;


## 通过explain查询和分析SQL的执行计划

如何分析SQL查询

1. 使用explain查询SQL的执行计划

```sql
dev@sakila>explain select customer_id, first_name, last_name from customer \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: customer
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 599
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)
```

|列名|说明|
|:---|:---|
|`select_type`|查询的类型|
|`table`|显示这一行的数据是关于哪张表的|
|`type`|这是重要的列, 显示连接使用了哪种类型, 从最好到最差的连接类型为const, eq_reg, ref,range, index 和 ALL|
|`possible_keys`|显示可能应用在这张表中的索引。 如果为空, 没有可能的索引|
|`key`|实际使用的索引。如果为NULL, 则没有使用索引|
|`key_len`|使用索引的长度。在不损失精确性的情况下, 长度越短越好|
|`ref`|显示索引的哪一列被使用了, 如果可能的话, 是一个常数|
|`rows`|MySQL认为必须检查的用来返回请求数据的行数|
|`filtered`| 扫描函数占数据表的比例|
|`extra`|是否需要额外的条件及操作来完成当前查询, 返回为NULL表示不需要, 如值为Using filesort或者Using temporary时 说明需要进行优化了|

select_type 查询类型说明,

|选择查询类型|说明|
|:---|:---|
|`SIMPLE`|简单查询(不适用union和子查询的)|
|`PRIMARY`|最外层的查询|
|`UNION`|UNION中的第二个或者后面的SELECT语句|
|`DEPENDENT`|UNION中的第二个或者后面的SELECT语句,依赖于外部查询|
|`UNION`|UNION结果|
|`SUBQUERY`|子查询中的第一个SELECT语句|
|`DEPENDENT`|子查询中的第一个SELECT语句，依赖于外部查询|
|`DERIVED`|派生表的SELECT(FROM子句的子查询)|
|`MATERIALIZED`|Materialized subquery|
|`UNCACHEABLE`|对于该结果不能被缓存，必须重新评估外部查询的每一行子查询|
|`UNCACHEABLE`|UNION中的第二个或者后面的SELECT语句属于不可缓存子查询 (see UNCACHEABLE SUBQUERY)|

type 连接类型说明, 

|连接类型|说明|
|:---|:---|
|`const` |指常数查找, 一般指对主键或唯一索引进行查找;|
|`eq_reg`| 指在一定范围内查找,一般是基于唯一索引/主键的范围查找;|
|`ref`  |常见于连接查询中, 基于某一个索引查找;|
|`range` |基于索引的范围查找;|
|`index` | 对索引进行扫描查找;|
|`ALL`  |进行表扫描查找;|

extra返回值说明,

|返回值|说明|
|:---|:---|
|`Using filesort`|Mysql需要进行额外的步骤来发现如何对返回的行排序。它根据连接类型以及存储排序键值和匹配条件的全部行的行指针来排序全部行|
|`Using temporary`| Mysql需要创建一个临时表来存储结果, 这通常发生在对不同的列集进行ORDER BY上, 而不是GROUP BY 上|

```sql
dev@sakila>explain select customer_id, first_name, last_name
    -> from customer
    -> where customer_id > 50
    -> group by customer_id, first_name, last_name
    -> having count(customer_id) > 1
    -> order by customer_id, first_name \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: customer
   partitions: NULL
         type: range
possible_keys: PRIMARY
          key: PRIMARY
      key_len: 2
          ref: NULL
         rows: 549
     filtered: 100.00
        Extra: Using where; Using temporary; Using filesort
1 row in set, 1 warning (0.00 sec)
```

> Mysql每次读取是以页为单位的, 而一页中存储的索引越多, 其查询效率就越高, 所以索引长度越小越好;

## Max()函数优化

Max()函数经常会被用于查找出最大的或最后的某个时间或数值操作;

Max()函数示例, 查询最后支付时间,

```sql
dev@sakila>explain select max(payment_date) from payment \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: payment
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 16086
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)
```

- type值为ALL 表示进行表扫描; 
- rows值为16086 表示扫描了16086行数据;
- filtered值为100 表示进行了完整全表扫描;

显然当payment数据量很大时就会消耗更多的IO, 从而会拖慢服务器的性能;

通常情况下 是对这个字段建立索引, 

```sql
dev@sakila>create index idx_paydate on payment(payment_date);
Query OK, 0 rows affected (0.11 sec)
Records: 0  Duplicates: 0  Warnings: 0

dev@sakila>explain select max(payment_date) from payment \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: NULL
   partitions: NULL
         type: NULL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: NULL
     filtered: NULL
        Extra: Select tables optimized away
1 row in set, 1 warning (0.00 sec)
```

通过建立索引后, 可以看到查询类型不在是All, 同时Extra 表示为 Select tables optimized away, 表示不需进行表的操作就可以完成查询, 因为索引是按顺序排序的, 通过索引就可以知道payment_date最后一个数据值, 因此并不需要进行表的操作, 大大优化了执行效率, 同时尽可能大的减少IO操作, 这种情况下不过payment_date的数据结构是什么样的, 不管它的数据量有多大, 它的执行效率基本是恒定的;

所以像Max()函数这类的操作优化的思路之一就是为字段建立索引来进行优化;

## Count()函数优化

问题: 在一条SQL中同时查出2006年和2007年电影的数量

方式一

```sql
SELECT COUNT(release_year='2006' OR release_year='2007') FROM film;
```

方式二

```sql
SELECT COUNT(*) FROM film WHERE release_year='2006' AND release_year='2007';
```

方式一无法区分2006和2007的电影数量;
方式二release_year值不存在同时为2006和2007的情况;

显然方式一二都无法满足需求, 合理的方式是, 

```sql
dev@sakila>select
    -> count(release_year='2006' OR NULL) AS '2006年电影数量',
    -> count(release_year='2007' OR NULL) AS '2007年电影数量'
    -> from film \G
*************************** 1. row ***************************
2006年电影数量: 1000
2007年电影数量: 0
1 row in set (0.01 sec)
```

问题一: count()函数参数里面是用星号(*)号好还是用列名好? 

说明 count()函数参数用星号和列名分别查询的结果 有时候是不一样的, 需要注意,

```sql
dev@sakila>create table tbtest(id int, name char(20));
Query OK, 0 rows affected (0.09 sec)

dev@sakila>insert tbtest values(1, 'Tom'), (2,NULL);
Query OK, 2 rows affected (0.08 sec)
Records: 2  Duplicates: 0  Warnings: 0

dev@sakila>select count(*), count(id), count(name) from tbtest;
+----------+-----------+-------------+
| count(*) | count(id) | count(name) |
+----------+-----------+-------------+
|        2 |         2 |           1 |
+----------+-----------+-------------+
1 row in set (0.00 sec)
```

上述示例说明count(*)是指存在的具体数据行数, 而count(列名)是指这列值不为NULL的行数; 

同时要注意 count(release_year='2007' OR NULL) 后面的`OR NULL` 这个表示当前面的查询不存在时返回NULL,
如果直接写成count(relase_year='2007') 那当不存在'2007'的条件值时 返回的结果是count(*)的值;

下面通过示例进一步分析, 

```sql
dev@sakila>create table tb19(name char(20), age tinyint unsigned);
Query OK, 0 rows affected (0.07 sec)

dev@sakila>insert tb19 values('Tom',19), ('Mike',20),
    -> ('jack',NULL), ('jason',19), ('oliva',19), ('reminer',20);
Query OK, 5 rows affected (0.07 sec)
Records: 5  Duplicates: 0  Warnings: 0

dev@sakila>select
    -> count(*),
    -> count(age=19),
    -> count(age=19 OR NULL),
    -> count(age=21),
    -> count(age=21 OR NULL),
    -> count(name),
    -> count(age)
    -> from tb19 \G
*************************** 1. row ***************************
             count(*): 6
        count(age=19): 5
count(age=19 OR NULL): 3
        count(age=21): 5
count(age=21 OR NULL): 0
          count(name): 6
           count(age): 5
1 row in set (0.00 sec)
```
- count(*) 返回数据表中当前的数据行数;
- count(age =19) 相当于count(age), 即不管count(age= N) 都相当于count(age)的返回值,count(age)计算这列不为NULL的记录之和; 
- count(age =19 OR NULL) 表示只有age=19条件时才参与结果统计, age=NULL或其它值均不参与结果统计;
- count(age=21)  与count(age) 值相同;
- count(列名) 即统计该列值不为NULL的记录总数;

## 子查询优化

通常情况下, 需要把子查询优化为join查询, 但是在优化时要注意关联键是否有一对多的关系, 需要注意重复数据;

### 1对多关系带来的重复数据问题

关于数据重复问题示例, 

```sql 
dev@sakila>create table t(id int);
Query OK, 0 rows affected (0.07 sec)

dev@sakila>create table t1(tid int);
Query OK, 0 rows affected (0.07 sec)

dev@sakila>insert t values(1);
Query OK, 1 row affected (0.04 sec)

dev@sakila>insert t1 values(1), (1);
Query OK, 2 row affected (0.07 sec)

```
查询t表id, 要求t表id是t1表中的tid的值范围;

子查询

```sql 
dev@sakila>select * from t where t.id in (select t1.tid from t1);
+------+
| id   |
+------+
|    1 |
+------+
1 row in set (0.00 sec)
```

修改为连接查询, 

```sql
dev@sakila>select t.id id from t inner join t1 on t.id = t1.tid;
+------+
| id   |
+------+
|    1 |
|    1 |
+------+
2 rows in set (0.00 sec)
```

因为t.id 与t1.tid存在1对多的关系, 所以用连接查询出现了重复数据问题, 那此时就需要通过distinct来处理重复问题;

```sql
dev@sakila>select distinct t.id id from t inner join t1 on t.id = t1.tid;
+------+
| id   |
+------+
|    1 |
+------+
1 row in set (0.00 sec)
```

### 实例分析

问题: 查询sandra出演的所有影片

子查询,

```sql
dev@sakila>select title, release_year, length
    -> from film
    -> where film_id in (
    -> select film_id from film_actor where actor_id in (
    -> select actor_id from actor where first_name = 'sandra'));
```

修改为连接查询,

```sql
dev@sakila>explain select title, release_year, length
    -> from film
    -> join film_actor fa on film.film_id = fa.film_id
    -> join actor a on fa.actor_id = a.actor_id where a.first_name = 'sandra';
```

子查询与连接查询执行计划对比,

```sql
dev@sakila>explain select title, release_year, length
    -> from film
    -> where film_id in (
    -> select film_id from film_actor where actor_id in (
    -> select actor_id from actor where first_name = 'sandra'));
+----+--------------+-------------+------------+--------+------------------------+---------+---------+-----------------------+------+----------+-------------+
| id | select_type  | table       | partitions | type   | possible_keys          | key     | key_len | ref                   | rows | filtered | Extra       |
+----+--------------+-------------+------------+--------+------------------------+---------+---------+-----------------------+------+----------+-------------+
|  1 | SIMPLE       | <subquery2> | NULL       | ALL    | NULL                   | NULL    | NULL    | NULL                  | NULL |   100.00 | NULL        |
|  1 | SIMPLE       | film        | NULL       | eq_ref | PRIMARY                | PRIMARY | 2       | <subquery2>.film_id   |    1 |   100.00 | NULL        |
|  2 | MATERIALIZED | actor       | NULL       | ALL    | PRIMARY                | NULL    | NULL    | NULL                  |  200 |    10.00 | Using where |
|  2 | MATERIALIZED | film_actor  | NULL       | ref    | PRIMARY,idx_fk_film_id | PRIMARY | 2       | sakila.actor.actor_id |   27 |   100.00 | Using index |
+----+--------------+-------------+------------+--------+------------------------+---------+---------+-----------------------+------+----------+-------------+
4 rows in set, 1 warning (0.00 sec)

dev@sakila>explain select title, release_year, length
    -> from film
    -> join film_actor fa on film.film_id = fa.film_id
    -> join actor a on fa.actor_id = a.actor_id where a.first_name = 'sandra';
+----+-------------+-------+------------+--------+------------------------+---------+---------+-------------------+------+----------+-------------+
| id | select_type | table | partitions | type   | possible_keys          | key     | key_len | ref               | rows | filtered | Extra       |
+----+-------------+-------+------------+--------+------------------------+---------+---------+-------------------+------+----------+-------------+
|  1 | SIMPLE      | a     | NULL       | ALL    | PRIMARY                | NULL    | NULL    | NULL              |  200 |    10.00 | Using where |
|  1 | SIMPLE      | fa    | NULL       | ref    | PRIMARY,idx_fk_film_id | PRIMARY | 2       | sakila.a.actor_id |   27 |   100.00 | Using index |
|  1 | SIMPLE      | film  | NULL       | eq_ref | PRIMARY                | PRIMARY | 2       | sakila.fa.film_id |    1 |   100.00 | NULL        |
+----+-------------+-------+------------+--------+------------------------+---------+---------+-------------------+------+----------+-------------+
3 rows in set, 1 warning (0.00 sec)
```

- 同对比中可以优化后的连接查询比子查询要少进行一次子查询引发的全表扫描查询操作, 如果数据量很大的时候, 优化效果将灰常明显;


## group by优化

对关联中的某一列进行group by 时, 尽量选用来自同一张表的列进行group by 操作;

问题: 查询每个演员所参演的影片的数量

查询语句, 

```sql 
select actor.first_name, actor.last_name, count(*) from sakila.film_actor 
inner join sakila.actor using(actor_id) group by film_actor.actor_id;
```

执行计划,

```sql
dev@sakila>explain select actor.first_name, actor.last_name, count(*)
    -> from film_actor
    -> join actor using(actor_id)
    -> group by film_actor.actor_id;
+----+-------------+------------+------------+------+------------------------+---------+---------+-----------------------+------+----------+-----------------+
| id | select_type | table      | partitions | type | possible_keys          | key     | key_len | ref                   | rows | filtered | Extra           |
+----+-------------+------------+------------+------+------------------------+---------+---------+-----------------------+------+----------+-----------------+
|  1 | SIMPLE      | actor      | NULL       | ALL  | PRIMARY                | NULL    | NULL    | NULL                  |  200 |   100.00 | Using temporary |
|  1 | SIMPLE      | film_actor | NULL       | ref  | PRIMARY,idx_fk_film_id | PRIMARY | 2       | sakila.actor.actor_id |   27 |   100.00 | Using index     |
+----+-------------+------------+------------+------+------------------------+---------+---------+-----------------------+------+----------+-----------------+
2 rows in set, 1 warning (0.00 sec)
```

可以看到执行计划中将用到临时表来支持查询操作, 那么最好对这个查询语句进行改写, 尽量避免使用临时表来进行操作, 

改写后的查询语句,

```sql
select actor.first_name, actor.last_name, c.cnt
from actor 
join (select actor_id, count(*) as cnt from film_actor group by actor_id) as c using(actor_id);
```

- using(id) 等价于 on actor.actor_id = c.actor_id的意思;

对比执行计划

```sql
dev@sakila>explain select actor.first_name, actor.last_name, c.cnt
    -> from actor
    -> inner join (
    -> select actor_id, count(*) as cnt from film_actor group by actor_id
    -> ) as c using(actor_id);
+----+-------------+------------+------------+-------+------------------------+-------------+---------+-----------------------+------+----------+-------------+
| id | select_type | table      | partitions | type  | possible_keys          | key         | key_len | ref                   | rows | filtered | Extra       |
+----+-------------+------------+------------+-------+------------------------+-------------+---------+-----------------------+------+----------+-------------+
|  1 | PRIMARY     | actor      | NULL       | ALL   | PRIMARY                | NULL        | NULL    | NULL                  |  200 |   100.00 | NULL        |
|  1 | PRIMARY     | <derived2> | NULL       | ref   | <auto_key0>            | <auto_key0> | 2       | sakila.actor.actor_id |   27 |   100.00 | NULL        |
|  2 | DERIVED     | film_actor | NULL       | index | PRIMARY,idx_fk_film_id | PRIMARY     | 4       | NULL                  | 5462 |   100.00 | Using index |
+----+-------------+------------+------------+-------+------------------------+-------------+---------+-----------------------+------+----------+-------------+
3 rows in set, 1 warning (0.00 sec)
```

- 可见优化后 就不需要使用临时表来辅助查询操作了; 
- 在上述语句中是先通过子查询查询到演员及其参演电影数量然后通过连接查询连接演员的基本信息, 这就是说 子查询可以通过修改为连接查询来进一步优化, 那有时候有可能在连接查询中应用子查询来提高查询效率, 具体优化时应根据实际情况进行灵活应用;

## limit查询优化

limit常用于分页处理, 时常会伴随order by 从句使用, 因此大多时候会使用filesorts, 这样会造成大量IO问题;

问题: 获取影片信息,

```sql 
select film_id, description from film order by title limit 50, 5;
```

优化1,

使用有索引的列或主键进行Order by 操作;

```sql 
dev@sakila>explain select film_id, description from film order by title limit 50, 5 \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: film
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 1000
     filtered: 100.00
        Extra: Using filesort
1 row in set, 1 warning (0.00 sec)

dev@sakila>explain select film_id, description from film order by film_id limit 50, 5 \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: film
   partitions: NULL
         type: index
possible_keys: NULL
          key: PRIMARY
      key_len: 2
          ref: NULL
         rows: 55
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)
select film_id, description from film order by film_id limit 50, 5;
```

- 优化前需要用到filesort排序, 将order by 字段修改为索引的列或主键后, 就不需要额外的filesort排序, 从而可以减少很多IO操作;

上述优化存在一个问题， 当表中数据量很大时, 要扫描的行数也随之增大, 那就需要进一步优化,

优化2,

记录上次返回的主键, 在下次查询时使用主键过滤, 从而可以避免数据量大时扫描过多的记录;

```sql
dev@sakila>explain select film_id, description from film where film_id > 55 and film_id <= 60 order by film_id limit 1, 5 \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: film
   partitions: NULL
         type: range
possible_keys: PRIMARY
          key: PRIMARY
      key_len: 2
          ref: NULL
         rows: 5
     filtered: 100.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

上述优化后, 可以看到要扫描的行数就是要查询的行数量, 从而可以避免数据量很大时要查询靠后的数据引发扫描多行的问题;

当然上述优化有一个限制, 就是要求主键是连续的， 如果主键在中间是不连续的那按照上述优化, 有可能where子查询返回的条数不够要查询的条数;

上述两个优化的思想就是优化过多的扫描带来的IO消耗;

## 总结
- 简要概述了优化的目的及方向;
- 对慢查日志知识进行回顾并通过实例实践深入了解学习慢查日志分析来发现存在效率的SQL;
- 对max()函数场景进行优化, 实例分析max()函数场景优化前后的执行计划;
- 对count()函数场景进行优化, 并实例分析count()函数优化的执行计划;
- 回顾子查询相关知识并实例分析子查询优化过程;
- 对group by及limit查询进行实例分析优化过程, 总结出其适用的场景及使用时应注意的限制级问题;

