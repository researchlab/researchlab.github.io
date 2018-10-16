---
title: "html 美化输出 json 字符串" 
date: 2016-06-17 10:55:21
categories: javascript
tags: [json, html]
description:
---

`json`字符串在html用js美化输出使用总结。
<!--more-->


##  JSON.stringify()函数原型

**语法：** 
　　`JSON.stringify(value [, replacer] [, space]) `

`value`：是必选字段。就是你输入的对象，比如数组，类等。 
`replacer`：这个是可选的。它又分为2种方式，一种是数组，第二种是方法。 
　　情况一：`replacer`为数组时，通过后面的实验可以知道，它是和第一个参数`value`有关系的。一般来说，系列化后的结果是通过键值对来进行表示的。 所以，如果此时第二个参数的值在第一个存在，那么就以第二个参数的值做`key`，第一个参数的值为`value`进行表示，如果不存在，就忽略。

　　情况二：`replacer`为方法时，那很简单，就是说把系列化后的每一个对象（记住是每一个）传进方法里面进行处理。 

`space`：就是用什么来做分隔符的。 
　　1）如果省略的话，那么显示出来的值就没有分隔符，直接输出来 。
　　2）如果是一个数字的话，那么它就定义缩进几个字符，当然如果大于10 ，则默认为10，因为最大值为10。
　　3）如果是一些转义字符，比如`\t`，表示回车，那么它每行一个回车。 
　　4）如果仅仅是字符串，就在每行输出值的时候把这些字符串附加上去。当然，最大长度也是10个字符。 

## JSON.stringify() 实例

```html
<!DOCTYPE html>
<html>
<head>
<title>html美化输出json字符串</title>
<style type='text/css'>
pre {outline: 1px solid #ccc; padding: 5px; margin: 5px; }
.string { color: green; }
.number { color: darkorange; }
.boolean { color: blue; }
.null { color: magenta; }
.key { color: red; }
</style>
</head>
<body>
<pre id="output"></pre>
<pre id="output2"></pre>

<script type="text/javascript">
var obj = {a:1, 'b':'foo', c:[false,null, {d:{e:1.3e5}}]};

// 1. 最简单的输出
var str = JSON.stringify(obj, undefined, 2);
document.getElementById('output').innerHTML = str;

// 2. 带高亮的输出
function highLight(json){
			 json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
			  return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
				     var cls = 'number';
				     if (/^"/.test(match)) {
				         if (/:$/.test(match)) {
				             cls = 'key';
				         } else {
				             cls = 'string';
				         }
				     } else if (/true|false/.test(match)) {
				         cls = 'boolean';
				     } else if (/null/.test(match)) {
				         cls = 'null';
				     }
				     return '<span class="' + cls + '">' + match + '</span>';
				 });
		}
		var person = {
			 name: "Hello Kitty",
			 sex: "男",
			 age: 20,
			 child: [
			 	{
			 		name: "Hello",
					sex: "男",
					age: 10,
					toy:['a','b']
			 	},
			 	{
			 		name: "Kitty",
					sex: "女",
					age: 8,
					toy:[1,2,3]
			 	}
			 ]
		};

		var str = JSON.stringify(person, undefined, 3);

	

//document.getElementById('output2').innerHTML = syntaxHighlight(str);
document.getElementById('output2').innerHTML = highLight(str);
</script>

</body>
</html>
```

上述示例的效果如图:
<center>![](jsonfmt.png)</center>

[详见github示例代码](https://github.com/researchlab/CodeSnippets/blob/master/json.html)
