//
//  ViewB.m
//  ResponderChain
//
//  Created by Honey on 2019/4/25.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "ViewB.h"

@implementation ViewB

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"ViewB范围内查找");
    NSLog(@"ViewB-->hitTest:withEvent:");
    UIView *view = [super hitTest:point withEvent:event];
    NSLog(@"ViewB-->hitTest:withEvent:-->FirstResponder：%@", view);
    return view;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"ViewB-->pointInside:withEvent:");
    BOOL result = [super pointInside:point withEvent:event];
    NSLog(@"ViewB-->pointInside:withEvent:-->是否包含第一响应者：%d", result);
    return result;
}

@end
