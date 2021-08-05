//
//  SerialQueueSync.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/7/2.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "SerialQueueSync.h"

@interface SerialQueueSync ()

@property (nonatomic, strong) dispatch_queue_t moneyQueue;
@property (nonatomic, strong) dispatch_queue_t ticketQueue;

@end

@implementation SerialQueueSync

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.moneyQueue = dispatch_queue_create("money", DISPATCH_QUEUE_SERIAL);
        self.ticketQueue = dispatch_queue_create("ticket", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
- (void)saveMoney {
    
    dispatch_sync(self.moneyQueue, ^{
        [super saveMoney];
    });
    
}

- (void)withdrawMoney {
    
    dispatch_sync(self.moneyQueue, ^{
        [super withdrawMoney];
    });

}


- (void)sellOneTicket {
    
    dispatch_sync(self.ticketQueue, ^{
        [super sellOneTicket];
    });
    
}


@end
