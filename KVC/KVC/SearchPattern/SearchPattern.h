//
//  SearchPattern.h
//  KVC
//
//  Created by Honey on 2019/4/29.
//  Copyright © 2019 Honey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SearchPattern : NSObject
{
@public
    //第四搜索梯队
    NSString *_name;
    NSString *_isName;
    NSString *name;
    NSString *isName;
    NSString *_interalName;
@private
    NSArray *_interalArray;
    NSSet *_interalSet;
//    NSArray *array;
//    NSMutableArray *mutableArray;
//    NSMutableSet *mutableSet;
//    NSMutableOrderedSet *mutableOrderedSet;
    //    NSMutableArray *_isTest;
}
//@property (nonatomic, strong) NSArray *name;
@end

NS_ASSUME_NONNULL_END
