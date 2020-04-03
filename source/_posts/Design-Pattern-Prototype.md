---
title: 设计模式-原型模式
date: 2020-04-02 20:06:00
tags:
    - 设计模式
categories: 设计模式
author: Guyuqing
copyright: false
comments: false
---
## 什么是原型模式
原型实例指定创建对象的种类，并且通过拷贝这些原型创建新的对象。

相信大家都都听过Java中的克隆（clone()），所谓的原型模式其实就是克隆，以某个对象为原型，复制出新的对象。


## 代码实现
原型模式其实就是Java中的克隆，在Java中实现克隆可以通过实现 Cloneable接口，并重写clone()方法来实现。
**可以发现Cloneable接口中并没有定义任何方法**，clone()方法定义在Object中，其实Cloneable和Serializable一样都是标记型接口，内部没有方法和属性，实现Cloneable接口表示该对象能被克隆，能使用Object.clone()方法。如果没有实现Cloneable的类调用Object.clone()方法就会抛出CloneNotSupportedException。

**Prototype**
实现Cloneable，并重写clone()方法，Prototype有两个属性，一个是基本类型的，一个是对象引用，之后来看clone的结果是怎么样的。
```java
public class Prototype implements Cloneable {
    //基本类型的属性
    private String attribute;

    //对象属性，引用
    private Attribute attributeObject;

    public Prototype(String attribute, Attribute attributeObject) {
        this.attribute = attribute;
        this.attributeObject = attributeObject;
    }

    public String getAttribute() {
        return attribute;
    }

    public void setAttribute(String attribute) {
        this.attribute = attribute;
    }

    public Attribute getAttributeObject() {
        return attributeObject;
    }

    public void setAttributeObject(Attribute attributeObject) {
        this.attributeObject = attributeObject;
    }

    /**
     * 重写clone方法，这里实现的是浅拷贝，如果要进行深拷贝需要自己实现。
     * @return
     * @throws CloneNotSupportedException
     */
    @Override
    public Object clone() throws CloneNotSupportedException {
        return super.clone();
    }
}
```

**Attribute**

```java
public class Attribute {
    public String name;

    public Attribute(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
```
客户端调用和输出
```java
public class Client {
    public static void main(String[] args) throws CloneNotSupportedException {
        Attribute attributeObject = new Attribute("BrightLoong");
        Prototype prototype = new Prototype("属性", attributeObject);
        Prototype copy = (Prototype) prototype.clone();

        System.out.println(copy.getAttribute() + "======" + copy.getAttributeObject().getName());

        //克隆后，原型中的对象引用的还是同一个，所以输出true
        System.out.println(attributeObject == copy.getAttributeObject());
    }
}
```
```bash
属性======BrightLoong
true
```
可以看到结果符合预期，进行了clone，但是发现Attribute属性试用==比较返回的是true，说明引用的是同一个Attribute，**两个Prototype对象引用了同一个Attribute对象，这就是所谓的浅拷贝。**

### 浅拷贝和深拷贝
Object的clone()方法，如果属性是基本类型，对该属性的值进行复制，如果属性是引用类型，则复制引用而不是复制引用的对象。

浅拷贝：浅拷贝是指拷贝对象时，拷贝的对象的所有基本类型属性的值都与原来的对象的值相同，而引用属性仍然指向原来对象中的引用属性。

深拷贝：深拷贝不仅拷贝对象本身，而且拷贝对象包含的引用指向的所有对象。

### 深拷贝代码实现
如何实现深拷贝，当然最简单粗暴的方法就是对引用的对象实现克隆，如果引用的对象中还有对象，那么对引用的对象中的对象的实现克隆，依次类推。

这里使用另外一种方法，通过序列化(Serialization) 类实现深克隆。通过将对象写到流中，写到流中的对象是原有对象的一个拷贝，而原对象仍然存在于内存中，再从流里将其读出来，可以实现深克隆。 对象序列化需要实现Serializable 接口。

**Prototype**
同时实现Cloneable, Serializable ，并重写clone()方法。
```java
public class Prototype implements Cloneable, Serializable {
    //基本类型的属性
    private String attribute;

    //对象属性，引用
    private Attribute attributeObject;

    public Prototype(String attribute, Attribute attributeObject) {
        this.attribute = attribute;
        this.attributeObject = attributeObject;
    }

    public String getAttribute() {
        return attribute;
    }

    public void setAttribute(String attribute) {
        this.attribute = attribute;
    }

    public Attribute getAttributeObject() {
        return attributeObject;
    }

    public void setAttributeObject(Attribute attributeObject) {
        this.attributeObject = attributeObject;
    }

    /**
     * 重写clone方法，这里实现的是浅拷贝，如果要进行深拷贝需要自己实现。
     * @return
     * @throws CloneNotSupportedException
     */
    @Override
    public Object clone() throws CloneNotSupportedException {
        //将对象写入流中

        ByteArrayOutputStream bao=new  ByteArrayOutputStream();
        ObjectOutputStream oos = null;
        ObjectInputStream ois = null;
        Object copy = null;
        try {
            //将对象写入流中
            oos = new ObjectOutputStream(bao);
            oos.writeObject(this);
            //将对象从流中取出
            ByteArrayInputStream bis=new  ByteArrayInputStream(bao.toByteArray());
            ois=new  ObjectInputStream(bis);
            copy =  ois.readObject();
        } catch (Exception e) {
            e.printStackTrace();
            if (oos != null) {
                try {
                    oos.close();
                } catch (IOException e1) {
                    e1.printStackTrace();
                }
            }
            if (ois != null) {
                try {
                    ois.close();
                } catch (IOException e1) {
                    e1.printStackTrace();
                }
            }
        }
        return copy;
    }
}
```

**Attribute**
```java
public class Attribute implements Serializable{
    public String name;

    public Attribute(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
```

**输出**
还是使用原来的Client，输出如下，可以看到Attribute属性不再是同一个了，使用==比较返回了false。
```bash
属性======BrightLoong
false
```

## 总结
使用场景
    * 如果某个对象new的过程中很耗时（类初始化需要消化非常多的资源，这个资源包括数据、硬件资源等 ），则可以考虑使用原型模式 。
    * 如果系统要保存对象的状态，而对象的状态变化很小，或者对象本身占用内存较少时。
    * 一个对象需要提供给其他对象访问，而且各个调用者可能都需要修改其值时，可以考虑使用原型模式拷贝多个对象供调用者使用。
    
优点
    * 提高了效率，逃避了类的构造方法（对象拷贝时，类的构造函数是不会被执行的）。
    * 当创建新的对象实例较为复杂时，使用原型模式可以简化对象的创建过程 。
    
缺点
    * 在实现深克隆的时候，使用的对象可能是原来已经存在的，并且没有实现Serializable，这个时候只能自己去一层一层的克隆，编写较为复杂的代码。
    
其他: 在很多工具类中已经实现了属性拷贝，并不用我们自己去实现比如apache.commons.beanutils 中的BeanUtils.copyProperties(obj1,obj2) 和PropertyUtils .copyProperties(obj1,obj2)。spring中也有类似的实现。