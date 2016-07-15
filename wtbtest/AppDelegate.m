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
#import "Flurry.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //initial Parse & Fb set up
    
    [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {

        // checks before sending to test:
            //1. server
            //2. tab number
            //3. messaging/offering items to yourself
            //4. push check for non-simulator devices
        
        configuration.applicationId = @"jack1234";
        configuration.clientKey = @"jack1234";
//        configuration.server = @"http://localhost:1337/parse";
        configuration.server = @"http://wantobuy.herokuapp.com/parse";
    }]];

    [Flurry startSession:@"9Y63FGHCCGZQJDQTCTMP"];
//    [Flurry setDebugLogEnabled:YES];
    [Fabric with:@[[Crashlytics class]]];
    
    if ([PFUser currentUser]) {
        [Flurry setUserID:[NSString stringWithFormat:@"%@", [PFUser currentUser].objectId]];
        [self logUser];
    }
    
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    
    //set up tab bar
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.welcomeView = [[WelcomeViewController alloc] init];
    self.createView = [[CreateViewController alloc]init];
    self.exploreView = [[ExploreVC alloc]init];
    self.profileView = [[ProfileController alloc]init];
    self.inboxView = [[InboxViewController alloc]init];
        
    [self.window setBackgroundColor:[UIColor whiteColor]];
    
    NavigationController *navController = [[NavigationController alloc] initWithRootViewController:self.exploreView];
    NavigationController *navController1 = [[NavigationController alloc] initWithRootViewController:self.createView];
    NavigationController *navController2 = [[NavigationController alloc] initWithRootViewController:self.profileView];
    NavigationController *navController3 = [[NavigationController alloc] initWithRootViewController:self.welcomeView];
    NavigationController *navController4 = [[NavigationController alloc] initWithRootViewController:self.inboxView];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:navController, navController1,navController4, navController2, navController3, nil];
    self.tabBarController.tabBar.translucent = NO;
    self.tabBarController.selectedIndex = 0;
//    [self.tabBarController.tabBar setTintColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
    [self.tabBarController.tabBar setTintColor:[UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1]];
    
    UITabBarItem *tabBarItem1 = [self.tabBarController.tabBar.items objectAtIndex:0];
    tabBarItem1.image = [UIImage imageNamed:@"homeIcon"];
    tabBarItem1.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    
    UITabBarItem *tabBarItem2 = [self.tabBarController.tabBar.items objectAtIndex:1];
    tabBarItem2.image = [UIImage imageNamed:@"plusIcon"];
    tabBarItem2.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    
    UITabBarItem *tabBarItem3 = [self.tabBarController.tabBar.items objectAtIndex:2];
    tabBarItem3.image = [UIImage imageNamed:@"messagesIcon2"];
    tabBarItem3.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    
    UITabBarItem *tabBarItem4 = [self.tabBarController.tabBar.items objectAtIndex:3];
    tabBarItem4.image = [UIImage imageNamed:@"profileIcon2"];
    tabBarItem4.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);    
    
    [self.tabBarController setDelegate:self];
    
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    
    self.installation = [PFInstallation currentInstallation];
    if (self.installation.badge == 0) {
        [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:nil];
    }
    else{
        [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:[NSString stringWithFormat:@"%ld", (long)self.installation.badge]];
    }
    
    self.unseenMessages = [[NSMutableArray alloc]init];
        
//    if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications] == NO) {  //commented out for simulator testing purposes
       NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(checkMesages) userInfo:nil repeats:YES];
        [timer fire];
//    }
//    else{
//        [self checkMesages];
//    }

    return YES;
}

- (void) logUser {
    [CrashlyticsKit setUserIdentifier:[NSString stringWithFormat:@"%@", [PFUser currentUser].objectId]];
    [CrashlyticsKit setUserName:[NSString stringWithFormat:@"%@", [PFUser currentUser].username]];
}

//call to check messages if installation badge value doesnt work for ppl who havent enabled push
-(void)checkMesages{
    PFQuery *convosQuery = [PFQuery queryWithClassName:@"convos"];
    [convosQuery whereKey:@"convoId" containsString:[PFUser currentUser].objectId];
    [convosQuery whereKey:@"totalMessages" notEqualTo:@0];
    [convosQuery orderByDescending:@"createdAt"];
    [convosQuery includeKey:@"lastSent"];
    [convosQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (objects) {
                //check if last msg sent is seen
                //if no then retrieves the relevant unseen counter for the user
                //uses that on the tab
                
                [self.unseenMessages removeAllObjects];
                int totalUnseen = 0;
                int unseen = 0;

                for (PFObject *convo in objects) {
                    PFObject *msgObject = [convo objectForKey:@"lastSent"];
                    
                    if ([[msgObject objectForKey:@"status"]isEqualToString:@"sent"] && ![[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                        if (![self.inboxView.selectedConvo isEqualToString:convo.objectId]) {
                            //don't add to tab bar for a selected convo since the added badge could be confusing
                            [self.unseenMessages addObject:convo];
                        }
                        
                        PFUser *buyer = [convo objectForKey:@"buyerUser"];
                        if ([[PFUser currentUser].objectId isEqualToString:buyer.objectId]) {
                            //current user is buyer so other user is seller
                            unseen = [[convo objectForKey:@"buyerUnseen"] intValue];
                        }
                        else{
                            //other user is buyer, current is seller
                            unseen = [[convo objectForKey:@"sellerUnseen"] intValue];
                        }
                        
                        totalUnseen = totalUnseen + unseen;
                        
                        NSLog(@"running total unseen: %d", totalUnseen);
                    }
                }
                
                if (self.unseenMessages.count != 0) {
                    [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:[NSString stringWithFormat:@"%d", totalUnseen]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessage" object:self.unseenMessages];
                }
                else{
                    [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:nil];
                }
            }
            else{
                //no convos
                NSLog(@"no convos");
            }
        }
        else{
            NSLog(@"error getting convos %@", error);
        }
    }];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    [self.installation setDeviceTokenFromData:deviceToken];
    if ([PFUser currentUser]) {
        [self.installation setObject:[PFUser currentUser] forKey:@"user"];
        [self.installation setObject:[PFUser currentUser].objectId forKey:@"userId"];
    }
    self.installation.channels = @[ @"global" ];
    [self.installation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [self checkMesages];
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

//prevent user going back on create VC by tapping tab bar
- (BOOL)tabBarController:(UITabBarController *)theTabBarController shouldSelectViewController:(UIViewController *)viewController
{
    return (theTabBarController.selectedViewController != viewController);
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    // handler code here
    
    NSLog(@"url recieved: %@", url);
    
    return YES;
}

@end
