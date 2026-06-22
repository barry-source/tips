# RunLoop 流程分析

基于 CoreFoundation CF-1153.18 源码分析

## 一、RunLoop 入口函数

### 1. CFRunLoopRun()
```c
void CFRunLoopRun(void) {
    int32_t result;
    do {
        result = CFRunLoopRunSpecific(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 1.0e10, false);
        CHECK_FOR_FORK();
    } while (kCFRunLoopRunStopped != result && kCFRunLoopRunFinished != result);
}
```
- 无限循环运行 RunLoop，直到被停止或完成
- 使用 `kCFRunLoopDefaultMode` 模式
- 超时时间设置为 `1.0e10`（几乎无限）

### 2. CFRunLoopRunInMode()
```c
SInt32 CFRunLoopRunInMode(CFStringRef modeName, CFTimeInterval seconds, Boolean returnAfterSourceHandled)
```
- 在指定模式下运行 RunLoop
- 可以设置超时时间和是否在处理完 Source 后返回

### 3. CFRunLoopRunSpecific()
这是核心的入口函数，负责：
- 获取或创建指定的 Mode
- 设置当前 Mode
- 调用核心执行函数 `__CFRunLoopRun()`
- 处理 Mode 的进入和退出通知

## 二、核心执行流程：__CFRunLoopRun()

这是 RunLoop 的核心执行函数，包含完整的事件处理循环。

### 执行流程图

```
┌─────────────────────────────────────┐
│  1. Entry - 通知 Observers          │
│     kCFRunLoopEntry                 │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  2. Before Timers - 通知 Observers │
│     kCFRunLoopBeforeTimers          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  3. Before Sources - 通知 Observers│
│     kCFRunLoopBeforeSources         │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  4. 执行 Blocks                     │
│     __CFRunLoopDoBlocks()           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  5. 处理 Source0                    │
│     __CFRunLoopDoSources0()         │
│     (如果处理了 Source，再次执行    │
│     Blocks)                          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  6. 检查 Source1 (Dispatch Port)   │
│     如果有消息，跳转到 handle_msg   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  7. Before Waiting - 通知 Observers │
│     kCFRunLoopBeforeWaiting         │
│     设置休眠状态                     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  8. 进入休眠等待                     │
│     __CFRunLoopServiceMachPort()    │
│     等待消息唤醒                     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  9. After Waiting - 通知 Observers  │
│     kCFRunLoopAfterWaiting          │
│     被唤醒，处理消息                 │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  10. handle_msg - 处理唤醒事件       │
│      - Timer 触发                    │
│      - GCD Main Queue               │
│      - Source1 事件                  │
│      - 执行 Blocks                   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  11. 检查退出条件                    │
│      - 超时                          │
│      - 被停止                        │
│      - Mode 为空                     │
│      - 处理完 Source 后返回          │
└──────────────┬──────────────────────┘
               │
        ┌──────┴──────┐
        │             │
       否             是
        │             │
        └──────┬──────┘
               │
               ▼
        继续循环或退出
```

## 三、详细步骤分析

### 步骤 1: Entry（进入 RunLoop）
```c
// 在 CFRunLoopRunSpecific 中
if (currentMode->_observerMask & kCFRunLoopEntry) 
    __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopEntry);
```
- 通知所有 Observers：RunLoop 即将进入
- 设置当前 Mode

### 步骤 2: Before Timers（处理 Timer 前）
```c
if (rlm->_observerMask & kCFRunLoopBeforeTimers) 
    __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeTimers);
```
- 通知 Observers：即将处理 Timer 回调

### 步骤 3: Before Sources（处理 Source 前）
```c
if (rlm->_observerMask & kCFRunLoopBeforeSources) 
    __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeSources);
```
- 通知 Observers：即将处理 Source0 回调

### 步骤 4: 执行 Blocks
```c
__CFRunLoopDoBlocks(rl, rlm);
```
- 执行通过 `CFRunLoopPerformBlock()` 添加的 Blocks
- 这些 Blocks 在当前 Mode 下执行

### 步骤 5: 处理 Source0
```c
Boolean sourceHandledThisLoop = __CFRunLoopDoSources0(rl, rlm, stopAfterHandle);
if (sourceHandledThisLoop) {
    __CFRunLoopDoBlocks(rl, rlm);  // 如果处理了 Source，再次执行 Blocks
}
```
- **Source0**：需要手动标记为待处理（signal）的 Source
- 处理所有待处理的 Source0
- 如果处理了 Source，再次执行 Blocks（因为 Source 处理可能添加新的 Blocks）

