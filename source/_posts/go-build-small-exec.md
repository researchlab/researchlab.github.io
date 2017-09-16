---
title: "go编译生成更小的执行程序" 
date: 2016-10-23 14:00:32
categories: [golang]
tags: golang
description:
---

尽管go1.7.3编译生成的可执行程序已经很小了,但是通过编译参数控制还能编译出更小的可执行文件，总结如下,
<!--more-->

## 加-ldflags参数
在程序编译的时候可以加上`-ldflags "-s -w"` 参数来优化编译程序, 其实通过去除部分连接和调试等信息来使得编译之后的执行程序更小,具体参数如下:
- `-a` 强制编译所有依赖包
- `-s` 去掉符号表信息, panic时候的stack trace就没有任何文件名/行号信息了.
- `-w` 去掉DWARF调试信息，得到的程序就不能用gdb调试了

如执行如下命令可得到优化编译过的`test`可执行程序:4.8M

```bash
$ go build -ldflags -w test.go
```

> 不建议s和w同时使用。

## 使用upx
上面golang build 时加上`-ldflags`参数得到了比较小的可执行程序， 但是还可以通过`upx`这个开源，绿色，好用的压缩工具进行进一步压缩，首先其下载地址:http://upx.sourceforge.net/#downloadupx

linux 系统选择下载:`upx-3.91-amd64_linux.tar.bz2` 即可, 然后 `tar -xvf upx-3.91-amd64_linux.tar.bz2` 进入到解压文件夹中将可执行文件`upx` 拷贝到`/usr/bin`就可以全局执行了
```bash
$ sudo mv upx /usr/bin
➜  test git:(master) ✗ upx -9 -k test 
                       Ultimate Packer for eXecutables
                          Copyright (C) 1996 - 2013
UPX 3.91        Markus Oberhumer, Laszlo Molnar & John Reiser   Sep 30th 2013

        File size         Ratio      Format      Name
   --------------------   ------   -----------   -----------
   5024059 ->   1552060   30.89%  linux/ElfAMD   test 

Packed 1 file.
```

可以看到通过`upx`进一步压缩之后得到的程序大约只有1.5M了， 压缩比率达到了`30.89%`.
其中`-k`参数表示保留备份文件， `-9`代表最优压缩，`upx`总共有9档压缩,从`1`到`9` 其中 `-1`压缩速度最快.

再来看看下面编译之后的效果
```bash
$ go build test.go ---> 得到的 test  大约6.5MB 
$ go build -ldflags -w ---> 得到的 test 大约4.8MB
$ upx -9 test  ---> 得到的 test 大约 1.5MB
```
