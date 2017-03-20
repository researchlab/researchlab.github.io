---
title: "docker实践--02 数据卷管理"
date: 2017-03-05 00:44:31
categories: [docker-practice]
tags: [docker]

description:
---

## 前言

Docker中的数据可以存储在类似于虚拟机磁盘的介质中，在Docker中称为`数据卷`(Data Volume)。数据卷可以用来存储Docker应用的数据，也可以用来在Docker容器间进行数据共享。数据卷呈现给Docker容器的形式就是一个目录，支持多个容器间共享，修改也不会影响镜像。使用Docker的数据卷，类似在系统中使用`mount` 挂载一个文件系统。
<!--more-->

## 创建数据卷
利用`docker run`创建容器时, 添加`-v`参数, 就可以创建并挂载一个到多个数据卷到当前运行的容器中，`-v`参数的作用是将宿主机的一个目录作为容器的数据卷挂载到容器中，使宿主机和容器之间可以共享一个目录，如果本地路径不存在，Docker也会自动创建。

下面就通过挂载2个数据卷到新创建的容器上来操作一下,
```bash
# 创建两个目录
➜  mkdir /tmp/data{1,2}

# 分别将两个目录挂载到新创建的data容器上
➜  docker run -t -i --name data -v /tmp/data1:/data1 -v /tmp/data2:/data2 ubuntu /bin/bash
```
上述命令中 -v 参数可以使用多次，并挂在多个数据卷到容器中。后面的参数信息中冒号前面是宿主机的本地目录，冒号后面是容器中的挂载目录, 结果如下,
```bash
➜  mkdir /tmp/data{1,2}
➜  docker run -t -i --name data -v /tmp/data1:/data1 -v /tmp/data2:/data2 ubuntu /bin/bash
root@8a8754728a1c:/# ls
bin  boot  data1  data2  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
root@8a8754728a1c:/# mount | grep data
osxfs on /data1 type fuse.osxfs (rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other,max_read=1048576)
osxfs on /data2 type fuse.osxfs (rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other,max_read=1048576)
/dev/vda1 on /etc/resolv.conf type ext4 (rw,relatime,data=ordered)
/dev/vda1 on /etc/hostname type ext4 (rw,relatime,data=ordered)
/dev/vda1 on /etc/hosts type ext4 (rw,relatime,data=ordered)
root@8a8754728a1c:/# ls -l data*
data1:
total 0

data2:
total 0
root@8a8754728a1c:/#
```
进入容器后我们可以查看和使用容器卷，尝试向这个容器卷中写入数据，然后在宿主机中查看是否存在,
```bash
root@8a8754728a1c:/# touch /data1/test1
root@8a8754728a1c:/# touch /data2/test2
root@8a8754728a1c:/# %                                                                                                ➜  helloworldimage ls /tmp/data1/test1
➜  helloworldimage cd /tmp/data2/test2
cd: not a directory: /tmp/data2/test2
➜  helloworldimage cd /tmp/data2
➜  data2 ls
test2
```
可以看到容器中挂载的数据卷具备可写权限，那么如何对数据卷的权限进行管理呢？比如如何创建一个只读的数据卷呢？

## 管理数据卷权限
挂载的数据卷默认为可读写权限，除非外部文件系统做了特殊限制，在`docker run`时也可以执行为只读权限,
```bash 
# 创建一个数据卷目录
➜  mkdir /tmp/readonlydata
# 以只读的方式挂载到data容器上
➜  docker run -t -i --name data -v /tmp/readonlydata:/rodata:ro ubuntu /bin/bash
```
上面的命令中参数很简单, `ro`表示`readonly`, 挂载后的数据卷就是只读权限了, 此时再次尝试向数据卷中写入,
```bash 

t@ad5299bae606:/# mount | grep rodata
osxfs on /rodata type fuse.osxfs (ro,relatime,user_id=0,group_id=0,allow_other,max_read=1048576)
root@ad5299bae606:/# ls -l /rodata/
total 0
root@ad5299bae606:/# touch /rodata/readonlydatafile
touch: cannot touch '/rodata/readonlydatafile': Read-only file system
```
除了可以挂载目录之外，文件也可以作为数据卷挂载到容器中。

