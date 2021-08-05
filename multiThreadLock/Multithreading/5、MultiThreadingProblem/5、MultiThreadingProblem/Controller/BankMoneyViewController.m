//
//  BankMoneyViewController.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/6/29.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "BankMoneyViewController.h"
#import "SpinLock.h"
#import "UnfairLock.h"
#import "MutexLock.h"
#import "NSLockDemo.h"
#import "SemaphoreSync.h"

@interface BankMoneyViewController ()

@property (nonatomic, strong) SpinLock *spinLock;
@property (nonatomic, strong) UnfairLock *unfairLock;
@property (nonatomic, strong) MutexLock *mutexLock;
@property (nonatomic, strong) NSLockDemo *nslockLock;
@property (nonatomic, strong) SemaphoreSync *semaphoreSync;

@end

@implementation BankMoneyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"存取钱问题";
//    self.spinLock = [[SpinLock alloc] init];
//    [self.spinLock bankMoney];
    
//    //不公平锁
//    self.unfairLock = [[UnfairLock alloc] init];
//    [self.unfairLock bankMoney];
    
//    //互斥锁
//    self.mutexLock = [[MutexLock alloc] init];
//    [self.mutexLock bankMoney];
    
//    //mutex对象封装
//    self.nslockLock = [[NSLockDemo alloc] init];
//    [self.nslockLock bankMoney];
    
    self.semaphoreSync = [[SemaphoreSync alloc] init];
    [self.semaphoreSync bankMoney];
    
}

@end
