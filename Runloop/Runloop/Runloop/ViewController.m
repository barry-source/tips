//
//  ViewController.m
//  Runloop
//
//  Created by tongshichao on 2021/8/4.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [NSRunLoop currentRunLoop];
    CFRunLoopRun()
}


@end
