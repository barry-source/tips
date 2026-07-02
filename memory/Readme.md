# iOS 内存管理

## 一、内存分区

App 运行时，内存分为 5 个区域：

```
┌─────────────────────────────┐
│ 栈区（Stack）                │ ← 局部变量、函数参数、函数返回地址
│ 自动管理，高地址向低地址分配  │
├─────────────────────────────┤
│ 堆区（Heap）                 │ ← OC 对象、malloc 分配的内存
│ 需要手动/ARC 管理，低地址向上 │
├─────────────────────────────┤
│ 全局区（静态区/常量区）       │ ← 全局变量、static 变量、常量
│ 程序启动时分配，结束时释放    │
├─────────────────────────────┤
│ 代码区                       │ ← 程序代码（编译后的指令）
│ 只读，程序启动时加载          │
├─────────────────────────────┤
│ 内核区                       │ ← 系统保留
└─────────────────────────────┘
```

**开发者只需要管理堆区的内存**，其他区域由系统自动管理。

---

## 二、引用计数（Reference Counting）

### 2.1 基本原理

iOS 通过引用计数来管理 OC 对象的内存：

```
对象创建时：引用计数 = 1
[obj retain]    → 引用计数 + 1
[obj release]   → 引用计数 - 1
引用计数 = 0   → 系统调用 dealloc，释放内存
```

```objc
// MRC 下的引用计数
NSObject *obj = [[NSObject alloc] init];   // retCount = 1
[obj retain];                               // retCount = 2
[obj release];                              // retCount = 1
[obj release];                              // retCount = 0 → dealloc
```

### 2.2 引用计数的存储位置（64位）

```
isa 指针（8 字节，64 位）
┌────────────────────────────────────────────────────────────┐
│ 位域                      │ 说明                            │
├────────────────────────────────────────────────────────────┤
│ bits[0]                   │ indexed：1 = Tagged Pointer     │
│ bits[1]                   │ has_assoc：有关联对象            │
│ bits[2]                   │ has_cxx_dtor：有 C++ 析构       │
│ bits[3-17] (15 bits)      │ shiftcls：类信息地址             │
│ bits[18-19] (2 bits)      │ magic：调试用                   │
│ bits[20-35] (16 bits)     │ has_sidetable_rc：引用计数太大？ │
│ bits[36-51] (16 bits)     │ extra_rc：额外的引用计数         │
│ bits[52-54] (3 bits)      │ deallocating：是否在 dealloc    │
│ bits[55]                  │ weakly_ref：有弱引用             │
│ bits[56-62] (7 bits)      │ unused：未使用                   │
│ bits[63]                  │ shiftcls_shift：存储类信息        │
└────────────────────────────────────────────────────────────┘
```

**引用计数存储规则**：
- **isa 的 extra_rc**（16 位）：存储大部分引用计数（最多 65535）
- **SideTable**：当 extra_rc 存不下时，溢出部分存入 SideTable 的散列表
- 通过 `objc-retainCount` 查看时，返回值 = 1（默认）+ extra_rc + sidetable 中的值

```
// 引用计数查找流程
retainCount = 1 + isa.extra_rc + sidetable_rc

// 正常对象的引用计数
obj = [[NSObject alloc] init]     → retainCount = 1
[obj retain]                       → isa.extra_rc = 1, retainCount = 2
...多次 retain...
isa.extra_rc 溢出                 → sidetable_rc 接管
```

---

## 三、MRC vs ARC

| 对比项 | MRC（Manual Reference Counting） | ARC（Automatic Reference Counting） |
|--------|-------------------------------|-----------------------------------|
| 版本 | iOS 5 之前 | iOS 5+ |
| 管理方式 | 手动调用 retain/release | 编译器自动插入 retain/release |
| 所有权修饰符 | retain / assign / copy | strong / weak / copy / unsafe_unretained |
| 是否可以 dealloc 中释放 | ✅ 需调用 `[super dealloc]` | ✅ 不许调 `[super dealloc]` |
| 是否允许 `retainCount` | ✅ | ❌ 不允许 |
| 是否允许 `NSAutoreleasePool` | 手动创建 | 仍可用 `@autoreleasepool {}` |

