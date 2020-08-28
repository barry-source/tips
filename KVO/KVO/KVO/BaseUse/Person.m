//
//  Person.m
//  KVO
//
//  Created by Honey on 2019/5/7.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "Person.h"

@implementation Person
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@", change);
}

@end
