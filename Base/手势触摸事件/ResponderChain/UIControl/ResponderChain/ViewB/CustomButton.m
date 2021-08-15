//
//  ButtonB.m
//  ResponderChain
//
//  Created by Honey on 2019/5/14.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "CustomButton.h"

@implementation CustomButton

- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    [super sendAction:action to:target forEvent:event];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event]; //对于UIControl在其内部自动调用beginTrackingWithTouch，下面方法类似调用相应的方法
    NSLog(@"CustomButton -- touchesBegan");
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    NSLog(@"CustomButton -- touchesEnded");
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    NSLog(@"CustomButton -- touchesCancelled");
}

@end
