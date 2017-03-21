---
title: "一步一步构建自己的RPC server" 
date: 2017-03-20 21:28:14
categories: [golang]
tags: [golang, rpc]
description:
---

## 前言
[远程程序调用(Remote procedure call, RPC)](https://en.wikipedia.org/wiki/Remote_procedure_call)是进程间通信的一种基本形式， 并且广泛用于分布式计算中。下面就通过一步一步构建一个简单的RPC服务器来总结加深对RPC应用的理解。

<!--more-->

## 公共接口和结构
方便起见，假设有一个包含`Multiply`和`Divide`方法的接口， 这两个接口分别表示乘法`*`和除法`/`操作，另外存在一个`Args`的结构体用于将客户端参数传递到服务器端， 还存在一个`Quotient`的公共结构，用于表示乘法和除法操作的输出结果，具体如下，

公共结构
```golang 
//file: shared_structs.go
package shared 

type Args struct {
	A, B int 
}

type Quotient struct {
	Quo, Rem int
}
```

公共接口
```golang 
//file interface.go 

package shared 

type Arith interface {
	Multiply(args *Args, reply *int) error
	Divide(args *Args, quo *Quotient) error
}
```

## 接口实现
下面简单实现上述定义的公共接口， 具体如下， 
```golang 
//file interface_implementation.go 

package main 

import(
	"shared" 
)

// Every method that we want to export must have 
// (1) the method has two arguments, both exported(or builtin) types
// (2) the method's second argument is a pointer 
// (3) the method has return type error

type Arith int 

func (t *Arith) Multiply(args *shared.Args, reply *int) error{
	*reply = args.A * args.B 
	return nil
}

func (t * Arith) Divide(args *shared.Args, quo *shared.Quotient) error{
	if args.B == 0 {
		return errors.New("divide by zero")	
	}

	quo.Quo = args.A / args.B
	quo.Rem = args.A % args.B 
	return nil 
}
```

## RPC server 实现
可以通过HTTP协议或TCP协议来实现一个RPC server, 下面用这两种方式分别实现RPC server。

### HTTP RPC server/client 

- HTTP RPC server 实现
这种方法即先通过监听HTTP 协议链接，然后转换到RPC 协议上， 这种方法的好处是可以很方便对客户端链接请求进行授权验证，因为HTTP可以方便地支持多种授权验证，具体实现如下， 
```golang 
// file: server_http.go 
package main 

import(
	"errors"
	"log"
	"net"
	"net/http"
	"net/rpc"

	"shared"
)

func registerArith(server *rpc.Server, arith shared.Arith) {
	// registers Arith interface by name of `Arithmetic`.
	// If you want this name to be same as the type name, you can 
	// use server.Register instead.
	server.RegisterName("Arithmetic", arith)
}

func main() {
	// Creating an instance of struct which implement Arith interface 
	arith := new(Arith)

	// Register a new rpc server (In most cases, you will use default server only) 
	// And register struct we created above by name "Arith"
	// The wrapper method here ensures that only structs which implement Arith interface
	// are allowed to register themselves. 

	server := rpc.NewServer()
	registerArith(server, arith)

	// registers an HTTP handler for RPC messages on rpcPath, and a debugging handler on debugPath
	server.HandleHTTP("/", "/debug")

	// Listen for incoming tcp packets on specified port. 
	l, e := net.Listen("tcp", ":1234")
	if e != nil {
		log.Fatal("listen error:", e)	
	}

	// This statement starts go's http server on 
	// socket specified by l .
	http.Serve(l, nil)
}
```

- HTTP RPC Client 
```golang 
// file: client_http.go 

package main 

import(
	"fmt"
	"log"
	"net/rpc"

	"shared" 
)

type Arith struct {
	client *rpc.Client 
}

func (t * Arith) Divide(a, b int) shared.Quotient{
	args := &shared.Args{a, b}
	var reply shared.Quotient 
	err := t.client.Call("Arithmetic.Divide", args, &reply)
	if err != nil {
		log.Fatal("arith error:", err)	
	}
	return reply
}

func (t *Arith)Multiply(a, b int) int {
	args := &shared.Args{a, b} 
	var reply int 
	err := t.client.Call("Arithmetic.Multiply", args, &reply)
	if err != nil {
		log.Fatal("arith error:", err)	
	}
	return reply
}

func main() {
	// Tries to connect to localhost:1234 using HTTP protocol (The port on which rpc server is listening)
	client, err := rpc.DialHTTP("tcp", "localhost:1234")
	if err != nil {
		log.Fatal("dialing:", err)	
	}

	// Create a struct, that mimics all methods provided by interface.
	// It is not compulsory, we are doing it here, just to simulate a traditional method call.
	arith := &Arith{client: client}
	fmt.Println(arith.Multiply(5, 6)) 
    fmt.Println(arith.Divide(500, 10))
}
```

### TCP RPC server/client

上述通过`HTTP`协议实现来一个RPC server/client, 但是需要先监听HTTP协议链接，然后转换到RPC协议上来， 这就多了一个转换操作， 下面通过TCP协议来实现RPC server， 则可以直接监听链接，无需依赖HTTP协议， 具体实现如下，

- TCP RPC server 

```golang 
// file: tcp_server.go
package main 

import(
	"errors"
	"log"
	"net"
	"net/rpc"
	"shared"
)

func registerArith(server *rpc.Server, arith shared.Arith) {
	// registers Arith interface by name of `Arithmetic`. 
	// If you want this name to be same as the type name, you 
	// can use server.Register instead. 
	server.RegisterName("Arithmetic", arith)
}

func main() {
	// Creating an instance of struct which implement Arith interface
	arith := new(Arith)

	// Register a new rpc server (In most cases, you will use default server only) 
	// And register struct we created above by name "Arith"
	// The wrapper method here ensures that only structs which iplement Arith interface 
	// are allowed to register themselves.
	server := rpc.NewServer()
	registerArith(server, arith)

	// Listen for incoming tcp packets on specified port. 
	l, e := net.Listen("tcp", ":1234")
	if e != nil {
		log.Fatal("listen error:", e)	
	}

	//This statment links rpc server to the socket, and allows rpc server to accept 
	// rpc request comming from that socket. 
	server.Accept(l)
}
```

- TCP RPC client 

```golang 
// file: tcp_client.go 
package main 

import(
	"fmt"
	"log"
	"net"
	"net/rpc"
	"shared" 
)

type Arith struct {
	client *rpc.Client 
}

func (t *Arith) Divide(a, b int) shared.Quotient {
	args := &shared.Args{a, b}
	var reply shared.Quotient 
	err := t.client.Call("Arithmetic.Divide", args, &reply)
	if err !=nil {
		log.Fatal("arith error:", err)	
	}
	return reply
}

func (t *Arith) Multiply(a, b int) int {
	args := &shared.Args{a, b}
	var reply int 
	err := t.client.Call("Arithmetic.Multiply", args, &reply)
	if err != nil {
		log.Fatal("arith error:", err)	
	}
	return reply
}

func main() {
	// Tries to connect to localhost:1234 (The port on which rpc server is listening)
	conn, err := net.Dial("tcp", "localhost:1234")
	if err != nil {
		log.Fatal("Connectiong:", err)	
	}

	// Create a struct, that mimics all methods provided by interface. 
	// It is not compulsory, we are doing it here, just to simulate a tradional method call. 
	arith := &Arith{client: rpc.NewClient(conn)}

	fmt.Println(arith.Multiply(5, 6))
	fmt.Println(arith.Divide(500, 10))
}
```

## 总结

- 通过用HTTP协议和TCP协议分别实现了RPC 服务， 加深了对RPC应用的理解， 

