---
title: "golang操作mysql使用总结" 
date: 2016-11-11 13:21:16
categories: [golang]
tags: [golang, mysql]
description:
---

Golang 提供了`database/sql`包用于对`SQL数据库`的访问, 作为操作数据库的入口对象`sql.DB`, 主要为我们提供了两个重要的功能:
<!--more-->
-  sql.DB 通过数据库驱动为我们提供管理底层数据库连接的打开和关闭操作.
-  sql.DB 为我们管理数据库连接池

需要注意的是，sql.DB表示操作数据库的抽象访问接口,而非一个数据库连接对象;它可以根据driver打开关闭数据库连接，管理连接池。正在使用的连接被标记为繁忙，用完后回到连接池等待下次使用。所以，如果你没有把连接释放回连接池，会导致过多连接使系统资源耗尽。

## 操作mysql

**1.导入mysql数据库驱动**
```golang
import (
   "database/sql"
   _ "github.com/go-sql-driver/mysql"
)
```
> 通常来说, 不应该直接使用驱动所提供的方法, 而是应该使用 sql.DB, 因此在导入 mysql 驱动时, 这里使用了匿名导入的方式(在包路径前添加 _), 当导入了一个数据库驱动后, 此驱动会自行初始化并注册自己到Golang的database/sql上下文中, 因此我们就可以通过 database/sql 包提供的方法访问数据库了.

**2.连接数据库**
```golang

type DbWorker struct {
    //mysql data source name
    Dsn string 
}

func main() {
    dbw := DbWorker{
        Dsn: "user:password@tcp(127.0.0.1:3306)/test",
    }	
    db, err := sql.Open("mysql",
        dbw.Dsn)
    if err != nil {
        panic(err)
        return
    }
    defer db.Close()
}
```
通过调用sql.Open函数返回一个`sql.DB指针`; sql.Open函数原型如下:
```golang
func Open(driverName, dataSourceName string) (*DB, error)
```
- `driverName`: 使用的驱动名. 这个名字其实就是数据库驱动注册到 database/sql 时所使用的名字.
- `dataSourceName`:  数据库连接信息，这个连接包含了数据库的用户名, 密码, 数据库主机以及需要连接的数据库名等信息.

>1. sql.Open并不会立即建立一个数据库的网络连接, 也不会对数据库链接参数的合法性做检验, 它仅仅是初始化一个sql.DB对象. 当真正进行第一次数据库查询操作时, 此时才会真正建立网络连接; 
>2. sql.DB表示操作数据库的抽象接口的对象，但不是所谓的数据库连接对象，sql.DB对象只有当需要使用时才会创建连接，如果想立即验证连接，需要用Ping()方法; 
>3. sql.Open返回的sql.DB对象是协程并发安全的.
>4. sql.DB的设计就是用来作为长连接使用的。不要频繁Open, Close。比较好的做法是，为每个不同的datastore建一个DB对象，保持这些对象Open。如果需要短连接，那么把DB作为参数传入function，而不要在function中Open, Close。

**3.数据库基本操作**

数据库查询的一般步骤如下:

1. 调用 db.Query 执行 SQL 语句, 此方法会返回一个 Rows 作为查询的结果
2. 通过 rows.Next() 迭代查询数据.
3. 通过 rows.Scan() 读取每一行的值
4. 调用 db.Close() 关闭查询

现有`user`数据库表如下:
```sql
CREATE TABLE `user` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(20) DEFAULT '',
  `age` int(11) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4
```
>> <font color=red>MySQL 5.5 之前， UTF8 编码只支持1-3个字节,从MYSQL5.5开始，可支持4个字节UTF编码utf8mb4，一个字符最多能有4字节，utf8mb4兼容utf8，所以能支持更多的字符集;关于emoji表情的话mysql的utf8是不支持，需要修改设置为utf8mb4，才能支持。</font>

查询数据
```golang
func (dbw *DbWorker) QueryData() {
	dbw.QueryDataPre()
	rows, err := dbw.Db.Query(`SELECT * From user where age >= 20 AND age < 30`)
	defer rows.Close()
	if err != nil {
		fmt.Printf("insert data error: %v\n", err)
		return
	}
	for rows.Next() {
		rows.Scan(&dbw.UserInfo.Id, &dbw.UserInfo.Name, &dbw.UserInfo.Age)
		if err != nil {
			fmt.Printf(err.Error())
			continue
		}
		if !dbw.UserInfo.Name.Valid {
			dbw.UserInfo.Name.String = ""
		}
		if !dbw.UserInfo.Age.Valid {
			dbw.UserInfo.Age.Int64 = 0
		}
		fmt.Println("get data, id: ", dbw.UserInfo.Id, " name: ", dbw.UserInfo.Name.String, " age: ", int(dbw.UserInfo.Age.Int64))
	}

	err = rows.Err()
	if err != nil {
		fmt.Printf(err.Error())
	}
}
```
>1. rows.Scan 参数的顺序很重要, 需要和查询的结果的column对应. 例如 "SELECT * From user where age >=20 AND age < 30" 查询的行的 column 顺序是 "id, name, age" 和插入操作顺序相同, 因此 rows.Scan 也需要按照此顺序 rows.Scan(&id, &name, &age), 不然会造成数据读取的错位.
>2. 因为golang是强类型语言，所以查询数据时先定义数据类型，但是查询数据库中的数据存在三种可能:存在值，存在零值，未赋值NULL 三种状态, 因为可以将待查询的数据类型定义为sql.Nullxxx类型，可以通过判断Valid值来判断查询到的值是否为赋值状态还是未赋值NULL状态.
>3. 每次db.Query操作后, 都建议调用rows.Close(). 因为 db.Query() 会从数据库连接池中获取一个连接, 这个底层连接在结果集(rows)未关闭前会被标记为处于繁忙状态。当遍历读到最后一条记录时，会发生一个内部EOF错误，自动调用rows.Close(),但如果提前退出循环，rows不会关闭，连接不会回到连接池中，连接也不会关闭, 则此连接会一直被占用. 因此通常我们使用 defer rows.Close() 来确保数据库连接可以正确放回到连接池中; 不过阅读源码发现rows.Close()操作是幂等操作，即一个幂等操作的特点是其任意多次执行所产生的影响均与一次执行的影响相同, 所以即便对已关闭的rows再执行close()也没关系.

