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

## 内存
![innoDB内存的结构](Mysql02/2.png)

innoDB内存主要由[缓冲池(innodb buffer pool)](#缓冲池)、[重做日志缓冲(redo log buffer)](#重做日志缓冲)、[额外内存池组成(innodb additional men pool size)](#额外的内存池)组成

### 缓冲池
缓冲池是主存储器中的一个区域，用于在访问时缓存表和索引数据。缓冲池允许直接从内存处理常用数据，从而加快处理速度。
在专用服务器上，通常会将最多80％的物理内存分配给缓冲池。
* **读** 
    * 将从磁盘读到的页存放在缓冲池中 也称将页**fix**在缓冲池中
    * 下一次读相同的页的时候，判断是不是在缓冲池里面 ？直接读该页 ：读磁盘
* **写**
    * 修改缓冲池中的页
    * 以一定的频率刷新到磁盘
    * 不是每次数据修改都刷新，而是通过[`Checkpoint`](#Checkpoint技术)机制刷新会磁盘

因此缓冲池的大小影响数据库的整体性能。
{% note info %}

由于32位操作系统的限制，在该系统下最多将该值设置为3G。
用户可以打开操作系统的`PAE`选项来获得32位操作系统下最大64GB内存的支持。
为了让数据库使用更多的内存,建议数据库系统都采用 64 位操作系统。

{% endnote %}

|参数|版本|作用|
|:---:|:---:|:---:|
|innodb_buffer_pool_instances|从InnoDB 1.0.x开始|配置多个缓冲池实例，默认为1|
 
#### 缓冲池中缓存的数据页类型
 
* 索引页(index page)
* 数据页(data page)
* undo页(undo Log Page)
* 插入缓冲（insert buffer）
    在InnoDB引擎上进行插入操作时，一般需要按照主键顺序进行插入，这样才能获得较高的插入性能。当一张表中存在非聚簇的且不唯一的索引时，在插入时，数据页的存放还是按照主键进行顺序存放，但是对于非聚簇索引叶节点的插入不再是顺序的了，这时就需要离散的访问非聚簇索引页，由于随机读取的存在导致插入操作性能下降。
    
    InnoDB为此设计了Insert Buffer来进行插入优化。对于非聚簇索引的插入或者更新操作，不是每一次都直接插入到索引页中，而是先判断插入的非聚集索引是否在缓冲池中，若在，则直接插入；若不在，则先放入到一个Insert Buffer中。看似数据库这个非聚集的索引已经查到叶节点，而实际没有，这时存放在另外一个位置。然后再以一定的频率和情况进行Insert Buffer和非聚簇索引页子节点的合并操作。这时通常能够将多个插入合并到一个操作中，这样就大大提高了对于非聚簇索引的插入性能。
* 自适应哈希索引（adaptive hash index）
    InnoDB会根据访问的频率和模式，为热点页建立哈希索引，来提高查询效率。InnoDB存储引擎会监控对表上各个索引页的查询，如果观察到建立哈希索引可以带来速度上的提升，则建立哈希索引，所以叫做自适应哈希索引。
    
    自适应哈希索引是通过缓冲池的B+树页构建而来，因此建立速度很快，而且不需要对整张数据表建立哈希索引。其有一个要求，即对这个页的连续访问模式必须是一样的，也就是说其查询的条件(WHERE)必须完全一样，而且必须是连续的。
* InnoDB存储的锁信息（lock info）
* 数据字典信息（data dictionary）
    数据字典是对数据库中的数据、库对象、表对象等的元信息的集合。
    在MySQL中，数据字典信息内容就包括表结构、数据库名或表名、字段的数据类型、视图、索引、表字段信息、存储过程、触发器等内容。
    InnoDB有自己的表缓存，可以称为表定义缓存或者数据字典。当InnoDB打开一张表，就增加一个对应的对象到数据字典。

 
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
   {% note info %}
    **什么是redo log？**
    当数据库对数据做修改的时候，需要把数据页从磁盘读到buffer pool中，然后在buffer pool中进行修改，那么这个时候buffer pool中的数据页就与磁盘上的数据页内容不一致，称buffer pool的数据页为dirty page 脏数据。
    如果发生非正常的DB服务重启，那么这些数据并没有同步到磁盘文件中（注意，同步到磁盘文件是个随机IO），会发生数据丢失。
    如果这个时候，能够有一个文件，当缓冲池中的data page变更结束后，把相应修改记录记录到这个文件（注意，记录日志是顺序IO），那么当DB服务发生crash的情况，恢复DB的时候，也可以根据这个文件的记录内容，重新应用到磁盘文件，数据保持一致。
    这个文件就是redo log ，用于记录 数据修改后的记录，顺序记录。<br>
    **什么是undo log？**
    undo日志用于存放数据修改被修改前的值。
    假设修改表中 id=1 的行数据，把Name='B' 修改为Name = 'B2' ，那么undo日志就会用来存放Name='B'的记录，如果这个修改出现异常，可以使用undo日志来实现回滚操作，保证事务的一致性。
   {% endnote %}  

![lru](Mysql02/redo-buffer.png)
  
  重做日志缓冲不需要设置很大，通常情况下8M能满足大部分的应用场景。重做日志支持以下三种情况触发刷新：
  * Master Thread每一秒将重做日志缓冲刷新到重做日志文件
  * 每次事务提交时将重做日志缓冲刷新到重做日志文件
  * 当重做日志缓冲池剩余空间小于1/2时，重做日志缓冲刷新到重做日志文件
  
### 额外的内存池
   在InnoDB存储引擎中，对内存的管理是通过一种称为内存堆的方式进行的。在对一些数据结构本身的内存进行分配时，需要从额外的内存池中进行申请，当该区域的内存不够时，会从缓冲池中进行申请。

## Checkpoint技术 
        
{% note info %}    
   **什么是Checkpoint？**
   是一个数据库事件(event)，这个事件激活以后会触发数据库写进程(DBWR)将脏数据块写到磁盘中。                           
   
   **为什么需要Checkpoint技术？**
   innoDB在事务提交时，先写重做日志，再修改内存数据这样，就产生了脏页。既然有重做日志保证数据持久性，查询时也可以从缓冲池页中取数据，那为什么还要刷新脏页到磁盘呢？如果重做日志可以无限增大，同时缓冲池足够大，能够缓存所有数据，那么是不需要将缓冲池中的脏页刷新到磁盘。但是，会有以下几个问题：
   1) 服务器内存有限，缓冲池不够用，无法缓存全部数据
   2) 重做日志无限增大成本要求太高
   3) 宕机时如果重做全部日志恢复时间过长            
                                         
   **Checkpoint 解决了什么问题？**
   1) 缩短短数据库的恢复时间
   2) 缓冲池不够时，将脏页刷新到磁盘
   3) 重做日志不可用时，刷新脏页
{% endnote %} 

