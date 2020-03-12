---
title: JAVA-Spring-AOP
date: 2020-03-09 15:07:00
tags:
    - JAVA
    - Spring
    - 学习笔记
categories: JAVA
author: Guyuqing
copyright: true
comments: false
---
# AOP
与OOP对比，面向切面，传统的OOP开发中的代码逻辑是自上而下的，而这些过程会产生一些横切性问题，这些横切性的问题和我们的主业务逻辑关系不大，这些横切性问题不会影响到主逻辑实现的，但是会散落到代码的各个部分，难以维护。AOP是处理一些横切性问题，AOP的编程思想就是把这些问题和主业务逻辑分开，达到与主业务逻辑解耦的目的。使代码的重用性和开发效率更高。
## AOP的应用场景
日志记录、权限验证、效率检查、事务管理、exception
## springAop的概念
* 切面(Aspect)：切面是通知和切点的结合，通知和切点共同定义了切面的全部内容
* 连接点(Join point)：目标对象中的方法。
* 通知(Advice)：定义了切面是做什么以及何时使用。
* 切点(Pointcut)：表示连接点的集合。（PointCut是JoinPoint的谓语，这是一个动作，主要是告诉通知连接点在哪里，切点表达式决定 JoinPoint 的数量）
* 目标对象(Target object)：目标对象 原始对象
* aop代理(AOP proxy)：代理对象  包含了原始对象的代码和增加后的代码的那个对象
* 织入(Weaving)：把代理逻辑加入到目标对象上的过程

## advice通知类型
* **Before** 连接点执行之前，但是无法阻止连接点的正常执行，除非该段执行抛出异常
* **After**  连接点正常执行之后，执行过程中正常执行返回退出，非异常退出
* **After throwing**  执行抛出异常的时候
* **After (finally)**  无论连接点是正常退出还是异常退出，都会执行
* **Around advice** 围绕连接点执行，例如方法调用。这是最有用的切面方式。around通知可以在方法调用之前和之后执行自定义行为。它还负责选择是继续加入点还是通过返回自己的返回值或抛出异常来快速建议的方法执行。

## springAop支持AspectJ
### 启用@AspectJ支持
1. 使用Java @Configuration启用@AspectJ支持，添加@EnableAspectJAutoProxy注释
    ```java
    @Configuration
    @EnableAspectJAutoProxy
    public class AppConfig {
    
    }
    ```
2. 使用XML配置启用@AspectJ支持
   ```java
    <aop:aspectj-autoproxy/>
   ```
### 声明一个Aspect
```java
@Component
@Aspect
public class UserAspect {
}
```
### 声明明一个pointCut
切入点表达式由@Pointcut注释表示。切入点声明由两部分组成:一个签名包含名称和任何参数，以及一个切入点表达式，该表达式确定我们对哪个方法执行感兴趣。
```java
@Pointcut("execution(* transfer(..))")// 切入点表达式
private void anyOldTransfer() {}// 切入点签名
```


### 声明一个Advice通知
```java
/**
 * 申明Aspect，并且交给spring容器管理
 */
@Component
@Aspect
public class UserAspect {
    /**
     * 申明切入点，匹配UserDao所有方法调用
     * execution匹配方法执行连接点
     * within:将匹配限制为特定类型中的连接点
     * args：参数
     * target：目标对象
     * this：代理对象
     */
    @Pointcut("execution(* com.yao.dao.UserDao.*(..))")
    public void pintCut(){
        System.out.println("point cut");
    }
    /**
     * 申明before通知,在pintCut切入点前执行
     * 通知与切入点表达式相关联，
     * 并在切入点匹配的方法执行之前、之后或前后运行。
     * 切入点表达式可以是对指定切入点的简单引用，也可以是在适当位置声明的切入点表达式。
     */
    @Before("com.yao.aop.UserAspect.pintCut()")
    public void beforeAdvice(){
        System.out.println("before");
    }
}
```




