---
title: "[译]GO BOOTCAMP 第四章：集合类型"
date: 2016-01-19 09:24:38
categories: go-bootcamp
tags: [golang]
description:
---

`Go`集合类型包含`Array`,`Slice`,`Range`,`Map`等议题的分析和讨论。
<!--more-->

## Array-数组

`[n]T` 表示为一个n个数据类型为T的数组.

```golang
var a [10]int
```
表示声明一个包含10个整数的数组变量a.
数组的长度是它类型的一部分，所以数组在初始化之后就不能再更改大小，不过`Go`提供了一种方便的方式来使用数组.

```golang
package main

import "fmt"

func main() {
    var a [2]string
    a[0] = "Hello"
    a[1] = "World"
    fmt.Println(a[0], a[1])
    fmt.Println(a)
}
```

可以在声明数组的同时初始化数组

```golang
package main

import "fmt"

func main() {
    a  := [2]string{"hello", "world!"}
    fmt.Printf("%q", a)
}
```

在初始化数组时，也可以使用三个省略号来代替具体指明数组的大小
```golang
package main

import "fmt"

func main() {
	a := [...]string{"hello", "world!"}
	fmt.Printf("%q", a)
}
```
** 打印数组 ** 
之前使用`fmt`包的`Printf`函数和使用`%q`参数来打印每一个引用的元素，现在我们使用`Println`或`%s`参数来打印，将会得到不同的输出
```golang
package main

import "fmt"

func main() {
	a := [2]string{"hello", "world!"}
	fmt.Println(a)
	// [hello world!]
	fmt.Printf("%s\n", a)
	// [hello world!]
	fmt.Printf("%q\n", a)
	// ["hello" "world!"]
}
```
** 多维数组 **
创建多维数组
```golang
package main

import "fmt"

func main() {
	var a [2][3]string
	for i := 0; i < 2; i++ {
		for j := 0; j < 3; j++ {
			a[i][j] = fmt.Sprintf("row %d - column %d", i+1, j+1)
		}
	}
	fmt.Printf("%q", a)
	// [["row 1 - column 1" "row 1 - column 2" "row 1 - column 3"]
	//  ["row 2 - column 1" "row 2 - column 2" "row 2 - column 3"]]
}
```

如果试图通过索引取访问或修改某个不存在的数组元素，在编译时会报错不通过
```golang
package main

func main() {
    var a [2]string
    a[3] = "Hello"
}
```
当试图编译上述代码，会得到如下报错信息:

```golang
Invalid array index 3 (out of bounds for 2-element array)
```
这是因为长度为2的数组下标索引为0或1,试图获取索引3是数组越界，所以报上述error.

因为在使用数组之初，通常不能确定数组的长度， 所以`golang`提供了另一种常用的数据类型`Slices`.

## Slices-切片

`Slices`的底层依然是一个数组，不过封装过后的它更方便用于处理数据，除了多维数组以外，在`Go`编程中大多数情况使用`slices`而不是简单的使用数组.

`Slices`是对底层数组的一个引用，如果将一个`Slices`直接赋值给另一个`Slices`,那这两个`Slices`指向的是同一个数组. 将`Slices`通过函数形参传入，所做的修改会直接影响`slices`中的元素， 效果跟传入指针数组类似.

`Slices`包含一个指向数组的指针和这个数组的长度值。`Slices`可以被重新定义长度，因为它们仅仅是数组的一个顶层封装.

`[]T`表示为一个数据类型为`T`的切片.

```golang
package main

import "fmt"

func main() {
    p := []int{2, 3, 5, 7, 11, 13}
    fmt.Println(p)
    // [2 3 5 7 11 13]
}

```

可以基于现有的切片创建新的切片，表达式:
```golang
s[lo:hi]
```
上述表达式表示创建了一个新的切片，包含的数据为现有切片数据索引`lo`到索引`hi`的范围,因此
```golang
s[lo:lo]
```
表示一个空的切片.
```golang
s[lo:lo+1]
```
表示有一个元素的切片.

`lo`和`hi`是表示索引的整型整数
```golang
package main

import "fmt"

func main() {
	mySlice := []int{2, 3, 5, 7, 11, 13}
	fmt.Println(mySlice)
	// [2 3 5 7 11 13]

	fmt.Println(mySlice[1:4])
	// [3 5 7]

	// missing low index implies 0
	fmt.Println(mySlice[:3])
	// [2 3 5]

	// missing high index implies len(s)
	fmt.Println(mySlice[4:])
	// [11 13]
}
```

** 声明 slices ** 
除了可以通过在声明右边赋值来初始化一个`Slices`外， 还可以使用关键字`make`,方便用于创建一个指定初始长度的空`Slices`.
```golang 
package main

import "fmt"

func main() {
	cities := make([]string, 3)
	cities[0] = "Santa Monica"
	cities[1] = "Venice"
	cities[2] = "Los Angeles"
	fmt.Printf("%q", cities)
	// ["Santa Monica" "Venice" "Los Angeles"]
}
```
通过`make`关键字表示创建一个空数组，并返回这向这个数组的指针。

