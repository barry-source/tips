//
//  Animal+Function2.m
//  Category
//
//  Created by TSC on 2020/9/21.
//  Copyright © 2020 TSC. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

#import "Animal+Function2.h"

@implementation Animal (Function2)

+ (void)load {
    NSLog(@"Function2 --- load");
}

- (void)run {
    NSLog(@"Function2 --- run");
}

@end
