//
//  UsageViewController.m
//  KVO
//
//  Created by tongshichao on 2020/8/27.
//  Copyright © 2020 Honey. All rights reserved.
//

#import "UsageViewController.h"
#import "Person.h"
#import "Account.h"

@interface UsageViewController ()
@property (nonatomic, strong) Person *person;
@property (nonatomic, strong) Account *account;
@end

@implementation UsageViewController

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
    [self.account addObserver:self forKeyPath:@"balance" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    //    [self.account addObserver:self forKeyPath:@"balance" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)dealloc {
    if (self.account != nil) {
        [self.account removeObserver:self.person forKeyPath:@"balance" context:nil];
    }
}

//####### 点击屏幕操作
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.account.balance = 1.0;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@", change);
}
@end
