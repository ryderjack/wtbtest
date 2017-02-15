//
//  AppDelegate.h
//  wtbtest
//
//  Created by Jack Ryder on 19/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WelcomeViewController.h"
#import "CreateViewController.h"
#import "ExploreVC.h"
#import "ProfileController.h"
#import "InboxViewController.h"
#import "BuyNowController.h"
#import "simpleCreateVC.h"
#import "UserProfileController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;
@property (strong, nonatomic) WelcomeViewController *welcomeView;
@property (strong, nonatomic) CreateViewController *createView;
@property (strong, nonatomic) simpleCreateVC *simpleCreateView;
@property (strong, nonatomic) ExploreVC *exploreView;
@property (strong, nonatomic) UserProfileController *profileView;
@property (strong, nonatomic) InboxViewController *inboxView;
@property (nonatomic, strong) PFInstallation *installation;
@property (nonatomic, strong) BuyNowController *buyView;
@property (nonatomic, strong) NSMutableArray *unseenMessages;

@end

