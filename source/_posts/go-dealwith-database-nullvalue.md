---
title: "golang处理数据表中字段为空或NULL的情况"
date: 2016-11-23 11:40:54
categories: [golang]
tags: 
description:
---

golang是强类型语言，在赋值和解析过程中需要先定义好数据类型，否在会报类型错误，下面总结在处理数据库表时遇到字段为空或零值的情况
<!--more-->

## 场景
假如存在如下没有指定`not null`的场合
```sql
CREATE TABLE "users" (
    "id" serial not null primary key,
    "name" text,
    "age" integer
)
```

在[gorp](https://github.com/researchlab/gorp)中`insert`插入场合，可以直接赋零值即可，很方便.
```golang
 dbmap.Insert(
	 &User{Name: "John", Age: 0},　// insert into "users" ("id","name","age") values (default,$1,$2) returning Id; [1:"John" 2:0]
	 &User{Name: "John"}, // insert into "users" ("id","name","age") values (default,$1,$2) returning Id; [1:"John" 2:0]
	 &User{Name: "", Age: 8}, // insert into "users" ("id","name","age") values (default,$1,$2) returning Id; [1:"" 2:8]
	 &User{Age: 30}, // insert into "users" ("id","name","age") values (default,$1,$2) returning Id; [1:"" 2:30]
	)
```
在使用golang中零值与空值和NULL是不同的数据类型和值，需要加以判断，在数据库表中的NULL值字段可以用`database/sql`数据包中提供的`sql.NullString`，`sql.NullBool`等值类型进行判断后加以使用.

## 如何使用
可能存在NULL值的数据类型可以使用`sql.NullString`或`sql.NullBool`等来指定其类型.
```golang
type User struct{
    Id int `db:id`
    Name sql.NullString `db:name`
    Age sql.NullInt64 `db:age`
}
```
其中`sql.NullString`，它的结构如下:
```golang
type NullString struct {
    String string 
    Valid  bool // Valid is true if String is not NULL
}
```
借助`.sql.NullString`这样的结构体就可以在`insert`时，通过设置`Valid`的值为`fasle`就可以表示此值为`null`值，这样在读取时如果为`false`就可以肯定此值为默认的空值了，具体操作如下:
```golang
dbmap.Insert(
    &User{
      Name: sql.NullString{"Mike", true},
      Age: sql.NullInt64{0, true},
    }, //  insert into "users" ("id","name","age") values (default,$1,$2) returning Id; [1:"Mike" 2:0]
    &User{
      Name: sql.NullString{"", false},
      Age: sql.NullInt64{30, true},
    }, // insert into "users" ("id","name","age") values (default,$1,$2) returning Id; [1:<nil> 2:30]
  )
```
读取数据时，可以根据`valid`的值判断是否为设置的零值还是未被赋值操作.
```golang 
dbmap.Insert(
    &User{Name: sql.NullString{"Mike", true}, Age: sql.NullInt64{0, true}},
    &User{Name: sql.NullString{"John", true}, Age: sql.NullInt64{0, false}},
    &User{Name: sql.NullString{"John", true}, Age: sql.NullInt64{8, true}},
    &User{Name: sql.NullString{"", false}, Age: sql.NullInt64{30, true}},
  )

  users := []User{}
  _, err := dbmap.Select(&users, "select * from users")
  if err != nil {
    log.Fatal(err)
  }
  for _, user := range users {
    spew.Dump(user)
  }
/*
(main.User) {
 Id: (int) 1,
 Name: (sql.NullString) {
  String: (string) (len=4) "Mike",
  Valid: (bool) true
 },
 Age: (sql.NullInt64) {
  Int64: (int64) 0,
  Valid: (bool) true
 }
}
(main.User) {
 Id: (int) 2,
 Name: (sql.NullString) {
  String: (string) (len=4) "John",
  Valid: (bool) true
 },
 Age: (sql.NullInt64) {
  Int64: (int64) 0,
  Valid: (bool) false
 }
}
(main.User) {
 Id: (int) 3,
 Name: (sql.NullString) {
  String: (string) (len=4) "John",
  Valid: (bool) true
 },
 Age: (sql.NullInt64) {
  Int64: (int64) 8,
  Valid: (bool) true
 }
}
(main.User) {
 Id: (int) 4,
 Name: (sql.NullString) {
  String: (string) "",
  Valid: (bool) false
 },
 Age: (sql.NullInt64) {
  Int64: (int64) 30,
  Valid: (bool) true
 }
}
*/
```
在单次查询中根据`valid`的值作相应的零值判断处理, 方法如下:
```golang
var s NullString
err := db.QueryRow("SELECT name FROM foo WHERE id=?", id).Scan(&s)
...
if s.Valid {
   // use s.String
} else {
   // NULL value
}
```
