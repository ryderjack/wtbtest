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
#import <HNKGooglePlacesAutocomplete/HNKGooglePlacesAutocomplete.h>
#import "BumpVC.h"
#import "mainApprovedSellerController.h"
#include <CommonCrypto/CommonCrypto.h>
#import "resetPassController.h"
#import "MBFingerTipWindow.h"
#import "OrderSummaryView.h"
#import "Mixpanel/Mixpanel.h"
#import <Intercom/Intercom.h>
#import "Branch.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //initial Parse & Fb set up

    [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {

        // checks prior to distributing, search for //CHANGE to see major dev changes
        ////////////////////CHANGE
        
        configuration.applicationId = @"jack1234";
        configuration.clientKey = @"jack1234";
        
        //local host
//        configuration.server = @"http://localhost:1337/parse";
        
        //production
        configuration.server = @"https://live.bumpapi.com/parse";
        
        //preproduction
//        configuration.server = @"https://preprod.bumpapi.com/parse";

        //dev server w/ dev DB
//        configuration.server = @"https://dev.bumpapi.com/parse";

    }]];

//    [Fabric with:@[[Crashlytics class]]]; ////////////////////CHANGE

    //live mixpanel
//    [Mixpanel sharedInstanceWithToken:@"f83619c7bc4c4710bf87d892c0c170df"]; //CHANGE
    
    //dev mixpanel
    [Mixpanel sharedInstanceWithToken:@"5936c96d62474e044e9f214bb8938d91"]; //CHANGE

    [HNKGooglePlacesAutocompleteQuery setupSharedQueryWithAPIKey:@"AIzaSyC812pR1iegUl3UkzqY0rwYlRmrvAAUbgw"];

    //production
//    [Intercom setApiKey:@"ios_sdk-dcdcb0d85e2a1da18471b8506beb225e5800e7dd" forAppId:@"zjwtufx1"]; //CHANGE
    //devs
    [Intercom setApiKey:@"ios_sdk-67598bd2fc99548a4f157a6c78c00c98da59991f" forAppId:@"bjtqi7s6"];
    
    if ([PFUser currentUser]) {
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel identify:[PFUser currentUser].objectId];
        
        NSDictionary *params = @{@"userId": [PFUser currentUser].objectId};
        [PFCloud callFunctionInBackground:@"verifyIntercomUserId" withParameters:params block:^(NSString *hash, NSError *error) {
            if (!error) {
                [Intercom setUserHash:hash];
                [Intercom registerUserWithUserId:[PFUser currentUser].objectId];
                [self setupIntercomListener];
            }
            else{
                [Answers logCustomEventWithName:@"Intercom Verify Error"
                               customAttributes:@{
                                                  @"where":@"delegate"
                                                  }];
            }
        }];
        [self logUser];
        
        //make sure user has currency tracked in mixpanel
        if ([[PFUser currentUser]objectForKey:@"currency"] != nil) {
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel registerSuperPropertiesOnce:@{
                                                    @"currency":[[PFUser currentUser]objectForKey:@"currency"]
                                                    }];
        }
    }
    else{
        //no current user
        
        //listen for when user signs up so we can start to monitor unread intercom messages
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupIntercomListener) name:@"registerIntercom" object:nil];
    }
    
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    
    //set up tab bar
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.welcomeView = [[WelcomeViewController alloc] init];
    self.simpleCreateView = [[simpleCreateVC alloc]init];
    self.exploreView = [[ExploreVC alloc]init];
    self.createTabView = [[CreateTab alloc]init];
    
    self.profileView = [[UserProfileController alloc]init];
    self.profileView.user = [PFUser currentUser];
    self.profileView.tabMode = YES;
    
    self.inboxView = [[InboxViewController alloc]init];
    self.purchaseView = [[PurchaseTab alloc]init];
    
//    self.createSaleListing = [[CreateForSaleListing alloc]init];
//    self.createSaleListing.tabMode = YES;
    
    self.activityView = [[activityVC alloc]init];
    
    [self.window setBackgroundColor:[UIColor whiteColor]];
    
//    NavigationController *navController = [[NavigationController alloc] initWithRootViewController:self.exploreView];
    NavigationController *navController6 = [[NavigationController alloc] initWithRootViewController:self.createTabView];
    NavigationController *navController2 = [[NavigationController alloc] initWithRootViewController:self.profileView];
//    NavigationController *navController3 = [[NavigationController alloc] initWithRootViewController:self.welcomeView];
    NavigationController *navController4 = [[NavigationController alloc] initWithRootViewController:self.inboxView];
    NavigationController *navController7 = [[NavigationController alloc] initWithRootViewController:self.purchaseView];
    NavigationController *navController8 = [[NavigationController alloc] initWithRootViewController:self.activityView];

    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:navController7,navController8, navController6,navController4, navController2, nil];
    self.tabBarController.tabBar.translucent = NO;
    self.tabBarController.selectedIndex = 0;
    [self.tabBarController.tabBar setTintColor:[UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]];
    
    //check if user has iOS 10 or later as this is only for then
    NSString *reqSysVer = @"10.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending) {
        //iOS 10 or later
        self.tabBarController.tabBar.unselectedItemTintColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    }
    
    [self.tabBarController.tabBar setBarTintColor:[UIColor whiteColor]];
    
    UITabBarItem *tabBarItem1 = [self.tabBarController.tabBar.items objectAtIndex:0];
    tabBarItem1.image = [UIImage imageNamed:@"homeIconThin"];
    tabBarItem1.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    tabBarItem1.selectedImage = [UIImage imageNamed:@"homeFilledThin"];
    
    UITabBarItem *tabBarItem5 = [self.tabBarController.tabBar.items objectAtIndex:1];
    tabBarItem5.image = [UIImage imageNamed:@"activityIcon"];
    tabBarItem5.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    tabBarItem5.selectedImage = [UIImage imageNamed:@"activityIconBlack"];
    
    UITabBarItem *tabBarItem2 = [self.tabBarController.tabBar.items objectAtIndex:2];
    tabBarItem2.image = [UIImage imageNamed:@"CreateIconThin"];
    tabBarItem2.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    tabBarItem2.selectedImage = [UIImage imageNamed:@"CreateFilledThin"];
    
    UITabBarItem *tabBarItem3 = [self.tabBarController.tabBar.items objectAtIndex:3];
    tabBarItem3.image = [UIImage imageNamed:@"inboxIcon"];
    tabBarItem3.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    tabBarItem3.selectedImage = [UIImage imageNamed:@"inboxIconFill"];
    
    UITabBarItem *tabBarItem4 = [self.tabBarController.tabBar.items objectAtIndex:4];
    tabBarItem4.image = [UIImage imageNamed:@"userIconThin"];
    tabBarItem4.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    tabBarItem4.selectedImage = [UIImage imageNamed:@"userFilledThin"];
    
    //set unseen badge colour
    if (@available(iOS 10.0, *)) {
        [tabBarItem1 setBadgeColor:[UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0]];
        [tabBarItem2 setBadgeColor:[UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0]];
        [tabBarItem3 setBadgeColor:[UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0]];
        [tabBarItem4 setBadgeColor:[UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0]];
        [tabBarItem5 setBadgeColor:[UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0]];
    }
    
    [self.tabBarController setDelegate:self];
    
