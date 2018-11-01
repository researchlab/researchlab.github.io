---
title: "mysql专题09 常用函数及自定义函数"
date: 2018-10-02 17:29:37
categories: "mysql专题"
tags: [mysql]
description:
---
Mysql中常用函数根据功能大致可划分为1.字符函数;2.数值运算符及函数;3.比较运算符及函数;4.日期时间函数;5.信息函数;6.聚合函数;7.加密函数等;
<!--more-->

# 字符函数

1. 函数整理

|语法|	用途|
|:---|:---|
|`ASCII(char)`|返回字符的ASCII码值|
|`BIT_LENGTH(str)`|返回字符串的比特长度|
|`CONCAT(s1,s2…,sn)`|将s1,s2…,sn连接成字符串|
|`CONCAT_WS(separator,s1,s2…,sn)`|将s1,s2…,sn连接成字符串，并用separator字符间隔|
|`INSERT(str,pos,lenth,newstr)`|将字符串str从第pos位置开始，lenth个字符长的子串替换为字符串newstr，返回结果|
|`FIND_IN_SET(str,list)`|分析逗号分隔的list列表，如果发现str，返回str在list中的位置|
|`LCASE(str)或LOWER(str)`|返回将字符串str中所有字符改变为小写后的结果|
|`LEFT(str,x)`|返回字符串str中最左边的x个字符|
|`RIGHT(str,x)`|返回字符串str中最右边的x个字符|
|`LENGTH(s)`|返回字符串str中的字符数|
|`LTRIM(str)`|从字符串str中切掉开头的空格|
|`POSITION(substr,str)`|返回子串substr在字符串str中第一次出现的位置|
|`POSITION(substr IN str)`|返回子串substr在字符串str中第一次出现的位置|
|`QUOTE(str)`|用反斜杠转义str中的单引号|
|`REPEAT(str,count)`|返回字符串str重复count次的结果|
|`REVERSE(str)`|返回颠倒字符串str的结果|
|`RTRIM(str)`|去掉字符串str尾部的空格|
|`STRCMP(s1,s2)`|比较字符串s1和s2|
|`TRIM(str)`|去除字符串首部和尾部的所有空格|
|`UCASE(str)或UPPER(str)`|返回将字符串str中所有字符转变为大写后的结果|
|`REPLACE(str,from_str,to_str)`|将str中的from_str替换为to_str|

2. 用法举例

```shell
select CONCAT('11','22','33');//结果-->   112233
select CONCAT_WS(',','11','22','33');//结果--> 11,22,33
SELECT INSERT('abcdef',1,2,'xyz');//结果-->xyzcdef 注:a是1,b是2,从1开始替换2个字符,也就是ab2各字符替换为xyz
SELECT FIND_IN_SET('b','a,b,c,d');    //结果-->2
SELECT FIND_IN_SET('b','a,b,c,d,b');  //结果-->2
SELECT FIND_IN_SET('f','a,b,c,d');    //结果-->0
SELECT LEFT('abcdef',3);//结果->abc
SELECT POSITION('abc' IN 'aababdabcdabc');//7,注:5.7.11为POSITION(substr in str),是IN不是,号
SELECT QUOTE('d''abc');//结果'd\'abc'
SELECT REPEAT('abc',3);//abcabcabc
SELECT REVERSE('abcdef')//fedcba
SELECT STRCMP('abc','edf');//-1
SELECT STRCMP('def','abc');//1
SELECT STRCMP('1','0');//1
SELECT STRCMP('0','1');//-1
SELECT STRCMP('aaa','aaa');//0
SELECT REPLACE('abcxyzdefxyz','xyz','mnt');//abcmntdefmnt
SELECT TRIM(LEADING '?' FROM '??MYSQL???'); //MYSQL??? 
SELECT TRIM(TRAILING '?' FROM '??MYSQL???'); //??MYSQL
SELECT TRIM(BOTH '?' FROM '??MYSQL???'); //MYSQL 
SELECT SUBSTRING('MYSQL',1,2); //MY 下标是从1开始的;
SELECT SUBSTRING('MYSQL', 3); //SQL  从3开始取 一直取完整个字符串;
```
- 在MySQL中百分号(%)中代表匹配任意字符串;下划线(_)代表匹配任意一个字符;
- SELECT * FROM tb where name LIKE '%1%%' ESCAPE '1'; 表示1后的%不需要转义了, 而1仅起标识作用; 上述标识返回包含%的字符串;

# 格式化函数

