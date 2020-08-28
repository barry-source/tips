//
//  ViewController.m
//  KVO
//
//  Created by Honey on 2019/5/7.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "ViewController.h"
#import "UsageViewController.h"
#import "UsageContextViewController.h"
#import "ManualViewController.h"
#import "OrderedViewController.h"
#import "UnorderedViewController.h"
#import "Person.h"
#import "Account.h"
#import "ManualObject.h"
#import "DependentKeys.h"
#import "DeepSearch.h"

static void *PersonAccountBalanceContext = &PersonAccountBalanceContext;
static void *PersonAccountInterestRateContext = &PersonAccountInterestRateContext;

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) Person *person;
@property (nonatomic, strong) Account *account;

@property (nonatomic, strong) DependentKeys *dependent;
@property (nonatomic, strong) DeepSearch *deep;

@property (nonatomic, strong) NSMutableArray *array;

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    self.array = [@[@"基本用法", @"Context", @"基本用法-NSMutableArray", @"基本用法-NSMutableSet", @"手动触发kvo", @"手动触发kvo"] mutableCopy];
//    [self manualTest];
//    [self dependentKeysTest];
//    [self deepSearchTest];
}

/************************************************底层探究***********************************************************************/
- (void)deepSearchTest {
    DeepSearch *x = [[DeepSearch alloc] init];
    DeepSearch *y = [[DeepSearch alloc] init];
    DeepSearch *xy = [[DeepSearch alloc] init];
    DeepSearch *control = [[DeepSearch alloc] init];

    [x addObserver:x forKeyPath:@"x" options:0 context:NULL];
    [xy addObserver:xy forKeyPath:@"x" options:0 context:NULL];
    [y addObserver:y forKeyPath:@"y" options:0 context:NULL];
    [xy addObserver:xy forKeyPath:@"y" options:0 context:NULL];

    [DeepSearch PrintDescription:@"control" obj:control];
    [DeepSearch PrintDescription:@"x" obj:x];
    [DeepSearch PrintDescription:@"y" obj:y];
    [DeepSearch PrintDescription:@"xy" obj:xy];

    printf("Using NSObject methods, normal setX: is %p, overridden setX: is %p\n",
           [control methodForSelector:@selector(setX:)],
           [x methodForSelector:@selector(setX:)]);
    printf("Using libobjc functions, normal setX: is %p, overridden setX: is %p\n",
           method_getImplementation(class_getInstanceMethod(object_getClass(control),
                                                            @selector(setX:))),
           method_getImplementation(class_getInstanceMethod(object_getClass(x),
                                                            @selector(setX:))));
}

/************************************************键关联***********************************************************************/
- (void)dependentKeysTest {
    self.dependent = [[DependentKeys alloc] init];
    self.dependent.firstName = @"first";
    self.dependent.lastName = @"last";
    [self.dependent addObserver:self forKeyPath:@"fullName"options:NSKeyValueObservingOptionNew context:nil];
    [self.dependent addObserver:self forKeyPath:@"firstName"options:NSKeyValueObservingOptionNew context:nil];
    [self.dependent addObserver:self forKeyPath:@"lastName"options:NSKeyValueObservingOptionNew context:nil];
}

/***********************************************************************************************************************/


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    self.array = [NSMutableArray array];
    self.account.balance = 1.0;
    self.dependent.lastName = @"aaaa";
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == PersonAccountBalanceContext) {
        NSLog(@"PersonAccountBalanceContext");
    } else if (context == PersonAccountInterestRateContext) {
        NSLog(@"PersonAccountInterestRateContext");
    } else if ([keyPath isEqualToString:@"fullName"])  {
        NSLog(@"fullname:%@--%@", change, self.dependent.fullName);
    }  else if ([keyPath isEqualToString:@"firstName"])  {
        NSLog(@"firstName:%@--%@", change, self.dependent.firstName);
    }  else if ([keyPath isEqualToString:@"lastName"])  {
        NSLog(@"lastName:%@--%@", change, self.dependent.lastName);
    } else {
        //因为没有对象处理这个消息会抛出一个NSInternalInconsistencyException异常
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"test"];
    cell.textLabel.text = self.array[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: {
            UsageViewController *vc = [[UsageViewController alloc] init];
            [self.navigationController pushViewController:vc animated:true];
            break;
        }
        case 1: {
            UsageContextViewController *vc = [[UsageContextViewController alloc] init];
            [self.navigationController pushViewController:vc animated:true];
            break;
        }
        case 2: {
            OrderedViewController *vc = [[OrderedViewController alloc] init];
            [self.navigationController pushViewController:vc animated:true];
            break;
        }
        case 3: {
            UnorderedViewController *vc = [[UnorderedViewController alloc] init];
            [self.navigationController pushViewController:vc animated:true];
            break;
        }
        case 4: {
            ManualViewController *vc = [[ManualViewController alloc] init];
            [self.navigationController pushViewController:vc animated:true];
            break;
        }
        default:
            break;
    }
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:UIScreen.mainScreen.bounds style: UITableViewStylePlain];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"test"];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}
@end