//    MBFingerTipWindow *finger = [[MBFingerTipWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
//    finger.alwaysShowTouches = YES;
//    self.window = finger;

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
        [[self.tabBarController.tabBar.items objectAtIndex:4] setBadgeValue:nil];
    }
    else{
        //if app badge not zero, reset to zero
        self.installation.badge = 0;
        [self.installation saveEventually];
        [[self.tabBarController.tabBar.items objectAtIndex:4] setBadgeValue:nil];
    }
    
    self.unseenMessages = [[NSMutableArray alloc]init];
    
    if ([PFUser currentUser]) {
        
        if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications] == NO) {
            [self setupTimers];
        }
        else{
            [self checkMesages];
            [self checkForOrders];
            [self checkForActivity];
        }
    }
    
    //check for local push trigger
    UILocalNotification *localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    
    if ([localNotif.alertBody containsString:@"Congrats on your first listing! Want to sell faster? Try searching through wanted listings on BUMP"]){
        [Answers logCustomEventWithName:@"Opened First Reminder Push"
                       customAttributes:@{}];
        
        self.tabBarController.selectedIndex = 0;
    }
    else if ([localNotif.alertBody.lowercaseString containsString:@"what are you selling? list your first item for sale on BUMP"]){
        [Answers logCustomEventWithName:@"Opened First Listing Post Reminder Push"
                       customAttributes:@{}];
        
        self.tabBarController.selectedIndex = 2;
    }
    else if ([localNotif.alertBody containsString:@"What's your next cop? Find it on BUMP"]){
        [Answers logCustomEventWithName:@"Opened 6 day Reminder Push"
                       customAttributes:@{}];
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"longTermLocalSeen"];
    }
    else if ([localNotif.alertBody.lowercaseString containsString:@"sell faster and boost your listing now"] || [localNotif.alertBody.lowercaseString containsString:@"your boost is now available for "]){
        NSLog(@"opening boost local push from close ");
        
        if ([localNotif.alertBody.lowercaseString containsString:@"sell faster and boost your listing now"]) {
            [Answers logCustomEventWithName:@"Opened First BOOST Reminder"
                           customAttributes:@{}];
        }
        else{
            [Answers logCustomEventWithName:@"Opened BOOST Reminder"
                           customAttributes:@{}];
        }
        
        if ([[localNotif userInfo]valueForKey:@"listingId"]) {

            NSString *listingId = [[localNotif userInfo]valueForKey:@"listingId"];
            
            if ([PFUser currentUser]) {
                PFQuery *listingQuery = [PFQuery queryWithClassName:@"forSaleItems"];
                [listingQuery whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
                [listingQuery whereKey:@"status" equalTo:@"live"];
                [listingQuery whereKey:@"objectId" equalTo:listingId];
                [listingQuery orderByAscending:@"nextBoostDate"];
                [listingQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                    if (object) {
                        
                        PFObject *listingObject = object;
                        
                        ForSaleListing *vc = [[ForSaleListing alloc]init];
                        vc.listingObject = listingObject;
                        vc.source = @"boost";
                        vc.fromBuyNow = YES;
                        vc.pureWTS = YES;
                        vc.fromPush = YES;
                        vc.fromBoostPush = YES;
                        
                        NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
                        
                        if (nav.presentedViewController) {
                            
                            //nav bar is showing something
                            if ([nav.presentedViewController isKindOfClass:[NavigationController class]]) {
                                
                                //2nd nav is showing so push from there instead of tab bar nav
                                NavigationController *presenter = (NavigationController*)nav.presentedViewController;
                                [presenter pushViewController:vc animated:YES];
                            }
                        }
                        //if user is looking at mainsearch VC
                        else if(nav.visibleViewController.presentedViewController){
                            //2nd nav is showing so push from there instead of tab bar nav
                            NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                            [presenter pushViewController:vc animated:YES];
                        }
                        else{
                            //no other VC showing so push!
                            [nav pushViewController:vc animated:YES];
                        }
                    }
                    else{
                        NSLog(@"error finding first listing 1 %@", error);
                    }
                }];
            }
            
        }
    }
    else{
        //no local release alert so check for remote
        
        //needed to handle the standard pushes that require no opening
        NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (notification) {
            NSLog(@"app recieved notification from remote%@",notification);
            [self application:application didReceiveRemoteNotification:notification];
        }else{
            NSLog(@"app did not recieve notification");
        }
        
        //Handle fresh opened from a push notification
        NSDictionary *userInfo = [launchOptions valueForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
        
        NSString *bumpedStatus = [userInfo objectForKey:@"bumpRequest"];
        NSString *listing = [userInfo objectForKey:@"listingID"];
        
        NSDictionary *dic = [userInfo objectForKey:@"aps"];
        NSString *strMsg = [dic objectForKey:@"alert"];
        
        if([strMsg hasSuffix:@"just left you a review"]){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened order after receiving Feedback Push"
                           customAttributes:@{}];
            
            PFObject *orderObject = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:listing];
            OrderSummaryView *vc = [[OrderSummaryView alloc]init];
            vc.orderObject = orderObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            [nav pushViewController:vc animated:YES];
        }
        else if([strMsg hasSuffix:@"just listed an item for sale"] && listing.length > 0){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened subscriber push"
                           customAttributes:@{}];
            
            PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"forSaleItems" objectId:listing];
            
            ForSaleListing *vc = [[ForSaleListing alloc]init];
            vc.listingObject = listingObject;
            vc.source = @"push";
            vc.fromBuyNow = YES;
            vc.pureWTS = YES;
            vc.fromPush = YES;
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            [nav pushViewController:vc animated:YES];
        }
        else if([strMsg hasPrefix:@"Item Sold"]){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened order after receiving Sold Push"
                           customAttributes:@{}];
            
            PFObject *orderObject = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:listing];
            OrderSummaryView *vc = [[OrderSummaryView alloc]init];
            vc.orderObject = orderObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            [nav pushViewController:vc animated:YES];
        }
        else if([strMsg hasPrefix:@"Refund Received"]){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened order after receiving Refund Push"
                           customAttributes:@{}];
            
            PFObject *orderObject = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:listing];
            OrderSummaryView *vc = [[OrderSummaryView alloc]init];
            vc.orderObject = orderObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            [nav pushViewController:vc animated:YES];
        }
        else if([strMsg hasPrefix:@"Refund Requested"]){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened order after receiving Refund Requested Push"
                           customAttributes:@{}];
            
            PFObject *orderObject = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:listing];
            OrderSummaryView *vc = [[OrderSummaryView alloc]init];
            vc.orderObject = orderObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            [nav pushViewController:vc animated:YES];
        }
        else if([strMsg hasPrefix:@"Tracking added"]){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened order after receiving Tracking added Push"
                           customAttributes:@{}];
            
            PFObject *orderObject = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:listing];
            OrderSummaryView *vc = [[OrderSummaryView alloc]init];
            vc.orderObject = orderObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            [nav pushViewController:vc animated:YES];
        }
        else if([strMsg hasPrefix:@"Item Shipped"]){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened order after receiving Shipped Push"
                           customAttributes:@{}];
            
            PFObject *orderObject = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:listing];
            OrderSummaryView *vc = [[OrderSummaryView alloc]init];
            vc.orderObject = orderObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            [nav pushViewController:vc animated:YES];
        }
        else if([strMsg hasPrefix:@"Payment Failed"]){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened order after receiving Payment Failed Push"
                           customAttributes:@{}];
            
            PFObject *orderObject = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:listing];
            OrderSummaryView *vc = [[OrderSummaryView alloc]init];
            vc.orderObject = orderObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            [nav pushViewController:vc animated:YES];
        }
        else if([strMsg containsString:@"liked your wanted listing"]){
            //open wanted listing
            [Answers logCustomEventWithName:@"Opened wanted listing after receiving Bump Push"
                           customAttributes:@{}];
            
            PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"wantobuys" objectId:listing];
            ListingController *vc = [[ListingController alloc]init];
            vc.listingObject = listingObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            [nav pushViewController:vc animated:YES];
            
        }
        else if([strMsg containsString:@"liked your listing"]){
            //open for sale listing
            [Answers logCustomEventWithName:@"Opened listing after receiving Bump Push"
                           customAttributes:@{}];
            
            self.tabBarController.selectedIndex = 1;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"newActivtyItems" object:nil];
            