1. 函数整理

|语法 |用途|
|:---|:---|
|`DATE_FORMAT(date,fmt)	`|依照字符串fmt格式化日期date值|
|`FORMAT(x,y)	`|把x格式化为以逗号隔开的数字序列，y是结果的小数位数|
|`INET_ATON(ip)	`|返回IP地址的数字表示|
|`INET_NTOA(num)	`|返回数字所代表的IP地址|
|`TIME_FORMAT(time,fmt)	`|依照字符串fmt格式化时间time值|

# 数值运算符函数

1. 函数整理

|语法|	用途|
|:---|:---|
|`ABS(x)	`|返回x的绝对值|
|`BIN(x)	`|返回x的二进制（OCT返回八进制，HEX返回十六进制）|
|`CEILING(x)	`|返回大于x的最小整数值|
|`EXP(x)	`|返回值e（自然对数的底）的x次方|
|`FLOOR(x)	`|返回小于x的最大整数值|
|`GREATEST(x1,x2,…,xn)	`|返回集合中最大的值|
|`LEAST(x1,x2,…,xn)	`|返回集合中最小的值|
|`LN(x)	`|返回x的自然对数|
|`LOG(x,y)	`|返回x的以y为底的对数|
|`MOD(x,y)	`|返回x/y的模（余数）|
|`PI()	`|返回pi的值（圆周率）|
|`RAND()	`|返回０到１内的随机值,可以通过提供一个参数(种子)使RAND()随机数生成器生成一个指定的值。|
|`ROUND(x,y)	`|返回参数x的四舍五入的有y位小数的值|
|`SIGN(x)	`|返回代表数字x的符号的值|
|`SQRT(x)	`|返回一个数的平方根|
|`TRUNCATE(x,y)	`|返回数字x截短为y位小数的结果|
|`CEIL()`| 进一取整|

2. 用法示例

```shell
SELECT CEIL(3.01); // 4
SELECT FLOOR(3.99); //3
SELECT 3 DIV 4; // 0
SELECT 5 % 3; // 2;
SELECT 5 MOD 3; //2;
SELECT POWER(2,3); //8
SELECT ROUND(3.652, 2); //3.65
SELECT ROUND(3.652, 1); /3.7 四舍五入
SELECT TRUNCATE(125.80,0); // 125
SELECT TRUNCATE(125.89,-1); //120
```

# 比较运算符函数

1. 函数整理

|语法|说明|
|:---|:---|
|`IS [NOT] NULL`| 是否为空|

2. 使用举例

```shell
SELECT NULL IS NULL; //1
SELECT '' IS NULL; //0
SELECT 0 IS NULL; //0
```

# 日期时间函数

1. 函数整理

|语法|	用途|
|:---|:---|
|`CURDATE()或CURRENT_DATE()	`|返回当前的日期|
|`CURTIME()或CURRENT_TIME()	`|返回当前的时间|
|`DATE_ADD(date,INTERVAL int keyword)	`|返回日期date加上间隔时间int的结果(int必须按照关键字进行格式化),如：SELECTDATE_ADD(CURRENT_DATE,INTERVAL 6 MONTH);|
|`DATE_FORMAT(date,fmt)	`|依照指定的fmt格式格式化日期date值|
|`DATE_SUB(date,INTERVAL exprtype)	`|返回日期date加上间隔时间int的结果(int必须按照关键字进行格式化),如：SELECTDATE_SUB(CURRENT_DATE,INTERVAL 6 MONTH);|
|`DAYOFWEEK(date)	`|返回date所代表的一星期中的第几天(1~7)|
|`DAYOFMONTH(date)	`|返回date是一个月的第几天(1~31)|
|`DAYOFYEAR(date)	`|返回date是一年的第几天(1~366)|
|`DAYNAME(date)	`|返回date的星期名，如：SELECT DAYNAME(CURRENT_DATE);|
|`FROM_UNIXTIME(ts,fmt)	`|根据指定的fmt格式，格式化UNIX时间戳ts|
|`HOUR(time)	`|返回time的小时值(0~23)|
|`MINUTE(time)	`|返回time的分钟值(0~59)|
|`MONTH(date)	`|返回date的月份值(1~12)|
|`MONTHNAME(date)	`|返回date的月份名，如：SELECT***|
|`NOW()	`|返回当前的日期和时间|
|`QUARTER(date)	`|返回date在一年中的季度(1~4)，如SELECT***|
|`WEEK(date)	`|返回日期date为一年中第几周(0~53)|
|`YEAR(date)	`|返回日期date的年份(1000~9999)|

