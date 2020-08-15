//
//  TestObject.h
//  MemorySize
//
//  Created by tongshichao on 2020/8/15.
//  Copyright © 2020 tongshichao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((aligned(4)))
@interface TestObject : NSObject 
{
    int p1;
    int p2;
    char p3;
}
@end

NS_ASSUME_NONNULL_END

