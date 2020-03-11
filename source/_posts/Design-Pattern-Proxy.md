---
title: 设计模式-代理模式
date: 2020-03-10 23:15:04
tags:
    - 设计模式
categories: 设计模式
author: Guyuqing
copyright: true
comments: false
---
# 什么是代理
给某一个对象提供一个代理，并由代理对象控制对原对象的引用
简单来说就是增强了一个对象的功能，比如：买火车票，app就是一个代理，他代理了火车站

#java实现的代理的办法
## 代理的名词
* 代理对象：增强后的对象
* 目标对象：被增强的对象

## 静态代理
### 继承
代理对象继承目标对象，重写需要增强的方法
缺点：会代理类过多，非常复杂

以租房为例，我们一般用租房软件、找中介或者找房东。这里的中介就是代理者。
```java
// 目标对象
public class RentHose {

	public void rentHose() {
		System.out.println("租了一间房子。。。");
	}
}

//代理对象
public class IntermediaryProxy extends RentHose{
	@Override
	public void rentHose() {
		System.out.println("交中介费..");
		super.rentHose();
		System.out.println("中介负责维修管理..");
	}
}

public class Test {
	public static void main(String[] args) {
		RentHose rentHose = new IntermediaryProxy();
		rentHose.rentHose();
	}
}
```

### 聚合
目标对象和代理对象实现同一个接口，代理对象当中要包含目标对象。
缺点：也会产生类爆炸，只不过比继承少一点点

```java
public interface IRentHose {
	public void rentHose();
}

// 目标对象
public class RentHose implements IRentHose{

	@Override
	public void rentHose() {
		System.out.println("租了一间房子。。。");
	}
}

// 代理对象
public class IntermediaryProxy implements IRentHose{

	private IRentHose iRentHose;

	public IntermediaryProxy(IRentHose iRentHose) {
		this.iRentHose = iRentHose;
	}

	@Override
	public void rentHose() {
		System.out.println("交中介费..");
		iRentHose.rentHose();
		System.out.println("中介负责维修管理..");
	}
}

public class Test {
	public static void main(String[] args) {
		RentHose rentHose = new RentHose();
		IRentHose iRentHose = new IntermediaryProxy(rentHose);
		iRentHose.rentHose();
	}
}
```

### 总结
如果在不确定的情况下，尽量不要去使用静态代理。因为一旦你写代码，就会产生类，一旦产生类就爆炸。

## 动态代理
我们知道现在的中介不仅仅是有租房业务，同时还有卖房、家政、维修等得业务，只是我们就不能对每一个业务都增加一个代理，就要提供通用的代理方法，这就要通过动态代理来实现了。

### JDK动态代理
通过接口->反射得到字节码(.class)，然后把字节码转成Class对象（利用native方法）。

```java
public class IntermediaryProxy implements InvocationHandler {

	private Object obj;

	public IntermediaryProxy(Object obj) {
		this.obj = obj;
	}

	/**
	 * 调用被代理的方法
	 * @param proxy：代理对象
	 * @param method：方法
	 * @param args：参数
	 * @return 
	 * @throws Throwable
	 */
	@Override
	public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
		System.out.println("交中介费");
		//执行目标对象的方法
		Object result =  method.invoke(this.obj, args);
		System.out.println("中介负责维修管理");
		return  result;
	}
}

public class Test {
	public static void main(String[] args) {
		RentHose rentHose = new RentHose();
		//定义一个handler
		InvocationHandler handler = new IntermediaryProxy(rentHose);
		// 获取对象的classLoader
		ClassLoader classLoader = rentHose.getClass().getClassLoader();
		// JDK 动态代理产生代理类
		IRentHose proxy = (IRentHose) Proxy.newProxyInstance(classLoader,new Class[]{IRentHose.class},handler);
		proxy.rentHose();
	}
}
```

### 自己模拟的动态代理
步骤：
    1. 通过目标对象反射和字符串拼接生成一个类文件
    2. 然后调用第三方的编译技术,动态编译这个产生的类文件成class文件
    3. 利用UrlclassLoader,把这个动态编译的类加载到jvm当中
    4. 最后通过反射把这个类实例化。
    