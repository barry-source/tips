//
//  ViewC.m
//  ResponderChain
//
//  Created by Honey on 2019/4/25.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "ViewC.h"

@implementation ViewC

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"ViewC范围内查找");
    NSLog(@"ViewC-->hitTest:withEvent:");
    UIView *view = [super hitTest:point withEvent:event];
    NSLog(@"ViewC-->hitTest:withEvent:-->FirstResponder：%@", view);
    return view;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"ViewC-->pointInside:withEvent:");
    BOOL result = [super pointInside:point withEvent:event];
    NSLog(@"ViewC-->pointInside:withEvent:-->是否包含第一响应者：%d", result);
    return result;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"ViewC -- touchesBegan");
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"ViewC -- touchesEnded");
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"ViewC -- touchesCancelled");
}

@end
