---
title: golang reflect使用总结
date: 2016-02-17 08:57:59
categories: golang
tags: [golang,reflect]
description:
---

反射是一种检查存储在接口变量中的`<值,类型>`对的机制，借助go反射包提供的`reflect.TypeOf`和`reflect.ValueOf`可以方便的访问到一个接口值的`reflect.Type`和`reflect.Value`部分，从而可进一步得到这个接口的结构类型和对其进行值的修改操作。 
<!--more-->
## 反射的使用
1. **获取接口对象的字段,类型和方法信息**
先定义个通用的结构体
		type User struct{
			Id int
			Name string
			Age int
		}
将接口对象类型信息映射为反射类型信息
```golang
	func Info(o interface{}) {
		t := reflect.TypeOf(o)         //获取接口的类型
		fmt.Println("Type:", t.Name()) //t.Name() 获取接口的名称
		
		if t.Kind() != refelct.Struct { //通过Kind()来判断反射出的类型是否为需要的类型
			fmt.Println("err: type invalid!")		
			return
		}		

		v := reflect.ValueOf(o) //获取接口的值类型
		fmt.Println("Fields:")
				
		for i := 0; i < t.NumField(); i++ { //NumField取出这个接口所有的字段数量
		f := t.Field(i)                                   //取得结构体的第i个字段
		val := v.Field(i).Interface()                     //取得字段的值
		fmt.Printf("%6s: %v = %v\n", f.Name, f.Type, val) //第i个字段的名称,类型,值
		}

		for i := 0; i < t.NumMethod(); i++{
			m := t.Method(i)
			fmt.Printf("%6s: %v\n", m.Name,m.Type) //获取方法的名称和类型	   
		}
	}	
``` 
获取接口对象的类型名称，通过`refelct.TypeOf()`获取接口对象的类型,并通过`Name()`方法获取接口的名称。
获取对象中所有字段的名称,类型和值,通过`reflect.ValueOf()`获取接口对象的值类型取得字段的名称和类型,然后通过`v.Field(i).Interface()`取得第i个字段的值。
还可以通过`NumMethod()`循环获取接口对象所有方法的名称和类型。
[示例代码](https://github.com/researchlab/golearning/blob/master/reflect/01reflect.go)

2. **反射接口对象中的匿名或嵌入字段信息**
先再添加一个Manager结构,User作为它的匿名字段
		type Manager struct{
			User
			title string
		}
初始化Manager的两种方法：
		m0 := Manager{User: User{1,"Mike",11},title: "Man"}
		m1 := Manager{User{1,"Mike",11},"Man"} //这种初始化,赋值顺序必须和结构体中的声明顺序相同! 
现在如何来取出Manager中的匿名字段User？
		t := refelct.TypeOf(m)
		fmt.Printf("%#v\n", t.Field(0))
如上述代码，通过`t := refelct.TypeOf(m)`将Manager的字段类型取出来,在反射中对象字段是通过索引取到的，所以可通过`t.Field(0)`,
		#reflect.StructField{Name:"User", PkgPath:"", Type:(*reflect.rtype)(0xedd20), Tag:"", Offset:0x0, Index:[]int{0}, Anonymous:true}
还可以通过`FieldByIndex`和`FieldByName`两种方法取得匿名结构体中的字段属性
	1. 给`FieldByIndex()`传入一个int型的slice索引,如`FieldByIndex([]int{0,0})`即取得User结构体中的Id字段。
	2. 通过`FieldByName("Id")`也可以取得User结构体中Id字段。


## 通过反射修改对象
上面通过`reflect.TypeOf`和`reflect.ValueOf`已经可以得到接口对象的类型,字段和方法等属性了，怎么通过反射来修改对象的字段值？

		x := 100
		v := refelct.ValueOf(&x) //传入地址
		v.Elem().SetInt(200) //成功修改x值为200
要修改变量x的值，首先就要通过`reflect.ValueOf`来获取x的值类型,`refelct.ValueOf`返回的值类型是变量x一份值拷贝,要修改变量x就要传递x的地址,从而返回x的地址对象,才可以进行对x变量值对修改操作。在得到x变量的地址值类型之后先调用`Elem()`返回地址指针指向的值的Value封装。然后通过`Set`方法进行修改赋值。
通过反射可以很容易的修改变量的值，怎么来修改结构体中的字段值？

		func SetInfo(o interface{}) {
				v := reflect.ValueOf(o)
		
				if v.Kind() == reflect.Ptr && !v.Elem().CanSet() { //判断是否为指针类型 元素是否可以修改
					fmt.Println("cannot set")
						return
				} else {
					v = v.Elem() //实际取得的对象
				}
		
				//判断字段是否存在
				f := v.FieldByName("Name")
				if !f.IsValid() {
					fmt.Println("wuxiao")
						return
				}
		
				//设置字段
				if f := v.FieldByName("Name"); f.Kind() == reflect.String {
					f.SetString("BY")
				}
		}
要成功修改结构体中的某个字段,主要进行以下操作：
1. 首先要反射出这个字段的地址值类型;
2. 判断反射返回类型是否为`reflect.Ptr`指针类型（通过指针才能操作对象地址中的值)同时还要判断这个元素是否可以修改;
3. 通过`FieldByName`的返回值判断字段是否存在
4. 通过`Kind()`和`Set`来修改字段的值
[示例代码](https://github.com/researchlab/golearning/blob/master/reflect/02reflect.go)

## 通过反射“动态”调用方法
现在已经可以通过反射获取并修改接口对象的字段，类型等信息了，那怎么通过反射“动态”调用接口对象等方法？
先为`User`结构体引入一个`Hello`方法：

		func (u User) Hello(m User) (int, string) {
			fmt.Println("Hello", m.Name, ", I'm ", u.Name)
			return m.Age + u.Age, u.Name
		}

下面通过反射来调用`Hello`这个方法：

		func GetInfo(u interface{}) {
			m := User{2, "Json", 12}
		
			v := reflect.ValueOf(u)
		
			if v.Kind() != reflect.Struct {
				fmt.Println("type invalid")
				return
			}
		
			mv := v.MethodByName("Hello") //获取对应的方法
			if !mv.IsValid() {            //判断方法是否存在
				fmt.Println("Func Hello not exist")
				return
			}
		
			args := []reflect.Value{reflect.ValueOf(m)} //初始化传入等参数，传入等类型只能是[]reflect.Value类型
			res := mv.Call(args)
			fmt.Println(res[0], res[1])
		
		}
通过`MethodByName`先获取对象的`Hello`方法,然后准备要传入的参数,这里传入的参数必须是`[]refelct.Value`类型,传入的参数值必须强制转换为反射值类型`refelct.Value`。
最后通过调用`Call`方法就可以实现通过反射"动态"调用对象的方法。
[示例代码](https://github.com/researchlab/golearning/blob/master/reflect/03reflect.go)

## 小结
- 通过反射包提供`refelct.TypeOf`和`refelct.ValueOf`方法获得接口对象的类型，值和方法等。
- 通过反射修改字段值等时候需要传入地址类型，并且需要检查反射返回值类型是否为`refelct.Ptr`，检查字段是否`CanSet`,检查字段是存在,然后通过`Kind()`来帮助赋值相应对类型值。
- 最后总结了通过`MethodByName`等方法如何“动态”调用对象的方法，示例代码也演示了如何传入和接收多个参数值。
