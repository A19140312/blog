---
title: JAVA-CAS
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
# CAS

在看线程池源码的时候发现有很多CAS操作，那么什么是CAS？
<!-- more -->
## 定义
CAS是英文单词 Compare And Swap 的缩写，翻译过来就是比较并替换，它是一种原子操作，同时 CAS 是一种乐观机制。
java.util.concurrent 包很多功能都是建立在 CAS 之上，如 ReenterLock 内部的 AQS，各种原子类，其底层都用 CAS来实现原子操作。

## 如何解决并发安全问题
在我们认识 CAS 之前，我们是通过什么来解决并发带来的安全问题呢？
volatile 关键字可以保证变量的可见性，但保证不了原子性；
synchronized 关键字利用 JVM 字节码层面来实现同步机制，它是一个悲观锁机制。

```java
public class Test {
  public volatile int i;
  public void add() {
    i++;
  }
}
```
使用 `javap -c Test.class` 命令查看看add方法的字节码指令
```java
public void add();
    Code:
       0: aload_0
       1: dup
       2: getfield      #2                  // Field n:I
       5: iconst_1
       6: iadd
       7: putfield      #2                  // Field n:I
      10: return

```
i++被拆分成了几个指令：
    1. 执行getfield拿到原始i；
    2. 执行iadd进行加1操作；
    3. 执行putfield写把累加后的值写回i；

当线程 1 执行到加 1 步骤时，由于还没有执行赋值改变变量的值，这时候并不会刷新主内存区中的变量，
如果此时线程 2 正好要拷贝该变量的值到自己私有缓存中，问题就出现了，当线程 2 拷贝完以后，线程1正好执行赋值运算，立马更新主内存区的值，那么此时线程 2 的副本就是旧的了，脏读又出现了。

怎么解决这个问题呢？
在 add 方法加上 synchronized 修饰解决。

```java
public class Test {
  public volatile int i;
  public synchronized void add() {
    i++;
  }
}
```
这个方案当然可行，但是大大降低了性能。

## CAS原理
CAS机制当中使用了3个基本操作数：内存地址V，旧的预期值A，要修改的新值B。
更新一个变量的时候，只有当变量的预期值A和内存地址V当中的实际值相同时，才会将内存值修改为 B 并返回 true，否则什么都不做，并返回 false。

### 源码分析

下面以`AtomicInteger`的实现为例，分析一下CAS是如何实现的。

```java
public class AtomicInteger extends Number implements java.io.Serializable {
    private static final long serialVersionUID = 6214790243416807050L;

    // setup to use Unsafe.compareAndSwapInt for updates
    private static final Unsafe unsafe = Unsafe.getUnsafe();
    private static final long valueOffset;

    static {
        try {
            valueOffset = unsafe.objectFieldOffset
                (AtomicInteger.class.getDeclaredField("value"));
        } catch (Exception ex) { throw new Error(ex); }
    }

    private volatile int value;
    // 省略部分代码
}

```
**Unsafe**：是CAS的核心类(后门类，执行CPU指令)，它可以提供硬件级别的原子操作，它可以获取某个属性在内存中的位置，也可以修改对象的字段值，其底层是用 C/C++ 
**valueOffset**：表示该变量值在内存中的偏移地址，因为Unsafe就是根据内存偏移地址获取数据的。
**value**：要修改的值，用volatile修饰，保证了多线程之间的内存可见性。


看看`AtomicInteger`如何实现并发下的累加操作：
```java
    // AtomicInteger.getAndAdd
    public final int getAndAdd(int delta) {
        return unsafe.getAndAddInt(this, valueOffset, delta);
    }
    
    // unsafe.getAndAddInt
    /**
    * var1：要修改的值
    * var2：期望值偏移地址
    * var4：要增加的值
    * var5：当前值
    * var5 + var4： 当前值+要增加的值 = 目标值
    */
    public final int getAndAddInt(Object var1, long var2, int var4) {
        int var5;
        do {
            var5 = this.getIntVolatile(var1, var2);//获取对象中offset偏移地址对应的整型field的值
        } while(!this.compareAndSwapInt(var1, var2, var5, var5 + var4));

        return var5;
    }
```
假设线程A和线程B同时执行getAndAdd操作（分别跑在不同CPU上）：

