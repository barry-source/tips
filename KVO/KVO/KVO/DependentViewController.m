//
//  DependentViewController.m
//  KVO
//
//  Created by tongshichao on 2020/8/28.
//  Copyright © 2020 Honey. All rights reserved.
//

#import "DependentViewController.h"
#import "DependentKeys.h"
#import "Employee.h"
@interface DependentViewController ()
@property (nonatomic, strong) DependentKeys *dependent;
@property (nonatomic, strong) NSMutableArray *employees;
@property (nonatomic, strong) NSNumber *totalSalary;
@end

@implementation DependentViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    Employee *e1 = [[Employee alloc] init];
    Employee *e2 = [[Employee alloc] init];
    Employee *e3 = [[Employee alloc] init];
    e1.salary = 1;
    e2.salary = 2;
    e3.salary = 3;
    self.employees = [NSMutableArray arrayWithArray:@[e1, e2, e3]];
    [self dependentKeysTest1];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    NSMutableArray *tempArray = [self mutableArrayValueForKey:@"employees"];
    static NSInteger i = 0;
    if (i % 2 == 0) {
        Employee *e1 = [[Employee alloc] init];
        e1.salary = 4;
        [tempArray addObject:e1];
    } else {
        [tempArray removeLastObject];
    }
    i ++;
}

- (void)dependentKeysTest1 {
    [self addObserver:self forKeyPath:@"totalSalary" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    // employees的更改出发通知
    [self addObserver:self forKeyPath:@"employees" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"employees"])  {
        [self updateTotalSalary];
    } else if ([keyPath isEqualToString:@"totalSalary"])  {
        NSLog(@"salay 已被更新： %@", self.totalSalary);
    } else {
        //因为没有对象处理这个消息会抛出一个NSInternalInconsistencyException异常
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)updateTotalSalary {
    self.totalSalary = [self valueForKeyPath:@"employees.@sum.salary"];
}

- (void)setTotalSalary:(NSNumber *)newTotalSalary {
    if (_totalSalary != newTotalSalary) {
        [self willChangeValueForKey:@"totalSalary"];
        _totalSalary = newTotalSalary;
        [self didChangeValueForKey:@"totalSalary"];
    }
}
/**********************************************************************************************************************/

//- (void)viewDidLoad {
//    [super viewDidLoad];
//    self.view.backgroundColor = UIColor.whiteColor;
//    [self dependentKeysTest1];
//
//}
//
//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    static NSInteger i = 0;
//    if (i % 2 == 0) {
//        self.dependent.firstName = @"firstName";
//    } else {
//        self.dependent.lastName = @"lastName";
//    }
//    i ++;
//}
//
///************************************************键依赖***********************************************************************/
//- (void)dependentKeysTest1 {
//    self.dependent = [[DependentKeys alloc] init];
//    self.dependent.firstName = @"first";
//    self.dependent.lastName = @"last";
//    [self.dependent addObserver:self forKeyPath:@"fullName"options:NSKeyValueObservingOptionNew context:nil];
//    [self.dependent addObserver:self forKeyPath:@"firstName"options:NSKeyValueObservingOptionNew context:nil];
//    [self.dependent addObserver:self forKeyPath:@"lastName"options:NSKeyValueObservingOptionNew context:nil];
//}
//
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
//    if ([keyPath isEqualToString:@"fullName"])  {
//        NSLog(@"fullname:%@--%@", change, self.dependent.fullName);
//    }  else if ([keyPath isEqualToString:@"firstName"])  {
//        NSLog(@"firstName:%@--%@", change, self.dependent.firstName);
//    }  else if ([keyPath isEqualToString:@"lastName"])  {
//        NSLog(@"lastName:%@--%@", change, self.dependent.lastName);
//    } else {
//        //因为没有对象处理这个消息会抛出一个NSInternalInconsistencyException异常
//        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//    }
//}


@end
