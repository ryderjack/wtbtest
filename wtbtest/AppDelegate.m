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
//        configuration.server = @"http://parseserver-3q4w2-env.us-east-1.elasticbeanstalk.com/parse";
//        configuration.server = @"https://live.bumpapi.com/parse";
        
        //preproduction
//        configuration.server = @"http://bump-preprod.us-east-1.elasticbeanstalk.com/parse"; //CHANGE remove these links for safety reasons from the actual build
//        configuration.server = @"https://preprod.bumpapi.com/parse";

        //dev server w/ dev DB
//        configuration.server = @"http://bump-staging-s3fa.us-east-1.elasticbeanstalk.com/parse";
        configuration.server = @"https://dev.bumpapi.com/parse";

    }]];

//    [Fabric with:@[[Crashlytics class]]]; ////////////////////CHANGE
//    [Mixpanel sharedInstanceWithToken:@"f83619c7bc4c4710bf87d892c0c170df"]; //CHANGE
    [HNKGooglePlacesAutocompleteQuery setupSharedQueryWithAPIKey:@"AIzaSyC812pR1iegUl3UkzqY0rwYlRmrvAAUbgw"];

    //production
    [Intercom setApiKey:@"ios_sdk-dcdcb0d85e2a1da18471b8506beb225e5800e7dd" forAppId:@"zjwtufx1"]; //CHANGE
    //dev
//    [Intercom setApiKey:@"ios_sdk-67598bd2fc99548a4f157a6c78c00c98da59991f" forAppId:@"bjtqi7s6"];
    
    if ([PFUser currentUser]) {
        
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
    
    self.createSaleListing = [[CreateForSaleListing alloc]init];
    
    [self.window setBackgroundColor:[UIColor whiteColor]];
    
//    NavigationController *navController = [[NavigationController alloc] initWithRootViewController:self.exploreView];
    NavigationController *navController6 = [[NavigationController alloc] initWithRootViewController:self.createTabView];
    NavigationController *navController2 = [[NavigationController alloc] initWithRootViewController:self.profileView];
//    NavigationController *navController3 = [[NavigationController alloc] initWithRootViewController:self.welcomeView];
    NavigationController *navController4 = [[NavigationController alloc] initWithRootViewController:self.inboxView];
    NavigationController *navController7 = [[NavigationController alloc] initWithRootViewController:self.purchaseView];
//    NavigationController *navController8 = [[NavigationController alloc] initWithRootViewController:self.createSaleListing];

    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:navController7,navController6,navController4, navController2, nil];
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
    tabBarItem1.image = [UIImage imageNamed:@"homeIconNEW"];
    tabBarItem1.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    tabBarItem1.selectedImage = [UIImage imageNamed:@"homeIconFilled"];

//    UITabBarItem *tabBarItem5 = [self.tabBarController.tabBar.items objectAtIndex:1];
//    tabBarItem5.image = [UIImage imageNamed:@"buyNowIcon"];
//    tabBarItem5.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    
    UITabBarItem *tabBarItem2 = [self.tabBarController.tabBar.items objectAtIndex:1];
    tabBarItem2.image = [UIImage imageNamed:@"CreateIconTag"];
    tabBarItem2.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    tabBarItem2.selectedImage = [UIImage imageNamed:@"CreateIconTagFill"];
    
    UITabBarItem *tabBarItem3 = [self.tabBarController.tabBar.items objectAtIndex:2];
    tabBarItem3.image = [UIImage imageNamed:@"messageTabIconGrey"];
    tabBarItem3.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    tabBarItem3.selectedImage = [UIImage imageNamed:@"messageTabIconFilled"];

    
    UITabBarItem *tabBarItem4 = [self.tabBarController.tabBar.items objectAtIndex:3];
    tabBarItem4.image = [UIImage imageNamed:@"userIconNEW"];
    tabBarItem4.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    tabBarItem4.selectedImage = [UIImage imageNamed:@"userIconFilled"];
    
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
//            NSTimer *timer2 = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(checkForTBMessages) userInfo:nil repeats:YES];
//            [timer2 fire];

            if ([[[PFUser currentUser] objectForKey:@"orderNumber"]intValue] > 0) {
//                NSTimer *timer3 = [NSTimer scheduledTimerWithTimeInterval:120.0 target:self selector:@selector(checkForSupportMessages) userInfo:nil repeats:YES];
//                [timer3 fire];
            }
            
            NSTimer *timer4 = [NSTimer scheduledTimerWithTimeInterval:300.0 target:self selector:@selector(checkForOrders) userInfo:nil repeats:YES];
            [timer4 fire];
        }
        else{
            [self checkMesages];
//            [self checkForTBMessages];
            
            if ([[[PFUser currentUser] objectForKey:@"orderNumber"]intValue] > 0) {
//                [self checkForSupportMessages];
            }
            [self checkForOrders];
        }
    }
    else{
//        NSTimer *timer2 = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(checkForTBMessages) userInfo:nil repeats:YES];
//        [timer2 fire];
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
        
        self.tabBarController.selectedIndex = 1;
    }
    else if ([localNotif.alertBody containsString:@"What's your next cop? Find it on BUMP"]){
        [Answers logCustomEventWithName:@"Opened 6 day Reminder Push"
                       customAttributes:@{}];
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"longTermLocalSeen"];
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
            
            PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"forSaleItems" objectId:listing];
            
            ForSaleListing *vc = [[ForSaleListing alloc]init];
            vc.listingObject = listingObject;
            vc.source = @"bump";
            vc.fromBuyNow = YES;
            vc.pureWTS = YES;
            vc.fromPush = YES;

            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            [nav pushViewController:vc animated:YES];
            
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

    //app store observer
    
