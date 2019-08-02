---
title: MySql体系结构和存储引擎
date: 2019-07-30 02:40:04
tags:
    - MySql
    - 学习笔记
categories: Mysql
author: Guyuqing
copyright: true
comments: false
---
#### 数据库
> 数据库是文件的集合，是依照某种数据模型组织起来并存放于二级存储器中的数据集合。
> 在MySQL数据库中，数据库文件可以是frm、MYD、MYI、ibd结尾的文件。

<!-- more -->
#### 数据库实例
> 数据库实例是`程序`，是位于用户与操作系统之间的一层数据管理软件，用户对数据库数据的任何操作，
> 包括数据库定义、数据查询、数据维护、数据库运行控制等都是在数据库实例下进行的，应用程序只有通过数据库实例才能和数据库打交道。

#### MySql体系结构
![mysql体系结构图](Mysql01/01.jpg)

从图中可以发现，MySQL由：连接池组件、管理服务和工具组件、SQL接口组件、查询分析器组件、优化器组件、缓冲（Cache）组件、插件式存储引擎和物理文件组成。
MySQL数据库区别于其他数据库的最重要的一个特点就是其插件式的`表存储引擎`。

#### MySql存储引擎
MySql数据库常用存储引擎：InnoDB、MyISAM、NDB、Memory(HEAP)、Archive、BDB(BerkeleyDB)、Federated、Maria等。

|特性|InnoDB|MyISAM|NDB|Memory|Archive|BDB|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|存储限制|64TB|No|Yes|Yes|No|No|
|事务|Yes|||||Yes|
|锁粒度|Row|Table|Row|Table|Row|Page|
|MVCC|Yes||Yes||Yes||
|B树索引|Yes|Yes|Yes|Yes||Yes|
|哈希索引|Yes||Yes|Yes|||
|全文索引|5.6支持英文|Yes|||||
|集群索引|Yes||||||
|数据缓存|Yes||Yes|Yes|||
|索引缓存|Yes|Yes|Yes|Yes|||
|数据压缩||Yes|||Yes||
|加密传输|Yes|Yes|Yes|Yes|Yes|Yes|
|批量插入|相对低|高|高|高|非常高|高|
|内存消耗|高|低|高|中|低|低|
|存储空间消耗|高|低|低|N/A|非常低|低|
|外键支持|Yes||||||
|复制支持|Yes|Yes|Yes|Yes|Yes|Yes|
|查询缓存|Yes|Yes|Yes|Yes|Yes|Yes|
|备份恢复|Yes|Yes|Yes|Yes|Yes|Yes|
|数据字典更新|Yes|Yes|Yes|Yes|Yes|Yes|
|备份/时间点恢复|Yes|Yes|Yes|Yes|Yes|Yes|
|集群支持|||Yes|||||

