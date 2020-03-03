---
title: 设计模式-单例模式
date: 2020-02-29 17:37:00
tags:
    - 设计模式
categories: 设计模式
author: Guyuqing
copyright: true
comments: false
---
## 单例模式
多个线程操作不同实例对象。多个线程要操作同一对象，要保证对象的唯一性

## 单例模式的特点
1. 有一个实例化的过程（只有一次），产生实例化对象
2. 提供返回实例对象的方法

## 单例模式的分类

### 饿汉式
```java
public class HungrySingleton {
	//加载时就产生了实例对象
	private static HungrySingleton instance = new HungrySingleton();

	private HungrySingleton() {
	}
	//返回实例对象
	public static HungrySingleton getInstance() {
		return instance;
	}

	public static void main(String[] args) {
		for(int i = 0 ; i < 10 ; i ++){
			new Thread(()->{
				HungrySingleton hungerySingleton = HungrySingleton.getInstance();
				System.out.println(hungerySingleton);
			}).start();
		}
	}
}
```

* 线程安全性：在加载的时候已经被实例化，所以只有这一次，线程安全的。
* 懒加载：没有延迟加载
* 性能：长时间不使用，数据一直放在堆中影响性能


### 懒汉式
```java
public class LazySingleton {
	private static LazySingleton instance = null;

	private LazySingleton() {
	}

	public static LazySingleton getInstance() {
		if(instance == null){
			instance = new LazySingleton();
		}
		return instance;
	}

	public static void main(String[] args) {
		for(int i = 0 ; i < 10 ; i ++){
		    new Thread(()-> System.out.println(LazySingleton.getInstance())).start();
		}
	}
}
```
* 线程安全性：不能保证实例对象的唯一性
* 懒加载：有延迟加载
* 性能：使用时才进行加载，性能较好

### 懒汉式+同步方法
将懒汉式的get方法加上synchronized
```java
	public synchronized static LazySingleton getInstance() {
		if(instance == null){
			instance = new LazySingleton();
		}
		return instance;
	}
```
* 线程安全性：synchronized保证线程安全
* 懒加载：有延迟加载
* 性能：多个线程调用该方法时 synchronized 会使线程阻塞，退化到了串行执行

### Double-Check-Locking
```java
public class DCLSingleton {
	private static DCLSingleton instance = null;

	private DCLSingleton() {
	}

	public static DCLSingleton getInstance() {
		if(instance == null){
			synchronized (DCLSingleton.class){
				if(instance == null){
					instance = new DCLSingleton();
				}
			}
		}
		return instance;
	}
	public static void main(String[] args) {
		for(int i = 0 ; i < 10 ; i ++){
			new Thread(()-> System.out.println(DCLSingleton.getInstance())).start();
		}
	}
}
```
* 线程安全性：线程安全
* 懒加载：有延迟加载
* 性能：性能比较好
* 缺点：会因为指令重排，引起空指针异常。

### Volatile+Double-check
添加volatile 避免空指针异常。
```java
	private volatile static DCLSingleton instance = null;
```

### Holder
声明类的时候，成员变量中不声明实例变量，而放到内部静态类中，
```java
public class HolderSingleton {
	private HolderSingleton() {
	}
	//通过内部类实现懒加载，只有调用时才会进行实例化，静态类只能实例一次，保证线程安全
	private static class Holder{
		private static HolderSingleton instance=new HolderSingleton();
	}
	public static HolderSingleton getInstance(){
		return Holder.instance;
	}
}
```

### 枚举
```java
public class EnumSingleton {
	private EnumSingleton() {
	}
	//延迟加载
	private enum EnumHolder{
		INSTANCE;
		private EnumSingleton instance=null;

		EnumHolder() {
			this.instance = new EnumSingleton();
		}
	}
	public static EnumSingleton getInstance(){
		return EnumHolder.INSTANCE.instance;
	}
}
```
