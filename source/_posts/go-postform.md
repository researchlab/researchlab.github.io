---
title: "Golang发送post表单请求"
date: 2016-09-07 16:00:32
categories: [golang]
tags: [form, post]
description:
---

golang这边将`map`结构序列化通常采用`json.Marshal`和`json.Unmarshal`来做，但是在php server端还需要做`json`反序列化解析才能用， 用golang模拟表单提交, php server端则非常方便提取相应的数据字段. 
<!--more-->

## 方法

方法是利用golang`net/http`包提供的`PostForm`提交post表单提交。`ParseForm`解析`URL`中的查询字符串，并将解析结果更新到`r.Form`字段。对于`POST`或`PUT`请求，`ParseForm`还会将`body`当作表单解析，并将结果既更新到`r.PostForm`也更新到`r.Form`。解析结果中，`POST`或`PUT`请求主体要优先于`URL`查询字符串（同名变量，主体的值在查询字符串的值前面）。如果请求的主体的大小没有被`MaxBytesReader`函数设定限制，其大小默认限制为开头10MB。

## http.Client{}.PostForm

利用`http.Client{}.PostForm`提交post表单。

```golang
import "net/http"
client := &http.Client{}
res, err := client.PostForm("http://127.0.0.1:8091/postpage", url.Values{
	"key":   {"this is client key"},
	"value": {"this is client value"},
})
```

## http.PostForm

直接用`http.PostForm`提交post表单。

```golang
import "net/http"
//data := make(url.Values)
//data["key"] = []string{"this is key"}
//data["value"] = []string{"this is value"}

//把post表单发送给目标服务器
res, err := http.PostForm("http://127.0.0.1:8091/postpage", url.Values{
	"key":   {"this is url key"},
	"value": {"this is url value"},
})
```

## 对表单数据的提取
server端对表单数据的提取
```golang
//接受post请求， 然后打印表单中key和value字段的值
if r.Method == "POST" {
	var (
		key   string = r.PostFormValue("key")
		value string = r.PostFormValue("value")
	)
```

[github示例代码](https://github.com/researchlab/golearning/tree/master/postform)
