title: 《Mysql技术内幕》学习笔记-Redo与Undo
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
# redo log
## redo 概念
重做日志(redo log)：在InnoDB存储引擎中，大部分情况下 Redo 是`物理日志`，记录的是数据页的物理变化。
## redo 结构
Redo log可以简单分为以下两个部分：
<!-- more -->
1. 重做日志缓冲 (redo log buffer),是易失的，在内存中
    * 日志会先写到redo log buffer ，根据制定条件刷新到redo log file
    * 由log block组成  
    * 每个log block 512字节，所以不需要 [double write](http://123.56.47.170:8080/2019/07/31/Mysql02/#%E4%B8%A4%E6%AC%A1%E5%86%99)，因为每次刷新都是原子的  
2. 重做日志文件 (redo log file)，是持久的，保存在磁盘中	
	* redo log的物理文件，一般有2个,大小可配置  

## redo 写入时机
* 在数据页修改完成之后，在脏页刷出磁盘之前，写入redo日志。注意的是**先修改数据，后写日志**
* redo日志比数据页先写回磁盘
* 聚集索引、非聚集索引、undo页面的修改，均需要记录Redo日志。

## redo 的整体流程
![redo](Mysql-RedoAndUndo/redo-buffer.png)

## redo如何保证事务的持久性？
InnoDB 通过 **Force Log at Commit** 机制实现事务的持久性，即当事务提交时，先将 redo log buffer 写入到 redo log file 进行持久化，待事务的commit操作完成时才算完成。
这种做法也被称为 **Write-Ahead Log**(预先日志持久化)，在持久化一个数据页之前，先将内存中相应的日志页持久化。

为了保证每次日志都写入redo log file，在每次将redo buffer写入redo log file之后，默认情况下，InnoDB存储引擎都需要调用一次 fsync操作,因为重做日志打开并没有 O_DIRECT选项，所以重做日志先写入到文件系统缓存。为了确保重做日志写入到磁盘，必须进行一次 fsync操作。fsync操作 将数据提交到硬盘中，强制硬盘同步，将一直阻塞到写入硬盘完成后返回，大量进行fsync操作就有性能瓶颈，因此磁盘的性能也影响了事务提交的性能，也就是数据库的性能。
(O_DIRECT选项是在Linux系统中的选项，使用该选项后，对文件进行直接IO操作，不经过文件系统缓存，直接写入磁盘)

# undo log
## undo 概念
undo log主要记录的是数据的逻辑变化，为了在发生错误时回滚之前的操作，需要将之前的操作都记录下来，然后在发生错误时才可以回滚。

## undo 结构
在InnoDB存储引擎中，undo存储在回滚段(Rollback Segment)中,每个回滚段记录了1024个undo log segment，而在每个undo log segment段中进行undo 页的申请，在5.6以前，Rollback Segment是在共享表空间里的，5.6.3之后，可通过 innodb_undo_tablespace设置undo存储的位置。

## undo 写入时机
* DML操作修改聚集索引前，记录undo日志
* 非聚集索引记录的修改，**不**记录undo日志

## undo 的整体流程
![undo](Mysql-RedoAndUndo/undo-Segment.png)

## undo 类型
* insert undo log：在insert 操作中产生的undo log，因为insert操作的记录，只对事务本身可见，对其他事务不可见。故该undo log可以在事务提交后直接删除，不需要进行purge操作。
* update undo log：在delete 和update操作产生的undo log，该undo log可能需要提供MVCC机制，因此不能再事务提交时就进行删除。提交时放入undo log链表，等待purge线程进行最后的删除。

<div style='display: none'>
## DML的相关物理实现算法
* 主键索引
```text
1. 对于delete   --需要undo绑定该记录才能进行回滚，所以只能打上标记，delete mark  
2. 对于update  --原记录可以物理删除，因为可以在新插入进来的地方进行undo绑定  
	* 如果不能原地更新： delete(注意：这里是直接delete,而不是delete mark)  + insert 
	* 如果可以原地更新，那么直接update就好    
 ```
* 非聚集索
```text
1. 对于delete  --不能直接被物理删除，因为二级索引没有undo，只能通过打标记，然后回滚。否则如果被物理删除，则无法回滚
	delete mark    
2. 对于update  --不能直接被物理删除，因为二级索引没有undo，只能通过打标记，然后回滚。否则如果被物理删除，则无法回滚
	delete mark + insert
```
</div>

# redo & undo
## undo log 是否是 redo log 的逆过程？
undo log是逻辑日志，对事务回滚时，只是将数据库逻辑地恢复到原来的样子。
redo log是物理日志，记录的是数据页的物理变化，显然undo log不是redo log的逆过程。

## 事务实现过程
事务B要将字段A的值由原来的1修改为3，要将B的值由原来的2修改为4，redo日志记录的是：
```text
假设有A、B两个数据，值分别为1,2.
1. 事务B开始
2. 记录A=1到undo log
3. 修改A=3
4. 记录A=3到 redo log
5. 记录B=2到 undo log
6. 修改B=4
7. 记录B=4到redo log
8. 将redo log写入磁盘
9. 事务提交，将数据写入磁盘
10.事物B结束

```
在insert/update/delete操作中，redo和undo分别记录的内容都不一样，量也不一样。在InnoDB内存中，一般的顺序如下：
1. 写undo的redo
2. 写undo
3. 修改数据页
4. 写Redo

如果上面事务B回滚（当做新的事务C），则redo记录的是：
```text
1. 事务C开始
2. 记录A=1到undo log
3. 修改A=3
4. 记录A=3到 redo log
5. 记录B=2到 undo log
6. 修改B=4
7. 记录B=4到redo log
   <!--回滚-->
8. 修改B=2
9. 记录B=2到redo log
10.修改A=1
11.记录A=1到redo log
12.将redo log写入磁盘
13.事务提交，将数据写入磁盘
14.事物C结束
```

恢复策略：恢复时，先根据redo重做所有事务（包括未提交和回滚了的），再根据undo回滚未提交的事务。
当系统发生宕机时，如果一个事务的 redo log 已经全部刷入磁盘，那么该事务一定可以恢复；如果一个事务的 redo log 没有全部刷入磁盘，那么就通过 undo log 将这个事务恢复到执行之前。

如上，如果事务B异常未提交事务就宕机，恢复时，先根据redo日志将数据恢复为A=3&B=4，然后根据undo记录的A=1&B=2将数据恢复如初。

<div style='display: none'>
# 参考：
https://keithlan.github.io/2017/06/12/innodb_locks_redo/
https://juejin.im/post/5c3c5c0451882525487c498d
</div>