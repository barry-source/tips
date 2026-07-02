# iOS 多线程

## 一、iOS 多线程方案对比

| 方案 | 语言 | 抽象层级 | 线程管理 | 队列支持 | 使用复杂度 |
|------|------|---------|---------|---------|-----------|
| **pthread** | C | 最底层 | 手动 | ❌ | ⭐⭐⭐⭐⭐ |
| **NSThread** | OC | 面向对象 | 手动/自动 | ❌ | ⭐⭐⭐⭐ |
| **GCD** | C（Block） | 队列驱动 | 自动（线程池） | ✅ 串行/并发 | ⭐⭐ |
| **NSOperationQueue** | OC | 面向对象 | 自动 + 依赖 | ✅ 可设置最大并发 | ⭐⭐ |
| **Swift Concurrency** | Swift | 语言原生 | 自动（协作式） | ✅ TaskGroup | ⭐ |

---

## 二、pthread（POSIX Thread）

### 2.1 基本使用

```objc
#import <pthread.h>

void *task(void *param) {
    NSLog(@"pthread task on thread: %@", [NSThread currentThread]);
    return NULL;
}

- (void)createPthread {
    pthread_t thread;
    pthread_create(&thread, NULL, task, NULL);
    // pthread_create(&thread, NULL, task, (void *)"param"); // 传参
    pthread_detach(thread);  // 分离线程（自动释放资源）
    // pthread_join(thread, NULL);  // 等待线程结束
}
```

### 2.2 特点

- 最底层的线程 API，跨平台（POSIX 标准）
- 需要手动管理线程生命周期（创建、销毁、分离）
- 需要手动管理锁（`pthread_mutex_t`、`pthread_rwlock_t`、`pthread_cond_t`）
- 实际开发中较少直接使用，但 CF 层和部分第三方库底层使用

---

## 三、NSThread

### 3.1 创建方式

```objc
// 方式 1：动态创建
NSThread *thread = [[NSThread alloc] initWithTarget:self
                                          selector:@selector(task)
                                            object:nil];
thread.name = @"MyThread";
thread.threadPriority = 0.5;
[thread start];

// 方式 2：类方法创建（自动启动）
[NSThread detachNewThreadSelector:@selector(task) toTarget:self withObject:nil];

// 方式 3：隐式创建
[self performSelectorInBackground:@selector(task) withObject:nil];

// 方式 4：Swift 中
Thread.detachNewThread {
    print("Thread running")
}
```

### 3.2 常用方法

```objc
// 获取当前线程
[NSThread currentThread];

// 获取主线程
[NSThread mainThread];

// 休眠
[NSThread sleepForTimeInterval:1.0];
[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];

// 判断是否为主线程
[NSThread isMainThread];

// 线程取消
[thread cancel];
if ([[NSThread currentThread] isCancelled]) {
    [NSThread exit];  // 退出当前线程
}
```

### 3.3 线程间通信

```objc
// 子线程回到主线程
[self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];

// 在指定线程执行
[self performSelector:@selector(task) onThread:targetThread withObject:nil waitUntilDone:NO];

// waitUntilDone：是否等待目标线程执行完才返回
```

### 3.4 特点

- 面向对象的线程封装，比 pthread 易用
- 仍需手动管理线程生命周期和线程池
- 适合简单的单线程任务
- **生产环境较少使用**，通常用 GCD 替代

---

## 四、GCD（Grand Central Dispatch）

### 4.1 GCD 核心概念

```
GCD = 队列（Queue）+ 任务（Block/函数）
         │
         ▼
    系统线程池（自动管理线程的创建、复用、销毁）
```

**队列类型**：

| 队列类型 | 创建方式 | 任务执行 | 场景 |
|---------|---------|---------|------|
| **主队列** | `dispatch_get_main_queue()` | 串行 | UI 刷新 |
| **全局并发队列** | `dispatch_get_global_queue(qos, 0)` | 并发 | 通用异步任务 |
| **自定义串行队列** | `dispatch_queue_create("label", DISPATCH_QUEUE_SERIAL)` | 串行 | 同步访问资源 |
| **自定义并发队列** | `dispatch_queue_create("label", DISPATCH_QUEUE_CONCURRENT)` | 并发 | 多任务并行 |

### 4.2 QoS（Quality of Service）

| QoS | 级别 | CPU 分配 | 适用场景 |
|-----|------|---------|---------|
| `userInteractive` | 最高 | 最多 | UI 更新、手势响应 |
| `userInitiated` | 高 | 多 | 用户等待的结果（打开文件、加载图片） |
| `default` | 中 | 中 | 默认 |
| `utility` | 低 | 少 | 用户不直接等待（下载、同步） |
| `background` | 最低 | 极少 | 后台清理、备份 |

### 4.3 基本使用

```objc
// 异步执行（不阻塞当前线程）
dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
    // 耗时任务
    NSString *result = [self fetchData];

    // 回到主线程更新 UI
    dispatch_async(dispatch_get_main_queue(), ^{
        self.label.text = result;
    });
});

// 同步执行（阻塞当前线程，谨慎使用！）
dispatch_sync(dispatch_get_main_queue(), ^{
    // ❌ 主线程调用 dispatch_sync(主队列) → 死锁
});
```