//            PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"forSaleItems" objectId:listing];
//
//            ForSaleListing *vc = [[ForSaleListing alloc]init];
//            vc.listingObject = listingObject;
//            vc.source = @"bump";
//            vc.fromBuyNow = YES;
//            vc.pureWTS = YES;
//            vc.fromPush = YES;
//
//            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
//            [nav pushViewController:vc animated:YES];
            
        }
        else if([bumpedStatus isEqualToString:@"YES"]){
            //Facebook friend has posted a for sale listing, take them to it
            [Answers logCustomEventWithName:@"Opened Listing after receiving FB Friend Push"
                           customAttributes:@{}];
            
//            BumpVC *vc = [[BumpVC alloc]init];
//            vc.listingID = listing;
            
            PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"forSaleItems" objectId:listing];

            ForSaleListing *vc = [[ForSaleListing alloc]init];
            vc.listingObject = listingObject;
            vc.source = @"push";
            vc.fromBuyNow = YES;
            vc.pureWTS = YES;
            vc.fromPush = YES;
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            [nav pushViewController:vc animated:YES];
        }
    }
    
    //add observer which can refresh profile tab badge after user places an order
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(profileBadgeRefresh) name:@"orderPlaced" object:nil];
    
    //when a new listing has finished saving this is triggered
    //we can then pass this value to the create a listing page which also has an observer on there
    [center addObserver:self selector:@selector(listingFinished) name:@"justPostedSaleListing" object:nil];
    [center addObserver:self selector:@selector(listingStarted) name:@"postingItem" object:nil];

    //app store observer
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

    //reset BOOL which limits like drop downs to once per session
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"seenLikeDrop"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"seenFollowDrop"];
    
    //reset dummy follow setting
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showDummyFollowing"];
    
    //fetch IAP products & pricing info
    self.products = [NSArray array];
    self.productIdentifiersArray = @[@"BOOST0001"];
    
    [self validateProductIdentifiers:self.productIdentifiersArray];
    
    //deep link handling
    Branch *branch = [Branch getInstance];
    [branch initSessionWithLaunchOptions:launchOptions andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        if (!error && params) {
//            NSLog(@"branch link params: %@", params.description);
            
            //check if this is first session and then if so save the referrer in user defaults
            //can then pickup from userdefaults in signup screen and save to mixpanel sign up event
            
            if ([params valueForKey:@"+is_first_session"]) {
                if ([[params valueForKey:@"+is_first_session"]intValue] == 1) {
                    
                    if ([params valueForKey:@"affiliate"]) {
                        //store affiliate name in defaults to access in sign up process since this is the first session
                        NSString *affiliate = [params valueForKey:@"affiliate"];
                        [[NSUserDefaults standardUserDefaults] setObject:affiliate forKey:@"affiliate"];
                    }
                    
                    //check if there's a referrer property that would have created the link in-app and distributed it either by = Copying the link, Whatsapp, Facebook
                    if ([params valueForKey:@"referrer"]) {
                        
                        NSLog(@"user installed from another user's link");
                        
                        //pass referrer to signup so we know who caused the user to come here
                        NSString *referrer = [params valueForKey:@"referrer"];
                        [[NSUserDefaults standardUserDefaults] setObject:referrer forKey:@"referrer"];
                    }
                    
                    //check what channel this user came form (copied link, whatsapp, messenger or more!)
                    if ([params valueForKey:@"~channel"]) {
                        
                        //pass this onto signup too
                        NSString *channel = [params valueForKey:@"~channel"];
                        [[NSUserDefaults standardUserDefaults] setObject:channel forKey:@"channel"];
                    }
                    
                    //check what content caused this user to come here (listing, profile or more)
                    if ([params valueForKey:@"~feature"]) {
                        
                        //pass this onto signup too
                        NSString *content = [params valueForKey:@"~feature"];
                        [[NSUserDefaults standardUserDefaults] setObject:content forKey:@"content"];
                    }
                }
                else{
                    Mixpanel *mixpanel = [Mixpanel sharedInstance];
                    
                    //check what channel this user came form (copied link, whatsapp, messenger or more!)
                    if ([params valueForKey:@"~channel"] && [params valueForKey:@"~feature"]) {
                        
                        //pass this onto signup too
                        NSString *channel = [params valueForKey:@"~channel"];
                        NSString *content = [params valueForKey:@"~feature"];
                        
                        [mixpanel track:@"Branch Link App Open" properties:@{
                                                                             @"channel":channel,
                                                                             @"content":content
                                                                             }];
                    }
                    else if ([params valueForKey:@"~feature"]) {
                        
                        //pass this onto signup too
                        NSString *content = [params valueForKey:@"~feature"];
                        [mixpanel track:@"Branch Link App Open" properties:@{
                                                                             @"content":content
                                                                             }];
                    }
                    else if ([params valueForKey:@"~channel"]) {
                        
                        //pass this onto signup too
                        NSString *channel = [params valueForKey:@"~channel"];
                        [mixpanel track:@"Branch Link App Open" properties:@{
                                                                             @"channel":channel
                                                                             }];
                    }
                    else{
                        [mixpanel track:@"Branch Link App Open"];
                    }
                }
            }
            
            //now check if there's a current user and if the link has any routing info in it
            if ([PFUser currentUser] && [params valueForKey:@"$deeplink_path"]) {
                
                //only let users that have completed Reg into the app to see shared content
                if ([[PFUser currentUser]objectForKey:@"completedReg"]) {
                    //profile share link tapped profile/PROFILEID
                    NSString *URIPath = [params valueForKey:@"$deeplink_path"];
                    
                    
                    if ([URIPath hasPrefix:@"profile/"]) {
                        NSString *userId = [URIPath stringByReplacingOccurrencesOfString:@"profile/" withString:@""];
                        
                        PFQuery *profileQuery = [PFUser query];
                        [profileQuery whereKey:@"objectId" equalTo:userId];
                        [profileQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                            if (object) {
                                [Answers logCustomEventWithName:@"Link Opened"
                                               customAttributes:@{
                                                                  @"type":@"profile"
                                                                  }];
                                
                                UserProfileController *vc = [[UserProfileController alloc]init];
                                vc.user = (PFUser *)object;
                                NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
                                
                                if (nav.visibleViewController.presentedViewController) {
                                    
                                    //nav bar is showing something
                                    if ([nav.visibleViewController.presentedViewController isKindOfClass:[NavigationController class]]) {
                                        
                                        //2nd nav is showing so push from there instead of tab bar nav
                                        NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                                        [presenter pushViewController:vc animated:YES];
                                    }
                                }
                                else{
                                    //no other VC showing so push!
                                    [nav pushViewController:vc animated:YES];
                                }
                            }
                            else{
                                NSLog(@"error finding user object %@", error);
                            }
                        }];
                    }
                    
                    //listing share link tapped selling/LISTINGID
                    
                    else if ([URIPath hasPrefix:@"selling/"]){
                        NSString *listingId = [URIPath stringByReplacingOccurrencesOfString:@"selling/" withString:@""];
                        
                        [Answers logCustomEventWithName:@"Link Opened"
                                       customAttributes:@{
                                                          @"type":@"for sale"
                                                          }];
                        
                        PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"forSaleItems" objectId:listingId];
                        
                        ForSaleListing *vc = [[ForSaleListing alloc]init];
                        vc.listingObject = listingObject;
                        vc.source = @"link";
                        vc.fromBuyNow = YES;
                        vc.pureWTS = YES;
                        vc.fromPush = YES;
                        
                        NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
                        
                        if (nav.visibleViewController.presentedViewController) {
                            
                            //nav bar is showing something
                            if ([nav.visibleViewController.presentedViewController isKindOfClass:[NavigationController class]]) {
                                
                                //2nd nav is showing so push from there instead of tab bar nav
                                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                                [presenter pushViewController:vc animated:YES];
                            }
                        }
                        else{
                            //no other VC showing so push!
                            [nav pushViewController:vc animated:YES];
                        }
                    }
                }
            }
        }
    }];
    
    return YES;
}

- (void) logUser {
    [CrashlyticsKit setUserIdentifier:[NSString stringWithFormat:@"%@", [PFUser currentUser].objectId]];
    [CrashlyticsKit setUserName:[NSString stringWithFormat:@"%@", [PFUser currentUser].username]];
}

