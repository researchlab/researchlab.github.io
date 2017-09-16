---
title: "Go Vendoring Tools 使用总结"
date: 2016-05-24 14:03:36
categories: golang
tags: [vendoring, godep, govendor, glide]
description:
---

golang1.5版本开始支持第三方包到依赖管理,当多个项目在同一个`GOPATH`下，每个项目包含到第三方包通过`go get`命令都会`get`到`GOPATH`下到`src`目录中，而不是各个项目的文件夹中，这就导致第三方包的不同版本不能同时被`GOPATH`下到多个项目使用，从`golang`需要设置`GOPATH`来看,`golang`其实把每个项目当作一个个独立的第三包来看待。
<!--more-->
关于`golang`包管理工具的topic, 在`golang`的官方wiki要有一篇总结对比的文章:[PackageManagementTools](https://github.com/golang/go/wiki/PackageManagementTools)。下面主要就项目中用过的`godep`,`govendor`,`glide`做一个简要的对比分析。

## godep
[godep](https://github.com/tools/godep) helps build packages reproducibly by fixing their dependencies.

**前置条件**

- 项目处在`GOPATH`下
- 项目能被`go install`通过
- 项目能被`go test`通过

**包初始化管理**
在项目根目录下执行`godep save`命令
```bash
$ godep save
```
会在项目根目录下生成两个文件夹: 

`Godeps`目录

```bash
➜  Godeps tree
.
├── Godeps.json
└── Readme

0 directories, 2 files
➜  Godeps cat Godeps.json 
{
	"ImportPath": "yaml",
	"GoVersion": "go1.6",
	"GodepVersion": "v70",
	"Packages": [
		"./..."
	],
	"Deps": [
		{
			"ImportPath": "gopkg.in/yaml.v2",
			"Rev": "a83829b6f1293c91addabc89d0571c246397bbf4"
		}
	]
}
```
`vendor`目录:

```bash
➜  vendor tree
.
└── gopkg.in
    └── yaml.v2
        ├── apic.go
        ├── decode.go
        ├── emitterc.go
        ├── encode.go
        ├── LICENSE
        ├── LICENSE.libyaml
        ├── parserc.go
        ├── readerc.go
        ├── README.md
        ├── resolve.go
        ├── scannerc.go
        ├── sorter.go
        ├── writerc.go
        ├── yaml.go
        ├── yamlh.go
        └── yamlprivateh.go

2 directories, 16 files
```
可以看到，`godep`把第三包的版本依赖信息记录在`Godeps.json`下，并且把第三包完整拷贝一份到`vendor`下面。通过对`Godeps.json`文件进行版本管理即可以管理整个项目的第三方包依赖信息。

**添加新包**
方法一：

go get 把新增的第三方包get到`GOPATH`的`src`目录下，然后再执行`godep save`

方法二：

godep get <url> 同样是把第三方包get到`GOPATH`的`src`下，然后再执行`godep save`

可以看到`godep`只是把第三方包进行单独到依赖管理，而新增到第三包还是会被get到`GOPATH`中, 如果多个项目用同一个第三包的不同版本时，显然不能满足。

**更新包**
`godep`通过`godep update` 更新制定的第三包以及`golang`的版本。


## govendor 
[govendor](https://github.com/kardianos/govendor) Uses the go1.5+ vendor folder. Multiple workflows supported, single tool.

**Quick Start**

```bash
# Setup your project.
cd "my project in GOPATH"
govendor init

# Add existing GOPATH files to vendor.
govendor add +external

# View your work.
govendor list

# Look at what is using a package
govendor list -v fmt

# Specify a specific version or revision to fetch
govendor fetch golang.org/x/net/context@a4bbce9fcae005b22ae5443f6af064d80a6f5a55
govendor fetch golang.org/x/net/context@v1   # Get latest v1.*.* tag or branch.
govendor fetch golang.org/x/net/context@=v1  # Get the tag or branch named "v1".

# Update a package to latest, given any prior version constraint
govendor fetch golang.org/x/net/context
```
**Sub-commands**

```bash
init     Create the "vendor" folder and the "vendor.json" file.
    list     List and filter existing dependencies and packages.
    add      Add packages from $GOPATH.
    update   Update packages from $GOPATH.
    remove   Remove packages from the vendor folder.
    status   Lists any packages missing, out-of-date, or modified locally.
    fetch    Add new or update vendor folder packages from remote repository.
    sync     Pull packages into vendor folder from remote repository with revisions
                 from vendor.json file.
    migrate  Move packages from a legacy tool to the vendor folder with metadata.
    get      Like "go get" but copies dependencies into a "vendor" folder.
    license  List discovered licenses for the given status or import paths.
    shell    Run a "shell" to make multiple sub-commands more efficent for large
                 projects.

    go tool commands that are wrapped:
      `+<status>` package selection may be used with them
    fmt, build, install, clean, test, vet, generate
```
**Status** 

```bash
+local    (l) packages in your project
    +external (e) referenced packages in GOPATH but not in current project
    +vendor   (v) packages in the vendor folder
    +std      (s) packages in the standard library

    +unused   (u) packages in the vendor folder, but unused
    +missing  (m) referenced packages but not found

    +program  (p) package is a main package

    +outside  +external +missing
    +all      +all packages
```
可以看到`govendor init`之后会在根目录下生成一个`vendor`文件夹 

```bash
➜  yaml tree -d
.
└── vendor
    ├── github.com
    │   └── cihub
    │       └── seelog
    └── gopkg.in
        └── yaml.v2

6 directories
➜  yaml cat vendor/vendor.json 
{
	"comment": "",
	"ignore": "test",
	"package": [
		{
			"checksumSHA1": "Nc93Ubautl47L3RP6x4lTY+ud68=",
			"path": "github.com/cihub/seelog",
			"revision": "cedd97ac8c6c2ec413a97864185f9510fb1775cc",
			"revisionTime": "2016-05-20T13:10:56Z"
		},
		{
			"checksumSHA1": "+OgOXBoiQ+X+C2dsAeiOHwBIEH0=",
			"path": "gopkg.in/yaml.v2",
			"revision": "a83829b6f1293c91addabc89d0571c246397bbf4",
			"revisionTime": "2016-03-01T20:40:22Z"
		}
	],
	"rootPath": "yaml"
}
```

用`govendor fetch <url1> <url2> `新增的第三方包直接被get到根目录的`vendor`文件夹下,不会与其它的项目混用第三方包，完美避免多个项目同用同一个第三方包的不同版本问题。

只需要对`vendor/vendor.json`进行版本控制，即可对第三包依赖关系进行控制。

## glide 
[Glide](https://github.com/Masterminds/glide) Vendor Package Management for Golang.

**Usage**

```bash
➜  yaml glide --help
USAGE:
   glide [global options] command [command options] [arguments...]

	create, init	Initialize a new project, creating a glide.yaml file
    get			Install one or more packages into `vendor/` and add dependency to glide.yaml.
    remove, rm		Remove a package from the glide.yaml file, and regenerate the lock file.
    import		Import files from other dependency management systems.
    name		Print the name of this project.
    novendor, nv	List all non-vendor paths in a directory.
    rebuild		Rebuild ('go build') the dependencies
    install, i		Install a project's dependencies
    update, up		Update a project's dependencies
    tree		Tree prints the dependencies of this project as a tree.
    list		List prints all dependencies that the present code references.
    info		Info prints information about this project
    about		Learn about Glide

GLOBAL OPTIONS:
   --yaml, -y "glide.yaml"	Set a YAML configuration file.
   --quiet, -q			Quiet (no info or debug messages)
   --debug			Print Debug messages (verbose)
   --home "/home/dev/.glide"	The location of Glide files [$GLIDE_HOME]
   --no-color			Turn off colored output for log messages
   --help, -h			show help
   --version, -v		print the version
```
`glide`	通过`glide create`或`glide init`命令初始化第三方包管理，会在项目根目录下生成一个`glide.yaml`，这个文件记录用到的第三方包的依赖关系，支持编辑修改。 
`glide`通过`glide install`, 会把所有缺少的第三方包都下载到`vendor`文件夹下，并且会在`glide.yaml`中添加所有依赖的第三方包名称，在`glide.lock`文件中记录具体的版本管理信息。

**glide install**

When you want to install the specific versions from the glide.lock file use glide install.

```bash
$ glide install
```

This will read the `glide.lock` file and install the commit id specific versions there.

When the glide.lock file doesn't tie to the `glide.yaml` file, such as there being a change, it will provide a warning. Running glide up will recreate the `glide.lock` file when updating the dependency tree.

If no glide.lock file is present glide install will perform an update and generate a lock file.

## 总结

- `godep`,`govendor`,`glide` 都可以很好的进行包管理。`govendor`,`glide`提供的可操作命令更丰富。
- `godep` 会在根目录生成`Godeps`和`vendor`两个文件夹; `govendor`把所有信息都生成在`vendor`目录下; `glide` 会在根目录下生成`glide.yaml`, `glide.lock`文件及`vendor`目录; 从`简洁度`和`尽量不污染项目`来看，`govendor`最优，`glide`次之。
- `godep`, `govendor`, `glide` 都提供get 第三方包的命令，但是 `glide`的`glide install` 最为方便， 并且直接把第三方包get到本项目的vendor目录下，并且`glide`提供的`便捷`命令也丰富。

- ** 在生产项目中推荐使用`govendor`, 更简洁; 在试验项目中推荐试用`glide`, 更方便。**