```objc
// MRC 写法
- (void)dealloc {
    [_name release];
    [_timer invalidate];
    [_timer release];
    [super dealloc];
}

// ARC 写法（不需要 [super dealloc]）
- (void)dealloc {
    [_timer invalidate];
}
```

---

## 四、ARC 所有权修饰符

| 修饰符 | 作用 | 适用场景 | 引用计数影响 |
|--------|------|---------|------------|
| `__strong` | 强引用（默认） | 大部分对象属性 | ✅ 持有，+1 |
| `__weak` | 弱引用，自动置 nil | 避免循环引用 | ❌ 不持有 |
| `__unsafe_unretained` | 弱引用，不自动置 nil | 兼容旧代码 | ❌ 不持有 |
| `__autoreleasing` | 自动释放 | 传递 NSError 等参数 | 延迟 release |

```objc
@property (nonatomic, strong) NSString *name;    // 强引用（默认）
@property (nonatomic, weak) id delegate;          // 弱引用（防循环引用）
@property (nonatomic, copy) NSString *code;       // copy（不可变拷贝）
@property (nonatomic, assign) NSInteger age;      // 基本类型
```

**weak 和 unsafe_unretained 的区别**：

```
对象释放时：
  weak:             指针自动置为 nil → 安全
  unsafe_unretained:指针变成野指针 → 访问会崩溃！
```

---

## 五、循环引用（Retain Cycle）

循环引用是指两个或多个对象互相强引用，导致所有对象都无法被释放。

### 5.1 常见的 5 种循环引用场景

| 场景 | 代码示例 | 解决方案 |
|------|---------|---------|
| **Delegate** | A.delegate = self (strong) | `weak` 修饰 delegate |
| **Block** | block 内直接使用 self | `__weak typeof(self) weakSelf = self` |
| **NSTimer** | timer target = self | block 方式 / Proxy 中间层 |
| **CADisplayLink** | link target = self | Proxy 中间层 |
| **大对象相互持有** | A → B, B → A | 一端用 weak |

### 5.2 Delegate 循环引用

```objc
// ❌ 错误：delegate 用 strong
@property (nonatomic, strong) id<SomeDelegate> delegate;

// ✅ 正确：delegate 用 weak
@property (nonatomic, weak) id<SomeDelegate> delegate;
```

### 5.3 Block 循环引用

```objc
// ❌ 错误：block 直接使用 self
self.block = ^{
    [self doSomething];  // self → block → self（循环引用）
};

// ✅ 正确：weak-strong dance
__weak typeof(self) weakSelf = self;
self.block = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    [strongSelf doSomething];  // 内部用 strongSelf，防止在 block 执行过程中 self 被释放
};

// ✅ 如果 block 只执行一次，可用 weak 直接访问
__weak typeof(self) weakSelf = self;
self.completionBlock = ^{
    [weakSelf doSomething];
};
```

**Block 循环引用检测**：

| 场景 | 是否循环引用 | 原因 |
|------|------------|------|
| 不使用的 ivar | ❌ 否 | block 不会捕获 |
| 使用 `self->ivar` | ✅ 是 | 隐式强引用 self |
| 使用 `_ivar` | ✅ 是 | 隐式强引用 self |
| 使用 `self.property` | ✅ 是 | 强引用 self |
| `[weakSelf doSomething]` | ❌ 否 | weak 打破循环 |

### 5.4 NSTimer 循环引用

```objc
// ❌ 错误：timer 强引用 target（self）
self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                              target:self
                                            selector:@selector(timerTest)
                                            userInfo:nil
                                             repeats:YES];
// self → timer（strong）
// timer → self（target 强引用）
// → 循环引用，self 和 timer 都无法释放

// ✅ 方案 1：block 方式（iOS 10+）
__weak typeof(self) weakSelf = self;
self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                            repeats:YES
                                              block:^(NSTimer * _Nonnull timer) {
    [weakSelf timerTest];
}];

// ✅ 方案 2：NSProxy 中间层（iOS 10 以下）
@interface Proxy : NSProxy
@property (weak, nonatomic) id target;
+ (instancetype)proxyWithTarget:(id)target;
@end

@implementation Proxy
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}
- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}
@end

// 使用：
self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                              target:[Proxy proxyWithTarget:self]
                                            selector:@selector(timerTest)
                                            userInfo:nil
                                             repeats:YES];
```

