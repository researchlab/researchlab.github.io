---
title: "golang 格式化时间总结"
date: 2016-06-14 14:05:28
categories: [golang]
tags: [golang, time]
description:
---

`golang` 中经常需要格式化时间和日期来满足不同的业务需求,下面总结格式化时间日期中遇到的问题。
<!--more-->

## golang time包 时间日期格式化定义

go 的time package 提供了time.Format函数，用来对时间进行格式化输出;类似的还有time.Parse用来解析字符串类型的时间到time.Time。这是两个互逆的函数。

** 下面看`golang`中`time`包对于时间的详细定义 **
- 月份 1,01,Jan,January
- 日　 2,02,_2
- 时　 3,03,15,PM,pm,AM,am
- 分　 4,04
- 秒　 5,05
- 年　 06,2006
- 时区 -07,-0700,Z0700,Z07:00,-07:00,MST
- 周几 Mon,Monday

** 比如小时的表示(原定义是下午3时，也就是15时) **
- 3 用12小时制表示，去掉前导0
- 03 用12小时制表示，保留前导0
- 15 用24小时制表示，保留前导0
- 03pm 用24小时制am/pm表示上下午表示，保留前导0
- 3pm 用24小时制am/pm表示上下午表示，去掉前导0

** 又比如月份 **

- 1 数字表示月份，去掉前导0
- 01 数字表示月份，保留前导0
- Jan 缩写单词表示月份
- January 全单词表示月份


## 时间日期格式化

- 本地当期时间

```golang 
fmt.Println(time.Now()) //2016-07-14 14:27:28.214512532 +0800 CST
```

- 时间格式化

```golang 
fmt.Println(time.Now().Format("3:04:05.000 PM Mon Jan"))            // 2:27:05.702 PM Thu Jul
fmt.Println(time.Now().Format("2006-01-_2 3:04:05.000 PM Mon Jan")) // 2016-07-14 2:54:11.442 PM Thu Jul
fmt.Println(time.Now().Format("2006-01-02 15:04:05"))  // 2016-07-14 14:54:11.442239513 +0800 CST 
```

- 本地当前时间戳(10位)

```golang
fmt.Println(time.Now().Unix()) //1468479251
```

- 本地当前时间戳(19位)

```golang
fmt.Println(time.Now().UnixNano()) //1468480006774460462
```

- 时间戳转时间 

```golang
fmt.Println(time.Unix(1389058332, 0).Format("2006-01-02 15:04:05")) //2014-01-07 09:32:12
```

- 时间转时间戳

```golang
fmt.Println(time.Date(2014, 1, 7, 5, 50, 4, 0, time.Local).Unix())
```

- 时间转换为UTC时间和本地时间( UTC:零时区 +0000， China: 东八区 +0800)

```golang
dateStr := "2016-07-14 14:24:51" 
timestamp1, _ := time.Parse("2006-01-02 15:04:05", dateStr)
timestamp2, _ := time.ParseInLocation("2006-01-02 15:04:05", dateStr, time.Local)
fmt.Println(timestamp1, timestamp2)               //2016-07-14 14:24:51 +0000 UTC 2016-07-14 14:24:51 +0800 CST 
fmt.Println(timestamp1.Unix(), timestamp2.Unix()) //1468506291 1468477491 

now := time.Now()                
year, mon, day := now.UTC().Date()
hour, min, sec := now.UTC().Clock()
zone, _ := now.UTC().Zone()     
fmt.Printf("UTC 时间是 %d-%d-%d %02d:%02d:%02d %s\n",         
    year, mon, day, hour, min, sec, zone) // UTC 时间是 2016-7-14 07:06:46 UTC
                                                           
year, mon, day = now.Date()
hour, min, sec = now.Clock()
zone, _ = now.Zone()
fmt.Printf("本地时间是 %d-%d-%d %02d:%02d:%02d %s\n",
    year, mon, day, hour, min, sec, zone) // 本地时间是 2016-7-14 15:06:46 CST 
```
