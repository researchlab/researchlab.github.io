---
title: "docker实践--04 网络管理"
date: 2017-03-07 12:01:18
categories: [docker-practice]
tags: [docker]
description:
---

Docker中的网络一直是比较弱的, 本文从基础配置到访问控制再到容器互联等几个方面进行总结, 在较早期的docker版本中只提供最基本的网络通信支持, 如早期版本支持的最常见的三种场景, 
1.使用NAT方式连接外部网络;
2.映射容器和宿主机的端口, 使外部可以访问容器中的应用;
3.容器间网络互联.
<!--more-->

## 网络基本配置

** 1. 默认情况 **

Docker服务启动时会自动创建一个`docker0`的虚拟网桥，后续新创建的容器都会有个虚拟接口连接到这个网桥,
```bash
lihong@dev:~$ ifconfig docker0
docker0   Link encap:Ethernet  HWaddr 02:42:3e:4c:b6:22
          inet addr:172.17.0.1  Bcast:0.0.0.0  Mask:255.255.0.0
          inet6 addr: fe80::42:3eff:fe4c:b622/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:8317 errors:0 dropped:0 overruns:0 frame:0
          TX packets:12931 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:341661 (341.6 KB)  TX bytes:27114650 (27.1 MB)
```
Docker网桥会设置为NAT模式, 自动分配一个网段, 从上面看`docker0`的地址是`172.17.0.1`, 每个容器都会自动分配的到一个IP地址,
```bash
lihong@dev:~$ docker attach demo
root@1b9a2f9bfd51:/#
root@1b9a2f9bfd51:/# ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:ac:11:00:02
          inet addr:172.17.0.2  Bcast:0.0.0.0  Mask:255.255.0.0
          inet6 addr: fe80::42:acff:fe11:2/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:20 errors:0 dropped:0 overruns:0 frame:0
          TX packets:7 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:2878 (2.8 KB)  TX bytes:578 (578.0 B)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```
可以看到创建`demo`容器的ip地址是`172.17.0.2`， 可以通过`docker inspect`命令来详细查看`demo`容器的各项配置信息, 如查看`demo`容器的ip地址和网关地址，
```bash 
lihong@dev:~$ docker inspect -f '{{.NetworkSettings.Gateway}}' demo
172.17.0.1
lihong@dev:~$ docker inspect -f '{{.NetworkSettings.IPAddress}}' demo
172.17.0.2
```
通过上面可知，用户可以为`Docker`服务指定不同的网桥以及网段，这些配置都可以写在`/etc/default/docker`文件中, 作为服务启动的参数。

** 2. 配置文件 /etc/default/docker **
`/etc/default/docker`文件为Ubuntu 16.04.2操作系统中`Docker`服务启动时使用的配置文件，不同的操作系统位置会有不同。这个文件本身是个 Shell 脚本, 配置文件内容如下,
```bash
lihong@dev:~$ cat /etc/default/docker
# Here in Debian, this file is sourced by:
#   - /etc/init.d/docker (sysvinit)
#   - /etc/init/docker (upstart)
#   - systemd's docker.service

# Use of this file for configuring your Docker daemon is discouraged.

# The recommended alternative is "/etc/docker/daemon.json", as described in:
#   https://docs.docker.com/v1.11/engine/reference/commandline/daemon/#daemon-configuration-file

# If that does not suit your needs, try a systemd drop-in file, as described in:
#   https://docs.docker.com/v1.11/engine/admin/systemd/#custom-docker-daemon-options
```

可以看到上述说明已经不建议使用`/etc/default/docker`来配置`docker daemon`参数了，并且它给出了使用新方法的参考地址，其实就是在命令行中输入参数。记得老版本的`docker`要对网络进行配置，只需将必要的配置参数填入`/etc/default/docker`配置文件中的`DOCKER_OPTS`启动参数行即可。

