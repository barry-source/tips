//
//  ViewController.m
//  ResponderChain
//
//  Created by Honey on 2019/4/25.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "ViewController.h"
#import "CustomButton.h"
#import "ViewD.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet CustomButton *customButton;
@property (weak, nonatomic) IBOutlet ViewD *viewD;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;

    //    [self viewCAndViewDGesture];
    //    [self viewDGesture];

    //    [self controlAddGesture];
    [self controlSuperViewAddGesture];
}

// 测试
// customButton为父视图添加手势测试
- (void)controlSuperViewAddGesture
{
    UITapGestureRecognizer *superTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(superTapGesture:)];
    superTap.cancelsTouchesInView = false;
    [self.customButton.superview addGestureRecognizer:superTap];
}

// customButton添加手势测试
- (void)controlAddGesture
{
    UITapGestureRecognizer *buttonTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonTapGesture:)];
    //    buttonTap.cancelsTouchesInView = false;
    [self.customButton addGestureRecognizer:buttonTap];
}

//
- (void)pureTargetAction
{
    UITapGestureRecognizer *buttonTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonTapGesture:)];
    //    buttonTap.cancelsTouchesInView = false;
    [self.customButton addGestureRecognizer:buttonTap];

    UITapGestureRecognizer *superTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(superTapGesture:)];
    //    superTap.cancelsTouchesInView = false;
    [self.customButton.superview addGestureRecognizer:superTap];
}

// 只为viewD添加手势
- (void)viewDGesture
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDtapGesture:)];
    //    tap.cancelsTouchesInView = false;
    [self.viewD addGestureRecognizer:tap];
}

// 为viewD和其superView --viewC添加手势
- (void)viewCAndViewDGesture
{
    UITapGestureRecognizer *viewDtap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDtapGesture:)];
    viewDtap.cancelsTouchesInView = false;
    //    [self.viewD addGestureRecognizer:viewDtap];

    UITapGestureRecognizer *viewCtap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewCTapGesture:)];
    viewCtap.cancelsTouchesInView = false;
    [self.viewD.superview addGestureRecognizer:viewCtap];
}

- (void)viewCTapGesture:(UITapGestureRecognizer *)tap
{
    NSLog(@"ViewC-- tapGesture");
}

- (void)superTapGesture:(UITapGestureRecognizer *)tap
{
    NSLog(@"ViewB-- tapGesture");
}

/***************************Gesture***************************************************/
- (void)viewDtapGesture:(UITapGestureRecognizer *)tap
{
    NSLog(@"ViewD-- tapGesture");
}

/***************************Target action***************************************************/
- (void)buttonTapGesture:(UITapGestureRecognizer *)tap
{
    NSLog(@"CustomButton-- buttonTapGesture");
}


- (IBAction)customButtonDidClick:(CustomButton *)sender
{
    NSLog(@"CustomButton-- ButtonDidClick");
}

/***************************touches***************************************************/
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"ViewController-- touchesBegan");
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"ViewController-- touchesEnded");
}


@end
