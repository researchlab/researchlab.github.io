---
title: "docker实践--01 创建docker应用"
date: 2017-03-04 09:05:58
categories: [docker-practice]
tags: [docker]
description:
---

## 前言
很早就使用docker了，只是工作上一直没用起来， 加之工作多/杂，就只是断断续续自己瞎折腾，现在打算系统的整理总结一下docker使用经历，这个第一篇主要总结一下几个方面，  
<!--more-->
- 理解Docker是什么
- 学习如何在Linux上安装Docker
- 学习如何使用Docker Hub
- 创建第一个Docker应用HelloWorld
- Docker基本的容器和镜像管理

## Docker 概念
对比虚拟化技术，Docker容器与主机共享操作系统内核，不能像虚拟机那样运行独立的内核, 容器比虚拟化更轻量级, 对资源的消耗小很多。容器操作也更快捷，启动和停止都要比虚拟机快。Docker容器技术为使用者提供了更好的容器操作接口, 其中包括一系列的容器，镜像，网络等管理工具，可以让用户简单的创建和使用容器。
Docker支持将应用打包进一个可以移植的容器中，重新定义了应用开发，测试，部署上线的过程，核心理念就是<font color=red>Build once, Run anywhere</font>, Docker容器技术的典型应用场景是开发运维上提供持续集成和持续部署的服务。
在学习Docker容器技术时，首选要了解什么是`镜像`, 什么是`容器`, 什么是`仓库`等基础概念， 不过在阐述这些概念前推荐先阅读以下两篇文章，
- [深入浅出Docker(一): Docker核心技术预览](http://www.infoq.com/cn/articles/docker-core-technology-preview)
	这篇文章介绍了Docker产生的技术发展历程，Docker中的核心技术以及相关的子项目，非常好的入门资料。
- [了解Docker容器技术的架构设计](https://docs.docker.com/engine/understanding-docker/)
	这篇Docker 官方的文章详细介绍了Docker的运行机制和必要的组件。不涉及到很底层的技术，可以做为对Docker的一个初步了解。

** 什么是镜像? **

Docker的镜像概念类似于虚拟机里的镜像，是一个只读的模板，一个独立的文件系统，包括运行容器所需的数据，可以用来创建新的容器。
镜像可以基于Dockerfile构建，Dockerfile是一个描述文件，里面包含若干条命令，每条命令都会对基础文件系统创建新的层次结构。
用户可以通过编写Dockerfile创建新的镜像，也可以直接从类似github的Docker Hub上下载镜像使用。

** 什么是容器? **

Docker容器是由Docker镜像创建的运行实例。Docker容器类似虚拟机，可以支持的操作包括启动，停止，删除等。每个容器间是相互隔离的，但隔离的效果比不上虚拟机。容器中会运行特定的应用，包含特定应用的代码及所需的依赖文件。
在Docker容器中，每个容器之间的隔离使用Linux的 CGroups 和 Namespaces 技术实现的。其中 CGroups 对CPU，内存，磁盘等资源的访问限制，Namespaces 提供了环境的隔离。

** 什么是仓库? **

使用过git 和 github 就很容易理解Docker的仓库概念。Docker仓库相当于一个 github 上的代码库。
Docker 仓库是用来包含镜像的位置，Docker提供一个注册服务器（Registry）来保存多个仓库，每个仓库又可以包含多个具备不同tag的镜像。Docker运行中使用的默认仓库是 Docker Hub 公共仓库。
仓库支持的操作类似 git，创建了新的镜像后，我们可以 push 提交到仓库，也可以从指定仓库 pull 拉取镜像到本地。

## 安装docker 
安装官方说明在Mac 上安装docker非常简单，直接在官方下载docker for mac的安装程序双击安装即可，安装完后，可以使用`docker version`查看Docker的版本信息，如我的,
```bash
er version
Client:
 Version:      17.03.0-ce
 API version:  1.26
 Go version:   go1.7.5
 Git commit:   60ccb22
 Built:        Thu Feb 23 10:40:59 2017
 OS/Arch:      darwin/amd64

Server:
 Version:      17.03.0-ce
 API version:  1.26 (minimum version 1.12)
 Go version:   go1.7.5
 Git commit:   3a232c8
 Built:        Tue Feb 28 07:52:04 2017
 OS/Arch:      linux/amd64
 Experimental: true
```

如果可以看到version信息的话，说明docker 已经安装成功了，下面可以尝试执行如下命令，在docker中运行一个nginx 服务器，
```bash 
docker run -d -p 80:80 --name webserver nginx 
```

运行这个命令，docker首先会在本地找nginx:lastest镜像，如果没找到就会自动去`Docker Hub`公有仓库中去拉一个下来运行，运行上述命令之后， 就启动一个docker 应用nginx服务器了， 通过docker ps 命令查看 当前正在运行的服务器， 可以看到如下,
```bash
➜  ~ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                         NAMES
c1760b8f9359        nginx               "nginx -g 'daemon ..."   3 hours ago         Up About an hour    0.0.0.0:80->80/tcp, 443/tcp   webserver
```
> 注: 在国内直接运行docker run -d -p 80:80 --name webserver nginx 命令多半会出现xxx Timeout 的提示，因为国内docker Hub站点被强了，所以需要先更换Docker Hub源再运行上述docker run 命令就可以成功，要更换Docker Hub源可以通过DaoCloud公司提供的Docker Hub加速器地址来解决， 具体做法可参考[how to master docker image](http://blog.daocloud.io/how-to-master-docker-image/); 


此时就可以在浏览器中输入`http://0.0.0.0/`, 看到nginx服务器的欢迎界面咯，

<center>![webserver-nginx](imgs/hi-nginx.png)</center>

可以通过docker stats命令查看当前所有container的运行状态,
```bash
➜  ~ docker stats
CONTAINER           CPU %               MEM USAGE / LIMIT       MEM %               NET I/O             BLOCK I/O           PIDS
c1760b8f9359        0.00%               1.859 MiB / 1.952 GiB   0.09%               16.1 kB / 4.58 kB   0 B / 0 B           2
CONTAINER           CPU %               MEM USAGE / LIMIT       MEM %               NET I/O             BLOCK I/O           PIDS
c1760b8f9359        0.00%               1.859 MiB / 1.952 GiB   0.09%               16.1 kB / 4.58 kB   0 B / 0 B           2
```
## 创建docker应用

** 需求描述 **

Docker 安装后，下面来创建第一个Docker 应用。这个应用很简单，作用就是输出一句 HelloWorld!。

** 需求分析 **

应用执行的命令是 echo "HelloWorld"，可以为这条命令构建一个运行的容器，让这条命令在容器中运行，运行后容器自动退出。

**  解决方案 **

首先，需要有一个镜像来运行这个应用，这里选择用busybox镜像，直接使用docker run 命令来运行容器
```bash
docker run busybox echo "HelloWorld"
```
首先docker run 会先在本地找busybox 这个镜像，如果找不到就会到Docker Hub上去下载一个下来，然后docker run 命令会基于指定的镜像busyzbox运行一个容器实例，然后把 echo "HelloWorld"命令传递给该容器执行,所以上述命令最终会再屏幕上输出 "HelloWorld", 如下,
```bash
➜  ~ docker run busybox echo "HelloWorld"
Unable to find image 'busybox:latest' locally
latest: Pulling from library/busybox
4b0bc1c4050b: Pull complete
Digest: sha256:348432dd709c2cd6ca42e56c2a0d157f611c50c908e14c9bfc1e9cb0ed234871
Status: Downloaded newer image for busybox:latest
HelloWorld
```

执行 docker ps 命令查看运行的容器列表，但看不到任何容器在运行，原因是容器运行了echo 命令后已经终止，进入到停止状态，需要用 docker ps -a 命令查看,
```bash
➜  ~ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
➜  ~ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                          PORTS               NAMES
65948b8f61eb        busybox             "echo HelloWorld"        About an hour ago   Exited (0) 2 minutes ago                            xenodochial_bohr
```
在这个命令的输出中我们看到列表里有一个处于 Exited (0) 2 minutes ago 的容器，这个容器表示大约2分钟之前终止。列表中还包括该容器的ID，使用的镜像，执行的命令，创建的时间等信息。最后一个是为容器随机设置的名称，也可以通过run的参数进行设置为指定名称，注意同一个服务器上的容器不可以同名。

## 容器管理
上面通过docker run 命令在指定的镜像中运行一个容器，然后在容器中执行我们的应用程序，下面通过实践来了解docker容器管理中最常用的几个命令,

** docker run **

最主要的是创建运行容器的命令`docker run`，这个命令的参数非常多，可以通过`docker run --help` 查看。
继续上一节实验，echo 命令运行后容器就退出了，如果我们需要一个保持运行的容器呢，最简单的方法就是给这个容器一个可以保持的应用，比如bash，运行 ubuntu 容器并进入容器的 bash：
```bash 
docker run -t -i ubuntu /bin/bash
```
上面命令的说明：
`-t`：分配一个 pseudo-TTY
`-i`：--interactive参数缩写，表示交互模式
`ubuntu`：运行的镜像名称，默认为latest 标签
`/bin/bash`：容器中运行的应用
通过这个简单的命令，我们现在进入了新创建容器的bash中，在bash里执行的任何命令都不会影响到我们的宿主机，可以随意操作。你可以看到主机名和环境变量HOSTNAME都已经显示为容器的ID了。在这个bash下，我们可以进行各种Ubuntu系统上的操作，当然因为Docker本身的限制，有些涉及到磁盘、网络、设备等Linux特权命令是无法执行的，可以试试reboot命令，会提示你shutdown: Unable to shutdown system。

如何退出这个bash呢？有两种方法，两种方法的效果完全不同,
 - 直接`exit`，这时候`bash`程序终止，容器进入到停止状态
 - 使用组合键退出，仍然保持容器运行，我们可以随时回来到这个bash中来，组合键是`Ctrl-p Ctrl-q`，你没有看错，是两组组合键，先同时按下Ctrl和p，再按Ctrl和q。就可以退出到我们的宿主机了。

上述第二种方法比较常用，此时使用`docker ps` 查看，能看到容器仍然在运行中：
```bash
➜  ~ docker run -t -i ubuntu /bin/bash
Unable to find image 'ubuntu:latest' locally
latest: Pulling from library/ubuntu
d54efb8db41d: Pull complete
f8b845f45a87: Pull complete
e8db7bf7c39f: Pull complete
9654c40e9079: Pull complete
6d9ef359eaaa: Pull complete
Digest: sha256:f649e49c1ed34607912626a152efbc23238678af1ac37859b6223ef28e711a3f
Status: Downloaded newer image for ubuntu:latest
root@65fc97a6b032:/# %
➜  ~ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
65fc97a6b032        ubuntu              "/bin/bash"         About an hour ago   Up 4 minutes                            kickass_goodall
```

如果想再次回到刚才的bash中，只需要使用`docker attach`命令就可以再次连接到运行的bash里：
```bash
➜  ~ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
65fc97a6b032        ubuntu              "/bin/bash"         About an hour ago   Up 4 minutes                            kickass_goodall
➜  ~ docker attach 65fc9
root@65fc97a6b032:/#
```
** 注意** ：命令后面的参数是容器的ID，并不需要输入完整的数字，只要能唯一定位这个容器即可，通常输入4位就足够了。

** docker ps **

`docker ps`命令用来查看正在运行的容器,几个最常用的参数：
`-a`：查看所有容器，含停止运行的
`-l`：查看刚启动的容器
`-q`：只显示容器ID

例如查看所有容器的ID列表,则执行`docker ps -a -q`命令即可。

** docker start **

docker start 启动容器，此处我们尝试启动先前的运行/bin/bash的容器,
```bash
docker start 65fc
```
通过`docker start`启动容器之后， 可以通过`docker attach`命令直接进入到该容器中, 如果要停止正在运行的容器则可用`docker stop`命令，如果要重启则用`docker restart`命令即可。

** docker inspect **

查看Docker容器或镜像的一些内部信息, 如启动并查看`/bin/bash `容器,
```bash
➜  ~ docker start 65fc
65fc
➜  ~ docker inspect 65fc
[
    {
        "Id": "65fc97a6b0324436f4f9843f06657473d6cf441318937d243b395aff13d6d466",
        "Created": "2017-03-05T12:47:04.372874677Z",
        "Path": "/bin/bash",
        "Args": [],
.....
```
返回的信息非常多，是JSON格式，每一项内容具体含义本节不做详细介绍，可以参考官方文档。

** docker rm **

删除容器操作。该命令默认不可以删除运行的容器，但提供了强制删除的参数`-f`，

** docker top **

查看容器中运行的进程信息，显示容器中进程的PID，UID，PPID，时间，tty等信息,
```bash
➜  ~ docker top 65fc
PID                 USER                TIME                COMMAND
3073                root                0:00                /bin/bash
```

## 镜像管理
先来简单了解一下镜像管理的基本概念,

** 查看镜像列表 **

`docker images` 命令可以列出当前系统上所有的镜像信息,
```bash
➜  ~ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nginx               latest              6b914bbcb89e        4 days ago          182 MB
ubuntu              latest              0ef2e08ed3fa        5 days ago          130 MB
busybox             latest              7968321274dc        7 weeks ago         1.11 MB
```
其中：
`REPOSITORY`：仓库名称
`TAG`：标签名，一个仓库可以有若干个标签对应不同的镜像，默认都是latest
`IMAGE ID`：镜像ID
`CREATED`：创建时间，注意不是本地的pull时间
`SIZE`：镜像大小

** 获取镜像 **

最简单的获取镜像的方式是从 Docker Hub上 pull 最新的镜像，比如我们想要一个`busybox` 的镜像，直接使用命令
```bash
docker pull busybox
```

** 创建镜像 **

最常用的是写一个`Dockerfile`，从`Dockerfile`里创建新的镜像。
`Dockerfile`的详细编写方法我们后续有专门的实验介绍，此处只写一个最简单的`Dockerfile`来介绍。
使用vim打开一个文件`Dockerfile`, 写入如下两行保存,
```bash
from ubuntu:latest
ENV HOSTNAME=HelloWorld
```

这个`Dockerfile` 中只有两行，
第一行表示基于哪个镜像创建新的镜像，类似于程序开发中的`import` 或`include`，这里以`ubuntu:latest`镜像为基础创建新的镜像。第二行是在新的镜像中我们要对基础镜像 ubuntu:latest 做的改变。这句是设置一个环境变量HOSTNAME等于HelloWorld。完成`Dockerfile` 后，使用`docker build` 命令进行构建：
```bash
docker build -t hellworld .
```
这个命令中第一个参数`-t helloworld`指定创建的新镜像的名字，第二个参数是一个点 `.` 指定从当前目录查找`Dockerfile` 文件，编译结果如图,
```bash
➜  helloworldimage docker build -t HelloWorld .
invalid argument "HelloWorld" for t: Error parsing reference: "HelloWorld" is not a valid repository/tag: repository name must be lowercase
See 'docker build --help'.
➜  helloworldimage docker build -t helloworld .
Sending build context to Docker daemon 2.048 kB
Step 1/2 : FROM ubuntu:latest
 ---> 0ef2e08ed3fa
Step 2/2 : ENV HOSTNAME HelloWorld
 ---> Running in d0f16b14164e
 ---> de0c24b4dc2e
Removing intermediate container d0f16b14164e
Successfully built de0c24b4dc2e
```
如结果所示，镜像名必须小写。执行`docker images` 命令就可以看到新的`helloworld`镜像了。
```bash
➜  helloworldimage docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
helloworld          latest              de0c24b4dc2e        About an hour ago   130 MB
nginx               latest              6b914bbcb89e        4 days ago          182 MB
ubuntu              latest              0ef2e08ed3fa        5 days ago          130 MB
busybox             latest              7968321274dc        7 weeks ago         1.11 MB
➜  helloworldimage docker run -t -i helloworld /bin/bash
root@3ce776c1ee74:/# echo $HOSTNAME
HelloWorld
root@3ce776c1ee74:/#
```
上述结果知, 通过`docker run`命令运行新的镜像，然后通过`echo $HOSTNAME` 果然是之前设置的`HelloWorld`名称。

** 清理镜像 **

通过命令退出上述`helloworld`容器后，可使用`docker rm` 命令删除容器，并使用`docker rmi` 删除镜像。
```bash
➜  helloworldimage docker rm -f 3ce7
3ce7
➜  helloworldimage docker rmi helloworld
Untagged: helloworld:latest
Deleted: sha256:de0c24b4dc2ee6512b8c95d15b532b162dc883c7e5caf8aa00939fa5712fb7d1
```

## 总结
- 理解Docker是什么
- 学习如何在Mac上安装Docker
- 学习如何使用Docker Hub
- 创建第一个HelloWorld 的Docker应用
- Docker基本的容器和镜像管理