下面通过一个栗子展示如何修改docker网络配置, 具体步骤大致如下,
- 删除原有的docker0虚拟网络
- 创建一个新的虚拟网络newnet0
- 配置newnet0的网段为172.17.100.1/22
- 配置Docker使用新的虚拟网络newnet0

首先, 删除docker0, 删除前需要删除所有容器并停止Docker服务,
操作命令如下,
```bash
# 安装brctl管理工具
sudo apt-get install bridge-utils

# 查看当前虚拟网络列表
sudo brctl show

# 停止docker服务
sudo service docker stop

# 停止docker0
sudo ip link set dev docker0 down

# 删除docker0
sudo brctl delbr docker0
```
操作结果如下,
```bash 
lihong@dev:~$ sudo apt install bridge-utils
[sudo] password for lihong:
Reading package lists... Done
Building dependency tree
Reading state information... Done
bridge-utils is already the newest version (1.5-9ubuntu1).
bridge-utils set to manually installed.
0 upgraded, 0 newly installed, 0 to remove and 61 not upgraded.
lihong@dev:~$ sudo brctl show
bridge name    	bridge id      		STP enabled    	interfaces
docker0		8000.02423e4cb622      	no     		veth136401f
lihong@dev:~$ sudo service docker stop
lihong@dev:~$ sudo ip link set dev docker0 down
lihong@dev:~$ sudo brctl delbr docker0
lihong@dev:~$ sudo brctl show
bridge name    	bridge id      		STP enabled    	interfaces
lihong@dev:~$
```
然后, 开始创建一个新的虚拟网络：
```bash
lihong@dev:~$ sudo brctl addbr newnet0
lihong@dev:~$ sudo brctl show
bridge name    	bridge id      		STP enabled    	interfaces
newnet0		8000.000000000000      	no
```

配置`newnet0`的网络,
```bash 
lihong@dev:~$ sudo ip addr add 172.17.100.1/22 dev newnet0
lihong@dev:~$ sudo ip addr show newnet0
8: newnet0: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether 8a:38:24:8d:6c:e6 brd ff:ff:ff:ff:ff:ff
    inet 172.17.100.1/22 scope global newnet0
       valid_lft forever preferred_lft forever
lihong@dev:~$ sudo ip link set dev newnet0 up
lihong@dev:~$ sudo brctl show newnet0
bridge name    	bridge id      		STP enabled    	interfaces
newnet0		8000.000000000000      	no
lihong@dev:~$
```

下面就要重启docker daemon 来修改一下配置参数, 如下,
```bash
lihong@dev:~$ sudo dockerd -b=newnet0 --icc=false --ip-forward=true
[sudo] password for lihong:
INFO[0000] libcontainerd: new containerd process, pid: 25310
INFO[0006] libcontainerd: new containerd process, pid: 25316
WARN[0000] containerd: low RLIMIT_NOFILE changing to max  current=1024 max=65536
INFO[0011] [graphdriver] using prior storage driver "aufs"
INFO[0013] Graph migration to content-addressability took 0.00 seconds
WARN[0013] Your kernel does not support swap memory limit.
INFO[0013] Loading containers: start.
.INFO[0015] Firewalld running: false

INFO[0020] Loading containers: done.
INFO[0020] Daemon has completed initialization
INFO[0020] Docker daemon                                 commit=78d1802 graphdriver=aufs version=1.12.6
INFO[0021] API listen on /var/run/docker.sock
```
docker1.12.6版本启动守护进程不再是`docker daemon`,而是用`dockerd`的代替了,下面关于上面参数设置说明, 
`-b` --bridge ：指定连接的网桥
`--icc`=true|false：是否允许容器间网络互通
`--ip-forward`=true|false：是否允许IP转发，可以对容器的外网访问进行限制

