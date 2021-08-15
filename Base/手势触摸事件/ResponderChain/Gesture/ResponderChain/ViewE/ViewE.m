//
//  ViewE.m
//  ResponderChain
//
//  Created by Honey on 2019/4/25.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "ViewE.h"

@implementation ViewE

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"ViewE范围内查找");
    NSLog(@"ViewE-->hitTest:withEvent:");
    UIView *view = [super hitTest:point withEvent:event];
    NSLog(@"ViewE-->hitTest:withEvent:-->FirstResponder：%@", view);
    return view;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"ViewE-->pointInside:withEvent:");
    BOOL result = [super pointInside:point withEvent:event];
    NSLog(@"ViewE-->pointInside:withEvent:-->是否包含第一响应者：%d", result);
    return result;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"ViewE---touchesBegan");
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"ViewE---touchesEnded");
}
@end
