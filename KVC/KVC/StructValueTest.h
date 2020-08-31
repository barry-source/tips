//
//  StructValueTest.h
//  KVC
//
//  Created by Honey on 2019/4/28.
//  Copyright © 2019 Honey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    float x, y, z;
} ThreeFloats;

NS_ASSUME_NONNULL_BEGIN

@interface StructValueTest : NSObject

@property (nonatomic) ThreeFloats threeFloats;

@end

NS_ASSUME_NONNULL_END
