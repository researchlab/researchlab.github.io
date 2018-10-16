---
title: "redis专题01 基础数据结构"
date: 2018-1-16 11:31:18
categories: "redis专题"
tags: [redis]
description:
---
在日常应用开发中，redis常应用于热点内容缓存，分布式锁，权限认证等场景中，此redis专题试图对redis技术在内容缓存,分布式及redis集群场景中的应用，使用特性，原理及源码进行分析总结，内容来源于个人工作经验实践及网络学习资源的融合归纳总结;
<!--more-->

### 1 redis 环境搭建
通过docker方式搭建一个redis 环境
```
# 拉取 redis 镜像
> docker pull redis
# 运行 redis 容器
> docker run --name myredis -d -p6379:6379 redis
# 执行容器中的 redis-cli，可以直接使用命令行操作 redis
> docker exec -it myredis redis-cli

```
##### 2 redis基础结构

redis有5种基础数据结构: string(字符串), list(列表), set(集合), hash(哈希), zset(有序集合);

> [redis命令参考链接](http://doc.redisfans.com/)

###### 2.1 string(字符串)
