//
//  LockViewController.h
//  5、MultiThreadingProblem
//
//  Created by 童世超 on 2018/7/3.
//  Copyright © 2018年 童世超. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LockViewController : UIViewController

@property (nonatomic, assign) NSInteger type;   //决定执行哪个方法
@property (nonatomic, strong) NSMutableArray *selectorArray;
@property (nonatomic, strong) NSMutableArray *titleArray;

@end
