//
//  NormalTips.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/7/2.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "NormalTips.h"

@interface NormalTips ()

@property (nonatomic, assign) NSInteger money;
@property (nonatomic, assign) NSInteger count;

@end

@implementation NormalTips

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.money = 100;
        self.count = 15;
    }
    return self;
}
//存取钱问题
- (void)bankMoney {
    
    dispatch_queue_t queue = dispatch_queue_create("bankmoney", DISPATCH_QUEUE_CONCURRENT);
    
    //存5次钱
    dispatch_async(queue, ^{
        for (NSInteger i = 0; i < 5; i ++) {
            [self saveMoney];
        }
    });
    
    //取5次钱
    dispatch_async(queue, ^{
        for (NSInteger i = 0; i < 5; i ++) {
            [self withdrawMoney];
        }
    });
    
}

- (void)saveMoney {
    [self locklessSaveMoney]; //无锁
}

- (void)withdrawMoney {
    [self locklessWithdrawMoney];  //无锁
}

//没有加锁的存钱
- (void)locklessSaveMoney {
    NSInteger money = self.money;
    sleep(.2);
    money += 50;
    self.money = money;
    NSLog(@"还剩%ld多少钱: %@", self.money, [NSThread currentThread]);
}

//没有加锁的取钱
- (void)locklessWithdrawMoney {
    NSInteger money = self.money;
    sleep(.2);
    money -= 20;
    self.money = money;
    NSLog(@"还剩%ld多少钱: %@", self.money, [NSThread currentThread]);
}

/**********************************************************************************************/

//卖票问题
- (void)sellTickets {
    
    dispatch_queue_t queue = dispatch_queue_create("sellTicket", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        
        for (NSInteger i = 0; i < 5; i ++) {
            [self sellOneTicket];
        }
    });
    
    dispatch_async(queue, ^{
        
        for (NSInteger i = 0; i < 5; i ++) {
            [self sellOneTicket];
        }
    });
    
    dispatch_async(queue, ^{
        
        for (NSInteger i = 0; i < 5; i ++) {
            [self sellOneTicket];
        }
    });
}

- (void)sellOneTicket {
    
    [self locklessSellOneTicket]; //无锁
}

//没有加锁的卖票
- (void)locklessSellOneTicket {
    NSInteger cnt = self.count;
    sleep(.2);
    cnt --;
    self.count = cnt;
    NSLog(@"还剩%ld张票: %@", self.count, [NSThread currentThread]);
}

@end
