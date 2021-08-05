//
//  DispatchBarrierRWLock.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/7/4.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "DispatchBarrierRWLock.h"

@interface DispatchBarrierRWLock ()

@property (nonatomic, assign) NSInteger count;

@end
@implementation DispatchBarrierRWLock

- (void)barrierRwLockTest {
    self.count = 0;
    //必须创建新队列，不能用全局队列
    dispatch_queue_t queue = dispatch_queue_create(0, DISPATCH_QUEUE_CONCURRENT);
    
    for (NSInteger i = 0 ; i < 10; i ++) {
        
        //测试data race
//        dispatch_async(queue, ^{
//            [self write];
//        });
//
//        dispatch_async(queue, ^{
//            [self read];
//        });
   
        //测试barrier

        dispatch_async(queue, ^{
            [self read];
        });
        dispatch_barrier_async(queue, ^{
            [self write];
        });
        
    }
    
    
}

- (void)read {
    NSLog(@"%s--%ld", __func__, self.count);
    
}

- (void)write {
    
    NSInteger cn = self.count;
    cn ++;
    self.count = cn;
    NSLog(@"%s--%ld", __func__, self.count);

}


@end
