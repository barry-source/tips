//
//  ViewController.m
//  Interview03-定时器
//
//  Created by MJ Lee on 2018/6/19.
//  Copyright © 2018年 MJ Lee. All rights reserved.
//

#import "ViewController.h"
#import "Proxy.h"
#import "Proxy1.h"

@interface ViewController ()
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[Proxy proxyWithTarget:self] selector:@selector(timerTest) userInfo:nil repeats:YES];
    
    ViewController *vc = [[ViewController alloc] init];
    
    Proxy *proxy1 = [Proxy proxyWithTarget:vc];
    
    Proxy1 *proxy2 = [Proxy1 proxyWithTarget:vc];
    
    NSLog(@"%d %d",
          [proxy1 isKindOfClass:[ViewController class]],
          
          [proxy2 isKindOfClass:[ViewController class]]);
}

- (void)timerTest
{
    NSLog(@"%s", __func__);
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    [self.timer invalidate];
}

@end
