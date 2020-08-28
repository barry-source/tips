//
//  ManualViewController.m
//  KVO
//
//  Created by tongshichao on 2020/8/27.
//  Copyright © 2020 Honey. All rights reserved.
//

#import "ManualViewController.h"
#import "ManualObject.h"

@interface ManualViewController ()
@property (nonatomic, strong) ManualObject *manual;
@end

@implementation ManualViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [self manualTest];
}

- (void)manualTest {
    self.manual = [[ManualObject alloc] init];
    self.manual.balance = 0.0;
    self.manual.transactions = [NSMutableArray arrayWithObjects:@"1", @"3", @"4", nil];
    [self.manual addObserver:self forKeyPath:@"balance"options:NSKeyValueObservingOptionNew context:nil];
    [self.manual addObserver:self forKeyPath:@"itemChanged"options:NSKeyValueObservingOptionNew context:nil];
    [self.manual addObserver:self forKeyPath:@"transactions"options:NSKeyValueObservingOptionNew context:nil];
}

// 上一个方法的dealloc
- (void)dealloc {
    if (self.manual != nil) {
        [self.manual removeObserver:self forKeyPath:@"balance" context:nil];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // 给itemChanged赋值无法触发kvo，因为内部automaticallyNotifiesObserversForKey 被禁用
    self.manual.itemChanged = 2;
    //setBalance内部手动触发了itemChanged的通知
    self.manual.balance = 1.0;
//    // remove无法接收到通知
//    [self.manual.transactions removeObjectAtIndex:0];
    [self.manual removeTransactionsAtIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"balance"]){
        NSLog(@"ManualObject");
    } else if ([keyPath isEqualToString:@"itemChanged"]) {
        NSLog(@"balance更改的次数:%@", change);
    }  else if ([keyPath isEqualToString:@"transactions"]) {
        NSLog(@"transactions:%@--%@", change, self.manual.transactions);
    }  else {
        //因为没有对象处理这个消息会抛出一个NSInternalInconsistencyException异常
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
    
}

@end