//call to check messages if installation badge value doesnt work for ppl who havent enabled push
-(void)checkMesages{
    if (![PFUser currentUser]) {
        return;
    }
    //query for convos we know this user hasn't seen
    PFQuery *buyingUnseenQuery = [PFQuery queryWithClassName:@"convos"];
    [buyingUnseenQuery whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
    [buyingUnseenQuery whereKey:@"buyerUnseen" greaterThan:@0];
    [buyingUnseenQuery whereKey:@"buyerDeleted" equalTo:@"NO"];
    
    PFQuery *sellingUnseenQuery = [PFQuery queryWithClassName:@"convos"];
    [sellingUnseenQuery whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
    [sellingUnseenQuery whereKey:@"sellerUnseen" greaterThan:@0];
    [sellingUnseenQuery whereKey:@"sellerDeleted" equalTo:@"NO"];
    
    PFQuery *unseenQuery = [PFQuery orQueryWithSubqueries:@[buyingUnseenQuery, sellingUnseenQuery]];
    [unseenQuery whereKey:@"totalMessages" greaterThan:@0];
    [unseenQuery orderByDescending:@"createdAt"];
    [unseenQuery includeKey:@"lastSent"];
    
    [unseenQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
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
                        
                        if ([[PFUser currentUser].objectId isEqualToString:[convo objectForKey:@"buyerId"]]) {
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
                        
//                        NSLog(@"TOTAL UNSEEN %d", totalUnseen);
                    }
                }
                
                if (self.unseenMessages.count != 0) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessage" object:self.unseenMessages];
                    
                    //remove current convo from array to avoid badge showing for current chat
                    for (PFObject *convoObjs in self.unseenMessages) {
                        if ([self.inboxView.selectedConvo isEqualToString:convoObjs.objectId]) {
                            [self.unseenMessages removeObject:convoObjs];
                        }
                    }
                    
                    if (totalUnseen > 0) {
                        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:[NSString stringWithFormat:@"%d", totalUnseen]];
                    }
                    else{
                        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
                    }
                    
                    //add unseen orders to badge make sure this is bulletproof
//                    if (self.profileView.ordersUnseen > 0) {
//                        totalUnseen+= self.profileView.ordersUnseen;
//                    }
                    self.installation.badge = totalUnseen;
                    [self.installation saveEventually];
                }
                else{
                    [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
                    
                    //add unseen orders to badge
//                    if (self.profileView.ordersUnseen > 0) {
//                        self.installation.badge = self.profileView.ordersUnseen;
//                    }
//                    else{
//                        self.installation.badge = 0;
//                    }
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

//this is unseen orders, not updating user object here
-(void)checkForOrders{
    if (![PFUser currentUser]) {
        return;
    }
    //query for convos we know this user hasn't seen
    PFQuery *buyingUnseenQuery = [PFQuery queryWithClassName:@"saleOrders"];
    [buyingUnseenQuery whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
    [buyingUnseenQuery whereKey:@"buyerUnseen" greaterThan:@0];
    [buyingUnseenQuery whereKey:@"status" containedIn:@[@"live",@"failed",@"refunded",@"pending"]];

    PFQuery *sellingUnseenQuery = [PFQuery queryWithClassName:@"saleOrders"];
    [sellingUnseenQuery whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
    [sellingUnseenQuery whereKey:@"sellerUnseen" greaterThan:@0];
    [sellingUnseenQuery whereKey:@"status" containedIn:@[@"live",@"refunded"]];

    PFQuery *unseenQuery = [PFQuery orQueryWithSubqueries:@[buyingUnseenQuery, sellingUnseenQuery]];
    [unseenQuery orderByDescending:@"lastUpdated"];
    
    [unseenQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int orderCount = (int)objects.count;
            NSLog(@"unseen orders count %d", orderCount);
            
            //If this is triggered after a user has viewed their orders then the unseen count may have hit zero. If so clear the badge
            if (self.profileView.ordersUnseen > 0 && orderCount == 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"clearOrders" object:nil];
            }
            
            self.profileView.ordersUnseen = orderCount;

            if (objects.count > 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UnseenOrders" object:@(orderCount)];
            }
            
            [self calcProfileBadge];
            
        }
        else{
            NSLog(@"error finding orders %@", error);
        }
    }];
}

-(void)checkForActivity{
    if (![PFUser currentUser]) {
        return;
    }
    //query for convos we know this user hasn't seen
    PFQuery *activityUnseen = [PFQuery queryWithClassName:@"Activity"];
    [activityUnseen whereKey:@"userId" equalTo:[PFUser currentUser].objectId];
    [activityUnseen whereKey:@"seen" equalTo:@"unseen"];
    [activityUnseen whereKey:@"status" equalTo:@"live"];
    [activityUnseen findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int unseenCount = (int)objects.count;
            NSLog(@"unseen activity objects count %d", unseenCount);

            if (objects.count > 0 && self.tabBarController.selectedIndex != 1) {

                //if activity VC has been loaded this session then trigger an update there
                [[NSNotificationCenter defaultCenter] postNotificationName:@"newActivtyItems" object:nil];

                int tabInt = (int)objects.count;

                if (tabInt > 9) {
                    [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:@"9+"];
                }
                else{
                    [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:[NSString stringWithFormat:@"%d",tabInt]];
                }
            }
            else{
                [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:nil];
            }

        }
        else{
            NSLog(@"error finding activity objects %@", error);
        }
    }];
}

-(void)checkForTBMessages{
    if (![PFUser currentUser]) {
        return;
    }
    PFQuery *convosQuery = [PFQuery queryWithClassName:@"teamConvos"];
    [convosQuery whereKey:@"convoId" equalTo: [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId]];
    [convosQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //is there anything unseen in the convo
            int userUnseen = [[object objectForKey:@"userUnseen"]intValue];
            self.profileView.messagesUnseen = userUnseen;

            if (userUnseen > 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NewTBMessage" object:nil];
            }
            
            [self calcProfileBadge];
        }
        else{
            if (error.code == 209) {
                NSLog(@"invalid so logout");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"invalidSessionNotification" object:nil];
            }
            NSLog(@"error finding team bump messages %@", error);
        }
    }];
}