### 5.5 CADisplayLink 循环引用

`CADisplayLink` 和 `NSTimer` 一样会强引用 target：

```objc
// ❌ 错误
self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(linkTest)];
[self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

// ✅ 正确：同样使用 Proxy 中间层
self.link = [CADisplayLink displayLinkWithTarget:[Proxy proxyWithTarget:self]
                                        selector:@selector(linkTest)];
```

### 5.6 循环引用检测工具

| 工具 | 方式 | 说明 |
|------|------|------|
| **Xcode Memory Debugger** | GUI 调试 | 运行时查看对象引用链 |
| **Instruments Leaks** | 性能工具 | 实时检测泄漏 |
| **MLeaksFinder** | 第三方库 | 自动检测泄漏 |
| **FBRetainCycleDetector** | 第三方库 | 自动检测循环引用 |

---

## 六、Weak 的实现原理

### 6.1 整体流程

```
① objc_initWeak → 初始化 weak 指针
② objc_storeWeak → 将 weak 指针注册到 SideTable 的弱引用表中
③ 对象 dealloc → 从 SideTable 中找到所有 weak 指针 → 全部置为 nil
```

### 6.2 SideTable 结构

```c
struct SideTable {
    spinlock_t slock;                  // 自旋锁
    RefcountMap refcnts;               // 引用计数散列表（extra_rc 溢出时使用）
    weak_table_t weak_table;           // 弱引用全局表
};

struct weak_table_t {
    weak_entry_t *weak_entries;        // 弱引用表（数组）
    size_t    num_entries;             // 条目数
    uintptr_t mask;                    // 散列表掩码
    uintptr_t max_hash_displacement;   // 最大哈希偏移
};
```

### 6.3 weak 指针置 nil 的时机

```
对象释放流程：
① objc_release → 引用计数减为 0
② objc_dealloc
③ rootDealloc → 判断是否需要 release
④ object_dispose
⑤ objc_destructInstance
⑥ clearDeallocating → 关键步骤！
   ├── 从 SideTable 的 weak_table 中找到所有 weak 指针
   └── 全部指向 nil
⑦ free(obj) → 释放内存
```

**关键点**：weak 指针是在对象 dealloc 时置 nil 的，**不是在对象引用计数为 0 时立即置 nil**。在 dealloc 方法执行期间，weak 指针还有效。

---

## 七、AutoreleasePool

### 7.1 AutoreleasePool 的原理

AutoreleasePool 用于延迟对象的释放：

```
@autoreleasepool {
    // 在此大括号内创建的对象，会被放入 pool 中
    // 在大括号结束时，pool 给所有对象发送 release 消息
}
```

### 7.2 AutoreleasePoolPage 内部结构

AutoreleasePool 底层由 `AutoreleasePoolPage` 实现，它是一个 **C++ 类**，每个 page 占用 **4096 字节（1 页）** 的内存，通过**双向链表**连接多个 page。

```cpp
class AutoreleasePoolPage {
    magic_t const magic;           // 4 字节，校验 page 是否完整 (0xA1A1A1A1)
    id *next;                      // 8 字节，指向下一个可存放对象的地址
    pthread_t const thread;        // 8 字节，所属线程
    AutoreleasePoolPage *parent;   // 8 字节，前一个 page
    AutoreleasePoolPage *child;    // 8 字节，后一个 page
    uint32_t const depth;          // 4 字节，page 深度（第几个 page）
    uint32_t hiwat;                // 4 字节，历史最大对象数量 high water mark
    // ... 其他成员
};
```

**Page 内存布局**（4096 字节）：

