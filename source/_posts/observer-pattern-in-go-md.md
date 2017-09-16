---
title: "golang 设计模式之observer使用总结"
date: 2016-02-26 00:40:11
categories: [go-pattern]
tags: [golang, observer]
description:
---

观察者(`Observer`)设计模式定义了对象间的一种一对多的依赖关系，以便一个对象的状态发生变化时，所有依赖于它的对象都得到通知并自动刷新。观察者模式将观察者和被观察的对象分离开,体现了面向对象设计中一个对象只做一件事情的原则，提高了应用程序的可维护性和重用性。
<!--more-->

## 实现观察者模式 
观察者模式有很多实现方式，从根本上说，该模式必须包含两个角色：观察者(Observer)和被观察对象(Subject)。
<center>![observer_pattern](/imgs/observer_pattern.jpg)</center>
- 观察者
观察者（`Observer`）将自己注册到被观察对象（`Subject`）中，被观察对象将观察者存放在一个容器（`Container`）里。

- 被观察
被观察对象(`Subject`)发生了某种变化，从容器中得到所有注册过的观察者，将变化通知观察者(`notifyObservers`)。

- 撤销观察
观察者告诉被观察者要撤销观察，被观察者从容器中将观察者去除。
**观察者将自己注册到被观察者的容器中时，被观察者不应该过问观察者的具体类型，而是应该使用观察者的接口。**这样的优点是：假定程序中还有别的观察者，那么只要这个观察者也是相同的接口实现即可。一个被观察者可以对应多个观察者，当被观察者发生变化的时候，它可以将消息一一通知给所有的观察者。基于接口，而不是具体的实现——这一点为程序提供了更大的灵活性。
下面通过构建一个股民(`Observer`)和他们关注的某支具体股票(`Subject`)案例分析,
首先观察者(`Observer`)要能注册/注销到某个被观察者(`Subject`)中，同时被观察者(`Subject`)发送变化时要能够通知到依赖它的观察者(`Observer`),由此我们需要声明一个被观察者(`Subject`)的接口：
```golang
// subject被观察者接口
type Subject interface {
	Attach(Observer)
	Detach(Observer)
	Notify()
}
```
遵循被观察者不应该过问观察者的具体类型，而是应该使用观察者的接口的原则，当被观察者(`Subject`)因自身改变通知观察者(`Observer`)改变时，应提供一个观察者(`Observer`)接口供被观察者(`Subject`)调用:
```golang
// observer观察者
type Observer interface {
	Update(Subject, interface{}) //更新
}
```
接口设计好之后，就需要通过具体的对象来实现这些接口，在这个案例中假定股民关注的是中国石油这只股票，那么股票就是观察者(`Observer`),而中国石油股票则是被观察者(`Subject`),具体结构如下：
```golang
// 具体observer观察者
type Investors struct {
	/*投资人*/
}

// 具体subject被观察者
type ChinaPetroleum struct {
	oblist []Observer //注册者链表
}
```

