---
title: "mysql专题02 mysql数据类型及数据表操作"
date: 2018-03-04 11:28:13
categories: "mysql专题"
tags: [mysql]
description:
---
区别于纯理论和纯实践步骤的文章, 本文将从实践结合理论的角度对常用的`Mysql`数据类型及使用进行归纳总结,从解决实际问题的角度出发在实践的基础上补充阐述理论知识，试图构建完整的`Mysql`知识体系, 深入学习了解`Mysql`常用数据类型对`Mysql`数据库表设计及优化非常重要;
<!--more-->

##### 搭建Mysql容器环境

```shell
# pull mysql image
➜  ~ docker pull mysql/mysql-server:5.7
# 启动 mysql 容器
➜  ~ docker run --name=dev-mysql -d -p 3307:3306 -e mysql_USER=dev -e mysql_PASSWORD=dev123 -e mysql_ROOT_PASSWORD=dev123456 -e mysql_DATABASE=testdb  mysql/mysql-server
# 登录mysql命令端
➜  ~ docker exec -it dev-mysql mysql -udev -P3307 -pdev123 --prompt "\u@\d>"
```

##### Mysql基础操作

```shell
# 创建testdb数据库
dev@(none)>create database if not exists testdb;
Query OK, 1 row affected (0.01 sec)

# 选择数据库
dev@(none)>use testdb;
Database changed

#查看数据库创建属性
dev@testdb>show create database testdb;
+----------+-------------------------------------------------------------------+
| Database | Create Database                                                   |
+----------+-------------------------------------------------------------------+
| testdb   | CREATE DATABASE `testdb` /*!40100 DEFAULT CHARACTER SET latin1 */ |
+----------+-------------------------------------------------------------------+
1 row in set (0.00 sec)

# 修改数据库字符集为utf8;
dev@testdb>alter database testdb character set utf8;
Query OK, 1 row affected (0.00 sec)

# 查看是否修改成功;
dev@testdb>show create database testdb;
+----------+-----------------------------------------------------------------+
| Database | Create Database                                                 |
+----------+-----------------------------------------------------------------+
| testdb   | CREATE DATABASE `testdb` /*!40100 DEFAULT CHARACTER SET utf8 */ |
+----------+-----------------------------------------------------------------+
1 row in set (0.00 sec)

# 删除数据库
dev@testdb>drop database if exists mydb;
Query OK, 0 rows affected (0.04 sec)

dev@testdb>
```

#####  SQL语句基本规范
- 关键字与函数名称全部大写;
- 数据库名称/表名称/字段名称全部小写;
- SQL语句必须以分号结尾;

`Mysql`数据类型是指列, 存储过程参数, 表达式和局部变量的数据特征, 它决定了数据的存储格式, 代表了不同的信息类型; 

##### 整型
* * *
`Mysql`整型主要有如下5类 

|数据类型|存储范围|字节|
|:---|:---|:---|
|TINYINT|有符号值: -128到127(-2<sup>7</sup>到2<sup>7</sup>-1)</br> 无符号值: 0 到255(0 到2<sup>8</sup>-1)|1|
|SMALLINT|有符号值: -32768到32767(-2<sup>15</sup>到2<sup>15</sup>-1)</br> 无符号值: 0 到65535(0 到2<sup>16</sup>-1)|2|
|MEDIUMINT|有符号值: -8388608到8388607(-2<sup>23</sup>到2<sup>23</sup>-1)</br> 无符号值: 0 到16777215(0 到2<sup>24</sup>-1)|3|
|INT|有符号值: -2147483648到2147483647(-2<sup>31</sup>到2<sup>31</sup>-1)</br> 无符号值: 0 到4294967295(0 到2<sup>32</sup>-1)|4|
|BIGINT|有符号值: -9223372036854775808到9223373036854775807(-2<sup>63</sup>到2<sup>63</sup>-1)</br> 无符号值: 0到18446744073709551615(0 到2<sup>64</sup>-1)|8|

