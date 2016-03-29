---
title: "gin中使用设置cookie过期时间总结"
date: 2016-03-29 01:48:56
categories: [golang]
tags: [golang,gin,setcookie]
description:
---

## 前言
可以操作`Cookie`的`Http`头有两个:`Set-Cookie`和`Cookie`。`Set-Cookie`由服务器发送，它包含在响应请求的头部中。它用于在客户端创建一个`Cookie`。`Cookie`头由客户端发送，包含在`HTTP`请求的头部中。<font color=red>**注意：1.只有cookie的domain和path与请求的URL匹配才会发送这个cookie;2.客户端发送cookie信息给服务器只发送键-值对到服务器，cookie的属性是不会发送给服务器的。**</font>
<!--more-->

## 试验需求
1.服务器给客户端设置cookie，并设置过期时间，客户端每次请求服务器时如果cookie没有过期，则服务器将cookie相应的value 加1并重设cookie, 如果cookie 过期，则重新设置cookie让value 从0开始计数。

## 试验代码
```golang
package main

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"net/http"
	"strconv"
	"time"
)

func main() {
	r := gin.Default()
	r.Use(Counter()) //这个是每个请求都会执行Counter()这个方法，

	r.GET("/counter", func(c *gin.Context) {
		if cookie, err := c.Request.Cookie("counter"); err == nil {
			c.String(http.StatusOK, cookie.Expires.String())
		} else {
			http.SetCookie(c.Writer, &http.Cookie{
				Name:    "counter",
				Value:   "",
				Expires: time.Now().Add(10 * time.Second),
			})
			c.String(http.StatusOK, "SetCookie ok")

		}
	})
	fmt.Println("server start from 8010")
	r.Run(":8010")
}

func Counter() gin.HandlerFunc {
	return func(c *gin.Context) {
		if cookie, err := c.Request.Cookie("counter"); err == nil {
			value := cookie.Value
			if len(value) == 0 {
				cookie.Value = "0"
			} else {
				if v, err := strconv.Atoi(value); err == nil {
					i := v + 1
					cookie.Value = fmt.Sprintf("%d", i)
				}
			}
			http.SetCookie(c.Writer, cookie)
			//before request
			c.Next()
			//after request
			c.String(http.StatusOK, " counter:"+cookie.Value)
		}
	}
}
```
## 代码分析
上述代码中`r.Use(Counter())`表示客户端每次发送一个请求给服务器，都会执行`Counter()`这个函数。比如客户端发送一个`http://localhost:8010/counter`的请求给服务器，则具体的处理流程为：先执行`Counter()`函数中的`c.Next()`前面的代码，当执行到`c.Next()`时， 先去执行`r.GET("/counter",func(c *gin.Context) {xxx}`中`xxx`程序体，当`xxx`程序体执行完之后，再执行`Counter()`函数中`c.Next()`之后的程序体，然后整个请求执行完毕。

回到上面的试验需求，第一次请求时没有cookie，此时服务器设置cookie并设置过期时间，第二次请求时如果还没有过期则在Counter中就能查到cookie,此时通过`Counter()`重新设置cookie, 但是注意：这里设置的cookie，因为Name与之前的cookie是一样的，所以此次设置的cookie的属性会覆盖之前的cookie的属性，因为此次只是改变cookie的value，而没有设置cookie的属性，所以此次设置cookie没有过期时间可言了。所以上述的试验需求是不合理的。或者说可以通过`redis`的操作去实现，但是不能仅靠设置`cookie`来实现这个需求。


## 总结

**服务器发送cookie给客户端**
 从服务器端，发送cookie给客户端，是对应的Set-Cookie。包括了对应的cookie的名称，值，以及各个属性。
 例如：
Set-Cookie: lu=Rg3vHJZnehYLjVg7qi3bZjzg; Expires=Tue, 15 Jan 2013 21:47:38 GMT; Path=/; Domain=.169it.com; HttpOnly
Set-Cookie: made_write_conn=1295214458; Path=/; Domain=.169it.com
Set-Cookie: reg_fb_gate=deleted; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Path=/; Domain=.169it.com; HttpOnly

**从客户端把cookie发送到服务器**
 从客户端发送cookie给服务器的时候，是不发送cookie的各个属性的，而只是发送对应的名称和值。
 例如：
GET /spec.html HTTP/1.1  
Host: www.example.org  
Cookie: name=value; name2=value2  
Accept: */*  

<font color=red>除了name=value对以外，我们还可以设置Cookie其他属性以支持更丰富的Cookie需求，**这些属性通常是浏览器用来判断如何对待cookie，何时删除、屏蔽或者如何发送name-value对给Server。也就是说无论我们设置了某个cookie的多少属性，这些Cookie属性是不会被浏览器发送回给Server的。包括设置的过期时间也不会发送到服务器端**</font>
