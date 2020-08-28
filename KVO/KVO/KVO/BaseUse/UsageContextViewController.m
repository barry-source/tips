//
//  UsageContextViewController.m
//  KVO
//
//  Created by tongshichao on 2020/8/27.
//  Copyright © 2020 Honey. All rights reserved.
//

#import "UsageContextViewController.h"
#import "Person.h"
#import "Account.h"

static void *PersonAccountBalanceContext = &PersonAccountBalanceContext;
static void *PersonAccountInterestRateContext = &PersonAccountInterestRateContext;

@interface UsageContextViewController ()
@property (nonatomic, strong) Person *person;
@property (nonatomic, strong) Account *account;
@end

@implementation UsageContextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [self basicUse];
}

//基本用法
- (void)basicUse {
    self.person = [[Person alloc] init];
    self.account = [[Account alloc] init];
    self.account.balance = 0.0;
    self.account.interestRate = 2.01;
    [self.account addObserver:self forKeyPath:@"balance" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:PersonAccountBalanceContext];
    [self.account addObserver:self forKeyPath:@"interestRate" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:PersonAccountInterestRateContext];
}

// 上一个方法的dealloc
- (void)dealloc {
    if (self.account != nil) {
        [self.account removeObserver:self forKeyPath:@"balance" context:PersonAccountBalanceContext];
        [self.account removeObserver:self forKeyPath:@"interestRate" context:PersonAccountInterestRateContext];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.account.balance = 1.0;
    self.account.interestRate = 3;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == PersonAccountBalanceContext) {
        NSLog(@"PersonAccountBalanceContext");
    } else if (context == PersonAccountInterestRateContext) {
        NSLog(@"PersonAccountInterestRateContext");
    } else {
        //因为没有对象处理这个消息会抛出一个NSInternalInconsistencyException异常
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}
@end