AtomicInteger里面的value原始值为 n，根据Java内存模型，线程A和线程B各自持有一份value的副本，值为n。
1. 线程A通过`getIntVolatile(var1, var2)`拿到value值 n，这时线程A被挂起。
2. 线程B也通过`getIntVolatile(var1, var2)`方法获取到value值 n，运气好，线程B没有被挂起，并执行compareAndSwapInt方法比较内存值也为 n，成功修改内存值为 m。
3. 这时线程A恢复，执行`compareAndSwapInt`方法比较，发现自己手里的值(n)和内存的值(m)不一致，说明该值已经被其它线程提前修改过了，那只能重新来一遍了。
4. 重新获取value值，因为变量value被volatile修饰，所以其它线程对它的修改，线程A总是能够看到，线程A继续执行`compareAndSwapInt`进行比较替换，直到成功。

继续深入看看Unsafe类中的compareAndSwapInt方法实现。
```java
public final native boolean compareAndSwapInt(Object var1, long var2, int var4, int var5);
```
Java 并没有直接实现 CAS，CAS 相关的实现是通过 C++ 内联汇编的形式实现的。Java 代码需通过 JNI 才能调用，位于 unsafe.cpp，
在OpenJDK8里的路径为: openjdk/hotspot/src/share/vm/prims/unsafe.cpp。
```C
UNSAFE_ENTRY(jboolean, Unsafe_CompareAndSwapInt(JNIEnv *env, jobject unsafe, jobject obj, jlong offset, jint e, jint x))
  UnsafeWrapper("Unsafe_CompareAndSwapInt");
  oop p = JNIHandles::resolve(obj);
  jint* addr = (jint *) index_oop_from_field_offset_long(p, offset);
  return (jint)(Atomic::cmpxchg(x, addr, e)) == e;
UNSAFE_END
```
逻辑执行流程：
1. obj是AtomicInteger对象，通过 JNIHandles::resolve() 获取obj在内存中OOP实例p
2. 根据成员变量value反射后计算出的内存偏移值offset去内存中取指针addr
3. 获得更新值x、指针addr、期待值e三个参数后，调用Atomic::cmpxchg(x, addr, e)
4. 通过Atomic::cmpxchg(x, addr, e)实现CAS
对应OpenJDK8的路径是: openjdk/hotspot/src/share/vm/runtime/atomic.cpp


```C
jbyte Atomic::cmpxchg(jbyte exchange_value, volatile jbyte* dest, jbyte compare_value) {
  assert(sizeof(jbyte) == 1, "assumption.");
  uintptr_t dest_addr = (uintptr_t)dest;
  uintptr_t offset = dest_addr % sizeof(jint);
  volatile jint* dest_int = (volatile jint*)(dest_addr - offset);
  jint cur = *dest_int;
  jbyte* cur_as_bytes = (jbyte*)(&cur);
  jint new_val = cur;
  jbyte* new_val_as_bytes = (jbyte*)(&new_val);
  new_val_as_bytes[offset] = exchange_value;
  while (cur_as_bytes[offset] == compare_value) {
    jint res = cmpxchg(new_val, dest_int, cur);
    if (res == cur) break;
    cur = res;
    new_val = cur;
    new_val_as_bytes[offset] = exchange_value;
  }
  return cur_as_bytes[offset];
}
```

其中的cmpxchg为核心内容. 但是这句代码根据操作系统和处理器的不同, 使用不同的底层代码. 

```C
#include "runtime/atomic.inline.hpp"
```

atomic.inline.hpp中定义如下，可见不同不同操作系统, 不同的处理器, 都要走不同的cmpxchg()方法的实现.

