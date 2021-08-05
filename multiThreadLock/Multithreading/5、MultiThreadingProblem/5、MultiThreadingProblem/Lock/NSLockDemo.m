//
//  NSLockDemo.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/7/2.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "NSLockDemo.h"

@interface NSLockDemo ()

@property (nonatomic, strong) NSLock *moneyLock;
@property (nonatomic, strong) NSLock *ticketLock;

@end


@implementation NSLockDemo

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.moneyLock = [[NSLock alloc] init];
        self.ticketLock = [[NSLock alloc] init];
        
    }
    return self;
}


- (void)saveMoney {
    
    [self.moneyLock lock];
    
    [super saveMoney];
    
    [self.moneyLock unlock];
    
}

- (void)withdrawMoney {
    
    [self.moneyLock lock];
    
    [super withdrawMoney];
    
    [self.moneyLock unlock];
    
}


- (void)sellOneTicket {
    
    [self.ticketLock lock];
    
    [super sellOneTicket];
    
    [self.ticketLock unlock];
    
}

@end
