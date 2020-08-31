//
//  MutableArraySearchPattern.h
//  KVC
//
//  Created by Honey on 2019/4/29.
//  Copyright © 2019 Honey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MutableArraySearchPattern : NSObject
{
    //搜索第三梯队
    @public
    NSMutableArray *internalMutableArray;
    NSMutableArray *_mutableArray;
    NSMutableArray *_isMutableArray;
    NSMutableArray *mutableArray;
    NSMutableArray *isMutableArray;
}

@end

NS_ASSUME_NONNULL_END
