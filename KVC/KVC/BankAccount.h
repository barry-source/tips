//
//  BankCount.h
//  KVC
//
//  Created by Honey on 2019/4/28.
//  Copyright © 2019 Honey. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Transaction;
@class Person;

NS_ASSUME_NONNULL_BEGIN

//银行账户
@interface BankAccount : NSObject

@property (nonatomic, strong) NSNumber* currentBalance;              // An attribute
@property (nonatomic, strong) Person* owner;                         // A to-one relation
@property (nonatomic, strong) NSArray< Transaction* >* transactions; // A to-many relation

//下面是另外添加的测试数据
@property (nonatomic, assign) NSInteger no;
@end

NS_ASSUME_NONNULL_END
