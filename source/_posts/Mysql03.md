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
MySQL中常见的日志文件有：
* 错误日志（error log）：对MySQL的启动、运行、关闭过程进行记录错误信息、警告信息。
* 慢查询日志（slow query log）
* 二进制日志（bin log）
* 查询日志（log）

 ## 慢查询日志
 在MySQL启动时设一个阈值，将运行时间超过该值的所有SQL语句都记录到慢查询日志文件中。
 <table>
     <tr>
         <th colspan="2">参数</th>
         <th colspan="3">作用</th>
     </tr>
     <tr>
         <th colspan="2" style="text-align:center" >set global log_slow_queries = on;</th>
         <td colspan="3">开启慢查询命令，默认启动慢查询</td>
     </tr>
     <tr>
         <th colspan="2" style="text-align:center" >set global long_query_time = 1;</th>
         <td colspan="3">设置慢查询时间超过1s即被认为慢查询，默认10s</td>
     </tr>
     <tr>
         <th colspan="2" style="text-align:center" >set global log_queries_not_using_indeces = on;</th>
         <td colspan="3">如果SQL语句没有使用索引，会记录到慢查询中</td>
     </tr>
     <tr>
         <th colspan="2" style="text-align:center" >set global log_throttle_queries_not_using_indexs = on;</th>
         <td colspan="3">设置每分钟允许记录到slow log的且未使用索引的SQL语句次数，默认为0，表示没有限制。</td>
     </tr>
 </table> 

# 套接字文件

# pid文件

# 表结构定义文件

# innoDB存储引擎文件

# 参考
* MySQL技术内幕：InnoDB存储引擎(第2版)
* https://www.jianshu.com/p/c1ffd6956e6a
* https://www.cnblogs.com/BlueMountain-HaggenDazs/p/9297883.html