//
//  ViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 19/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ViewController.h"
#import <Parse.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "WelcomeViewController.h"
#import "NavigationController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Test";
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //present welcome view
    WelcomeViewController *vc = [[WelcomeViewController alloc]init];
    
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    
    
    [self presentViewController:nav animated:NO completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
