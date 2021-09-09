
# 进程和线程


### 线程定义

线程是进程的基本执行单元,一个进程的所有任务都是在线程中执行,
进程至少有一条线程
程序启动会默认开始一条线程,这条线程被称为主线程或UI线程

### 进程定义

进程是指在系统中正在运行的一个应用程序
每个进程之间是独立的,
每个进程均运行在其专用的且受保护的内存中

进程与线程的区别:

- 调度：线程作为CPU调度和分配的基本单位，进程作为分配资源的基本单位
- 并发性：进程之间可以并发，线程之间也可以并发
- 资源拥有：进程是拥有资源的基本单位，线程不拥有资源，但是可以访问隶属于进程内的资源
- 系统开销：在创建和销毁进程时，系统都需要为之分配和回收资源，导致系统的开销明显大于创建和撤销线程的开销
- 一个进程崩溃后,在保护模式下不会对其他进程产生影响,但是一个线程崩溃整个进程都死掉.所以多进程要比多线程健壮.

# 谈谈对多线程开发的理解。iOS 多线程

### 优点：

- 能适当提高程序的执行效率
- 能适当提高资源利用率（CPU、内存利用率）能适当提高效率，比如在一些等待的任务实现上如用户输入、文件读写和网络收发数据等,线程就比较有用了。

### 缺点：

- 创建线程会消耗内存资源，创建一条线程大约需要90毫秒；创建线程太多会降低程序性能，大量消耗CPU
- 线程越多，CPU在调度线程上的开销就越大
- 线程的中止需要考虑其对程序运行的影响。
- 程序设计更加复杂：比如线程之间的通信、多线程的数据共享,共享数据时需要防止线程死锁情况的发生。

### OS中实现多线程的几种方案，各自有什么特点？

