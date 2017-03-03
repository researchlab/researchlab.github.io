---
title: "beego/orm使用总结" 
date: 2017-03-01 10:44:29
categories: [golang]
tags: [golang, beego/orm]
description:
---

## 前言
很早之前的一个老项目就使用过ORM，当时使用的是`xorm`，后来新的项目设计说考虑性能什么的又用写原生sql来做了，在项目中使用一直没什么问题， 但是代码中到处写着原生的sql语句,并且有很多重复的语句，很不好维护，于是最近又重新考虑采用orm的方式来操作数据库，最近看中`beego/orm`这个包， 它的官方文档也写了很详细的使用说明，下面还是简要总结一下自己在项目中的使用经历,
<!--more-->

## ORM

ORM, 即Object-Relational Mapping(对象关系映射)，它的作用是在关系型数据库和业务实体对象之间作一个映射，这样在具体的操作业务对象的时候，就不需要再去和复杂的SQL语句打交道，只需简单的操作对象的属性和方法。

** 优势 ** 

- 隐藏了数据访问细节，也是ORM的核心所在, "封闭"的通用数据库交互。使数据库交互变得简单易行，并且完全不用考虑SQL语句。快速开发，由此而来。

- ORM使构造固化数据结构变得简单易行。在使用ORM之前, 需要将对象模型转化为一条一条的SQL语句，通过直连或是DB helper在关系数据库构造想要的数据库体系。而基本上所有的ORM框架都提供了通过对象模型构造关系数据库结构的功能。

ORM有优势也存在缺点，

** 缺点 **

- 无可避免的，自动化意味着映射和关联管理，代价是牺牲性能(早期，这是所有不喜欢ORM人的共同点)。现各种ORM框架都在尝试使用各种方法来减轻这块(LazyLoad，Cache),效果还是很显著的。

- 面向对象的查询语言(X-QL)作为一种数据库与对象之间的过渡, 虽然隐藏了数据层面的业务抽象, 但并不能完全的屏蔽掉数据库层的设计, 并且无疑将增加学习成本。

- 对于复杂查询，ORM仍然力不从心。虽然可以实现，但是不值的。视图可以解决大部分calculated column，case，group，having, order by, exists，但是查询条件(a and b and not c and (d or d))。

从ORM优缺点来看， ORM适合使用在较大型复杂的系统中或数据库操作很多的系统中， 当即便使用了ORM的复杂项目在特殊情况下也应考虑用原生SQL来解决复杂查询和性能问题，小的项目则看性能苛刻来考虑了，如果性能苛刻则用原生的SQL实现更合适，如果没有什么要求则用不用ORM都没啥关系。

## beego/orm 使用

据beego/orm官方文档说明目前其还处在开发中只支持`MySQL`,`PostgreSQL`, `Sqlite3`三种数据库驱动，目前beego/orm包支持以下特性,
- 支持 Go 的所有类型存储
- 轻松上手，采用简单的 CRUD 风格
- 自动 Join 关联表
- 跨数据库兼容查询
- 允许直接使用 SQL 查询／映射
- 严格完整的测试保证 ORM 的稳定与健壮

官方使用案例,
```golang
package main

import (
	"fmt"

	"github.com/astaxie/beego/orm"
	_ "github.com/go-sql-driver/mysql" //import your used driver
)

// Model Struct
type User struct {
	Id   int
	Name string `orm:"size(100)"`
}

func init() {
	// set default database
	orm.RegisterDataBase("default", "mysql", "root:123456@/my_db?charset=utf8", 30)

	// register model
	orm.RegisterModel(new(User))

	// create table
	orm.RunSyncdb("default", false, true)
}

func main() {
	o := orm.NewOrm()

	user := User{Name: "slene"}

	// insert
	id, err := o.Insert(&user)
	fmt.Printf("ID: %d, ERR: %v\n", id, err)

	// update
	user.Name = "astaxie"
	num, err := o.Update(&user)
	fmt.Printf("NUM: %d, ERR: %v\n", num, err)

	// read one
	u := User{Id: user.Id}
	err = o.Read(&u)
	fmt.Printf("ERR: %v\n", err)
	fmt.Println("u:", u)

	// delete
	num, err = o.Delete(&u)
	fmt.Printf("NUM: %d, ERR: %v\n", num, err)
}
```

从上述代码可知，使用ORM大致分以下几步，
1.注册数据库;
2.注册待使用的数据库表结构对象;
3.在数据库中生成上述注册的数据库表结构对象;
4.得到一个待操作ORMER对象;
5.用上述的得到ORMER对象即可对数据库进行CURD操作了。

