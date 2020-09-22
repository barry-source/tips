//
//  Animal+Function1.m
//  Category
//
//  Created by TSC on 2020/9/21.
//  Copyright © 2020 TSC. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

#import "Animal+Function1.h"

@implementation Animal (Function1)

- (void)run {
    NSLog(@"Function1 --- run");
}

- (void)animalInstanceMethod {
    NSLog(@"Function1 --- animalInstanceMethod");
}

+ (void)animalClassMethod {
    
}

- (NSInteger)age {
    return 10;
}

- (void)setAge:(NSInteger)age {
    
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [Animal new];
}

@end


