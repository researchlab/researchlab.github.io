---
title: "golang server 跨域解决总结" 
date: 2017-01-20 15:30:40
categories: [golang]
tags: [golang]
description:
---

## 前言
server提供api服务直接对接前端js, 但是存在跨域问题，本文使用先查询请求过来的host 然后判断主域名是否存在，存在,则在返回头部设置这个请求域名充许跨域访问。
<!--more-->

## 跨域概念

浏览器的同源策略，出于防范跨站脚本的攻击，禁止客户端脚本（如 JavaScript）对不同域的服务进行跨站调用。

一般的，只要网站的 协议名protocol 、 主机host 、 端口号port 这三个中的任意一个不同，网站间的数据请求与传输便构成了跨域调用。

一般的，发起跨域请求而没有被设置许可跨域时，则会返回类型下面的说明

<center>![cross-website](/imgs/cross-website.png)</center>

上面返回提示说明: 跨域请求并非是浏览器限制了发起跨站请求，而是请求可以正常发起，到达服务器端，但是服务器返回的结果会被浏览器拦截。

## 获取完整url

查阅了r *http.Request对象中的所有属性，没有发现可以直接获取完整的url的方法。于是尝试根据host和请求地址进行拼接。在golang中可以通过r.Host获取hostname，r.RequestURI获取相应的请求地址。

但是还少一个协议的判断，怎么区分是http和https呢？一开始尝试通过r.Proto属性判断，但是发现该属性不管是http，还是https都是返回HTTP/1.1，又寻找了下发现TLS属性，在https协议下有对应值，在http下为nil。

```golang
package main
 
import (
    "fmt"
    "log"
    "net/http"
    "strings"
)
 
func index(w http.ResponseWriter, r *http.Request) {
    fmt.Println(r.Proto)
    // output:HTTP/1.1
    fmt.Println(r.TLS)
    // output: <nil>
    fmt.Println(r.Host)
    // output: localhost:9090
    fmt.Println(r.RequestURI)
    // output: /index?id=1
 
    scheme := "http://"
    if r.TLS != nil {
        scheme = "https://"
    }
    fmt.Println(strings.Join([]string{scheme, r.Host, r.RequestURI}, ""))
    // output: http://localhost:9090/index?id=1
}
 
func main() {
    http.HandleFunc("/index", index)
 
    err := http.ListenAndServe(":9090", nil)
    if err != nil {
        log.Fatal("ListenAndServe: ", err)
    }
}
```

## 动态许可跨域

1.直接取头部的`Origin`字段， 如果取到， 则判断是否包含主域名，然后设置跨域，如果`Origin`字段为空不存在，则转下面第2步;
2.获取子域名(scheme + r.Host)之后, 先判断是否存在，并且是否包含主域名，然后设置跨域, 如果`r.Host`字段为空， 则转下面第3步;
3.获取子域名(scheme + r.URL.Host)之后， 判断是否存在， 并且是否包含主域名， 然后设置跨域，

还有一种方法是利用redis缓存，同样通过上述三个方法获取子域名， 然后查询redis缓存是否存在这个域名，如果有则设置许可跨域; redis缓存的数据来源是 另外准备一个后台，当后台有修改许可跨域网站时，写完db(mysql)的同时先清空缓存，然后在回填缓存即可。


```golang
Origin := r.Header.Get("Origin")
    if 0 != len(Origin) && strings.Contains(Origin, "domain.com"){
        w.Header().Add("Access-Control-Allow-Origin", Origin)
        w.Header().Add("Access-Control-Allow-Methods", "POST,GET,OPTIONS,DELETE")
        w.Header().Add("Access-Control-Allow-Headers", "x-requested-with,content-type")
        w.Header().Add("Access-Control-Allow-Credentials", "true")
    }
```

更多参考[前端跨域请求原理与实践](http://www.open-open.com/lib/view/open1473667695212.html)
