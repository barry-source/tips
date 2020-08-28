//
//  ManualObject.m
//  KVO
//
//  Created by Honey on 2019/5/7.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "ManualObject.h"

@implementation ManualObject

//统计更改的次数，只有balance才触发itemChanged
- (void)setBalance:(double)balance {
    [self willChangeValueForKey:@"itemChanged"];
    _balance = balance;
    _itemChanged ++;
    [self didChangeValueForKey:@"itemChanged"];
}

//禁用balance和itemChanged的通知但是可以手动触发
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    BOOL automatic = NO;
    if ([theKey isEqualToString:@"itemChanged"]) {
        automatic = NO;
    } else {
        automatic = [super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}


- (void)removeTransactionsAtIndexes:(NSIndexSet *)indexes {

    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"transactions"];

    // Remove the transaction objects at the specified indexes.
    [self.transactions removeObjectsAtIndexes:indexes];

    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"transactions"];

}

//值相同不发通知
//- (void)setBalance:(double)balance {
//    if (_balance != balance) {
//        [self willChangeValueForKey:@"balance"];
//        _balance = balance;
//        [self didChangeValueForKey:@"balance"];
//    }
//}
////禁用balance的通知但是可以手动触发
//+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
//    BOOL automatic = NO;
//    if ([theKey isEqualToString:@"balance"]) {
//        automatic = NO;
//    } else {
//        automatic = [super automaticallyNotifiesObserversForKey:theKey];
//    }
//    return automatic;
//}

@end
