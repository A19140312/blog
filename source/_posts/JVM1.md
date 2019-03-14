---
title: 自己动手写JAVA虚拟机学习笔记一【命令行工具】
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