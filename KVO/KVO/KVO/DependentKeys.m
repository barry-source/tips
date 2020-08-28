//
//  DependentKeys.m
//  KVO
//
//  Created by Honey on 2019/5/7.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "DependentKeys.h"

@implementation DependentKeys

//+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
//    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
//    if ([key isEqualToString:@"fullName"]) {
//        NSArray *affectingKeys = @[@"lastName", @"firstName"];
//        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
//    }
//    return keyPaths;
//}

//这里的get方法必须写，这个会自动触发
- (NSString *)fullName {
    return [NSString stringWithFormat:@"%@ %@",self.firstName, self.lastName];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingFullName {
   return [NSSet setWithObjects:@"lastName", @"firstName", nil];
}
@end
