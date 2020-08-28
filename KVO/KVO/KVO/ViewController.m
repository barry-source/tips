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
#import "DependentViewController.h"
#import "DeepSearchViewController.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    self.array = [@[@"基本用法", @"Context", @"基本用法-NSMutableArray", @"基本用法-NSMutableSet", @"Key依赖", @"手动触发kvo", @"KVO底层原理"] mutableCopy];
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
            DependentViewController *vc = [[DependentViewController alloc] init];
            [self.navigationController pushViewController:vc animated:true];
            break;
        }
        case 5: {
            ManualViewController *vc = [[ManualViewController alloc] init];
            [self.navigationController pushViewController:vc animated:true];
            break;
        }
        case 6: {
            DeepSearchViewController *vc = [[DeepSearchViewController alloc] init];
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