-(void)checkForSupportMessages{
    if (![PFUser currentUser]) {
        return;
    }
    PFQuery *convosQuery = [PFQuery queryWithClassName:@"supportConvos"];
    [convosQuery whereKey:@"userId" equalTo:[PFUser currentUser].objectId];
    [convosQuery whereKey:@"userUnseen" greaterThan:@0];
    [convosQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            self.profileView.supportUnseen = count;

            if (objects.count > 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NewTBMessage" object:nil];
            }
            
            [self calcProfileBadge];
        }
        else{
            if (error.code == 209) {
                NSLog(@"invalid so logout");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"invalidSessionNotification" object:nil];
            }
            NSLog(@"error finding support messages %@", error);
        }
    }];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    [self.installation setDeviceTokenFromData:deviceToken];
    [Intercom setDeviceToken:deviceToken];

    if ([PFUser currentUser]) {
        [self.installation setObject:[PFUser currentUser] forKey:@"user"];
        [self.installation setObject:[PFUser currentUser].objectId forKey:@"userId"];
    }
    
    //only set global for first time user registers
    //otherwise we overwrite the 'subscribed to users' in the channel
    if(self.installation.channels.count == 0){
        self.installation.channels = @[ @"global" ];
    }
    
    [self.installation saveInBackground];
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    
//    NSDictionary *localUserInfo = notification.userInfo;
//    NSString *releaseLink = [localUserInfo valueForKey:@"link"];
//    NSString *itemTitle = [localUserInfo valueForKey:@"itemTitle"];
    
    if ( application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground  )
    {
        if ([notification.alertBody containsString:@"What's your next cop? Find it on Bump 👊"]){
            [Answers logCustomEventWithName:@"Opened 6 day Reminder Push"
                           customAttributes:@{}];
            [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"longTermLocalSeen"];
        }
        else if ([notification.alertBody.lowercaseString containsString:@"congrats on your first listing! want to sell faster? try searching through wanted listings on bump"]){
            [Answers logCustomEventWithName:@"Opened First Reminder Push"
                           customAttributes:@{}];
            
            self.tabBarController.selectedIndex = 0;
        }
        else if ([notification.alertBody.lowercaseString containsString:@"what are you selling? list your first item for sale on bump now!"]){
            [Answers logCustomEventWithName:@"Opened First Listing Post Reminder Push"
                           customAttributes:@{}];
            
            self.tabBarController.selectedIndex = 2;
        }
        else if ([notification.alertBody.lowercaseString containsString:@"your boost is now available for "] || [notification.alertBody.lowercaseString containsString:@"sell faster and boost your listing now"]){
            
            if ([notification.alertBody.lowercaseString containsString:@"your boost is now available for "] ) {
                [Answers logCustomEventWithName:@"Opened BOOST Reminder"
                               customAttributes:@{
                                                  @"method":@"did receive local push"
                                                  }];
            }
            else{
                [Answers logCustomEventWithName:@"Opened BOOST Reminder"
                               customAttributes:@{
                                                  @"method":@"did receive local push"
                                                  }];
            }
            
            if ([[notification userInfo]valueForKey:@"listingId"]) {
                //parse out the listingId
                NSString *listingId = [[notification userInfo]valueForKey:@"listingId"];
                
                if ([PFUser currentUser]) {
                    PFQuery *listingQuery = [PFQuery queryWithClassName:@"forSaleItems"];
                    [listingQuery whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
                    [listingQuery whereKey:@"status" equalTo:@"live"];
                    [listingQuery whereKey:@"objectId" equalTo:listingId];
                    [listingQuery orderByDescending:@"nextBoostDate"];
                    [listingQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                        if (object) {
                            
                            PFObject *listingObject = object;
                            
                            ForSaleListing *vc = [[ForSaleListing alloc]init];
                            vc.listingObject = listingObject;
                            vc.source = @"boost";
                            vc.fromBuyNow = YES;
                            vc.pureWTS = YES;
                            vc.fromPush = YES;
                            vc.fromBoostPush = YES;
                            
                            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
                            
                            if (nav.presentedViewController) {
                                
                                //nav bar is showing something
                                if ([nav.presentedViewController isKindOfClass:[NavigationController class]]) {
                                    
                                    //2nd nav is showing so push from there instead of tab bar nav
                                    NavigationController *presenter = (NavigationController*)nav.presentedViewController;
                                    [presenter pushViewController:vc animated:YES];
                                }
                            }
                            //if user is looking at mainsearch VC
                            else if(nav.visibleViewController.presentedViewController){
                                //2nd nav is showing so push from there instead of tab bar nav
                                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                                [presenter pushViewController:vc animated:YES];
                            }
                            else{
                                //no other VC showing so push!
                                [nav pushViewController:vc animated:YES];
                            }
                        }
                        else{
                            NSLog(@"error finding boost available listing %@", error);
                        }
                    }];
                }
            }
        }
        else{
            //fail safe - if local push doesn't match anything
        }
    }
    else{
        NSLog(@"local push received in-app");

        //local push received whilst app was open
        if ([notification.alertBody.lowercaseString containsString:@"sell faster and boost your listing now"]){
            
            NSLog(@"local first boost push received in-app");

            [Answers logCustomEventWithName:@"Received First BOOST Push in-app"
                           customAttributes:@{}];
            
            if ([[notification userInfo]valueForKey:@"listingId"]) {
                NSString *listingId = [[notification userInfo]valueForKey:@"listingId"];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"showBOOSTDropDown" object:@[listingId]];
            }
        }
        else if ([notification.alertBody.lowercaseString containsString:@"your boost is now available for "]){
            
            NSLog(@"local normal boost push received in-app");
            
            [Answers logCustomEventWithName:@"Received normal BOOST Push in-app"
                           customAttributes:@{}];
            
            if ([[notification userInfo]valueForKey:@"listingId"]) {
                NSString *listingId = [[notification userInfo]valueForKey:@"listingId"];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"showBOOSTDropDown" object:@[listingId]];
            }
        }
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [self checkMesages];
//    [self checkForTBMessages];
//    [self checkForSupportMessages];
    
    NSString *bumpedStatus = [userInfo objectForKey:@"bumpRequest"];
    NSString *listing = [userInfo objectForKey:@"listingID"];
    
    NSDictionary *dic = [userInfo objectForKey:@"aps"];
    NSString *strMsg = [dic objectForKey:@"alert"];
    
    if ( application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground  )
    {
        //opened from a push notification when the app in background
        
       // NSLog(@"dic: %@    and strMsg: %@", dic, strMsg);

        if([strMsg hasSuffix:@"just left you a review"]){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened order after receiving Feedback Push"
                           customAttributes:@{}];
            
            PFObject *orderObject = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:listing];
            OrderSummaryView *vc = [[OrderSummaryView alloc]init];
            vc.orderObject = orderObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;

            if (nav.presentedViewController) {
                
                //nav bar is showing something
                if ([nav.presentedViewController isKindOfClass:[NavigationController class]]) {
                    
                    //2nd nav is showing so push from there instead of tab bar nav
                    NavigationController *presenter = (NavigationController*)nav.presentedViewController;
                    [presenter pushViewController:vc animated:YES];
                }
            }
            //if user is looking at mainsearch VC
            else if(nav.visibleViewController.presentedViewController){
                //2nd nav is showing so push from there instead of tab bar nav
                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                [presenter pushViewController:vc animated:YES];
            }
            else{
                //no other VC showing so push!
                [nav pushViewController:vc animated:YES];
            }
        }
        else if([strMsg hasSuffix:@"just listed an item for sale"] && listing.length > 0){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened subscriber push"
                           customAttributes:@{}];
            
            PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"forSaleItems" objectId:listing];
            
            ForSaleListing *vc = [[ForSaleListing alloc]init];
            vc.listingObject = listingObject;
            vc.source = @"push";
            vc.fromBuyNow = YES;
            vc.pureWTS = YES;
            vc.fromPush = YES;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            
            if (nav.presentedViewController) {
                
                //nav bar is showing something
                if ([nav.presentedViewController isKindOfClass:[NavigationController class]]) {
                    
                    //2nd nav is showing so push from there instead of tab bar nav
                    NavigationController *presenter = (NavigationController*)nav.presentedViewController;
                    [presenter pushViewController:vc animated:YES];
                }
            }
            //if user is looking at mainsearch VC
            else if(nav.visibleViewController.presentedViewController){
                //2nd nav is showing so push from there instead of tab bar nav
                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                [presenter pushViewController:vc animated:YES];
            }
            else{
                //no other VC showing so push!
                [nav pushViewController:vc animated:YES];
            }
        }
        else if([strMsg hasPrefix:@"Item Sold"]){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened order after receiving Sold Push"
                           customAttributes:@{}];
            
            PFObject *orderObject = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:listing];
            OrderSummaryView *vc = [[OrderSummaryView alloc]init];
            vc.orderObject = orderObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            if (nav.presentedViewController) {
                
                //nav bar is showing something
                if ([nav.presentedViewController isKindOfClass:[NavigationController class]]) {
                    
                    //2nd nav is showing so push from there instead of tab bar nav
                    NavigationController *presenter = (NavigationController*)nav.presentedViewController;
                    [presenter pushViewController:vc animated:YES];
                }
            }
            //if user is looking at mainsearch VC
            else if(nav.visibleViewController.presentedViewController){
                //2nd nav is showing so push from there instead of tab bar nav
                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                [presenter pushViewController:vc animated:YES];
            }
            else{
                //no other VC showing so push!
                [nav pushViewController:vc animated:YES];
            }
        }
        else if([strMsg hasPrefix:@"Item Shipped"]){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened order after receiving Shipped Push"
                           customAttributes:@{}];
            
            PFObject *orderObject = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:listing];
            OrderSummaryView *vc = [[OrderSummaryView alloc]init];
            vc.orderObject = orderObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            if (nav.presentedViewController) {
                
                //nav bar is showing something
                if ([nav.presentedViewController isKindOfClass:[NavigationController class]]) {
                    
                    //2nd nav is showing so push from there instead of tab bar nav
                    NavigationController *presenter = (NavigationController*)nav.presentedViewController;
                    [presenter pushViewController:vc animated:YES];
                }
            }
            //if user is looking at mainsearch VC
            else if(nav.visibleViewController.presentedViewController){
                //2nd nav is showing so push from there instead of tab bar nav
                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                [presenter pushViewController:vc animated:YES];
            }
            else{
                //no other VC showing so push!
                [nav pushViewController:vc animated:YES];
            }
        }
        else if([strMsg hasPrefix:@"Payment Failed"]){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened order after receiving Payment Failed Push"
                           customAttributes:@{}];
            
            PFObject *orderObject = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:listing];
            OrderSummaryView *vc = [[OrderSummaryView alloc]init];
            vc.orderObject = orderObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            if (nav.presentedViewController) {
                
                //nav bar is showing something
                if ([nav.presentedViewController isKindOfClass:[NavigationController class]]) {
                    
                    //2nd nav is showing so push from there instead of tab bar nav
                    NavigationController *presenter = (NavigationController*)nav.presentedViewController;
                    [presenter pushViewController:vc animated:YES];
                }
            }
            //if user is looking at mainsearch VC
            else if(nav.visibleViewController.presentedViewController){
                //2nd nav is showing so push from there instead of tab bar nav
                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                [presenter pushViewController:vc animated:YES];
            }
            else{
                //no other VC showing so push!
                [nav pushViewController:vc animated:YES];
            }
        }
        else if([strMsg hasPrefix:@"Refund Received"]){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened order after receiving Refund Push"
                           customAttributes:@{}];
            
            PFObject *orderObject = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:listing];
            OrderSummaryView *vc = [[OrderSummaryView alloc]init];
            vc.orderObject = orderObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            if (nav.presentedViewController) {
                
                //nav bar is showing something
                if ([nav.presentedViewController isKindOfClass:[NavigationController class]]) {
                    
                    //2nd nav is showing so push from there instead of tab bar nav
                    NavigationController *presenter = (NavigationController*)nav.presentedViewController;
                    [presenter pushViewController:vc animated:YES];
                }
            }
            //if user is looking at mainsearch VC
            else if(nav.visibleViewController.presentedViewController){
                //2nd nav is showing so push from there instead of tab bar nav
                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                [presenter pushViewController:vc animated:YES];
            }
            else{
                //no other VC showing so push!
                [nav pushViewController:vc animated:YES];
            }
        }
        else if([strMsg hasPrefix:@"Refund Requested"]){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened order after receiving Refund Requested Push"
                           customAttributes:@{}];
            
            PFObject *orderObject = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:listing];
            OrderSummaryView *vc = [[OrderSummaryView alloc]init];
            vc.orderObject = orderObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            if (nav.presentedViewController) {
                
                //nav bar is showing something
                if ([nav.presentedViewController isKindOfClass:[NavigationController class]]) {
                    
                    //2nd nav is showing so push from there instead of tab bar nav
                    NavigationController *presenter = (NavigationController*)nav.presentedViewController;
                    [presenter pushViewController:vc animated:YES];
                }
            }
            //if user is looking at mainsearch VC
            else if(nav.visibleViewController.presentedViewController){
                //2nd nav is showing so push from there instead of tab bar nav
                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                [presenter pushViewController:vc animated:YES];
            }
            else{
                //no other VC showing so push!
                [nav pushViewController:vc animated:YES];
            }
        }
        else if([strMsg hasPrefix:@"Tracking added"]){
            //open order summary page of this order
            [Answers logCustomEventWithName:@"Opened order after receiving Tracking Added Push"
                           customAttributes:@{}];
            
            PFObject *orderObject = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:listing];
            OrderSummaryView *vc = [[OrderSummaryView alloc]init];
            vc.orderObject = orderObject;
            
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            if (nav.presentedViewController) {
                
                //nav bar is showing something
                if ([nav.presentedViewController isKindOfClass:[NavigationController class]]) {
                    
                    //2nd nav is showing so push from there instead of tab bar nav
                    NavigationController *presenter = (NavigationController*)nav.presentedViewController;
                    [presenter pushViewController:vc animated:YES];
                }
            }
            //if user is looking at mainsearch VC
            else if(nav.visibleViewController.presentedViewController){
                //2nd nav is showing so push from there instead of tab bar nav
                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                [presenter pushViewController:vc animated:YES];
            }
            else{
                //no other VC showing so push!
                [nav pushViewController:vc animated:YES];
            }
        }
        else if([strMsg containsString:@"liked your wanted listing"]){
            [Answers logCustomEventWithName:@"Opened wanted listing after receiving Bump Push"
                           customAttributes:@{}];
            
            //open wanted listing
            self.tabBarController.selectedIndex = 0;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"listingBumped" object:listing];
        }
        else if([strMsg containsString:@"liked your listing"]){
            [Answers logCustomEventWithName:@"Opened listing after receiving Bump Push"
                           customAttributes:@{}];
            
            //open activity feed
            self.tabBarController.selectedIndex = 1;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"newActivtyItems" object:nil];
        }
        else if([bumpedStatus isEqualToString:@"YES"]){
            //take user to mate's WTS to Bump it
            NSLog(@"listing and bumped status %@ %@", bumpedStatus, listing);
            
            PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"forSaleItems" objectId:listing];
            
            ForSaleListing *vc = [[ForSaleListing alloc]init];
            vc.listingObject = listingObject;
            vc.source = @"push";
            vc.fromBuyNow = YES;
            vc.pureWTS = YES;
            vc.fromPush = YES;

            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            
            if (nav.presentedViewController) {
                
                //nav bar is showing something
                if ([nav.presentedViewController isKindOfClass:[NavigationController class]]) {
                    
                    //2nd nav is showing so push from there instead of tab bar nav
                    NavigationController *presenter = (NavigationController*)nav.presentedViewController;
                    [presenter pushViewController:vc animated:YES];
                }
            }
            //if user is looking at mainsearch VC
            else if(nav.visibleViewController.presentedViewController){
                //2nd nav is showing so push from there instead of tab bar nav
                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                [presenter pushViewController:vc animated:YES];
            }
            else{
                //no other VC showing so push!
                [nav pushViewController:vc animated:YES];
            }
        }
        else if([strMsg containsString:@"started following you"]){
            [Answers logCustomEventWithName:@"Opened listing after receiving Bump Push"
                           customAttributes:@{}];
            
            //open app on activity screen
            self.tabBarController.selectedIndex = 1;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"newActivtyItems" object:nil];
        }
        else{
            //force refresh of inbox
            self.tabBarController.selectedIndex = 3;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessage" object:nil];
            
            //if user is viewing a listing from search then when we switch tabs the message button won't disappear
            //force it's disappearance via observer (need to grab the navController of the view we're going to)
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"switchedTabs" object:nav];
        }
    }
    else{
        //app is active and got push
        
        if([strMsg hasSuffix:@"liked your listing"]){
            //show just liked drop down
            
            //check not already on activity feed
            if (self.tabBarController.selectedIndex != 1) {
                //now check if seen a drop down this session - if not then show
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"seenLikeDrop"] != YES){
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"seenLikeDrop"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"showBumpedDropDown" object:@[listing, strMsg]];
                }
                
                [self checkForActivity];
            }
            else{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"newActivtyItems" object:nil];
            }
        }
        else if([strMsg hasSuffix:@"started following you"]){
            //show just liked drop down
            
            //check not already on activity feed
            if (self.tabBarController.selectedIndex != 1) {
                //now check if seen a drop down this session - if not then show
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"seenFollowDrop"] != YES){
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"seenFollowDrop"];
                    
                    //listing is the id of the following user
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"showFollowedDropDown" object:@[listing, strMsg]];
                }
                
                [self checkForActivity];
            }
            else{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"newActivtyItems" object:nil];
            }
        }
        else if([bumpedStatus isEqualToString:@"YES"]){
            //show drop down of mate who's listed an item for sale
//            NSLog(@"show fb drop down from delegate");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showDropDown" object:listing];
        }
        else if([strMsg hasSuffix:@"just listed an item for sale"]){
            NSLog(@"show sub drop in app");
            //show listing posted by subscribed to user drop down in-app
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showSubListingdDrop" object:@[listing, strMsg]];
        }
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

    NSLog(@"url %@", url);
    
    //does this interfere with paypal handling of url scheme? NO
    // pass the url to the handle deep link call
    [[Branch getInstance]
     application:application
     openURL:url
     sourceApplication:sourceApplication
     annotation:annotation];

    if ([[url host] isEqualToString:@"profile"]) {
        NSLog(@"got a profile url for this profile:%@", [url path]);
        
        NSString *username = [[url path] stringByReplacingOccurrencesOfString:@"/" withString:@""];
        
        PFQuery *profileQuery = [PFUser query];
        [profileQuery whereKey:@"username" containedIn:@[username]];
        [profileQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                [Answers logCustomEventWithName:@"Link Opened"
                               customAttributes:@{
                                                  @"type":@"profile"
                                                  }];
                
                UserProfileController *vc = [[UserProfileController alloc]init];
                vc.user = (PFUser *)object;
                NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
                
                if (nav.visibleViewController.presentedViewController) {
                    
                    //nav bar is showing something
                    if ([nav.visibleViewController.presentedViewController isKindOfClass:[NavigationController class]]) {
                        
                        //2nd nav is showing so push from there instead of tab bar nav
                        NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                        [presenter pushViewController:vc animated:YES];
                    }
                }
                else{
                    //no other VC showing so push!
                    [nav pushViewController:vc animated:YES];
                }
            }
            else{
                NSLog(@"error finding user object %@", error);
            }
        }];
    }
    
    //for listing share links e.g. bump://selling/LISTINGID
    
    else if ([[url host] isEqualToString:@"selling"]){
        NSString *listingId = [[url path] stringByReplacingOccurrencesOfString:@"/" withString:@""];
        
        [Answers logCustomEventWithName:@"Link Opened"
                       customAttributes:@{
                                          @"type":@"for sale"
                                          }];
        
        PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"forSaleItems" objectId:listingId];
        
        ForSaleListing *vc = [[ForSaleListing alloc]init];
        vc.listingObject = listingObject;
        vc.source = @"link";
        vc.fromBuyNow = YES;
        vc.pureWTS = YES;
        vc.fromPush = YES;

        NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
        
        if (nav.visibleViewController.presentedViewController) {
            
            //nav bar is showing something
            if ([nav.visibleViewController.presentedViewController isKindOfClass:[NavigationController class]]) {
                
                //2nd nav is showing so push from there instead of tab bar nav
                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                [presenter pushViewController:vc animated:YES];
            }
        }
        else{
            //no other VC showing so push!
            [nav pushViewController:vc animated:YES];
        }
    }
    
    //for wanted listing share links e.g. bump://wanted/LISTINGID
    
    else if ([[url host] isEqualToString:@"wanted"]){
        NSString *listingId = [[url path] stringByReplacingOccurrencesOfString:@"/" withString:@""];
        
        [Answers logCustomEventWithName:@"Link Opened"
                       customAttributes:@{
                                          @"type":@"wanted"
                                          }];
        
        PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"wantobuys" objectId:listingId];
        
        ListingController *vc = [[ListingController alloc]init];
        vc.listingObject = listingObject;
        NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
        
        if (nav.visibleViewController.presentedViewController) {

            //nav bar is showing something
            if ([nav.visibleViewController.presentedViewController isKindOfClass:[NavigationController class]]) {
                
                //2nd nav is showing so push from there instead of tab bar nav
                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                [presenter pushViewController:vc animated:YES];
            }
        }
        else{
            //no other VC showing so push!
            [nav pushViewController:vc animated:YES];
        }
    }
    
    //for verifying emails upon signup e.g. bump://verifyEmail/
    
    else if ([[url host] isEqualToString:@"verifyEmailSignUp"]){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"verifyEmail" object:nil];
    }
    
    //when user taps a password reset link in email e.g. bump://resetPassword/
    else if ([[url host] isEqualToString:@"resetPassword"]){
        NSString *userId = [[[url path] stringByReplacingOccurrencesOfString:@"/" withString:@""]stringByReplacingOccurrencesOfString:@"-" withString:@""];

        resetPassController *vc = [[resetPassController alloc]init];
        vc.resetMode = YES;
        vc.userId = userId;
        NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
        [nav.visibleViewController.navigationController pushViewController:vc animated:YES];
    }
    
    //when user returns from PayPal merchant onboarding e.g. bump://paypal/
    else if ([[url host] isEqualToString:@"paypal"]){
        
        NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
        NSArray *urlComponents = [[NSString stringWithFormat:@"%@", url] componentsSeparatedByString:@"&"];
        
        for (NSString *keyValuePair in urlComponents)
        {
            NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
            NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
            NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
            
            [queryStringDictionary setObject:value forKey:key];
        }
        
        NSLog(@"url components: %@", queryStringDictionary);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"paypalOnboardingReturn" object:queryStringDictionary];
    }
    
    //when user returns from PayPal order creation e.g. bump://order/
    else if ([[url host] isEqualToString:@"order"]){
        
        NSString *status = [[url path] stringByReplacingOccurrencesOfString:@"/" withString:@""];

        //depending on URL passed back, we know if user has successfully confirmed the order
        if ([status isEqualToString:@"success"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"paypalCreatedOrderSuccess" object:nil];
        }
        else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"paypalCreatedOrderFailed" object:nil];
        }
    }
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation
            ];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    [self invalidateTimers];
    
    //record last active time
    [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"lastActiveTime"];
    