可以通过创建新的容器来看下修改后的效果,
```bash
lihong@dev:~$ docker run -t -i --name container ubuntu /bin/bash
root@47fc5e302c80:/# ifconfig
bash: ifconfig: command not found
root@47fc5e302c80:/# apt update
Get:1 http://archive.ubuntu.com/ubuntu xenial InRelease [247 kB]
....
Get:15 http://archive.ubuntu.com/ubuntu xenial-updates/universe amd64 Packages [545 kB]
Fetched 24.9 MB in 52s (473 kB/s)
Reading package lists... Done
Building dependency tree
Reading state information... Done
All packages are up to date.
root@47fc5e302c80:/# apt install net-tools
Reading package lists... Done
Building dependency tree
Reading state information... Done
The following NEW packages will be installed:
  net-tools
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Unpacking net-tools (1.60-26ubuntu1) ...
Setting up net-tools (1.60-26ubuntu1) ...
root@47fc5e302c80:/# ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:ac:11:64:02
          inet addr:172.17.100.2  Bcast:0.0.0.0  Mask:255.255.252.0
          inet6 addr: fe80::42:acff:fe11:6402/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:12780 errors:0 dropped:0 overruns:0 frame:0
          TX packets:5551 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:25924957 (25.9 MB)  TX bytes:305225 (305.2 KB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

root@47fc5e302c80:/# apt install iputils-ping
Reading package lists... Done
....
root@47fc5e302c80:/# ping 172.17.100.1
PING 172.17.100.1 (172.17.100.1) 56(84) bytes of data.
64 bytes from 172.17.100.1: icmp_seq=1 ttl=64 time=0.095 ms
root@47fc5e302c80:/#
```
从上面的实践可知新容器创建时，IP地址被自动分配为`172.17.100.2`; 此外在容器启动时, `docker run`命令也有网络相关的参数，可以在容器启动时进行针对单个容器的网络配置, 常见的配置选项,
`-h --hostname`：配置容器主机名;
`--link`：添加另外一个容器的链接;
`--net=bridge|none|container|host`：设置容器的网络模式;
下面创建一个新的容器，设置主机名为test1，网络模式为none,
```bash 
lihong@dev:~/docker$ docker run --name test1 --hostname test1 --net none -t -i nbuntu /bin/bash
root@test1:/# ifconfig
lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

root@test1:/# hostname
test1
```
可以看到网络模式none设置后，在容器中没有出现`eth0`网卡了。

## 网络访问控制
容器默认是通过docker0的NAT模式访问外部网络，如果我们希望限制容器访问，有很多种办法,

** 1. 限制容器访问外网 **
在上面的实践中创建的`container`容器是可以连接外网的，是通过`newnet0`虚拟交换机进行了NAT转换,
```bash 
lihong@dev:~/docker$ docker attach demo
root@1b9a2f9bfd51:/#
root@1b9a2f9bfd51:/# ping www.baidu.com
PING www.a.shifen.com (119.75.217.109) 56(84) bytes of data.
64 bytes from 119.75.217.109: icmp_seq=1 ttl=127 time=32.4 ms
64 bytes from 119.75.217.109: icmp_seq=2 ttl=127 time=32.0 ms
--- www.a.shifen.com ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 32.012/32.206/32.400/0.194 ms
```

限制容器访问外网，可以关闭IP转发，设置方法是启动Docker时`--ip-forward=false`
```bash 
lihong@dev:~$ sudo dockerd -b=newnet0 --icc=false --ip-forward=false
[sudo] password for lihong:
INFO[0000] libcontainerd: new containerd process, pid: 27004
WARN[0000] containerd: low RLIMIT_NOFILE changing to max  current=1024 max=65536
INFO[0001] [graphdriver] using prior storage driver "aufs"
INFO[0001] Graph migration to content-addressability took 0.00 seconds
WARN[0001] Your kernel does not support swap memory limit.
INFO[0001] Loading containers: start.
.INFO[0001] Firewalld running: false

INFO[0001] Loading containers: done.
INFO[0001] Daemon has completed initialization
INFO[0001] Docker daemon                                 commit=78d1802 graphdriver=aufs version=1.12.6
INFO[0001] API listen on /var/run/docker.sock
```

