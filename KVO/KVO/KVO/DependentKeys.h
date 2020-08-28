//
//  DependentKeys.h
//  KVO
//
//  Created by Honey on 2019/5/7.
//  Copyright © 2019 Honey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DependentKeys : NSObject

@property (nonatomic, copy) NSString *fullName;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;

@end

NS_ASSUME_NONNULL_END
