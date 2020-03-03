title: JAVA-Volatile
date: 2020-02-27 19:36:00
tags:
    - JAVA
    - 并发
    - 学习笔记
categories: JAVA
author: Guyuqing
copyright: true
comments: false
---
## Volatile关键字
java编程语言允许线程访问共享变量，为了确保共享变量能被准确和一致的更新，线程应该确保通过排他锁单独获得这个变量。Java语言提供了volatile，在某些情况下比锁更加方便。如果一个字段被声明成volatile，java线程内存模型确保所有线程看到这个变量的值是一致的。
## 机器硬件CPU与JMM
{% post_link Java-MemoryModel 点击这里查看这篇文章 %}

## Volatile关键字的作用
volatile作用：让其他线程能够马上感知到某一线程多某个变量的修改
* 保证可见性:对共享变量的修改，其他的线程马上能感知到
* 保证有序性:重排序（编译阶段、指令优化阶段）volatile之前的代码不能调整到他的后面，volatile之后的代码不能调整到他的前面
* **不能保证原子性**：
    举个例子：   
     ```java
             public class Test {
                 public volatile int inc = 0;
             
                 public void increase() {
                     inc++;
                 }
             
                 public static void main(String[] args) {
                     final Test test = new Test();
                     for(int i=0;i<10;i++){
                         new Thread(){
                             public void run() {
                                 for(int j=0;j<1000;j++)
                                     test.increase();
                             };
                         }.start();
                     }
             
                     while(Thread.activeCount()>1)  //保证前面的线程都执行完
                         Thread.yield();
                     System.out.println(test.inc);
                 }
             }
     ```
    线程1对变量进行读取操作之后，被阻塞了的话，并没有对inc值进行修改。然后虽然volatile能保证线程2对变量inc的值读取是从内存中读取的，但是线程1没有进行修改，所以线程2根本就不会看到修改的值。

## Volatile实现原理
<table>
        <tr>
            <th>Java代码</th>
            <th>instance = new Singleton();//instance是volatile变量</th>
        </tr> 
        <tr>
            <th>汇编代码</th>
            <th>0x01a3de1d: movb $0x0,0x1104800(%esi);<br>0x01a3de24: lock  addl $0x0,(%esp);</th>
        </tr> 
</table> 

有volatile变量修饰的共享变量进行写操作的时候会多第二行汇编代码，通过查IA-32架构软件开发者手册可知，`lock`前缀的指令在多核处理器下会引发了两件事情。
* 将当前处理器缓存行的数据会写回到系统内存。
* 这个写回内存的操作会引起在其他CPU里缓存了该内存地址的数据无效。

## Volatile的使用场景
* 状态标志（开关模式）
    ```java
    public class ShutDowsnDemmo extends Thread{
        private volatile boolean started=false;
    
        @Override
        public void run() {
            while(started){
                dowork();
            }
        }
        public void shutdown(){
            started=false;
        }
    }
    ```
* 双重检查锁定（double-checked-locking）
* 需要利用顺序性

## volatile与synchronized的区别
1. 使用上的区别:
    Volatile只能修饰变量，synchronized只能修饰方法和语句块
2. 对原子性的保证:
    Volatile不能保证原子性，synchronized可以保证原子性
3. 对可见性的保证:
    都可以保证可见性，但实现原理不同;Volatile对变量加了lock，synchronized使用monitorEnter和monitorexit
4. 对有序性的保证:
    Volatile能保证有序，synchronized可以保证有序性，但是代价（重量级）并发退化到串行
5. 其他:
    Volatile不会引起阻塞，synchronized引起阻塞







    