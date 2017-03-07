---
title: "docker实践--03 镜像管理"
date: 2017-03-06 11:06:41
categories: [docker-practice]
tags: [docker]
description:
---

## 前言
在前面第一篇总结中已了解了一些镜像的概念，简单的说镜像就是一个容器的只读模板，用来创建容器。当运行容器时需要指定镜像，如果本地没有该镜像，则会从Docker Registry下载。默认查找的是`Docker Hub`。Docker的镜像是增量的修改，每次创建新的镜像都会在老的镜像上面构建一个增量的层，使用到的技术是Another Union File System(AUFS)，具体可参考 [剖析Docker文件系统：Aufs与Devicemapper](http://www.infoq.com/cn/articles/analysis-of-docker-file-system-aufs-and-devicemapper/), 下面主要总结记录使用和管理docker镜像的过程。

<!--more-->

## 查找和下载镜像
镜像存储中的核心概念仓库(Repository)是镜像存储的位置。Docker注册服务器(Registry)是仓库存储的位置。每个仓库包含不同的镜像。比如一个镜像名称`ubuntu:14.04`，冒号前面的ubuntu是仓库名, 后面的14.04是TAG, 不同的TAG可以对应相同的镜像, TAG通常设置为镜像的版本号。`Docker Hub`是Docker官方提供公共仓库，提供大量的常用镜像，由于国内网络原因经常连接Docker Hub会比较慢，所以我们也可以选择一些国内提供类似Docker Hub镜像服务站点。连接Docker Hub的常用命令包括,
- 搜索镜像 docker search
- 下载镜像 docker pull
假设现在需要一个busybox镜像，首先进行搜索，然后使用docker pull下载到本地,
```bash 
➜  ~ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nginx               latest              6b914bbcb89e        6 days ago          182 MB
ubuntu              latest              0ef2e08ed3fa        7 days ago          130 MB
➜  ~ docker search busybox
NAME                            DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
busybox                         Busybox base image.                             945       [OK]
progrium/busybox                                                                65                   [OK]
radial/busyboxplus              Full-chain, Internet enabled, busybox made...   11                   [OK]
container4armhf/armhf-busybox   Automated build of Busybox for armhf devic...   6                    [OK]
➜  ~
```

查找到的数据中包含仓库名称, 描述, 以及有多少人关注。一般情况只需要下载最基本的Busybox base image就可以, 查找命令返回的结果中通常可以看到不同版本的busybox, 不指定版本号默认下载busybox:latest。使用`docker pull`命令将镜像下载到本地,
```bash 
➜  ~ docker pull busybox
Using default tag: latest
latest: Pulling from library/busybox
4b0bc1c4050b: Pull complete
Digest: sha256:348432dd709c2cd6ca42e56c2a0d157f611c50c908e14c9bfc1e9cb0ed234871
Status: Downloaded newer image for busybox:latest
➜  ~ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nginx               latest              6b914bbcb89e        6 days ago          182 MB
ubuntu              latest              0ef2e08ed3fa        7 days ago          130 MB
busybox             latest              7968321274dc        7 weeks ago         1.11 MB
```
也可以在Docker Hub上创建一个账户，用来保存所需的镜像，但是在国内使用实在是太慢了。这里简单介绍下Docker中使用命令登陆Docker Hub保存镜像的方式,
- 首先在Docker Hub注册一个账号, 
- 然后可以基于Docker Hub上现有的镜像创建一个镜像
- 在本地完成修改后使用docker push命令推送到Docker Hub上

此外，Docker Hub提供一个强大的自动创建镜像的功能，可以设定跟踪某个镜像中安装的软件，如果有更新则自动重新构建新的镜像。更多有趣的功能可以登录到Docker Hub 官网进行体验。在此不做更多介绍。

## 创建镜像

** 方法一, 下载镜像 docker pull **

在本地创建镜像的方法有几种，最简单的是直接从Registry服务器上下载, 即通过`docker pull`命令下载下来，镜像下载中可以看到是分层下载，每一层都有一个唯一的ID值表示，每层下载的大小实际为该层进行的修改增量。

** 方法二,  创建镜像 Dockerfile **

`Dockerfile`可以很方便的基于已有镜像创建新的镜像。`Dockerfile`文件里包含若干条命令，每个命令都会创建一个新的层, `Dockerfile`创建的层数不可以超过127层。`Dockerfile`的详细编写方法后续再说，此处只写一个最简单的Dockerfile来介绍。

使用vim打开一个文件Dockerfile, 并写入下面两行，
```bash
from ubuntu:latest
ENV HOSTNAME=new_image
```
这个`Dockerfile`中只有两行，第一行表示基于哪个镜像创建新的镜像，类似于程序开发中的`import`或`include`, 这里以`ubuntu:latest`镜像为基础创建新的镜像。第二行是在新的镜像中我们要对基础镜像`ubuntu:latest`做的改变。这句是设置一个环境变量HOSTNAME等于new_image。完成`Dockerfile`后，使用`docker build`命令进行构建, 
```bash 
docker build -t nimage .
```
这个命令中第一个参数`-t nimage`指定创建的新镜像的名字，第二个参数是一个点`.`指定从当前目录查找`Dockerfile`文件。执行完成后我们 docker images 命令中就可以看到新的nimage镜像了。

** 其它方法创建镜像 **
创建镜像的方法很多，除了上述两种之外还可以使用下述方法进行创建，如,
- 容器管理中总结过的`docker import`
- 对容器提交修改`docker commit`
- 导入镜像`docker load`

## 查看镜像信息

** 1. 基本命令 docker images **
`docker images`命令查看本地的镜像列表，信息包括,
- `REPOSITORY`：仓库名称
- `TAG`：标签名，一个仓库可以有若干个标签对应不同的镜像，默认都是latest
- `IMAGE ID`：镜像ID
- `CREATED`：创建时间，注意不是本地的pull时间
- `SIZE`：镜像大小

其中需要注意的是运行容器时候如果不指定镜像的`TAG`, 则默认为`latest`。镜像的唯一标识符是`镜像ID`, 不是`TAG`, 有的时候同一个镜像可以有不同的`TAG`, 但实际指向的是同一个`镜像ID`。`TAG`可以理解为镜像的别名。

查看当前系统中存储的所有镜像信息,
```bash
➜  ~ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nginx               latest              6b914bbcb89e        6 days ago          182 MB
ubuntu              latest              0ef2e08ed3fa        7 days ago          130 MB
busybox             latest              7968321274dc        7 weeks ago         1.11 MB
```

** 2. 查看镜像详细信息 docker inspect **

`docker inspect`可以查看指定镜像的详细信息。这条命令可以查看容器或镜像的详细信息，输出是一个JSON格式的内容，比较重要的信息是创建时间，启动命令等, 前面已经总结过，这里就不再赘述。

## 导入和导出镜像
与容器的导出和导入类似, 镜像可以被导出到本地文件，也可以从本地文件中加载。导出命令是`docker save`命令，导出后的镜像如果需要导入到新的Docker 服务器, 则使用`docker load`命令。
```bash
~ docker save busybox > newbox.tar
➜  ~ docker load -i ~/newbox.tar
Loaded image: busybox:latest
➜  ~ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nginx               latest              6b914bbcb89e        6 days ago          182 MB
ubuntu              latest              0ef2e08ed3fa        7 days ago          130 MB
busybox             latest              7968321274dc        7 weeks ago         1.11 MB
```

## 更新镜像

更新镜像用命令 `docker commit`, 如果需要对镜像进行更新的话，一种方法是创建容器，在容器中进行修改，然后将修改后容器提交到镜像中。提交使用`docker commit`命令。
注意：本方法不推荐用在生产系统中，未来会很难维护镜像。最好的创建镜像的方法是`Dockerfile`，修改镜像的方法是`修改Dockerfile`，然后重新从Dockerfile中构建新的镜像。

下面先基于ubuntu镜像创建一个容器,
```bash
docker run -t -i --name updateimage ubuntu /bin/bash
```
进入到容器中进行修改，创建三个新的文件夹，然后退出容器, 通过`docker diff`命令可以查看到确实做出了修改，然后通过`docker commit`命令将修改后的内容提交到本地，另存为镜像newbuntu, 

```bash 
➜  ~ docker run -t -i --name updateimage ubuntu /bin/bash
root@4a7b3923ad93:/# touch /tmp/s{1,2,3}
root@4a7b3923ad93:/# ls -la /tmp/
total 8
drwxrwxrwt 1 root root 4096 Mar  7 03:53 .
drwxr-xr-x 1 root root 4096 Mar  7 03:53 ..
-rw-r--r-- 1 root root    0 Mar  7 03:53 s1
-rw-r--r-- 1 root root    0 Mar  7 03:53 s2
-rw-r--r-- 1 root root    0 Mar  7 03:53 s3
root@4a7b3923ad93:/# %                                                                                                                                                              ➜  ~ docker diff updateimage
C /tmp
A /tmp/s1
A /tmp/s2
A /tmp/s3
➜  ~ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nginx               latest              6b914bbcb89e        6 days ago          182 MB
ubuntu              latest              0ef2e08ed3fa        7 days ago          130 MB
➜  ~ docker commit -m 'add 3 dirs' -a 'newbuntu' -p updateimage newbuntu
sha256:2557af5f7c99b0f1dd61c32e5c70320c5181f8e288109220437ed51e829c996b
➜  ~ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
newbuntu            latest              2557af5f7c99        2 seconds ago       130 MB
nginx               latest              6b914bbcb89e        6 days ago          182 MB
ubuntu              latest              0ef2e08ed3fa        7 days ago          130 MB
➜  ~
```
`docker commit`参数说明,
- `-m`: 本次提交的描述
- `-a`: 指定镜像作者信息
- `-p`: 提交时暂停容器运行
- `updateimage`: 容器的ID或名称
- `newbuntu`: 目标镜像

如果指定了目标镜像，Docker会创建新的镜像。类似我们修改一个word文档后进行的另存为。

## 删除镜像
删除镜像命令:`docker rmi`, `docker rmi`命令可以删除本地的镜像，删除前需要先使用`docker rm` 删除所有依赖该镜像的容器。`docker rmi -f` 可以强制删除存在容器依赖的镜像，但这不是一个好习惯，请先删除容器再清理镜像。

## 总结

- 使用Docker Hub查找和下载镜像
- 创建镜像
- 查看镜像信息
- 导入和导出镜像
- 修改镜像
- 删除镜像