### 4.4 dispatch_after

```objc
// 延迟执行（不是精确计时，是在指定时间后将任务加入队列）
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
               dispatch_get_main_queue(), ^{
    NSLog(@"3 秒后执行");
});
```

### 4.5 dispatch_once

```objc
// 单例，保证只执行一次（线程安全）
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    // 初始化代码（如单例创建、方法交换）
});
```

### 4.6 dispatch_apply

```objc
// 快速迭代（并发执行 for 循环）
dispatch_apply(10, dispatch_get_global_queue(0, 0), ^(size_t index) {
    NSLog(@"并行执行第 %zu 次", index);
});
// 同步等待所有迭代完成
```

### 4.7 dispatch_group

```objc
// 场景：等待多个异步任务全部完成后再执行后续操作
dispatch_group_t group = dispatch_group_create();

dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
    // 任务 1
});

dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
    // 任务 2
});

dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
    // 任务 3
});

// 方式 1：阻塞等待（不推荐在主线程）
dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

// 方式 2：异步回调（推荐）
dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    // 所有任务完成后执行
    NSLog(@"全部任务完成");
});

// 方式 3：手动管理 enter/leave
dispatch_group_enter(group);
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    // 任务
    dispatch_group_leave(group);
});
```

### 4.8 dispatch_barrier

```objc
// 场景：多读单写（读并发，写独占）
dispatch_queue_t queue = dispatch_queue_create("rw_queue", DISPATCH_QUEUE_CONCURRENT);

// 读操作（并发）
- (id)readObjectForKey:(NSString *)key {
    __block id result;
    dispatch_sync(queue, ^{
        result = self.cache[key];
    });
    return result;
}

// 写操作（独占）
- (void)writeObject:(id)object forKey:(NSString *)key {
    dispatch_barrier_async(queue, ^{
        // barrier 会等待当前所有任务完成，再执行此任务
        // 执行期间，不会有其他任务同时在执行
        self.cache[key] = object;
    });
}
```

### 4.9 dispatch_semaphore

```objc
// 场景：控制并发数
dispatch_semaphore_t sem = dispatch_semaphore_create(3);  // 最多 3 个并发

for (int i = 0; i < 10; i++) {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);  // 等待信号量
        NSLog(@"开始任务 %d", i);
        sleep(1);
        NSLog(@"完成任务 %d", i);
        dispatch_semaphore_signal(sem);  // 释放信号量
    });
}
```

### 4.10 死锁场景

```objc
// ❌ 场景 1：主队列同步（主线程死锁）
dispatch_sync(dispatch_get_main_queue(), ^{
    NSLog(@"不会执行");
});

// ❌ 场景 2：串行队列嵌套同步
dispatch_queue_t queue = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
dispatch_async(queue, ^{
    dispatch_sync(queue, ^{  // 串行队列中同步提交到同一队列 → 死锁
        NSLog(@"不会执行");
    });
});
```

### 4.11 特点和面试重点

| 知识点 | 说明 |
|--------|------|
| GCD 是 C 语言框架，不是 OC | 基于 Block，由 libdispatch 库实现 |
| 自动线程池管理 | 系统根据 CPU 核心数和 QoS 动态管理线程 |
| 队列是核心 | 任务提交到队列，系统从线程池取线程执行 |
| 同步/异步 | sync（阻塞当前线程）/ async（不阻塞）|
| 串行/并发 | 队列的属性，决定任务 FCFS 还是同时执行 |
| 死锁 | 主队列 sync、串行队列中 self sync |

---

## 五、NSOperationQueue

### 5.1 基本使用

```objc
// 创建操作队列
NSOperationQueue *queue = [[NSOperationQueue alloc] init];
queue.maxConcurrentOperationCount = 3;  // 最大并发数

// 创建操作
NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
    NSLog(@"任务执行");
}];

// 添加到队列
[queue addOperation:operation];

// 简便方式
[queue addOperationWithBlock:^{
    NSLog(@"直接添加 Block");
}];
```

### 5.2 依赖关系

```objc
// 场景：任务 B 依赖任务 A 的结果
NSBlockOperation *opA = [NSBlockOperation blockOperationWithBlock:^{
    NSLog(@"登录");
}];

NSBlockOperation *opB = [NSBlockOperation blockOperationWithBlock:^{
    NSLog(@"获取用户信息（登录后）");
}];

[opB addDependency:opA];  // B 依赖于 A，A 完成后 B 才开始

// 跨队列依赖
NSOperationQueue *queue = [[NSOperationQueue alloc] init];
[queue addOperations:@[opA, opB] waitUntilFinished:NO];
```

### 5.3 任务取消

```objc
NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
    if (![op isCancelled]) {  // 检查取消状态
        // 执行任务
    }
}];

// 取消单个
[op cancel];

// 取消队列中所有任务
[queue cancelAllOperations];
```