如需要一个字段来存储年龄的话， 就没有必要采用`BIGINT`这样占用`8`个字节的类型， 因为年龄范围完全可用`TINYINT`来存储即可，这样每存储一个年龄就节省了7个字节，当数据量很大时是非常换算的; 

##### 浮点型
* * *
Mysql 支持的三个浮点类型是 FLOAT、DOUBLE 和 DECIMAL 类型。FLOAT 数值类型用于表示单精度浮点数值，而 DOUBLE 数值类型用于表示双精度浮点数值。

与整数一样，这些类型也带有附加参数：一个显示宽度指示器和一个小数点指示器。比如语句 FLOAT(7,3) 规定显示的值不会超过 7 位数字，小数点后面带有 3 位数字。

对于小数点后面的位数超过允许范围的值，Mysql 会自动将它四舍五入为最接近它的值，再插入它。

DECIMAL 数据类型用于精度要求非常高的计算中，这种类型允许指定数值的精度和计数方法作为选择参数。精度在这里指为这个值保存的有效数字的总个数，而计数方法表示小数点后数字的位数。比如语句 DECIMAL(7,3) 规定了存储的值不会超过 7 位数字，并且小数点后不超过 3 位。

忽略 DECIMAL 数据类型的精度和计数方法修饰符将会使 Mysql 数据库把所有标识为这个数据类型的字段精度设置为 10，计算方法设置为 0。

UNSIGNED 和 ZEROFILL 修饰符也可以被 FLOAT、DOUBLE 和 DECIMAL 数据类型使用。并且效果与 INT 数据类型相同。

|类型说明 |取值范围|
|:---|:---| 
|FLOAT[(M, D)]  |  最小非零值：±1.175494351E – 38        |
|DOUBLE[(M,D)]  |  最小非零值：±2.2250738585072014E – 308 |
|DECIMAL (M, D) |  可变；其值的范围依赖于M 和D |

##### 日期时间型
* * * 
Mysql所支持的日期时间类型有: DATETIME、 TIMESTAMP、DATE、TIME、YEAR;

Mysql中关于日期的类型有Date/Datetime/Timestamp三种类型,

|日期类型|	占用空间	|格式	         |最小值              |	最大值              |	零值表示|
|:---|:---|:---|:---|:---|:---|
| DATETIME	 |8 bytes	 |YYYY-MM-DD HH:MM:SS	 |1000-01-01 00:00:00	|9999-12-31 23:59:59 	|0000-00-00 00:00:00|
| TIMESTAMP	 |4 bytes	 |YYYY-MM-DD HH:MM:SS	 |19700101080001	    |2038 年的某个时刻	  |00000000000000|
| DATE	     |4 bytes	 |YYYY-MM-DD	         |1000-01-01 	        |9999-12-31 	        |0000-00-00|

-  日期赋值时，允许“不严格”语法：任何标点符都可以用做日期部分或时间部分之间的间割符。例如，'98-12-31 11:30:45'、'98.12.31 11+30+45'、'98/12/31 11*30*45'和'98@12@31 11^30^45'是等价的，对于不合法的将会转换为：0000-00-00 00:00:00

- `Date`和`DateTime`格式允许使用字符串或数字为此列复制;
日期格式的字段updated，通过字符串或数字赋值均可,
```sql
update person set updated= 12331212 where name= 'mike';
update person set updated= '1233-12-12' where name= 'name';
```
- `TimeStamp`指时间戳，从1970-01-01 00:00:00到当前的时间差值（注意：当你在Java中输出[new Date(0)] 的时候，输出的是：Thu Jan 01 08:00:00 CST 1970，这是因为时区的概念，中国是东八区，所以对应的是早上八点），它精确到毫秒级别，范围为：1970-01-01 00:00:00 到 2037年（参考2038年问题），当值大于2037年就会抛出： [Error Code: 1292, SQL State: 22001]  Data truncation: Incorrect datetime value: '20381212121212' for column 'updated' at row 1。设置值时只允许设置数字类型的值。

- 在为TimeStamp类型字段赋值的时候，值必须大于19700101000000，否则就会抛出： [Error Code: 1292, SQL State: 22001]  Data truncation: Incorrect datetime value: '10831212121212' for column 'updated' at row 1。


