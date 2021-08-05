//
//  SemaphoreSync.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/7/3.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "SemaphoreSync.h"

@interface SemaphoreSync ()

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation SemaphoreSync

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)saveMoney {
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    
    [super saveMoney];
    
    dispatch_semaphore_signal(self.semaphore);
    
}

- (void)withdrawMoney {
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    
    [super withdrawMoney];
    
    dispatch_semaphore_signal(self.semaphore);
    
}


- (void)sellOneTicket {
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    
    [super sellOneTicket];
    
    dispatch_semaphore_signal(self.semaphore);
    
}

@end
