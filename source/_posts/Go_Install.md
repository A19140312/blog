---
title: mac上安装GO安装
date: 2020-04-26 11:25:00
tags:
    - go
categories: go
author: Guyuqing
copyright: true
comments: false
---
## 安装Homebrew
官网https://brew.sh/index_zh-tw

安装：
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

## brew安装go
```bash
brew install go
```

## 添加环境变量
使用vim ~/.bash_profile
```bash
GOROOT=/usr/local/Cellar/go/1.14.2_1/libexec
export GOROOT
export GOPATH=/Users/XXX/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN:$GOROOT/bin
```
source ~/.bash_profile
然后再使用go env查看当前环境，可以发现已经是你配置文件中设置的路径环境了

## 安装GO指南教程
```bash
go get -u github.com/Go-zh/tour

tour
```

## 添加代理
Go 版本是 1.13 及以上 
```bash
go env -w GO111MODULE=on
go env -w GOPROXY=https://goproxy.io,direct

# 设置不走 proxy 的私有仓库，多个用逗号相隔（可选）
go env -w GOPRIVATE=*.corp.example.com
```

Go 版本是 1.12 及以下
```bash
# 启用 Go Modules 功能
export GO111MODULE=on
# 配置 GOPROXY 环境变量
export GOPROXY=https://goproxy.io
```

## 问题
### unrecognized import path "golang.org/x/net/websocket"..
由于谷歌ip被墙，还好，github 我们还能正常访问，可以将缺的包从 github 上clone 回来，如下：
（ 注意：需要手工创建出其提示的目录结构  ）
```bash
$mkdir -p $GOPATH/src/golang.org/x/

$cd $GOPATH/src/golang.org/x/

$git clone https://github.com/golang/net.git net

$go install net
```

### go run : cannot run non-main package
注意在运行单个的go文件时，package一定要是main才行
