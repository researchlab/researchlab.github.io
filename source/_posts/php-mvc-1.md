---
title: "php中mvc模式使用总结(一)"
date: 2016-07-30 16:34:45
categories: [php]
tags: [php, mvc]
description:
---

## 前言
尽管MVC(model view controller pattern)模式在`PHP`web开发中很受欢迎，但是网上很难找到一套代码简单又能清楚阐述`PHP MVC`模式的案例，本文希望通过理论和代码实践简单阐述`PHP MVC`模式。

<!--more-->

`MVC`模式在应用中分为`Model`, `View` 和 `Controller`三模块:

`Model`负责处理数据; 主要负责数据有关的业务处理及存储读取工作。

`View`负责将`Model`层的数据按一定的格式样式展现给用户。

`Controller`负责将`Model`层和`View`层联系起来，`Controller`层响应用户的请求，并将请求业务分发给`Model`层相应的业务逻辑处理，然后将处理数据再返回给`View`层展示。 

`MVC`三者之间的关系如图所示:

<center>
![MVC pattern Diagram](/imgs/mvc-collaboration.png)
</center>

本文设计的`MVC`demo目录如下
<center>
![mvc structure](/imgs/mvc-structure.png)
</center>

## Controller 层 
`Controller`层可是`MVC`的入口，接收一个用户请求，解析请求发送给`Model`层，调用`Model`层处理业务，接收`Model`层返回的数据结果，并将数据发送给展示层。`Controller`层是`Model`层和`View`层之间的连接纽带;小的框架中`Model`层和`View`层是包含在`Controller`层中。应用程序中一般会以`index.php`作为程序的入口，`index.php`会将用户的所有请求直接转发到`Controller`层,由`Controller`层进行相应的处理。

```php
//index.php file 
include_once("controller/Controller.php");

$controller = new Controller();
$controller->invoke();
```

在本例中`Controller`层只有一个函数和一个构造函数。构造函数示例化一个`Model`类的实例;当`Controller`对接收的`req`解析之后，需要决定调用`Model`层相应的业务逻辑进行处理，然后将`Model`层返回的处理数据分发给`view`层展示。需要知道的是`Controller`层不是知道`data`如何处理的，也不知道页面是如何生成的。

```php
//controller/Controller.php file
include_once("model/Model.php")

class Controller {
	public $model;

	public function __construct(){
		$this->model = new Model();	
	}

	public function invoke() {
		if(!isset(!_GET['book'])){
			$books = $this->model->getBookList();
			include 'view/booklist.php';
		}else {
			// show the requested book
			$book = $this->model->getBook($_GET['book']);
			include 'view/viewbook.php';
		}	
	}
}
```

`MVC`时序图
<center>
![MVC Sequence Diagram](/imgs/mvc-sequence1.png)   
</center>

## Model 和 Entity 类
`Model`层表示应用程序中的数据和逻辑，通常称之为业务逻辑; 通常表示为如下:

- 存储，删除， 更新应用程序的数据。通常包括数据库方面的操作, 也可以按照一定的协议格式封装数据然后再通过调用第三方web服务或APIs进行相应的数据处理。

- 封装应用程序的业务逻辑;实现应用程序的所有业务逻辑。通常人们会错误的应用程序的一些业务逻辑实现写入到`Controller`层或`View`层中， 这是一种错误的或者说不规范的做法。 

本例中，`Model`层主要由`Model`类和`Book`类组成。`Book`类是一个实体类，应该暴露给`View`层。在一个好的`MVC`模式设计中，`Model`层中只有`Entity`类应该暴露接口供`View`层调用。这样做的唯一目的就是保持数据,因为`Entity`类中的对象可以通过`xml`或`json`数据块替换。在上述的示例中，`Model`层返回了一个具体的`book`实例信息，或者一个`books`list:

```php
//model/Model.php file
include_once("model/Book.php");

class Model{
	public function getBookList() {
		//here goes some hardcoded values to simulate the database
		return array(
			"Jungle Book"=> new Book("Jungle Book", "R.Kipling", "A classic book."),
			"Moonwalker"=> new Book("Moonwalker", "J.Walker",""),
			"PHP for Dummies"=> new Book("PHP for Dummies", "Some Smart Guy","")
		);
	}

	public function getBook($title) {
		// we use the previous function to get all the books and then we return the requested one.
		// in a real life scenario this will be done through a db select command.
		$allBooks = $this->getBookList();
		return $allBooks[$title];
	}
}
```

在真实场景中，`Model`层负责将所有的实体和类中的数据持久化到数据库，`Model`层中的类封装所有的业务逻辑。

```php
//model/Book.php file
class Book {
	public $title;
	public $author;
	public $description;

	public function __construct($title, $author, $description){
		$this->title = $title;
		$this->author = $author;
		$this->description = $description;
	}
}
```

## View层

`View`层负责将`Model`层返回的数据按照一定样式格式化呈现给用户。`Model`层返回的数据可以是简单的对象类型，也可以是xml, json等复杂的数据类型。

`View`层对于类似的展示逻辑应提取为模板，便于复用`View`层代码的同时有利于维护 。`Controller`层通常通过`Entity`类中的主`Entity`实例对象将`Model`层返回的数据转发给`View`层中特定的展示元素。

在本例中`View`层包含展示单个`book`信息和展示所有`book`信息两个文件

### viewbook.php
```html
<html>
<head></head>
<body>
	<?php
		echo 'Title:' . $book->title . '<br/>';
		echo 'Author:' . $book->author . '<br/>';
		echo 'Description:' . $book->description . '<br/>';
	?>
</body>
</html>
```

### booklist.php

```html
<html>
<head></head>
<body>
	<table>
		<tbody><tr><td>Title</td><td>Author</td><td>Description</td></tr></tbody>	
		<?php

		foreach($books as $title => $book){
		echo '<tr><td><a href="index.php?book="' . $book->title .'">'.$book->title .'</a></td><td>'.$book->author.'</td><td>'.$book->description.'</td></tr>';	
		}
		?>
	</table>
</body>
</html>
```

至此本demo分析实现完毕，[github示例代码](https://github.com/researchlab/CodeSnippets/tree/master/php_wrk/simple_mvc)


## 总结
- `Model`层和`View`层分开使得构建应用程序更加容易
- `Model`层和`View`层可以根据项目需要其中一层构成`MV`或`CV`模式
- 可以对`MVC`模式中每个层进行单独的测试和调试

