//
//  ViewController.m
//  ResponderChain
//
//  Created by Honey on 2019/4/25.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "ViewController.h"
#import "CustomButton.h"
#import "ViewC.h"
#import "ViewD.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet ViewD *viewD;
@property (weak, nonatomic) IBOutlet ViewC *viewC;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;

    // 同时开启手势，父视图手势会被取消
    // 同一个视图如果添加多个相同的手势，最后一个生效
    UITapGestureRecognizer *tapD = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureViewD:)];
    //    tapD.cancelsTouchesInView = false;
    //    tapD.delaysTouchesBegan = true;     // 设置之后began不再被调用
    //    tapD.delaysTouchesEnded = true;
    [self.viewD addGestureRecognizer:tapD];

    UITapGestureRecognizer *tap2D = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureView2D:)];
    [self.viewD addGestureRecognizer:tap2D];

    UITapGestureRecognizer *tapC = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureViewC:)];
    [self.viewC addGestureRecognizer:tapC];
}

- (void)tapGestureView2D:(UITapGestureRecognizer *)tap
{
    NSLog(@"View2D-- tapGestureViewD");
}


- (void)tapGestureViewD:(UITapGestureRecognizer *)tap
{
    NSLog(@"ViewD-- tapGestureViewD");
}

- (void)tapGestureViewC:(UITapGestureRecognizer *)tap
{
    NSLog(@"ViewC-- tapGestureViewC");
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"ViewController-- touchesBegan");
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"ViewController-- touchesEnded");
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"ViewController-- touchesCancelled");
}

- (IBAction)customButtonDidClick:(CustomButton *)sender
{
    NSLog(@"CustomButton");
}


@end
