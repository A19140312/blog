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
* workQueue 保存等待执行的任务的阻塞队列，当提交一个新的任务到线程池以后, 线程池会根据当前线程池中正在运行着的线程的数量来决定对该任务的处理方式，主要有以下几种处理方式:
  * **使用无界队列**：一般使用基于链表的阻塞队列LinkedBlockingQueue。如果使用这种方式，那么线程池中能够创建的最大线程数就是corePoolSize，而maximumPoolSize就不会起作用了。当线程池中所有的核心线程都是RUNNING状态时，这时一个新的任务提交就会放入等待队列中。
  * **使用有界队列**：一般使用ArrayBlockingQueue。使用该方式可以将线程池的最大线程数量限制为maximumPoolSize，这样能够降低资源的消耗，但同时这种方式也使得线程池对线程的调度变得更困难，因为线程池和队列的容量都是有限的值，所以要想使线程池处理任务的吞吐率达到一个相对合理的范围，又想使线程调度相对简单，并且还要尽可能的降低线程池对资源的消耗，就需要合理的设置这两个数量。
* threadFactory 它是ThreadFactory类型的变量，用来创建新线程。默认使用Executors.defaultThreadFactory() 来创建线程。使用默认的ThreadFactory来创建线程时，会使新创建的线程具有相同的NORM_PRIORITY优先级并且是非守护线程，同时也设置了线程的名称。
* handler 它是RejectedExecutionHandler类型的变量，表示线程池的饱和策略。如果阻塞队列满了并且没有空闲的线程，这时如果继续提交任务，就需要采取一种策略处理该任务。线程池提供了4种策略：
  * AbortPolicy：直接抛出异常，这是默认策略；
  * CallerRunsPolicy：用调用者所在的线程来执行任务；
  * DiscardOldestPolicy：丢弃阻塞队列中靠最前的任务，并执行当前任务；
  * DiscardPolicy：直接丢弃任务；

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

runWorker函数中最重要的是getTask()，不断的从阻塞队列中取任务交给线程执行

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