//    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

    //reset BOOL which limits like drop downs to once per session
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"seenLikeDrop"];
    
//    if ([PFUser currentUser]) {
//        [self calcOrderNumber];
//    }
    
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
                        [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:[NSString stringWithFormat:@"%d", totalUnseen]];
                    }
                    else{
                        [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:nil];
                    }
                    
                    //add unseen orders to badge make sure this is bulletproof
//                    if (self.profileView.ordersUnseen > 0) {
//                        totalUnseen+= self.profileView.ordersUnseen;
//                    }
                    self.installation.badge = totalUnseen;
                    [self.installation saveEventually];
                }
                else{
                    [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:nil];
                    
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
    self.installation.channels = @[ @"global" ];
    [self.installation saveInBackground];
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    
//    NSDictionary *localUserInfo = notification.userInfo;
//    NSString *releaseLink = [localUserInfo valueForKey:@"link"];
//    NSString *itemTitle = [localUserInfo valueForKey:@"itemTitle"];
    
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
        
        self.tabBarController.selectedIndex = 1;
    }
    else{
        //fail safe
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
            
            //open WTS listing
            self.tabBarController.selectedIndex = 0;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"saleListingBumped" object:listing];
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
        else{
            //force refresh of inbox
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessage" object:nil];
            self.tabBarController.selectedIndex = 2;
            
            //if user is viewing a listing from search then when we switch tabs the message button won't disappear
            //force it's disappearance via observer (need to grab the navController of the view we're going to)
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"switchedTabs" object:nav];
        }
    }
    else{
        //app is active and got push
        
        if([strMsg containsString:@"liked your listing"]){
            //show just Bumped drop down
//            NSLog(@"show drop down %@   %@",listing,strMsg);
            
            //now check if seen a drop down this session - if not then show
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"seenLikeDrop"] != YES){
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"seenLikeDrop"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"showBumpedDropDown" object:@[listing, strMsg]];
            }
        }
        else if([bumpedStatus isEqualToString:@"YES"]){
            //show drop down of mate who's listed an item for sale
//            NSLog(@"show fb drop down from delegate");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showDropDown" object:listing];
        }
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

    NSLog(@"url %@", url);
    
    //for profile share links e.g. bump://profile/USERNAME

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

    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    // removed as user was switching apps and kept scrolling to top
    // only refresh after inactivity of 1 hour
    
    if ([[NSUserDefaults standardUserDefaults]valueForKey:@"lastActiveTime"]){
        
        NSDate *lastActive = [[NSUserDefaults standardUserDefaults]valueForKey:@"lastActiveTime"];
        
//        NSLog(@"last active: %@", lastActive);
        
        NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:lastActive];
        double secondsInAnHour = 3600;
        NSInteger hoursSinceLastActive = distanceBetweenDates / secondsInAnHour;
        
//        NSLog(@"hours since: %ld", (long)hoursSinceLastActive);

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
//    [self checkForTBMessages];
//    [self checkForSupportMessages];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSDKAppEvents activateApp];
    if ([PFUser currentUser]) {
        [[PFUser currentUser]setObject:[NSDate date] forKey:@"lastActive"];
        [[PFUser currentUser]addObject:[NSDate date] forKey:@"activeSessions"];
        [[PFUser currentUser]saveInBackground];
        
        [Answers logCustomEventWithName:@"User began session"
                       customAttributes:@{
                                          @"username":[PFUser currentUser].username
                                          }];
    }
    
    //cancel long term local push
