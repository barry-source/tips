//
//  Person.h
//  KVC
//
//  Created by Honey on 2019/4/28.
//  Copyright © 2019 Honey. All rights reserved.
//

#import <Foundation/Foundation.h>

// 个人信息
NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject
{
    @public
//    NSString *name;
    NSString *_name;
    NSArray *array;
    NSMutableArray *mutableArray;
    NSMutableSet *mutableSet;
    NSMutableOrderedSet *mutableOrderedSet;
//    NSMutableArray *_isTest;
}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *address;

@end

NS_ASSUME_NONNULL_END
