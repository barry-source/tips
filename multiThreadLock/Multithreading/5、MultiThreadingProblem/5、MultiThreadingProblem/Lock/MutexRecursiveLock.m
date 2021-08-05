//
//  MutexRecursiveLock.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/7/2.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "MutexRecursiveLock.h"
#import <pthread.h>

@interface MutexRecursiveLock ()

@property (nonatomic, assign) pthread_mutex_t lock;

@end


@implementation MutexRecursiveLock

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self __initLock:&_lock];
        
    }
    return self;
}

- (void)__initLock:(pthread_mutex_t *)lock {
    
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
//    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);//死锁
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(lock, &attr);
    pthread_mutexattr_destroy(&attr);
    
}

- (void)recursiveTest {
    
    static NSInteger count = 0;
    
    pthread_mutex_lock(&_lock);
    
    if (count < 8) {
        count ++;
        NSLog(@"%s", __func__);
        [self recursiveTest];
    }
    
    pthread_mutex_unlock(&_lock);
    
}

- (void)dealloc {
    pthread_mutex_destroy(&_lock);
}
@end
