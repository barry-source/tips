//
//  ViewController.m
//  3、ThreadDestructionTip
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
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)test {
    NSLog(@"任务二");
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {

    
    NSThread *thread = [[NSThread alloc] initWithBlock:^{
        NSLog(@"任务一");

        //开启runloop test可继续执行
//        [[NSRunLoop currentRunLoop] addPort:[NSPort new] forMode:NSDefaultRunLoopMode];
//        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }];
    //线程启动，先执行任务一，执行完毕，线程退出
    [thread start];
    
    //test任务执行在thread线程，但是线程已经退出，导致找不到线程执行test任务，崩溃
    [self performSelector:@selector(test) onThread:thread withObject:nil waitUntilDone:true];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
