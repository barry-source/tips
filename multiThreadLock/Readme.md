
# 10种锁的对比


## 1、9种锁的性能比较

![性能.png](https://upload-images.jianshu.io/upload_images/1899027-eb3ef0d444034362.png?imageMogr2/auto-orient/strip|imageView2/2/w/1060)



## 2、各种锁使用


###  2.1、`OSSpinLock`

OSSpinLock叫做”自旋锁”，等待锁的线程会处于忙等（`busy-wait`）状态，一直占用着CPU资源
目前已经不再安全，可能会出现优先级反转问题，ios 10被废弃，替代的是`os_unfair_lock`
如果等待锁的线程优先级较高，它会一直占用着CPU资源，优先级低的线程就无法释放锁
需要导入头文件`#import <libkern/OSAtomic.h>`

```ruby

// 初始化
OSSpinLock lock = OS_SPINLOCK_INIT;
// 尝试加锁(返回true加锁成功，false加锁失败)
bool result = OSSpinLockTry(&lock);
// 加锁
OSSpinLockLock(&lock);
// 解锁
OSSpinLockUnlock(&lock);

```

###  2.2、`os_unfair_lock`

`os_unfair_lock`用于取代不安全的`OSSpinLock` ，从`iOS10`开始才支持
从底层调用看，等待`os_unfair_lock`锁的线程会处于休眠状态，并非忙等
需要导入头文件`#import <os/lock.h>`


```ruby
// 初始化
os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;
// 尝试加锁(返回true加锁成功，false加锁失败)
bool result =  os_unfair_lock_trylock(&lock);
// 加锁
os_unfair_lock_lock(&lock);
// 解锁
os_unfair_lock_unlock(&lock);
```

###  2.3、`pthread_mutex` 互斥锁

mutex叫做”互斥锁”，等待锁的线程会处于休眠状态
需要导入头文件#import <pthread.h>

#### 互斥锁

```ruby
// 初始化锁的属性
pthread_mutexattr_t attr;
pthread_mutexattr_init(&attr);
pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_DEFAULT);
// 初始化锁
pthread_mutex_t lock;
pthread_mutex_init(&lock, &attr);
// 尝试加锁
pthread_mutex_trylock(&lock);
// 加锁
pthread_mutex_lock(&lock);
// 解锁
pthread_mutex_unlock(&lock);
// 销毁相关资源
pthread_mutexattr_destroy(&attr);
pthread_mutex_destroy(&lock);

/*
 * Mutex type attributes锁的属性
 */
#define PTHREAD_MUTEX_NORMAL        0
#define PTHREAD_MUTEX_ERRORCHECK    1
#define PTHREAD_MUTEX_RECURSIVE        2
#define PTHREAD_MUTEX_DEFAULT        PTHREAD_MUTEX_NORMAL
```

#### 递归锁

```ruby

/ 初始化锁的属性
pthread_mutexattr_t attr;
pthread_mutexattr_init(&attr);
// 递归锁
pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
// 初始化锁
pthread_mutex_t lock;
pthread_mutex_init(&lock, &attr);
// 尝试加锁
pthread_mutex_trylock(&lock);
// 加锁
pthread_mutex_lock(&lock);
// 解锁
pthread_mutex_unlock(&lock);
// 销毁相关资源
pthread_mutexattr_destroy(&attr);
pthread_mutex_destroy(&lock);

```

#### 条件锁

```ruby

// 初始化锁的属性
pthread_mutexattr_t attr;
pthread_mutexattr_init(&attr);
pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_DEFAULT);
// 初始化锁
pthread_mutex_t lock;
pthread_mutex_init(&lock, &attr);
// 初始化条件
pthread_cond_t condition;
pthread_cond_init(&condition, NULL);
// 等待条件（进入休眠时，会放开lock，补唤醒后，会再次对lock加锁）
pthread_cond_wait(&condition, &lock);
// 激活一个等待该条件的线程
pthread_cond_signal(&condition);
// 激活所有等待该条件的线程
pthread_cond_broadcast(&condition);
// 销毁相关资源
pthread_mutexattr_destroy(&attr);
pthread_cond_destroy(&condition);
```

###  2.4、`NSLock` 

`NSLock` 是对`mutex`普通锁的封装


```ruby

@protocol NSLocking

- (void)lock;
- (void)unlock;

@end

/*********************************/

@interface NSLock : NSObject <NSLocking> {

- (BOOL)tryLock;
- (BOOL)lockBeforeDate:(NSDate *)limit;

@property (nullable, copy) NSString *name API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0));

@end
```

###  2.5、`NSRecursiveLock` 递归锁

`NSRecursiveLock`也是对`mutex`递归锁的封装，API跟`NSLock`基本一致


```ruby
@protocol NSLocking

- (void)lock;
- (void)unlock;

@end

/*********************************/

@interface NSRecursiveLock : NSObject <NSLocking> {

- (BOOL)tryLock;
- (BOOL)lockBeforeDate:(NSDate *)limit;

@property (nullable, copy) NSString *name API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0));

@end

```

###  2.6、`NSCondition`

`NSCondition`是对`mutex`和`cond`的封装

```ruby

@protocol NSLocking

- (void)lock;
- (void)unlock;

@end

/*********************************/

@interface NSCondition : NSObject <NSLocking> {
- (void)wait;
- (BOOL)waitUntilDate:(NSDate *)limit;
- (void)signal;
- (void)broadcast;

@property (nullable, copy) NSString *name API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0));

@end

```

###  2.7、`NSConditionLock`

`NSConditionLock`是对`NSCondition`的进一步封装，可以设置具体的条件值


```ruby

@protocol NSLocking

- (void)lock;
- (void)unlock;

@end

/*********************************/

@interface NSConditionLock : NSObject <NSLocking> {

- (instancetype)initWithCondition:(NSInteger)condition NS_DESIGNATED_INITIALIZER;

@property (readonly) NSInteger condition;
- (void)lockWhenCondition:(NSInteger)condition;
- (BOOL)tryLock;
- (BOOL)tryLockWhenCondition:(NSInteger)condition;
- (void)unlockWithCondition:(NSInteger)condition;
- (BOOL)lockBeforeDate:(NSDate *)limit;
- (BOOL)lockWhenCondition:(NSInteger)condition beforeDate:(NSDate *)limit;

@property (nullable, copy) NSString *name API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0));

@end

```

###  2.8、`dispatch_semaphore`

信号量的初始值，可以用来控制线程并发访问的最大数量
信号量的初始值为1，代表同时只允许1条线程访问资源，保证线程同步，相当于互斥锁


```ruby
// 初始化信号量，最多开5个线程
dispatch_semaphore_t semaphore = dispatch_semaphore_create(5);
// 信号量<= 0进入休眠，
// 信号量 > 0时，减1，然后执行持续代码
dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
// 信号量加1
dispatch_semaphore_signal(semaphore);
```

###  2.9、`dispatch_queue`

利用串行队列的特性，也可以实现互斥锁，

```ruby

dispatch_queue_t queue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL);
dispatch_async(queue, ^{

});

```

###  2.10、`@synchronized`

`@synchronized`是对`mutex`递归锁的封装
源码查看：objc4中的objc-sync.mm文件
@synchronized(obj)内部会生成obj对应的递归锁，然后进行加锁、解锁操作


```ruby
@synchronized (obj) {
    
}
```



## 3、自旋锁和互斥锁

```ruby
什么情况使用自旋锁比较划算？
预计线程等待锁的时间很短
加锁的代码（临界区）经常被调用，但竞争情况很少发生
CPU资源不紧张
多核处理器

什么情况使用互斥锁比较划算？
预计线程等待锁的时间较长
单核处理器
临界区有IO操作
临界区代码复杂或者循环量大
临界区竞争非常激烈

```
