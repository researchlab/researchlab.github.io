---
title: "搭建私有镜像管理Docker Registry容器服务"
date: 2017-09-15 14:32:05
categories: [docker-practice]
tags: [docker]

description:
---

## 前言
Docker Registry 是一个用来管理Docker镜像的服务，本身也是一个Docker容器。搭建一个私有的Docker Registry的使用场景主要有下面几个:
1.当需要对容器镜像存储进行完全控制,就不能依赖官方提供的Docker Hub进行管理;
2.当内部使用存在网络问题或安全问题等情况都适合搭建私有的Docker Registry对镜像进行管理;

下面从需频繁pull镜像到某内部机器上新建容器的需求来搭建需要认证访问的Docker Registry,这样同时可以解决网络依赖问题及安全问题, 下面是搭建Docker Registry过程的记录和总结;
<!--more-->


## 搭建Docker Registry

1.要搭建本地私有Registry, 首先需要一个Docker Registry基础镜像,直接pull官方镜像即可,
```bash 
docker pull registry 
```

2.通过下面的命令运行一个基于上面pull的Registry容器服务, 
```bash
docker run -d -p 5000:5000 --restart=always -v /opt/registry-var/:/var/lib/registry/ registry:latest
```

**注:** 
- 上面需要注意的是新registry仓库数据目录的位置。容器内部新registry的仓库目录是在/var/lib/registry, 所以运行时挂载目录需要注意,因为挂着到别的目录是运行不的;
- 其中`-v`选项 是将本地(宿主机)/opt/registry-var/目录挂载到容器的/var/lib/registry/目录上,

当上面Registry服务启动之后可通过curl http://100.73.41.17:5000/v2/_catalog (假设上面启动Registry服务的的机器ip为:100.73.41.17)能看到json格式的返回值时，说明registry已经运行起来了。

但上面运行的Registry服务是没有设置认证权限的,即未授权用户也是可以访问上述Registry服务的，为了安全起见一般都会设置认证权限用于访问,

3.配置带用户权限的registry
现在registry已经可以使用了。如果想要控制registry的使用权限，使其只有在登录用户名和密码之后才能使用的话，还需要做额外的设置。
registry的用户名密码文件可以通过htpasswd来生成,
```bash 
mkdir /opt/registry-var/auth/
docker run --entrypoint htpasswd registry:latest -Bbn felix felix  >> /opt/registry-var/auth/htpasswd
```
上面这条命令是为felix用户名生成密码为felix的一条用户信息，存在/opt/registry-var/auth/htpasswd文件里面，文件中存的密码是被加密过的。
启动带权限配置的docker Registry服务就需要多加几个配置参数了, 启动命令如下:

```bash 
docker run -d -p 5000:5000 --restart=always \
  -v /opt/registry-var/auth/:/auth/ \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -v /opt/registry-var/:/var/lib/registry/ \
  registry:latest
```

**注:**
- 挂载认证目录到容器中: `-v /opt/registry-var/auth/:/auth/`
- 设置认证方式: `-e "REGISTRY_AUTH=htpasswd"` 
- 设置认证方式: `-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm"` 
- 设置认证路径: `-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd`
- 挂载镜像目录: `-v /opt/registry-var/:/var/lib/registry/`
- 端口映射 `-p 5000:5000` 注意Docker Registry容器内部默认监听的是`5000`端口,如果要修改内部监听端口可通过指定参数`REGISTRY_HTTP_ADDR`即可修改，如修改为内部监听`5001`端口,

```bash 
docker run -d --restart=always \
	-e REGISTRY_HTTP_ADDR=0.0.0.0:5001 \
  -p 5000:5001 \
  -v /opt/registry-var/auth/:/auth/ \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -v /opt/registry-var/:/var/lib/registry/ \
  registry:latest
```

## 管理镜像
上面认证Docker Registry 服务准备好之后，就可以用来管理镜像了，管理镜像一般分下面三步,
1.认证登录Docker Registry
因为需要认证所以在管理镜像时首选需要通过下面的命令认证登录,
```bash 
docker login 100.73.41.17:5000
```
通过上述命令按照提示输入登录名和密码即可登录，但是有可能会遇到下面的提示,而登录失败,
```bash 
➜  docker login 100.73.41.17:5000
Username (xxx): xxx 
Password:
Error response from daemon: Get https://100.73.41.17:5000/v2/: http: server gave HTTP response to HTTPS client
```
这个提示已经很明显告诉你是因为client(https)请求与server(http)接收端协议对不上导致,那如何解决？ 网上千篇一律的告诉你要做如下设置:
```bash 
➜  cat /etc/docker/daemon.json
{
"insecure-registries":["100.73.41.17:5000"]
}
```
是的没错, 是通过上述设置即可解决问题,但是这个设置不是设置在Docker Registry启动的那台机器上(上面是:100.73.41.17), 这个是要设置在你在那台机器上进行登录上传下载镜像操作的机器上，

