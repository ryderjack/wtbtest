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
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "iRate.h"
#import <HNKGooglePlacesAutocomplete/HNKGooglePlacesAutocomplete.h>
#import "BumpVC.h"
#import <ChimpKit.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

+ (void)initialize
{
    //configure iRate
    [iRate sharedInstance].daysUntilPrompt = 5;
    [iRate sharedInstance].usesUntilPrompt = 15;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //initial Parse & Fb set up
    
    [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {

        // checks prior to distributing, search for //CHANGE to see major dev changes
        
        configuration.applicationId = @"jack1234";
        configuration.clientKey = @"jack1234";
        //local host
//        configuration.server = @"http://localhost:1337/parse";
        
        //production
//        configuration.server = @"http://parseserver-3q4w2-env.us-east-1.elasticbeanstalk.com/parse";
        
        //preproduction
        configuration.server = @"http://bump-preprod.us-east-1.elasticbeanstalk.com/parse"; ////////////////////CHANGE
    }]];

//    [Fabric with:@[[Crashlytics class]]]; ////////////////////CHANGE
    
    [HNKGooglePlacesAutocompleteQuery setupSharedQueryWithAPIKey:@"AIzaSyC812pR1iegUl3UkzqY0rwYlRmrvAAUbgw"];
    [[ChimpKit sharedKit] setApiKey:@"5cbba863ff961ff8c60266185defc785-us14"];

    if ([PFUser currentUser]) {
        [self logUser];
    }
    else{
        //no current user
    }
    
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    
    //set up tab bar
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.welcomeView = [[WelcomeViewController alloc] init];
    self.createView = [[CreateViewController alloc]init];
    self.exploreView = [[ExploreVC alloc]init];
    self.profileView = [[ProfileController alloc]init];
    self.inboxView = [[InboxViewController alloc]init];
    self.buyView = [[BuyNowController alloc]init];
        
    [self.window setBackgroundColor:[UIColor whiteColor]];
    
    NavigationController *navController = [[NavigationController alloc] initWithRootViewController:self.exploreView];
    NavigationController *navController1 = [[NavigationController alloc] initWithRootViewController:self.createView];
    NavigationController *navController2 = [[NavigationController alloc] initWithRootViewController:self.profileView];
//    NavigationController *navController3 = [[NavigationController alloc] initWithRootViewController:self.welcomeView];
    NavigationController *navController4 = [[NavigationController alloc] initWithRootViewController:self.inboxView];
    NavigationController *navController5 = [[NavigationController alloc] initWithRootViewController:self.buyView];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:navController,navController5,navController1,navController4, navController2, nil];
    self.tabBarController.tabBar.translucent = NO;
    self.tabBarController.selectedIndex = 0;
    [self.tabBarController.tabBar setTintColor:[UIColor whiteColor]];

    [self.tabBarController.tabBar setBarTintColor:[UIColor blackColor]];
    
    UITabBarItem *tabBarItem1 = [self.tabBarController.tabBar.items objectAtIndex:0];
    tabBarItem1.image = [UIImage imageNamed:@"homeIconNEW"];
    tabBarItem1.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    
    UITabBarItem *tabBarItem5 = [self.tabBarController.tabBar.items objectAtIndex:1];
    tabBarItem5.image = [UIImage imageNamed:@"buyNowIcon"];
    tabBarItem5.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    
    UITabBarItem *tabBarItem2 = [self.tabBarController.tabBar.items objectAtIndex:2];
    tabBarItem2.image = [UIImage imageNamed:@"createIconNEW"];
    tabBarItem2.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    
    UITabBarItem *tabBarItem3 = [self.tabBarController.tabBar.items objectAtIndex:3];
    tabBarItem3.image = [UIImage imageNamed:@"messageIconNEW"];
    tabBarItem3.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    
    UITabBarItem *tabBarItem4 = [self.tabBarController.tabBar.items objectAtIndex:4];
    tabBarItem4.image = [UIImage imageNamed:@"userIconNEW"];
    tabBarItem4.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    
    [self.tabBarController setDelegate:self];
    
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    //to prevent app asking immediately for push permissions
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"askedForPushPermission"] || [[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }
    
    self.installation = [PFInstallation currentInstallation];
    if (self.installation.badge == 0) {
        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
    }
    else{
        //if app badge not zero, reset to zero
        self.installation.badge = 0;
        [self.installation saveEventually];
        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
    }
    
    self.unseenMessages = [[NSMutableArray alloc]init];
    
    if ([PFUser currentUser]) {
        if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications] == NO) {
            NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(checkMesages) userInfo:nil repeats:YES];
            [timer fire];
            NSTimer *timer2 = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(checkForTBMessages) userInfo:nil repeats:YES];
            [timer2 fire];
        }
        else{
            [self checkMesages];
            [self checkForTBMessages];
        }
    }
    else{
        NSTimer *timer2 = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(checkForTBMessages) userInfo:nil repeats:YES];
        [timer2 fire];
    }
    
    [iRate sharedInstance].previewMode = NO;
    [iRate sharedInstance].message = @"Enjoying Bump? Please leave us a review or send us some feedback!";
    
    NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notification) {
        NSLog(@"app recieved notification from remote%@",notification);
        [self application:application didReceiveRemoteNotification:notification];
    }else{
        NSLog(@"app did not recieve notification");
    }
    
    //Handle fresh opened from a notification
    NSDictionary *userInfo = [launchOptions valueForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
    
    NSString *bumpedStatus = [userInfo objectForKey:@"bumpRequest"];
    NSString *listing = [userInfo objectForKey:@"listingID"];
    
    NSDictionary *dic = [userInfo objectForKey:@"aps"];
    NSString *strMsg = [dic objectForKey:@"alert"];
    
    if([strMsg containsString:@"bumped your listing"]){
        //open listing
        [Answers logCustomEventWithName:@"Opened listing after receiving Bump Push"
                       customAttributes:@{}];
        
        PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"wantobuys" objectId:listing];
        ListingController *vc = [[ListingController alloc]init];
        vc.listingObject = listingObject;
        
        NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
        [nav pushViewController:vc animated:YES];

    }
    else if([bumpedStatus isEqualToString:@"YES"]){
        //open BumpedVC
        [Answers logCustomEventWithName:@"Opened BumpVC after receiving FB Friend Push"
                       customAttributes:@{}];
        
        BumpVC *vc = [[BumpVC alloc]init];
        vc.listingID = listing;
        [self.window.rootViewController presentViewController:vc animated:YES completion:nil];
    }
    
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
                        
                        [self.unseenMessages addObject:convo];

                        PFUser *buyer = [convo objectForKey:@"buyerUser"];
                    
                        //me IIEf7cUvrO
                    
                        if ([[PFUser currentUser].objectId isEqualToString:buyer.objectId]) {
                            //current user is buyer so other user is seller
                            unseen = [[convo objectForKey:@"buyerUnseen"] intValue];
                            //NSLog(@"unseen buyer %@", [convo objectForKey:@"buyerUnseen"]);

                        }
                        else{
                            //other user is buyer, current is seller
                            unseen = [[convo objectForKey:@"sellerUnseen"] intValue];
                            //NSLog(@"unseen seller %d", unseen);
                        }

                        totalUnseen = totalUnseen + unseen;
                        
