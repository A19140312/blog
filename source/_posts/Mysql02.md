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

InnoDB 使用的是多线程模型, 其后台有多个不同的线程负责处理不同的任务

#### Master Thread

Master Thread是最核心的一个后台线程，主要负责将缓冲池中的数据异步刷新到磁盘，保证数据的一致性。包括脏页刷新、合并插入缓冲、UNDO页的回收等。

#### IO Thread

在 InnoDB 存储引擎中大量使用了异步IO(Async IO)来处理写IO请求, IO Thread的工作主要是负责这些 IO 请求的回调。

* 1.0 版本之前共有 4 个 io thread：write，read，insert buffer，log IO Thread.
    * 在Linux下，IO Thread的数量不能进行调整
    * 在Windows下可以通过参数innodb_file_io_threads来增大IO Thread
* 1.0 之后，read 和 write IO thread 分别增大到了 4 个
    * 分别使用 innodb_read_io_threads 和 innodb_write_io_threads 设置线程数

#### Purge Thread

事务提交后，其所使用的undo log可能不再需要，因此需要Purge Thread来回收已经分配并使用的UNDO页。

* 1.1 之前，purge 操作在 master thread 内完成
* 1.1 之后，purge 可以独立到单独的线程，减轻 master thread 工作，提高 cpu 利用率和提高性能
    * MySQL数据库的配置文件中添加如下命令来启用独立的Purge Thread：
    * ```bash
         [mysqld] 
         innodb_purge_threads=1
      ```
    * 1.1版本中，即使将`innodb_purge_threads`设为大于1，InnoDB存储引擎启动时也会将其设为1
* 1.2 之后，支持多个Purge Thread, 这样做可以加快UNDO页的回收，也能更进一步利用磁盘的随机读取性能。
                                           

#### Page Cleaner Thread

Page Cleaner Thread的作用是取代Master Thread中脏页刷新的操作，
减轻原Master Thread的工作及对于用户查询线程的阻塞，进一步提高性能。
* 1.2.x 版本引入

### 内存
![innoDB内存的结构](Mysql02/2.png)

innoDB内存主要由缓冲池(innodb buffer pool)、重做日志缓冲(redo log buffer)、额外内存池组成(innodb additional men pool size)组成


#### 缓冲池
innodb 是基础磁盘存储的，将记录按照页的方式进行管理，是基础磁盘的数据库系统。
基于磁盘的数据库系统通常使用 **缓冲池** 技术来提高数据库的整体性能。
* 读 
    * 将从磁盘读到的页存放在缓冲池中 也称将页**fix**在缓冲池中
    * 下一次读相同的页的时候，判断是不是在缓冲池里面 ？直接读该页 ：读磁盘
* 写
    * 修改缓冲池中的页
    * 以一定的频率刷新到磁盘
    * 不是每次数据修改都刷新，而是通过`Checkpoint`机制刷新会磁盘
    




