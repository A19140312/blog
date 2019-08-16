title: Redo与Undo
tags:
  - 学习笔记
  - MySql
categories:
  - Mysql
author: Guyuqing
copyright: true
comments: false
date: 2019-08-16 19:09:00
---
ACID 通过什么实现？
* A 原子性
	通过redo实现
* C 一致性
	通过undo实现  	
* I 隔离性
	通过lock实现
* D 持久性
	通过redo和undo实现

# redo log
## redo 概念
重做日志(redo log)用来保证事务的持久性，即事务ACID中的D。在InnoDB存储引擎中，大部分情况下 Redo 是`物理日志`，记录的是数据页的物理变化。
## redo 结构
Redo log可以简单分为以下两个部分：
1. 重做日志缓冲 (redo log buffer),是易失的，在内存中
    * 日志会先写到redo log buffer ，根据制定条件刷新到redo log file
    * 由log block组成  
    * 每个log block 512字节，所以不需要 [double write](http://123.56.47.170:8080/2019/07/31/Mysql02/#%E4%B8%A4%E6%AC%A1%E5%86%99)，因为每次刷新都是原子的  
2. 重做日志文件 (redo log file)，是持久的，保存在磁盘中	
	* redo log的物理文件，一般有2个,大小可配置  

## redo 写入时机
* 在数据页修改完成之后，在脏页刷出磁盘之前，写入redo日志。注意的是**先修改数据，后写日志**
* redo日志比数据页先写回磁盘
* 聚集索引、二级索引、undo页面的修改，均需要记录Redo日志。

## redo 的整体流程
![redo](Mysql-RedoAndUndo/redo-buffer.png)


# 参考：
https://keithlan.github.io/2017/06/12/innodb_locks_redo/
https://juejin.im/post/5c3c5c0451882525487c498d