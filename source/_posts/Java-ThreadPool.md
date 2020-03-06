---
title: JAVA-线程池
date: 2019-10-21 17:23:04
tags:
    - JAVA
    - 线程池
    - 学习笔记
categories: JAVA
author: Guyuqing
copyright: true
comments: false
---
# 线程

#### 概念
操作系统调度的最小单元是线程，也叫轻量级进程（Light Weight Process），在一个进程里可以创建多个线程， 这些线程都拥有各自的计数器、 堆栈和局部变量等属性， 并且能够访问共享的内存变量。 处理器在这些线程上高速切换， 让使用者感觉到这些线程在同时执行。
<!-- more -->
#### 线程的创建

* 通过继承Thread类来创建一个线程
* 实现Runnable接口并重写run()方法，new Thread(runnable).start()，线程启动时就会自动调用该对象的run方法
* 实现Callable接口并实现call()方法，使用FutureTask类包装Callable对象，使用FutureTask对象作为Thread对象的targer创建并启动线程；也可以使用线程池启动
       Runnable 和 Callable 的区别
        1. Runnable规定方法是run方法，Callable规定方法是call方法
        2. Runnable任务执行后无返回值，Callable任务执行后可返回值
        3. run方法无法抛出异常，call方法可以抛出异常
        4. 运行Callable任务可以拿到一个Future对象，Future表示异步计算结果，他提供了检查计算是否完成的方法，以等待计算完成并获取结果。计算完成后用get()方法获取结果，如果线程没有执行完，get()方法会阻塞当前线程执行。如果线程出现异常，get()方法会抛出异常。
* 线程池：Executors类提供了方便的工厂方法来创建不同类型的 executor services。无论Runnable还是Callable都可以被ThreadPoolExecutor或ScheduledThreadPoolExecutor执行
      1. public static ExecutorService newCachedThreadPool() 创建一个可缓存线程池，如果线程池长度超过处理需要，可灵活回收空闲线程，若无可回收，则新建线程，但是在之前构造的线程可用时将重用它们。
      2. public static ExecutorService newFixedThreadPool(int nThreads)  创建一个定长线程池，可控制线程最大并发数，以共享的无界队列方式来运行线程，超出的线程会在队列中等待。
      3. public static ExecutorService newSingleThreadExecutor() 创建一个单线程化的线程池，它只会用唯一的工作线程来执行任务，以无界队列方式来运行线程，保证所有任务按照指定顺序(FIFO, LIFO, 优先级)执行。
      4. public static ScheduledExecutorService newScheduledThreadPool(int corePoolSize) 创建一个周期线程池，支持定时及周期性任务执行。
      5. public static ExecutorService newWorkStealingPool() 创建持有足够线程的线程池来支持给定的并行级别，并通过使用多个队列，减少竞争，它需要穿一个并行级别的参数，如果不传，则被设定为默认的CPU数量，这个线程池实际上是ForkJoinPool的扩展，适合使用在很耗时的任务中，能够合理的使用CPU进行并行操作。

#### 线程的管理
* ForkJoinPool 的每个工作线程都维护了一个工作队列(WorkQueue)，这是一个双端队列，里面存放的对象是任务(ForkJoinTask)
  * 每个工作线程在运行中产生新的任务(通常是因为调用了fork())，会放入工作队列的队尾，并且工作线程在处理自己的工作队列时，使用的是LIFO方式，也就是每次从队尾取任务执行。
  * 每个工作线程在处理自己的工作队列时，会尝试窃取一个任务(或是来自刚刚提交到pool的任务，或是来自其他的工作队列)，窃取的任务位于其他线程工作队列的队首，也就是使用FIFO方式。
  * 在遇到join()时如果join的任务尚未完成，则会先处理其他任务，并等待其完成。
* ExecutorCompletionService 内部维护了一个阻塞队列(BlockingQueue), 只有完成的任务才被加入到队列中。如果队列中的数据为空时, 调用take()就会阻塞直到有完成的任务加入队列，基于FutureTask实现。

# 线程池原理

## ThreadPoolExecutor

```java
    public ThreadPoolExecutor(int corePoolSize,
                              int maximumPoolSize,
                              long keepAliveTime,
                              TimeUnit unit,
                              BlockingQueue<Runnable> workQueue,
                              ThreadFactory threadFactory,
                              RejectedExecutionHandler handler) {
        if (corePoolSize < 0 ||
            maximumPoolSize <= 0 ||
            maximumPoolSize < corePoolSize ||
            keepAliveTime < 0)
            throw new IllegalArgumentException();
        if (workQueue == null || threadFactory == null || handler == null)
            throw new NullPointerException();
        this.acc = System.getSecurityManager() == null ?
                null :
                AccessController.getContext();
        this.corePoolSize = corePoolSize;
        this.maximumPoolSize = maximumPoolSize;
        this.workQueue = workQueue;
        this.keepAliveTime = unit.toNanos(keepAliveTime);
        this.threadFactory = threadFactory;
        this.handler = handler;
    }
```