单行查询
```golang 
var name string
err = db.QueryRow("select name from user where id = ?", 1).Scan(&name)
if err != nil {
    log.Fatal(err)
}
fmt.Println(name)
```
>1. err在Scan后才产生，上述链式写法是对的
>2. 需要注意Scan()中变量和顺序要和前面Query语句中的顺序一致，否则查出的数据会映射不一致.

插入数据
```golang
func (dbw *DbWorker) insertData() {
	ret, err := dbw.Db.Exec(`INSERT INTO user (name, age) VALUES ("xys", 23)`)
	if err != nil {
		fmt.Printf("insert data error: %v\n", err)
		return
	}
	if LastInsertId, err := ret.LastInsertId(); nil == err {
		fmt.Println("LastInsertId:", LastInsertId)
	}
	if RowsAffected, err := ret.RowsAffected(); nil == err {
		fmt.Println("RowsAffected:", RowsAffected)
	}
}
```
通过`db.Exec()`插入数据，通过返回的`err`可知插入失败的原因，通过返回的`ret`可以进一步查询本次插入数据影响的行数`RowsAffected`和最后插入的Id(如果数据库支持查询最后插入Id).

[github完整代码示例](https://github.com/researchlab/golearning/blob/master/sql/sql.go)

**4.预编译语句(Prepared Statement)**
预编译语句(PreparedStatement)提供了诸多好处, 因此我们在开发中尽量使用它. 下面列出了使用预编译语句所提供的功能:

- PreparedStatement 可以实现自定义参数的查询
- PreparedStatement 通常来说, 比手动拼接字符串 SQL 语句高效.
- PreparedStatement 可以防止SQL注入攻击


一般用`Prepared Statements`和`Exec()`完成`INSERT`, `UPDATE`, `DELETE`操作。

下面是将上述案例用Prepared Statement 修改之后的完整代码
```golang 
package main

import (
	"database/sql"
	"fmt"
	_ "github.com/go-sql-driver/mysql"
)

type DbWorker struct {
	Dsn      string
	Db       *sql.DB
	UserInfo userTB
}
type userTB struct {
	Id   int
	Name sql.NullString
	Age  sql.NullInt64
}

func main() {
	var err error
	dbw := DbWorker{
		Dsn: "root:123456@tcp(localhost:3306)/sqlx_db?charset=utf8mb4",
	}
	dbw.Db, err = sql.Open("mysql", dbw.Dsn)
	if err != nil {
		panic(err)
		return
	}
	defer dbw.Db.Close()

	dbw.insertData()
	dbw.queryData()
}

func (dbw *DbWorker) insertData() {
	stmt, _ := dbw.Db.Prepare(`INSERT INTO user (name, age) VALUES (?, ?)`)
	defer stmt.Close()

	ret, err := stmt.Exec("xys", 23)
	if err != nil {
		fmt.Printf("insert data error: %v\n", err)
		return
	}
	if LastInsertId, err := ret.LastInsertId(); nil == err {
		fmt.Println("LastInsertId:", LastInsertId)
	}
	if RowsAffected, err := ret.RowsAffected(); nil == err {
		fmt.Println("RowsAffected:", RowsAffected)
	}
}

func (dbw *DbWorker) QueryDataPre() {
	dbw.UserInfo = userTB{}
}
func (dbw *DbWorker) queryData() {
	stmt, _ := dbw.Db.Prepare(`SELECT * From user where age >= ? AND age < ?`)
	defer stmt.Close()

	dbw.QueryDataPre()

	rows, err := stmt.Query(20, 30)
	defer rows.Close()
	if err != nil {
		fmt.Printf("insert data error: %v\n", err)
		return
	}
	for rows.Next() {
		rows.Scan(&dbw.UserInfo.Id, &dbw.UserInfo.Name, &dbw.UserInfo.Age)
		if err != nil {
			fmt.Printf(err.Error())
			continue
		}
		if !dbw.UserInfo.Name.Valid {
			dbw.UserInfo.Name.String = ""
		}
		if !dbw.UserInfo.Age.Valid {
			dbw.UserInfo.Age.Int64 = 0
		}
		fmt.Println("get data, id: ", dbw.UserInfo.Id, " name: ", dbw.UserInfo.Name.String, " age: ", int(dbw.UserInfo.Age.Int64))
	}

	err = rows.Err()
	if err != nil {
		fmt.Printf(err.Error())
	}
}
```

>> <font color=red>db.Prepare()返回的statement使用完之后需要手动关闭，即defer stmt.Close()</font>
