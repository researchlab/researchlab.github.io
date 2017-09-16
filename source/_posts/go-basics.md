---
title: "[译]GO BOOTCAMP 第二章：基本概念实战"
date: 2016-01-16 16:54:06
categories: go-bootcamp
tags: [golang]
description:
---

如果已经有一定的编程基础，那你只需花几个小时就能学会`Go`编程，因此`Go`也常被认为是一门“简单易用”的编程语言。Go语言被设计得尽量简洁，它的整个语言规范也一样。在写第一个`Go`应用之前，我们先来学习`Go`的一些基础概念。
<!--more-->

## 变量及类型推断
用`var`关键字声明一个变量列表，其中变量的数据类型Type放在变量名的后面，如:
```golang
var(
	name string
	age int
	location string	
)
```
或着将相同类型的变量写在一行并用逗号隔开,
```golang
var(
	name, location string
	age int	
)
```
也可以一个一个的声明变量, 
```golang
var name string
var age int 
var location string
```
也可在`var`关键字声明的变量列表中初始化变量，
```golang
var(
	name string = "Prince Oberyn"
	age int = 32
	location string = "Dorne"	
)
```
也可以向下面这样声明初始化变量,
```golang
var (
	name, location, age = "Prince Oberyn", "Dorne", 32
)
```
在函数内部可以直接用短赋值符号`:=`来隐式的声明初始化变量，但是这种短赋值符号只能用于声明局部变量，即只能在函数体内使用,如:
```golang
func main() {
	name, location := "Prince Oberyn", "Dorne"
	age := 32
	fmt.Printf("%s (%d) of %s", name, age, location)
}
```
[示例代码](https://github.com/researchlab/go-bootcamp/blob/master/ch02/short_assign_case.go)
在`Go`语言中，一个变量可以是任意类型，甚至可以将一个函数赋值给一个变量,如:
```golang
func main() {
	action := func() {
		//doing something
	}
	action()
}
```
**注意:** 短赋值符号`:=`只能用来隐式初始化局部变量，不能在函数体外部使用。

## 常量
在`Go`语言中，用`const`关键字声明常量。常量只能是字符，字符串，布尔值或数值。常量初始化可以通过上下文推断它的类型，但是不能使用短赋值符号`:=`对常量进行声明初始化操作，如:
```golang
const Pi = 3.14
const (
		StatusOK                   = 200
		StatusCreated              = 201
		StatusAccepted             = 202
		StatusNonAuthoritativeInfo = 203
		StatusNoContent            = 204
		StatusResetContent         = 205
		StatusPartialContent       = 206
)
```
```golang
package main

import "fmt"

const (
	Pi    = 3.14
	Truth = false
	Big   = 1 << 100
	Small = Big >> 99
)

func main() {
	const Greeting = "ハローワールド"
	fmt.Println(Greeting)
	fmt.Println(Pi)
	fmt.Println(Truth)
}
```
[示例代码](https://github.com/researchlab/go-bootcamp/blob/master/ch02/constant_declared.go)

## 打印常量和变量
你可以灵活的使用`fmt`包提供的`print`和`println`函数打印一个常量或变量的值,如:
```golang
func main() {
	cylonModel := 6
	fmt.Println(cylonModel)
}
```
可用`fmt.Println`换行打印变量，如果要按指定的输出格式打印一个或多个值变量时可以用`fmt.Printf`函数,如:
```golang
func main() {
	name := "Caprica-Six"
	aka := fmt.Sprintf("Number %d", 6)
	fmt.Printf("%s is also known as %s",name, aka)
}
```
## 包和引入
每个`Go`程序都是由`packages`组成的，并且以`main`包为程序的运行入口，如:
```golang
package main
func main() {
	print("Hello,World!\n")
}
```
如果写一个可执行程序（相对于库）,那需要定义一个`main` 包的`go`文件，`main`包中的`main`函数就是执行程序的入口。按惯例，包名是相同的导入路径的最后一个元素。例如，引入路径`math/rand`，是指引入`math/`路径下的`rand`包。
引入包示例:
```golang
import "fmt"
import "math/rand"
```
或着引入一个包组:
```golang
import(
	"fmt"
	"math/rand"	
)
```
通常，非标准库包使用一个`web url`作为命名空间，如我将`Rails 4`中使用的一些用于加密的代码和逻辑移植到`Go`中，然后将代码包托管到`github`的`repository`上，如:[http://github.com/mattetti/goRailsYourself]()
 那现在可以通过下面的方式来引入提交的这个加密包`crypto package`:
 ```golang
import "github.com/mattetti/goRailsYourself/crypto"
```

## 代码位置
上面的代码片段只是简单的告诉编译器可以在**github.com/mattetti/goRailsYourself/crypto**路径下获得`crypto`这个包，但并不意味着编译器会自动去`github`仓库中把这个代码拉下来，那到哪里去找到这个`crypto`代码包呢？
你需要自己去把代码拉下来，最简单的方法是使用`Go`提供的`go get`命令,
```bash
$ go get github.com/mattetti/goRailsYourself/crypto
```
当安装`Go`时，我们需要设置`GOPATH`环境变量, 这个是用来指明二进制执行程序，库文件和你自己代码的存放位置的。执行`go get`命令，它会把相应的包文件下载到`GOPATH`指定到路径下。
```bash
$ ls $GOPATH
bin	pkg	src
```
`bin`文件夹中包括`Go`编译生成到二进制执行文件，你需要将`bin`文件夹路径添加到你的系统路径中。
`pkg`文件夹存放编译生成的对应编译版本的所有库文件使得编译器在不需要重新编译的情况下可以重新链接它们。
最后，`src`文件夹中按引入路径存放着所有`Go`源码,如：
```bash
$ ls $GOPATH/src
bitbucket.org	code.google.com	github.com	launchpad.net
```
```bash
$ ls $GOPATH/src/github.com/mattetti
goblin			goRailsYourself		jet
```
当新建一个项目时，在`src`文件夹中推荐按照包引入路径来放置源码文件(如: **github.com/<your username>/<project name>**)

## 导入名字
导入一个包后，就可以通过名字来引用导入包中的内容（即在包外可以访问到它到变量，方法及函数等）,在`Go`中，如果名字首字母大写则这个名字，则这个名字可导入的，可以被导入到其它包中使用，即公有的。如`Foo`和`FOO`都是可导入的,而`foo`则不是可导入的，来看两者的不同:
```golang
func main() {
    fmt.Println(math.pi)
}
```
和
```golang
func main() {
	fmt.Println(math.Pi)
}
```
`Pi`是可以导入的，可以在包外被调用，是公有的，而`pi`则不可以，编译报错提示：
```bash
cannot refer to unexported name math.pi
```

## 函数形参名,返回值，被命名的返回值
一个函数可以有零个或多个形参，也可以有多个返回值。在形参列表中类型放在形参变量的后面，如:
```golang
package main

import "fmt"

func add(x int, y int) int {
	    return x + y
}

func main() {
	    fmt.Println(add(42, 13))
}
```
在下面的示例中，可以将多个类型相同的形参一起声明，如`x int, y int`可以写成`x, y int`，
```golang
package main

import "fmt"

func add(x, y int) int {
	    return x + y
}

func main() {
	    fmt.Println(add(42, 13))
}
```
下面示例中，`location`函数返回两个`string`类型值。
```golang
func location(city string) (string, string) {
		var region string
		var continent string

		switch city {
		case "Los Angeles", "LA", "Santa Monica":
			region, continent = "California", "North America"
		case "New York", "NYC":
			region, continent = "New York", "North America"
		default:
			region, continent = "Unknown", "Unknown"
		}
			return region, continent
}

func main() {
		region, continent := location("Santa Monica")
		fmt.Printf("Matt lives in %s, %s", region, continent)
}
```
在`Go`语言中，函数可以返回多个值，如果返回参数被命名了，则返回语句可以不需要显示返回相应的返回参数，如：
```golang
func location(name, city string) (name, continent string) {
	switch city {
		case "New York", "LA", "Chicago":
			continent = "North America"
		default:
			continent = "Unknown"
		}
		return
}

func main() {
		name, continent := location("Matt", "LA")
		fmt.Printf("%s lives in %s", name, continent)
}
```
但是个人推荐，无论返回参数是否被命名了，在返回语句中都显示加上被返回的参数名称

## 指针
在`Go`语言中有指针，但是没有指针运算。结构字段都可以通过一个结构指针进行访问。`Go`中指针就像透明的一样，可以用指针直接调用字段和方法。不过`Go`默认是按值传递参数（值拷贝），如果想通过引用传递参数，则需要传递指针（或使用`slice`和`map`等引用结构类型。可以在变量前面加`&`符号取得这个变量的地址,在变量前面加`*`符号则可以取得这个变量的值。在`Go`中方法默认被定义为指针类型而不是值类型（不过方法也可以定义为值类型），通常可以将一个指针赋值给一个变量，如：
```golang
client := &http.Client{}
resp, err := client.Get("http://gobootcamp.com")
```
## 可变性
在`Go`中，只有常量在初始化之后是不可改变的。但注意在`Go`函数中参数默认按值传递，在函数体内修改传入的参数值，并不会改变函数外这个参数的值，如：
```golang
package main
import "fmt"

type Artist struct {
		Name, Genre string
		Songs       int
}

func newRelease(a Artist) int {
		a.Songs++
		return a.Songs
}

func main() {
		me := Artist{Name: "Matt", Genre: "Electro", Songs: 42}
		fmt.Printf("%s released their %dth song\n", me.Name, newRelease(me))
		fmt.Printf("%s has a total of %d songs", me.Name, me.Songs)
}
```
results:
```bash
Matt released their 43th song
Matt has a total of 42 songs
```
上面的结果并没有真正修改`me`变量中的值，是因为上述形参是通过值传递，如果要达到成功修改，则需要借助指针对`me`变量进行引用传递，如：
```golang
package main

import "fmt"

type Artist struct {
		Name, Genre string
		Songs       int
}

func newRelease(a *Artist) int {
		a.Songs++
		return a.Songs
}

func main() {
		me := &Artist{Name: "Matt", Genre: "Electro", Songs: 42}
		fmt.Printf("%s released their %dth song\n", me.Name, newRelease(me))
		fmt.Printf("%s has a total of %d songs", me.Name, me.Songs)
}
```
上面两个版本中唯一对不同是第一个版本是值传递，只修改了拷贝不影响变量原值，而第二个版本是引用传递，修改的是同一地址上的内容，所以修改成功。

** 《GO BOOTCAMP》第二章翻译完成，原著第二章出处：[Chapter 2 The Basics](http://www.golangbootcamp.com/book/basics) **