2. 格式化的类型格式

|格式|  描述|
|:---|:---|
|`%a`| 缩写星期名|
|`%b`| 缩写月名|
|`%c`| 月，数值|
|`%D`| 带有英文前缀的月中的天|
|`%d`| 月的天，数值(00-31)|
|`%e`| 月的天，数值(0-31)|
|`%f`| 微秒|
|`%H`| 小时 (00-23)|
|`%h`| 小时 (01-12)|
|`%I`| 小时 (01-12)|
|`%i`| 分钟，数值(00-59)|
|`%j`| 年的天 (001-366)|
|`%k`| 小时 (0-23)|
|`%l`| 小时 (1-12)|
|`%M`| 月名|
|`%m`| 月，数值(00-12)|
|`%p`| AM 或 PM|
|`%r`| 时间，12-小时（hh:mm:ss AM 或 PM）|
|`%S`| 秒(00-59)|
|`%s`| 秒(00-59)|
|`%T`| 时间, 24-小时 (hh:mm:ss)|
|`%U`| 周 (00-53) 星期日是一周的第一天|
|`%u`| 周 (00-53) 星期一是一周的第一天|
|`%V`| 周 (01-53) 星期日是一周的第一天，与 %X 使用|
|`%v`| 周 (01-53) 星期一是一周的第一天，与 %x 使用|
|`%W`| 星期名|
|`%w`| 周的天 （0=星期日, 6=星期六）|
|`%X`| 年，其中的星期日是周的第一天，4 位，与 %V 使用|
|`%x`| 年，其中的星期一是周的第一天，4 位，与 %v 使用|
|`%Y`| 年，4 位|
|`%y`| 年，2 位|

3. 单位整理
DATE_SUB()和DATE_ADD()对应的keyword参数
```shell
MICROSECOND
SECOND
MINUTE
HOUR
DAY
WEEK
MONTH
QUARTER
YEAR
SECOND_MICROSECOND
MINUTE_MICROSECOND
MINUTE_SECOND
HOUR_MICROSECOND
HOUR_SECOND
HOUR_MINUTE
DAY_MICROSECOND
DAY_SECOND
DAY_MINUTE
DAY_HOUR
YEAR_MONTH
```

4. 使用举例
```shell
SELECT DATE_FORMAT(FROM_DAYS(TO_DAYS(NOW())-TO_DAYS(birthday)),'%Y')+0 AS age FROM employee;

#这样，如果Brithday是未来的年月日的话，计算结果为0。

#下面的SQL语句计算员工的绝对年龄，即当Birthday是未来的日期时，将得到负值。

SELECT DATE_FORMAT(NOW(), '%Y') - DATE_FORMAT(birthday, '%Y') -(DATE_FORMAT(NOW(), '00-%m-%d') <DATE_FORMAT(birthday, '00-%m-%d')) AS age from employee
```

# 系统信息函数

1. 函数整理

|语法|说明|
|:---|:---|
|`DATABASE()	`|返回当前数据库名|
|`BENCHMARK(count,expr)	`|将表达式expr重复运行count次|
|`CONNECTION_ID()	`|返回当前客户的连接ID|
|`FOUND_ROWS()	`|返回最后一个SELECT查询进行检索的总行数|
|`USER()或SYSTEM_USER()	`|返回当前登陆用户名|
|`VERSION()	`|返回MySQL服务器的版本|

2. 用法举例

```shell
SELECT DATABASE(),VERSION(),USER();
```

# 聚合函数

聚合函数,常用于GROUP BY从句的SELECT查询中

1. 函数整理

|语法|	用途|
|:---|:---|
|`AVG(col)	`|返回指定列的平均值|
|`COUNT(col)	`|返回指定列中非NULL值的个数|
|`MIN(col)	`|返回指定列的最小值|
|`MAX(col)	`|返回指定列的最大值|
|`SUM(col)	`|返回指定列的所有值之和|
|`GROUP_CONCAT(col)	`|返回由属于一组的列值连接组合而成的结果|

2. 用法举例

```shell
dev@testdb>select group_id, group_concat(name) from tb16 group by group_id;
+----------+--------------------+
| group_id | group_concat(name) |
+----------+--------------------+
| A        | 小刚               |
| B        | 小明,小花          |
| C        | 小红               |
+----------+--------------------+
3 rows in set (0.00 sec)
```
# 加密函数

