//
//  Person.m
//  KVC
//
//  Created by Honey on 2019/4/28.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "Person.h"

@implementation Person

- (BOOL)validateName:(id *)ioValue error:(NSError **)outError {
    //这里只判断类型是不是NSString类型，是返回true，否返回false
    NSString *result = (NSString *)*ioValue;
    if ([result isKindOfClass:[NSString class]]) {
        return true;
    }
    NSError *error = [[NSError alloc] initWithDomain:@"0" code:100 userInfo:@{@"info":@"type error"}];
    *outError = error;
    return false;
}

@end
