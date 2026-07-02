
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

// 初始化锁的属性
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
// 等待条件（进入休眠时，会放开lock，被唤醒后，会再次对lock加锁）
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

---

## 4、优先级反转（Priority Inversion）

### 4.1 什么是优先级反转

优先级反转是指**低优先级线程持有锁时，被中优先级线程抢占，导致高优先级线程因拿不到锁而阻塞**的现象。

### 4.2 优先级反转的过程

```
正常情况：
  高优先级线程（H）→ 先执行 → 完成
  中优先级线程（M）→ 后执行 → 完成
  低优先级线程（L）→ 最后执行 → 完成

优先级反转发生：
  时间轴 →
  ──────────────────────────────────────────────────
  L: 获得锁 [████████████████████]
  H: 尝试获取锁 [----------等待 L 释放锁----------]
  M: 抢占 CPU [████████] ← M 优先级高于 L，但低于 H
  ──────────────────────────────────────────────────
  H 等待 L，L 被 M 抢占，M 跟锁无关但插队执行 → H 的等待时间不确定
```

**具体步骤**：

```
① 低优先级线程 L 获得锁，开始执行临界区代码
② 高优先级线程 H 尝试获取同一把锁 → 被阻塞（等待 L 释放锁）
③ 中优先级线程 M（不需要锁）被调度执行 → 抢占 CPU
④ L 被 M 抢占，无法继续执行 → 无法释放锁
⑤ H 只能等 M 执行完 → L 才能继续 → 释放锁 → H 才能拿到锁
⑥ H 的等待时间从"等 L 释放锁"变成了"等 M + L 都完成"
```

### 4.3 优先级反转的后果

- **高优先级线程的实时性被破坏**：H 的响应时间被中优先级线程延长
- **不确定性**：H 的等待时间取决于 M 的执行时间，无法预估
- **严重时导致系统崩溃**：如音频断音、视频卡顿、看门狗超时

### 4.4 iOS 中的优先级反转场景

#### 场景 1：OSSpinLock（已被废弃的原因）

```objc
// OSSpinLock 已被废弃，因为它会导致严重的优先级反转
OSSpinLock lock = OS_SPINLOCK_INIT;

// 低优先级线程
dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
    OSSpinLockLock(&lock);
    // 临界区
    sleep(1);
    OSSpinLockUnlock(&lock);
});

// 高优先级线程
dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    OSSpinLockLock(&lock);  // 忙等！一直占用 CPU
    // 因为 OSSpinLock 自旋时不会休眠，高优线程持续占用 CPU
    // 低优线程无法获得 CPU 时间 → 无法释放锁
    OSSpinLockUnlock(&lock);
});
```

**OSSpinLock 为什么被废弃**：
- 自旋锁在等待时是**忙等（busy-wait）**，不释放 CPU
- 高优先级线程自旋等待时，低优先级线程无法获得 CPU 时间片
- 低优先级线程无法执行临界区代码 → 无法释放锁
- 高优先级线程永远等不到锁 → **实质上死锁**
- iOS 10 起被 `os_unfair_lock` 替代

#### 场景 2：GCD 全局队列的 QoS 优先级反转

```objc
// iOS 8+ 中 GCD 会自动处理 QoS 优先级反转
// 当一个高 QoS 任务在等待低 QoS 队列中的任务时
// 系统会临时提升低 QoS 队列中的任务的优先级

dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
    // 低优先级任务持有锁
    [lock lock];
    // 临界区
    [lock unlock];
});

dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
    // 高优先级任务等待锁
    // 系统会自动提升低优任务的 QoS → 让低优任务尽快释放锁
    [lock lock];
    [lock unlock];
});
```

#### 场景 3：@synchronized 与 NSOperationQueue

```objc
// 使用 NSOperationQueue 时注意优先级反转
NSOperationQueue *queue = [[NSOperationQueue alloc] init];

NSOperation *lowOp = [NSBlockOperation blockOperationWithBlock:^{
    [lock lock];
    sleep(1);
    [lock unlock];
}];
lowOp.qualityOfService = NSQualityOfServiceBackground;

NSOperation *highOp = [NSBlockOperation blockOperationWithBlock:^{
    [lock lock];  // 等待 lowOp 释放
    [lock unlock];
}];
highOp.qualityOfService = NSQualityOfServiceUserInteractive;
// 如果 lowOp 和 highOp 在同一队列，且 lowOp 先执行
// highOp 虽然优先级高但被 lowOp 阻塞
```

### 4.5 优先级反转的解决方案

| 方案 | 原理 | 使用场景 |
|------|------|---------|
| **优先级继承** | 低优先级线程临时继承高优先级线程的优先级，尽快释放锁 | pthread_mutex、GCD QoS 自动处理 |
| **优先级天花板** | 将锁的优先级设置为所有可能竞争该锁的线程的最高优先级 | 实时操作系统 |
| **不使用自旋锁** | 使用互斥锁替代自旋锁，等待时休眠 | iOS 中用 os_unfair_lock 替代 OSSpinLock |
| **避免锁竞争** | 减少共享资源，使用无锁数据结构 | 性能敏感场景 |

