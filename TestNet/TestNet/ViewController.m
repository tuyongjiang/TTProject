//
//  ViewController.m
//  TestNet
//
//  Created by 涂永江 on 2021/10/26.
//

#import "ViewController.h"
#import <WWHomesViewController.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *btn = [[UIButton alloc] init];
    btn.frame = CGRectMake(0, 100, 100, 100);
    btn.backgroundColor = [UIColor redColor];
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(clik:) forControlEvents:UIControlEventTouchUpInside];
    // Do any additional setup after loading the view.
    
}
- (void)clik:(UIButton *)btn{
    WWHomesViewController *home = [WWHomesViewController new];
    [self.navigationController pushViewController:home animated:YES];
}

@end
