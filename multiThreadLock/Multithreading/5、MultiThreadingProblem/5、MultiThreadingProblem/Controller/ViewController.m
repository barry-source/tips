//
//  ViewController.m
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/6/29.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import "ViewController.h"
#import "SellTicketViewController.h"
#import "BankMoneyViewController.h"
#import "OtherViewController.h"
#import "LockViewController.h"
#import "LockCompareViewController.h"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *titleArray;
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) NSMutableArray *controllerArray;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"多线程";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"test"];
}


- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [@[
                        @[@"各种锁加锁解锁时间对比", @"1、SpinLock自旋锁-----卖票", @"2、unfair_lock-----卖票", @"3、pthread_mutex互斥锁-----卖票", @"4、NSLock-----卖票", @"串行队列-----卖票", @"5、semaphore信号量-----卖票", @"6、synchronized-----卖票"],
                        @[@"SpinLock自旋锁-----存取钱", @"unfair_lock-----存取钱", @"pthread_mutex互斥锁-----存取钱", @"NSLock-----存取钱", @"串行队列-----存取钱", @"semaphore-----存取钱", @"synchronized-----存取钱"],
                        @[@"7、pthread_mutex-----互斥递归锁",  @"8、pthread_cond-----互斥条件锁", @"9、NSRecursiveLock", @"10、NSCondition", @"11、NSConditionLock线程依赖", @"dispatch_semaphore", @"pthread_rwlock_t读写锁", @"dispatch_barrier_async栅栏"]] mutableCopy];

    }
    return _dataArray;
}

- (NSMutableArray *)titleArray {
    if (!_titleArray) {
        _titleArray = [@[@"卖票问题", @"存取钱问题", @"其它锁功能测试"] mutableCopy];
    }
    return _titleArray;
}


- (NSMutableArray *)controllerArray {
    if (!_controllerArray) {
        _controllerArray = [@[@"LockViewController", @"LockViewController", @"LockViewController", @"LockViewController", @"LockViewController", @"LockViewController", @"LockViewController", @"LockViewController" ] mutableCopy];
    }
    return _controllerArray;
}

@end


/****************************************************************************************************/


@interface ViewController (test)<UITableViewDelegate, UITableViewDataSource>

@end

@implementation ViewController (test)

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSString *name = self.controllerArray[indexPath.row];
//
//    Class class = NSClassFromString(name);
//
//    UIViewController *controller = [[class alloc] init];
//    if (![controller isKindOfClass:[LockViewController class]]) return;
//    LockViewController *c = (LockViewController *)controller;
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        LockCompareViewController *compareController = [sb instantiateViewControllerWithIdentifier:@"LockCompareViewController"];
        [self.navigationController pushViewController:compareController animated:true];
        return;
    }
    
    LockViewController *c = [[LockViewController alloc] init];

    c.type = indexPath.row;
    if (indexPath.section == 0) {
        c.type --;
    }
    
    switch (indexPath.section) {
        case 0:     //卖票
            c.selectorArray = [@[@"spinLockTicketTest", @"unfairLockTicketTest", @"mutexLockTicketTest", @"NSLockTicketTest", @"serialQueueTicketTest", @"semaphoreTicketTest", @"synchronizedTicketTest"] mutableCopy];
            c.titleArray = [self.dataArray[indexPath.section] mutableCopy];
            break;
        case 1:     //存取钱
            c.selectorArray = [@[@"spinLockMoneyTest", @"unfairLockMoneyTest", @"mutexLockMoneyTest", @"NSLockMoneyTest", @"serialQueueMoneyTest", @"semaphoreMoneyTest", @"synchronizedMoneyTest"] mutableCopy];
            c.titleArray = [self.dataArray[indexPath.section] mutableCopy];
            break;
        case 2:     //其它
            c.selectorArray = [@[@"recursiveLockTest", @"conditionLockTest", @"NSRecursiveLockTest", @"NSConditionTest", @"NSConditionLockTest", @"semaphoreMaxConcurrentCount", @"readWriteLock", @"barrierRWLock"] mutableCopy];
            c.titleArray = [self.dataArray[indexPath.section] mutableCopy];
//            c.titleArray = [@[@"互斥递归锁测试", @"互斥条件锁测试", @"NSRecursiveLock", @"NSCondition", @"NSConditionLock", @"semaphore最大并发数", @"pthread_rwlock_t读写锁"] mutableCopy];
            break;
        default:
            break;
    }

    [self.navigationController pushViewController:c animated:true];

}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataArray[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"test"];
    
    cell.textLabel.text = _dataArray[indexPath.section][indexPath.row];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.titleArray[section];
}
@end
