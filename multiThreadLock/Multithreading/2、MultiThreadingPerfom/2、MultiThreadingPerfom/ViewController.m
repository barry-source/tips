//
//  ViewController.m
//  2、MultiThreadingPerfom
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

//    [self peformInChildThreading];
    
    [self performInMainThreading];
    
}

//主线程执行perform
- (void)performInMainThreading {
    NSLog(@"任务一");
    //performSelector afterDelay本质是往线程中加入定时器，但是主线程中开启了runloop，也就会执行定时器
    [self performSelector:@selector(test) withObject:nil afterDelay:3.0];
    NSLog(@"任务三");
}

//开启子线程执行perfomr
- (void)peformInChildThreading {
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    
    dispatch_async(queue, ^{
        
        NSLog(@"任务一");
        //performSelector afterDelay本质是往线程中加入定时器，但是子线程中没有开启runloop，也就无法执行定时器
        [self performSelector:@selector(test) withObject:nil afterDelay:3.0];
        NSLog(@"任务三");
        
    });
}


- (void)test {
    NSLog(@"任务二");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
