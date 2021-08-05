//
//  NSConditionLockDemo.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/7/3.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "NSConditionLockDemo.h"

@interface NSConditionLockDemo ()

@property (nonatomic, strong) NSConditionLock *lock;

@end

@implementation NSConditionLockDemo

- (instancetype)init
{
    self = [super init];
    if (self) {
        //设置条件值1
        self.lock = [[NSConditionLock alloc] initWithCondition:1];
        
    }
    return self;
}

- (void)conditionLockTest {
    [[[NSThread alloc] initWithTarget:self selector:@selector(__third) object:nil] start];
    [[[NSThread alloc] initWithTarget:self selector:@selector(__second) object:nil] start];
    [[[NSThread alloc] initWithTarget:self selector:@selector(__first) object:nil] start];
}


- (void)__first {
    //条件值是1才能进
    [self.lock lockWhenCondition:1];
    
    NSLog(@"%s", __func__);
    
    //退出时设置条件值是2
    [self.lock unlockWithCondition:2];
    
    NSLog(@"__first退出临界区");
}

- (void)__second {
    
    //条件值是2才能进
    [self.lock lockWhenCondition:2];
    
    NSLog(@"%s", __func__);
    
    //退出时设置条件值是3
    [self.lock unlockWithCondition:3];
    
    NSLog(@"__second退出临界区");
}

- (void)__third {
    //条件值是3才能进
    [self.lock lockWhenCondition:3];
    
    NSLog(@"%s", __func__);
    
    [self.lock unlock];
    
    NSLog(@"__third退出临界区");
}
@end
