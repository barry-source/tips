//
//  ViewController.m
//  SYMTest
//
//  Created by tongshichao on 2023/9/20.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) NSArray *array;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.array = @[ @1 ];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.array[1];
}

@end