** 给slice 追加数据 ** 
```golang
cities := []string{}
cities[0] = "Santa Monica"
```
上述代码将报出一个运行时错误，因为`slice`是一个数组的引用，初始化一个长度为零的空数组时，不能直接通过`slice`给其引用的长度为0的空数组赋值。但是可以通过关键字`append`追加来做这件事情.
```golang 
package main

import "fmt"

func main() {
	cities := []string{}
	cities = append(cities, "San Diego")
	fmt.Println(cities)
	// [San Diego]
}
```
也可以给`slice`一次`append`多个值
```golang 
package main

import "fmt"

func main() {
	cities := []string{}
	cities = append(cities, "San Diego", "Mountain View")
	fmt.Printf("%q", cities)
	// ["San Diego" "Mountain View"]
}
```
也可以用省略号`...`来`append`多个数据
```golang 
package main

import "fmt"

func main() {
	cities := []string{"San Diego", "Mountain View"}
	otherCities := []string{"Santa Monica", "Venice"}
	cities = append(cities, otherCities...)
	fmt.Printf("%q", cities)
	// ["San Diego" "Mountain View" "Santa Monica" "Venice"]
}
```
省略号`...`是`Go`语言的一个内建特征，意味着这个元素是一个集合. 如果不用省略号不能给一个`[]string`直接`append`一个`[]string`, 只能`append`strings. 如果用了省略号则可以`append`,当然`append`的`slice`数据类型需要和被`append`的数据类型相同，比如就不能将`[]int`直接`append`到一个`[]string`的`slice`上。

** 长度 ** 
使用关键字`len`可以得到一个`slice`的长度.
```golang 
package main

import "fmt"

func main() {
	cities := []string{
		"Santa Monica",
		"San Diego",
		"San Francisco",
	}
	fmt.Println(len(cities))
	// 3
	countries := make([]string, 42)
	fmt.Println(len(countries))
	// 42
}
``` 

** Nil slices ** 
空`slice`的零值为`nil`, 一个`nil`的`slice` 长度和容量都为0 
```golang 
package main

import "fmt"

func main() {
    var z []int
    fmt.Println(z, len(z), cap(z))
    // [] 0 0
    if z == nil {
        fmt.Println("nil!")
    }
    // nil!
}
```

