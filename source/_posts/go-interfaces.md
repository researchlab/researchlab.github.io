---
title: "[译]GO BOOTCAMP 第七章：接口"
date: 2016-01-25 15:12:56
categories: go-bootcamp
tags: [golang]
description:
---

## 前言
接口被定义为一组方法的集合, 接口可以接收任何其实现的方法的值.
<!--more-->
下面利用接口的特性，重构了之前的一个案例,这次通过给`Greet`方法提供一个接口类型参数`Namer`，使得`Greet`方法更通用. `Namer`是定义的新接口，只包含一个方法`Name()`,所以`Greet()`可以接收任意有`Name()`方法定义的值.

为`User`结构体实现这个接口，定义了一个`Name()`方法。 可以通过传递一个执行`User`的指针给`Greet`方法来调用`Greet`.
```golang
package main

import (
	"fmt"
)

type User struct {
	FirstName, LastName string
}

func (u *User) Name() string {
	return fmt.Sprintf("%s %s", u.FirstName, u.LastName)
}

type Namer interface {
	Name() string
}

func Greet(n Namer) string {
	return fmt.Sprintf("Dear %s", n.Name())
}

func main() {
	u := &User{"Matt", "Aimonetti"}
	fmt.Println(Greet(u))
}
```
可以定义一个新的类型实现相同的接口，`Greet`函数同样可以使用
```golang
package main

import (
	"fmt"
)

type User struct {
	FirstName, LastName string
}

func (u *User) Name() string {
	return fmt.Sprintf("%s %s", u.FirstName, u.LastName)
}

type Customer struct {
	Id       int
	FullName string
}

func (c *Customer) Name() string {
	return c.FullName
}

type Namer interface {
	Name() string
}

func Greet(n Namer) string {
	return fmt.Sprintf("Dear %s", n.Name())
}

func main() {
	u := &User{"Matt", "Aimonetti"}
	fmt.Println(Greet(u))
	c := &Customer{42, "Francesc"}
	fmt.Println(Greet(c))
}
```

## 接口满足隐式实现

一个类型可以通过实现接口的所有方法来实现接口.

不需要显示的取声明或者实现某个接口.

隐式接口解偶实现定义接口的包，不需要额外的依赖.

推荐合理定义接口，就不需要额外标记定义的新接口.
```golang 
package main

import (
	"fmt"
	"os"
)

type Reader interface {
	Read(b []byte) (n int, err error)
}

type Writer interface {
	Write(b []byte) (n int, err error)
}

type ReadWriter interface {
	Reader
	Writer
}

func main() {
	var w Writer

	// os.Stdout implements Writer
	w = os.Stdout

	fmt.Fprintf(w, "hello, writer\n")
}
```

## 错误
错误可以被描述任意的错误字符串. 可以捕获前置定义，内置接口类型，错误等， 错误返回的是一个字符串。
```golang
type error interface {
    Error() string
}
```
可以使用`fmt`包来打印错误信息
```golang
package main

import (
    "fmt"
    "time"
)

type MyError struct {
    When time.Time
    What string
}

func (e *MyError) Error() string {
    return fmt.Sprintf("at %v, %s",
        e.When, e.What)
}

func run() error {
    return &MyError{
        time.Now(),
        "it didn't work",
    }
}

func main() {
    if err := run(); err != nil {
        fmt.Println(err)
    }
}
```

** 练习题 ** 
自定义一个`Sqrt`函数，让起返回一个错误。
创建一个新类型
```golang
type ErrNegativeSqrt float64
```
定义一个Error()
```golang
func (e ErrNegativeSqrt) Error() string
```
如果直接打印错误`fmt.Print(e)` 可能使得程序陷入无限循环，可以通过`fmt.Print(float64(e))` 来避免这种情况.

** 解决方案 ** 
```golang
package main

import (
	"fmt"
)

type ErrNegativeSqrt float64

func (e ErrNegativeSqrt) Error() string {
	return fmt.Sprintf("cannot Sqrt negative number: %g", float64(e))
}

func Sqrt(x float64) (float64, error) {
	if x < 0 {
		return 0, ErrNegativeSqrt(x)
	}

	z := 1.0
	for i := 0; i < 10; i++ {
		z = z - ((z*z)-x)/(2*z)
	}
	return z, nil
}

func main() {
	fmt.Println(Sqrt(2))
	fmt.Println(Sqrt(-2))
}
```

** Tip: ** 
当声明一个浮点数声明时，可以省略小数点后面的值, 如下面那样, 但是，不推荐!
```golang 
z := 1.
// same as
// z := 1.0
```

