//
//  AppDelegate.h
//  wtbtest
//
//  Created by Jack Ryder on 19/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WelcomeViewController.h"
#import "ExploreViewController.h"
#import "ViewController.h"
#import "CreateViewController.h"
#import "ExploreVC.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;
@property (strong, nonatomic) WelcomeViewController *welcomeView;
@property (strong, nonatomic) ViewController *testView;
@property (strong, nonatomic) CreateViewController *createView;
@property (strong, nonatomic) ExploreVC *exploreView;

@end

