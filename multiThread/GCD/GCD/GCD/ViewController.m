//
//  ViewController.m
//  GCD
//
//  Created by tongshichao on 2021/8/4.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self deadLock1];
//    [self deadLock2];
//    [self interview];
//    [self interview2];
//    [self groupNotify];
//    [self barrierAsync];
//    [self barrierSync];
    [self apply];
}

- (void)deadLock1 {
    NSLog(@"任务1");
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_sync(queue, ^{
        NSLog(@"任务2");
    });
    NSLog(@"任务3");
}

- (void)deadLock2 {
    NSLog(@"任务1");
    dispatch_queue_t queue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        NSLog(@"任务2");
        dispatch_sync(queue, ^{
            NSLog(@"任务3");
        });
    });
}


- (void)interview {
    dispatch_queue_t queue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        NSLog(@"任务1");
        [self performSelector:@selector(selectorMethod) withObject:nil afterDelay:0];
        NSLog(@"任务3");
    });
}


- (void)selectorMethod {
    NSLog(@"任务2");
}

- (void)interview2 {
    NSThread *thread = [[NSThread alloc] initWithBlock:^{
        NSLog(@"任务1");
    }];
    [thread start];
    
    [self performSelector:@selector(selectorMethod) onThread:thread withObject:nil waitUntilDone:NO];
}


- (void)groupNotify {
    NSLog(@"group---begin");
    dispatch_group_t group =  dispatch_group_create();
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
        NSLog(@"group---end");
    });
}


- (void)barrierAsync {
    dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        NSLog(@"任务1");
    });
    dispatch_async(queue, ^{
        NSLog(@"任务2");
    });
    
    dispatch_barrier_async(queue, ^{
        NSLog(@"任务3");
    });
    
    dispatch_async(queue, ^{
        NSLog(@"任务4");
    });
    dispatch_async(queue, ^{
        NSLog(@"任务5");
    });
}

- (void)barrierSync {
    dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        NSLog(@"任务1");
    });
    
    NSLog(@"任务2");
    
    dispatch_barrier_sync(queue, ^{
        NSLog(@"任务3");
    });
    
    NSLog(@"任务4");
    
    dispatch_async(queue, ^{
        NSLog(@"任务5");
    });
}

- (void)apply {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    NSLog(@"apply---begin");
    dispatch_apply(6, queue, ^(size_t index) {
        NSLog(@"%zd---%@",index, [NSThread currentThread]);
    });
    NSLog(@"apply---end");
}


- (void)groupEnterAndLeave {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        NSLog(@"任务1");
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        NSLog(@"任务2");
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"任务3");
    });
}

@end
