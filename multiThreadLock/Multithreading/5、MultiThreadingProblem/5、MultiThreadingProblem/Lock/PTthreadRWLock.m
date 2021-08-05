//
//  PTthreadRWLock.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/7/4.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "PTthreadRWLock.h"
#import <pthread.h>

@interface PTthreadRWLock ()

@property (nonatomic, assign) pthread_rwlock_t lock;

@end

@implementation PTthreadRWLock

- (void)rwLockTest {
    
    //初始化锁
    pthread_rwlock_init(&_lock, NULL);
    
    //必须创建新队列，不能用全局队列
    dispatch_queue_t queue = dispatch_queue_create(0, 0);
    
    for (NSInteger i = 0 ; i < 10; i ++) {
        dispatch_async(queue, ^{
            [self read];
        });
        
        dispatch_async(queue, ^{
            [self write];
        });
    }
    
    
}

- (void)read {
    pthread_rwlock_rdlock(&_lock);
    
    sleep(1);
    NSLog(@"%s", __func__);
    
    pthread_rwlock_unlock(&_lock);
}

- (void)write {
    pthread_rwlock_wrlock(&_lock);
    
    sleep(1);
    NSLog(@"%s", __func__);
    
    pthread_rwlock_unlock(&_lock);
}

- (void)dealloc {
    pthread_rwlock_destroy(&_lock);
}
@end
