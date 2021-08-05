//
//  NSConditionLockDemo.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/7/2.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "NSConditionDemo.h"

@interface NSConditionDemo ()

@property (nonatomic, strong) NSCondition *lock;
@property (nonatomic, strong) NSMutableArray *dataArray;


@end

@implementation NSConditionDemo

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.lock = [[NSCondition alloc] init];
        self.dataArray = [@[] mutableCopy];
        
    }
    return self;
}

- (void)conditionTest {
    [[[NSThread alloc] initWithTarget:self selector:@selector(__remove) object:nil] start];
    [[[NSThread alloc] initWithTarget:self selector:@selector(__append) object:nil] start];
}


- (void)__remove {
    
    [self.lock lock];
    if (self.dataArray.count == 0) {
        [self.lock wait];
        NSLog(@"__remove接收到信号量");
    }
    
    [self.dataArray removeLastObject];
    NSLog(@"__remove删除数据");
    
    [self.lock unlock];
    NSLog(@"__remove退出临界区");
}

- (void)__append {
    [self.lock lock];
    
    sleep(1);
    
    NSLog(@"__append添加数据");
    [self.dataArray addObject:@"test"];
    
    NSLog(@"__append发送信号");
    //产生数据之后，发送信号
    [self.lock signal];
//    [self.lock broadcast];
    
    NSLog(@"__append发送信号之后");
    
    [self.lock unlock];
    
    NSLog(@"__append退出临界区");
}

@end
