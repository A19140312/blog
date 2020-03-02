---
title: JAVA-AQS
date: 2019-10-23 14:41:04
tags:
    - JAVA
    - 并发
    - 学习笔记
categories: JAVA
author: Guyuqing
copyright: true
comments: false
---
# AQS
AQS是AbstractQueuedSynchronizer的简称。AQS提供了一种实现阻塞锁和一系列依赖FIFO等待队列的同步器的框架，如下图所示。
![](Java-AQS/CLH.jpg)
state: AQS维护了一个volatile long类型的state,state = 0 表示无线程占用，state > 0 表示有线程占用
当state > 0 有线程占用时，队列中其他线程自旋等待。//设置当前线程占有资源