```
AutoreleasePoolPage 内存分布（4096 字节 = 4KB）：
┌─────────────────────────────────┐
│  头部（Header）                 │ ← 成员变量占用约 56 字节
│  ┌───────────────────────────┐  │
│  │ magic (4)                 │  │
│  │ next (8)                  │  │
│  │ thread (8)                │  │
│  │ parent (8)                │  │
│  │ child (8)                 │  │
│  │ depth (4)                 │  │
│  │ hiwat (4)                 │  │
│  │ 对齐填充                   │  │
│  └───────────────────────────┘  │
├─────────────────────────────────┤
│  栈区（Stack Area）              │ ← 存放 autorelease 对象指针
│  一个指针 8 字节                  │
│  每添加一个 [obj autorelease]    │
│  就 push 一个 obj 的地址到栈顶    │
│  next 指向下一个空闲槽位          │
│                                  │
│  可用空间 ≈ 4096 - 56 ≈ 4040 字节│
│  可存放对象数 ≈ 4040 / 8 ≈ 505   │
├─────────────────────────────────┤
│  哨兵对象（POOL_BOUNDARY）        │
│  @autoreleasepool {} 入栈时      │
│  插入一个 POOL_BOUNDARY 作为边界  │
└─────────────────────────────────┘
```

**关键数据结构**：

```cpp
// AutoreleasePoolPage 的大小
static size_t const SIZE = 4096;                     // 固定 4KB
static size_t const COUNT = SIZE / sizeof(id);       // 约 512 个对象指针
static id *const EMPTY = (id *)begin();              // 空池起始位置
static id *const END = (id *)(begin() + SIZE);       // page 末尾

// 哨兵对象：nil 的别名，用于标记 @autoreleasepool 的边界
# define POOL_BOUNDARY nil
```

### 7.3 push / pop 机制

```cpp
// @autoreleasepool {} 编译后对应两个函数调用

// ① 入口：push 一个哨兵
void *objc_autoreleasePoolPush() {
    return AutoreleasePoolPage::push();
}

// push 内部逻辑：
//   1. 如果当前 page 满了，创建新 page
//   2. 插入一个 POOL_BOUNDARY（nil）作为标记
//   3. 返回 POOL_BOUNDARY 的地址作为 token

// ② 出口：pop 到哨兵位置
void objc_autoreleasePoolPop(void *ctxt) {
    AutoreleasePoolPage::pop(ctxt);
}

// pop 内部逻辑：
//   1. 从栈顶开始，给每个对象发送 release 消息
//   2. 一直 pop 到 token（POOL_BOUNDARY）位置
//   3. 如果当前 page 空了，释放该 page
```

**嵌套 AutoreleasePool 的栈结构**：

```
栈顶（最新加入的对象）
┌─────────────────────────┐
│  obj 3（最新 autorelease）│
│  obj 2                   │
│  obj 1                   │
│  POOL_BOUNDARY ← 内部 pool 边界│
│  obj B                   │
│  obj A                   │
│  POOL_BOUNDARY ← 外部 pool 边界│ ← 栈底（最早加入）
└─────────────────────────┘

@autoreleasepool {              ← 外部 pool，push 了一个 POOL_BOUNDARY
    [objA autorelease];         ← push
    [objB autorelease];         ← push
    @autoreleasepool {          ← 内部 pool，又 push 了一个 POOL_BOUNDARY
        [obj1 autorelease];     ← push
        [obj2 autorelease];     ← push
        [obj3 autorelease];     ← push
    }                           ← pop 到内部 POOL_BOUNDARY：释放 obj1,2,3
}                               ← pop 到外部 POOL_BOUNDARY：释放 objA,objB
```

### 7.4 Page 扩容机制

```
创建第一个 @autoreleasepool：
  page1 创建（堆上分配 4096 字节）
  ↓
  往 page1 中 push 对象...
  ↓
  page1 满了（可用空间 < 8 字节）
  ↓
  创建 page2
  page1.child = page2
  page2.parent = page1
  ↓
  继续往 page2 中 push 对象...
  ↓
  page2 也满了...
  ↓
  创建 page3（以此类推）
```

**每个 AutoreleasePoolPage 在堆上分配 4096 字节，可用存储对象指针的空间约 4040 字节，约可存放 505 个对象**。超过后创建新的 page。

### 7.5 AutoreleasePool 的运行时机

```
RunLoop 一次循环：
① 启动 RunLoop → 创建 AutoreleasePool
② 处理事件（触摸、定时器等）
③ BeforeWaiting → 销毁旧的 AutoreleasePool，创建新的
④ 休眠
⑤ 被唤醒 → 回到 ②
```

**主线程的 AutoreleasePool**：
- 每次 RunLoop 循环创建和销毁一次 Pool
- 如果在一行代码中创建了大量临时对象（如 for 循环），建议手动加 `@autoreleasepool {}`