```C
#include "runtime/atomic.hpp"

// Linux
#ifdef TARGET_OS_ARCH_linux_x86
# include "atomic_linux_x86.inline.hpp"
#endif
#ifdef TARGET_OS_ARCH_linux_sparc
# include "atomic_linux_sparc.inline.hpp"
#endif
#ifdef TARGET_OS_ARCH_linux_zero
# include "atomic_linux_zero.inline.hpp"
#endif
#ifdef TARGET_OS_ARCH_linux_arm
# include "atomic_linux_arm.inline.hpp"
#endif
#ifdef TARGET_OS_ARCH_linux_ppc
# include "atomic_linux_ppc.inline.hpp"
#endif

// Solaris
#ifdef TARGET_OS_ARCH_solaris_x86
# include "atomic_solaris_x86.inline.hpp"
#endif
#ifdef TARGET_OS_ARCH_solaris_sparc
# include "atomic_solaris_sparc.inline.hpp"
#endif

// Windows
#ifdef TARGET_OS_ARCH_windows_x86
# include "atomic_windows_x86.inline.hpp"
#endif

// ..省略
```
以其中的linux操作系统 x86处理器为例, atomic_linux_x86.inline.hpp
在OpenJDK中路径如下: openjdk/hotspot/src/os_cpu/linux_x86/vm/atomic_linux_x86.inline.hpp

```C
#define LOCK_IF_MP(mp) "cmp $0, " #mp "; je 1f; lock; 1: "

inline jint     Atomic::cmpxchg    (jint     exchange_value, volatile jint*     dest, jint     compare_value) {
  int mp = os::is_MP();
  __asm__ volatile (LOCK_IF_MP(%4) "cmpxchgl %1,(%3)"
                    : "=a" (exchange_value)
                    : "r" (exchange_value), "a" (compare_value), "r" (dest), "r" (mp)
                    : "cc", "memory");
  return exchange_value;
}
```
已经开始内联汇编了，头疼

`__asm__`：表示汇编的开始
`volatile`：表示禁止编译器优化
`cmpxchgl`：就是汇编中x86的比较并交换指令了。
`LOCK_IF_MP`：是个内联函数，根据当前系统是否为多核处理器决定是否为cmpxchg1指令添加lock前缀。


简单说下C内联汇编的语法格式：
```C
__asm__ volatile("Instruction List"
 
: Output
 
: Input
 
: Clobber/Modify);
```
**instruction list**：它是汇编指令列表
**Clobber/Modify**：寄存器/内存修改标示。有时候,当你想通知GCC当前内联汇编语句可能会对某些寄存器或内存进行修改,希望GCC在编译时能够将这一点考虑进去;那么你就可以在Clobber/Modify部分声明这些寄存器或内存

所以上述汇编指令解释为：
嵌入式汇编规定把输出和输入寄存器按统一顺序编号，顺序是从输出寄存器序列从左到右从上到下以%0开始，分别记为%0、%1···%9。也就是说，输出的eax是%0，输入的exchange_value、compare_value、dest、mp分别是%1、%2、%3、%4。
然后看asm里的第一行指令，**cmpxchgl %1,(%3)**，比较eax(compare_value在eax中)与dest的值，如果相等，那么将**exchange_value**的值赋值给dest；否则，将dest的值赋值给eax。
然后看输出: "=a" (**exchange_value**) 表示把eax中存的值(compare_value)写入**exchange_value**变量中。
        
`Atomic::cmpxchg`这个函数最终返回值是exchange_value，也就有两种情况：
1. 如果cmpxchgl执行时compare_value和dest指针指向内存值相等则会使得dest指针指向内存值变成**exchange_value**，最终eax存的compare_value赋值给了**exchange_value**变量，即函数最终返回的值是原先的compare_value。
   此时Unsafe_CompareAndSwapInt的返回值(jint)(Atomic::cmpxchg(x, addr, e)) == e就是true，表明CAS成功。

2. 如果cmpxchgl执行时compare_value和(dest)不等则会把当前dest指针指向内存的值写入eax，最终输出时赋值给**exchange_value**变量作为返回值，
   导致(jint)(Atomic::cmpxchg(x, addr, e)) == e得到false，表明CAS失败。


