//
//  DependentKeys.m
//  KVO
//
//  Created by Honey on 2019/5/7.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "DependentKeys.h"

@implementation DependentKeys

// 只要 firstName 和 lastName 有一个改变就会触发fullName的通知
// 方式 1
//+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
//    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
//    if ([key isEqualToString:@"fullName"]) {
//        NSArray *affectingKeys = @[@"lastName", @"firstName"];
//        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
//    }
//    return keyPaths;
//}

- (NSString *)fullName {
    return [NSString stringWithFormat:@"%@ %@",self.firstName, self.lastName];
}

// 只要 firstName 和 lastName 有一个改变就会触发fullName的通知
// 方式 2
+ (NSSet<NSString *> *)keyPathsForValuesAffectingFullName {
   return [NSSet setWithObjects:@"lastName", @"firstName", nil];
}
@end
