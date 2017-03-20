---
title: "浏览器刷新后input输入框依旧保留原值不被清空"
date: 2016-07-10 18:22:43
categories: javascript
tags: [setcookie, getcookie]
description:
---

## 前言
html页面中的input框如果在浏览器刷新前有值，怎么在刷新后依然保留这个值不被清空呢？下面用`setCookie`的方案来解决这个问题.
<!--more-->
首选判断input框中有值时,`setcookie`, 每次刷新浏览器时，读取`Cookie`值,如果存在`Cookie`值，则用此值初始化input值。

## 纯js实现

### 设置Cookie

```javascript
/*
* @cname  cookie name 
* @cvalue cookie value 
* @ exdays cookie expires(天)
*/
function setCookie(cname,cvalue,exdays)
{
	if(!(document.cookie || navigator.cookieEnabled))
	{
		console.log('浏览器 cookie 未打开!');
	} 

	var d = new Date();
	d.setTime(d.getTime()+(exdays*24*60*60*1000));
	var expires = "expires="+d.toGMTString();
	document.cookie = cname+"="+cvalue+"; "+expires;
}
```

### 获取Cookie

```javascript
function getCookie(cname)
{
	var name = cname + "=";
	var ca = document.cookie.split(';');
	for(var i=0; i<ca.length; i++) 
	  {
	  var c = ca[i].trim();
	  if (c.indexOf(name)==0) return c.substring(name.length,c.length);
	  }
	return "";
}
```

根据`cname` 获取相应的cookie值， cookie不存在就返回空字符串.

### checkCookie
可以将判断Cookie是否存在的下一步处理逻辑封装到`checkCookie`方法中

```javascript
function checkCookie()
{
	var user=getCookie("username");
	if (user!="")
	  {
		console.log('user', user);	
	  }
	else 
	  {
	  if (user!="" && user!=null)
	    {
	    setCookie("username",user,3000);
	    }
	  }
}
```

## 另一种方式是借助jQuery实现

首选引入jquery相应的库

```html
<script src="http://apps.bdimg.com/libs/jquery.cookie/1.4.1/jquery.cookie.js"></script>
```

## 创建Cookie

如创建一个名为“example”，值为“foo”的cookie：
```javascript
$.cookie("example", "foo");  
```
要设置cookie的有效期，可以设置expires值，如设置cookie的过期时间为10天：

```javascript
$.cookie("example", "foo",{expires:10});  
```

设置cookie一小时后过期：

```javascript
var cookietime = new Date(); 
cookietime.setTime(date.getTime() + (60 * 60 * 1000));//coockie保存一小时 
$.cookie("example", "foo",{expires:cookietime});  
```

要设置cookie的保存路径，可以设置path值，如设置路径为根目录：

```javascript
$.cookie("example", "foo",{path:"/"});  
```

如果要设置路径为/admin，则：

```javascript
$.cookie("example", "foo",{path:"/admin"});  
```

## 获取cookie值

```javascript
$.cookie("example");  
```


## 删除Cookie

使用jQuery删除cookie，只需要将cookie的值为null，注意如果设置值为空的字符串时，并不能删除cookie，只是将cookie值清空而已。
```javascript
$.cookie("example",null);  
```

或者
```javascript 
$.cookie('the_cookie', '', { expires: -1 }); // 删除 cookie 
```

[github源码demo](https://github.com/researchlab/CodeSnippets)
- js-setcookie.html
- jquery-setcookie.html

## 总结
cookie是基于域名来储存的, cookie具有不同域名下储存不可共享的特性。 这也是cookie支持设置`path`和`domain`的作用之一。
所以要测试cookie是否生效，需要放到测试服务器上或者本地localhost服务器上才会生效。<strong><font color=red>单纯的本地一个html页面打开是无效的。</font></strong>

