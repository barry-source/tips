//
//  Transaction.h
//  KVC
//
//  Created by Honey on 2019/4/28.
//  Copyright © 2019 Honey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//交易记录
@interface Transaction : NSObject

@property (nonatomic, copy) NSString* payee;   // To whom
@property (nonatomic, strong) NSNumber* amount;  // How much
@property (nonatomic, strong) NSDate* date;      // When

@end

NS_ASSUME_NONNULL_END