### lock前缀
在单处理器系统中是不需要加lock的，因为能够在单条指令中完成的操作都可以认为是原子操作，中断只能发生在指令与指令之间。
在多处理器系统中,由于系统中有多个处理器在独立的运行，即使在能单条指令中完成的操作也可能受到干扰。

在所有的 X86 CPU 上都具有锁定一个特定内存地址的能力，当这个特定内存地址被锁定后，它就可以阻止其他的系统总线读取或修改这个内存地址。这种能力是通过 LOCK 指令前缀再加上前面的汇编指令来实现的。当使用 LOCK 指令前缀时，它会使 CPU 宣告一个 LOCK# 信号，这样就能确保在多处理器系统或多线程竞争的环境下互斥地使用这个内存地址。当指令执行完毕，这个锁定动作也就会消失。

## 缺点
1. CPU开销较大：在并发量比较高的情况下，如果许多线程反复尝试更新某一个变量，却又一直更新不成功，循环往复，会给CPU带来很大的压力。
2. 不能保证代码块的原子性：CAS机制所保证的只是一个变量的原子性操作，而不能保证整个代码块的原子性。比如需要保证多个变量共同进行原子性的更新，就得使用Synchronized了。
3. ABA问题：这是CAS机制最大的问题所在。

## ABA问题
线程 1 从内存位置 V 取出 A，这时候线程 2 也从内存位置 V 取出 A，此时线程 1 处于挂起状态，线程 2 将位置 V 的值改成 B，最后再改成 A，
这时候线程 1 再执行，发现位置 V 的值没有变化，尽管线程 1 也更改成功了，但内存地址V中的变量已经经历了A->B->A的改变。

举个例子：
假设有一个遵循CAS原理的提款机，小灰有100元存款，要用这个提款机来提款50元。
由于提款机硬件出了点小问题，小灰的提款操作被同时提交两次，开启了两个线程，两个线程都是获取当前值100元，要更新成50元。
理想情况下，应该一个线程更新成功，另一个线程更新失败，小灰的存款只被扣一次。
线程1首先执行成功，把余额从100改成50。线程2因为某种原因阻塞了。这时候，小灰的妈妈刚好给小灰汇款50元。
线程2仍然是阻塞状态，线程3执行成功，把余额从50改成100。
线程2恢复运行，由于阻塞之前已经获得了“当前值”100，并且经过compare检测，此时存款实际值也是100，所以成功把变量值100更新成了50。
小灰凭空少了50元钱。

所以真正要做到严谨的CAS机制，我们在Compare阶段不仅要比较期望值A和地址V中的实际值，还要比较变量的版本号是否一致。
在Java当中，`AtomicStampedReference`类就实现了用版本号做比较的CAS机制。

```java
    private static class Pair<T> {
        final T reference;
        final int stamp;
        private Pair(T reference, int stamp) {
            this.reference = reference;
            this.stamp = stamp;
        }
        static <T> Pair<T> of(T reference, int stamp) {
            return new Pair<T>(reference, stamp);
        }
    }
```
AtomicStampedReference 的内部类 Pair, reference 维护对象的引用，stamp 维护修改的版本号。

```java
    public boolean compareAndSet(V   expectedReference,
                                 V   newReference,
                                 int expectedStamp,
                                 int newStamp) {
        Pair<V> current = pair;
        return
            expectedReference == current.reference &&
            expectedStamp == current.stamp &&
            ((newReference == current.reference &&
              newStamp == current.stamp) ||
             casPair(current, Pair.of(newReference, newStamp)));
    }
```
从 compareAndSet 方法得知，如果要更改内存中的值，不但要值相同，还要版本号相同。


## 参考
* https://www.jianshu.com/p/0e312402f6ca
* https://blog.csdn.net/dlh0313/article/details/52172833
* https://www.cnblogs.com/noKing/p/9094983.html
* https://www.jianshu.com/p/fb6e91b013cc
* https://objcoding.com/2018/11/29/cas/
* https://mp.weixin.qq.com/s/nRnQKhiSUrDKu3mz3vItWg
