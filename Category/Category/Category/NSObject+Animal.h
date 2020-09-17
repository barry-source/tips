//
//  NSObject+Animal.h
//  Category
//
//  Created by TSC on 2020/9/16.
//  Copyright © 2020 TSC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Animal)<NSCopying>

@property (nonatomic, assign) NSInteger age;

- (void)animalInstanceMethod;
+ (void)animalClassMethod;

@end

NS_ASSUME_NONNULL_END