### 步骤 6: 检查 Source1（Dispatch Port）
```c
if (MACH_PORT_NULL != dispatchPort && !didDispatchPortLastTime) {
    if (__CFRunLoopServiceMachPort(dispatchPort, &msg, sizeof(msg_buffer), &livePort, 0, &voucherState, NULL)) {
        goto handle_msg;  // 如果有消息，直接处理
    }
}
```
- **Source1**：基于 Mach Port 的 Source，可以唤醒 RunLoop
- 检查主队列（GCD）的 Port 是否有消息
- 如果有消息，直接跳转到 `handle_msg` 处理

### 步骤 7: Before Waiting（进入休眠前）
```c
if (!poll && (rlm->_observerMask & kCFRunLoopBeforeWaiting)) 
    __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeWaiting);
__CFRunLoopSetSleeping(rl);
```
- 通知 Observers：RunLoop 即将进入休眠
- 设置休眠状态
- **注意**：只有在 `poll == false` 时才会进入休眠（即没有 Source0 需要处理且没有立即超时）

### 步骤 8: 进入休眠等待
```c
__CFRunLoopServiceMachPort(waitSet, &msg, sizeof(msg_buffer), &livePort, 
    poll ? 0 : TIMEOUT_INFINITY, &voucherState, &voucherCopy);
```
- 调用 `mach_msg()` 等待消息
- `waitSet` 包含所有需要监听的 Port（Timer Port、Dispatch Port、Source1 Ports 等）
- 如果没有消息，线程会在这里休眠，直到：
  - Timer 触发
  - Source1 事件到达
  - GCD Main Queue 有任务
  - 被手动唤醒（`CFRunLoopWakeUp()`）
  - 超时

### 步骤 9: After Waiting（被唤醒后）
```c
__CFRunLoopUnsetSleeping(rl);
if (!poll && (rlm->_observerMask & kCFRunLoopAfterWaiting)) 
    __CFRunLoopDoObservers(rl, rlm, kCFRunLoopAfterWaiting);
```
- 取消休眠状态
- 通知 Observers：RunLoop 被唤醒

### 步骤 10: handle_msg（处理唤醒事件）

根据 `livePort` 判断唤醒原因并处理：

#### 10.1 处理 Timer
```c
else if (rlm->_timerPort != MACH_PORT_NULL && livePort == rlm->_timerPort) {
    CFRUNLOOP_WAKEUP_FOR_TIMER();
    if (!__CFRunLoopDoTimers(rl, rlm, mach_absolute_time())) {
        __CFArmNextTimerInMode(rlm, rl);  // 重新设置下一个 Timer
    }
}
```
- Timer 时间到达，执行所有到期的 Timer 回调
- 如果 Timer 是重复的，重新设置下次触发时间

#### 10.2 处理 GCD Main Queue
```c
else if (livePort == dispatchPort) {
    CFRUNLOOP_WAKEUP_FOR_DISPATCH();
    __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__(msg);
    sourceHandledThisLoop = true;
    didDispatchPortLastTime = true;
}
```
- GCD 主队列有任务需要执行
- 执行主队列中的任务（Block）

#### 10.3 处理 Source1
```c
else {
    CFRunLoopSourceRef rls = __CFRunLoopModeFindSourceForMachPort(rl, rlm, livePort);
    if (rls) {
        sourceHandledThisLoop = __CFRunLoopDoSource1(rl, rlm, rls, msg, msg->msgh_size, &reply) || sourceHandledThisLoop;
        // 发送回复消息
    }
}
```
- 处理基于 Mach Port 的 Source1 事件
- 执行 Source1 的回调函数

#### 10.4 执行 Blocks（处理完事件后）
```c
__CFRunLoopDoBlocks(rl, rlm);
```
- 在处理完 Timer/GCD/Source1 后，再次执行 Blocks
- 因为事件处理可能添加新的 Blocks

### 步骤 11: 检查退出条件

```c
if (sourceHandledThisLoop && stopAfterHandle) {
    retVal = kCFRunLoopRunHandledSource;  // 处理完 Source 后返回
} else if (timeout_context->termTSR < mach_absolute_time()) {
    retVal = kCFRunLoopRunTimedOut;  // 超时
} else if (__CFRunLoopIsStopped(rl)) {
    retVal = kCFRunLoopRunStopped;  // 被停止
} else if (rlm->_stopped) {
    retVal = kCFRunLoopRunStopped;  // Mode 被停止
} else if (__CFRunLoopModeIsEmpty(rl, rlm, previousMode)) {
    retVal = kCFRunLoopRunFinished;  // Mode 为空（没有 Sources/Timers/Observers）
}
```

退出条件：
1. **kCFRunLoopRunHandledSource**：处理完 Source 后返回（`returnAfterSourceHandled = true`）
2. **kCFRunLoopRunTimedOut**：超时
3. **kCFRunLoopRunStopped**：被 `CFRunLoopStop()` 停止
4. **kCFRunLoopRunFinished**：Mode 为空，没有需要处理的事件