#### 方案 1：优先级继承（Priority Inheritance）

```
优先级继承过程：
  ① L 持有锁
  ② H 等待锁 → 系统发现优先级反转 → L 临时继承 H 的优先级
  ③ L 以高优先级执行 → 尽快释放锁
  ④ L 释放锁 → 恢复 L 的原优先级
  ⑤ H 获得锁 → 继续执行

  效果：M 无法再抢占 L，因为 L 已经有了和 H 同级的优先级
```

**pthread_mutex 的优先级继承属性**：

```objc
pthread_mutexattr_t attr;
pthread_mutexattr_init(&attr);
pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_INHERIT);  // 启用优先级继承
pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);

pthread_mutex_t lock;
pthread_mutex_init(&lock, &attr);
```

#### 方案 2：使用 os_unfair_lock（推荐）

```objc
// os_unfair_lock 在等待时让线程休眠，不忙等
// 避免了高优线程忙等导致低优线程无法执行的问题
os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;
os_unfair_lock_lock(&lock);   // 等待时休眠，不占用 CPU
// 临界区
os_unfair_lock_unlock(&lock);
```

#### 方案 3：使用 GCD 的 dispatch_queue

```objc
// GCD 自动处理优先级反转
// 使用串行队列替代显式锁
dispatch_queue_t serialQueue = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);

// 低优先级任务
dispatch_async(serialQueue, ^{
    // 临界区
});

// 高优先级任务
dispatch_async(serialQueue, ^{
    // GCD 会自动提升前一个任务的 QoS
    // 确保低优任务尽快完成
});
```

### 4.6 如何检测优先级反转

| 工具 | 方法 | 现象 |
|------|------|------|
| **Instruments（Time Profiler）** | 查看线程运行时间 | 高优线程大量时间在 waiting |
| **Instruments（System Trace）** | 查看锁竞争 | 能看到线程的锁等待链 |
| **Xcode Thread Sanitizer** | 静态检查 | 检测数据竞争 |
| **自定义打点** | 记录锁等待时间 | 等待时间异常长时报警 |

### 4.7 面试题

#### Q1：OSSpinLock 为什么被废弃？

因为 OSSpinLock 是自旋锁，等待时忙等不释放 CPU。当高优先级线程自旋等待低优先级线程释放锁时，低优线程无法获得 CPU 时间片，导致锁无法释放，形成**优先级反转**。

#### Q2：什么是优先级反转？

低优先级线程持有锁时，被中优先级线程抢占，导致高优先级线程因拿不到锁而阻塞的现象。

#### Q3：如何避免优先级反转？

1. 使用 `os_unfair_lock` 替代 `OSSpinLock`（等待时休眠）
2. 使用 `pthread_mutex` 的优先级继承属性
3. 使用 GCD 队列（自动 QoS 提升）
4. 减少锁的竞争范围

#### Q4：GCD 如何处理优先级反转？

当一个高 QoS 任务等待低 QoS 任务时，系统会**临时提升**低 QoS 任务的优先级，使其尽快执行完成并释放资源。

---

## 5、锁的全面对比

| 锁 | 类型 | 等待行为 | 性能（约） | 线程安全 | 递归 | 是否推荐 |
|---|------|---------|-----------|---------|------|---------|
| `OSSpinLock` | 自旋锁 | 忙等 | ~30ns | ❌ 不安全（优先级反转） | ❌ | ❌（已废弃） |
| `os_unfair_lock` | 互斥锁 | 休眠 | ~30ns | ✅ | ❌ | ✅ |
| `pthread_mutex` | 互斥锁 | 休眠 | ~60ns | ✅ | 可选 | ✅ |
| `NSLock` | 互斥锁 | 休眠 | ~100ns | ✅ | ❌ | ⚠️ |
| `NSRecursiveLock` | 递归锁 | 休眠 | ~120ns | ✅ | ✅ | ⚠️ |
| `NSCondition` | 条件锁 | 休眠 | ~150ns | ✅ | ❌ | ⚠️ |
| `NSConditionLock` | 条件锁 | 休眠 | ~150ns | ✅ | ❌ | ⚠️ |
| `dispatch_semaphore` | 信号量 | 休眠 | ~50ns | ✅ | ✅ | ✅ |
| `dispatch_queue`(串行) | 队列 | FIFO | ~80ns | ✅ | ❌ | ✅ |
| `@synchronized` | 递归锁 | 休眠 | ~500ns | ✅ | ✅ | ⚠️（最慢） |

**选择建议**：

| 场景 | 推荐 |
|------|------|
| 极简互斥 | `os_unfair_lock` |
| 需要递归锁 | `pthread_mutex(PTHREAD_MUTEX_RECURSIVE)` |
| OC 代码 | `NSLock` / `NSRecursiveLock` |
| 控制并发数 | `dispatch_semaphore` |
| 多读单写 | `dispatch_barrier_async` |
| 条件等待 | `NSCondition` / `NSConditionLock` |
| 快速加锁（性能优先） | `os_unfair_lock` |
| 兼容旧代码 | `@synchronized` |