//    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"longTermLocalSeen"] != YES){
//        
//        //schedule 6 day inactivity local notification
//        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
//        dayComponent.day = 6;
//        NSCalendar *theCalendar = [NSCalendar currentCalendar];
//        NSDate *dateToFire = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
//        
//        // Create new date
//        NSDateComponents *components1 = [theCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
//                                                       fromDate:dateToFire];
//        
//        NSDateComponents *components3 = [[NSDateComponents alloc] init];
//        
//        [components3 setYear:components1.year];
//        [components3 setMonth:components1.month];
//        [components3 setDay:components1.day];
//        
//        [components3 setHour:20];
//        
//        // Generate a new NSDate from components3.
//        NSDate * combinedDate = [theCalendar dateFromComponents:components3];
//        
//        UILocalNotification *localNotification = [[UILocalNotification alloc]init];
//        [localNotification setAlertBody:@"What's your next cop? Find it on BUMP 👊"];
//        [localNotification setFireDate: combinedDate];
//        [localNotification setTimeZone: [NSTimeZone defaultTimeZone]];
//        [localNotification setRepeatInterval: 0];
//        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
//    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    //reset so can see like drop downs again
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"seenLikeDrop"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"seenFollowDrop"];
    
    //in case app stuck in processing state
    [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"processingPurchase"];

    //save system resources & invalidate timers
    [self invalidateTimers];
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    //resetup timers
    if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications] == NO) {
        [self setupTimers];
    }
    
    // removed as user was switching apps and kept scrolling to top
    // only refresh after inactivity of 1 hour
    if ([[NSUserDefaults standardUserDefaults]valueForKey:@"lastActiveTime"]){
        
        NSDate *lastActive = [[NSUserDefaults standardUserDefaults]valueForKey:@"lastActiveTime"];
        
//        NSLog(@"last active: %@", lastActive);
        
        NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:lastActive];
        double secondsInAnHour = 3600;
        NSInteger hoursSinceLastActive = distanceBetweenDates / secondsInAnHour;
        
        if (hoursSinceLastActive > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshHome" object:nil];
        }
    }
    else{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshHome" object:nil];
    }
    
    //seems to be a bug, only resets to zero after setting badge to >0 first
    self.installation.badge = 1;
    self.installation.badge = 0;
    [self.installation saveEventually];
    
    [self checkMesages];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self setupTimers];
    
    [FBSDKAppEvents activateApp];
    
    if ([PFUser currentUser]) {
        [[PFUser currentUser]setObject:[NSDate date] forKey:@"lastActive"];
        [[PFUser currentUser]addObject:[NSDate date] forKey:@"activeSessions"];
        [[PFUser currentUser]saveInBackground];
        
        [Answers logCustomEventWithName:@"User began session"
                       customAttributes:@{
                                          @"username":[PFUser currentUser].username
                                          }];
        
        //when user resumes app lets check for activity notifications (already done by setting up timers)

    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    // handler code here
    
    NSLog(@"url recieved: %@", url);
    
    return YES;
}