### 步骤 12: Exit（退出 RunLoop）
```c
// 在 CFRunLoopRunSpecific 中
if (currentMode->_observerMask & kCFRunLoopExit) 
    __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopExit);
```
- 通知 Observers：RunLoop 即将退出
- 恢复之前的 Mode
- 释放资源

## 四、RunLoop 的组件

### 1. Mode（模式）
- **kCFRunLoopDefaultMode**：默认模式
- **kCFRunLoopCommonModes**：通用模式集合
- 每个 Mode 包含：
  - Sources（Source0 和 Source1）
  - Timers
  - Observers

### 2. Source（事件源）
- **Source0**：需要手动标记为待处理
  - 通过 `CFRunLoopSourceSignal()` 标记
  - 在 RunLoop 中通过 `__CFRunLoopDoSources0()` 处理
- **Source1**：基于 Mach Port，可以唤醒 RunLoop
  - 通过 Port 消息自动唤醒
  - 在 `handle_msg` 中通过 `__CFRunLoopDoSource1()` 处理

### 3. Timer（定时器）
- 基于 Mach Port 或 Dispatch Source
- 在 `handle_msg` 中通过 `__CFRunLoopDoTimers()` 处理
- 支持重复和一次性触发

### 4. Observer（观察者）
- 可以监听 RunLoop 的 6 种状态：
  - `kCFRunLoopEntry`：进入
  - `kCFRunLoopBeforeTimers`：处理 Timer 前
  - `kCFRunLoopBeforeSources`：处理 Source 前
  - `kCFRunLoopBeforeWaiting`：进入休眠前
  - `kCFRunLoopAfterWaiting`：被唤醒后
  - `kCFRunLoopExit`：退出

### 5. Blocks
- 通过 `CFRunLoopPerformBlock()` 添加
- 在当前 Mode 下执行
- 在多个时机执行：处理 Source0 前后、处理事件后

## 五、关键机制

### 1. 休眠机制
- RunLoop 在没有事件时进入休眠，避免 CPU 空转
- 使用 `mach_msg()` 等待 Mach Port 消息
- 被唤醒后继续处理事件

### 2. Mode 切换
- RunLoop 同一时间只能运行在一个 Mode 下
- 切换 Mode 会退出当前循环，重新进入新 Mode

### 3. Common Modes
- 添加到 Common Modes 的 Source/Timer/Observer 会在所有 Common Mode 下生效
- 默认包含 `kCFRunLoopDefaultMode`

### 4. 线程安全
- 使用锁保护 RunLoop 和 Mode 的访问
- `__CFRunLoopLock()` / `__CFRunLoopUnlock()`
- `__CFRunLoopModeLock()` / `__CFRunLoopModeUnlock()`

## 六、实际应用场景

### 1. 主线程 RunLoop
- 处理 UI 事件（Source0）
- 处理 Timer（如 NSTimer）
- 处理 GCD Main Queue 任务
- 处理网络事件（Source1）

### 2. 子线程 RunLoop
- 需要手动创建和运行
- 通常用于后台任务处理
- 可以添加自定义 Source/Timer

### 3. 性能优化
- 使用 Observer 监控 RunLoop 状态
- 检测卡顿（BeforeWaiting 到 AfterWaiting 的时间过长）
- 优化 Timer 的触发时机

## 七、关键函数实现细节

### 1. __CFRunLoopDoBlocks()
```c
static Boolean __CFRunLoopDoBlocks(CFRunLoopRef rl, CFRunLoopModeRef rlm)
```
- 执行所有在当前 Mode 下待执行的 Blocks
- 支持 Common Modes：如果 Block 添加到 Common Modes，会在所有 Common Mode 下执行
- 执行前会解锁，执行后重新加锁，避免死锁
- 返回是否执行了至少一个 Block

### 2. __CFRunLoopDoObservers()
```c
static void __CFRunLoopDoObservers(CFRunLoopRef rl, CFRunLoopModeRef rlm, CFRunLoopActivity activity)
```
- 通知所有监听该 activity 的 Observers
- 先收集所有需要通知的 Observers（避免在遍历时修改数组）
- 解锁后执行回调，避免死锁
- 如果 Observer 不重复（`repeats = false`），执行后自动失效

### 3. __CFRunLoopDoSources0()
```c
static Boolean __CFRunLoopDoSources0(CFRunLoopRef rl, CFRunLoopModeRef rlm, Boolean stopAfterHandle)
```
- 处理所有已标记（signaled）的 Source0
- 按 `order` 排序执行（保证执行顺序）
- 执行前清除 signaled 标志
- 如果 `stopAfterHandle = true`，处理完第一个 Source 后停止
- 返回是否处理了至少一个 Source

