//
//  ViewD.m
//  ResponderChain
//
//  Created by Honey on 2019/4/25.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "ViewD.h"

@implementation ViewD

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"ViewD范围内查找");
    NSLog(@"ViewD-->hitTest:withEvent:");
    UIView *view = [super hitTest:point withEvent:event];
    NSLog(@"ViewD-->hitTest:withEvent:-->FirstResponder：%@", view);
    return view;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"ViewD-->pointInside:withEvent:");
    BOOL result = [super pointInside:point withEvent:event];
    NSLog(@"ViewD-->pointInside:withEvent:-->是否包含第一响应者：%d", result);
    return result;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"ViewD -- touchesBegan");
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"ViewD -- touchesEnded");
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"ViewD -- touchesCancelled");
}
@end