创建新的容器，查看关闭IP转发后的效果, 
```bash
lihong@dev:~/docker$ docker run -ti --name noip nbuntu /bin/bash
root@04972966e18b:/# ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:ac:11:64:02
          inet addr:172.17.100.2  Bcast:0.0.0.0  Mask:255.255.252.0
          inet6 addr: fe80::42:acff:fe11:6402/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:14 errors:0 dropped:0 overruns:0 frame:0
          TX packets:6 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1938 (1.9 KB)  TX bytes:508 (508.0 B)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

root@04972966e18b:/# ping www.baidu.com
PING www.a.shifen.com (119.75.217.109) 56(84) bytes of data.
64 bytes from 119.75.217.109: icmp_seq=1 ttl=127 time=32.8 ms
```
不过并没有效果，依然可以ping www.baidu.com, 然后看`dockerd`输出的结果是, 
```bash
lihong@dev:~$ sudo dockerd -b=newnet0 --icc=false --ip-forward=false --ipv6=false
....
INFO[0021] No non-localhost DNS nameservers are left in resolv.conf. Using default external servers : [nameserver 8.8.8.8 nameserver 8.8.4.4]
INFO[0021] IPv6 enabled; Adding default IPv6 external servers : [nameserver 2001:4860:4860::8888 nameserver 2001:4860:4860::8844]
```
上述`--ip-forward=false`表示`ipv4`禁止转发, `ipv6=false`表示禁`ipv6`, 但是实际好像不起作用, 目前还不知道什么情况?

注意, 如果有容器正在运行时重启Docker服务，所有运行的容器都会被强制停止。Docker服务重启后也不会重启被停止的容器。

** 2. 限制容器间的访问 **

限制容器间的访问，可以设置`--icc`参数，或设置`iptables`参数。默认容器间可以互相访问，通过设置`--icc=false`可以禁止, 即此时不同的容器间不能互ping对方，无法进行通信, 
```bash
lihong@dev:~$ docker run --name site1 -ti nbuntu /bin/bash
root@73b9d8b7ec70:/# ifconfig eth0
eth0      Link encap:Ethernet  HWaddr 02:42:ac:11:64:02
          inet addr:172.17.100.2  Bcast:0.0.0.0  Mask:255.255.252.0
          inet6 addr: fe80::42:acff:fe11:6402/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:16 errors:0 dropped:0 overruns:0 frame:0
          TX packets:6 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:2338 (2.3 KB)  TX bytes:508 (508.0 B)

root@73b9d8b7ec70:/# ping 172.17.100.3
PING 172.17.100.3 (172.17.100.3) 56(84) bytes of data.

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
lihong@dev:~/docker$ docker run --name site2 -ti nbuntu /bin/bash
root@7395b959e752:/# ifconfig eth0
eth0      Link encap:Ethernet  HWaddr 02:42:ac:11:64:03
          inet addr:172.17.100.3  Bcast:0.0.0.0  Mask:255.255.252.0
          inet6 addr: fe80::42:acff:fe11:6403/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:8 errors:0 dropped:0 overruns:0 frame:0
          TX packets:5 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:920 (920.0 B)  TX bytes:418 (418.0 B)

root@7395b959e752:/# ping 172.17.100.2
PING 172.17.100.2 (172.17.100.2) 56(84) bytes of data.
```

可以看到site1,site2互ping是不通的，因为`docker`启动时设置`-icc=false`禁止了容器之间互通, 如果需要打开容器间访问, 只需要设置`--icc=true`即可。

## 容器端口映射
运行`docker run`的时候可以使用`-P`参数进行端口映射，这个参数不需要指定任何宿主机的端口，会自动从49000~49900端口中选择一个映射到容器中开放的端口。

