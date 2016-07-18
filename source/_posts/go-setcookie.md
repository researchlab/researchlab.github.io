---
title: "go http client/server 设置cookie小结" 
date: 2016-07-10 16:51:56
categories: [golang]
tags: [golang, setcookie, net/http]
description:
---

## 前言

<!--more-->

## golang中cookie 详细定义

golang 官方文档中对`Cookie`结构的定义
```golang
type Cookie struct {
    Name       string
    Value      string
    Path       string
    Domain     string
    Expires    time.Time
    RawExpires string
    // MaxAge=0表示未设置Max-Age属性
    // MaxAge<0表示立刻删除该cookie，等价于"Max-Age: 0"
    // MaxAge>0表示存在Max-Age属性，单位是秒
    MaxAge   int
    Secure   bool
    HttpOnly bool
    Raw      string
    Unparsed []string // 未解析的“属性-值”对的原始文本
}
```

`Cookie`代表一个出现在`HTTP回复的头域`中`Set-Cookie头的值里`或者`HTTP请求的头域`中Cookie头的值里的HTTP cookie。

- `Expires` – 过期时间。指定cookie的生命期。具体是值是过期日期。如果想让cookie的存在期限超过当前浏览器会话时间，就必须使用这个属性。当过了到期日期时，浏览器就可以删除cookie文件，没有任何影响。

- `Path` – 路径。指定与cookie关联的WEB页。值可以是一个目录，或者是一个路径。如果/head/index.html 建立了一个cookie，那么在/head/目录里的所有页面，以及该目录下面任何子目录里的页面都可以访问这个cookie。这就是说，在/head/stories/articles 里的任何页面都可以访问/head/index.html建立的cookie。但是，如果/zdnn/ 需要访问/head/index.html设置的cookes，该怎么办?这时，我们要把cookies的path属性设置成“/”。在指定路径的时候，凡是来自同一服务器，URL里有相同路径的所有WEB页面都可以共享cookies。现在看另一个例子：如果想让 /head/filters/ 和/head/stories/共享cookies，就要把path设成“/head”。

- `Domain` – 域。指定关联的WEB服务器或域。值是域名，比如goaler.com。这是对path路径属性的一个延伸。如果我们想让dev.mycompany.com 能够访问bbs.mycompany.com设置的cookies，该怎么办? 我们可以把domain属性设置成“mycompany.com”，并把path属性设置成“/”。FYI：不能把cookies域属性设置成与设置它的服务器的所在域不同的值。

- `Secure` – 安全。指定cookie的值通过网络如何在用户和WEB服务器之间传递。这个属性的值或者是“secure”，或者为空。缺省情况下，该属性为空，也就是使用不安全的HTTP连接传递数据。如果一个 cookie 标记为secure，那么，它与WEB服务器之间就通过HTTPS或者其它安全协议传递数据。不过，设置了secure属性不代表其他人不能看到你机器本地保存的cookie。换句话说，把cookie设置为secure，只保证cookie与WEB服务器之间的数据传输过程加密，而保存在本地的cookie文件并不加密。如果想让本地cookie也加密，得自己加密数据。当设置为true时，表示创建的 Cookie 会被以安全的形式向服务器传输，也就是只能在 HTTPS 连接中被浏览器传递到服务器端进行会话验证，如果是 HTTP 连接则不会传递该信息，所以不会被窃取到Cookie 的具体内容。

- `HttpOnly`属性,如果在Cookie中设置了"HttpOnly"属性，那么通过程序(JS脚本、Applet等)将无法读取到Cookie信息，这样能有效的防止XSS攻击。

- `secure`属性是防止信息在传递的过程中被监听捕获后信息泄漏，`HttpOnly`属性的目的是防止程序获取cookie后进行攻击。

** 参考更多 **
- [中文维基 - Cookie](https://zh.wikipedia.org/wiki/Cookie)
- [英文维基 - Http-Cookie](https://en.wikipedia.org/wiki/HTTP_cookie#Session_management)

## client 端设置cookie

客户端设置cookie,很简单
```golang
// client  set cookie
cookie := http.Cookie{Name: "clientcookieid", Value: "121", Expires: time.Now().Add(111 * time.Second)}
req.AddCookie(&cookie)
```
或者
```golang
req.AddCookie(&http.Cookie{
	Name:    "clientcookieid2",
	Value:   "id2",
	Expires: time.Now().Add(111 * time.Second),
})
```
## server端接收cookie
后端接收cookie有两种方式,如果是指定cookie的名字，只要取得1个或少数几个cookie, 可以用如下方式获取
```golang
client_cookie, _ := r.Cookie("clientcookieid")

fmt.Printf("%+v\n", client_cookie)
fmt.Println(client_cookie.Name, clinet_cookie.Value) // 通过点运算符获取client_cookie的属性
```

如果指定了多个cookie值对，则可以通过迭代的方式访问
```golang
for _, v := range r.Cookies() {
	fmt.Printf("%+v\n", v)
}
```
## server端设置cookie
server端设置cookie 和client端设置cookie类似，不同的是 server端用的是`http.SetCookie`, 而client端用的是`req.AddCookie`
```golang
http.SetCookie(w, &http.Cookie{
	Name:    "servercookie",
	Value:   "servercookievalue",
	Expires: time.Now().Add(111 * time.Second),
})
http.SetCookie(w, &http.Cookie{
	Name:    "servercookie2",
	Value:   "servercookievalue2",
	Expires: time.Now().Add(111 * time.Second),
})
```
## client 端接收cookie
golang client端接收cookie 只能通过迭代的方式获取
```golang
for _, v := range resp.Cookies() {
	fmt.Printf("%+v\n", v)
}
```

[完整示例代码](https://github.com/researchlab/golearning/tree/master/setcookie)

