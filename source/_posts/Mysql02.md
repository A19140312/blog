---
title: InnoDB存储引擎
date: 2019-07-31 11:34:03
tags:
    - MySql
    - 学习笔记
categories: Mysql
author: Guyuqing
copyright: true
comments: false
password: 12345
---
### InnoDB存储引擎概述
> InnoDB存储引擎最早由Innobase Oy公司开发，被包括在MySQL数据库所有的二进制发行版本中，从MySQL 5.5版本开始是默认的表存储引擎（之前的版本InnoDB存储引擎仅在Windows下为默认的存储引擎）。
> 该存储引擎是第一个完整支持ACID事务的MySQL存储引擎（BDB是第一个支持事务的MySQL存储引擎，现在已经停止开发），其特点是行锁设计、支持MVCC、支持外键、提供一致性非锁定读，同时被设计用来最有效地利用以及使用内存和CPU。
<!-- more -->