### 4. __CFRunLoopDoSource1()
```c
static Boolean __CFRunLoopDoSource1(CFRunLoopRef rl, CFRunLoopModeRef rlm, CFRunLoopSourceRef rls, ...)
```
- 处理 Source1 事件
- 接收 Mach 消息（`mach_msg_header_t`）
- 可以返回回复消息
- 执行前清除 signaled 标志

### 5. __CFRunLoopDoTimers()
```c
static Boolean __CFRunLoopDoTimers(CFRunLoopRef rl, CFRunLoopModeRef rlm, uint64_t limitTSR)
```
- 处理所有到期的 Timer（`_fireTSR <= limitTSR`）
- 先收集所有到期的 Timer，再执行（避免在执行时修改数组）
- 返回是否处理了至少一个 Timer

### 6. __CFRunLoopServiceMachPort()
```c
static Boolean __CFRunLoopServiceMachPort(mach_port_name_t port, mach_msg_header_t **buffer, 
    size_t buffer_size, mach_port_t *livePort, mach_msg_timeout_t timeout, ...)
```
- 核心的休眠和唤醒机制
- 调用 `mach_msg()` 等待 Port 消息
- `timeout` 参数：
  - `0`：立即返回（poll）
  - `TIMEOUT_INFINITY`：无限等待
  - 其他值：超时时间
- 返回是否有消息到达
- `livePort` 返回唤醒的 Port

## 八、重要细节

### 1. 锁的使用
- RunLoop 和 Mode 都有锁保护
- 在执行用户回调前会解锁，避免死锁
- 回调执行后重新加锁

### 2. Source0 vs Source1
- **Source0**：
  - 需要手动调用 `CFRunLoopSourceSignal()` 标记
  - 在 RunLoop 循环中检查并处理
  - 不能主动唤醒 RunLoop
- **Source1**：
  - 基于 Mach Port
  - 可以主动唤醒休眠的 RunLoop
  - 通过 Port 消息自动触发

### 3. Timer 的实现
- 现代实现使用 Dispatch Source（`USE_DISPATCH_SOURCE_FOR_TIMERS`）
- 传统实现使用 Mach Timer Port（`USE_MK_TIMER_TOO`）
- Timer 触发后，RunLoop 被唤醒，在 `handle_msg` 中处理

### 4. GCD 集成
- 主线程 RunLoop 监听 GCD Main Queue 的 Port
- 当 Main Queue 有任务时，RunLoop 被唤醒
- 在 `handle_msg` 中执行 `__CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__()`

### 5. Blocks 的执行时机
Blocks 在以下时机执行：
1. 处理 Source0 前（步骤 4）
2. 处理 Source0 后（如果处理了 Source）
3. 处理完 Timer/GCD/Source1 后（步骤 10.4）

### 6. Mode 为空判断
```c
__CFRunLoopModeIsEmpty(rl, rlm, previousMode)
```
Mode 为空的条件：
- 没有 Sources（Source0 和 Source1）
- 没有 Timers
- 没有 Observers
- 没有 Blocks

### 7. 退出返回值
- `kCFRunLoopRunFinished`：Mode 为空，没有事件需要处理
- `kCFRunLoopRunStopped`：被 `CFRunLoopStop()` 停止
- `kCFRunLoopRunTimedOut`：超时
- `kCFRunLoopRunHandledSource`：处理完 Source 后返回（`returnAfterSourceHandled = true`）

## 九、总结

RunLoop 的核心是一个**事件循环**，它：

1. **等待事件**：在没有事件时休眠，节省 CPU
2. **处理事件**：按顺序处理 Timer、Source0、Source1、Blocks
3. **通知观察者**：在关键节点通知 Observers
4. **模式切换**：支持不同 Mode 下的不同事件集合
5. **优雅退出**：支持超时、停止、完成等多种退出方式

### 设计亮点

1. **高效休眠**：使用 Mach Port 消息机制，避免 CPU 空转
2. **线程安全**：使用锁保护，但在回调前解锁，避免死锁
3. **灵活扩展**：支持自定义 Source、Timer、Observer
4. **模式隔离**：不同 Mode 下的事件互不干扰
5. **性能优化**：按 order 排序执行，支持 Common Modes

RunLoop 的设计使得 iOS/macOS 应用能够高效地处理各种异步事件，同时保持线程的响应性和资源利用效率。理解 RunLoop 的流程对于：
- 性能优化（避免主线程卡顿）
- 理解事件处理机制
- 调试异步问题
- 实现自定义的异步处理逻辑

都非常重要。

