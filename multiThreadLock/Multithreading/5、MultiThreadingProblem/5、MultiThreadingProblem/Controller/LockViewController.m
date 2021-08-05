//
//  LockViewController.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/7/3.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "LockViewController.h"
#import "MutexRecursiveLock.h"
#import "MutexConditionLock.h"
#import "NSRecursiveLockDemo.h"
#import "NSConditionDemo.h"
#import "NSConditionLockDemo.h"
#import "Semaphore.h"
#import "SpinLock.h"
#import "UnfairLock.h"
#import "MutexLock.h"
#import "NSLockDemo.h"
#import "SerialQueueSync.h"
#import "SemaphoreSync.h"
#import "SynchronizedDemo.h"
#import "PTthreadRWLock.h"
#import "DispatchBarrierRWLock.h"

@interface LockViewController ()

//卖票 存取钱
@property (nonatomic, strong) SpinLock *spinLock;
@property (nonatomic, strong) UnfairLock *unfairLock;
@property (nonatomic, strong) MutexLock *mutexLock;
@property (nonatomic, strong) NSLockDemo *nslockLock;
@property (nonatomic, strong) SerialQueueSync *serialQueueSync;
@property (nonatomic, strong) SemaphoreSync *semaphoreSync;
@property (nonatomic, strong) SynchronizedDemo *synchronizedDemo;

//其它
@property (nonatomic, strong) MutexRecursiveLock *recursiveLock;
@property (nonatomic, strong) MutexConditionLock *conditionLock;
@property (nonatomic, strong) NSRecursiveLockDemo *nsRecursiveLock;
@property (nonatomic, strong) NSConditionDemo *nsCondition;
@property (nonatomic, strong) NSConditionLockDemo *nsConditionLock;
@property (nonatomic, strong) Semaphore *semaphore;
@property (nonatomic, strong) PTthreadRWLock *rwLock;
@property (nonatomic, strong) DispatchBarrierRWLock *barrierLock;

@property (nonatomic,strong) UILabel *descLabel;
@end

@implementation LockViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = self.titleArray[self.type];
    
    
    
    self.descLabel = [[UILabel alloc] init];
    self.descLabel.frame = self.view.frame;
    self.descLabel.numberOfLines = 0;
    
    self.descLabel.lineBreakMode =     NSLineBreakByCharWrapping;

    [self.view addSubview:self.descLabel];
    
    
    NSString *selectorName = self.selectorArray[self.type];
    NSLog(@"方法名：%@", selectorName);
    SEL sel = NSSelectorFromString(selectorName);
    [self performSelector:sel];
    
}


#pragma 卖票
- (void)spinLockTicketTest {
    //自旋锁
    self.spinLock = [[SpinLock alloc] init];
    [self.spinLock sellTickets];
    
    self.descLabel.text = @"自旋锁是保证线程安全的一种锁，当一个线程进入临界区之后，其它线程如果想执行临界区代码，那么就会处理忙等状态，类似一种while循环,会一直判断锁是不是被放开\n>>>>>适用场景：\n1、临界区代码执行时间比较短，因为忙等会消耗大量cpu资源\n>>>>>缺点:\n1、它会造成优先级反转(低优先级线程占用了锁，然后来了一个高优先级线程，因些低优先级的线程无法分配到时间片，无法继续执行，导致锁无法释放)\n2、ios 10之后，自旋锁被放弃,忙等占用cpu资源";
}

- (void)unfairLockTicketTest {
    //不公平锁
    self.unfairLock = [[UnfairLock alloc] init];
    [self.unfairLock sellTickets];
    
    self.descLabel.text = @"unfair_lock用于替代Spinlock,它解决了优先级反转问题，ios 10之后，才能使用,线程在等待的过程中会处于休眠状态";
}

- (void)mutexLockTicketTest {
    //互斥锁
    self.mutexLock = [[MutexLock alloc] init];
    [self.mutexLock sellTickets];
    
    self.descLabel.text = @"pthread 表示 POSIX thread，定义了一组跨平台的线程相关的 API，pthread_mutex 表示互斥锁。互斥锁的实现原理与信号量非常相似，不是使用忙等，而是阻塞线程并睡眠，需要进行上下文切换。锁的类型有\nPTHREAD_MUTEX_NORMAL、\nPTHREAD_MUTEX_ERRORCHECK、\nPTHREAD_MUTEX_RECURSIVE";
}

