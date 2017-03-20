---
title: "mysql 数据库表及数据导入导出方法总结" 
date: 2017-02-22 10:50:36
categories: [DevOps]
tags: [mysql]

description:
---

## 前言

由于公司的MySQL是搭建在服务器上，为了避免对服务器进行直接改动，想远程导出和导入MySQL的数据库表结构及数据进行操作, 刚好Mysql本身提供了命令行导出工具`Mysqldump`和`Mysql Source`导入命令进行SQL数据导入导出工作，通过Mysql命令行导出工具Mysqldump命令能够将Mysql数据导出为文本格式(txt)的SQL文件，通过Mysql Source命令能够将SQL文件导入Mysql数据库中，下面通过Mysql导入导出SQL实例详解Mysqldump和Source命令的用法

<!--more-->

## 数据库表及数据导出

需求说明是要希望导出整个数据库结构脚本，而MySQL提供的Mysqldump命令刚好可达到此目的而且还可以将数据库中的数据也一并导出，

** mysqldump导出语法以及实践 **

```bash
mysqldump -h{hostname} [-P{port}] -u{username} -p{password} [--default-character-set=charset] database [tablename] > {you file path}
# 注:-h和[hostname]之间并没有空格相连, 后同之, []扩起来的为可选项, 可不填
```

- hostname表示主机名, 本地则填localhost, 远程则填写你的远程IP, 如192.168.0.3;
- username是你的MySQL登录帐号, password则是登录密码;
- default-character-set则是你的字符集编码, 如gb2312、gbk和utf8(没有横杠哦);
- dbname是你的数据库名称, tablename是你的表名, 假如你不填写tablename的话则默认导出所有的表。

```bash 
mysqldump -h192.168.0.3 -P3307 -uroot -p123456 --default-character-set=utf8  crm_adapter > ./crm_adapter_db.sql
```
通过上面的导出语句, 将会在当前目录下面创建一个crm_adapter_db.sql脚本文件, 这个脚本文件是可运行的, 它包含了crm_adapter数据库中所有数据表的建表细节以及其所有的数据。这就是导出命令的特点，它不但会导出数据，还会导出表或者数据库的结构信息。另外如果不带"> {you file path}"这一部分路径信息，mysqldump导出命令或把内容打印在terminal命令界面上。

## 数据库表及数据导入

数据库表及数据导入可用mysqldump 和source 两种方法来操作， 

** 通过mysqldump 工具导入** 
mysqldump -h{hostname} [-P{port}] -u{username} -p{password} [--default-character-set=charset] database [tablename] < {you file path}

```bash
mysqldump -h192.168.0.3 -P3308 -uroot -p123456  databasename < ./crm_adapter_db.sql
```

** 通过source 命令导入 **

`source`命令导入不同于mysqldump, 它是一个SQL命令, 必须登录进入MySQL在命令行那里才可以运行, 而mysqldump实则是一个管理工具，无须登入MySQ在命令行那里运行，只须在命令行下运行即可。先登入MySQL:

```bash 
mysql -h{hostname} [-p{port}] -u{username} -p{password}
```

举例, 我们登入一个远程MySQL可以用下面的命令,

```bash 
mysql -h192.168.0.3 -unikey -p123456
```

登入之后，进入我们要作用的数据库,

```bash 
mysql > use my_crm_adapter;
```

然后我们可以使用source命令来运行前面导出的sql脚本实现数据的导入,

```bash
mysql > source ./crm_adapter_db.sql;
```

** mysqldump vs source **
mysqldump虽然好用, 但它实际上也是运用先登录在运行脚本的策略, 只是其中的细节我们无需关心, 但是, 因为其中有很多远程连接细节, 我们有可能遭遇中文乱码问题。
<center>![mysqldump 乱码](imgs/mysqldump_error.png)</center>

关于为何在使用mysqldump做导入时会出现中文乱码问题, 我们先用mysql命令登入, 然后输入下面的命令:
```bash 
mysql > show variables like 'character%';
```

<center>![mysqldump character error](imgs/mysqldump_ret.png)</center>

是否注意到红圈部分的编码是latin1? latin1是MySQL的默认字符集, 可能由于某种原因你没有指定默认编码, 它就会默认为latin1了, 这就是你中文乱码出现的原因。

** <font color=red> 所以建议优先使用source 命令来导入数据 </font> ** 

## mysqldump使用总结

- 导出所有库 
	系统命令行
	```bash
	 mysqldump -uusername -ppassword --all-databases > all.sql
	```

