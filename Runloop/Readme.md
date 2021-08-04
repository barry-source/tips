
# Runloop

## 1、RunLoop概念

```
    RunLoop是一个运行循环，保证App能够持续运行，处理各种事件，节省CPU资源，没事处理的时候就进入休眠。
    休眠时由`用户态`进入`内核态`，唤醒时由`内核态`进入`用户态`，另外Runloop是通过内部维护一个事件循环来对事件、消息进行管理的一个对象。
```
    
### 休眠

![休眠.png](https://upload-images.jianshu.io/upload_images/1846524-5c77b99db0334f30.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 唤醒

![唤醒.png](https://upload-images.jianshu.io/upload_images/1846524-297cf7a508193585.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 官方解释图：

![Runloop.png](https://upload-images.jianshu.io/upload_images/1846524-a44da9a25c20ea95.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



## 2、结构

通常所说的RunLoop指的是NSRunloop或者CFRunloopRef：

- CFRunLoopRef 是在 CoreFoundation 框架内的，它提供了纯 C 函数的 API，所有这些 API 都是线程安全的。
- NSRunLoop 是基于 CFRunLoopRef 的封装，提供了面向对象的 API，但是这些 API 不是线程安全的。


#### 2.1、 Runloop获取

Foundation：

    [NSRunloop currentRunLoop];获得当前线程的RunLoop对象 
    [NSRunLoop mainRunLoop];获得主线程的Runloop对象

Core Foundation：

    CFRunLoopGetCurrent();获得当前线程的RunLoop对象
    CFRunLoopGetMain();获得主线程的Runloop对象
    
#### 2.2、Runloop底层结构

```ruby
struct __CFRunLoop {
    /**************
        省略变量
    **************/
    pthread_t _pthread;
    uint32_t _winthread;
    CFMutableSetRef _commonModes;
    CFMutableSetRef _commonModeItems;
    CFRunLoopModeRef _currentMode;
    CFMutableSetRef _modes;
    /**************
        省略变量
    **************/
};

typedef struct __CFRunLoopMode *CFRunLoopModeRef;

struct __CFRunLoopMode {
    /**************
        省略变量
    **************/
    CFStringRef _name;
    CFMutableSetRef _sources0;
    CFMutableSetRef _sources1;
    CFMutableArrayRef _observers;
    CFMutableArrayRef _timers;
    /**************
        省略变量+代码
    **************/
}
```
由上可知：

- 一个 `RunLoop` 包含若干个 `Mode`，每个 `Mode` 又包含若干个 `Source/Timer/Observer`。
每次调用 `RunLoop` 的主函数时，只能指定其中一个 `Mode`，这个`Mode`被称作 `CurrentMode`。
如果需要切换` Mode`，只能退出 `Loop`，再重新指定一个 `Mode` 进入。这样做主要是为了分隔开不同组的 `Source/Timer/Observer`，让其互不影响。

- 每一条线程都有唯一的一个与之对应的RunLoop，从结构中可以发现`pthread_t _pthread`

#### 2.3、Mode 分类

- `kCFRunLoopDefaultMode`: App的默认运行模式，通常主线程是在这个运行模式下运行
- `UITrackingRunLoopMode`: 跟踪用户交互事件（用于 ScrollView 追踪触摸滑动，保证界面滑动时不受其他Mode影响）
- `kCFRunLoopCommonModes`: 伪模式，不是一种真正的运行模式l黑夜包括`kCFRunLoopDefaultMode`和 `UITrackingRunLoopMod`
- `UIInitializationRunLoopMode`：在刚启动App时第进入的第一个Mode，启动完成后就不再使用
- `GSEventReceiveRunLoopMode`：接受系统内部事件，通常用不到

#### 2.4、Input Source

- `_sources0`: 负责App内部事件，由App负责管理触发，例如UITouch事件, performSelector:onThread:
- `_sources1`: 基于Port的线程间通信, 系统事件捕捉
- `_timers`: 基于时间的触发器，上层对应NSTimer，performSelector:withObject:afterDelay:

#### 2.5、observers

作用：

- `用于监听RunLoop的状态`
- `UI刷新（BeforeWaiting）`
- `Autorelease pool（BeforeWaiting`

observers 底层结构如下：

```ruby
struct __CFRunLoopObserver {
    CFRuntimeBase _base;
    pthread_mutex_t _lock;
    CFRunLoopRef _runLoop;
    CFIndex _rlCount;
    CFOptionFlags _activities;        /* immutable */
    CFIndex _order;            /* immutable */
    CFRunLoopObserverCallBack _callout;    /* immutable */
    CFRunLoopObserverContext _context;    /* immutable, except invalidation */
};

// 可观察的类型
/* Run Loop Observer Activities */
typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
    kCFRunLoopEntry = (1UL << 0),
    kCFRunLoopBeforeTimers = (1UL << 1),
    kCFRunLoopBeforeSources = (1UL << 2),
    kCFRunLoopBeforeWaiting = (1UL << 5),
    kCFRunLoopAfterWaiting = (1UL << 6),
    kCFRunLoopExit = (1UL << 7),
    kCFRunLoopAllActivities = 0x0FFFFFFFU
};

```

## 3、源码分析

启动runloop有两种方式：

- CFRunLoopRun
- CFRunLoopRunInMode

两种方式内部都是调用了`CFRunLoopRunSpecific`函数

// 简化，有空再做分析

CFRunLoopRunSpecific 函数如下

```ruby
SInt32 CFRunLoopRunSpecific(CFRunLoopRef rl, CFStringRef modeName, CFTimeInterval seconds, Boolean returnAfterSourceHandled) {     /* DOES CALLOUT */
    CHECK_FOR_FORK();
    if (__CFRunLoopIsDeallocating(rl)) return kCFRunLoopRunFinished;
     // runloop 加锁
    __CFRunLoopLock(rl);
    // 获取当前mode
    CFRunLoopModeRef currentMode = __CFRunLoopFindMode(rl, modeName, false);
    if (NULL == currentMode || __CFRunLoopModeIsEmpty(rl, currentMode, rl->_currentMode)) {
        Boolean did = false;
        if (currentMode) __CFRunLoopModeUnlock(currentMode);
        __CFRunLoopUnlock(rl);
        return did ? kCFRunLoopRunHandledSource : kCFRunLoopRunFinished;
    }
    volatile _per_run_data *previousPerRun = __CFRunLoopPushPerRunData(rl);
    CFRunLoopModeRef previousMode = rl->_currentMode;
    rl->_currentMode = currentMode;
    int32_t result = kCFRunLoopRunFinished;

    // 1、通知观察者，runloop已经进入了kCFRunLoopEntry
    if (currentMode->_observerMask & kCFRunLoopEntry ) __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopEntry);
    // MARK: 这里是实际的runloop流程操作
    result = __CFRunLoopRun(rl, currentMode, seconds, returnAfterSourceHandled, previousMode);
    // 11、通知观察者，runloop已经退出了kCFRunLoopEntry
    if (currentMode->_observerMask & kCFRunLoopExit ) __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopExit);

    __CFRunLoopModeUnlock(currentMode);
    __CFRunLoopPopPerRunData(rl, previousPerRun);
    rl->_currentMode = previousMode;
    
     // runloop 解锁
    __CFRunLoopUnlock(rl);
    return result;
}
```

__CFRunLoopRun 源码过长，删减如下：


```
/* rl, rlm are locked on entrance and exit */
static int32_t __CFRunLoopRun(CFRunLoopRef rl, CFRunLoopModeRef rlm, CFTimeInterval seconds, Boolean stopAfterHandle, CFRunLoopModeRef previousMode) {
    uint64_t startTSR = mach_absolute_time();

    if (__CFRunLoopIsStopped(rl)) {
        __CFRunLoopUnsetStopped(rl);
        return kCFRunLoopRunStopped;
    } else if (rlm->_stopped) {
        rlm->_stopped = false;
        return kCFRunLoopRunStopped;
    }
    
    mach_port_name_t dispatchPort = MACH_PORT_NULL;
    Boolean libdispatchQSafe = pthread_main_np() && ((HANDLE_DISPATCH_ON_BASE_INVOCATION_ONLY && NULL == previousMode) || (!HANDLE_DISPATCH_ON_BASE_INVOCATION_ONLY && 0 == _CFGetTSD(__CFTSDKeyIsInGCDMainQ)));
    if (libdispatchQSafe && (CFRunLoopGetMain() == rl) && CFSetContainsValue(rl->_commonModes, rlm->_name)) dispatchPort = _dispatch_get_main_queue_port_4CF();
    
#if USE_DISPATCH_SOURCE_FOR_TIMERS
    mach_port_name_t modeQueuePort = MACH_PORT_NULL;
    if (rlm->_queue) {
        modeQueuePort = _dispatch_runloop_root_queue_get_port_4CF(rlm->_queue);
        if (!modeQueuePort) {
            CRASH("Unable to get port for run loop mode queue (%d)", -1);
        }
    }
#endif
    
    dispatch_source_t timeout_timer = NULL;
    struct __timeout_context *timeout_context = (struct __timeout_context *)malloc(sizeof(*timeout_context));
    if (seconds <= 0.0) { // instant timeout
        seconds = 0.0;
        timeout_context->termTSR = 0ULL;
    } else if (seconds <= TIMER_INTERVAL_LIMIT) {
        dispatch_queue_t queue = pthread_main_np() ? __CFDispatchQueueGetGenericMatchingMain() : __CFDispatchQueueGetGenericBackground();
        timeout_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
            dispatch_retain(timeout_timer);
        timeout_context->ds = timeout_timer;
        timeout_context->rl = (CFRunLoopRef)CFRetain(rl);
        timeout_context->termTSR = startTSR + __CFTimeIntervalToTSR(seconds);
        dispatch_set_context(timeout_timer, timeout_context); // source gets ownership of context
        dispatch_source_set_event_handler_f(timeout_timer, __CFRunLoopTimeout);
        dispatch_source_set_cancel_handler_f(timeout_timer, __CFRunLoopTimeoutCancel);
        uint64_t ns_at = (uint64_t)((__CFTSRToTimeInterval(startTSR) + seconds) * 1000000000ULL);
        dispatch_source_set_timer(timeout_timer, dispatch_time(1, ns_at), DISPATCH_TIME_FOREVER, 1000ULL);
        dispatch_resume(timeout_timer);
    } else { // infinite timeout
        seconds = 9999999999.0;
        timeout_context->termTSR = UINT64_MAX;
    }

    Boolean didDispatchPortLastTime = true;
    int32_t retVal = 0;
    // 这里处理runloop的逻辑
    do {
#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
        voucher_mach_msg_state_t voucherState = VOUCHER_MACH_MSG_STATE_UNCHANGED;
        voucher_t voucherCopy = NULL;
#endif
        uint8_t msg_buffer[3 * 1024];
#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
        mach_msg_header_t *msg = NULL;
        mach_port_t livePort = MACH_PORT_NULL;
#endif
        __CFPortSet waitSet = rlm->_portSet;

        __CFRunLoopUnsetIgnoreWakeUps(rl);

        // 2. 通知 Observers: RunLoop 即将触发 Timer 回调。
        if (rlm->_observerMask & kCFRunLoopBeforeTimers) __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeTimers);
        
        // 3. 通知 Observers: RunLoop 即将触发 Source0 (非port) 回调。
        if (rlm->_observerMask & kCFRunLoopBeforeSources) __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeSources);

        // 4、 执行被加入的block
        __CFRunLoopDoBlocks(rl, rlm);

        // 5、处理Source0（可能会再次处理Blocks）
        Boolean sourceHandledThisLoop = __CFRunLoopDoSources0(rl, rlm, stopAfterHandle);
        // 如果有Blocks 再次处理block
        if (sourceHandledThisLoop) {
            __CFRunLoopDoBlocks(rl, rlm);
    }

        Boolean poll = sourceHandledThisLoop || (0ULL == timeout_context->termTSR);

        if (MACH_PORT_NULL != dispatchPort && !didDispatchPortLastTime) {
#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
            msg = (mach_msg_header_t *)msg_buffer;
            // 6、如果存在Source1，就跳转到第8步，其实就是标签：handle_msg的事件处理
            if (__CFRunLoopServiceMachPort(dispatchPort, &msg, sizeof(msg_buffer), &livePort, 0, &voucherState, NULL)) {
                goto handle_msg;
            }
#endif
        }

        didDispatchPortLastTime = false;
        
    // 7、通知Observers：开始休眠（等待消息唤醒)
    if (!poll && (rlm->_observerMask & kCFRunLoopBeforeWaiting)) __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeWaiting);
    __CFRunLoopSetSleeping(rl);
    // do not do any user callouts after this point (after notifying of sleeping)

    // Must push the local-to-this-activation ports in on every loop
    // iteration, as this mode could be run re-entrantly and we don't
    // want these ports to get serviced.

    __CFPortSetInsert(dispatchPort, waitSet);
        
    __CFRunLoopModeUnlock(rlm);
    __CFRunLoopUnlock(rl);

    CFAbsoluteTime sleepStart = poll ? 0.0 : CFAbsoluteTimeGetCurrent();

#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
#if USE_DISPATCH_SOURCE_FOR_TIMERS
        do {
            if (kCFUseCollectableAllocator) {
                // objc_clear_stack(0);
                // <rdar://problem/16393959>
                memset(msg_buffer, 0, sizeof(msg_buffer));
            }
            msg = (mach_msg_header_t *)msg_buffer;
            
            __CFRunLoopServiceMachPort(waitSet, &msg, sizeof(msg_buffer), &livePort, poll ? 0 : TIMEOUT_INFINITY, &voucherState, &voucherCopy);
            
            if (modeQueuePort != MACH_PORT_NULL && livePort == modeQueuePort) {
                // Drain the internal queue. If one of the callout blocks sets the timerFired flag, break out and service the timer.
                while (_dispatch_runloop_root_queue_perform_4CF(rlm->_queue));
                if (rlm->_timerFired) {
                    // Leave livePort as the queue port, and service timers below
                    rlm->_timerFired = false;
                    break;
                } else {
                    if (msg && msg != (mach_msg_header_t *)msg_buffer) free(msg);
                }
            } else {
                // Go ahead and leave the inner loop.
                break;
            }
        } while (1);
#else
        if (kCFUseCollectableAllocator) {
            // objc_clear_stack(0);
            // <rdar://problem/16393959>
            memset(msg_buffer, 0, sizeof(msg_buffer));
        }
        msg = (mach_msg_header_t *)msg_buffer;
        __CFRunLoopServiceMachPort(waitSet, &msg, sizeof(msg_buffer), &livePort, poll ? 0 : TIMEOUT_INFINITY, &voucherState, &voucherCopy);
#endif
        
#endif
        
    __CFRunLoopLock(rl);
    __CFRunLoopModeLock(rlm);

    rl->_sleepTime += (poll ? 0.0 : (CFAbsoluteTimeGetCurrent() - sleepStart));

    // Must remove the local-to-this-activation ports in on every loop
    // iteration, as this mode could be run re-entrantly and we don't
    // want these ports to get serviced. Also, we don't want them left
    // in there if this function returns.

    __CFPortSetRemove(dispatchPort, waitSet);
    
    __CFRunLoopSetIgnoreWakeUps(rl);

        // user callouts now OK again
    __CFRunLoopUnsetSleeping(rl);
    // 8、通知Observers：结束休眠（被某个消息唤醒）
    if (!poll && (rlm->_observerMask & kCFRunLoopAfterWaiting)) __CFRunLoopDoObservers(rl, rlm, kCFRunLoopAfterWaiting);

        handle_msg:;
        __CFRunLoopSetIgnoreWakeUps(rl);
        if (MACH_PORT_NULL == livePort) {
            CFRUNLOOP_WAKEUP_FOR_NOTHING();
            // handle nothing
        } else if (livePort == rl->_wakeUpPort) {
            CFRUNLOOP_WAKEUP_FOR_WAKEUP();
            // do nothing on Mac OS
        }
#if USE_DISPATCH_SOURCE_FOR_TIMERS
        else if (modeQueuePort != MACH_PORT_NULL && livePort == modeQueuePort) {
            CFRUNLOOP_WAKEUP_FOR_TIMER();
            if (!__CFRunLoopDoTimers(rl, rlm, mach_absolute_time())) {
                // Re-arm the next timer, because we apparently fired early
                __CFArmNextTimerInMode(rlm, rl);
            }
        }
#endif
    
#if USE_MK_TIMER_TOO
        // 8.1、 处理timer
        else if (rlm->_timerPort != MACH_PORT_NULL && livePort == rlm->_timerPort) {
            CFRUNLOOP_WAKEUP_FOR_TIMER();
            // On Windows, we have observed an issue where the timer port is set before the time which we requested it to be set. For example, we set the fire time to be TSR 167646765860, but it is actually observed firing at TSR 167646764145, which is 1715 ticks early. The result is that, when __CFRunLoopDoTimers checks to see if any of the run loop timers should be firing, it appears to be 'too early' for the next timer, and no timers are handled.
            // In this case, the timer port has been automatically reset (since it was returned from MsgWaitForMultipleObjectsEx), and if we do not re-arm it, then no timers will ever be serviced again unless something adjusts the timer list (e.g. adding or removing timers). The fix for the issue is to reset the timer here if CFRunLoopDoTimers did not handle a timer itself. 9308754
            if (!__CFRunLoopDoTimers(rl, rlm, mach_absolute_time())) {
                // Re-arm the next timer
                __CFArmNextTimerInMode(rlm, rl);
            }
        }
#endif
        // 8.2、 GCD
        else if (livePort == dispatchPort) {
            CFRUNLOOP_WAKEUP_FOR_DISPATCH();
            __CFRunLoopModeUnlock(rlm);
            __CFRunLoopUnlock(rl);
            _CFSetTSD(__CFTSDKeyIsInGCDMainQ, (void *)6, NULL);
            __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__(msg);
            _CFSetTSD(__CFTSDKeyIsInGCDMainQ, (void *)0, NULL);
            __CFRunLoopLock(rl);
            __CFRunLoopModeLock(rlm);
            sourceHandledThisLoop = true;
            didDispatchPortLastTime = true;
        } else {
            CFRUNLOOP_WAKEUP_FOR_SOURCE();
            
            // If we received a voucher from this mach_msg, then put a copy of the new voucher into TSD. CFMachPortBoost will look in the TSD for the voucher. By using the value in the TSD we tie the CFMachPortBoost to this received mach_msg explicitly without a chance for anything in between the two pieces of code to set the voucher again.
            voucher_t previousVoucher = _CFSetTSD(__CFTSDKeyMachMessageHasVoucher, (void *)voucherCopy, os_release);

            // Despite the name, this works for windows handles as well
            CFRunLoopSourceRef rls = __CFRunLoopModeFindSourceForMachPort(rl, rlm, livePort);
            if (rls) {
#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
        mach_msg_header_t *reply = NULL;
        // 8.3、 处理Source1
        sourceHandledThisLoop = __CFRunLoopDoSource1(rl, rlm, rls, msg, msg->msgh_size, &reply) || sourceHandledThisLoop;
        if (NULL != reply) {
            (void)mach_msg(reply, MACH_SEND_MSG, reply->msgh_size, 0, MACH_PORT_NULL, 0, MACH_PORT_NULL);
            CFAllocatorDeallocate(kCFAllocatorSystemDefault, reply);
        }
#endif
        }
            
            // Restore the previous voucher
            _CFSetTSD(__CFTSDKeyMachMessageHasVoucher, previousVoucher, os_release);
            
        } 
#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
        if (msg && msg != (mach_msg_header_t *)msg_buffer) free(msg);
#endif
        
    __CFRunLoopDoBlocks(rl, rlm);
        

    if (sourceHandledThisLoop && stopAfterHandle) {
        retVal = kCFRunLoopRunHandledSource;
    } else if (timeout_context->termTSR < mach_absolute_time()) {
        retVal = kCFRunLoopRunTimedOut;
    } else if (__CFRunLoopIsStopped(rl)) {
        __CFRunLoopUnsetStopped(rl);
        retVal = kCFRunLoopRunStopped;
    } else if (rlm->_stopped) {
        rlm->_stopped = false;
        retVal = kCFRunLoopRunStopped;
    } else if (__CFRunLoopModeIsEmpty(rl, rlm, previousMode)) {
        retVal = kCFRunLoopRunFinished;
    }
        
#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
        voucher_mach_msg_revert(voucherState);
        os_release(voucherCopy);
#endif

    } while (0 == retVal);

    if (timeout_timer) {
        dispatch_source_cancel(timeout_timer);
        dispatch_release(timeout_timer);
    } else {
        free(timeout_context);
    }

    return retVal;
}
```

![Runloop运行流程.png](https://upload-images.jianshu.io/upload_images/1846524-dac90e2f3831b74a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 4、应用



## 参考：

[Runloop](https://blog.csdn.net/xiaoxiaobukuang/article/details/80021616)
