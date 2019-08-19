title: 《Mysql技术内幕》学习笔记-Mysql文件
tags:
  - 学习笔记
  - MySql
  - InnoDB
categories:
  - Mysql
author: Guyuqing
copyright: true
comments: false
date: 2019-08-19 19:23:00
---
# 文件种类

* [参数文件](#参数文件)：告诉MySQL实例启动时在哪里可以找到数据库文件，并且指定某些初始化参数，这些参数定义了某种内存结构的大小等设置，还会介绍各种参数的类型。

* [日志文件](#日志文件)：用来记录MySQL实例对某种条件做出响应时写入的文件，如错误日志文件、二进制日志文件、慢查询日志文件、查询日志文件等。

* [socket文件](#套接字文件)：当用UNIX域套接字方式进行连接时需要的文件。

* [pid文件](#pid文件)：MySQL实例的进程ID文件。

* [MySQL表结构文件](#表结构定义文件)：用来存放MySQL表结构定义文件。

* [存储引擎文件](#innoDB存储引擎文件)：因为MySQL表存储引擎的关系，每个存储引擎都会有自己的文件来保存各种数据。这些存储引擎真正存储了记录和索引等数据。本章主要介绍与InnoDB有关的存储引擎文件。”

# 参数文件
参数分为两类：
* 动态参数：在 Mysql 实例运行中可以进行更改
* 静态参数：在整个实例生命周期内都不得更改

更改动态参数的语法如下：
```sql
SET
| [global | session] system_var_name=expr
| [@@global. | @@session. | @@] system_var_name = expr

# 改变当前会话，不会改变全局
SET read_buffer_size = 524288

# 改变全局会话参数，不会改变当前
SET @@global.read_buffer_size = 1048576;

# 查询当前会话参数
SELECT @@session.read_buffer_size;

# 查询全局会话参数
SELECT @@global.read_buffer_size;

```
`​global`：全局的，`session`：当前会话。 
这种修改，并不最终修改配置文件my.cnf的参数值，所以重新启动后，参数还是按照配置文件中的加载。

# 日志文件

# 套接字文件

# pid文件

# 表结构定义文件

# innoDB存储引擎文件

# 参考
* MySQL技术内幕：InnoDB存储引擎(第2版)
* https://www.jianshu.com/p/c1ffd6956e6a