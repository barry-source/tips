//
//  Account.h
//  KVO
//
//  Created by Honey on 2019/5/7.
//  Copyright © 2019 Honey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Account : NSObject

@property (nonatomic, assign) double balance; //余额
@property (nonatomic, assign) double interestRate; //利率

@end

NS_ASSUME_NONNULL_END