* corePoolSize 核心线程数量，当有新任务在exectue()方法提交时，会执行以下判断：
        1. 如果运行的线程少于 corePoolSize，则创建新线程来处理任务，即使线程池中的其他线程是空闲的；
        2. 如果线程池中的线程数量大于等于 corePoolSize 且小于 maximumPoolSize，则只有当workQueue满时才创建新的线程去处理任务；
        3. 如果设置的corePoolSize 和 maximumPoolSize相同，则创建的线程池的大小是固定的，这时如果有新任务提交，若workQueue未满，则将请求放入workQueue中，等待有空闲的线程去从workQueue中取任务并处理；
        4. 如果运行的线程数量大于等于maximumPoolSize，这时如果workQueue已经满了，则通过handler所指定的策略来处理任务；
        5. 所以，任务提交时，判断的顺序为 corePoolSize –> workQueue –> maximumPoolSize
* maximumPoolSize 最大线程数量；
* keepAliveTime 线程池维护线程所允许的空闲时间。当线程池中的线程数量大于corePoolSize的时候，如果这时没有新的任务提交，核心线程外的线程不会立即销毁，而是会等待，直到等待的时间超过了keepAliveTime；
* TimeUnit 线程保持活动的时间单位
* BlockingQueue<Runnable> workQueue 保存等待执行的任务的阻塞队列，当提交一个新的任务到线程池以后, 线程池会根据当前线程池中正在运行着的线程的数量来决定对该任务的处理方式，主要有以下几种处理方式:
  * **直接切换**：这种方式常用的队列是SynchronousQueue
  * **使用无界队列**：一般使用基于链表的阻塞队列LinkedBlockingQueue。如果使用这种方式，那么线程池中能够创建的最大线程数就是corePoolSize，而maximumPoolSize就不会起作用了。当线程池中所有的核心线程都是RUNNING状态时，这时一个新的任务提交就会放入等待队列中。
  * **使用有界队列**：一般使用ArrayBlockingQueue。使用该方式可以将线程池的最大线程数量限制为maximumPoolSize，这样能够降低资源的消耗，但同时这种方式也使得线程池对线程的调度变得更困难，因为线程池和队列的容量都是有限的值，所以要想使线程池处理任务的吞吐率达到一个相对合理的范围，又想使线程调度相对简单，并且还要尽可能的降低线程池对资源的消耗，就需要合理的设置这两个数量。
* threadFactory 它是ThreadFactory类型的变量，用来创建新线程。默认使用Executors.defaultThreadFactory() 来创建线程。使用默认的ThreadFactory来创建线程时，会使新创建的线程具有相同的NORM_PRIORITY优先级并且是非守护线程，同时也设置了线程的名称。
* handler 它是RejectedExecutionHandler类型的变量，表示线程池的饱和的**拒绝策略**。如果阻塞队列满了并且没有空闲的线程，这时如果继续提交任务，就需要采取一种策略处理该任务。线程池提供了4种策略：
  * AbortPolicy：直接抛出异常，这是默认策略；
  * CallerRunsPolicy：用调用者所在的线程来执行任务；
  * DiscardOldestPolicy：丢弃阻塞队列中靠最前的任务，并执行当前任务；
  * DiscardPolicy：直接丢弃任务；

## 线程池状态
```java
    private static final int COUNT_BITS = Integer.SIZE - 3;
    private static final int CAPACITY   = (1 << COUNT_BITS) - 1;

    // runState is stored in the high-order bits
    private static final int RUNNING    = -1 << COUNT_BITS;
    private static final int SHUTDOWN   =  0 << COUNT_BITS;
    private static final int STOP       =  1 << COUNT_BITS;
    private static final int TIDYING    =  2 << COUNT_BITS;
    private static final int TERMINATED =  3 << COUNT_BITS;
```
* COUNT_BITS: 线程的最大位数29位
* CAPACITY：线程的最大容量
* RUNNING：运行状态，线程池被一旦被创建，就处于RUNNING状态，并且线程池中的任务数为0
* SHUTDOWN：线程池处在SHUTDOWN状态时，不接收新任务，但能处理已添加的任务。 
* STOP：线程池处在STOP状态时，不接收新任务，不处理已添加的任务，并且会中断正在处理的任务。
* TIDYING：当所有的任务已终止，任务数量”为0，线程池会变为TIDYING状态。当线程池变为TIDYING状态时，会执行钩子函数terminated()。
* TERMINATED：终止状态，当执行 terminated() 后会更新为这个状态。
![](Java-ThreadPool/01.png)

## 核心源码

### 线程池执行源码

