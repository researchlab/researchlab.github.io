---
title: "安装golang工具包软件" 
date: 2016-12-19 00:18:37
categories: [golang]
tags: [golang]
description:
---

## 前言
golang tool chains 提供了很多好用的工具， 但是如果直接安装的话，大多数需要翻墙才能安装， 而且比较麻烦； 本文记录一种不需要翻墙就能顺利安装相应的工具

<!--more-->

## 安装
不需要翻墙安装相应的golang tool chains，具体步骤如下:
1. 假设`GOPATH=/path/to/proj_go/`,在`/path/to/proj_go/src/`目录下新建`golang.org/x/`目录，进入`/path/to/proj_go/src/golang.org/x/`目录下载`tools`目录，下载命令如下:
```bash
$git clone https://github.com/golang/tools.git 
```
2. 通过`go install`命令直接安装相应的tools, 比如安装`guru`工具，
$cd `/path/to/proj_go/bin`目录， 然后安装`go install ../src/golang.org/x/tools/cmd/guru` 直接安装即可， 

3. 同样的方法也可以安装`tools`下得任何工具.
