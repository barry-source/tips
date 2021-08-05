//
//  SynchronizedDemo.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/7/3.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "SynchronizedDemo.h"

@implementation SynchronizedDemo

//利用synchronized加锁，效率低下
- (void)saveMoney {
    
    @synchronized ([self class]) {
        [super saveMoney];
    }

}

- (void)withdrawMoney {
    
    @synchronized ([self class]) {
        [super withdrawMoney];
    }

}


- (void)sellOneTicket {
    
    static NSObject *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[NSObject alloc] init];
    });
    
    @synchronized (obj) {
        [super sellOneTicket];
    }

}

@end