## 挂载宿主机文件
如果想让所有的容器都可以共享宿主机的/etc/apt/sources.list，从而只需要改变宿主机的apt源就能够影响到所有的容器。
```bash 
docker run -t -i --name file -v /etc/apt/sources.list:/etc/apt/sources.list:ro ubuntu /bin/bash
```
> 此命令适合linux系统中执行，在mac os中无/etc/apt/sources.list文件

如果想共享一个数据卷给多个容器怎么办，比如设想一个场景，我们有两个处理上传数据的应用运行在不同的容器中，但需要同时读取同一个文件夹下的文件，此时，最好的方式是使用数据卷容器。

## 使用数据卷容器共享数据
如果需要在多个容器间共享数据，并希望永久保存这些数据，最好的方式是使用数据卷容器，类似于一个提供网络文件共享服务的NFS服务器。

数据卷容器创建方法跟普通容器一样，只需要指定宿主机的一个文件夹作为数据卷即可，使用`docker create`命令创建但不启动数据卷容器,
```bash 
➜ docker create -v /sharedb --name sharedb ubuntu /bin/true
b73abf556db4e76edc79bb7514cfa4067fd891ffb4d26105eec32ab612b83d78
➜ docker ps
dCONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
➜ docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
b73abf556db4        ubuntu              "/bin/true"         4 hours ago         Created                                 sharedb
```

其他使用该数据卷容器的容器创建时候需要使用`--volumes-from`参数，指定该容器名称或ID,
```bash 
docker run --volumes-from sharedb...
```
创建site1和site2两个容器挂载数据卷容器sharedb,
```
➜  ~ docker run --volumes-from sharedb --name site1 -t -i ubuntu /bin/bash
root@e0984656600a:/# %                                                                                                ➜  ~ docker run --volumes-from sharedb --name site2 -t -i ubuntu /bin/bash
root@7bf4a2ebe458:/# %                                                                                                ➜  ~ docker attach site1
root@e0984656600a:/#
root@e0984656600a:/# ls -l /sharedb/
total 0
root@e0984656600a:/# touch /sharedb/site1file
root@e0984656600a:/# %                                                                                                ➜  ~ docker attach site2
root@7bf4a2ebe458:/#
root@7bf4a2ebe458:/# ls -l /sharedb/
total 0
-rw-r--r-- 1 root root 0 Mar  6 13:01 site1file
root@7bf4a2ebe458:/# touch /sharedb/fromsite2file
root@7bf4a2ebe458:/# %                                                                                                ➜  ~ docker attach site1
root@e0984656600a:/#
root@e0984656600a:/# ls /sharedb/
fromsite2file  site1file
root@e0984656600a:/#
```
上面通过连接到这两个容器中对数据卷进行操作，并查看彼此之间已经有了共享文件。

## 数据卷备份
既然可以利用数据卷容器共享数据， 那如何备份这些共享数据呢？下面通过一个完整的案例来操作如何进行数据卷备份，

1.创建一个新的容器
2.挂载数据卷容器
3.挂载宿主机本地目录作为数据卷
4.将数据卷容器的内容备份到宿主机本地目录挂载的数据卷中
5.完成备份操作后容器销毁

```bash 
➜  ~ docker run --rm --volumes-from sharedb -v /tmp/backup:/backup ubuntu tar cvf /backup/sharedb.tar /sharedb
tar: Removing leading `/' from member names
/sharedb/
/sharedb/fromsite2_file
/sharedb/fromsite1_file
/sharedb/fromsite2file
/sharedb/site1file
➜  ~ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
2207035e4d5c        ubuntu              "/bin/bash"         4 hours ago         Up 2 minutes                            site2
350af1aa2bc6        ubuntu              "/bin/bash"         4 hours ago         Up 3 minutes                            site1
➜  ~ ls /tmp/backup/sharedb.tar
```

## 总结

- 创建数据卷
- 管理数据卷权限
- 挂载宿主机文件
- 使用数据卷容器共享数据
- 数据卷备份