### 5.4 回调监听

```objc
NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
    // 任务
}];

op.completionBlock = ^{
    NSLog(@"任务完成");
};
```

### 5.5 NSOperation vs GCD

| 对比项 | GCD | NSOperationQueue |
|--------|-----|-----------------|
| **语言** | C（Block） | OC 面向对象 |
| **依赖** | ❌ 不支持 | ✅ addDependency |
| **取消** | ❌ 无法取消单个任务 | ✅ cancel 单个操作 |
| **最大并发数** | ❌ 不能直接控制 | ✅ maxConcurrentOperationCount |
| **暂停/恢复** | ❌ 不支持 | ✅ setSuspended: |
| **状态监听** | ❌ 不支持 | ✅ isFinished / completionBlock |
| **适用场景** | 简单异步任务 | 复杂任务编排 |

---

## 六、Swift Concurrency（async/await）

### 6.1 基本使用

```swift
// async 函数
func fetchData() async throws -> Data {
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}

// 调用
Task {
    do {
        let data = try await fetchData()
        // 处理数据
    } catch {
        print("Error: \(error)")
    }
}
```

### 6.2 Task

```swift
// 创建 Task（继承当前 actor 的优先级和上下文）
Task {
    await someAsyncFunction()
}

// detached task（独立上下文，不继承）
Task.detached {
    await someAsyncFunction()
}

// 带优先级的 Task
Task(priority: .high) {
    // ...
}
```

### 6.3 TaskGroup

```swift
// 并行执行多个异步任务
let results = try await withThrowingTaskGroup(of: Data.self) { group in
    for url in urls {
        group.addTask {
            return try await download(url: url)
        }
    }

    var datas: [Data] = []
    for try await data in group {
        datas.append(data)
    }
    return datas
}
```

### 6.4 Actor

```swift
actor Counter {
    private var value = 0

    func increment() {
        value += 1
    }

    func getValue() -> Int {
        return value
    }
}

// 使用
let counter = Counter()
await counter.increment()
print(await counter.getValue())
```

### 6.5 Swift Concurrency vs GCD

| 对比项 | GCD | Swift Concurrency |
|--------|-----|-------------------|
| **语法** | Block 回调 | 同步风格 async/await |
| **上下文切换** | 手动管理 | 编译器自动处理 |
| **线程安全** | 需手动加锁 | Actor 自动隔离 |
| **任务取消** | ❌ 不支持 | ✅ 内置 Task.isCancelled |
| **结构化并发** | ❌ 不支持 | ✅ TaskGroup |
| **性能** | 线程切换开销 | 协作式调度，更轻量 |

---

## 七、锁

锁的详细内容请参见 [多线程同步（锁）](../multiThreadLock/Readme.md)。

---

## 八、面试题

### 1. iOS 有哪些多线程方案？各自的优缺点？

pthread、NSThread、GCD、NSOperationQueue、Swift Concurrency。见第一章对比表。

### 2. GCD 中 sync 和 async 的区别？

- `sync`：阻塞当前线程，等待 block 执行完后才返回。**主线程 sync 会死锁**
- `async`：不阻塞当前线程，立即返回，block 在后台执行

### 3. 什么是死锁？哪些场景会死锁？

- 主队列中调用 `dispatch_sync(主队列)`
- 串行队列中嵌套同名串行队列的 `dispatch_sync`
- 多个线程互相等待对方释放锁

### 4. dispatch_barrier 的作用？

在并发队列中创建一个同步屏障，等待之前所有任务完成后再执行，执行期间没有其他任务并发。常用于**多读单写**模式。

### 5. dispatch_group 的用途？

等待多个异步任务全部完成后再执行后续操作。用于多个网络请求的合并、多个图片下载完成后合成等。

### 6. NSOperationQueue 相比 GCD 的优势？

支持**依赖**、**取消**、**最大并发数控制**、**状态监听**，适合复杂的任务编排。

### 7. Swift Concurrency 中 Actor 的作用？

Actor 保护可变状态免受数据竞争，编译器自动保证同一时间只有一个线程访问 Actor 内部状态。

### 8. 如何实现线程安全的单例？

```objc
// 方式 1：dispatch_once（推荐）
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static id instance;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

// 方式 2：静态变量（ARC 下也是线程安全的）
+ (instancetype)sharedInstance {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}
```

### 9. 如何控制 GCD 的并发数？

使用 `dispatch_semaphore`：

```objc
dispatch_semaphore_t sem = dispatch_semaphore_create(3);
for (int i = 0; i < 100; i++) {
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        // 最多 3 个同时执行
        dispatch_semaphore_signal(sem);
    });
}
```

### 10. PerformSelector 和 GCD 的区别？

- `performSelector:withObject:afterDelay:` 依赖于 RunLoop，会在 Timer 中触发
- `dispatch_after` 不依赖 RunLoop，直接由 GCD 管理
- 在子线程中 `performSelector` 可能不执行（子线程默认没开启 RunLoop）