|语法|	用途|
|:---|:---|
|`AES_ENCRYPT(str,key)	`|返回用密钥key对字符串str利用高级加密标准算法加密后的结果，调用AES_ENCRYPT的结果是一个二进制字符串，以BLOB类型存储|
|`AES_DECRYPT(str,key)	`|返回用密钥key对字符串str利用高级加密标准算法解密后的结果|
|`DECODE(str,key)	`|使用key作为密钥解密加密字符串str|
|`ENCRYPT(str,salt)	`|使用UNIXcrypt()函数，用关键词salt(一个可以惟一确定口令的字符串，就像钥匙一样)加密字符串str|
|`ENCODE(str,key)	`|使用key作为密钥加密字符串str，调用ENCODE()的结果是一个二进制字符串，它以BLOB类型存储|
|`MD5()	`|计算字符串str的MD5校验和|
|`PASSWORD(str)	`|返回字符串str的加密版本，这个加密过程是不可逆转的，和UNIX密码加密过程使用不同的算法。|
|`SHA()	`|计算字符串str的安全散列算法(SHA)校验和|

# 自定义函数

Mysql中自定义函数(user-defined function, UDF) 是一种对Mysql扩展的路径, 其用法与内置函数相同;

一个自定义函数必会有参数及返回值;
函数可以返回任意类型的值, 同样也可以接收这些类型的参数;

创建自定义函数
```shell
CREATE FUNCTION function_name 
RETURNS 
{STRING | INTEGER | REAL |DECIMAL}
routine_body
```

函数体可以由如下语句构成, 

1. 函数体由合法的SQL语句构成;
2. 函数体可以是简单的SELECT或INSERT语句;
3. 函数体如果为复合结构则使用BEGIN..END语句;
4. 复合结构可以包含声明, 循环, 控制结构;

创建不带参数的自定义函数

> dev@testdb>SET NAMES utf8;  # 修改编码 临时生效

```shell
#登录root
mysql> set global log_bin_trust_function_creators =1;
Query OK, 0 rows affected (0.00 sec)

#切换普通账号 创建f2()
dev@testdb>CREATE FUNCTION f2() RETURNS VARCHAR(30) DETERMINISTIC RETURN date_format(NOW(), '%Y年%m月%d日 %H点:%i分:%s秒');
Query OK, 0 rows affected (0.05 sec)

dev@testdb>select f2() as now ;
+-------------------------------------+
| now                                 |
+-------------------------------------+
| 2018年11月01日 11点:49分:23秒       |
+-------------------------------------+
1 row in set (0.01 sec)
```

创建带参数的函数

```shell
dev@testdb>DROP FUNCTION f1;
Query OK, 0 rows affected (0.10 sec)

dev@testdb>CREATE FUNCTION f1(num1 SMALLINT UNSIGNED, num2 SMALLINT UNSIGNED)
    -> RETURNS FLOAT(10,2) UNSIGNED
    -> RETURN (num1+num2)/2;
Query OK, 0 rows affected (0.07 sec)

dev@testdb>select f1(1,5) as avg;
+------+
| avg  |
+------+
| 3.00 |
+------+
1 row in set (0.00 sec)
```

创建具有复合结构函数体的自定义函数

```shell
# delimiter 替换分割结束符;
dev@testdb>DELIMITER //
# 当函数体中包含两条以上SQL语句时, 需要用BEGIN...END包含起来
dev@testdb>CREATE FUNCTION adduser(username VARCHAR(20))
    -> RETURNS INT UNSIGNED
    -> BEGIN
    -> INSERT tb17(username) VALUES(username);
    -> RETURN LAST_INSERT_ID();
    -> END
    -> //
Query OK, 0 rows affected (0.11 sec)

dev@testdb>SELECT adduser('Tom');
    -> //
+----------------+
| adduser('Tom') |
+----------------+
|              3 |
+----------------+
1 row in set, 1 warning (0.10 sec)

dev@testdb>DELIMITER ;
dev@testdb>select adduser('Jack');
+-----------------+
| adduser('Jack') |
+-----------------+
|               4 |
+-----------------+
1 row in set (0.08 sec)
```

# 总结
- 本文总结了常用的mysql函数用法，并通过实例进行实践分析学习;
- 进一步了解学习了自定义函数的用法及适用, 通过创建带参和不带参数自定义函数的创建,以及复合函数体自定义函数的实践 进一步加深了对Mysql函数的学习过程; 自定义函数是用户扩展Mysql功能的一种便捷路径;
