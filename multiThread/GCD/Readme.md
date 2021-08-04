
# GCD

## 1. GCD 简介

    Grand Central Dispatch（GCD） 是 Apple 开发的一个多核编程的较新的解决方法。它主要用于优化应用程序以支持多核处理器以及其他对称多处理系统。
    它是一个在线程池模式的基础上执行的并发任务。在 Mac OS X 10.6 雪豹中首次推出，也可在 iOS 4 及以上版本使用。

### 1.1、 GCD优势：

GCD 可用于多核的并行运算；
GCD 会自动利用更多的 CPU 内核（比如双核、四核）；
GCD 会自动管理线程的生命周期（创建线程、调度任务、销毁线程）；
程序员只需要告诉 GCD 想要执行什么任务，不需要编写任何线程管理代码。
GCD 拥有以上这么多的好处，而且在多线程中处于举足轻重的地位。那么我们就很有必要系统地学习一下 GCD 的使用方法。

### 1.2、GCD 任务和队列


- 『任务』：就是执行操作的意思，换句话说就是你在线程中执行的那段代码。在 GCD 中是放在 block 中的。执行任务有两种方式， 
    两者的主要区别是：是否等待队列的任务执行结束
    - 『同步任务』：同步添加任务到指定的队列中，在添加的任务执行结束之前，会一直等待，直到队列里面的任务完成之后再继续执行。
    - 『异步任务』：如果队列支持开多个线程，那么它会在其它线程中执行任务，不用等待当前线程执行结束

- 『队列』: 这里的队列指执行任务的等待队列，即用来存放任务的队列。队列是一种特殊的线性表，采用 FIFO（先进先出）的原则，即新任务总是被插入到队列的末尾，而读取任务的时候总是从队列的头部开始读取。每读取一个任务，则从队列中释放一个
    
    - 『串行队列』：每次只有一个任务被执行。让任务一个接着一个地执行。（只开启一个线程，一个任务执行完毕后，再执行下一个任务）
    - 『并发队列』：可以让多个任务并发（同时）执行。（可以开启多个线程，并且同时执行任务）


`任务`和`队列`的关系：
`任务`指的是需不需要开启线程
`队列`指的是有没有开启多线程的能力

### 1.3、队列和任务的组合情况

![Picture1.png](https://upload-images.jianshu.io/upload_images/1846524-2ccec9b142ac1ce0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 2. GCD 死锁


## 2.1、串行主队列+同步任务

主队列
```ruby
- (void)deadLock1 {
    NSLog(@"任务1");
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_sync(queue, ^{
        NSLog(@"任务2");
    });
    NSLog(@"任务3");
}

解决：开启异步任务
```
串行队列

```ruby

- (void)deadLock2 {
    NSLog(@"任务1");
    dispatch_queue_t queue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        NSLog(@"任务2");
        dispatch_sync(queue, ^{
            NSLog(@"任务3");
        });
    });
}

解决：同步任务在其它队列执行或开启异步任务或开启并发队列
```


## 3、 GCD 面试题


```ruby

- (void)interview {
    dispatch_queue_t queue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        NSLog(@"任务1");
        [self performSelector:@selector(selectorMethod) withObject:nil afterDelay:0];
        NSLog(@"任务3");
    });
}


- (void)selectorMethod {
    NSLog(@"任务2");
}

结果： 1 3

解：performSelector: withObject:nil afterDelay: 和定时器有关，定时器会加在runloop里面，由于dispatch_async内部没有开启runloop所以2不会打印

```

```ruby

- (void)selectorMethod {
    NSLog(@"任务2");
}

- (void)interview2 {
    NSThread *thread = [[NSThread alloc] initWithBlock:^{
        NSLog(@"任务1");
    }];
    [thread start];
    
    [self performSelector:@selector(selectorMethod) onThread:thread withObject:nil waitUntilDone:YES];
}
结果： 1 同时崩溃

打印1 是因为没有开启runloop, 崩溃是因为thread被释放

如果将YES 改为NO，就不会产生崩溃


```

### 3.1、 GCD 队列组`dispatch_group`


```ruby

- (void)groupNotify {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"group---begin");
    
    dispatch_group_t group =  dispatch_group_create();
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
        NSLog(@"group---end");
    });
}

打印结果： 1或2 然后打印3
```

### 3.2、 GCD 栅栏方法`dispatch_barrier_async` 和 `dispatch_barrier_async`

`dispatch_barrier_async` 只隔离异步任务，
`dispatch_barrier_async`只隔离同步任务

```ruby
- (void)barrierAsync {
    dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        NSLog(@"任务1");
    });
    dispatch_async(queue, ^{
        NSLog(@"任务2");
    });
    
    dispatch_barrier_async(queue, ^{
        NSLog(@"任务3");
    });
    
    dispatch_async(queue, ^{
        NSLog(@"任务4");
    });
    dispatch_async(queue, ^{
        NSLog(@"任务5");
    });
}

打印结果： （1，2），3 （4， 5）,1和2顺序不固定，4和5顺序不固定
```

```ruby
- (void)barrierSync {
    dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        NSLog(@"任务1");
    });
    
    NSLog(@"任务2");
    
    dispatch_barrier_sync(queue, ^{
        NSLog(@"任务3");
    });
    
    NSLog(@"任务4");
    
    dispatch_async(queue, ^{
        NSLog(@"任务5");
    });
}

打印结果： 2 在 3 前，3 在 4 前，1，5随机出现
```

### 3.4、GCD 快速迭代 `dispatch_apply `


快速迭代不能保证顺序

```ruy
- (void)apply {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    NSLog(@"apply---begin");
    dispatch_apply(6, queue, ^(size_t index) {
        NSLog(@"%zd---%@",index, [NSThread currentThread]);
    });
    NSLog(@"apply---end");
}

```

### 3.4 dispatch_group_enter、dispatch_group_leave

```ruby
- (void)groupEnterAndLeave {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        NSLog(@"任务1");
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        NSLog(@"任务2");
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"任务3");
    });
}
打印结果 （1， 2），3 其中1和2顺序不固定
```

### 3.5、其它 

`dispatch_once`和`dispatch_after`