### 7.6 AutoreleasePool 具体的创建时间

#### App 启动时

App 启动后，主线程 RunLoop 开启前，系统在 `UIApplicationMain` 函数中创建了**第一个** AutoreleasePool：

```objc
// main.m 中
int main(int argc, char * argv[]) {
    @autoreleasepool {  // ← 这是 App 的第一个 AutoreleasePool
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
```

**这个 Pool 覆盖了整个 App 的生命周期**，但它只是兜底的——真正起作用的 RunLoop 会在每个循环中创建和销毁自己的 Pool。

#### RunLoop 中的创建时机

RunLoop 通过 `_CFRunLoopAutoreleasePool` 这个 Observer 来管理 Pool 的创建和销毁。

```objc
// RunLoop 注册了两个 Observer 来管理 AutoreleasePool：
// Observer 1: _CFRunLoopAutoreleasePoolPush — 优先级 0x7FFFFFFF（最低优先级）
// Observer 2: _CFRunLoopAutoreleasePoolPop  — 优先级 0x7FFFFFFF（最低优先级）
```

**具体创建和销毁的时机由 RunLoop Activity 触发**：

```
RunLoop Activity 触发时序：
                                                                AutoreleasePool
  kCFRunLoopEntry （进入 RunLoop）
    ↓
    _objc_autoreleasePoolPush()                              → 创建 Pool
    ↓
  kCFRunLoopBeforeTimers （即将处理 Timer）
    ↓
  kCFRunLoopBeforeSources （即将处理 Source）
    ↓
    （处理事件：触摸、点击、网络回调等）
    ↓
  kCFRunLoopBeforeWaiting （即将休眠）
    ↓
    _objc_autoreleasePoolPop() + _objc_autoreleasePoolPush() → 销毁旧 Pool，创建新 Pool
    ↓
  kCFRunLoopAfterWaiting （被唤醒）
    ↓
    （处理 Timer、Source1 等）
    ↓
  kCFRunLoopExit （退出 RunLoop）
    ↓
    _objc_autoreleasePoolPop()                               → 销毁 Pool
```

**关键点**：

```
时机 1：kCFRunLoopEntry
  → 系统自动调用 objc_autoreleasePoolPush()
  → 创建一个新的 AutoreleasePool
  → 这个 Pool 用于管理本次循环中产生的 autorelease 对象

时机 2：kCFRunLoopBeforeWaiting
  → 系统自动调用 objc_autoreleasePoolPop() + objc_autoreleasePoolPush()
  → 先释放当前 Pool 中的所有对象
  → 再创建新的 Pool 用于下一轮循环
  → 这是最频繁的 Pool 创建/销毁时机

时机 3：kCFRunLoopExit
  → 系统自动调用 objc_autoreleasePoolPop()
  → 销毁当前的 Pool
  → 通常发生在线程结束时
```

#### 子线程的情况

```objc
// ❌ 子线程默认没有 AutoreleasePool
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    // 如果创建了 autorelease 对象，不会自动释放！
    UIImage *image = [UIImage imageNamed:@"large"];  // 不会释放 → 泄漏！
});

// ✅ 子线程需要手动创建 AutoreleasePool
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    @autoreleasepool {
        UIImage *image = [UIImage imageNamed:@"large"];  // 池结束时释放
    }
});
```

#### 总结

| 时机 | 调用的方法 | 创建/销毁 | 说明 |
|------|-----------|-----------|------|
| App 启动 | `main()` 中的 `@autoreleasepool` | 创建 | App 的第一个兜底 Pool |
| `kCFRunLoopEntry` | `objc_autoreleasePoolPush()` | 创建 | 每次 RunLoop 循环开始 |
| `kCFRunLoopBeforeWaiting` | `pop + push` | **销毁旧 + 创建新** | 最频繁的时机 |
| `kCFRunLoopExit` | `objc_autoreleasePoolPop()` | 销毁 | RunLoop 退出时 |
| 子线程 | 无 | 无 | 需要手动创建 `@autoreleasepool` |
| 手动 `@autoreleasepool {}` | `push + pop` | 创建 + 销毁 | 由开发者控制 |

