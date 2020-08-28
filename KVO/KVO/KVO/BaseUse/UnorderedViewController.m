//
//  UnorderedViewController.m
//  KVO
//
//  Created by tongshichao on 2020/8/28.
//  Copyright © 2020 Honey. All rights reserved.
//

#import "UnorderedViewController.h"

@interface UnorderedViewController ()
@property (nonatomic, strong) NSMutableSet *set;
@end

@implementation UnorderedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    // 无法监听set的属性
    //    [self.set addObserver:self forKeyPath:@"count" options:(NSKeyValueObservingOptionNew) context:nil];
    
    // 设置了NSKeyValueObservingOptionInitial 之后就会立即触发了一个NSKeyValueChangeSetting类型的通知
    [self addObserver:self forKeyPath:@"set" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial context:nil];
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
    //##### 注： 数组一定要通过这种方法取出，否则不会触发通知
    NSMutableSet *tempset = [self mutableSetValueForKey:@"set"];
    switch (i % 4) { // add
        case 0:
            [tempset addObject:@"a"];
            break;
        case 1:  // replace
//            [tempset replaceObjectAtIndex:0 withObject:@"2"];
            break;
        case 2: // remove
            [tempset removeObject:@"a"];
            break;
        case 3:
            [tempset removeAllObjects]; // 不会触发通知
            break;
        default:
            break;
    }
    i ++;
}


- (NSMutableSet *)set {
    if (!_set) {
        _set = [NSMutableSet set];
    }
    return _set;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"set"];
}

@end
