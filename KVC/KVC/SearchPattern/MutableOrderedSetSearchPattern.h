//
//  MutableOrderedSetSearchPattern.h
//  KVC
//
//  Created by Honey on 2019/4/29.
//  Copyright © 2019 Honey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MutableOrderedSetSearchPattern : NSObject
{
    //搜索第三梯队
@public
    NSMutableOrderedSet *internalMutableSet;
    NSMutableOrderedSet *_mutableOrderedSet;
    NSMutableOrderedSet *_isMutableOrderedSet;
    NSMutableOrderedSet *mutableOrderedSet;
    NSMutableOrderedSet *isMutableOrderedSet;
}

@end

NS_ASSUME_NONNULL_END