Mysql中时间类型用Time表示,

|时间类型|	占用空间	|格式	         |最小值              |	最大值              |	零值表示|
|:---|:---|:---|:---|:---|:---|
| TIME	     |3 bytes	 |HH:MM:SS	           |-838:59:59	        |838:59:59 	          |00:00:00|

Mysql以'HH:MM:SS'格式检索和显示TIME值(或对于大的小时值采用'HHH:MM:SS'格式)。TIME值的范围可以从'-838:59:59'到'838:59:59'。小时部分会因此大的原因是TIME类型不仅可以用于表示一天的时间(必须小于24小时)，还可能为某个事件过去的时间或两个事件之间的时间间隔(可以大于24小时，或者甚至为负)。 格式说明, 

- 'D HH:MM:SS.fraction'格式的字符串。还可以使用下面任何一种“非严格”语法：'HH:MM:SS.fraction'、'HH:MM:SS'、'HH:MM'、'D HH:MM:SS'、'D HH:MM'、'D HH'或'SS'。这里D表示日，可以取0到34之间的值。请注意Mysql还不保存分数。

- 'HHMMSS'格式的没有间割符的字符串，假定是有意义的时间。例如，'101112'被理解为'10:11:12'，但'109712'是不合法的(它有一个没有意义的分钟部分)，将变为'00:00:00'。

- HHMMSS格式的数值，假定是有意义的时间。例如，101112被理解为'10:11:12'。下面格式也可以理解：SS、MMSS、HHMMSS、HHMMSS.fraction。请注意Mysql还不保存分数。

- 函数返回的结果，其值适合TIME上下文，例如CURRENT_TIME。

- 超出TIME范围但合法的值被裁为范围最接近的端点。例如，'-850:00:00'和'850:00:00'被转换为'-838:59:59'和'838:59:59'。

Mysql中用year表示年类型,

|年类型|	占用空间	|格式	         |最小值              |	最大值              |	零值表示|
|:---|:---|:---|:---|:---|:---|
| YEAR	     |1 bytes	 |YYYY	               |1901 	              |2155 	              |0000|

Mysql以YYYY格式检索和显示YEAR值。范围是1901到2155。可以指定各种格式的YEAR值,

- 四位字符串，范围为'1901'到'2155'。

- 四位数字，范围为1901到2155。

- 两位字符串，范围为'00'到'99'。'00'到'69'和'70'到'99'范围的值被转换为2000到2069和1970到1999范围的YEAR值。

- 两位整数，范围为1到99。1到69和70到99范围的值被转换为2001到2069和1970到1999范围的YEAR值。请注意两位整数范围与两位字符串范围稍有不同，因为你不能直接将零指定为数字并将它解释为2000。你必须将它指定为一个字符串'0'或'00'或它被解释为0000。

- 函数返回的结果，其值适合YEAR上下文，例如NOW()。

- 非法YEAR值被转换为0000。

关于日期兼容性问题,
> Mysql服务器采用了Unix的时间功能，对于TIMESTAMP值，可处理的日期至2037年。对于DATE和DATETIME值，可接受的日期可至9999年。

> 所有的Mysql日期函数均是在1个源文件sql/time.cc中实现的，并经过了恰当编码以确保2000年安全。

> 在Mysql 3.22和以后的版本中，YEAR列类型能够在1个字节内保存0年以及1901～2155年，并能使用两位或四位数字显示它们。所有的两位数字年份均被视为介于1970～2069年之间，这意味着，如果你在YEAR列中保存了01，Mysql服务器会将其当作2001年。

##### 字符串型

Mysql中字符串类型大致分为可以变长和固定长度两类字符串,

|字符串类型 |描述及存储需求|
|:---|:---|
|CHAR(M)		  |M为0~255之间的整数|
|VARCHAR(M)	  |M为0~65536之间的整数|
|TINYBLOB	 	  |允许长度0~255字节|
|BLOB	 	      |允许长度0~65535字节|
|MEDUIMBLOB	  |允许长度0~167772150字节|
|LONGBLOB	 	  |允许长度0~4294967295|
|TINYTEXT	 	  |允许长度0~255字节|
|TEXT	 	      |允许长度0~65535字节|
|MEDIUMTEXT	 	|允许长度0~167772150字节|
|LONGTEXT	 	  |允许长度0~4294967295字节|
|VARBINARY(M)	|允许长度0~M个字节的边长字节字符集|
|BINARY(M)		|允许长度0~M个字节的定长字节字符集|