//                        NSLog(@"delegate: running total unseen: %d", totalUnseen);
                    }
                }
                
//                NSLog(@"unseen convo's count %lu", (unsigned long)self.unseenMessages.count);
                
                if (self.unseenMessages.count != 0) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessage" object:self.unseenMessages];
                    
                    //remove current convo from array to avoid badge showing for current chat
                    for (PFObject *convoObjs in self.unseenMessages) {
                        if ([self.inboxView.selectedConvo isEqualToString:convoObjs.objectId]) {
                            [self.unseenMessages removeObject:convoObjs];
                        }
                    }
                    
//                    NSLog(@"unseen messages %lu and unseentotal %d and selected convo %@", (unsigned long)self.unseenMessages.count, totalUnseen, self.inboxView.selectedConvo);
                    
                    if (totalUnseen > 0) {
                        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:[NSString stringWithFormat:@"%d", totalUnseen]];
                        self.installation.badge = totalUnseen;
                    }
                    else{
                        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
                        self.installation.badge = 0;
                    }
                    [self.installation saveEventually];
                }
                else{
                    [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
                    self.installation.badge = 0;
                    [self.installation saveEventually];
                }
            }
            else{
                //no convos
//                NSLog(@"no convos");
            }
        }
        else{
            NSLog(@"error getting convos %@", error);
        }
    }];
}

-(void)checkForTBMessages{
    NSLog(@"checking TB messages");
    PFQuery *convosQuery = [PFQuery queryWithClassName:@"teamConvos"];
    [convosQuery whereKey:@"convoId" equalTo: [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId]];
    [convosQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //is there anything unseen in the convo
            int userUnseen = [[object objectForKey:@"userUnseen"]intValue];
            if (userUnseen > 0) {
                [[self.tabBarController.tabBar.items objectAtIndex:4] setBadgeValue:[NSString stringWithFormat:@"%d", userUnseen]];
            }
            else{
                [[self.tabBarController.tabBar.items objectAtIndex:4] setBadgeValue:nil];
            }
        }
        else{
            NSLog(@"error finding %@", error);
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

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    [Answers logCustomEventWithName:@"Opened First Reminder Push"
                   customAttributes:@{}];
    
    self.tabBarController.selectedIndex = 1;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [self checkMesages];
    [self checkForTBMessages];
    NSString *bumpedStatus = [userInfo objectForKey:@"bumpRequest"];
    NSString *listing = [userInfo objectForKey:@"listingID"];
    
    NSDictionary *dic = [userInfo objectForKey:@"aps"];
    NSString *strMsg = [dic objectForKey:@"alert"];
    
    if ( application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground  )
    {
        //opened from a push notification when the app in background
        
       // NSLog(@"dic: %@    and strMsg: %@", dic, strMsg);
        
        NSLog(@"userinfo: %@", userInfo);
        
        if ([strMsg hasPrefix:@"Team Bump"]) {
            [self checkForTBMessages];
            self.tabBarController.selectedIndex = 4;
        }
        else if([strMsg containsString:@"bumped your listing"]){
            //open listing
            self.tabBarController.selectedIndex = 0;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"listingBumped" object:listing];
        }
        else if([bumpedStatus isEqualToString:@"YES"]){
            //open BumpedVC
            NSLog(@"listing and bumped status %@ %@", bumpedStatus, listing);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showBumpedVC" object:listing];
        }
        else{
            self.tabBarController.selectedIndex = 3;
        }
    }
    else{
        //app is active
        
        if([strMsg containsString:@"bumped your listing"]){
            //show just Bumped drop down
            NSLog(@"show drop down");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showBumpedDropDown" object:@[listing, strMsg]];
        }
        else if([bumpedStatus isEqualToString:@"YES"]){
            //open BumpedVC
            NSLog(@"show drop down from delegate");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showDropDown" object:listing];
        }
    }
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshHome" object:nil];
    [self checkMesages];
    [self checkForTBMessages];
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
