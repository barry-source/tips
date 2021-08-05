//
//  NSRecursiveLockDemo.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/7/2.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "NSRecursiveLockDemo.h"

@interface NSRecursiveLockDemo ()

@property (nonatomic, strong) NSRecursiveLock *lock;
@end

@implementation NSRecursiveLockDemo

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}
- (void)recursiveTest {
    
    static NSInteger count = 0;
    
    [self.lock lock];
    
    if (count < 8) {
        count ++;
        NSLog(@"%s", __func__);
        [self recursiveTest];
    }
    
    [self.lock unlock];
    
}

@end