##### CHAR于VARCHAR类型
* * *
   - 用来保存Mysql中较短的字符串, 主要区别在于:CHAR列的长度固定为创建表时声明的长度，长度可以为从0~255的任何值，而VARCHAR的值可以是变长字符串，长度可以指定0~65535之间的值，在检索的时候，CHAR列会删除尾部的空格而VARCHAR则保留了这些空格。

```shell
dev@testdb>create table if not exists name(first varchar(4), last char(4));
Query OK, 0 rows affected (0.14 sec)

dev@testdb>desc name;
+-------+------------+------+-----+---------+-------+
| Field | Type       | Null | Key | Default | Extra |
+-------+------------+------+-----+---------+-------+
| first | varchar(4) | YES  |     | NULL    |       |
| last  | char(4)    | YES  |     | NULL    |       |
+-------+------------+------+-----+---------+-------+
2 rows in set (0.03 sec)

dev@testdb>insert name(first, last) values("ab ", "ab ");
Query OK, 1 row affected (0.00 sec)

dev@testdb>select length(first), length(last) from name limit 1;
+---------------+--------------+
| length(first) | length(last) |
+---------------+--------------+
|             3 |            2 |
+---------------+--------------+
1 row in set (0.00 sec)

dev@testdb>select concat(first, '+'), concat(last, '+') from name limit 1;
+--------------------+-------------------+
| concat(first, '+') | concat(last, '+') |
+--------------------+-------------------+
| ab +               | ab+               |
+--------------------+-------------------+
1 row in set (0.01 sec)

dev@testdb>
```

从上面可以看到, CHAR列最后的空格在做操作的时候都被删除，而VARCHAR依然保留这些空格;

- 4.0版本以下，varchar(20)，指的是20字节，如果存放UTF8汉字时，只能存6个（每个汉字3字节） ；5.0版本以上，varchar(20)，指的是20字符，无论存放的是数字、字母还是UTF8汉字（每个汉字3字节），都可以存放20个，最大大小是65532字节 ；varchar(20)在Mysql4中最大也不过是20个字节,但是Mysql5根据编码不同,存储大小也不同;

- **varchar 字段是将实际内容单独存储在聚簇索引之外，内容开头用1到2个字节表示实际长度（长度超过255时需要2个字节），因此最大长度不能超过65535;**

- 字符类型若为gbk，每个字符最多占2个字节，最大长度不能超过32766;字符类型若为utf8，每个字符最多占3个字节，最大长度不能超过21845。若定义的时候超过上述限制，则varchar字段会被强行转为text类型，并产生warning。

##### CHAR(M), VARCHAR(M)的区别
* * * 
- CHAR(M)定义的列的长度为固定的，M取值可以为0～255之间，当保存CHAR值时，在它们的右边填充空格以达到指定的长度。当检索到CHAR值时，尾部的空格被删除掉。在存储或检索过程中不进行大小写转换。CHAR存储定长数据很方便，CHAR字段上的索引效率级高，比如定义char(10)，那么不论你存储的数据是否达到了10个字节，都要占去10个字节的空间,不足的自动用空格填充;