//    NSArray *notificationArray = [[UIApplication sharedApplication] scheduledLocalNotifications];
//    for(UILocalNotification *notification in notificationArray){
//        if ([notification.alertBody.lowercaseString containsString:@"what's your next cop? find it on bump"]) {
//            // delete this notification
//            [[UIApplication sharedApplication] cancelLocalNotification:notification] ;
//        }
//    }
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"switchingTabs" object:viewController];

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
//            if ([vc.visibleViewController isKindOfClass:[ExploreVC class]]){
//                [self.exploreView doubleTapScroll];
//            }
            if ([vc.visibleViewController isKindOfClass:[InboxViewController class]]){
                [self.inboxView doubleTapScroll];
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
                NSLog(@"Restored");
                
                [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"processingPurchase"];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseDeferred" object:nil];

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
        
        [Answers logCustomEventWithName:@"Boost Purchase Failed"
                       customAttributes:@{
                                          @"error":@"no receipt"
                                          }];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseFailed" object:transaction];
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
            
            [Answers logCustomEventWithName:@"Boost Purchase Failed"
                           customAttributes:@{
                                              @"error":@"failed verification"
                                              }];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseFailed" object:transaction];

        }
    }];
    
}

-(BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler{
//    NSLog(@"continue user activity %@", userActivity);
    return YES;
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
    NSLog(@"updating intercom unread: %lu", (unsigned long)[Intercom unreadConversationCount]);
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
        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
    }
    else if(tabInt > 9){
        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:@"9+"];
    }
    else{
        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:[NSString stringWithFormat:@"%d",tabInt]];
    }
}

-(void)profileBadgeRefresh{
//    [self checkForTBMessages];
    [self checkForOrders];
//    [self checkForSupportMessages];
}

//-(void)calcOrderNumber{
//    PFQuery *buyingQuery = [PFQuery queryWithClassName:@"saleOrders"];
//    [buyingQuery whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
//    [buyingQuery whereKey:@"status" containedIn:@[@"live"]];
//    [buyingQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//        if (objects) {
////            NSLog(@"calc order number, got objects: %@", objects);
//
//            int buyCount = (int)objects.count;
//            __block int totalCount = (int)objects.count;
//
//            PFQuery *sellingQuery = [PFQuery queryWithClassName:@"saleOrders"];
//            [sellingQuery whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
//            [sellingQuery whereKey:@"status" equalTo:@"live"];
//            [sellingQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable sales, NSError * _Nullable error) {
//                if (objects) {
//                    int saleCount = (int)sales.count;
//                    totalCount += saleCount;
//
////                    int totalEarningsGBP = [[[PFUser currentUser]objectForKey:@"earnTotalGBP"]intValue];
////                    int totalEarningsUSD = [[[PFUser currentUser]objectForKey:@"earnTotalUSD"]intValue];
////                    int totalEarningsEUR = [[[PFUser currentUser]objectForKey:@"earnTotalEUR"]intValue];
////
////                    int totalSpentGBP = [[[PFUser currentUser]objectForKey:@"spendTotalGBP"]intValue];
////                    int totalSpentUSD = [[[PFUser currentUser]objectForKey:@"spendTotalUSD"]intValue];
////                    int totalSpentEUR = [[[PFUser currentUser]objectForKey:@"spendTotalEUR"]intValue];
////
////                    //update Intercom
////                    ICMUserAttributes *userAttributes = [ICMUserAttributes new];
////                    userAttributes.customAttributes = @{@"purchase_number" : @(buyCount),
////                                                        @"sale_number" : @(saleCount),
////                                                        @"order_number" : @(totalCount),
////                                                        };
////                    [Intercom updateUser:userAttributes];
//
////                    NSLog(@"orders: %d    sales: %d    purchases: %d",[[[PFUser currentUser]objectForKey:@"orderNumber"]intValue],[[[PFUser currentUser]objectForKey:@"saleNumber"]intValue],[[[PFUser currentUser]objectForKey:@"purchaseNumber"]intValue]);
//
//
//                    //if (for some unlikely reason) cloud code didn't update user's order number we re-save it here along w/ buy/sell counts
////                    if ([[[PFUser currentUser]objectForKey:@"orderNumber"]intValue] != totalCount) {
////                        [[PFUser currentUser]setObject:@(totalCount) forKey:@"orderNumber"];
////                        [[PFUser currentUser]setObject:@(saleCount) forKey:@"saleNumber"];
////                        [[PFUser currentUser]setObject:@(buyCount) forKey:@"purchaseNumber"];
////                        [[PFUser currentUser] saveInBackground];
////                    }
//                }
//                else{
//                    [Answers logCustomEventWithName:@"Order Calc Error"
//                                   customAttributes:@{
//                                                      @"type":@"sale"
//                                                      }];
//                }
//            }];
//        }
//        else{
//            [Answers logCustomEventWithName:@"Order Calc Error"
//                           customAttributes:@{
//                                              @"type":@"buy"
//                                              }];
//        }
//    }];
//}
@end
