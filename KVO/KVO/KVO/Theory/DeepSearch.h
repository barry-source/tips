//
//  DeepSearch.h
//  KVO
//
//  Created by Honey on 2019/5/7.
//  Copyright © 2019 Honey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeepSearch : NSObject
@property int x;
@property int y;
@property int z;

+ (NSArray *)ClassMethodNames:(Class) c;
+ (void)PrintDescription:(NSString *)name obj:(id) obj;
@end

NS_ASSUME_NONNULL_END
