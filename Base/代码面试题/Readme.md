# 打印题

一、考察串行队列，同步，死锁等

```
dispatch_queue_t queue = dispatch_queue_create("com.dispatch.serial", DISPATCH_QUEUE_SERIAL);
    
NSLog(@"1");
    
dispatch_async(queue, ^{
    NSLog(@"2");
});
NSLog(@"3");
dispatch_sync(queue, ^{
    NSLog(@"4");
});
```

答案： 打印顺序 1 3 2 4 

1 3 4 的顺序可以确定，queue是串行队列，已经开了一个异步任务2，所以4要等2处理完成才能处理，所以2 在4前

二、考虑消息查找机制

```
///////////////
#import "Person.h"

@implementation Person

- (void)test {
        
}

@end

////////////////////

@interface Son : Person
@end

////////////////////

#import "Son.h"
#import <objc/runtime.h>

@implementation Son

+ (void)load {
    Method originalM = class_getInstanceMethod([self class], @selector(test));
    Method exchangeM = class_getInstanceMethod([self class], @selector(newTest));
    method_exchangeImplementations(originalM, exchangeM);
}

-(void)newTest {
    [self newTest];
}

@end

/////// 下面有问题吗
// son 是Person的子类
Person *p = [Person new];
[p test];
Son *s = [Son new];
[s test];
```
答案： [p test] 会崩溃，[s test]不会产生递归，因为交换了方法的实现

三、考察线程runloop未自动开启

```

dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
       
dispatch_async(queue, ^{
    
    NSLog(@"1");
    
    [self performSelector:@selector(testAction2) withObject:nil afterDelay:0];
     
    NSLog(@"2");
    
});

- (void)testAction2 {
    
    NSLog(@"3");
    
}
```

答案： 只打印 1 和 2

四、考察子线程runloop问题

```
//结果如何
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSThread *thread = [[NSThread alloc] initWithBlock:^{
        NSLog(@"1");
    }];
    [thread start];
    [self performSelector:@selector(test) onThread:thread withObject:nil  waitUntilDone:YES];
}

- (void)test {
    NSLog(@"2");
}

```
答案： 崩溃

thread start 执行完之后，线程就会被销毁，另一个waitUntilDone会等待线程执行完，但是线程销毁了，也就产生崩溃了

> Terminating app due to uncaught exception 'NSDestinationInvalidException', reason: '*** -[ViewController performSelector:onThread:withObject:waitUntilDone:modes:]: target thread exited while waiting for the perform'

如果改成NO,不会产生崩溃，但是因为perform依赖runloop，所以2也不会打印

五、barrier

```
dispatch_queue_t queue = dispatch_queue_create("com.dispatch.serial", DISPATCH_QUEUE_CONCURRENT);
    
dispatch_async(queue, ^{
    NSLog(@"1");
});
    
dispatch_barrier_async(queue, ^{
    NSLog(@"2");
});
    
dispatch_barrier_async(queue, ^{
    NSLog(@"3");
});
    
dispatch_async(queue, ^{
    NSLog(@"4");
});
```

答案： 1  2  3 4 

barrier2 也阻塞barrier3

六、

```
- (void)testGCD {
    //并发队列
    dispatch_queue_t queue = dispatch_queue_create("zxy", DISPATCH_QUEUE_CONCURRENT);
    NSLog(@"1");
    dispatch_async(queue, ^{
        NSLog(@"2");
        dispatch_async(queue, ^{
            NSLog(@"3");
        });
        NSLog(@"4");
    });
    NSLog(@"5");
}
```

答案： 正常打印是 1 5 2 4 3，但是因为是异步，这个结果不是准确的，，，

七、死锁

```
dispatch_queue_t queue = dispatch_queue_create("zxy", DISPATCH_QUEUE_SERIAL);
    NSLog(@"1");
    dispatch_async(queue, ^{
        NSLog(@"2");
        // 异步任务中开启同步任务
        dispatch_sync(queue, ^{
            NSLog(@"3");
        });
        NSLog(@"4");
    });
    NSLog(@"5");
```