- (void)NSLockTicketTest {
    //mutex对象封装
    self.nslockLock = [[NSLockDemo alloc] init];
    [self.nslockLock sellTickets];
    self.descLabel.text = @"NSLock 是 Objective-C 以对象的形式暴露给开发者的一种锁.NSLock 只是在内部封装了一个 pthread_mutex，属性为 PTHREAD_MUTEX_ERRORCHECK，它会损失一定性能换来错误提示。NSLock 比 pthread_mutex 略慢的原因在于它需要经过方法调用，同时由于缓存的存在，多次方法调用不会对性能产生太大的影响。";
}

- (void)serialQueueTicketTest {
    //串行队列保证任务同步
    self.serialQueueSync = [[SerialQueueSync alloc] init];
    [self.serialQueueSync sellTickets];
}

- (void)semaphoreTicketTest {
    //信号量
    self.semaphoreSync = [[SemaphoreSync alloc] init];
    [self.semaphoreSync sellTickets];
    
    self.descLabel.text = @"semaphore是一种更高级的同步机制，互斥锁可以说是semaphore在仅取值0/1时的特例。信号量可以有更多的取值空间，用来实现更加复杂的同步，而不单单是线程间互斥。";
}

- (void)synchronizedTicketTest {
    //信号量
    self.synchronizedDemo = [[SynchronizedDemo alloc] init];
    [self.synchronizedDemo sellTickets];
    self.descLabel.text = @"@synchronized是对mutex递归锁的封装,效率低下，用法最简单";
}

#pragma 存取钱


- (void)spinLockMoneyTest {
    //自旋锁
    self.spinLock = [[SpinLock alloc] init];
    [self.spinLock bankMoney];
    self.descLabel.text = @"自旋锁是保证线程安全的一种锁，当一个线程进入临界区之后，其它线程如果想执行临界区代码，那么就会处理忙等状态，类似一种while循环,会一直判断锁是不是被放开\n>>>>>适用场景：\n1、临界区代码执行时间比较短，因为忙等会消耗大量cpu资源\n>>>>>缺点:\n1、它会造成优先级反转(低优先级线程占用了锁，然后来了一个高优先级线程，因些低优先级的线程无法分配到时间片，无法继续执行，导致锁无法释放)\n2、ios 10之后，自旋锁被放弃,忙等占用cpu资源";
}

- (void)unfairLockMoneyTest {
    //不公平锁
    self.unfairLock = [[UnfairLock alloc] init];
    [self.unfairLock bankMoney];
    
    self.descLabel.text = @"unfair_lock用于替代Spinlock,它解决了优先级反转问题，ios 10之后，才能使用,线程在等待的过程中会处于休眠状态";
}

- (void)mutexLockMoneyTest {
    //互斥锁
    self.mutexLock = [[MutexLock alloc] init];
    [self.mutexLock bankMoney];
    self.descLabel.text = @"pthread 表示 POSIX thread，定义了一组跨平台的线程相关的 API，pthread_mutex 表示互斥锁。互斥锁的实现原理与信号量非常相似，不是使用忙等，而是阻塞线程并睡眠，需要进行上下文切换。锁的类型有\nPTHREAD_MUTEX_NORMAL、\nPTHREAD_MUTEX_ERRORCHECK、\nPTHREAD_MUTEX_RECURSIVE";
}

- (void)serialQueueMoneyTest {
    //串行队列保证任务同步
    self.serialQueueSync = [[SerialQueueSync alloc] init];
    [self.serialQueueSync bankMoney];
}

- (void)NSLockMoneyTest {
    //mutex对象封装
    self.nslockLock = [[NSLockDemo alloc] init];
    [self.nslockLock bankMoney];
    
    self.descLabel.text = @"NSLock 是 Objective-C 以对象的形式暴露给开发者的一种锁.NSLock 只是在内部封装了一个 pthread_mutex，属性为 PTHREAD_MUTEX_ERRORCHECK，它会损失一定性能换来错误提示。NSLock 比 pthread_mutex 略慢的原因在于它需要经过方法调用，同时由于缓存的存在，多次方法调用不会对性能产生太大的影响。";
}