## 连接点joinPoint的意义
1. execution：用于匹配方法执行 join points连接点，最小粒度方法，在aop中主要使用。
   > execution(modifiers-pattern? ret-type-pattern declaring-type-pattern?name-pattern(param-pattern) throws-pattern?)
   > 这里问号表示当前项可以有也可以没有，其中各项的语义如下
   > **modifiers-pattern**：方法的可见性，如public，protected；
   > **ret-type-pattern**：方法的返回值类型，如int，void等；
   > **declaring-type-pattern**：方法所在类的全路径名，如com.spring.Aspect；
   > **name-pattern**：方法名类型，如buisinessService()；
   > **param-pattern**：方法的参数类型，如java.lang.String；
   > **throws-pattern**：方法抛出的异常类型，如java.lang.Exception；
   
   example:
   ```java
       @Pointcut("execution(* com.chenss.dao.*.*(..))")//匹配com.chenss.dao包下的任意接口和类的任意方法
       @Pointcut("execution(public * com.chenss.dao.*.*(..))")//匹配com.chenss.dao包下的任意接口和类的public方法
       @Pointcut("execution(public * com.chenss.dao.*.*())")//匹配com.chenss.dao包下的任意接口和类的public 无方法参数的方法
       @Pointcut("execution(* com.chenss.dao.*.*(java.lang.String, ..))")//匹配com.chenss.dao包下的任意接口和类的第一个参数为String类型的方法
       @Pointcut("execution(* com.chenss.dao.*.*(java.lang.String))")//匹配com.chenss.dao包下的任意接口和类的只有一个参数，且参数为String类型的方法
       @Pointcut("execution(* com.chenss.dao.*.*(java.lang.String))")//匹配com.chenss.dao包下的任意接口和类的只有一个参数，且参数为String类型的方法
       @Pointcut("execution(public * *(..))")//匹配任意的public方法
       @Pointcut("execution(* te*(..))")//匹配任意的以te开头的方法
       @Pointcut("execution(* com.chenss.dao.IndexDao.*(..))")//匹配com.chenss.dao.IndexDao接口中任意的方法
       @Pointcut("execution(* com.chenss.dao..*.*(..))")//匹配com.chenss.dao包及其子包中任意的方法
   ```
   由于Spring切面粒度最小是达到方法级别，而execution表达式可以用于明确指定方法返回类型，类名，方法名和参数名等与方法相关的信息，并且在Spring中，大部分需要使用AOP的业务场景也只需要达到方法级别即可，因而execution表达式的使用是最为广泛的
2. within:表达式的最小粒度为类
   ```java
       @Pointcut("within(com.chenss.dao.*)")//匹配com.chenss.dao包中的任意方法
       @Pointcut("within(com.chenss.dao..*)")//匹配com.chenss.dao包及其子包中的任意方法
   ```
   within与execution相比，粒度更大，仅能实现到包和接口、类级别。而execution可以精确到方法的返回值，参数个数、修饰符、参数类型等
3. args:表达式的作用是匹配指定参数类型和指定参数数量的方法,与包名和类名无关
   ```java
       @Pointcut("args(java.io.Serializable)")//匹配运行时传递的参数类型为指定类型的、且参数个数和顺序匹配
       @Pointcut("@args(com.chenss.anno.Chenss)")//接受一个参数，并且传递的参数的运行时类型具有@Classified
   ```
   args同execution不同的地方在于,args匹配的是运行时传递给方法的参数类型,execution(* *(java.io.Serializable))匹配的是方法在声明时指定的方法参数类型。
4. this:JDK代理时，指向接口和代理类proxy，cglib代理时 指向接口和子类(不使用proxy)
5. target:指向接口和子类
   ```java
        /**
         * 此处需要注意的是，如果配置设置proxyTargetClass=false，或默认为false，则是用JDK代理，否则使用的是CGLIB代理
         * JDK代理的实现方式是基于接口实现，代理类继承Proxy，实现接口。
         * 而CGLIB继承被代理的类来实现。
         * 所以使用target会保证目标不变，关联对象不会受到这个设置的影响。
         * 但是使用this对象时，会根据该选项的设置，判断是否能找到对象。
         */
        @Pointcut("target(com.chenss.dao.IndexDaoImpl)")//目标对象，也就是被代理的对象。限制目标对象为com.chenss.dao.IndexDaoImpl类
        @Pointcut("this(com.chenss.dao.IndexDaoImpl)")//当前对象，也就是代理对象，代理对象时通过代理目标对象的方式获取新的对象，与原值并非一个
        @Pointcut("@target(com.chenss.anno.Chenss)")//具有@Chenss的目标对象中的任意方法
        @Pointcut("@within(com.chenss.anno.Chenss)")//等同于@targ
   ```
   
   


