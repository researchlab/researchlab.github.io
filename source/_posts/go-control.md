---
title: "[译]GO BOOTCAMP 第五章：控制流程"
date: 2016-01-21 11:33:49
categories: go-bootcamp
tags: [golang]
description:
---

`Go`语言中主要有三种控制流程`if`,`for`循环,`switch case`语句。 
<!--more-->

## if 声明
`Go`中的`if`声明，除了不需要`()`和必需`{}`之外，其它跟`C`或`Java`类似的。 像`for`语句一样,`if`语句可以在条件执行语句前有一个简短的声明,在`if`声明中声明的参数，其作用仅限于`if`语句体。在`if`语句体中声明的变量，有效作用域也仅限于本语句体.

`if`声明示例
```golang
if answer != 42 {
    return "Wrong answer"
	}
```

`if`简短初始化声明示例
```golang
if err := foo(); err != nil {
    panic(err)
	}
```

## for循环 
`Go`语言中只有一个循环结构，`for`循环. 基本的`for`循环体与`C`或`Java`语言类似,只是不需要`()`,必需`{}`. 并且和在`C`和`Java`中一个，可以给前置条件和后置声明留空. 
```golang
sum := 0
for i := 0; i < 10; i++ {
    sum += i
	}
```

前置条件和后置声明赋空示例
```golang
sum := 1
for ; sum < 1000; {
    sum += sum
	}
```

`for`完成`while`功能
```golang
sum := 1
for sum < 1000 {
    sum += sum
	}
```

无限循环示例
```golang
for {
  // do something in a loop forever
}
```

## Switch case 声明 

多数开发语言都有`Switch case`控制流程，用于避免复杂的`if else`语句
```golang 
package main

import (
	"fmt"
		"time"
		)

		func main() {
			now := time.Now().Unix()
				mins := now % 2
					switch mins {
						case 0:
								fmt.Println("even")
									case 1:
											fmt.Println("odd")
												}
												}
```

但是`Go`语言中的`Switch case`还是有如下差别的

- 只能对同类型数据进行比对
- 如果所有`case`都没有命中的化，可以设置一个`default`语句执行默认的操作.
- 可以在`case`声明中使用表达式，例如可以在声明中计算某个值

```golang
package main

import "fmt"

func main() {
	num := 3
		v := num % 2
			switch v {
				case 0:
						fmt.Println("even")
							case 3 - 2:
									fmt.Println("odd")
										}
										}
```

也可以在一个`case`声明中放多个条件值
```golang
package main

import "fmt"

func main() {
	score := 7
	switch score {
	case 0, 1, 3:
		fmt.Println("Terrible")
	case 4, 5:
		fmt.Println("Mediocre")
	case 6, 7:
		fmt.Println("Not bad")
	case 8, 9:
		fmt.Println("Almost perfect")
	case 10:
		fmt.Println("hmm did you cheat?")
	default:
		fmt.Println(score, " off the chart")
	}
}
```
还可以通过关键字`fallthrough`来使得同一个条件执行多个的`case`

```golang 
package main

import "fmt"

func main() {
	n := 4
	switch n {
	case 0:
		fmt.Println("is zero")
		fallthrough
	case 1:
		fmt.Println("is <= 1")
		fallthrough
	case 2:
		fmt.Println("is <= 2")
		fallthrough
	case 3:
		fmt.Println("is <= 3")
		fallthrough
	case 4:
		fmt.Println("is <= 4")
		fallthrough
	case 5:
		fmt.Println("is <= 5")
		fallthrough
	case 6:
		fmt.Println("is <= 6")
		fallthrough
	case 7:
		fmt.Println("is <= 7")
		fallthrough
	case 8:
		fmt.Println("is <= 8")
		fallthrough
	default:
		fmt.Println("Try again!")
	}
}
```
the result: 
```bash
is <= 4
is <= 5
is <= 6
is <= 7
is <= 8
Try again!
```

也可以使用`break`关键字退出`switch case`
```golang 
package main

import (
	"fmt"
	"time"
)

func main() {
	n := 1
	switch n {
	case 0:
		fmt.Println("is zero")
		fallthrough
	case 1:
		fmt.Println("<= 1")
		fallthrough
	case 2:
		fmt.Println("<= 2")
		fallthrough
	case 3:
		fmt.Println("<= 3")
		if time.Now().Unix()%2 == 0 {
			fmt.Println("un pasito pa lante maria")
			break
		}
		fallthrough
	case 4:
		fmt.Println("<= 4")
		fallthrough
	case 5:
		fmt.Println("<= 5")
	}
}
```

the result:
```bash
<= 1
<= 2
<= 3
un pasito pa lante maria
```

** 练习题 **

将50个硬币分给10个用户： Matthew, Sarah, Augustus, Heidi, Emilie, Peter, Giana, Adriano, Aaron, Elizabeth; 硬币根据名字中包含的元音来分配，分配规则：
a: 1 coin e: 1 coin i: 2 coins o: 3 coins u: 4 coins

并且每个用户最多不能超过10个硬币, 打印这个map, 用户的名字为`key`, 分得的硬币为`value`. 分完所以硬币之后， 应该还有两个硬币剩余.

预期输出结果:
```bash
map[Matthew:2 Peter:2 Giana:4 Adriano:7 Elizabeth:5 Sarah:2 Augustus:10 Heidi:5 Emilie:6 Aaron:5]
Coins left: 2
``` 

注意`Go`中的`map`是无序的，但是最终的输出结果应该跟上面是一样的.

开始代码
```golang
package main

import "fmt"

var (
	coins = 50
	users = []string{
		"Matthew", "Sarah", "Augustus", "Heidi", "Emilie",
		"Peter", "Giana", "Adriano", "Aaron", "Elizabeth",
	}
	distribution = make(map[string]int, len(users))
)

func main() {
	fmt.Println(distribution)
	fmt.Println("Coins left:", coins)
}
```

** 练习题解答 ** 

```golang
package main

import "fmt"

var (
	coins = 50
	users = []string{
		"Matthew", "Sarah", "Augustus", "Heidi", "Emilie",
		"Peter", "Giana", "Adriano", "Aaron", "Elizabeth",
	}
	distribution = make(map[string]int, len(users))
)

func main() {
	coinsForUser := func(name string) int {
		var total int
		for i := 0; i < len(name); i++ {
			switch string(name[i]) {
			case "a", "A":
				total++
			case "e", "E":
				total++
			case "i", "I":
				total = total + 2
			case "o", "O":
				total = total + 3
			case "u", "U":
				total = total + 4
			}
		}
		return total
	}

	for _, name := range users {
		v := coinsForUser(name)
		if v > 10 {
			v = 10
		}
		distribution[name] = v
		coins = coins - v
	}
	fmt.Println(distribution)
	fmt.Println("Coins left:", coins)
}
```