```obj-c
// 查看 AutoreleasePool 栈的调试方法
extern void _objc_autoreleasePoolPrint(void);

- (void)viewDidLoad {
    [super viewDidLoad];
    _objc_autoreleasePoolPrint();  // 打印当前 AutoreleasePool 栈
}
```

```objc
// 验证 RunLoop 的 Observer
- (void)printPoolStatus {
    // App 中任意位置调用
    extern void _objc_autoreleasePoolPrint(void);
    _objc_autoreleasePoolPrint();
}
```

```objc
// 手动创建子线程 Pool 的推荐写法
- (void)doHeavyWorkInBackground {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @autoreleasepool {  // 子线程必须手动创建
            for (int i = 0; i < 1000; i++) {
                @autoreleasepool {  // 内部再嵌套，及时释放
                    NSString *str = [NSString stringWithFormat:@"%d", i];
                    // 处理 str
                }
            }
        }
    });
}
```

### 7.6 Autorelease 的返回值优化

```objc
// 系统会自动对方法返回值做优化（通过 objc_autoreleaseReturnValue 和 objc_retainAutoreleasedReturnValue）
// 当方法返回一个 autorelease 对象，且调用方紧接着 retain 时
// 系统会通过 TLS（线程局部存储）优化跳过 autorelease 和 retain，直接传递引用

+ (instancetype)createObject {
    return [[[self alloc] init] autorelease];  // 实际可能不走 autorelease
}

// 调用方
id obj = [SomeClass createObject];  // 这里不会 retain
// 系统通过 TLS 优化，直接传递对象而不走 autorelease pool
```

---

## 八、Tagged Pointer

### 8.1 原理

从 64 位系统开始，iOS 引入 Tagged Pointer 技术，将小对象的**值直接存储在指针中**，而不是在堆中分配内存。

```
普通对象指针（8 字节）：
  0x600000123456 → 指向堆内存中的 NSNumber 对象

Tagged Pointer（8 字节）：
  0x3FF1234       → 指针本身存储了值，不分配堆内存
```

### 8.2 适用场景

| 类型 | 是否使用 Tagged Pointer | 条件 |
|------|------------------------|------|
| `NSNumber` | ✅ | 小整数、布尔值、浮点数 |
| `NSDate` | ✅ | 时间戳 |
| `NSString` | ✅ | 短字符串（如 "abc"） |

**Tagged Pointer 的特点**：
- 指针本身存值，**不在堆中分配内存**
- **没有引用计数**（不需要 retain/release）
- `objc_msgSend` 可以直接从指针中提取值，节省调用开销
- 性能比普通对象高很多

**判断一个指针是否为 Tagged Pointer**：
- iOS 平台：最高有效位（第 64 位）为 1
- macOS 平台：最低有效位为 1

---

## 九、NSCache

### 9.1 NSCache vs NSDictionary

| 对比项 | NSCache | NSDictionary |
|--------|---------|-------------|
| **线程安全** | ✅ 自带 | ❌ 需加锁 |
| **自动回收** | ✅ 内存紧张时自动清理 | ❌ 不会 |
| **Key 拷贝** | ❌ 不拷贝 key（对象引用） | ✅ 会拷贝 key |
| **淘汰策略** | LRU + Cost + Count | 无 |

```objc
// NSCache 使用
NSCache *cache = [[NSCache alloc] init];
cache.countLimit = 100;        // 最大数量
cache.totalCostLimit = 1e8;    // 最大成本（如 100MB）

// 存：cost 按图片像素计算
[cache setObject:image forKey:key cost:size.width * size.height * 4];

// 取
UIImage *image = [cache objectForKey:key];
```

---

## 十、内存泄漏的检测与修复

### 10.1 常见内存泄漏

| 类型 | 说明 | 检测方法 |
|------|------|---------|
| **循环引用** | 对象互相持有，无法释放 | Memory Graph / Leaks |
| **NSTimer 未释放** | timer 强引用 target | 检查 invalidate |
| **通知未移除** | iOS 9 后不用手动移除 | 但 iOS 8 仍需 |
| **KVO 未移除** | 观察者已释放但 KVO 未移除 | crash at dealloc |
| **CoreFoundation 对象** | C 语言对象需要手动 CFRelease | Leaks 工具 |
| **内存泄漏的图片** | 大图未释放 | Allocations 工具 |
| **WebView** | WKWebView 可能泄漏 | 单独进程处理 |

