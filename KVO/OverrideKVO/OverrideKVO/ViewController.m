//
//  ViewController.m
//  OverrideKVO
//
//  Created by Honey on 2019/5/8.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "ViewController.h"
#import "TestClass.h"
#import "NSObject+KVOBlock.h"

@interface ViewController ()
@property (nonatomic, strong) TestClass *testClass;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.testClass = [TestClass new];
    [self.testClass addObserver:self forKey:@"message" options:NSKeyValueObservingOptionNew block:^(id  _Nullable observered, NSString * _Nullable key, id  _Nullable oldValue, id  _Nullable newValue) {
        NSLog(@"%@", newValue);
    }];
    self.testClass.message = @"asdf";
    [self.testClass removeObserver:self forKey:@"message"];
    self.testClass.message = @"asdfffff";
    NSLog(@"%@", [self.testClass class]);
}


@end