#### execute
```java
    public void execute(Runnable command) {
        if (command == null)
            throw new NullPointerException();
        
        // clt记录着runState和workerCount
        int c = ctl.get();
        
        // workerCountOf方法取出低29位的值，表示当前活动的线程数；
        // 如果当前活动线程数小于corePoolSize，则新建一个线程放入线程池中，并把任务添加到该线程中；
        if (workerCountOf(c) < corePoolSize) {
            
            // addWorker中的第二个参数表示限制添加线程的数量是根据corePoolSize来判断还是maximumPoolSize来判断；
            // 如果为true，根据corePoolSize来判断；
            // 如果为false，则根据maximumPoolSize来判断
            if (addWorker(command, true))
                return;
            
            // 如果添加失败，则重新获取ctl值
            c = ctl.get();
        }
        
        // 如果当前线程池是运行状态 并且 任务能够成功添加到工作队列
        if (isRunning(c) && workQueue.offer(command)) {
            
            // 重新获取ctl值
            int recheck = ctl.get();
            
            // 再次判断线程池的运行状态，如果不是运行状态，由于之前已经把command添加到workQueue中了，
            // 这时需要移除该command
            // 执行过后通过handler使用拒绝策略对该任务进行处理，整个方法返回
            if (! isRunning(recheck) && remove(command))
                reject(command);
            
            // 获取线程池中的有效线程数，如果数量是0，则执行addWorker方法
            // 1. 第一个参数为null，表示在线程池中创建一个线程，但不去启动；
            // 2. 第二个参数为false，将线程池的有限线程数量的上限设置为maximumPoolSize，添加线程时根据maximumPoolSize来判断；
            // 如果判断workerCount大于0，则直接返回，在workQueue中新增的command会在将来的某个时刻被执行。
            else if (workerCountOf(recheck) == 0)
                addWorker(null, false);
        }
        // 如果执行到这里，有两种情况：
        // 1.线程池已经不是RUNNING状态；
        // 2.线程池是RUNNING状态，但workerCount >= corePoolSize并且workQueue已满;
        // 这时，再次调用addWorker方法，但第二个参数传入为false，将线程池的有限线程数量的上限设置为maximumPoolSize；
        // 如果失败则拒绝该任务 
        else if (!addWorker(command, false))
            reject(command);
    }

```

runState和workCount变量怎么存储在一个int中？参考：https://blog.csdn.net/weixin_34396902/article/details/94527424

#### addWorker

```java
    private boolean addWorker(Runnable firstTask, boolean core) {
        // 循环CAS操作，将线程池中的线程数+1
        retry:
        for (;;) {
            
            // clt记录着runState和workerCount
            int c = ctl.get();
            
            // 获取运行状态
            int rs = runStateOf(c);

            // 如果rs >= SHUTDOWN，则表示此时不再接收新任务；
            // 接着判断以下3个条件，只要有1个不满足，则返回false：
            // 1. rs == SHUTDOWN，这时表示关闭状态，不再接受新提交的任务，但却可以继续处理阻塞队列中已保存的任务
            // 2. firsTask为空
            // 3. 阻塞队列不为空
            //
            // rs == SHUTDOWN的情况
            // 这种情况下不会接受新提交的任务，所以在firstTask不为空的时候会返回false；
            // 如果firstTask为空，并且workQueue也为空，因为队列中已经没有任务了，不需要再添加线程了，则返回false，
            if (rs >= SHUTDOWN &&
                ! (rs == SHUTDOWN &&
                   firstTask == null &&
                   ! workQueue.isEmpty()))
                return false;

            for (;;) {
                // 获取线程数
                int wc = workerCountOf(c);
                
                // 如果wc超过CAPACITY(最大线程数线程数),也就是ctl的低29位的最大值（二进制是29个1），返回false；
                // core是addWorker方法的第二个参数,如果为true表示根据corePoolSize来比较，如果为false则根据maximumPoolSize来比较;
                if (wc >= CAPACITY ||
                    wc >= (core ? corePoolSize : maximumPoolSize))
                    return false;
                
                // CAS操作尝试增加workerCount，修改clt的值+1，如果成功，则跳出第一个for循环
                if (compareAndIncrementWorkerCount(c))
                    break retry;
                
                // 如果增加workerCount失败，则重新获取ctl的值
                c = ctl.get();  
                // 如果当前的运行状态不等于rs，说明状态已被改变，返回第一个for循环继续执行
                if (runStateOf(c) != rs)
                    continue retry;
            }
        }

        // 新建线程，并加入到线程池workers中。
        boolean workerStarted = false;
        boolean workerAdded = false;
        Worker w = null;
        try {
            // 根据firstTask来创建Worker对象
            w = new Worker(firstTask);
            
            // 每一个Worker对象都会创建一个线程
            final Thread t = w.thread;
            
            
            if (t != null) {
                // 对workers操作要通过加锁来实现
                final ReentrantLock mainLock = this.mainLock;
                mainLock.lock();
                try {
                    // 获取运行状态
                    int rs = runStateOf(ctl.get());
                    
                    // rs < SHUTDOWN表示是RUNNING状态；
                    // 如果rs是RUNNING状态或者rs是SHUTDOWN状态并且firstTask为null，向线程池中添加线程。
                    // 因为在SHUTDOWN时不会在添加新的任务，但还是会执行workQueue中的任务
                    if (rs < SHUTDOWN ||
                        (rs == SHUTDOWN && firstTask == null)) {
                        // 判断添加的任务状态,如果已经开始丢出异常
                        if (t.isAlive()) 
                            throw new IllegalThreadStateException();
                        
                        // 将新建的线程加入到线程池中，workers是一个hashSet
                        workers.add(w);
                        int s = workers.size();
                        
                        // largestPoolSize记录着线程池中出现过的最大线程数量
                        if (s > largestPoolSize)
                            largestPoolSize = s;
                        //标记任务添加
                        workerAdded = true;
                    }
                } finally {
                    mainLock.unlock();
                }
                if (workerAdded) {
                    // 启动线程
                    t.start();
                    // 标记线程启动
                    workerStarted = true;
                }
            }
        } finally {
            // 线程添加线程池失败或者线程start失败，则需要调用addWorkerFailed函数
            // 如果添加成功则需要移除线程，并恢复复clt的值
            if (! workerStarted)
                addWorkerFailed(w);
        }
        return workerStarted;
    }

```
t.start()这个语句，启动时会调用Worker类中的run方法，Worker本身实现了Runnable接口，所以一个Worker类型的对象也是一个线程。

