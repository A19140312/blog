---
title: 设计模式-策略模式
date: 2019-12-13 12:00:04
tags:
    - 设计模式
categories: 设计模式
author: Guyuqing
copyright: true
comments: false
---
## 什么是策略模式
策略这个词应该怎么理解，打个比方说，我们出门的时候会选择不同的出行方式，比如骑自行车、坐公交、坐火车、坐飞机、坐火箭等等，这些出行方式，每一种都是一个策略。

再比如我们去逛商场，商场现在正在搞活动，有打折的、有满减的、有返利的等等，其实不管商场如何进行促销，说到底都是一些算法，这些算法本身只是一种策略，并且这些算法是随时都可能互相替换的，比如针对同一件商品，今天打八折、明天满100减30，这些策略间是可以互换的。

**策略模式（Strategy）**，定义了一组算法，将每个算法都封装起来，并且使它们之间可以互换。
<!-- more -->
## 示例

### 模拟鸭子项目
![](Design-Pattern-Strategy/1.png)
```java

public abstract class Duck {	
    public void Quack() {	
        System.out.println("~~gaga~~");
    }
    public abstract void display();
    public void swim() {	
        System.out.println("~~im swim~~");
    }
}

```
GreenHeadDuck继承Duck ：
```java

public class GreenHeadDuck extends Duck {	
    @Override	
    public void display() {	
          System.out.println("**GreenHead**");
    }
}
```
### 新需求

添加会飞的鸭子

```java
public abstract class Duck {
        //...;
	 public void Fly() {	
	 	System.out.println("~~im fly~~");
	 }
}
```
问题来了,这个Fly让所有子类都会飞了，这是不科学的。并非Duck所有的子类都会飞。在Duck超类中加上新的行为，会使得某些并不适合该行为的子类也具有该行为。
这个导致，后面几十个鸭子不没有这个功能，不会飞，那么他们的都要去实现。工作量大，而且重复劳动。
所以：超类挖的一个坑，每个子类都要来填，增加工作量，复杂度O(N^2)。不是好的设计方式

### 用策略模式来解决新需求
需要新的设计方式，应对项目的扩展性，降低复杂度：

1）分析项目变化与不变部分，提取变化部分，然后把变化的部分抽象成接口+实现；

2）鸭子哪些功能是会根据新需求变化的？叫声、飞行...

![](Design-Pattern-Strategy/2.png)

### 重新设计模拟鸭子项目

```java
public abstract class Duck {	
    FlyBehavior mFlyBehavior;
    QuackBehavior mQuackBehavior;
    public Duck() { }
    public void Fly() {	
        mFlyBehavior.fly();
    }
    public void Quack() {	
        mQuackBehavior.quack();
    }
    public abstract void display();
}


public class GreenHeadDuck extends Duck {
    public GreenHeadDuck() {
        mFlyBehavior = new GoodFlyBehavior();
        mQuackBehavior = new GaGaQuackBehavior();
    }
    @Override
    public void display() {
        System.out.println("I’m a real GreenHeadDuck");
    }
}

```
## 总结
1. 分析项目中变化部分与不变部分（方法论）——>这个方法论不仅是策略模式中才可以用的，用来分析项目中变法的何不变化的，变化的就可以怎么来抽取替换。而且变化的抽离出来的行为族，行为族之间是可以来相互替换的。

2. 多用组合少用继承；用行为类组合，而不是行为的继承。更有弹性

## 策略模式中的设计原则
1. 开闭原则（Open-Closed Principle，缩写为OCP）
    * 一个软件实体应当对扩展开放(例如对抽象层的扩展)，对修改关闭(例如对抽象层的修改)。即在设计一个模块的时候，应当使这个模块可以在不被修改的前提下被扩展。
    * 开闭原则的关键，在于抽象。策略模式，是开闭原则的一个极好的应用范例。

2. 里氏替换原则（Liskov Substitution Principle，缩写为LSP）
    * 里氏替换原则里一个软件实体如果使用的是**一个基类的话，那么一定适用于其子类，而且它根本不能察觉到基类对象和子类对象的区别。** 比如，假设有两个类，一个是Base类，一个是Derived类，并且Derived类是Base类的子类。那么一个方法如果可以接受一个基类对象b的话：method1(Base b)，那么它必然可以接受一个子类对象d，也即可以有method1(d)。反之，则不一定成立。
    * 里氏替换原则讲的是基类与子类的关系。只有当这种关系存在时，里氏替换关系才存在，反之则不存在。
    * 策略模式之所以可行的基础便是里氏替换原则：策略模式要求所有的策略对象都是可以互换的，因此它们都必须是一个抽象策略角色的子类。在客户端则仅知道抽象策略角色类型，虽然变量的真实类型可以是任何一个具体策略角色的实例。
