---
title: 《自己动手写JAVA虚拟机》学习笔记一【命令行工具】
date: 2019-02-11 17:23:04
tags:
    - JVM
    - JAVA
    - GO
    - 学习笔记
categories: JVM
copyright: true
comments: false
---
最近正在看张秀宏著的《自己动手写Java虚拟机》，这本书适合初学者更深入的理解java虚拟机的含义，也可以简单学习go语言的基本使用。

## 准备工作

### 安装JDK
从Oracle官网下载最新的JDK，双击运行即可。我使用的是1.8.0_161

### 安装GO
从[GO语言官网](https://golang.org/dl/)下载最新版本的GO安装文件，双击运行即可,我使用的是1.11.2。
测试Go环境是否安装成功
``` bash
～$ go version
go version go1.11.2 darwin/amd64
```
设置环境变量
```bash
#添加Go的运行环境路径
export PATH=$PATH:/usr/local/go/bin
#添加Go工程的工作空间,可自行修改
export GOPATH=/home/XXX/XXX/jvmgo/go
```
执行以下命令，如果GOPATH与你设置的相同环境变量设置成功,
```base
～$ go env
```
## 实现JAVA命令

java命令常用选项及其用途

| 选项 | 用途 |
| :------ | :------ | 
| -version | 输出版本信息，然后退出 | 
| -?/-help	 | 输出帮助信息，然后退出 |
| -cp/-classpath | 指定用户类路径 |
| -Dproperty=value | 设置Java系统属性 |
| -Xms | 设置初始堆空间大小 |
| -Xmx | 设置最大堆空间大小 |
| -Xss | 设置线程栈空间大小 |

### 编写命令行工具

首先创建项目结构
```base
|-jvmgo
    |-ch01
```
在ch01目录下创建cmd.go文件
```go
package main

import "flag"
import "fmt"
import "os"


//用法: java [-options] class [args...] (执行类)
//或  java [-options] -jar jarfile [args...] (执行 jar 文件)
type Cmd struct {
	helpFlag bool
	versionFlag bool
	cpOption string
	class string
	args []string
}


//把命令的用法打印到控制台
func printUsage()  {
	fmt.Printf("Usage：%s [-options] class [args...]\n",os.Args[0])
}

//命令解析
func parseCmd() *Cmd {
	
	//声明cmd为指向空的Cmd对象的指针
	cmd := &Cmd{}

	//定义flag参数
	//Usage是一个函数，默认输出所有定义了的命令行参数和帮助信息
	flag.Usage = printUsage
	flag.BoolVar(&cmd.helpFlag,"help",false,"print help message")
	flag.BoolVar(&cmd.helpFlag,"?",false,"print help message")
	flag.BoolVar(&cmd.versionFlag,"version",false,"print version and exit")
	flag.StringVar(&cmd.cpOption,"classpath","","classpath")
	flag.StringVar(&cmd.cpOption,"cp","","classpath")
	//在所有的flag定义完成之后，可以通过调用flag.Parse()进行解析。
	flag.Parse()
	//flag.Args()可以捕获未被解析的参数
	args := flag.Args()
	if len(args) > 0{
		cmd.class = args[0]
		cmd.args = args[1:]
	}

	return cmd
}

```
### 测试代码

在ch01目录下创建main.go文件
```go
package main

import "fmt"

func main() {
	cmd := parseCmd()
	if cmd.versionFlag {
		fmt.Println("version 0.0.1")
	}else if cmd.helpFlag || cmd.class == ""{
		printUsage()
	}else {
		startJVM(cmd)
	}
}
//模拟启动jvm
func startJVM(cmd *Cmd)  {
	//还未开始写，暂时打印
	fmt.Printf("classpath:%s class:%s args:%v\n",cmd.cpOption,cmd.class,cmd.args)
}
```

编译main.go，并测试-version
```bash
$ go install jvmgo/ch01 
$ ch01 -version
version 0.0.1
```
