---
title: "golang server 跨域解决总结" 
date: 2017-01-20 15:30:40
categories: [golang]
tags: [golang]
description:
---

## 前言
server提供api服务直接对接前端js, 但是存在跨域问题，本文使用先查询请求过来的host 然后判断主域名是否存在，存在返回头部设置这个请求域名充许跨域访问。
<!--more-->

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
从上一步获取子域名(scheme + r.Host)之后, 先判断是否存在，并且是否包含主域名，然后设置跨域.
```golang
Origin := r.Header.Get("Origin")
    if 0 != len(Origin) && strings.Contains(Origin, "domain.com"){
        w.Header().Add("Access-Control-Allow-Origin", Origin)
        w.Header().Add("Access-Control-Allow-Methods", "POST,GET,OPTIONS,DELETE")
        w.Header().Add("Access-Control-Allow-Headers", "x-requested-with,content-type")
        w.Header().Add("Access-Control-Allow-Credentials", "true")
    }
```
