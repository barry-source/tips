//
//  NSObject+KVOBlock.h
//  OverrideKVO
//
//  Created by Honey on 2019/5/8.
//  Copyright © 2019 Honey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^KVOBlock)(id _Nullable observered, NSString * _Nullable key, id _Nullable newValue, id _Nullable oldValue);

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (KVOBlock)

// 添加观察者
- (void)addObserver:(NSObject *)observer forKey:(NSString *)key options:(NSKeyValueObservingOptions)options block:(KVOBlock)block;
// 删除观察者
- (void)removeObserver:(NSObject *)observer forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
