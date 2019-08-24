---
title: "minikube从本地docker registry 拉取镜像的两种方法"
date: 2019-08-24 19:47:33
categories: k8s
tags: minikube
description:
---
在mac中用minikube搭建了一个k8s环境，但是每次拉取镜像都很慢甚至失败, 本文总结两种从本地私有镜像仓库拉取镜像的方法实践, 先将镜像在宿主机上翻墙拉取到本地, 再由minikube 虚机中的k8s 来拉取本地镜像, 这样即可解决之前的拉取镜像失败，也可提升拉取镜像的速度;
<!--more-->

## 两种方案
1. 把私有镜像仓库docker registry 搭建在宿主机上, k8s从本地宿主机上拉取镜像;
2. 把本地镜像推送到minikube的私有镜像仓库上, k8s从minikube的私有镜像仓库(k8s的本地私有镜像仓库)拉取镜像;

## 方案一: k8s从宿主机私有镜像仓库中拉取镜像

1. 搭建宿主机私有镜像仓库; 

```shell
#!/bin/bash 

docker pull registry

docker run -d -p 5000:5000 -v $(pwd):/var/lib/registry --restart always --name registry registry:2 
```

2. 验证私有镜像仓库

```shell
curl http://127.0.0.1:5000/v2/_catalog
{"repositories":[]}
```

3. 推送镜像到私有镜像仓库

对docker 作出如下配置，并重启使其生效,

```shell
{
  "insecure-registries" : [
    "10.21.71.237:5000"
  ],
  "debug" : true
}

```

> 10.21.71.237 是宿主机ip 

> mac 配置路径:  工具栏--> docker --> Preferences --> Daemon --> basic --> Insecure registries 加上一行:  10.21.71.237:5000

为镜像打tag, 并推送

```shell
➜  docker tag luksa/kubia 10.21.71.237:5000/kubia-local
➜  docker push 10.21.71.237:5000/kubia-local
The push refers to repository [10.21.71.237:5000/kubia-local]
5ef1e33458c5: Pushed
dff19e36a9d2: Pushed
28e6af096bca: Pushed
d84d07ed960c: Pushed
894dceed4a75: Pushed
f078de0e3e2b: Pushed
e6562eb04a92: Pushed
596280599f68: Pushed
5d6cbe0dbcf9: Pushed
latest: digest: sha256:0d41ead4dbf022881deafdea4cc3c5a46e0315ebd5805b40f8bbcb7d8b745575 size: 2213
```

4 配置minikube 并重启

minikube 配置如下, 并重启(重启时确保翻墙VPN开启)

```shell
#!/bin/bash
minikube delete && minikube start --cpus=2 --memory=4096 --disk-size=10g \
	--docker-env http_proxy=10.21.71.237:1087 \
	--docker-env https_proxy=10.21.71.237:1087 \
	--docker-env no_proxy=192.168.99.0/24 \
	--registry-mirror=https://registry.docker-cn.com \
  --insecure-registry=10.21.71.237:5000
```

> 为了使得minikube 虚机中的k8s 能拉取到宿主机私有镜像 需要上述两项配置  --registry-mirror 和 --insecure-registry

5 k8s 拉取宿主机私有镜像仓库镜像

k8s pod 文件如下, 
```shell
➜  k8s cat kubia-local.yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-local-pod
spec:
  containers:
    - image: 10.21.71.237:5000/kubia-local
      imagePullPolicy: IfNotPresent
      name: kubia-local-mike
      ports:
      - containerPort: 8080
        protocol: TCP
```

创建 kubia-local pod ,

```shell
➜  k8s kubectl create -f kubia-local.yaml
➜  k8s kubectl describe pod kubia-local-pod
Name:               kubia-local-pod
Namespace:          default
Priority:           0
PriorityClassName:  <none>
Node:               minikube/10.0.2.15
Start Time:         Sat, 24 Aug 2019 19:38:29 +0800
Labels:             <none>
Annotations:        <none>
Status:             Running
IP:                 172.17.0.7
Containers:
  kubia-local-mike:
    Container ID:   docker://fc4df4e9328fb4896672cd4c2504d1a950294ced574200d607e778a72ba8100a
    Image:          10.21.71.237:5000/kubia-local
    Image ID:       docker-pullable://10.21.71.237:5000/kubia-local@sha256:0d41ead4dbf022881deafdea4cc3c5a46e0315ebd5805b40f8bbcb7d8b745575
    Port:           8080/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Sat, 24 Aug 2019 19:41:14 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-qkm5t (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  default-token-qkm5t:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-qkm5t
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  6m44s  default-scheduler  Successfully assigned default/kubia-local-pod to minikube
  Normal  Pulling    6m43s  kubelet, minikube  Pulling image "10.21.71.237:5000/kubia-local"
  Normal  Pulled     4m     kubelet, minikube  Successfully pulled image "10.21.71.237:5000/kubia-local"
  Normal  Created    4m     kubelet, minikube  Created container kubia-local-mike
  Normal  Started    3m59s  kubelet, minikube  Started container kubia-local-mike
➜  k8s kubectl get po
NAME              READY   STATUS    RESTARTS   AGE
kubia-local-pod   1/1     Running   0          7m22s
```

通过 k8s port-forward 端口转发机制 可方便临时对pod中的服务进行访问

端口转发
```shell
➜  k8s kubectl port-forward kubia-local-pod 8888:8080
Forwarding from 127.0.0.1:8888 -> 8080
```

本地访问k8s pod中的服务

```shell
➜  ~ curl localhost:8888
You've hit kubia-local-pod

```

## 方案二 k8s从minikube 虚机本地私有镜像仓库直接拉取镜像

https://minikube.sigs.k8s.io/docs/tasks/docker_registry/

https://blog.hasura.io/sharing-a-local-registry-for-minikube-37c7240d0615/

## 总结
- 本文总结了两种从本地拉取镜像的方案;
- 推荐使用方案一, 更方便;

