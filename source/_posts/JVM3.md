---
title: 《自己动手写JAVA虚拟机》学习笔记三【解析class文件】
date: 2019-02-14 11:38:04
tags:
    - JVM
    - JAVA
    - GO
    - 学习笔记
categories: JVM
copyright: true
comments: false
---
java虚拟机规范中使用一种类似C语言结构体来描述Class文件的基本结构，具体如下：
```java
ClassFile {
     u4             magic;//魔数
     u2             minor_version;//主版本号
     u2             major_version;//次版本号
     u2             constant_pool_count;//常量池长度
     cp_info        constant_pool[constant_pool_count-1];//常量池信息
     u2             access_flags;//该类的访问修饰符
     u2             this_class;//类索引
     u2             super_class;//父类索引
     u2             interfaces_count;//接口个数
     u2             interfaces[interfaces_count];//接口详细信息
     u2             fields_count;//属性个数
     field_info     fields[fields_count];//属性详细信息
     u2             methods_count;//方法个数
     method_info    methods[methods_count];//方法详情
     u2             attributes_count;//类文件属性个数
     attribute_info attributes[attributes_count];//类文件属性详细信息
}
```
### 准备工作

把ch02的目录结构复制一份改名ch03，在ch03的目录中创建一个classfile子目录。
```base
|-jvmgo
    |-ch01
    |-ch01
    |-ch03
        |-classfile
        |-classpath
        |-cmd.go
        |-main.go
```
为了学习编译后的class文件，新建一个classFileTest.java然后编译
```java
public class ClassFileTest {
    public static final boolean FLAG = true;
    public static final byte BYTE = 123;
    public static final char X = 'X';
    public static final short SHORT = 12345;
    public static final int INT = 123456789;
    public static final long LONG = 12345678901L;
    public static final float PI = 3.14f;
    public static final double E = 2.71828;
    public static void main(String[] args) throws RuntimeException {
        System.out.println("Hello, World!");
    }
}
```
用作者提供的[classpy](https://github.com/zxh0/classpy)的图形化工具，可以查看反编译后的class文件。