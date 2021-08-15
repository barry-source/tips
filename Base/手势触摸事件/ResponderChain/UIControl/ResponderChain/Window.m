//
//  Window.m
//  ResponderChain
//
//  Created by Honey on 2019/4/25.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "Window.h"

@implementation Window

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"Window范围内查找");
    NSLog(@"Window-->hitTest:withEvent:");
    UIView *view = [super hitTest:point withEvent:event];
    NSLog(@"Window-->hitTest:withEvent:-->FirstResponder：%@", view);
    return view;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"Window-->pointInside:withEvent:");
    BOOL result = [super pointInside:point withEvent:event];
    NSLog(@"Window-->pointInside:withEvent:-->是否包含第一响应者：%d", result);
    return result;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"Window");
    
}

- (void)sendEvent:(UIEvent *)event {
    [super sendEvent: event];
}
@end