** 参考更多 ** 
- [Go slices, usage and internals](https://blog.golang.org/go-slices-usage-and-internals)
- [Effective Go - slices](https://golang.org/doc/effective_go.html#slices)
- [Append function documentation](https://golang.org/pkg/builtin/#append)
- [Slice tricks](https://golang.org/pkg/builtin/#append)
- [Effective Go - slices](https://golang.org/doc/effective_go.html#slices)
- [Effective Go - two-dimensional slices](https://golang.org/doc/effective_go.html#two_dimensional_slices)
- [Go by example - slices](https://gobyexample.com/slices)


## 循环slice-Range
循环迭代`slice`或`map`, 用关键字`range`,用`range`关键字可以很方便迭代一个数据结构的所有元素. 
```golang 
package main

import "fmt"

var pow = []int{1, 2, 4, 8, 16, 32, 64, 128}

func main() {
    for i, v := range pow {
        fmt.Printf("2**%d = %d\n", i, v)
    }
}
```

result:
```bash
2**0 = 1
2**1 = 2
2**2 = 4
2**3 = 8
2**4 = 16
2**5 = 32
2**6 = 64
2**7 = 128
```
如果不需要`index` 则可以直接`_` 丢弃即可，如果只需要`index`,则可以不用管返回的`value`参数
```golang 
package main

import "fmt"

func main() {
    pow := make([]int, 10)
    for i := range pow {
        pow[i] = 1 << uint(i)
    }
    for _, value := range pow {
        fmt.Printf("%d\n", value)
    }
}
```

** Break & continue **
可以使用`break`去stop一次迭代
```golang
package main

import "fmt"

func main() {
	pow := make([]int, 10)
	for i := range pow {
		pow[i] = 1 << uint(i)
		if pow[i] >= 16 {
			break
		}
	}
	fmt.Println(pow)
	// [1 2 4 8 16 0 0 0 0 0]
}
```
也可以使用`continue`关键字来跳过一次迭代 
```golang
package main

import "fmt"

func main() {
	pow := make([]int, 10)
	for i := range pow {
		if i%2 == 0 {
			continue
		}
		pow[i] = 1 << uint(i)
	}
	fmt.Println(pow)
	// [0 2 0 8 0 32 0 128 0 512]
}
```
** Range and maps **
`range`关键字同样也可以用于迭代`map`, 但是返回的第一个参数值不是一个递增的索引而是`map`的`key`值.
```golang 
package main

import "fmt"

func main() {
	cities := map[string]int{
		"New York":    8336697,
		"Los Angeles": 3857799,
		"Chicago":     2714856,
	}
	for key, value := range cities {
		fmt.Printf("%s has %d inhabitants\n", key, value)
	}
}
```

the result:
```golang
New York has 8336697 inhabitants
Los Angeles has 3857799 inhabitants
Chicago has 2714856 inhabitants
```
** 练习题 ** 
给定一个名字列表的`slices`, 要求将相同长度的名字，放到同一个`slice`中;输出的结果如下：
```bash
[[] [] [Ava Mia] [Evan Neil Adam Matt Emma] [Emily Chloe]
[Martin Olivia Sophia Alexis] [Katrina Madison Abigail Addison Natalie]
[Isabella Samantha] [Elizabeth]]
```

** 习题解答 ** 
```golang
package main

import "fmt"

var names = []string{"Katrina", "Evan", "Neil", "Adam", "Martin", "Matt",
	"Emma", "Isabella", "Emily", "Madison",
	"Ava", "Olivia", "Sophia", "Abigail",
	"Elizabeth", "Chloe", "Samantha",
	"Addison", "Natalie", "Mia", "Alexis"}

func main() {
	var maxLen int
	for _, name := range names {
		if l := len(name); l > maxLen {
			maxLen = l
		}
	}
	output := make([][]string, maxLen)
	for _, name := range names {
		output[len(name)-1] = append(output[len(name)-1], name)
	}

	fmt.Printf("%v", output)
}
```
- 为了避免插入越界, 需要申请一个足够大的`slice`,但是并不需要申请一个过于大的`slice`,这是为什么我们首选获得最长的`name`的`length`, 并且以这个`length`作为输出`slice`的长度.因为`slice`是从索引0开始的，所以插入时需要获取`name`的长度减一。


## Maps 

`Go`语言中的`Map`数据结构类似于其它语言中的`字典`或`hashes`。
一个`Map`就是一个`key-values`值对，下面将演员的名字作为`Map`的`key`, 年龄作为`Map`的`values`. 
```golang 
package main

import "fmt"

func main() {
	celebs := map[string]int{
		"Nicolas Cage":       50,
		"Selena Gomez":       21,
		"Jude Law":           41,
		"Scarlett Johansson": 29,
	}

	fmt.Printf("%#v", celebs)
}
```

the result: 
```golang 
map[string]int{"Nicolas Cage":50, "Selena Gomez":21, "Jude Law":41,
    "Scarlett Johansson":29}
```
`Map`在使用前，必需先用`make`关键字初始化，否在不能使用，也不能添加值. 
```golang 
package main

import "fmt"

type Vertex struct {
	Lat, Long float64
}

var m map[string]Vertex

func main() {
	m = make(map[string]Vertex)
	m["Bell Labs"] = Vertex{40.68433, -74.39967}
	fmt.Println(m["Bell Labs"])
}
```

在使用`Map`，如果顶层类型只是一个类型名，那么在初始化赋值时可以省略它
```golang
package main

import "fmt"

type Vertex struct {
	Lat, Long float64
}

var m = map[string]Vertex{
	"Bell Labs": {40.68433, -74.39967},
	// same as "Bell Labs": Vertex{40.68433, -74.39967}
	"Google": {37.42202, -122.08408},
}

func main() {
	fmt.Println(m)
}
```

** Maps基本操作 **
插入或更新`map`中的元素
```golang
m[key]=elem
```
获取元素
```golang
elem=m[key]
```
删除一个元素
```golang
delete(m,key)
```
测试是否存在某个值
```golang
elem, ok = m[key]
```
如果`m`中存在`key`,  则`ok`返回`true` ,否则返回`false`表示不存在,并且`elem`是`map`相应数据类型的零值.

** 参考更多 **
- [Go team blog post on maps](https://blog.golang.org/go-maps-in-action)
- [Effective Go - maps](https://golang.org/doc/effective_go.html#maps)

** 练习题  **
实现单词统计 
```golang
package main

import (
    "code.google.com/p/go-tour/wc"
)

func WordCount(s string) map[string]int {
    return map[string]int{"x": 1}
}

func main() {
    wc.Test(WordCount)
}
```

应该返回一个`map`,包含每个单词的长度值和单词的映像关系.

** 解决方案 ** 
```golang 
package main

import (
	"code.google.com/p/go-tour/wc"
	"strings"
)

func WordCount(s string) map[string]int {
	words := strings.Fields(s)
	count := map[string]int{}
	for _, word := range words {
		count[word]++
	}
	return count
}

func main() {
	wc.Test(WordCount)
}
```