- (void)semaphoreMoneyTest {
    //信号量
    self.semaphoreSync = [[SemaphoreSync alloc] init];
    [self.semaphoreSync bankMoney];
    
    self.descLabel.text = @"semaphore是一种更高级的同步机制，互斥锁可以说是semaphore在仅取值0/1时的特例。信号量可以有更多的取值空间，用来实现更加复杂的同步，而不单单是线程间互斥。";
}

- (void)synchronizedMoneyTest {
    //信号量
    self.synchronizedDemo = [[SynchronizedDemo alloc] init];
    [self.synchronizedDemo bankMoney];
    
    self.descLabel.text = @"@synchronized是对mutex递归锁的封装,效率低下，用法最简单";
}
#pragma 其它锁

//pthread 递归锁
- (void)recursiveLockTest {
    self.recursiveLock = [[MutexRecursiveLock alloc] init];
    
    [self.recursiveLock recursiveTest];
    self.descLabel.text = @"\npthread_mutexattr_t attr;\npthread_mutexattr_init(&attr);\npthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);\npthread_mutex_init(lock, &attr);\npthread_mutexattr_destroy(&attr);";
}

//pthread 条件锁
- (void)conditionLockTest {
    self.conditionLock = [[MutexConditionLock alloc] init];
    [self.conditionLock conditionTest];
    
    self.descLabel.text = @"\npthread_mutexattr_t attr;\npthread_mutexattr_init(&attr);\npthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);\npthread_mutex_init(lock, &attr);\npthread_mutexattr_destroy(&attr);\npthread_cond_init(&_condition, NULL);";

}

//NSRecursiveLock
- (void)NSRecursiveLockTest {
    self.nsRecursiveLock = [[NSRecursiveLockDemo alloc] init];
    [self.nsRecursiveLock recursiveTest];
    self.descLabel.text = @"NSRecursiveLock也是对mutex递归锁的封装";
    
}

//NSConditionLock
- (void)NSConditionTest {
    self.nsCondition= [[NSConditionDemo alloc] init];
    [self.nsCondition conditionTest];
    self.descLabel.text = @"NSCondition是对mutex和cond的封装,NSCondition 的底层是通过条件变量(condition variable) pthread_cond_t 来实现的。条件变量有点像信号量，提供了线程阻塞与信号机制，因此可以用来阻塞某个线程，并等待某个数据就绪，随后唤醒线程，比如常见的生产者-消费者模式。";
}

//线程依赖NSConditionLock
- (void)NSConditionLockTest {
    self.nsConditionLock = [[NSConditionLockDemo alloc] init];
    [self.nsConditionLock conditionLockTest];
    
    self.descLabel.text = @"NSConditionLock 借助 NSCondition 来实现，它的本质就是一个生产者-消费者模型。“条件被满足”可以理解为生产者提供了新的内容。NSConditionLock 的内部持有一个 NSCondition 对象，以及 _condition_value 属性，在初始化时就会对这个属性进行赋值:";
}

//dispatch_semaphore_t  信号量，最大并发数
- (void)semaphoreMaxConcurrentCount {
    self.semaphore = [[Semaphore alloc] init];
    [self.semaphore semaphoreTest];
}

//读写锁
- (void)readWriteLock {
    self.rwLock = [[PTthreadRWLock alloc] init];
    [self.rwLock rwLockTest];
}

//栅栏
- (void)barrierRWLock {
    self.barrierLock = [[DispatchBarrierRWLock alloc] init];
    [self.barrierLock barrierRwLockTest];
}

- (NSMutableArray *)selectorArray {
    if (!_selectorArray) {
        _selectorArray = [[NSMutableArray alloc] init];
    }
    return _selectorArray;
}

- (NSMutableArray *)titleArray {
    if (!_titleArray) {
        _titleArray = [[NSMutableArray alloc] init];
    }
    return _titleArray;
}


@end
