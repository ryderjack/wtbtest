//
//  AppDelegate.m
//  wtbtest
//
//  Created by Jack Ryder on 19/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "NavigationController.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //initial Parse & Fb set up
    
    [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {

        configuration.applicationId = @"jack1234";
        configuration.clientKey = @"jack1234";
        configuration.server = @"http://localhost:1337/parse";
//        configuration.server = @"http://wantobuy.azurewebsites.net/parse";
        
    }]];
    
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    
    //set up tab bar
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.welcomeView = [[WelcomeViewController alloc] init];
    self.testView = [[ViewController alloc] init];
    self.createView = [[CreateViewController alloc]init];
    self.exploreView = [[ExploreVC alloc]init];
    self.profileView = [[ProfileController alloc]init];
        
    [self.window setBackgroundColor:[UIColor whiteColor]];
    
    NavigationController *navController = [[NavigationController alloc] initWithRootViewController:self.exploreView];
    NavigationController *navController1 = [[NavigationController alloc] initWithRootViewController:self.createView];
    NavigationController *navController2 = [[NavigationController alloc] initWithRootViewController:self.profileView];
    NavigationController *navController3 = [[NavigationController alloc] initWithRootViewController:self.welcomeView];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:navController, navController1,navController2,navController3, nil];
    self.tabBarController.tabBar.translucent = NO;
    self.tabBarController.selectedIndex = 0;
    [self.tabBarController.tabBar setTintColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
    
    UITabBarItem *tabBarItem1 = [self.tabBarController.tabBar.items objectAtIndex:0];
    tabBarItem1.image = [UIImage imageNamed:@"exploreTabIcon"];
    tabBarItem1.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    
    UITabBarItem *tabBarItem2 = [self.tabBarController.tabBar.items objectAtIndex:1];
    tabBarItem2.image = [UIImage imageNamed:@"createIcon"];
    tabBarItem2.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    
    UITabBarItem *tabBarItem3 = [self.tabBarController.tabBar.items objectAtIndex:2];
    tabBarItem3.image = [UIImage imageNamed:@"profileIcon"];
    tabBarItem3.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    
    [self.tabBarController setDelegate:self];
    
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation
            ];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