innodb 内部有两种 checkpoint：
1. sharp checkpoint：数据库关闭的时候将所有的脏页刷回到磁盘，默认方式，参数 innodb_fast_shudown=1
2. fuzzy checkpoint：只刷新部分脏页
    - master thread checkpoint：master thread 异步的以每秒或者每 10 秒的速度从缓冲池的脏页列表中刷新一定比列的也回磁盘
    - flush_lru_list checkpoint：InnoDB要保证LRU列表中需要有差不多100个空闲页可供使用。如果没有这么多，就会将 lru list 尾部的页移除。如果这些页有脏页，就需要进行 checkpoint。
         - innodb 1.1.x版本之前，检查在用户查询线程中,会阻塞用户查询操作。
         - innodb 1.2.x版本之后，检查放到了单独的 page cleaner 线程中,可通过 **innodb_lru_scan_depth** 控制lru列表中可用页的数量，默认是1024。
    - async/sync flush checkpoint：重做日志文件不可用时，强制将一些页刷新到磁盘。达到重做日志文件的大小阈值。
    - dirty page too much checkpoint：当缓冲池中脏页的数量占据一定百分比时，强制进行Checkpoint，用来保证缓冲池中有足够的页，通过 [innodb_max_dirty_pages_pct](#innodb_max_dirty_pages_pct) 参数控制。
                                             
## Master thread 工作方式

### InnoDB 1.0.x 版本之前的 Master thread
Master thread 内部有多个循环 loop 组成：
* 主循环 loop
* 后台循环 backgroup loop
* 刷新循环 flush loop
* 暂停循环 suspend loop

伪代码如下：

```java
void master_thread()
{
	goto loop;
	//主循环
	loop ：
	for(int i = 0; i < 10; ++i){
		thread_sleep(1);
		//1. 日志缓冲刷新到磁盘，即使事务还没有提交
		do log buffer flush to disk;
		//2. 根据前一秒IO操作小于5，合并插入缓冲
		if(last_one_second_ios < 5)
			do merge at most 5 insert buffer;
		//3. 脏页的比例超过了阈值，刷新 100 个脏页到磁盘
		if(buf_get_modified_ratio_pct > innodb_max_dirty_pages_pct)
			do buffer pool flush 100 dirty page;
		//4. 没有用户活动（数据库空闲时）或者数据库关闭（shutdown），切换到 backgroup loop
		if(no user activity)
			goto backgroud loop;
	}
	
	//1. 前10秒IO操作小于200，刷新 100 个脏页到磁盘
	if(last_ten_second_ios < 200)
		do buffer pool flush 100 dirty page;
	//2. 合并至多 5 个插入缓冲
	do merge at most 5 insert buffer;
	//3. 将重做日志刷新到磁盘
	do log buffer flush to disk;
	//4. 删除无用的 undo 页（每次最多尝试回收 20 个 undo 页）
	do full purge;
	//5. 脏页比例超过 70% 刷新100 个脏页到磁盘，否则刷新 10 个脏页
	if ( buf_get_modified_ratio_pct ＞ 70 % )
		do buffer pool flush 100 dirty page
	else
		buffer pool flush 10 dirty page
																
	goto loop
	//后台循环																
	background loop :
	//1. 删除无用的 undo 页
	do full purge
	//2. 合并 20 个插入缓冲
	do merge 20 insert buffer
	//3.如果有任务，跳转到主循环，否则跳转到刷新循环
	if not idle	
		goto loop
	else
		goto flush loop
	
	//刷新循环
	flush loop :
	//不断刷新100个脏页，直到脏页比例没有超过阈值
	do buffer pool flush 100 dirty page
	if ( buf_get_modified_ratio_pct ＞ innodb_max_dirty_pages_pct )
		goto flush loop
	//没有任务，跳转到暂停循环
	goto suspend loop
	
	//暂停循环
	suspend loop :
	//将主线程挂起，等待事件发生
	suspend_thread()
	waiting event
	goto loop;
}

```
### InnoDB 1.2.x 版本之前的 Master thread
1. 提高刷新脏页数量和合并插入数量，改善磁盘 IO 处理能力,刷新数量不再硬编码，而是使用百分比控制。
    * 在合并插入缓冲的时候，合并插入缓冲的数量为 [innodb_io_capacity](#innodb_io_capacity) 的 5%
    * 在从缓冲区刷新脏页的时候，刷新脏页的数量为 [innodb_io_capacity](#innodb_io_capacity)
2. 增加了自适应刷新脏页功能。
    * 1.0.x之前版本：脏页在缓冲池占比小于[innodb_max_dirty_pages_pct](#innodb_max_dirty_pages_pct)，不刷新脏页，大于则刷新100个脏页
    * 1.0.x版本开始：引入[innodb_adaptive_flushing](#innodb_adaptive_flushing)参数，通过函数buf_flush_get_desired_flush_rate判断产生重做日志的速度来决定最适合的刷新脏页数量。
3. full purge回收的Undo页的数量也不再硬编码，使用参数[innodb_purge_batch_size](#innodb_purge_batch_size)控制。

<table>
<tr>
    <th colspan="2">参数</th>
    <th>InnoDB 版本</th>
    <th colspan="3">作用</th>
</tr>
<tr>
    <td colspan="2" style="text-align:center"><span id="innodb_io_capacity">innodb_io_capacity</span></td>
    <td style="text-align:center"> 1.0.x开始 </td>
    <td colspan="3">表示磁盘IO的吞吐量,默认值是200</td>
</tr>
<tr>
    <td colspan="2" rowspan="2" style="text-align:center"><span id="innodb_max_dirty_pages_pct">innodb_max_dirty_pages_pct</span></td>
    <td style="text-align:center"> 1.0.x之前 </td>
    <td colspan="3">脏页在缓冲池中所占比率，默认值是90</td>
</tr>
<tr>
    <td style="text-align:center"> 1.0.x开始</td>
    <td colspan="3">默认值是75<br>加快刷新脏页的频率，保证了磁盘IO的负载。</td>                       
</tr>
<tr>
    <td colspan="2" style="text-align:center"><span id="innodb_adaptive_flushing">innodb_adaptive_flushing</span></td>
    <td style="text-align:center"> 1.0.x开始 </td>
    <td colspan="3">是否自适应刷新脏页，默认为 ON</td>
</tr>
<tr>
    <td colspan="2" style="text-align:center"><span id="innodb_purge_batch_size">innodb_purge_batch_size</span></td>
    <td style="text-align:center"> 1.0.x开始 </td>
    <td colspan="3">清除 undo 页时,表示一次删除多少页,默认是 20</td>
</tr>
</table>   

Master Thread的伪代码变为了下面的形式：

```java
void master_thread()
{
	goto loop;
	//主循环
	loop ：
	for(int i = 0; i < 10; ++i){
		thread_sleep(1);
		//1. 日志缓冲刷新到磁盘，即使事务还没有提交
		do log buffer flush to disk;
		//2. 根据前一秒IO操作小于5%innodb_io_capacity，合并插入缓冲
		if(last_one_second_ios < 5%innodb_io_capacity)
			do merge 5%innodb_io_capacity insert buffer;
		//3. 脏页的比例超过了阈值，刷新 100%innodb_io_capacity 个脏页到磁盘
		if(buf_get_modified_ratio_pct > innodb_max_dirty_pages_pct)
			do buffer pool flush 100%innodb_io_capacity dirty page;
		//4. 没有用户活动（数据库空闲时）或者数据库关闭（shutdown），切换到 backgroup loop
		if(no user activity)
			goto backgroud loop;
	}
	
	//1. 前10秒IO操作小于innodb_io_capacity，刷新 innodb_io_capacity 个脏页到磁盘
	if(last_ten_second_ios < innodb_io_capacity)
		do buffer pool flush 100%innodb_io_capacity dirty page;
	//2. 合并至多 5%innodb_io_capacity 个插入缓冲
	do merge at most 5%innodb_io_capacity insert buffer;
	//3. 将重做日志刷新到磁盘
	do log buffer flush to disk;
	//4. 删除无用的 undo 页（每次最多尝试回收 5%innodb_io_capacity 个 undo 页）
	do full purge;
	//5. 脏页比例超过 70% 刷新 100%innodb_io_capacity 个脏页到磁盘，
	// 否则刷新 10%innodb_io_capacity 个脏页
	if ( buf_get_modified_ratio_pct ＞ 70 % )
		do buffer pool flush 100%innodb_io_capacity dirty page
	else
		buffer pool flush 10%innodb_io_capacity dirty page
																
	goto loop
	//后台循环																
	background loop :
	//1. 删除无用的 undo 页
	do full purge
	//2. 合并 100%innodb_io_capacity 个插入缓冲
	do merge 100%innodb_io_capacity insert buffer
	//3.如果有任务，跳转到主循环，否则跳转到刷新循环
	if not idle	
		goto loop
	else
		goto flush loop
	
	//刷新循环
	flush loop :
	//不断刷新 100%innodb_io_capacity 个脏页，直到脏页比例没有超过阈值
	do buffer pool flush 100%innodb_io_capacity dirty page
	if ( buf_get_modified_ratio_pct ＞ innodb_max_dirty_pages_pct )
		goto flush loop
	//没有任务，跳转到暂停循环
	goto suspend loop
	
	//暂停循环
	suspend loop :
	//将主线程挂起，等待事件发生
	suspend_thread()
	waiting event
	goto loop;
}

```
### InnoDB 1.2.x 版本的 Master thread
