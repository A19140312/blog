title: InnoDB存储引擎
tags:
  - 学习笔记
  - MySql
categories:
  - Mysql
author: Guyuqing
copyright: true
comments: false
password: 12345
date: 2019-07-31 11:34:00
---
## InnoDB存储引擎概述

* InnoDB存储引擎最早由Innobase Oy公司开发，被包括在MySQL数据库所有的二进制发行版本中，
* 从MySQL 5.5版本开始是默认的表存储引擎<font color=gray>（之前的版本InnoDB存储引擎仅在Windows下为默认的存储引擎）</font>
* 第一个完整支持ACID事务的MySQL存储引擎<font color=gray>（BDB是第一个支持事务的MySQL存储引擎，现在已经停止开发）</font>
* 特点：行锁设计、支持 MVCC、支持外键、提供一致性非锁定读、有效利用内存和 CPU
<!-- more -->

## InnoDB体系架构
![innoDB体系结构图](Mysql02/1.png)
InnoDB存储引擎是由内存池、后台线程、磁盘存储三大部分组成。

### 线程

