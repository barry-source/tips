//
//  ManualObject.h
//  KVO
//
//  Created by Honey on 2019/5/7.
//  Copyright © 2019 Honey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ManualObject : NSObject
@property (nonatomic, assign) double balance; 
@property (nonatomic, assign) int itemChanged;
@property (nonatomic, strong) NSMutableArray *transactions;

- (void)removeTransactionsAtIndexes:(NSIndexSet *)indexes;
@end

NS_ASSUME_NONNULL_END
