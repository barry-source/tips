//
//  Proxy1.m
//  Interview03-定时器
//
//  Created by MJ Lee on 2018/6/19.
//  Copyright © 2018年 MJ Lee. All rights reserved.
//

#import "Proxy1.h"

@implementation Proxy1

+ (instancetype)proxyWithTarget:(id)target
{
    Proxy1 *proxy = [[Proxy1 alloc] init];
    proxy.target = target;
    return proxy;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self.target;
}

@end