### 10.2 dealloc 中必须做的事

```objc
- (void)dealloc {
    [_timer invalidate];            // 停止 NSTimer
    [_link invalidate];             // 停止 CADisplayLink
    [[NSNotificationCenter defaultCenter] removeObserver:self]; // 移除通知
    [self removeObserver:self forKeyPath:@"keyPath"]; // 移除 KVO
    // ARC 中不需要调 [super dealloc]
}
```

### 10.3 检查对象是否释放的方法

```objc
// 方法 1：监听 dealloc
- (void)dealloc {
    NSLog(@"✅ %@ dealloc", NSStringFromClass([self class]));
}

// 方法 2：MLeaksFinder 检测
// pod 'MLeaksFinder'
// 当对象应该释放但未释放时，自动弹窗提示

// 方法 3：Xcode Memory Graph
// Debug → Memory Graph → 搜索类名 → 查看引用链
```

---

## 十一、内存优化

### 11.1 图片内存优化

| 优化 | 做法 | 效果 |
|------|------|------|
| **图片降采样** | 用 ImageIO 解码目标尺寸 | 内存从 48MB → 160KB |
| **子线程解码** | dispatch_async 解码 | 主线程不卡顿 |
| **移除大图的缓存** | NSCache 按 cost 优先淘汰大图 | 总内存可控 |
| **缩略图和原图分开** | 不同场景加载不同尺寸 | 列表场景节省 99% 内存 |

### 11.2 其他优化

```objc
// 1. 懒加载 + 及时释放
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.bigImageView.image = nil;  // 页面不可见时释放大图
}

// 2. 复用 Cell / View
// UICollectionView 和 UITableView 的复用机制

// 3. 使用轻量级对象
// 能用 struct 不用 class，能用值类型不用引用类型

// 4. 避免 XIB/Storyboard 加载大图
// XIB 会一次性加载所有图片到内存

// 5. 使用 NSCache 替代 NSDictionary
NSCache *cache = [[NSCache alloc] init];
cache.totalCostLimit = 50 * 1024 * 1024;  // 内存缓存上限 50MB
```

### 11.3 内存警告处理

```objc
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    // 清空图片缓存
    [self.imageCache removeAllObjects];

    // 释放不可见的 View
    for (UIView *view in self.offscreenViews) {
        [view removeFromSuperview];
    }

    // 停止耗时操作
    [self.currentOperation cancel];
}
```

---

## 十二、内存管理面试题

### 1. 什么是循环引用？如何解决？

两个或多个对象互相强引用，导致所有对象都无法释放。解决方案：一端用 `weak` 打破循环。

### 2. weak 指针的实现原理？

`weak` 指针通过 **SideTable 的 weak_table** 管理，对象 dealloc 时会找到所有 weak 指针并置 nil。

### 3. AutoreleasePool 的原理和时机？

基于 `AutoreleasePoolPage` 双向链表实现。主线程在每次 RunLoop 循环的 BeforeWaiting 时释放 Pool。

### 4. 引用计数存储在什么地方？

优先存在 `isa` 指针的 `extra_rc` 位域（16 bit），溢出后存在 `SideTable` 的 `refcnts` 散列表。

### 5. Tagged Pointer 是什么？

将小对象的值直接存在指针中，不分配堆内存，没有引用计数，性能高。

### 6. NSCache 和 NSDictionary 的区别？

NSCache 线程安全、自动回收、不拷贝 key。适合图片缓存。

### 7. __block 在 ARC 和 MRC 下的区别？

- MRC：`__block` 不会 retain 对象，可用于打破循环引用
- ARC：`__block` 会强引用对象，应用 `__weak` 打破循环

### 8. 如何检测内存泄漏？

Xcode Memory Graph、Instruments Leaks、MLeaksFinder、FBRetainCycleDetector。

### 9. dealloc 里必须做什么？

停止 Timer、移除 KVO、移除通知（iOS 9 以下）、置空 delegate（非 ARC）。

### 10. RunLoop 和 AutoreleasePool 的关系？

RunLoop 每次循环开始时创建 Pool，BeforeWaiting 时销毁 Pool，进入下一次循环时创建新 Pool。
