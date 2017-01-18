---
title: "git submodule使用总结"
date: 2017-01-18 17:11:52
categories: [DevOps]
tags: [submodule]
description:
---

## 前言
现在golang已经可以通过`vendor`来管理第三方依赖包了，但是之前的一个老项目用的是`git submodule`来管理的，但是`.gitsubmodule`文件中只记录管理了项目的部分依赖包， 需要把还没有被管理的第三包也加上，下面总结使用`git submodule`的过程。
<!--more-->

## 添加第三方包
为当前工程添加submodule，命令如下：

```bash
git submodule add 仓库地址 保存路经路径
```
例如要为gomail包添加`submodule`管理， 
gomail包 仓库地址: `https://github.com/go-gomail/gomail.git`
gomail包要保存在项目里的路经为: `src/github.com/go-gomail/gomail`, 则命令为:

```bash 
git submodule add https://github.com/go-gomail/gomail   src/github.com/go-gomail/gomail
```

但是老项目遇到的情况是在保存路经`src/github.com/go-gomail/gomail`中已经存在`gomail`, 这里只是需要把这个第三包用`git submodule`记录下来编译管理， 所以需要加一个强制参数， 则命令为如下:

```bash
git submodule add -f https://github.com/go-gomail/gomail   src/github.com/go-gomail/gomail
```

> 其中，仓库地址是指子模块仓库地址，路径指将子模块放置在当前工程下的路径。 
> 注意：路径不能以 / 结尾（会造成修改不生效）、不能是现有工程已有的目录（不能順利 Clone）

命令执行完成，会在当前工程根路径下生成一个名为`.gitmodules`的文件，其中记录了子模块的信息。添加完成以后，再将子模块所在的文件夹添加到工程中即可。

## 删除第三方包

submodule的删除稍微麻烦点:首先，要在“.gitmodules”文件中删除相应配置信息。然后，执行“git rm –cached ”命令将子模块所在的文件从git中删除。

## 下载的工程带有submodule
当使用git clone下来的工程中带有submodule时，初始的时候，submodule的内容并不会自动下载下来的，此时，只需执行如下命令：
```bash
git submodule update --init --recursive
```
即可将子模块内容下载下来后工程才不会缺少相应的文件。

## 问题
当第三包被`git submodule`记录之后，`git status`命令会出现下面的情况,
```bash 
$ git status vendor | grep modified:
#       modified:   vendor/rails (modified content)
```

```bash 
$ git diff vendor/
diff --git a/vendor/rails b/vendor/rails
--- a/vendor/rails
+++ b/vendor/rails
@@ -1 +1 @@
-Subproject commit 046c900df27994d454b7f906caa0e4226bb42b6f
+Subproject commit 046c900df27994d454b7f906caa0e4226bb42b6f-dirty
```

如何让`git status`不显示那个`modified content`呢？ 
修改`.gitmodule`文件， 在显示`modified content`的第三包管理下添加一个`ignore = dirty`， 如下:
```bash
[submodule "bundle/fugitive"]
    path = bundle/fugitive
    url = git://github.com/tpope/vim-fugitive.git
    ignore = dirty
```

上述三个步骤一般就能解决问题了， 如果想深入理解`git submodule`,可进一步参考[git submodule使用完整教程](http://www.kafeitu.me/git/2012/03/27/git-submodule.html)
