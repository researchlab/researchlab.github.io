---
title: "php7 安装redis扩展"
date: 2016-08-02 18:56:05
categories: [php]
tags: [php_redis, phpize]
description:
---

## 前言
在`Ubuntu16.04`上， 安装`php7`的`redis`扩展, 记录安装过程。
<!--more-->

### 安装phpredis  

`Redis`已经有了`PHP7`版本，可以从` github` 上获取项目克隆，然后手动切换到 `php7` 分支即可安装

```bash
$ git clone https://github.com/phpredis/phpredis.git 
$ cd phpredis/ 
$ git checkout php7 
$ phpize 
$ ./configure 
$ make 
$ makeinstall
```

如果没有安装php7.0-dev, 则没有安装 `phpize` , 可以直接`sudo apt install php7.0-dev` 安装即可。 

## 启动 redis 扩展

光安装了还不够，我们还需要编辑PHP的配置文件来使扩展被加载才行， 打开配置文件`vim /etc/php/7.0/fpm/php .ini`, 在配置文件中添加如下语句：
```bash
extension=redis.so
```

然后重启php服务,
```bash
/etc/init.d/php7.0-fpm restart 
```