可以看到整个过程几乎不用写SQL语句， 并且逻辑清晰，当然性能方面跟直接用原生的SQL语句写肯定要差一些，因为beego/orm源码里面为了判断数据类型/转换数据类型等用了很多反射/强转等操作，这样做虽然是为了最大限度兼容各类数据操作，但对于本就不涉及复杂繁多的SQL的系统而言， 还是多考虑用原生SQL语句来写了。

下面是工作中应用抽取出来的一个代码片段，
```golang
package main

import (
	"log"
	"strconv"
	"sync"
	"time"

	"github.com/astaxie/beego/orm"
	_ "github.com/go-sql-driver/mysql"
)

const (
	DEBUG = true
)

var db orm.Ormer

func init() {
	orm.RegisterDriver("mysql", orm.DRMySQL)
	err := orm.RegisterDataBase("default", "mysql", *dsn)
	if err != nil {
		log.Fatalf("connect database error: %v\n", err)
	} else {
		log.Println("connect db success")
	}

	orm.RegisterModel(new(Record))

	err = orm.RunSyncdb("default", false, false)
	if err != nil {
		log.Fatalf(err)
	}

	db = orm.NewOrm()
	if DEBUG {
		orm.Debug = true
	}
	recordsChan = make(chan *Record, *insertBatchNum)
	recordInsterLoop(done)
}

func GetDB() orm.Ormer {
	return db
}

func newRecord(param *requestParameter, resp *responseData) *Record {
	r := new(Record)
	r.Src = param.values.Get("src")
	r.OpenID = param.values.Get("openid")
	r.IdempotentStr = param.values.Get("idempotent_str")
	r.Noncestr = param.values.Get("noncestr")
	r.ReqTimestamp, _ = strconv.Atoi(param.values.Get("timestamp"))
	r.ActivityID, _ = strconv.Atoi(param.values.Get("activity_id"))
	r.BatchID, _ = strconv.Atoi(param.values.Get("batch_id"))
	r.Sign = param.values.Get("sign")

	if resp != nil {
		r.ErrorCode = resp.ErrorCode
		r.ErrorMsg = resp.ErrorMsg
		if resp.Timestamp == 0 {
			r.RespTimestamp = int(time.Now().Unix())
		}
		r.CouponID = resp.CouponID
	}
	return r
}

type Record struct {
	ID            int    `orm:"column(id)" json:"record_id"`
	Src           string `json:"str"`
	OpenID        string `orm:"column(open_id)" json:"open_id"`
	IdempotentStr string `json:"idempotent_str"`
	Noncestr      string `json:"noncestr"`
	ReqTimestamp  int    `json:"req_timestamp"`
	ActivityID    int    `orm:"column(activity_id)" json:"activity_id"`
	BatchID       int    `orm:"column(batch_id)" json:"batch_id"`
	Sign          string `json:"sign"`
	ErrorCode     int    `json:"error_code"`
	ErrorMsg      string `json:"error_msg"`
	RespTimestamp int    `json:"resp_timestamp"`
	CouponID      int    `orm:"column(coupon_id)" json:"coupon_id"`
}

func (Record) TableName() string {
	return "records"
}

var recordsChan chan *Record

func (r *Record) InsertRecord() {
	recordsChan <- r
}

func recordInsterLoop(done <-chan bool) {
	var mu sync.Mutex
	go func() {
		records := make([]*Record, 0, *insertBatchNum)
		for {
			select {
			case <-done:
				recordCopy := Copyrecode(records)
				insertMulti(recordLen, recordCopy)

			case <-time.After(time.Duration(5) * time.Second):

				recordCopy, recordLen := Copyrecode(records)
				insertMulti(recordLen, recordCopy)

			case r := <-recordsChan:
				records = append(records, r)
				recordLen := len(records)

				if recordLen >= *insertBatchNum {
					recordCopy, recordLen := Copyrecode(records)
					insertMulti(recordLen, recordCopy)
				}
			}
		}
		close(recordsChan)
	}()
}

func Copyrecode(records []*Record) (recordCopy []*Record, recordLen int) {
	mu.Lock()
	recordLen = len(records)
	recordCopy = make([]*Record, recordLen)
	copy(recordCopy, records)
	records = make([]*Record, 0, *insertBatchNum)
	mu.Unlock()
}
func insertMulti(n int, rs []*Record) (int64, error) {
	return GetDB().InsertMulti(n, rs)
}
```

上述代码就是用ORM将数据插入到指定数据库表中，实现过程考虑到了数据插入超时及强制退出时将records中预留的数据插入数据库一定程度上保证数据不丢失。