而容器中开放的端口号如何获得呢？可以写在创建镜像的Dockerfile中：
```bash 
FROM ubuntu:latest

EXPOSE 80
```
基于该Dockerfile创建一个新的镜像port
```bash
lihong@dev:~/docker$ vim Dockerfile
lihong@dev:~/docker$ cat Dockerfile
from ubuntu:latest

EXPOSE 80
lihong@dev:~/docker$ docker build -t port:1.0 .
Sending build context to Docker daemon 2.048 kB
Step 1 : FROM ubuntu:latest
 ---> 0ef2e08ed3fa
Step 2 : EXPOSE 80
 ---> Running in 487a948fcda6
 ---> 35d62582a16a
Removing intermediate container 487a948fcda6
Successfully built 35d62582a16a
lihong@dev:~/docker$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
port                1.0                 35d62582a16a        10 seconds ago      130 MB
nbuntu              latest              f16a2621960a        39 minutes ago      174.2 MB
ubuntu              latest              0ef2e08ed3fa        8 days ago          130 MB
lihong@dev:~/docker$ docker run -P -ti --name portdemo port:1.0 /bin/bash
root@2d4b6a054e9e:/# lihong@dev:~/docker$
lihong@dev:~/docker$ docker inspect -f {{.NetworkSettings.Ports}} portdemo
map[80/tcp:[{0.0.0.0 32768}]]
```
如果想指定映射端口，可以使用`-p`参数，请注意一个宿主机的端口只能绑定到一个容器，如果该端口已经有进程在用则不可以绑定。并且`-p`参数可以绑定多个端口,
```bash
lihong@dev:~/docker$ docker run -ti -p 80:80 -p 5000:5000 --name portdemo1 port:1.0 /bin/bash
root@dfb3563babd5:/# lihong@dev:~/docker$
lihong@dev:~/docker$ docker inspect -f {{.NetworkSettings.Ports}} portdemo1
map[5000/tcp:[{0.0.0.0 5000}] 80/tcp:[{0.0.0.0 80}]]
```
如果想映射到指定的本地地址，可以增加`IP`参数，比如映射到`127.0.0.1`地址，只需要将参数写成 `-p 127.0.0.1:80:80`。
查看指定容器的端口映射可以使用`docker port`命令,
```bash
lihong@dev:~/docker$ docker port portdemo1 80
0.0.0.0:80
lihong@dev:~/docker$ docker port portdemo1
5000/tcp -> 0.0.0.0:5000
80/tcp -> 0.0.0.0:80
```
`Docker`的端口映射也是通过`iptables`规则来设置的，当完成映射后，使用`iptables`命令查看是否新增了规则,
```bash
lihong@dev:~/docker$ sudo iptables -L
[sudo] password for lihong:
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination
DOCKER-ISOLATION  all  --  anywhere             anywhere
DOCKER     all  --  anywhere             anywhere
ACCEPT     all  --  anywhere             anywhere             ctstate RELATED,ESTABLISHED
ACCEPT     all  --  anywhere             anywhere
DROP       all  --  anywhere             anywhere

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

Chain DOCKER (1 references)
target     prot opt source               destination
ACCEPT     tcp  --  anywhere             172.17.100.2         tcp dpt:5000
ACCEPT     tcp  --  anywhere             172.17.100.2         tcp dpt:http

Chain DOCKER-ISOLATION (1 references)
target     prot opt source               destination
RETURN     all  --  anywhere             anywhere
```

## 容器互联

** 需求 **
设定一个场景，我们的应用包含多个容器,

容器1：Web前端服务 端口80
容器2：App应用服务 端口80
容器3：Redis数据库服务 端口6379
创建容器后，如何让这三个容器连接共同构成我们所需的Web应用服务呢？

此时我们并不想将每个容器的端口都通过映射的方式暴露出来，那么Docker又提供了怎样的方案呢？

这就需要用到Docker强大的`--link`参数，完美支持容器间互联。

** 需求分析 **

需要创建三个容器, 分别根据作用命名, 在创建过程中使用`--link`参数让容器间建立安全的互联通道。
`docker run`命令的`--link`参数可以在不映射端口的前提下为两个容器间建立安全连接。`--link`参数可以连接一个或多个容器到将要创建的容器。

