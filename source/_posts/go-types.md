---
title: "[译]GO BOOTCAMP 第三章：内置类型实战"
date: 2016-01-17 21:36:28
categories: go-bootcamp
tags: [golang]
description:
---

## 前言
`Go`内置类型实战，包括类型转换，类型断言，结构类型，结构继承等内容。
<!--more-->

## 基本类型
`Go`语言主要有如下内置基本类型，
```golang
bool
string

Numeric types:

uint        either 32 or 64 bits
int         same size as uint
uintptr     an unsigned integer large enough to store the uninterpreted bits of
            a pointer value
uint8       the set of all unsigned  8-bit integers (0 to 255)
uint16      the set of all unsigned 16-bit integers (0 to 65535)
uint32      the set of all unsigned 32-bit integers (0 to 4294967295)
uint64      the set of all unsigned 64-bit integers (0 to 18446744073709551615)

int8        the set of all signed  8-bit integers (-128 to 127)
int16       the set of all signed 16-bit integers (-32768 to 32767)
int32       the set of all signed 32-bit integers (-2147483648 to 2147483647)
int64       the set of all signed 64-bit integers
            (-9223372036854775808 to 9223372036854775807)

float32     the set of all IEEE-754 32-bit floating-point numbers
float64     the set of all IEEE-754 64-bit floating-point numbers

complex64   the set of all complex numbers with float32 real and imaginary parts
complex128  the set of all complex numbers with float64 real and imaginary parts

byte        alias for uint8
rune        alias for int32 (represents a Unicode code point)
```
内置类型基本使用示例，
```golang
package main

import (
	"fmt"
	"math/cmplx"
)

var (
	goIsFun bool       = true
	maxInt  uint64     = 1<<64 - 1
	complex complex128 = cmplx.Sqrt(-5 + 12i)
)

func main() {
	const f = "%T(%v)\n"
	fmt.Printf(f, goIsFun, goIsFun)
	fmt.Printf(f, maxInt, maxInt)
	fmt.Printf(f, complex, complex)
}
```
输出结果:
```bash
bool(true)
uint64(18446744073709551615)
complex128((2+3i))
```

## 类型转换
`T(v)`表示将`v`的类型转换为`T`类型，一些数值类型转换如下，
```golang
var i int = 42
var f float64 = float64(i)
var u uint = uint(f)
```
简化一下,
```golang 
i := 42
f := float64(i)
u := uint(f)
```
`Go`语言中不同类型之间需要显示转换才能相互赋值，如传入的参数类型与函数接收的参数不同时，需要手动进行类型转换才能传入。
**译者注:** `Go`语言中除了`byte`和`uint8`之间以及`rune`和`int32`之间可以相互进行赋值操作外，其它不同类型直接都需要显示转换才能进行相互赋值操作。 如,
	```golang
	var i byte = 1
	var u uint8 
	u = i // 可以直接赋值，不需显示转换 ，同样rune 与 int32 之间也是一样的。

	var i int = 1
	var f float64 = float64(i) //这里需要显示将 int 转换float64 才能赋值成功!
	```