#### Worker类

```java
    private final class Worker extends AbstractQueuedSynchronizer implements Runnable
    {

        private static final long serialVersionUID = 6138294804551838833L;

        /** 线程池中正真运行的线程。通过我们指定的线程工厂创建而来 **/
        final Thread thread;
        /** 线程包装的任务。thread 在run时主要调用了该任务的run方法 */
        Runnable firstTask;
        /** 记录当前线程完成的任务数 */
        volatile long completedTasks;

        /**
         * Creates with given first task and thread from ThreadFactory.
         * @param firstTask the first task (null if none)
         */
        Worker(Runnable firstTask) {
            setState(-1); // 在调用runWorker()前，禁止interrupt中断，在interruptIfStarted()方法中会判断 getState()>=0
            this.firstTask = firstTask;
            // 利用我们指定的线程工厂创建一个线程
            this.thread = getThreadFactory().newThread(this);
        }

        /** Delegates main run loop to outer runWorker  */
        public void run() {
            runWorker(this);
        }

        // Lock methods
        //
        // The value 0 represents the unlocked state.
        // The value 1 represents the locked state.

        protected boolean isHeldExclusively() {
            return getState() != 0;
        }

        /**
        * 尝试获取锁
        */
        protected boolean tryAcquire(int unused) {
            //尝试一次将state从0设置为1，即“锁定”状态，
            if (compareAndSetState(0, 1)) {
                //设置exclusiveOwnerThread=当前线程
                setExclusiveOwnerThread(Thread.currentThread());
                return true;
            }
            return false;
        }

        /**
        * 尝试释放锁
        */
        protected boolean tryRelease(int unused) {
            setExclusiveOwnerThread(null);
            setState(0);
            return true;
        }

        public void lock()        { acquire(1); }
        public boolean tryLock()  { return tryAcquire(1); }
        public void unlock()      { release(1); }
        public boolean isLocked() { return isHeldExclusively(); }


        /**
        * 中断（如果运行）
        * shutdownNow时会循环对worker线程执行
        * 且不需要获取worker锁，即使在worker运行时也可以中断
        */
        void interruptIfStarted() {
            Thread t;
            // 如果state>=0、t!=null、且t没有被中断
            // new Worker()时state==-1，说明不能中断
            if (getState() >= 0 && (t = thread) != null && !t.isInterrupted()) {
                try {
                    t.interrupt();
                } catch (SecurityException ignore) {
                }
            }
        }
    }
```

Worker类投机取巧的继承了AbstractQueuedSynchronizer来简化在执行任务时的获取、释放锁,这样防止了中断在运行中的任务，只会唤醒(中断)在等待从workQueue中获取任务的线程.
不直接执行execute(command)提交的command，而要在外面包一层Worker主要是为了使用用AQS锁控制中断，当运行时上锁，就不能中断，TreadPoolExecutor的shutdown()方法中断前都要获取worker锁，只有在等待从workQueue中获取任务getTask()时才能中断。

#### runWorker 方法

在Worker类中的run方法调用了runWorker方法来执行任务.

```java

    final void runWorker(Worker w) {
        Thread wt = Thread.currentThread();
        
        // 获取第一个任务
        Runnable task = w.firstTask;
        w.firstTask = null;
        w.unlock(); // 允许中断
        
         // 是否因为异常退出循环
        boolean completedAbruptly = true;
        try {
            
            // 如果task为空，则通过getTask来获取任务
            while (task != null || (task = getTask()) != null) {
                w.lock();
                // If pool is stopping, ensure thread is interrupted;
                // if not, ensure thread is not interrupted.  This
                // requires a recheck in second case to deal with
                // shutdownNow race while clearing interrupt
                // 线程池处于stop状态或者当前线程被中断时，线程池状态是stop状态
                // 但是当前线程没有中断，则发出中断请求
                if ((runStateAtLeast(ctl.get(), STOP) ||
                     (Thread.interrupted() &&
                      runStateAtLeast(ctl.get(), STOP))) &&
                    !wt.isInterrupted())
                    wt.interrupt();
                try {
                    //开始执行任务前的Hook，类似回调函数
                    beforeExecute(wt, task);
                    Throwable thrown = null;
                    try {
                        //执行任务
                        task.run();
                    } catch (RuntimeException x) {
                        thrown = x; throw x;
                    } catch (Error x) {
                        thrown = x; throw x;
                    } catch (Throwable x) {
                        thrown = x; throw new Error(x);
                    } finally {
                        //任务执行后的Hook，类似回调函数
                        afterExecute(task, thrown);
                    }
                } finally {
                    //执行完毕后task重置，completedTasks计数器++，解锁
                    task = null;
                    w.completedTasks++;
                    w.unlock();
                }
            }
            //标记正常退出
            completedAbruptly = false;
        } finally {
            //线程空闲达到我们设定的值时，Worker退出销毁。
            processWorkerExit(w, completedAbruptly);
        }
    }

```
#### getTask 方法

