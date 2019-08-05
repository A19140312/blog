title: InnoDB存储引擎
tags:
  - 学习笔记
  - MySql
categories:
  - Mysql
author: Guyuqing
copyright: true
comments: false
date: 2019-07-31 11:34:00
---
# 概述

* InnoDB存储引擎最早由Innobase Oy公司开发，被包括在MySQL数据库所有的二进制发行版本中，
* 从MySQL 5.5版本开始是默认的表存储引擎<font color=gray>（之前的版本InnoDB存储引擎仅在Windows下为默认的存储引擎）</font>
* 第一个完整支持ACID事务的MySQL存储引擎<font color=gray>（BDB是第一个支持事务的MySQL存储引擎，现在已经停止开发）</font>
* 特点：行锁设计、支持 MVCC、支持外键、提供一致性非锁定读、有效利用内存和 CPU
<!-- more -->

# 体系架构
![innoDB体系结构图](Mysql02/1.png)
InnoDB存储引擎是由内存池、后台线程、磁盘存储三大部分组成。

## 线程

InnoDB 使用的是多线程模型, 其后台有多个不同的线程负责处理不同的任务

### Master Thread

Master Thread是最核心的一个后台线程，主要负责将缓冲池中的数据异步刷新到磁盘，保证数据的一致性。包括脏页刷新、合并插入缓冲、UNDO页的回收等。

### IO Thread

在 InnoDB 存储引擎中大量使用了异步IO(Async IO)来处理写IO请求, IO Thread的工作主要是负责这些 IO 请求的回调。

<table>
<tr>
    <th>InnoDB 版本</th>
    <th colspan="4">线程</th>
</tr>
<tr>
    <td style="text-align:center"> 1.0之前 </td>
    <td colspan="4">4 个 io thread：write，read，insert buffer，log IO Thread.
    <ul>
        <li>在Linux下，IO Thread的数量不能进行调整</li>
        <li>在Windows下可以通过参数 innodb_file_io_threads 来增大IO Thread=1</li>
    </ul>
    </td>
</tr>
<tr>
    <td style="text-align:center"> 1.0之后 </td>
    <td colspan="4">read 和 write IO thread 分别增大到了 4 个<br>
    <ul>
    <li>分别使用 innodb_read_io_threads 和 innodb_write_io_threads 设置线程数</li>
    </ul>
    </td>
</tr>
</table>  

### Purge Thread

事务提交后，其所使用的undo log可能不再需要，因此需要Purge Thread来回收已经分配并使用的UNDO页。

<table>
<tr>
    <th>InnoDB 版本</th>
    <th colspan="4">作用</th>
</tr>
<tr>
    <td style="text-align:center"> 1.1之前 </td>
    <td colspan="4">purge 操作在 master thread 内完成</td>
</tr>
<tr>
    <td style="text-align:center"> 1.1之后 </td>
    <td colspan="4">purge 可以独立到单独的线程,减轻 master thread 工作,提高 cpu 利用率和提高性能<br>
    <ul>
    <li>MySQL数据库的配置文件<code>[mysqld]</code>中添加如下命令来启用独立的Purge Thread：</li>
    <li>innodb_purge_threads=1 </li>
    <li>1.1版本中，即使将 innodb_purge_threads 设为大于1，InnoDB存储引擎启动时也会将其设为1</li>
    </ul>
    </td>
</tr>
<tr>
    <td style="text-align:center"> 1.2之后</td>
    <td colspan="4">支持多个Purge Thread, 这样做可以加快UNDO页的回收，也能更进一步利用磁盘的随机读取性能</td>
</tr>
</table>                                  

### Page Cleaner Thread

Page Cleaner Thread的作用是取代Master Thread中脏页刷新的操作，
减轻原Master Thread的工作及对于用户查询线程的阻塞，进一步提高性能。
* 1.2.x 版本引入

## 内存
![innoDB内存的结构](Mysql02/2.png)

innoDB内存主要由缓冲池(innodb buffer pool)、重做日志缓冲(redo log buffer)、额外内存池组成(innodb additional men pool size)组成

### 缓冲池
缓冲池是主存储器中的一个区域，用于在访问时缓存表和索引数据。缓冲池允许直接从内存处理常用数据，从而加快处理速度。
在专用服务器上，通常会将最多80％的物理内存分配给缓冲池。
* **读** 
    * 将从磁盘读到的页存放在缓冲池中 也称将页**fix**在缓冲池中
    * 下一次读相同的页的时候，判断是不是在缓冲池里面 ？直接读该页 ：读磁盘
