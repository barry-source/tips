//
//  SellTicketViewController.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/6/29.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "SellTicketViewController.h"
#import "SpinLock.h"
#import "UnfairLock.h"
#import "MutexLock.h"
#import "NSLockDemo.h"
#import "SerialQueueSync.h"
#import "SemaphoreSync.h"

@interface SellTicketViewController ()

@property (nonatomic, strong) SpinLock *spinLock;
@property (nonatomic, strong) UnfairLock *unfairLock;
@property (nonatomic, strong) MutexLock *mutexLock;
@property (nonatomic, strong) NSLockDemo *nslockLock;
@property (nonatomic, strong) SerialQueueSync *serialQueueSync;
@property (nonatomic, strong) SemaphoreSync *semaphoreSync;

@end

@implementation SellTicketViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"卖票问题";
    //自旋锁
//    self.spinLock = [[SpinLock alloc] init];
//    [self.spinLock sellTickets];

//    //不公平锁
//    self.unfairLock = [[UnfairLock alloc] init];
//    [self.unfairLock sellTickets];
    
//    //互斥锁
//    self.mutexLock = [[MutexLock alloc] init];
//    [self.mutexLock sellTickets];
    
//    //mutex对象封装
//    self.nslockLock = [[NSLockDemo alloc] init];
//    [self.nslockLock sellTickets];
    
//    //串行队列保证任务同步
//    self.serialQueueSync = [[SerialQueueSync alloc] init];
//    [self.serialQueueSync sellTickets];
    
    self.semaphoreSync = [[SemaphoreSync alloc] init];
    [self.semaphoreSync sellTickets];
}

@end
