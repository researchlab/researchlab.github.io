---
title: "[译]GO BOOTCAMP 第六章：方法"
date: 2016-01-23 14:19:07
categories: go-bootcamp
tags: [golang]
description:
---

从技术上来将，`Go`并不是一门面向对象的编程语言,所以与充许将类型和方法以面向对象的方式编程有些差别,最大的差异在于`Go`不支持类型继承,但是提供一个`接口`的概念. 在本章中，我们主要来讨论在`Go`编程中使用方法和接口.
<!--more-->

** 函数和方法的区别？**
方法是定义了接收者的函数，从面向对象的角度来讲,方法是对象实例上的一个函数。

`Go`语言没有`class`类的概念，但是你可以在结构体类型中定义方法.
方法的接收者在`func`关键字和方法名之间，并以它自己的参数形式出现. 下面是一个拥有`FirstName`和`LastName`字段的`User`结构体的示例
```golang 
package main

import (
	"fmt"
)

type User struct {
	FirstName, LastName string
}

func (u User) Greeting() string {
	return fmt.Sprintf("Dear %s %s", u.FirstName, u.LastName)
}

func main() {
	u := User{"Matt", "Aimonetti"}
	fmt.Println(u.Greeting())
}
```
注意上述代码中，是如何在结构体外定义方法的，如果你做过面向对象编程，你可能会觉得有点奇怪. `User`结构体上的方法可以定义在包内的任意位置.

## 组织代码

方法可以定义在包中的任意文件中，但是推荐向下面这样定义方法来组织代码结构
```golang 
package models

// list of packages to import
import (
	"fmt"
)

// list of constants
const (
	ConstExample = "const before vars"
)

// list of variables
var (
	ExportedVar    = 42
	nonExportedVar = "so say we all"
)

// Main type(s) for the file,
// try to keep the lowest amount of structs per file when possible.
type User struct {
	FirstName, LastName string
	Location            *UserLocation
}

type UserLocation struct {
	City    string
	Country string
}

// List of functions
func NewUser(firstName, lastName string) *User {
	return &User{FirstName: firstName,
		LastName: lastName,
		Location: &UserLocation{
			City:    "Santa Monica",
			Country: "USA",
		},
	}
}

// List of methods
func (u *User) Greeting() string {
	return fmt.Sprintf("Dear %s %s", u.FirstName, u.LastName)
}
```
可以在任何类型上定义方法，而不仅仅在结构体上取定义方法.但是不能在本包中为另一个包中的类型定义方法，也不能为`Go`语言内置的基础类型定义方法.


## 类型别名
在一个不需要你的类型上定义方法， 你需要给这个类型定义一个别名用来扩展

示例1 

```golang 
package main

import (
	"fmt"
	"strings"
)

type MyStr string

func (s MyStr) Uppercase() string {
	return strings.ToUpper(string(s))
}

func main() {
	fmt.Println(MyStr("test").Uppercase())
}
```

示例2

```golang
package main

import (
    "fmt"
    "math"
)

type MyFloat float64

func (f MyFloat) Abs() float64 {
    if f < 0 {
        return float64(-f)
    }
    return float64(f)
}

func main() {
    f := MyFloat(-math.Sqrt2)
    fmt.Println(f.Abs())
}
```

## 方法接收者

方法可以通过一个类型名或一个指向类型的指针与类型关联起来.在上述两个案例中，通过类型别名`MyStr`和`MyFloat`定义了相应的方法.

有如下理由推荐使用指针接收器:
- 避免为每个方法拷贝值(如果值类型是一个大型的结构体，使用指针则更高效）
- 上面的例子可以做如下更好的改进

```golang
package main

import (
	"fmt"
)

type User struct {
	FirstName, LastName string
}

func (u *User) Greeting() string {
	return fmt.Sprintf("Dear %s %s", u.FirstName, u.LastName)
}

func main() {
	u := &User{"Matt", "Aimonetti"}
	fmt.Println(u.Greeting())
}
```

在`Go`语言中，一切都是值传递,意味着当`Greeting()`定义在值类型上，每次调用`Greeting()`,都需要拷贝一份`User`结构体，而如果使用指针，则只需要拷贝一份指针.

- 另一个推荐使用指针的原因是，可以方便地通过指针将方法体内修改的值传递到方法外面.
```golang 
package main

import (
	"fmt"
	"math"
)

type Vertex struct {
	X, Y float64
}

func (v *Vertex) Scale(f float64) {
	v.X = v.X * f
	v.Y = v.Y * f
}

func (v *Vertex) Abs() float64 {
	return math.Sqrt(v.X*v.X + v.Y*v.Y)
}

func main() {
	v := &Vertex{3, 4}
	v.Scale(5)
	fmt.Println(v, v.Abs())
}

```

在上述案例中,`Abs()`因为没有修改接收者的值(the vertex),所以进行值类型定义和指针定义都美关系. 然而`Scale()`方法必需定义在指针上, 因为`Scale()`改变了`X`和`Y`的值，需要通过指针将方法体内的修改传递到方法外部来.