## 类型断言
如果想判断一个变量的数据类型,或将当前类型(如 interface{})作相应的类型判断,可以借助类型断言来解决。类型断言试图将当前变量转换为指定的数据类型，并返回转换之后相应的指针对象（如果转换成功）及是否转换成功的标志值。下面示例中，`timeMap`函数接受一个变量，并断言这个变量类型是否为`map[string]interface{}`类型，如果是则为其初始化一个`key`为`updated_at`,`value`为`time.Now()`的值对。
```golang
package main

import (
	"fmt"
	"time"
)

func timeMap(y interface{}) {
	z, ok := y.(map[string]interface{})
	if ok {
		z["updated_at"] = time.Now()
	}
}

func main() {
	foo := map[string]interface{}{
		"Matt": 42,
	}
	timeMap(foo)
		fmt.Println(foo)
}
```
`Go`语言并不对空接口`interface{}`进行类型断言，如果函数内部如对不同类型参数会作出不同的处理，则通常需借助类型断言来完成，如：
```golang
type Stringer interface {
	String() string
}

type fakeString struct {
	content string
}

func (s *fakeString) String() string {
	return s.content
}

func printString(value interface{}) {
	switch str := value.(type) {
	case string:
		fmt.Println(str)
	case Stringer:
		fmt.Println(str.String())
	}
}
```
如果给`printString`传入一个`fakeString`,因为`fakeString`实现了`Stringer`方法，那么`printString`中会处理`Stringer`这个case,如果直接传入一个字符串给`printString`，则显然会处理`string`这个case 从而直接输出传入的字符串。
[示例代码](https://github.com/researchlab/go-bootcamp/blob/master/ch03/type_assertion.go)
类型断言也可以用于判断具体的`error`类型，如:
```golang
if err != nil {
	  if msqlerr, ok := err.(*mysql.MySQLError); ok && msqlerr.Number == 1062 {
	    	log.Println("We got a MySQL duplicate :(")
	   } else {
		    return err
	   }
}
```

## 结构
`struct`是多个字段或属性的集合，用户也可以自定义一个像`struct`或`interface`这样的数据类型。如果你学过面向对象编程，你可以将`struct`理解为一个轻量级的`class`支持字段属性的集合，但不支持继承。`struct`中默认提供`get`和`set`方法，需要注意的是只有首字母大写的`struct`变量才能被包访问。`struct`可以通过`Name:`后跟初始值来初始化`struct`,这样初始化时可以不按`struct`中字段声明的顺序进行初始化，如果在`struct`变量前加上`&`符号，返回的是一个指向这个`struct`的指针对象。
```golang
package main

import (
	"fmt"
	"time"
)

type Bootcamp struct {
	// Latitude of the event
	Lat float64
	// Longitude of the event
	Lon float64
	// Date of the event
	Date time.Time
}

func main() {
	fmt.Println(Bootcamp{
		Lat:  34.012836,
		Lon:  -118.495338,
		Date: time.Now(),
	})
}
```
声明并初始化`struct`对象，
```golang
package main

import "fmt"

type Point struct {
	X, Y int
}

var (
	p = Point{1, 2}  // 初始化一个Point对象
	q = &Point{1, 2} // 初始化一个Point指针对象
	r = Point{X: 1}  // Y值默认为0 
	s = Point{}      // X和Y的值都默认为0
)

func main() {
	fmt.Println(p, q, r, s)
}
```
[示例代码](https://github.com/researchlab/go-bootcamp/blob/master/ch03/declaration_struct.go)

可通过`.`符号访问`struct`中的成员变量，
```golang
package main

import (
	"fmt"
	"time"
)

type Bootcamp struct {
	Lat, Lon float64
	Date     time.Time
}

func main() {
	event := Bootcamp{
		Lat: 34.012836,
		Lon: -118.495338,
	}
	event.Date = time.Now()
	fmt.Printf("Event on %s, location (%f, %f)",event.Date, event.Lat, event.Lon)
}
```
[示例代码](https://github.com/researchlab/go-bootcamp/blob/master/ch03/access_struct_field.go)

## 初始化
`Go`支持用`new`表达式初始化变量，分配一个类型零值并返回指向这个类型的指针给变量。
```golang
x := new(int)
```
一种常见的初始化一个包含`struct`或引用变量的方法是创建一个`struct`字段。另一种方法是通过创建构造函数来完成初始化操作。这两种方法是当需要自定义初始化字段值常用的两种方法。下面用`new`方法和用空`struct`字段初始化一个`struct`是等价的，如:
```golang
package main

import (
	"fmt"
)

type Bootcamp struct {
	Lat float64
	Lon float64
}

func main() {
	x := new(Bootcamp)
	y := &Bootcamp{}
	fmt.Println(*x == *y)
}
```
上面`x`和`y`的初始化操作是等价的；后面要接触的`slices`，`maps`和`channels`结构初始化一般需要自定义初始化字段如长度，容量等，所以这些结构通常用`make`关键字来初始化操作。

## 组合vs继承
`Go`不支持面向对象编程中的继承操作，但是可以使用组合和接口来完成继承的操作。`Go`支持`OOP`中的组合（或者说绑定）操作。下面是一个关于地址操作的示例:
```golang
package main

import "fmt"

type User struct {
	Id       int
	Name     string
	Location string
}

type Player struct {
	User
	GameId   int
}

func main() {
	p := Player{}
	p.Id = 42
	p.Name = "Matt"
	p.Location = "LA"
	p.GameId = 90404
	fmt.Printf("%+v", p)
}
```
[示例代码](https://github.com/researchlab/go-bootcamp/blob/master/ch03/composition_case.go)
上面地址的案例是一个经典的`OOP`例子，现在考虑到`Player` struct和`User`struct有相同的字段，但是`Player`还有一个自己的`GameId`字段，用`OOP`思想则声明`Player`和`User`struct，会存在重复声明相同的字段，但是在`Go`中可以通过组合`struct`来简化这样的情况,
```golang
type User struct {
	Id             int
	Name, Location string
}

type Player struct {
	User
	GameId int
}
```
现在可通过两种方法来初始化一个`Player`结构。第一种使用`.`来设置`struct`字段,
```golang
package main

import "fmt"

type User struct {
	Id             int
	Name, Location string
}

type Player struct {
	User
	GameId int
}

func main() {
	p := Player{}
	p.Id = 42
	p.Name = "Matt"
	p.Location = "LA"
	p.GameId = 90404
	fmt.Printf("%+v", p)
}
```
另一种初始化方法是使用`struct`字段初始化语法`Name:`来初始化，
```golang
package main

import "fmt"

type User struct {
	Id             int
	Name, Location string
}

type Player struct {
	User
	GameId int
}

func main() {
	p := Player{
	User{Id: 42, Name: "Matt", Location: "LA"},90404,}
	fmt.Printf("Id: %d, Name: %s, Location: %s, Game id: %d\n",	p.Id, p.Name, p.Location, p.GameId)
	// Directly set a field define on the Player struct
	p.Id = 11
	fmt.Printf("%+v", p)
}
```
当需要调用匿名结构中的字段时，不能直接引用相应的字段，而是需要通过当前结构对象来调用，如`User`作为匿名结构嵌入在`Player`中，所以通过`Player`对象能调用到`User`中到字段，但是不能直接通过`User`中到字段名去调用，示例如:
```golang
package main

import "fmt"

type User struct {
	Id             int
	Name, Location string
}

func (u *User) Greetings() string {
	return fmt.Sprintf("Hi %s from %s",u.Name, u.Location)
}

type Player struct {
	User
	GameId int
}

func main() {
	p := Player{}
	p.Id = 42
	p.Name = "Matt"
	p.Location = "LA"
	fmt.Println(p.Greetings())
}
```
通过当前结构体对象引用嵌入到匿名结构体中的字段对构建数据结构非常有效，当嵌入对匿名结构实现了某个接口，那当前结构也就自动实现了这个接口了。下面来看另一个示例，`Job`结构中嵌入了`Logger`结构，那相当于`Job`也实现了`Logger`实现的了日志接口，如：
```golang
package main

import (
	"log"
	"os"
)

type Job struct {
	Command string
	Logger  *log.Logger
}

func main() {
	job := &Job{"demo", log.New(os.Stderr, "Job: ", log.Ldate)}
	// 也可这样初始化job
	// job := &Job{Command: "demo",
    //       Logger: log.New(os.Stderr, "Job: ", log.Ldate)}
	job.Logger.Print("test")
}
```
`Job`结构中有个字段`Logger`是一个指向`log.Logger`类型的指针，在初始化值之后，则`Job`对象就可以通过这样来调用`log.Logger`实现的`Print`函数了，`job.Logger.Print()`。既然`Logger`本身是一个指向`log.Logger`类型的指针，那我们直接在`Job`结构中嵌入一个`log.Logger`指针对象，那`Job`结构对象不就可以直接调用`job.Logger`实现的`Print`方法？ 答案是可以的， 如:
```golang
package main

import (
	"log"
	"os"
)

type Job struct {
	Command string
	*log.Logger //嵌入匿名指针类型
}

func main() {
	job := &Job{"demo", log.New(os.Stderr, "Job: ", log.Ldate)}
	job.Print("starting now...") //直接调用log.Logger实现的Print()方法
}
```
注意在使用`log.Logger`之前需要初始化，如果匿名结构实现了某个接口，也相当于使嵌入这个匿名结构的当前结构也实现了这个接口，非常方便高效。

## 案例分析
在`Go`中参数是默认是值传递,所以从上述`User/Player`示例中，你可能注意到在`Player`结构中嵌入`User`结构指针比直接嵌入`User`结构对象更好。确实如果嵌入到结构体比较简单时，使用哪种方法都差不多，如果像现实中`User`结构其实非常复杂，那选择传入引用则是更好到选择。修改上述代码如：
```golang
type User struct {
	Id             int
	Name, Location string
}

func (u *User) Greetings() string {
	return fmt.Sprintf("Hi %s from %s",u.Name, u.Location)
}

type Player struct {
	*User
	GameId int
}
```
上述将代码修改为嵌入`User`指针，那在调用`User`中字段之后，需要对`User`先初始化，详情看[示例代码](https://github.com/researchlab/go-bootcamp/blob/master/ch03/pass_ptr.go)

- Question: 为`User`结构指针类型定义一个`Greetings`方法，如何直接去调用它呢？
- Solution:
```golang
package main

import "fmt"

type User struct {
	Id             int
	Name, Location string
}

func (u *User) Greetings() string {
	return fmt.Sprintf("Hi %s from %s",u.Name, u.Location)
}

type Player struct {
	*User
	GameId int
}

func NewPlayer(id int, name, location string, gameId int) *Player {
	return &Player{
		User:   &User{id, name, location},
		GameId: gameId,
	}
}

func main() {
	p := NewPlayer(42, "Matt", "LA", 90404)
	fmt.Println(p.Greetings())
}
```
上述案例通过`NewPlayer`方法在使用`User`中的`Greetings`前，先初始化了`User`结构指针,如果在使用前不初始化，则调用`Greetings`时，是用一个`nil ptr`去调用`Greetings`，显然这样调用不成功，所以使用前需要先初始化，得到返回指向这个匿名对象的地址指针对象，才能进一步通过这个指针对象去调用匿名结构中的字段属性。


** 《GO BOOTCAMP》第三章翻译完成，原著第三章出处：[Chapter 3 Types](http://www.golangbootcamp.com/book/types) **