如上面所设置，我的Docker Registry是搭建在100.73.41.17这台远程机器上,而我需要在本地的Mac 机器上登录远程得这个私有的Docker Registry 进行上传下载操作，那么上面的设置就要设置在我的Mac机器的Docker配置中;

但是在Mac机器上好像没有发现/etc/docker/daemon.json这个文件，后来通过docker client的图形界面进行设置的，如下，设置之后需要重启docker server,如我需要重启Mac机器上的docker server;
<center>![set insecure-registries](imgs/set_insecure_registries.png)图1 设置insecure-registries</center>

不过设置`insecure-registries`是非常不安全的，官方文档中也不推荐而是给出自己生成证书的方式进行认证，[官方链接](https://docs.docker.com/registry/insecure/#troubleshoot-insecure-registry)
而生产环境中一般需要配置两道认证，第一道认证即证书认证就是将启动Docker Registry 服务的认证证书copy一份到操作Docker Registry机器上（如我的Mac机器）， 第二道认证即上面的用户名密码认证; 具体[官方链接](https://docs.docker.com/registry/deploying/#native-basic-auth)

1.写入本地镜像到私有Docker Registry,
上面登录成功后，接着就可以把本地的镜像推送到远程私有Docker Registry上去了,不过这里需要注意的是待推送到远程Registry上去的本地镜像其名字前缀必须设置为`100.73.41.17:5000/`, 因为下面要去取镜像时,按照docker读取镜像的规则是`镜像地址/镜像名称`, 通过镜像地址读取镜像名称, 如果在读取镜像是只给出镜像名称, 则Docker会到官方的Docker Hub上去下载相应的镜像而非本地私有Registry库;下面假设已经制作了一个jenkins镜像但是其前缀不是上面的Registry服务地址,可通过docker tag命令给镜像重新命名然后上传到私有Registry即可，具体命令如下,
```bash 
docker tag jenkins:latest 100.73.41.17:5000/jenkins:latest
docker push 100.73.41.17:5000/jenkins:latest
```

2.读取镜像到本地
上面成功把镜像推送到远程Docker Registry服务上之后，要用时怎么读取到本地？ 在认证登录远程私有Docker Registry通过如下pull命令即可取回目标镜像,
```bash 
docker pull 100.73.41.17:5000/jenkins:latest
```

3.删除镜像
当镜像上传到远程私有Docker Registry 之后, 发现不需要想删除怎么办？ docker registry应该提供了删除镜像的方法的,不过这个好像在启动Docker Registry 需要配置可删除的开关才行,那么有什么简单的办法可以直接删除呢？办法当然有, 还记得在启动Docker Registry容器服务时, 挂载的镜像目录`-v /opt/registry-var/:/var/lib/registry/` ？ 是的你上传的镜像其实都在本地的`/opt/registry-var/`目录下,在这里手动删除即可，虽然简单粗暴；


## 详细配置
上面启动Docker Registry 服务对镜像进行管理,但是这个Registry还有些什么特性可以用于对镜像的管理呢？可以通过设置镜像启动容器的配置来管理, 
首先在本地配置好自定义配置然后通过volume挂载到容器内部即可，这样Registry容器启动命令如下,
```bash 
docker run -d --restart=always \
	-e REGISTRY_HTTP_ADDR=0.0.0.0:5001 \
  -p 5000:5001 \
  -v /opt/registry-var/auth/:/auth/ \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -v /opt/registry-var/:/var/lib/registry/ \
	-v /local/path/to/config.yml:/etc/docker/registry/config.yml \
  registry:latest
```

其中Registry 容器的官方配置文件及配置字段参考官方即可[Registry配置文件及配置字段官方文档](https://docs.docker.com/registry/configuration/#list-of-configuration-options)


## 总结
1.本文总结了如何搭建私有Docker Registry服务;
2.本文总结了如何设置认证权限,并建议在生成环境中同时配置证书认证及密码认证两道安全认证措施;
3.同时也演示了如何用搭建好的私有Docker Registry服务进行镜像上传下载删除等管理工作；
4.在总结本文时重点参考了官方文档, 发现之前在搭建Docker  Registry服务时并没有这么清楚，包括出现的错误等问题也是先通过搜索引擎来解决问题，但现在看来其实官方文档中也给出了可能存在的异常情况并给出了较为全面的解决方案;
