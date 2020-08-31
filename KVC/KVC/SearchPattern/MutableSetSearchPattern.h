//
//  MutableSetSearchPattern.h
//  KVC
//
//  Created by Honey on 2019/4/29.
//  Copyright © 2019 Honey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MutableSetSearchPattern : NSObject
{
    //搜索第三梯队
@public
    NSMutableSet *internalMutableSet;
    NSMutableSet *_mutableSet;
    NSMutableSet *_isMutableSet;
    NSMutableSet *mutableSet;
    NSMutableSet *isMutableSet;
}

@end

NS_ASSUME_NONNULL_END
