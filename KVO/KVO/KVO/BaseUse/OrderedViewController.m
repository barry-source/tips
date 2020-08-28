//
//  OrderedViewController.m
//  KVO
//
//  Created by tongshichao on 2020/8/28.
//  Copyright © 2020 Honey. All rights reserved.
//

#import "OrderedViewController.h"

@interface OrderedViewController ()
@property (nonatomic, strong) NSMutableArray *array;
@end

@implementation OrderedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    // 无法监听array的属性
//    [self.array addObserver:self forKeyPath:@"count" options:(NSKeyValueObservingOptionNew) context:nil];
    
    // 设置了NSKeyValueObservingOptionInitial 之后就会立即触发了一个NSKeyValueChangeSetting类型的通知
    [self addObserver:self forKeyPath:@"array" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial context:nil];
}

//typedef NS_ENUM(NSUInteger, NSKeyValueChange) {
//    NSKeyValueChangeSetting = 1,
//    NSKeyValueChangeInsertion = 2,
//    NSKeyValueChangeRemoval = 3,
//    NSKeyValueChangeReplacement = 4,
//};

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context {
    NSInteger kind = [change[@"kind"] integerValue];
    switch (kind) {
        case NSKeyValueChangeSetting:
            NSLog(@"NSKeyValueChangeSetting");
            break;
        case NSKeyValueChangeInsertion:
            NSLog(@"NSKeyValueChangeInsertion");
            break;
        case NSKeyValueChangeRemoval:
            NSLog(@"NSKeyValueChangeRemoval");
            break;
        case NSKeyValueChangeReplacement:
            NSLog(@"NSKeyValueChangeReplacement");
            break;
    }
    NSLog(@"%@", change);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    static NSInteger i = 0;
    NSMutableArray *tempArray = [self mutableArrayValueForKey:@"array"];
    switch (i % 4) { // add
        case 0:
            [tempArray addObject:@"1"];
            break;
        case 1:  // replace
            [tempArray replaceObjectAtIndex:0 withObject:@"2"];
            break;
        case 2: // remove
            [tempArray removeObjectAtIndex:0];
            break;
        case 3:
            [tempArray removeAllObjects]; // 不会触发通知
            break;
        default:
            break;
    }
    i ++;
}


- (NSMutableArray *)array {
    if (!_array) {
        _array = [NSMutableArray array];
    }
    return _array;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"array"];
}

@end
