//
//  ViewController.m
//  4、GCDGroup
//
//  Created by 童世超 on 2018/6/29.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

//两个任务执行完之后，再执行最后的任务
- (void)twoConcurrentThreadAndThirdMainThread {
    
    dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, queue, ^{
        for (NSInteger i = 0; i < 5; i ++) {
            NSLog(@"子线程任务一：%@", [NSThread currentThread]);
        }
    });
    
    dispatch_group_async(group, queue, ^{
        for (NSInteger i = 0; i < 5; i ++) {
            NSLog(@"子线程任务二：%@", [NSThread currentThread]);
        }
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        for (NSInteger i = 0; i < 5; i ++) {
            NSLog(@"主线程任务三：%@", [NSThread currentThread]);
        }
        
    });
}

//两个任务执行完之后，再执行另外两个任务
- (void)twoConcurrentThreadAndtwoConcurrentThread {
    dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, queue, ^{
        for (NSInteger i = 0; i < 5; i ++) {
            NSLog(@"子线程任务一：%@", [NSThread currentThread]);
        }
    });
    
    dispatch_group_async(group, queue, ^{
        for (NSInteger i = 0; i < 5; i ++) {
            NSLog(@"子线程任务二：%@", [NSThread currentThread]);
        }
    });
    
    dispatch_group_notify(group, queue, ^{
        for (NSInteger i = 0; i < 5; i ++) {
            NSLog(@"子线程任务三：%@", [NSThread currentThread]);
        }
    });

    dispatch_group_notify(group, queue, ^{
        for (NSInteger i = 0; i < 5; i ++) {
            NSLog(@"子线程任务四：%@", [NSThread currentThread]);
        }
    });
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
//    [self twoConcurrentThreadAndThirdMainThread];
    
    [self twoConcurrentThreadAndtwoConcurrentThread];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