- VARCHAR(M)定义的列的长度为可变长字符串，M取值可以为0~65535之间，(VARCHAR的最大有效长度由最大行大小和使用的字符集确定。整体最大长度是65,532字节）。VARCHAR值保存时只保存需要的字符数，另加一个字节来记录长度(如果列声明的长度超过255，则使用两个字节)。VARCHAR值保存时不进行填充。当值保存和检索时尾部的空格仍保留，符合标准SQL。varchar存储变长数据，但存储效率没有CHAR高。如果一个字段可能的值是不固定长度的，我们只知道它不可能超过10个字符，把它定义为 VARCHAR(10)是最合算的。VARCHAR类型的实际长度是它的值的实际长度+1。为什么"+1"呢？这一个字节用于保存实际使用了多大的长度。从空间上考虑，用varchar合适；从效率上考虑，用char合适，关键是根据实际情况找到权衡点;

- CHAR和VARCHAR最大的不同就是一个是固定长度，一个是可变长度。由于是可变长度，因此实际存储的时候是实际字符串再加上一个记录字符串长度的字节(如果超过255则需要两个字节)。如果分配给CHAR或VARCHAR列的值超过列的最大长度，则对值进行裁剪以使其适合。如果被裁掉的字符不是空格，则会产生一条警告。如果裁剪非空格字符，则会造成错误(而不是警告)并通过使用严格SQL模式禁用值的插入;

##### VARCHAR和TEXT、BlOB类型的区别
* * * 
- VARCHAR，BLOB和TEXT类型是变长类型，对于其存储需求取决于列值的实际长度(在前面的表格中用L表示)，而不是取决于类型的最大可能尺寸。例如，一个VARCHAR(10)列能保存最大长度为10个字符的一个字符串，实际的存储需要是字符串的长度 ，加上1个字节以记录字符串的长度。对于字符串'abcd'，L是4而存储要求是5个字节。

- BLOB和TEXT类型需要1，2，3或4个字节来记录列值的长度，这取决于类型的最大可能长度。VARCHAR需要定义大小，有65535字节的最大限制；TEXT则不需要。如果你把一个超过列类型最大长度的值赋给一个BLOB或TEXT列，值被截断以适合它。

- 一个BLOB是一个能保存可变数量的数据的二进制的大对象。4个BLOB类型TINYBLOB、BLOB、MEDIUMBLOB和LONGBLOB仅仅在他们能保存值的最大长度方面有所不同。

- BLOB 可以储存图片,TEXT不行，TEXT只能储存纯文本文件。4个TEXT类型TINYTEXT、TEXT、MEDIUMTEXT和LONGTEXT对应于4个BLOB类型，并且有同样的最大长度和存储需求。在BLOB和TEXT类型之间的唯一差别是对BLOB值的排序和比较以大小写敏感方式执行，而对TEXT值是大小写不敏感的。换句话说，一个TEXT是一个大小写不敏感的BLOB。

##### CHAR, VARCHAR和TEXT的区别
* * *
- 长度的区别，CHAR范围是0～255，VARCHAR最长是64k，但是注意这里的64k是整个row的长度，要考虑到其它的column，还有如果存在not null的时候也会占用一位，对不同的字符集，有效长度还不一样，比如utf8的，最多21845，还要除去别的column，但是VARCHAR在一般情况下存储都够用了。如果遇到了大文本，考虑使用TEXT，最大能到4G。

- 效率来说基本是CHAR>VARCHAR>TEXT，但是如果使用的是Innodb引擎的话，推荐使用VARCHAR代替CHAR;

- CHAR和VARCHAR可以有默认值，TEXT不能指定默认值;

ENUM类型

　　枚举类型，它的值范围需要在创建表时通过枚举方式显示指定，对1~255个成员的枚举需要1个字节存储，对于255~65535个成员，需要2个字节存储，最多允许65535个成员。

```shell
dev@testdb>insert into info values('M'), ('l'), ('f'), (null);
ERROR 1265 (01000): Data truncated for column 'gander' at row 2
dev@testdb>insert into info values('M'), ('f'), (null);
Query OK, 3 rows affected (0.01 sec)
Records: 3  Duplicates: 0  Warnings: 0

dev@testdb>select * from info;
+--------+
| gander |
+--------+
| M      |
| F      |
| NULL   |
+--------+
3 rows in set (0.00 sec)
```

- ENUM类型忽略大小写;
- 当插入值不在ENUM类型中则报错, 整个插入语句都执行失败;

SET类型

SET和enum非常相似，里面可以包含0~64个成员，根据成员的不用，存储上也有不同。
1~8成员的集合，占1个字节
9~16成员的集合，占2个字节
17~24成员的集合，占3个字节
25~32成员的集合，占4个字节
33~64成员的集合，占8个字节
set类型一次可以选取多个成员，而ENUM则只能选一个，就相当于ENUM是单选，而set是复选。

```shell
dev@testdb>create table ts(col set('a','b','c','d','e'));
Query OK, 0 rows affected (0.02 sec)

dev@testdb>desc ts;
+-------+--------------------------+------+-----+---------+-------+
| Field | Type                     | Null | Key | Default | Extra |
+-------+--------------------------+------+-----+---------+-------+
| col   | set('a','b','c','d','e') | YES  |     | NULL    |       |
+-------+--------------------------+------+-----+---------+-------+
1 row in set (0.01 sec)

dev@testdb>insert into ts values('a,b'), ('a,d,a'), ('a,b'),('a');
Query OK, 4 rows affected (0.00 sec)
Records: 4  Duplicates: 0  Warnings: 0

dev@testdb>select * from ts;
+------+
| col  |
+------+
| a,b  |
| a,d  |
| a,b  |
| a    |
+------+
4 rows in set (0.00 sec)

dev@testdb>
```
可以看出set类型可以从允许值的集合中选择任意1个或多个元素进行组合，所以对于输入的值只要是在允许值的组合范围内，都可以正确的写入到set类型中，对于超过的允许值范围如（'a,d,f'）是不能写入到上面的例子中的，而对于（‘a,d,a’）这样包含的重复成员将只取一次，写入后的结果为'a,d'。

##### 选择数据库
```shell
dev@testdb>use testdb;
Database changed
dev@testdb>select database();
+------------+
| database() |
+------------+
| testdb     |
+------------+
1 row in set (0.00 sec)
dev@testdb>
```

##### 建表
语法
```shell
create table if not exists table_name (
column_name data_type,
...
)
```

建表t1,

```shell
dev@testdb>create table if not exists t1(
    -> username VARCHAR(20),
    -> age TINYINT UNSIGNED,
    -> salary FLOAT(8,2) UNSIGNED
    -> );
Query OK, 0 rows affected (0.02 sec)

dev@testdb>desc t1;
+----------+---------------------+------+-----+---------+-------+
| Field    | Type                | Null | Key | Default | Extra |
+----------+---------------------+------+-----+---------+-------+
| username | varchar(20)         | YES  |     | NULL    |       |
| age      | tinyint(3) unsigned | YES  |     | NULL    |       |
| salary   | float(8,2) unsigned | YES  |     | NULL    |       |
+----------+---------------------+------+-----+---------+-------+
3 rows in set (0.00 sec)
```
##### 查表

```shell
# 查询当前数据库中的所有表
dev@testdb>show tables;
+------------------+
| Tables_in_testdb |
+------------------+
| t1               |
+------------------+
1 row in set (0.00 sec)

# 查询指定数据库中所有表
dev@testdb>show tables from mysql;
+---------------------------+
| Tables_in_mysql           |
+---------------------------+
| columns_priv              |
| .....                     |
| user                      |
+---------------------------+
31 rows in set (0.01 sec)
```

##### 查看表结构

```shell
dev@testdb>show columns from t1;
+----------+---------------------+------+-----+---------+-------+
| Field    | Type                | Null | Key | Default | Extra |
+----------+---------------------+------+-----+---------+-------+
| username | varchar(20)         | YES  |     | NULL    |       |
| age      | tinyint(3) unsigned | YES  |     | NULL    |       |
| salary   | float(8,2) unsigned | YES  |     | NULL    |       |
+----------+---------------------+------+-----+---------+-------+
3 rows in set (0.00 sec)

dev@testdb>desc t1;
+----------+---------------------+------+-----+---------+-------+
| Field    | Type                | Null | Key | Default | Extra |
+----------+---------------------+------+-----+---------+-------+
| username | varchar(20)         | YES  |     | NULL    |       |
| age      | tinyint(3) unsigned | YES  |     | NULL    |       |
| salary   | float(8,2) unsigned | YES  |     | NULL    |       |
+----------+---------------------+------+-----+---------+-------+
3 rows in set (0.00 sec)
```

##### 插入/查找数据
insert [into] tbl_name [(col_name,...)] values(val,...)
如果省略到[(col_name,...)] 则必须为所有字段赋值
```shell
dev@testdb>insert t1 values('Tom', 25, 7888.25);
Query OK, 1 row affected (0.01 sec)

#当省略[(col_name, ...)]后,如果values中没有全部写入列值则会报错,
dev@testdb>insert t1 values('Mike', '26');
ERROR 1136 (21S01): Column count doesn't match value count at row 1

dev@testdb>insert t1 (username, salary) values('John', 5600.01);
Query OK, 1 row affected (0.01 sec)

dev@testdb>select * from t1;
+----------+------+---------+
| username | age  | salary  |
+----------+------+---------+
| Tom      |   25 | 7888.25 |
| John     | NULL | 5600.01 |
+----------+------+---------+
2 rows in set (0.01 sec)
```

##### 空值与非空值
- `NULL` 字段值可以为空, `NOT NULL` 字段值禁止为空; 

```shell
dev@testdb>create table if not exists t2(
    -> username VARCHAR(20) NOT NULL,
    -> age TINYINT UNSIGNED NULL
    -> );
Query OK, 0 rows affected (0.01 sec)

dev@testdb>show columns from t2;
+----------+---------------------+------+-----+---------+-------+
| Field    | Type                | Null | Key | Default | Extra |
+----------+---------------------+------+-----+---------+-------+
| username | varchar(20)         | NO   |     | NULL    |       |
| age      | tinyint(3) unsigned | YES  |     | NULL    |       |
+----------+---------------------+------+-----+---------+-------+
2 rows in set (0.01 sec)

dev@testdb>insert t2 values('Tom', NULL);
Query OK, 1 row affected (0.01 sec)

dev@testdb>insert t2 values(NULL, 26); 
ERROR 1048 (23000): Column 'username' cannot be null

# 注意NULL和空字符是两回事;
dev@testdb>insert t2 values('', 26);
Query OK, 1 row affected (0.00 sec)

dev@testdb>select * from t2;
+----------+------+
| username | age  |
+----------+------+
| Tom      | NULL |
|          |   26 |
+----------+------+
2 rows in set (0.00 sec)
```
- `NULL`和''空字符是两回事，不是一个值;

##### 自动编号
可以通过自动编号来保证这个值在当前表中是唯一不重复;

```shell
dev@testdb>create table if not exists t3(
    -> id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    -> username VARCHAR(20) NOT NULL
    -> );
Query OK, 0 rows affected (0.02 sec)

dev@testdb>desc t3;
+----------+----------------------+------+-----+---------+----------------+
| Field    | Type                 | Null | Key | Default | Extra          |
+----------+----------------------+------+-----+---------+----------------+
| id       | smallint(5) unsigned | NO   | PRI | NULL    | auto_increment |
| username | varchar(20)          | NO   |     | NULL    |                |
+----------+----------------------+------+-----+---------+----------------+
2 rows in set (0.00 sec)

dev@testdb>insert t3 values('Mike'), ('Tom');
ERROR 1136 (21S01): Column count doesn't match value count at row 1

dev@testdb>insert t3(username) values('Mike'), ('Tom');
Query OK, 2 rows affected (0.00 sec)
Records: 2  Duplicates: 0  Warnings: 0

dev@testdb>select * from t3;
+----+----------+
| id | username |
+----+----------+
|  1 | Mike     |
|  2 | Tom      |
+----+----------+
2 rows in set (0.00 sec)
```

- 主键允许用户赋值，但是不允许存在两个相同的值;
- AUTO_INCREMENT 必须与PRIMARY KEY一起使用; 
- PRIMARY KEY 也可以简写为KEY;

##### 总结
- 本文首先搭建mysql容器环境;
- 本文对mysql数据的基本数据类型整型/浮点型/日期类型及字符串等常用类型进行了归类总结并对字符类型中各个类型的差异与区别进行了简要分析;
- 对数据表的基本操作进行了示例分析说明; 