现在假设三个容器命名为: web, app, db, 连接方式分别是web连接app, app连接db。其中web和app容器使用上面创建的EXPOSE 80端口的镜像port:1.0。

** 需求实现 **

首先依次创建三个容器db, app 和web,
```bash 
lihong@dev:~/docker$ docker run -d --name db redis
Unable to find image 'redis:latest' locally
latest: Pulling from library/redis
693502eb7dfb: Pull complete
338a71333959: Pull complete
83f12ff60ff1: Pull complete
4b7726832aec: Pull complete
19a7e34366a6: Pull complete
622732cddc34: Pull complete
3b281f2bcae3: Pull complete
Digest: sha256:e4a69910ba49d7c211135df2b8220ee94c634f4789c9b3c7ed391a36bbdbddbf
Status: Downloaded newer image for redis:latest
25a3e1d54cac360110cee428b29e7c6db293353043fabc0f5e2e6a40b5a84d37
lihong@dev:~/docker$ docker run -ti --name app --link db:db port:1.0 /bin/bash
root@49b603633f45:/# lihong@dev:~/docker$ docker run -ti --name web --link app:app port:1.0 /bin/bash
root@e19881f8497c:/#
```
注: `-d`, --detach                  Run container in background and print container ID

现在进入到`web容器`中可以查看到`--link`参数为了连接容器做了哪些改变,
```bash
root@e19881f8497c:/# cat /etc/hosts
127.0.0.1      	localhost
::1    	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
ff00::0	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.17.100.3   	app 49b603633f45
172.17.100.4   	e19881f8497c
root@e19881f8497c:/# ping app
PING app (172.17.100.3) 56(84) bytes of data.
64 bytes from app (172.17.100.3): icmp_seq=1 ttl=64 time=0.072 ms
64 bytes from app (172.17.100.3): icmp_seq=2 ttl=64 time=0.062 ms
^C
--- app ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1015ms
rtt min/avg/max/mdev = 0.062/0.067/0.072/0.005 ms
root@e19881f8497c:/# env | grep APP
APP_PORT_80_TCP_PORT=80
APP_PORT_80_TCP_ADDR=172.17.100.3
APP_PORT_80_TCP=tcp://172.17.100.3:80
APP_PORT_80_TCP_PROTO=tcp
APP_NAME=/web/app
APP_PORT=tcp://172.17.100.3:80
root@e19881f8497c:/#
```

注意: 要使得容器间互通, 要保证`dockerd`启动时, `--icc=true`设置或者不设置这个参数, 因为默认是true, 否则如上面的ping app是ping不通的,

可以看到环境变量和/etc/hosts文件的变化，在web容器中可以`ping app`进行测试。
通过`--link`参数可以把几个容器绑定在一起，并且不需要向外部公开内部应用容器和数据库容器的端口号，只需要将对外提供服务的web服务端口`80`开放即可。

## 总结

本文主要实践了如下内容, 

- Docker 网络基本配置
- Docker 网络访问控制
- Docker 容器端口映射
- Docker 容器互联

额外收获如下,

> 实验过程中在Mac/Linux(ubuntu)系统中同时进行(即在Mac上做一遍然后又到ubuntu上做一遍(简直时间多，折腾啊)), 其中遇到问题的相关解决方案记录

** 1. 在ubuntu上安装docker之后，pull东西慢 **
从docker Hub上pull东西很慢,是因为使用的是国外的下载源, 所以要修改docker Hub pull的源, 本文解决方案是到daocloud.io官网注册一个账号,然后到控制台那有个加速器会生成一个docker 加速器地址，按照它的说明更换掉docker源即可。

** 2. 没有`ifconfig`, `ping`命令 **
通过docker 运行的镜像ubuntu容器里没有`ifconfig`, `ping`命令, 这个可以直接进入相关的容器执行下面三条命令即可将`ifconfig`, `ping`命令安装上来,
```bash 
apt-get update 
apt install net-tools    # ifconfig
apt install iputils-ping # ping
```

