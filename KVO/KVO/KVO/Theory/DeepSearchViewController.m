//
//  DeepSearchViewController.m
//  KVO
//
//  Created by tongshichao on 2020/8/28.
//  Copyright © 2020 Honey. All rights reserved.
//

#import "DeepSearchViewController.h"
#import "DeepSearch.h"

@interface DeepSearchViewController ()
@property (nonatomic, strong) DeepSearch *deep;
@end

@implementation DeepSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [self deepSearchTest];
}


- (void)deepSearchTest {
    DeepSearch *x = [[DeepSearch alloc] init];
    DeepSearch *y = [[DeepSearch alloc] init];
    DeepSearch *xy = [[DeepSearch alloc] init];
    DeepSearch *control = [[DeepSearch alloc] init];
    [DeepSearch PrintDescription:@"control" obj:control];
    [x addObserver:x forKeyPath:@"x" options:0 context:NULL];
    [xy addObserver:xy forKeyPath:@"x" options:0 context:NULL];
    [y addObserver:y forKeyPath:@"y" options:0 context:NULL];
    [xy addObserver:xy forKeyPath:@"y" options:0 context:NULL];
    
    [DeepSearch PrintDescription:@"control" obj:control];
    [DeepSearch PrintDescription:@"x" obj:x];
    [DeepSearch PrintDescription:@"y" obj:y];
    [DeepSearch PrintDescription:@"xy" obj:xy];
    
    printf("使用NSObject方法, 正常的 setX 地址: is %p, 重写 setX后的地址: is %p\n",
           [control methodForSelector:@selector(setX:)],
           [x methodForSelector:@selector(setX:)]);
    printf("使用libobjc方法, 正常的 setX 地址: is %p, 重写 setX后的地址: is %p\n",
           method_getImplementation(class_getInstanceMethod(object_getClass(control), @selector(setX:))),
           method_getImplementation(class_getInstanceMethod(object_getClass(x), @selector(setX:))));
}

@end
