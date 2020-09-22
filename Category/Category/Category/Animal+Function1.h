//
//  Animal+Function1.h
//  Category
//
//  Created by TSC on 2020/9/21.
//  Copyright © 2020 TSC. All rights reserved.
//

#import "Animal.h"

NS_ASSUME_NONNULL_BEGIN

@interface Animal (Function1) <NSCopying>

@property (nonatomic, assign) NSInteger age;

- (void)animalInstanceMethod;
+ (void)animalClassMethod;

@end

NS_ASSUME_NONNULL_END
