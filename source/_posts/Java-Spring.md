---
title: JAVA-Spring
date: 2020-03-06 17:1:00
tags:
    - JAVA
    - Spring
    - 学习笔记
categories: JAVA
author: Guyuqing
copyright: true
comments: false
---
# springIOC
## what is IOC
> 控制反转（Inversion of Control，缩写为IoC），是面向对象编程中的一种设计原则，将你设计好的对象交给容器控制，可以用来减低计算机代码之间的耦合度。
> 其中最常见的方式叫做依赖注入（Dependency Injection，简称`DI`），还有一种方式叫“依赖查找”（Dependency `Lookup`）

## 依赖注入（Dependency Injection）
依赖：比如A.class中有一个B.class的属性，那么我们可以理解为A依赖了B
依赖注入：由容器动态的将某个依赖关系注入到组件之中。
依赖注入是实现IOC的一种方式。

## 为什么要使用spring IOC？
> 在日常程序开发过程当中，我们推荐面向抽象编程，面向抽象编程会产生类的依赖
> 当然如果你够强大可以自己写一个管理的容器
> 但是既然spring以及实现了，并且spring如此优秀，我们仅仅需要学习spring框架便可。
> 当我们有了一个管理对象的容器之后，类的产生过程也交给了容器，至于我们自己的程序则可以不需要去关系这些对象的产生了。

## spring实现IOC的思路和方法
1. 应用程序中提供类，提供依赖关系（属性或者构造方法）
2. 把需要交给容器管理的对象通过配置信息告诉容器（xml、annotation，javaconfig）
3. 把各个类之间的依赖关系通过配置信息告诉容器

> 配置这些信息的方法有三种分别是xml，annotation和javaconfig
> 维护的过程称为自动注入，自动注入的方法有两种`构造方法和setter`
> 自动注入的值可以是对象，数组，map，list和常量比如字符串整形等

## spring编程的风格
1. schemal-based-------xml
2. annotation-based-----annotation
3. java-based----java Configuration

## 注入的两种方法
官网文档已经很详细了：https://docs.spring.io/spring-framework/docs/current/spring-framework-reference/core.html#beans-factory-properties-detailed

### 构造方法注入（Constructor-based Dependency Injection）
构造方法参考文档：https://docs.spring.io/spring-framework/docs/current/spring-framework-reference/core.html#beans-constructor-injection

### setter方法注入（Setter-based Dependency Injection）
setter参考文档：https://docs.spring.io/spring-framework/docs/current/spring-framework-reference/core.html#beans-setter-injection


## 自动装配
上面说过，IOC的注入有两个地方需要提供依赖关系，一是类的定义中，二是在spring的配置中需要去描述。
自动装配则把第二个取消了，即我们仅仅需要在类中提供依赖，继而把对象交给容器管理即可完成注入。

自动装配的优点参考文档：https://docs.spring.io/spring-framework/docs/current/spring-framework-reference/core.html#beans-factory-autowire
缺点参考文档：https://docs.spring.io/spring-framework/docs/current/spring-framework-reference/core.html#beans-autowired-exceptions

## 自动装配的方法
* no：默认值，表示没有自动装配，应使用显式 bean 引用进行装配。
* byName：它根据 bean 的名称注入对象依赖项。
* byType：它根据类型注入对象依赖项。
* constructor：通过构造函数来注入依赖项，需要设置大量的参数。

## @Component，@Service，@Controller，@Repository
* @Component是一个通用的Spring容器管理的单例bean组件
* @Repository 通常用于持久层
* @Service 通常用于业务逻辑层
* @Controller 通常用于表现层（spring-mvc的注解）

`这几种注解当前的作用没有任何区别。`
官网有这样一段话，意思是这几种注解在未来可能会有其他语意。因此推荐按照通用使用方式使用注解。
>  @Repository, @Service, and @Controller can also carry additional semantics in future releases of the Spring Framework


## spring懒加载
官方文档：https://docs.spring.io/spring-framework/docs/current/spring-framework-reference/core.html#beans-factory-lazy-init

## springbean的作用域
文档参考：https://docs.spring.io/spring-framework/docs/current/spring-framework-reference/core.html#beans-factory-scopes

### Singleton 中引用了一个Prototype的bean的时候引发的问题 
官网引导我们参考：https://docs.spring.io/spring-framework/docs/current/spring-framework-reference/core.html#beans-factory-method-injection

由于Singleton状态的bean A在初始化的时候只new一次，也只会注入一次依赖的对象B
因此B对象设置为Prototype 就没有任何意义。解决方式参考官网。