-(BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"switchedTabs" object:viewController];
    
    if ([viewController isKindOfClass:[NavigationController class]]) {
        
        NavigationController *nav = (NavigationController*)viewController;
        if ([nav.visibleViewController isKindOfClass:[CreateTab class]]) {
            
            if (self.savingListing) {
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"still_saving_pop_up_seen" properties:@{}];
                
                //don't show create a listing VC until first listing has finished saving
                [self showAlertWithTitle:@"Save In Progress" andMsg:@"Please wait until your previous item has finished posting before listing another item for sale\n\nYou can check the progress of this at the top of the Home Feed"];
                return NO;
            }
            
            CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
            NavigationController *saleNav = [[NavigationController alloc] initWithRootViewController:vc];
            [self.tabBarController presentViewController:saleNav animated:YES completion:nil];
            return NO;
        }
    }

    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController
{
    //notification used to disimss bar button when tabs switched on a modal VC that doesn't responds to VWDis
    [[NSNotificationCenter defaultCenter] postNotificationName:@"switchedTabs" object:viewController];

    static UIViewController *previousController = nil;
    static int previousTab = 0;
        
    if (previousTab == tabBarController.selectedIndex && tabBarController.selectedIndex == 0) {
        NavigationController *nav = (NavigationController*)tabBarController.selectedViewController;
        
        if (nav.visibleViewController.presentedViewController) {
            
            //nav bar is showing something
            if ([nav.visibleViewController.presentedViewController isKindOfClass:[NavigationController class]]) {
                
                //2nd nav is showing something
                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
//                NSLog(@"presenter's nav bar visible %@", [presenter.visibleViewController class]);
                
                //check if its a for sale  listing VC - if it is, pop the nav bar
                if (![presenter.visibleViewController  isKindOfClass:[searchedViewC class]]) {
                    [presenter popViewControllerAnimated:YES];
                }
                else{
                    //scroll to top of searchVC
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"scrollSearchTop" object:viewController];
                }
            }
        }
        else{
            //no other VC showing
            NSLog(@"no vc being presented");
        }
    }
    
    if (previousController == viewController) {
        // the same tab was tapped a second time
        if ([viewController isKindOfClass:[NavigationController class]]) {
            NavigationController *vc = (NavigationController *)viewController;
            if ([vc.visibleViewController isKindOfClass:[InboxViewController class]]){
                [self.inboxView doubleTapScroll];
            }
            else if ([vc.visibleViewController isKindOfClass:[activityVC class]]){
                [self.activityView doubleTapScroll];
            }
            else if ([vc.visibleViewController isKindOfClass:[PurchaseTab class]]){
                [self.purchaseView doubleTapScroll];
            }
        }
    }
    
    previousTab = (int)tabBarController.selectedIndex;
    previousController = viewController;
}