![iOS多线程](https://upload-images.jianshu.io/upload_images/1846524-cf7b835865f8c5f0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

NSThread 面向对象的，需要程序员手动创建线程，但不需要手动销毁。子线程间通信很难。

GCD c语言，充分利用了设备的多核，自动管理线程生命周期。比NSOperation效率更高。

NSOperation 基于gcd封装，更加面向对象，比gcd多了一些功能。

### 多线程的 `并行` 和 `并发` 有什么区别？

并行：并行是指多个处理器或者是多核的处理器同时处理多个不同的任务。 
并发：并发是指一个处理器同时处理多个任务。在线程间通过快速切换，让人感觉在同步进行

### 多线程的 `同步` 和 `异步` 有什么区别？

同步：只能在当前线程中执行任务，不具备开启新线程的能力
异步：可以在新的线程中执行任务，具备开启新线程的能力

### 队列的 `串行` 和 `并发` 有什么区别？

并发队列（ConcurrentDispatch Queue）
可以让多个任务并发（同时）执行（自动开启多个线程同时执行任务）
并发功能只有在异步（dispatch_async）函数下才有效

串行队列（SerialDispatch Queue）
让任务一个接着一个地执行（一个任务执行完毕后，再执行下一个任务）


### 总结： 串行队列一次只能派发一个任务，等上个任务执行完成之后才去派发另外一个任务，并发队列可以同时派发多个任务 
派发的任务是如何执行的 和队列没有半毛钱关系。如果派发的任务是都同步任务，那么不管你是串行队列还是并发队列，所有任务都 是一个接一个执行，如果是异步任务，这个关系就区别出来了


##### 队列和同步、异步之间的关系

![同步和异步](https://upload-images.jianshu.io/upload_images/1846524-64c994e1bef068cf.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


## ios 线程间通信方式

通信方式

主要包括传统的可用于线程间通信的进程间通信方式，Mach内核核心mach port，NSObject对象、GCD及操作队列等方式。

### 传统方式

- 管道
- 套接字
- 共享内存

### iOS

- 共享存储
- Mach Port
- NSObject
 
 ```python
 //主线程
 - (void)performSelectorOnMainThread:(SEL)aSelector withObject:(nullable id)arg waitUntilDone:(BOOL)wait modes:(nullable NSArray<NSString *> *)array;
 - (void)performSelectorOnMainThread:(SEL)aSelector withObject:(nullable id)arg waitUntilDone:(BOOL)wait;
 //指定线程
 - (void)performSelector:(SEL)aSelector onThread:(NSThread *)thr withObject:(nullable id)arg waitUntilDone:(BOOL)wait modes:(nullable NSArray<NSString *> *)array;
 - (void)performSelector:(SEL)aSelector onThread:(NSThread *)thr withObject:(nullable id)arg waitUntilDone:(BOOL)wait;
```
 
 - GCD  (指的回到主线程)
 - NSOperation(指的回到主线程)

# 几个多线程案例

### iOS多个网络请求完成后执行下一步

> 1、使用GCD的DispatchGroup。每次网络请求前先enter，请求回调后再leave，enter和leave必须配合使用，有几次enter就要有几次leave，否则group会一直存在。

当所有enter的block都leave后，会执行notify的block。

```python
let group = DispatchGroup()
group.enter()
DispatchQueue.global().async {
    print("线程1执行结束")
    group.leave()
}
group.enter()
DispatchQueue.global().async {
    print("线程2执行结束")
    group.leave()
}
group.notify(queue: .main) {
    print("两个线程全部执行结束")
}
```
> 1、使用GCD的信号量DispatchSemaphore

DispatchSemaphore信号量为基于计数器的一种多线程同步机制。如果semaphore计数大于等于1，计数-1，返回，程序继续运行。如果计数为0，则等待。dispatch_semaphore_signal(semaphore)为计数+1操作,dispatch_semaphore_wait为设置等待时间，这里设置的等待时间是一直等待。创建semaphore为0，等待，等10个网络请求都完成了，dispatch_semaphore_signal(semaphore)为计数+1，然后计数-1返回

```python
//初始化信号量为1
let semaphore = DispatchSemaphore(value: 0)

var count = 0
DispatchQueue.global().async() {
    count += 1
    print("线程1执行结束")
    if count == 2 {
        semaphore.signal()
    }
}

DispatchQueue.global().async() {
    count += 1
    print("线程2执行结束")
    if count == 2 {
        semaphore.signal()
    }
}

_ = semaphore.wait(timeout: .distantFuture)
DispatchQueue.global().async() {
    print("两个线程执行结束")
}

```
### 异步操作两组数据时, 执行完第一组之后, 才能执行第二组

```
let queue = DispatchQueue(label: "name", qos: .default, attributes: .concurrent, autoreleaseFrequency: .never, target: nil)
queue.async {
    print("-----A")
}
queue.async {
    print("-----B")
}
queue.async(flags: .barrier) {
    print("-----C")
}
queue.async {
    print("-----D")
}
queue.async {
    print("-----E")
}
```



## GCD执行原理？
- GCD有一个底层线程池，这个池中存放的是一个个的线程。之所以称为“池”，很容易理解出这个“池”中的线程是可以重用的，当一段时间后这个线程没有被调用胡话，这个线程就会被销毁。注意：开多少条线程是由底层线程池决定的（线程建议控制再3~5条），池是系统自动来维护，不需要我们程序员来维护（看到这句话是不是很开心？） 而我们程序员需要关心的是什么呢？我们只关心的是向队列中添加任务，队列调度即可。

- 如果队列中存放的是同步任务，则任务出队后，底层线程池中会提供一条线程供这个任务执行，任务执行完毕后这条线程再回到线程池。这样队列中的任务反复调度，因为是同步的，所以当我们用currentThread打印的时候，就是同一条线程。

- 如果队列中存放的是异步的任务，（注意异步可以开线程），当任务出队后，底层线程池会提供一个线程供任务执行，因为是异步执行，队列中的任务不需等待当前任务执行完毕就可以调度下一个任务，这时底层线程池中会再次提供一个线程供第二个任务执行，执行完毕后再回到底层线程池中。

- 这样就对线程完成一个复用，而不需要每一个任务执行都开启新的线程，也就从而节约的系统的开销，提高了效率。在iOS7.0的时候，使用GCD系统通常只能开5~8条线程，iOS8.0以后，系统可以开启很多条线程，但是实在开发应用中，建议开启线程条数：3~5条最为合理



