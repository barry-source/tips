//
//  ViewController.m
//  SyncAsync
//
//  Created by 童世超 on 2018/6/28.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

//串行、并发队列：是否有同时执行多个任务的能力
//同步、异步线程：是否有开启新线程的能力，异步不一定会开启新线程，还要看队列


- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self syncFunction];
    
//    [self asnyFunction];
    
//    [self serialQueueSync];
    
//    [self serialAsync];
    
//    [self mainQueueSync];
    
//    [self mainQueueAsync];
    
//    [self serialQueueDeakLock];
    
//    [self serialQueueHandleDeakLock];
    
    [self concurrentQueueHandleDeadLock];
}

//并发队列解死锁
- (void)concurrentQueueHandleDeadLock {
    dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_CONCURRENT);
    
    NSLog(@"任务一: %@", [NSThread currentThread]);
    dispatch_async(queue, ^{
        
        NSLog(@"任务二: %@", [NSThread currentThread]);
        
        dispatch_sync(queue, ^{
            NSLog(@"任务三: %@", [NSThread currentThread]);
        });
        
        NSLog(@"任务四: %@", [NSThread currentThread]);
    });
    
    NSLog(@"任务五: %@", [NSThread currentThread]);
}

//串行队列解死锁
- (void)serialQueueHandleDeakLock {
    dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue2 = dispatch_queue_create("test1", DISPATCH_QUEUE_SERIAL);
    
    NSLog(@"任务一: %@", [NSThread currentThread]);
    dispatch_async(queue, ^{
        
        NSLog(@"任务二: %@", [NSThread currentThread]);
        
        dispatch_sync(queue2, ^{
            NSLog(@"任务三: %@", [NSThread currentThread]);
        });
        
        NSLog(@"任务四: %@", [NSThread currentThread]);
    });
    
    NSLog(@"任务五: %@", [NSThread currentThread]);
}


//串行队列死锁
- (void)serialQueueDeakLock {
    
    //para1: 标识
    //para2: 队列类型  NULL或DISPATCH_QUEUE_SERIAL表示串行队列  DISPATCH_QUEUE_CONCURRENT并发队列
    
    dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL);
    
    NSLog(@"任务一: %@", [NSThread currentThread]);
    dispatch_async(queue, ^{
        
        NSLog(@"任务二: %@", [NSThread currentThread]);
        
        dispatch_sync(queue, ^{
            NSLog(@"任务三: %@", [NSThread currentThread]);
        });
        
        NSLog(@"任务四: %@", [NSThread currentThread]);
    });
    
    NSLog(@"任务五: %@", [NSThread currentThread]);
    
}

//主队列（串行队列）异步，不开启线程，相当于同步执行
- (void)mainQueueAsync {
    NSLog(@"任务一：%@", [NSThread currentThread]);
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    dispatch_async(queue, ^{
        NSLog(@"任务二：%@", [NSThread currentThread]);
    });
    
    NSLog(@"任务三：%@", [NSThread currentThread]);
}

//主队列（串行队列）同步， 死锁
- (void)mainQueueSync {
    NSLog(@"任务一：%@", [NSThread currentThread]);
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    dispatch_sync(queue, ^{
        NSLog(@"任务二：%@", [NSThread currentThread]);
    });
}

//串行队列，异步任务
- (void)serialAsync {
    NSLog(@"任务一：%@", [NSThread currentThread]);
    dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL);
    
    //串行队列，异步任务，只开启一个子线程
    dispatch_async(queue, ^{
        NSLog(@"任务二：%@", [NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"任务三：%@", [NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"任务四：%@", [NSThread currentThread]);
    });
    
}

//串行队列， 同步任务
- (void)serialQueueSync {
    NSLog(@"任务一：%@", [NSThread currentThread]);
    
    dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL);
    
    dispatch_sync(queue, ^{
        NSLog(@"任务二：%@", [NSThread currentThread]);
    });
    
    dispatch_sync(queue, ^{
        NSLog(@"任务三：%@", [NSThread currentThread]);
    });
}

//全局并发队列，异步线程
- (void)asnyFunction {
    NSLog(@"任务一：%@", [NSThread currentThread]);
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    
    dispatch_async(queue, ^{
        NSLog(@"任务二：%@", [NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"任务三：%@", [NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        NSLog(@"任务四：%@", [NSThread currentThread]);
    });

}


//全局并发队列，同步线程
- (void)syncFunction {
    
    
    // para: identifier
    //    __QOS_ENUM(qos_class, unsigned int,
    //       QOS_CLASS_USER_INTERACTIVE
    //       __QOS_CLASS_AVAILABLE(macos(10.10), ios(8.0)) = 0x21,
    //       QOS_CLASS_USER_INITIATED
    //       __QOS_CLASS_AVAILABLE(macos(10.10), ios(8.0)) = 0x19,
    //       QOS_CLASS_DEFAULT
    //       __QOS_CLASS_AVAILABLE(macos(10.10), ios(8.0)) = 0x15,
    //       QOS_CLASS_UTILITY
    //       __QOS_CLASS_AVAILABLE(macos(10.10), ios(8.0)) = 0x11,
    //       QOS_CLASS_BACKGROUND
    //       __QOS_CLASS_AVAILABLE(macos(10.10), ios(8.0)) = 0x09,
    //       QOS_CLASS_UNSPECIFIED
    //       __QOS_CLASS_AVAILABLE(macos(10.10), ios(8.0)) = 0x00,
    //       );
    
    //para: flag  优先级
    //#define DISPATCH_QUEUE_PRIORITY_HIGH 2
    //#define DISPATCH_QUEUE_PRIORITY_DEFAULT 0
    //#define DISPATCH_QUEUE_PRIORITY_LOW (-2)
    //#define DISPATCH_QUEUE_PRIORITY_BACKGROUND INT16_MIN
    
    NSLog(@"任务一:%@", [NSThread currentThread]);
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    
    dispatch_sync(queue, ^{
        NSLog(@"任务二:%@", [NSThread currentThread]);
    });
    
    dispatch_sync(queue, ^{
        NSLog(@"任务三：%@", [NSThread currentThread]);
    });
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