#pragma mark - web view delegates
-(void)paidPressed{
    //do nothing
}

-(void)cancelWebPressed{
    [self.web dismissViewControllerAnimated:YES completion:nil];
}

-(void)cameraPressed{
    //do nothing
}

-(void)screeshotPressed:(UIImage *)screenshot withTaps:(int)taps{
    //do nothing
}

#pragma mark - app store observer delegates

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
                // Call the appropriate custom method for the transaction state.
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"In progress");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseStarted" object:nil];
                [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"processingPurchase"];
                break;
            case SKPaymentTransactionStateDeferred:
                //pending
                NSLog(@"Deferred");
                
                [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"processingPurchase"];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseDeferred" object:nil];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"Failed");
                
                [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"processingPurchase"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseFailed" object:transaction];
                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"Purchased");

                [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"processingPurchase"];
                [self validateReceiptForTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                //called when user switches phones or something similar and transfers the previous purchases across
                //doesn't apply
                //also called when a user purchases an item that hasn't had the transaction completed call
                NSLog(@"Restored");
                
                [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"processingPurchase"];
                [self validateReceiptForTransaction:transaction];

//                [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseRestored" object:nil];
                break;
            default:
                // For debugging
                [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"processingPurchase"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseFailed" object:transaction];

                NSLog(@"Unexpected transaction state %@", @(transaction.transactionState));
                break;
        }
    }
}

-(void)validateReceiptForTransaction:(SKPaymentTransaction *)transaction{
    
    //validate receipt
    // Load the receipt from the app bundle.
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
    if (!receipt) {
        /* No local receipt -- handle the error. */
        NSLog(@"no receipt error!");
        
        [Answers logCustomEventWithName:@"Paid Boost Error"
                       customAttributes:@{
                                          @"type":@"No receipt"
                                          }];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseFailed" object:transaction];
        return;
    }
    
    /* ... Send the receipt data to your server ... */
    
    NSString *dataString = [receipt base64EncodedStringWithOptions:0];
    NSDictionary *params = @{@"receipt": dataString};
    
    [PFCloud callFunctionInBackground:@"verifyPurchase" withParameters:params block:^(NSDictionary *response, NSError *error) {
        if (!error) {
            NSLog(@"verification response %@", response);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseComplete" object:transaction];
        }
        else{
            NSLog(@"verification error %@", error);
            
            [Answers logCustomEventWithName:@"Paid Boost Error"
                           customAttributes:@{
                                              @"type":[NSString stringWithFormat:@"Receipt Verification error %@", error.description]
                                              }];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseFailed" object:transaction];

        }
    }];
    
}

// Respond to Universal Links
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    BOOL handledByBranch = [[Branch getInstance] continueUserActivity:userActivity];
    
    return handledByBranch;
}

-(void)setupIntercomListener{
    int intercomUnread = (int)[Intercom unreadConversationCount];
    self.profileView.messagesUnseen = intercomUnread;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateIntercomUnread:)
                                                 name:IntercomUnreadConversationCountDidChangeNotification
                                               object:nil];
}

-(void)updateIntercomUnread:(NSNotification *)not{
    int intercomUnread = (int)[Intercom unreadConversationCount];
//    NSLog(@"updating intercom unread: %lu", (unsigned long)[Intercom unreadConversationCount]);
    self.profileView.messagesUnseen = intercomUnread;
    
    if (intercomUnread > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NewTBMessage" object:nil];
    }
    
    [self calcProfileBadge];
}

-(void)calcProfileBadge{
    
    //check if any support or team bump messages unseen
    int tabInt = 0;
    
    if (self.profileView.messagesUnseen > 0) {
        tabInt++;
    }
    
    //then get number of unseen orders
    if (self.profileView.ordersUnseen > 0) {
        tabInt += self.profileView.ordersUnseen;
    }
    
    //add all together and set tab badge
    if (tabInt == 0) {
        [[self.tabBarController.tabBar.items objectAtIndex:4] setBadgeValue:nil];
    }
    else if(tabInt > 9){
        [[self.tabBarController.tabBar.items objectAtIndex:4] setBadgeValue:@"9+"];
    }
    else{
        [[self.tabBarController.tabBar.items objectAtIndex:4] setBadgeValue:[NSString stringWithFormat:@"%d",tabInt]];
    }
}

-(void)profileBadgeRefresh{
    [self checkForOrders];
}

#pragma mark - fetch IAP
- (void)validateProductIdentifiers:(NSArray *)productIdentifiers
{
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
                                          initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    
    // Keep a strong reference to the request.
    self.request = productsRequest;
    productsRequest.delegate = self;
    [productsRequest start];
}

// SKProductsRequestDelegate protocol method
- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response
{
//    NSLog(@"got product request response %@", response);
    
    self.products = response.products;
    
    for (SKProduct *product in self.products) {
        
        if ([product.localizedTitle isEqualToString:@"BOOST"]) {
            
            //set button title w/ price
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
            [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
            [numberFormatter setLocale:product.priceLocale];
            
            self.boostPriceString = [numberFormatter stringFromNumber:product.price];
            
//            NSLog(@"GOT BOOST PRODUCT: %@", self.boostPriceString);
            
            self.BOOSTProduct = product;
            
        }
    }
}

// Custom method to calculate the SHA-256 hash using Common Crypto
- (NSString *)hashedValueForAccountName:(NSString*)userAccountName
{
    const int HASH_SIZE = 32;
    unsigned char hashedChars[HASH_SIZE];
    const char *accountName = [userAccountName UTF8String];
    size_t accountNameLen = strlen(accountName);
    
    // Confirm that the length of the user name is small enough
    // to be recast when calling the hash function.
    if (accountNameLen > UINT32_MAX) {
        NSLog(@"Account name too long to hash: %@", userAccountName);
        return nil;
    }
    CC_SHA256(accountName, (CC_LONG)accountNameLen, hashedChars);
    
    // Convert the array of bytes into a string showing its hex representation.
    NSMutableString *userAccountHash = [[NSMutableString alloc] init];
    for (int i = 0; i < HASH_SIZE; i++) {
        // Add a dash every four bytes, for readability.
        if (i != 0 && i%4 == 0) {
            [userAccountHash appendString:@"-"];
        }
        [userAccountHash appendFormat:@"%02x", hashedChars[i]];
    }
    
    return userAccountHash;
}

-(void)setupTimers{
    NSLog(@"setup timers called");

    if (!self.messagesTimer) {
        self.messagesTimer = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(checkMesages) userInfo:nil repeats:YES];
        [self.messagesTimer fire];
    }

    if (!self.ordersTimer) {
        self.ordersTimer = [NSTimer scheduledTimerWithTimeInterval:300.0 target:self selector:@selector(checkForOrders) userInfo:nil repeats:YES];
        [self.ordersTimer fire];
    }

    if (!self.activityTimer) {
        self.activityTimer = [NSTimer scheduledTimerWithTimeInterval:100.0 target:self selector:@selector(checkForActivity) userInfo:nil repeats:YES];
        [self.activityTimer fire];
    }
}

-(void)invalidateTimers{
    NSLog(@"invalidate called");
    
    if (self.messagesTimer) {
        [self.messagesTimer invalidate];
        self.messagesTimer = nil;
    }
    
    if (self.ordersTimer) {
        [self.ordersTimer invalidate];
        self.ordersTimer = nil;
    }
    
    if (self.activityTimer) {
        [self.activityTimer invalidate];
        self.activityTimer = nil;
    }
    
}

#pragma mark - create a listing observer callbacks

-(void)listingStarted{
    self.savingListing = YES;
}

-(void)listingFinished{
    self.savingListing = NO;
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [self.tabBarController presentViewController:alertView animated:YES completion:nil];
}

@end
