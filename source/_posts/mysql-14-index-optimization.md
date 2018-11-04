---
title: "mysql专题14 性能优化之索引优化"
date: 2018-10-07 08:53:28
categories: "mysql专题"
tags: [mysql]
description:
---
索引优化也是数据库优化的一个重要方向, 本文将从实践结合理论的角度回顾索引相关知识, 同时通过实例分析进一步学习索引选择及优化过程;
<!--more-->

## 创建合适索引原则

如何选择合适的列创建索引?
1. 在where从句, group by 从句, order by 从句, on 从句中出现的列;

2. 索引字段越小越好;

3. 离散度大的列放到联合索引的前面;

例如,

```sql
select * from payment where staff_id = 2 and customer_id = 580;
```
是index(staff_id, customer_id) 好还是index(customer_id, staff_id)好? 

由于customer_id的离散度更大, 所以应该使用index(customer_id, staff_id)


## 索引优化SQL
通常情况下, 索引可以提高查询效率, 但是会影响insert/update/delete这种修改语句, 降低写入效率, 索引并不是建立得越多越好, 但实际情况下过多的索引不但会影响写入同时也会影响查询效率, 因为在查询时首选要选择用哪个索引来进行查询, 如果索引多, 分析的就多, 从而分析过程就很长;

所以不见要知道如何选择合适的列创建索引, 也需要知道如何维护和删除重复和冗余的索引;

### 重复索引

重复索引指相同的列以相同的顺序建立的同类型的索引, 

```sql
create table test(
id int not null primary key,
name varchar(10) not null,
title varchar(50) not null,
unique(id)
) engine = InnoDB;
```

如上primary key 与ID列的上的索引这种情况即为重复索引;

### 冗余索引

冗余索引是指多个索引的前缀列相同, 或是在联合索引中包含了主键的索引, 

```sql
create table test(
id int not null primary key,
name varchar(10) not null,
title varchar(10) not null,
key(name,id)
)engine=InnoDB;
```

上述sql中key(name,id)就是一个冗余索引; 因为这个联合索引包含了主键索引;

### 查询重复及冗余索引

实例分析,

```sql
mysql> use information_schema;

mysql> select
    -> a.table_schema as 'database',
    -> a.table_name as 'table_name',
    -> a.index_name as 'index_one',
    -> b.index_name as 'index_two',
    -> a.column_name as 'duplicate_col_name'
    -> from statistics a
    -> join statistics b on
    -> a.table_schema = b.table_schema and
    -> a.table_name = b.table_name and
    -> a.seq_in_index = b.seq_in_index and
    -> a.column_name = b.column_name
    -> where a.seq_in_index = 1 and a.index_name <> b.index_name;
+-----------+--------------+-------------+-------------+--------------------+
| database  | table_name   | index_one   | index_two   | duplicate_col_name |
+-----------+--------------+-------------+-------------+--------------------+
| employees | departments  | dept_name   | dept_name_2 | dept_name          |
| employees | departments  | dept_name_2 | dept_name   | dept_name          |
| employees | dept_manager | PRIMARY     | emp_no      | emp_no             |
| employees | dept_manager | emp_no      | PRIMARY     | emp_no             |
+-----------+--------------+-------------+-------------+--------------------+
4 rows in set (0.01 sec)
```

上述sql语句用于查询所有数据库中存在重复前缀索引, 需要用到information_schema 元数据表中的一些信息所有需要注意use information_schema数据库下执行;

```sql
CREATE TABLE departments (
    dept_no     CHAR(4)         NOT NULL,
    dept_name   VARCHAR(40)     NOT NULL,
    PRIMARY KEY (dept_no),
    UNIQUE  KEY (dept_name),
		KEY (dept_name)
);

CREATE TABLE dept_manager (
   emp_no       INT             NOT NULL,
   dept_no      CHAR(4)         NOT NULL,
   from_date    DATE            NOT NULL,
   to_date      DATE            NOT NULL,
   FOREIGN KEY (emp_no)  REFERENCES employees (emp_no)    ON DELETE CASCADE,
   FOREIGN KEY (dept_no) REFERENCES departments (dept_no) ON DELETE CASCADE,
   PRIMARY KEY (emp_no,dept_no),
	KEY (emp_no)
);

```

从上述分析及表结构可以看出, 
- 在departments中UNIQUE KEY和KEY中存在重复索引;
- 在dept_manager中PRIMARY KEY和KEY中存在冗余索引;

## pt-duplicate-key-checker
上面通过SQL语句可以查询到重复及冗余索引, 也可以通过工具来查询, 如使用pt-duplicate-key-checker工具检查重复及冗余索引,

这个工具使用非常简单, 只需要提供下面几个参数即可,

```sql
pt-duplicate-key-checker \
-uroot \
-p 'pwd' \
-h 127.0.0.1 
```

同时这个工具还会提供一个修订的SQL方案供参考;

## 索引维护

### 删除不用索引
因业务变更等因素, 有些索引会不在被使用, 此时最好将其删除; 目前MySQL中还没有记录索引的使用情况, 但是在PerconMySQL和MariaDB中可以通过INDEX_STATISTICS表来查看哪些索引未使用, 但是在MySQL中目前只能通过慢查日志配合pt-index-usage工具来进行索引使用情况的分析, pt-index-usage 工具使用也非常简单, 

```sql
pt-index-usage \ 
-uroot -p 'pwd' \
mysql-slow.log
```

注意如果是主从集群, 则工具分析时应对所有慢查日志进行分析;

## 总结
- 优先将where/group by/order by/on从句中出现的列 创建索引; 并且索引字段越小越好; 如创建联合索引时, 建议将离散度大的列放在联合索引的前面;
- 不但要选择合适的列创建索引, 同时也应将重复及冗余索引删除;
- pt-duplicate-key-checker及pt-index-usage工具的联合使用, 可以帮助查询到重复及冗余和未使用的索引;