* **写**
    * 修改缓冲池中的页
    * 以一定的频率刷新到磁盘
    * 不是每次数据修改都刷新，而是通过`Checkpoint`机制刷新会磁盘

因此缓冲池的大小影响数据库的整体性能。
{% note info %}

由于32位操作系统的限制，在该系统下最多将该值设置为3G。
用户可以打开操作系统的`PAE`选项来获得32位操作系统下最大64GB内存的支持。
为了让数据库使用更多的内存,建议数据库系统都采用 64 位操作系统。

{% endnote %}

|参数|版本|作用|
|:---:|:---:|:---:|
|innodb_buffer_pool_instances|从InnoDB 1.0.x开始|配置多个缓冲池实例，默认为1|
 
#### 缓存的数据页类型
 
* 索引页
* 数据页
* undo页
* 插入缓冲（insert buffer）
* 自适应哈希索引（adaptive hash index）
* InnoDB存储的锁信息（lock info）
* 数据字典信息（data dictionary）

 
#### 缓冲池管理方式
 1. **LRU list** 
     **LRU算法**：最频繁使用页在LRU列表的前端，最少使用的页在尾端。首先释放LRU列表中的尾端的页。缓冲池中页的大小默认为16KB。
     **InnoDB优化的LRU算法(midpoint insertion strategy)**：将新读取到的页不放在首部，而是中间部位 `midpoint` 位置。目标是确保频繁访问"热"页面保留在缓冲池中。
     ![lru](Mysql02/innodb-buffer-pool-list.jpg)

     <table>
     <tr>
         <th>参数</th>
         <th colspan="2">作用</th>
     </tr>
     <tr>
         <td style="text-align:center"> innodb_old_blocks_pct </td>
         <td colspan="2">控制LRU列表中 old list 的百分比。<br>
            默认值为 37，对应于原始固定比率3/8。<br>
            值范围是 5（缓冲池中的新页面很快就会老化）到 95。
         </td>
     </tr>
     <tr>
         <td style="text-align:center"> innodb_old_blocks_time </td>
         <td colspan="2">指定第一次访问页面之后的时间窗口（ms）<br>
            在此期间可以访问该页面而不移动到LRU列表的前端<br>
            默认值为 1000 ms
         </td>
     </tr>
     </table> 
     
     默认情况下，算法操作如下：
     * 在默认配置下， `midpoint`位置在LRU list 的5/8处。
     * `midpoint`是new sublist的尾部与old sublist的头部相交的边界。
     * 当 InnoDB 将页面读入缓冲池时，将页插入`midpoint`位置(old sublist的头部)。
     * 访问old sublist中的页 && 该页在old sublist中的停留时间超过innodb_old_blocks_time设置的时间，使其变`young`,将其移动到缓冲池的头部(new sublist的头部)。
     * 当页从LRU列表的old部分加入到new部分时，称此时发生的操作为`page made young`，而因为innodb_old_blocks_time的设置而导致页没有从old部分移动到new部分的操作称为`page not made young`
     * 在数据库操作中，被访问的页将移到new sublist的表头，这样一来，在new sublist中的未被访问的节点将逐渐往表尾移动，当移动过中点，将变为old list的节点。当表满时，old list末尾的页将会被移除。
     
 {% note warning %}
 为什么不采用朴素的LRU？
 因为某些SQL操作会访问很多页，甚至全部页，但仅仅在该次查询操作，并不是活跃的热点数据。可能会使缓冲池中的页被刷新出，从而影响缓冲池的效率。
 {% endnote %}  
 
 2. **Free list**
    当数据库刚启动时，LRU列表是空的，这时页都存放在Free list中。
    当需要从缓冲池中分页时，从Free list中查找是否有可用的空闲页，若有则将该页从Free列表中删除，放入到LRU列表中。
 3. **Flush list**               
    在LRU类表的页被修改后，称为脏页（Dirty Page），即缓存和硬盘的页数据不一致。
    数据库会通过`CHECKPOINT`机制将脏页刷新回磁盘，Flush list中的页即为脏页列表。

### 重做日志缓冲  
                                                              
      
参考：https://chyroc.cn/posts/innodb-storage-engine-reading-1/
                                                                 