runWorker函数中最重要的是getTask()，不断的从阻塞队列中取任务交给线程执行，并且负责线程回收

```java
    private Runnable getTask() {
        // 表示上次从阻塞队列中取任务时是否超时
        boolean timedOut = false; // Did the last poll() time out?

        for (;;) {
            int c = ctl.get();
            int rs = runStateOf(c);

            // 如果线程池处于shutdown状态，
            // 并且队列为空，或者线程池处于stop或者terminate状态，
            // 在线程池数量-1，返回null，回收线程
            if (rs >= SHUTDOWN && (rs >= STOP || workQueue.isEmpty())) {
                decrementWorkerCount();
                return null;
            }

            // 获取线程数
            int wc = workerCountOf(c);

            // timed变量用于判断是否需要进行超时控制。
            // allowCoreThreadTimeOut默认是false，也就是核心线程不允许进行超时；
            // wc > corePoolSize，表示当前线程池中的线程数量大于核心线程数量；
            // 对于超过核心线程数量的这些线程，需要进行超时控制
            boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;

            // 如果线程数目大于最大线程数目 或 当前操作需要进行超时控制，并且上次从阻塞队列中获取任务发生了超时
            // 并且 线程数目大于1 或 工作队列为空
            // 尝试将workerCount减1；
            if ((wc > maximumPoolSize || (timed && timedOut))
                && (wc > 1 || workQueue.isEmpty())) {
                if (compareAndDecrementWorkerCount(c))
                    return null;
                continue;
            }

            try {
                //**保证核心线程不被销毁**
                // 根据timed来判断，如果为true，则通过阻塞队列的poll方法进行超时控制，如果在keepAliveTime时间内没有获取到任务，则返回null；
                // 否则通过take方法，如果这时队列为空，则take方法会阻塞直到队列不为空。
                Runnable r = timed ?
                    workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) :
                    workQueue.take();
                if (r != null)
                    return r;
                
                // 如果 r == null，说明已经超时，timedOut设置为true，进入下一个循环
                timedOut = true;
            } catch (InterruptedException retry) {
                // 如果获取任务时当前线程发生了中断，则设置timedOut为false并返回循环重试
                timedOut = false;
            }
        }
    }
```
### FutureTask源码

