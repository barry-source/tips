## 多读单写

- 读读并发
- 读写互斥
- 写写互斥


```ruby

#import "Person.h"

@interface Person ()

@property (nonatomic, strong) dispatch_queue_t dictQueue;//并发队列
@property (nonatomic, strong) NSMutableDictionary *dict;//可变字典

@end

@implementation Person

- (instancetype)init {
    if(self = [super init]) {
        _dictQueue = dispatch_queue_create("com.huangwenhong.queue", DISPATCH_QUEUE_CONCURRENT);
        _dict = [NSMutableDictionary dictionary];
//        [self conformsToProtocol:NSProxy.self];
    }
    return self;
}

- (id)valueForKey:(NSString *)key {
    id __block obj;
    dispatch_sync(_dictQueue, ^{//因为有数据 return，所以这里是同步调用
        obj = [self.dict valueForKey:key];
    });
    return obj;
}

- (void)setObject:(id)obj forKey:(id<NSCopying>)key {
    //重点：dispatch_barrier_async()，异步栅栏调用；
    //只有提交到并行队列才有意义
    dispatch_barrier_async(_dictQueue, ^{
        [self.dict setObject:obj forKey:key];
    });
}

@end

```

对于 setObject 在这里要不要同步都没什么影响，因为多线程中要取返回值，可能会导致返回值出错的情况这里加了个同步锁