- 导入所有库
	mysql命令行
	```bash
	mysql>source all.sql;
	```

- 导出某些库
	系统命令行
	```bash
	mysqldump -uusername -ppassword --databases db1 db2 > db1db2.sql
	```

- 导入某些库
	mysql命令行
	```bash
	mysql>source db1db2.sql;
	```

- 导入某个库
	系统命令行
	```bash
	mysql -uusername -ppassword db1 < db1.sql;
	```
	或mysql命令行
	```bash
	mysql>source db1.sql;
	```

- 导出某些数据表
	系统命令行
	```bash
	mysqldump -uusername -ppassword db1 table1 table2 > tb1tb2.sql
	```

- 导入某些数据表
	系统命令行
	```bash
	mysql -uusername -ppassword db1 < tb1tb2.sql
	```
	或mysql命令行
	```bash
	mysql>user db1;
	mysql>source tb1tb2.sql;
	```

- mysqldump字符集设置
	mysqldump -uusername -ppassword --default-character-set=gb2312 db1 table1 > tb1.sql
	mysqldump客户端可用来转储数据库或搜集数据库进行备份或将数据转移到另一个sql服务器(不一定是一个mysql服务器)。转储包含创建表和/或装载表的sql语句。
	如果在服务器上进行备份，并且表均为myisam表，应考虑使用mysqlhotcopy，因为可以更快地进行备份和恢复。
	有3种方式来调用mysqldump:
	系统命令行
	```bash
	mysqldump [options] db_name [tables]
# 或
	mysqldump [options] ---database db1 [db2 db3...]
# 或
	mysqldump [options] --all--database
	```

	如果没有指定任何表或使用了---database或--all--database选项，则转储整个数据库。
	要想获得你的版本的mysqldump支持的选项，执行mysqldump ---help。
	如果运行mysqldump没有--quick或--opt选项，mysqldump在转储结果前将整个结果集装入内存。如果转储大数据库可能会出现问题。该选项默认启用，但可以用--skip-opt禁用。
	如果使用最新版本的mysqldump程序生成一个转储重装到很旧版本的mysql服务器中，不应使用--opt或-e选项。
	mysqldump支持下面的选项:
 	`--help` 或`-?`
 	显示帮助消息并退出。
 	`--add-drop--database`
 	在每个create database语句前添加drop database语句。
 	`--add-drop-tables`
 	在每个create table语句前添加drop table语句。
 	`--add-locking`
 	用lock tables和unlock tables语句引用每个表转储。重载转储文件时插入得更快。
 	`--all--database` 或 `-a`
	转储所有数据库中的所有表。与使用---database选项相同，在命令行中命名所有数据库。
 	`--allow-keywords`
 	允许创建关键字列名。应在每个列名前面加上表名前缀。
 	`--comments[={0|1}]`
 	如果设置为0, 禁止转储文件中的其它信息, 例如程序版本, 服务器版本和主机。`--skip—comments`与`--comments=0`的结果相同。 默认值为1，即包括额外信息。
 	`--compact`
 	产生少量输出。该选项禁用注释并启用`--skip-add-drop-tables`、`--no-set-names`、`--skip-disable-keys`和`--skip-add-locking`选项。
 	`--compatible=name`
 	产生与其它数据库系统或旧的mysql服务器更兼容的输出。值可以为ansi、mysql323、mysql40、postgresql、oracle、mssql、db2、maxdb、no_key_options、no_tables_options或者no_field_options。要使用几个值，用逗号将它们隔开。这些值与设置服务器sql模式的相应选项有相同的含义。该选项不能保证同其它服务器之间的兼容性。它只启用那些目前能够使转储输出更兼容的sql模式值。例如，--compatible=oracle 不映射oracle类型或使用oracle注释语法的数据类型。
 	`--complete-insert` 或 `-c`
 	使用包括列名的完整的insert语句。
 	`--compress` 或`-c`
 	压缩在客户端和服务器之间发送的所有信息（如果二者均支持压缩）。
 	`--create-option`
 	在create table语句中包括所有mysql表选项。
    `--database` 或 `-b`
	转储几个数据库。通常情况, mysqldump将命令行中的第1个名字参量看作数据库名，后面的名看作表名。使用该选项，它将所有名字参量看作数据库名。create database if not exists db_name和use db_name语句包含在每个新数据库前的输出中。
 	`--debug[=debug_options]` 或`-# [debug_options]`
 	写调试日志。debug_options字符串通常为'd:t:o,file_name'。
 	`--default-character-set=charset`
 	使用charsetas默认字符集。如果没有指定，mysqldump使用utf8。
 	`--delayed-insert`
 	使用insert delayed语句插入行。
 	`--delete-master-logs`
 	在主复制服务器上，完成转储操作后删除二进制日志。该选项自动启用`--master-data`。
 	`--disable-keys` 或 `-k`
 	对于每个表，用/*!40000 alter table tbl_name disable keys */;和/*!40000 alter table tbl_name enable keys */;语句引用insert语句。这样可以更快地装载转储文件，因为在插入所有行后创建索引。该选项只适合myisam表。
 	`--extended-insert` 或 `-e`
 	使用包括几个values列表的多行insert语法。这样使转储文件更小，重载文件时可以加速插入。
 	`--fields-terminated-by=...，--fields-enclosed-by=...，--fields-optionally-enclosed-by=...，--fields-escaped-by=...，--行-terminated-by=...`
 	这些选项结合-t选项使用，与load data infile的相应子句有相同的含义。
 	`--first-slave` 或 `-x`
 	不赞成使用，现在重新命名为--lock-all-tables。
 	`--flush-logs` 或 `-f`
 	开始转储前刷新mysql服务器日志文件。该选项要求reload权限。请注意如果结合`--all--database`(或-a)选项使用该选项，根据每个转储的数据库刷新日志。例外情况是当使用`--lock-all-tables`或`--master-data`的时候:在这种情况下, 日志只刷新一次, 在所有表被锁定后刷新。如果你想要同时转储和刷新日志，应使用`--flush-logs`连同`--lock-all-tables`或`--master-data`。
 	`--force`或`-f`
 	在表转储过程中, 即使出现sql错误也继续。
 	`--host=host_name` 或 `-h host_name`
 	从给定主机的mysql服务器转储数据。默认主机是localhost。
 	`--hex-blob`
 	使用十六进制符号转储二进制字符串列(例如，'abc' 变为0x616263)。影响到的列有binary、varbinary、blob。
 	`--lock-all-tables` 或 `-x`
 	所有数据库中的所有表加锁。在整体转储过程中通过全局读锁定来实现。该选项自动关闭`--single-transaction`和`--lock-tables`。
 	`--lock-tables` 或`-l`
 	开始转储前锁定所有表。用read local锁定表以允许并行插入myisam表。对于事务表例如innodb和bdb，`--single-transaction`是一个更好的选项，因为它不根本需要锁定表。请注意当转储多个数据库时，--lock-tables分别为每个数据库锁定表。因此，该选项不能保证转储文件中的表在数据库之间的逻辑一致性。不同数据库表的转储状态可以完全不同。
 	`--master-data[=value]`
 	该选项将二进制日志的位置和文件名写入到输出中。该选项要求有reload权限，并且必须启用二进制日志。如果该选项值等于1，位置和文件名被写入change master语句形式的转储输出，如果你使用该sql转储主服务器以设置从服务器，从服务器从主服务器二进制日志的正确位置开始。如果选项值等于2，change master语句被写成sql注释。如果value被省略，这是默认动作。
 	`--master-data`选项启用`--lock-all-tables`，除非还指定`--single-transaction`(在这种情况下，只在刚开始转储时短时间获得全局读锁定。又见`--single-transaction`。在任何一种情况下，日志相关动作发生在转储时。该选项自动关闭`--lock-tables`。
 	`--no-create-db` 或 `-n`
 	该选项禁用create database /*!32312 if not exists*/ db_name语句，如果给出---database或--all--database选项，则包含到输出中。
 	`--no-create-info` 或 `-t`
 	不写重新创建每个转储表的create table语句。
 	`--no-data` 或 `-d`
 	不写表的任何行信息。如果你只想转储表的结构这很有用。
 	`--opt`
 	该选项是速记；等同于指定 --add-drop-tables--add-locking --create-option --disable-keys--extended-insert --lock-tables --quick --set-charset。它可以给出很快的转储操作并产生一个可以很快装入mysql服务器的转储文件。该选项默认开启，但可以用--skip-opt禁用。要想只禁用确信用-opt启用的选项，使用--skip形式；例如，--skip-add-drop-tables或--skip-quick。
 	--password[=password]，-p[password]
 	连接服务器时使用的密码。如果你使用短选项形式(-p)，不能在选项和密码之间有一个空格。如果在命令行中，忽略了--password或-p选项后面的 密码值，将提示你输入一个。
 	--port=port_num，-p port_num
 	用于连接的tcp/ip端口号。
 	--protocol={tcp | socket | pipe | memory}
 	使用的连接协议。
 	--quick，-q
 	该选项用于转储大的表。它强制mysqldump从服务器一次一行地检索表中的行而不是检索所有行并在输出前将它缓存到内存中。
 	--quote-names，-q
 	用"\`"字符引用数据库、表和列名。如果服务器sql模式包括ansi_quotes选项，用"字符引用名。默认启用该选项。可以用--skip-quote-names禁用，但该选项应跟在其它选项后面，例如可以启用--quote-names的--compatible。
 	--result-file=file，-r file
	--socket=path，-s path
 	当连接localhost(为默认主机)时使用的套接字文件。
 	--skip--comments
	参见---comments选项的描述。
	--tab=path，-t path
	产生tab分割的数据文件。对于每个转储的表，mysqldump创建一个包含创建表的create table语句的tbl_name.sql文件，和一个包含其数据的tbl_name.txt文件。选项值为写入文件的目录。
	默认情况，.txt数据文件的格式是在列值和每行后面的新行之间使用tab字符。可以使用--fields-xxx和--行--xxx选项明显指定格式。
	注释：该选项只适用于mysqldump与mysqld服务器在同一台机器上运行时。你必须具有file权限，并且服务器必须有在你指定的目录中有写文件的许可。
	--tables
	覆盖---database或-b选项。选项后面的所有参量被看作表名。
	--triggers
	为每个转储的表转储触发器。该选项默认启用；用--skip-triggers禁用它。
	--tz-utc
	在转储文件中加入set time_zone='+00:00'以便timestamp列可以在具有不同时区的服务器之间转储和重载。(不使用该选项，timestamp列在具有本地时区的源服务器和目的服务器之间转储和重载）。--tz-utc也可以保护由于夏令时带来的更改。--tz-utc默认启用。要想禁用它，使用--skip-tz-utc。该选项在mysql 5.1.2中加入。
 	--where='where-condition', -w 'where-condition'
 	只转储给定的where条件选择的记录。请注意如果条件包含命令解释符专用空格或字符，一定要将条件引用起来。
 	例如:
 	`"--where=user='jimf'"
 	"-wuserid>1"
 	"-wuserid<1"`
 	--xml，-x
 	将转储输出写成xml。
 	还可以使用--var_name=value选项设置下面的变量:
 	max_allowed_packet
 	客户端/服务器之间通信的缓存区的最大大小。最大为1gb。
 	net_buffer_length
 	客户端/服务器之间通信的缓存区的初始大小。当创建多行插入语句时(如同使用选项--extended-insert或--opt)，mysqldump创建长度达net_buffer_length的行。如果增加该变量，还应确保在mysql服务器中的net_buffer_length变量至少这么大。
 	还可以使用--set-variable=var_name=value或-o var_name=value语法设置变量。然而，现在不赞成使用该语法。
 	mysqldump最常用于备份一个整个的数据库:
	mysqldump --opt db_name > backup-file.sql
	可以这样将转储文件读回到服务器:
	mysql db_name < backup-file.sql
 	或:
	mysql -e "source /path-to--backup/backup-file.sql" db_name
 	mysqldump也可用于从一个mysql服务器向另一个服务器复制数据时装载数据库:
	mysqldump --opt db_name | mysql --host=remote_host -c db_name
	可以用一个命令转储几个数据库:
	mysqldump ---database db_name1 [db_name2 ...] > my_databases.sql
	如果想要转储所有数据库，使用--all--database选项:
	mysqldump --all-databases > all_databases.sql
	如果表保存在innodb存储引擎中，mysqldump提供了一种联机备份的途径(参见下面的命令)。该备份只需要在开始转储时对所有表进行全局读锁定(使用flush tables with read lock)。获得锁定后，读取二进制日志的相应内容并将锁释放。因此如果并且只有当发出flush...时正执行一个长的更新语句，mysql服务器才停止直到长语句结束，然后转储则释放锁。因此如果mysql服务器只接收到短("短执行时间")的更新语句，即使有大量的语句，也不会注意到锁期间。
	mysqldump --all-databases --single-transaction > all_databases.sql 
	对于点对点恢复(也称为“前滚”，当你需要恢复旧的备份并重放该备份以后的更改时)，循环二进制日志或至少知道转储对应的二进制日志内容很有用：
	mysqldump --all-databases --master-data=2 > all_databases.sql
	或
	mysqldump --all-databases --flush-logs --master-data=2 > all_databases.sql
	如果表保存在innodb存储引擎中，同时使用--master-data和--single-transaction提供了一个很方便的方式来进行适合点对点恢复的联机备份。