```java

public class FutureTask<V> implements RunnableFuture<V> {

    /**
     * state字段用来保存FutureTask内部的任务执行状态，一共有7中状态，每种状态及其对应的值如下
     * NEW:表示是个新的任务或者还没被执行完的任务。这是初始状态。
     * COMPLETING:任务已经执行完成或者执行任务的时候发生异常，但是任务执行结果或者异常原因还没有保存到outcome字段(outcome字段用来保存任务执行结果，如果发生异常，则用来保存异常原因)的时候，状态会从NEW变更到COMPLETING。但是这个状态会时间会比较短，属于中间状态。
     * NORMAL:任务已经执行完成并且任务执行结果已经保存到outcome字段，状态会从COMPLETING转换到NORMAL。这是一个最终态。
     * EXCEPTIONAL:任务执行发生异常并且异常原因已经保存到outcome字段中后，状态会从COMPLETING转换到EXCEPTIONAL。这是一个最终态。
     * CANCELLED:任务还没开始执行或者已经开始执行但是还没有执行完成的时候，用户调用了cancel(false)方法取消任务且不中断任务执行线程，这个时候状态会从NEW转化为CANCELLED状态。这是一个最终态。
     * INTERRUPTING: 任务还没开始执行或者已经执行但是还没有执行完成的时候，用户调用了cancel(true)方法取消任务并且要中断任务执行线程但是还没有中断任务执行线程之前，状态会从NEW转化为INTERRUPTING。这是一个中间状态。
     * INTERRUPTED:调用interrupt()中断任务执行线程之后状态会从INTERRUPTING转换到INTERRUPTED。这是一个最终态。
     * 
     * NEW -> COMPLETING -> NORMAL 正常执行并返回
     * NEW -> COMPLETING -> EXCEPTIONAL 执行过程中出现了异常
     * NEW -> CANCELLED 执行前被取消
     * NEW -> INTERRUPTING -> INTERRUPTED 取消时被中断
     */
    private volatile int state;
    private static final int NEW          = 0;
    private static final int COMPLETING   = 1;//大于这个值就是完成状态
    private static final int NORMAL       = 2;
    private static final int EXCEPTIONAL  = 3;
    private static final int CANCELLED    = 4;
    private static final int INTERRUPTING = 5;
    private static final int INTERRUPTED  = 6;

    /** The underlying callable; nulled out after running */
    private Callable<V> callable;
    /** The result to return or exception to throw from get() */
    private Object outcome; // non-volatile, protected by state reads/writes
    /** 执行callable的线程 **/
    private volatile Thread runner;
    /** 使用Treiber算法实现的无阻塞的Stack，用于存放等待的线程 */
    private volatile WaitNode waiters;

    @SuppressWarnings("unchecked")
    private V report(int s) throws ExecutionException {
        // 拿到返回结果
        Object x = outcome;
        // 判断状态
        if (s == NORMAL)
            // 状态正常，就返回结果值
            return (V)x;
        // 判断异常，就抛出异常。
        if (s >= CANCELLED)
            throw new CancellationException();
        throw new ExecutionException((Throwable)x);
    }

    /**
     * 构造方法
     */
    public FutureTask(Callable<V> callable) {
        if (callable == null)
            throw new NullPointerException();
        this.callable = callable;
        this.state = NEW;       // ensure visibility of callable
    }

    /**
     * 这个构造方法会把传入的Runnable封装成一个Callable对象保存在callable字段中，同时如果任务执行成功的话就会返回传入的result。
     * 这种情况下如果不需要返回值的话可以传入一个null。
     */
    public FutureTask(Runnable runnable, V result) {
        this.callable = Executors.callable(runnable, result);
        this.state = NEW;       // ensure visibility of callable
    }

    //判断任务是否被取消
    public boolean isCancelled() {
        return state >= CANCELLED;
    }
    //判断任务是否完成
    public boolean isDone() {
        return state != NEW;
    }

    public boolean cancel(boolean mayInterruptIfRunning) {
        // 1. 任务是new状态 并且 根据mayInterruptIfRunning把状态从NEW转化到INTERRUPTING或CANCELLED 
        // 不符合上述状态，返回false
        if (!(state == NEW &&
              UNSAFE.compareAndSwapInt(this, stateOffset, NEW,
                  mayInterruptIfRunning ? INTERRUPTING : CANCELLED)))
            return false;
        try {    
        // 2. 如果需要中断任务执行线程
            if (mayInterruptIfRunning) {
                try {
                    // runner保存着当前执行任务的线程
                    Thread t = runner;
                    if (t != null)
                        //中断任务执行线程
                        t.interrupt();
                } finally { // final state
                    // 修改状态为INTERRUPTED
                    UNSAFE.putOrderedInt(this, stateOffset, INTERRUPTED);
                }
            }
        } finally {
            finishCompletion();
        }
        return true;
    }


    public V get() throws InterruptedException, ExecutionException {
        int s = state;
        // 判断任务当前的state <= COMPLETING是否成立。
        if (s <= COMPLETING)
            // 如果成立，表明任务还没有结束(这里的结束包括任务正常执行完毕，任务执行异常，任务被取消)
            // 调用awaitDone()进行阻塞等待。
            s = awaitDone(false, 0L);
        // 任务已经结束，调用report()返回结果。
        return report(s);
    }


    public V get(long timeout, TimeUnit unit)
        throws InterruptedException, ExecutionException, TimeoutException {
        if (unit == null)
            throw new NullPointerException();
        int s = state;
        // 如果awaitDone()超时返回之后任务还没结束，则抛出异常
        if (s <= COMPLETING &&
            (s = awaitDone(true, unit.toNanos(timeout))) <= COMPLETING)
            throw new TimeoutException();
        return report(s);
    }


    protected void done() { }


    protected void set(V v) {
        // 尝试CAS操作，把当前的状态从NEW变更为COMPLETING(中间状态)状态。
        if (UNSAFE.compareAndSwapInt(this, stateOffset, NEW, COMPLETING)) {
            // 把任务执行结果保存在outcome字段中。
            outcome = v;
            // CAS的把当前任务状态从COMPLETING变更为NORMAL
            UNSAFE.putOrderedInt(this, stateOffset, NORMAL); // final state
            finishCompletion();
        }
    }


    protected void setException(Throwable t) {
        // 尝试CAS操作，把当前的状态从NEW变更为COMPLETING(中间状态)状态。
        if (UNSAFE.compareAndSwapInt(this, stateOffset, NEW, COMPLETING)) {
            // 把异常原因保存在outcome字段中，outcome字段用来保存任务执行结果或者异常原因。
            outcome = t;
            // CAS的把当前任务状态从COMPLETING变更为EXCEPTIONAL。
            UNSAFE.putOrderedInt(this, stateOffset, EXCEPTIONAL); // final state
            finishCompletion();
        }
    }


    public void run() {
        // 状态如果不是NEW，说明任务或者已经执行过，或者已经被取消，直接返回
        // 状态如果是NEW，则尝试把当前执行线程保存在runner字段(runnerOffset)中，如果赋值失败则直接返回
        if (state != NEW ||
            !UNSAFE.compareAndSwapObject(this, runnerOffset,
                                         null, Thread.currentThread()))
            return;
        try {
            Callable<V> c = callable;
            // 只有初始状态才会执行
            if (c != null && state == NEW) {
                V result;
                boolean ran;
                try {
                    // 执行任务  计算逻辑
                    result = c.call();
                    ran = true;
                } catch (Throwable ex) {
                    result = null;
                    ran = false;
                    // 保存异常
                    setException(ex);
                }
                if (ran)
                    // 任务执行成功，保存返回结果
                    set(result);
            }
        } finally {
            // 无论是否执行成功，把runner设置为null
            runner = null;
            // state must be re-read after nulling runner to prevent
            // leaked interrupts
            int s = state;
            // 如果任务被中断，执行中断处理
            if (s >= INTERRUPTING)
                handlePossibleCancellationInterrupt(s);
        }
    }

    /**
     * 与run方法类似，区别在于这个方法不会设置任务的执行结果值
     *
     * @return {@code true} if successfully run and reset
     */
    protected boolean runAndReset() {
        if (state != NEW ||
            !UNSAFE.compareAndSwapObject(this, runnerOffset,
                                         null, Thread.currentThread()))
            return false;
        boolean ran = false;
        int s = state;
        try {
            Callable<V> c = callable;
            if (c != null && s == NEW) {
                try {
                    // 不获取和设置返回值
                    c.call(); // don't set result
                    ran = true;
                } catch (Throwable ex) {
                    setException(ex);
                }
            }
        } finally {

            runner = null;
            s = state;
            if (s >= INTERRUPTING)
                handlePossibleCancellationInterrupt(s);
        }
        // 是否正确的执行并复位
        return ran && s == NEW;
    }


    private void handlePossibleCancellationInterrupt(int s) {
        if (s == INTERRUPTING)
            while (state == INTERRUPTING)
                Thread.yield(); // wait out pending interrupt

        // 确保cancel(true)产生的中断发生在run或runAndReset方法执行的过程中。
        //这里会循环的调用Thread.yield()来确保状态在cancel方法中被设置为INTERRUPTED。
    }

    /**
     * Simple linked list nodes to record waiting threads in a Treiber
     * stack.  See other classes such as Phaser and SynchronousQueue
     * for more detailed explanation.
     */
    static final class WaitNode {
        volatile Thread thread;
        volatile WaitNode next;
        WaitNode() { thread = Thread.currentThread(); }
    }

    /**
     * Removes and signals all waiting threads, invokes done(), and
     * nulls out callable.
     */
    private void finishCompletion() {
        // assert state > COMPLETING;
        // 执行该方法时state必须大于COMPLETING
        // 依次遍历waiters链表
        for (WaitNode q; (q = waiters) != null;) {
            // 设置栈顶节点为null
            if (UNSAFE.compareAndSwapObject(this, waitersOffset, q, null)) {
                for (;;) {
                    Thread t = q.thread;
                    if (t != null) {
                        q.thread = null;
                        // 唤醒等待线程
                        LockSupport.unpark(t);
                    }
                    WaitNode next = q.next;
                    // 如果next为空，说明栈空了，跳出循环
                    if (next == null)
                        break;
                    // 方便gc回收
                    q.next = null; 
                    // 重新设置栈顶node
                    q = next;
                }
                break;
            }
        }
        // 空方法，留给子类扩展
        done();

        callable = null;        // to reduce footprint
    }

    /**
     * Awaits completion or aborts on interrupt or timeout.
     *
     * @param timed true if use timed waits
     * @param nanos time to wait, if timed
     * @return state upon completion
     */
    private int awaitDone(boolean timed, long nanos)
        throws InterruptedException {
        // 计算等待截止时间
        final long deadline = timed ? System.nanoTime() + nanos : 0L;
        WaitNode q = null;
        boolean queued = false;
        for (;;) {
            // 1. 判断阻塞线程是否被中断
            if (Thread.interrupted()) {
                // 被中断则在等待队列中删除该节点
                removeWaiter(q);
                // 抛出InterruptedException异常
                throw new InterruptedException();
            }

            int s = state;
            // 2. 获取当前状态，如果状态大于COMPLETING
            if (s > COMPLETING) {
                // 说明任务已经结束(要么正常结束，要么异常结束，要么被取消)
                if (q != null)
                    // 把thread显示置空
                    q.thread = null;
                // 返回结果
                return s;
            }
            // 3. 如果状态处于中间状态COMPLETING
            // 表示任务已经结束但是任务执行线程还没来得及给outcome赋值
            else if (s == COMPLETING) // cannot time out yet
                Thread.yield();// 让出执行权让其他线程优先执行
            // 4. 如果等待节点为空，则构造一个等待节点
            else if (q == null)
                q = new WaitNode();
            // 5. 如果还没有入队列，则把当前节点加入waiters首节点并替换原来waiters
            else if (!queued)
                queued = UNSAFE.compareAndSwapObject(this, waitersOffset,
                                                     q.next = waiters, q);
            else if (timed) {
                // 如果需要等待特定时间，则先计算要等待的时间
                // 如果已经超时，则删除对应节点并返回对应的状态
                nanos = deadline - System.nanoTime();
                if (nanos <= 0L) {
                    removeWaiter(q);
                    return state;
                }
                // 6. 阻塞等待特定时间
                LockSupport.parkNanos(this, nanos);
            }
            // 6. 阻塞等待直到被其他线程唤醒
            else
                LockSupport.park(this);
        }
    }


    private void removeWaiter(WaitNode node) {
        if (node != null) {
            // 将thread设置为null是因为下面要根据thread是否为null判断是否要把node移出
            node.thread = null;
            // 这里自旋保证删除成功
            retry:
            for (;;) {          // restart on removeWaiter race
                for (WaitNode pred = null, q = waiters, s; q != null; q = s) {
                    s = q.next;
                    // q.thread != null说明该q节点不需要移除
                    if (q.thread != null)
                        pred = q;
                    // 如果q.thread == null，且pred != null，需要删除q节点
                    else if (pred != null) {
                        // 删除q节点
                        pred.next = s;
                         // pred.thread == null时说明在并发情况下被其他线程修改了；
                         // 返回第一个for循环重试
                        if (pred.thread == null) // check for race
                            continue retry;
                    }
                     // 如果q.thread != null且pred == null，说明q是栈顶节点
                     // 设置栈顶元素为s节点，如果失败则返回重试
                    else if (!UNSAFE.compareAndSwapObject(this, waitersOffset,
                                                          q, s))
                        continue retry;
                }
                break;
            }
        }
    }

    // Unsafe mechanics
    private static final sun.misc.Unsafe UNSAFE;
    private static final long stateOffset;
    private static final long runnerOffset;
    private static final long waitersOffset;
    static {
        try {
            UNSAFE = sun.misc.Unsafe.getUnsafe();
            Class<?> k = FutureTask.class;
            stateOffset = UNSAFE.objectFieldOffset
                (k.getDeclaredField("state"));
            runnerOffset = UNSAFE.objectFieldOffset
                (k.getDeclaredField("runner"));
            waitersOffset = UNSAFE.objectFieldOffset
                (k.getDeclaredField("waiters"));
        } catch (Exception e) {
            throw new Error(e);
        }
    }

}

```
## 线程池中的线程初始化

