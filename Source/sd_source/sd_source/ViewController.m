//
//  ViewController.m
//  sd_source
//
//  Created by user on 2023/5/11.
//

#import "ViewController.h"
#import <SDWebImage/SDWebImage.h>

@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *button;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.imageView = [[UIImageView alloc] init];
    self.imageView.backgroundColor = UIColor.orangeColor;
    self.imageView.frame = CGRectMake(0, 0, 100, 100);
    self.imageView.center = self.view.center;
    [self.view addSubview:self.imageView];

    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    self.button.backgroundColor = UIColor.orangeColor;
    [self.button setTitle:@"加载" forState:UIControlStateNormal];
    [self.button setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    self.button.center = CGPointMake(self.imageView.center.x, CGRectGetMaxY(self.imageView.frame) + 10);
    [self.button sizeToFit];
    [self.button addTarget:self action:@selector(buttonDidClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.button];
}

- (void)buttonDidClick
{
    NSURL *url = [NSURL URLWithString:@"https://scpic.chinaz.net/files/default/imgs/2023-04-14/f9f163d1f77795df.jpg"];
    [self.imageView sd_setImageWithURL:url placeholderImage:nil options:SDWebImageFromCacheOnly context:nil];
}

@end