　　默认情况下，创建线程池之后，线程池中是没有线程的，需要提交任务之后才会创建线程。在实际中如果需要线程池创建之后立即创建线程，可以通过以下两个方法办到：
* prestartCoreThread()：初始化一个核心线程；
* prestartAllCoreThreads()：初始化所有核心线程

## 线程池的关闭
ThreadPoolExecutor提供了两个方法，用于线程池的关闭
* shutdown()：不会立即终止线程池，而是要等所有任务缓存队列中的任务都执行完后才终止，但再也不会接受新的任务
* shutdownNow()：立即终止线程池，并尝试打断正在执行的任务，并且清空任务缓存队列，返回尚未执行的任务

## 线程池大小
1. 粗略
    1. 如果是CPU密集型任务，就需要尽量压榨CPU，参考值可以设为 NCPU+1
    2. 如果是IO密集型任务，参考值可以设置为2*NCPU
2. 精确：（(线程等待时间+线程CPU时间）/线程CPU时间 ）* CPU数目
3. 最佳：压测

## 任务缓存队列

**workQueue**，它用来存放等待执行的任务。BlockingQueue 是个接口，你需要使用它的实现之一来使用BlockingQueue，java.util.concurrent包下具有以下 BlockingQueue 接口的实现类：
* ArrayBlockingQueue：ArrayBlockingQueue 是一个有界的阻塞队列，其内部实现是将对象放到一个数组里。有界也就意味着，它不能够存储无限多数量的元素。它有一个同一时间能够存储元素数量的上限。你可以在对其初始化的时候设定这个上限，但之后就无法对这个上限进行修改了(译者注：因为它是基于数组实现的，也就具有数组的特性：一旦初始化，大小就无法修改)。
* LinkedBlockingQueue：LinkedBlockingQueue 内部以一个链式结构(链接节点)对其元素进行存储。如果需要的话，这一链式结构可以选择一个上限。如果没有定义上限，将使用 Integer.MAX_VALUE 作为上限。
* DelayQueue：DelayQueue 对元素进行持有直到一个特定的延迟到期。注入其中的元素必须实现 java.util.concurrent.Delayed 接口。
* PriorityBlockingQueue：PriorityBlockingQueue 是一个无界的并发队列。它使用了和类 java.util.PriorityQueue 一样的排序规则。你无法向这个队列中插入 null 值。所有插入到 PriorityBlockingQueue 的元素必须实现 java.lang.Comparable 接口。因此该队列中元素的排序就取决于你自己的 Comparable 实现。
* SynchronousQueue：SynchronousQueue 是一个特殊的队列，它的内部同时只能够容纳单个元素。如果该队列已有一元素的话，试图向队列中插入一个新元素的线程将会阻塞，直到另一个线程将该元素从队列中抽走。同样，如果该队列为空，试图向队列中抽取一个元素的线程将会阻塞，直到另一个线程向队列中插入了一条新的元素。据此，把这个类称作一个队列显然是夸大其词了。它更多像是一个汇合点。


## 线程池总结
1. 线程池刚创建时，里面没有一个线程。任务队列是作为参数传进来的。不过，就算队列里面有任务，线程池也不会马上执行它们。
2. 当调用 execute() 方法添加一个任务时，线程池会做如下判断：
     1. 如果正在运行的线程数量小于 corePoolSize，那么马上创建线程运行这个任务；
     2. 如果正在运行的线程数量大于或等于 corePoolSize，那么将这个任务放入队列；
     3. 如果这时候队列满了，而且正在运行的线程数量小于 maximumPoolSize，那么还是要创建非核心线程立刻运行这个任务；
     4. 如果队列满了，而且正在运行的线程数量大于或等于 maximumPoolSize，那么线程池会抛出异常RejectExecutionException。
     5. 当一个线程完成任务时，它会从队列中取下一个任务来执行。
     6. 当一个线程无事可做，超过一定的时间（keepAliveTime）时，线程池会判断，如果当前运行的线程数大于 corePoolSize，那么这个线程就被停掉。所以线程池的所有任务完成后，它最终会收缩到 corePoolSize 的大小。

