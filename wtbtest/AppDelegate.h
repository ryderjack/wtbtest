//
//  AppDelegate.h
//  wtbtest
//
//  Created by Jack Ryder on 19/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WelcomeViewController.h"
#import "ExploreVC.h"
#import "ProfileController.h"
#import "InboxViewController.h"
#import "simpleCreateVC.h"
#import "UserProfileController.h"
#import "PurchaseTab.h"
#import "TOJRWebView.h"
#import <StoreKit/StoreKit.h>
#import "CreateTab.h"
#import "CreateForSaleListing.h"
#import "activityVC.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, JRWebViewDelegate,SKPaymentTransactionObserver,SKProductsRequestDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;
@property (strong, nonatomic) WelcomeViewController *welcomeView;
@property (strong, nonatomic) simpleCreateVC *simpleCreateView;
@property (strong, nonatomic) ExploreVC *exploreView;
@property (strong, nonatomic) UserProfileController *profileView;
@property (strong, nonatomic) InboxViewController *inboxView;
@property (nonatomic, strong) PFInstallation *installation;
@property (nonatomic, strong) PurchaseTab *purchaseView;
@property (nonatomic, strong) CreateTab *createTabView;
@property (nonatomic, strong) CreateForSaleListing *createSaleListing;
@property (nonatomic, strong) activityVC *activityView;

@property (nonatomic, strong) NSMutableArray *unseenMessages;

//web view
@property (nonatomic, strong) TOJRWebView *web;

//fetch IAPs
@property (nonatomic, strong) SKProductsRequest *request;
@property (nonatomic, strong) SKProduct *BOOSTProduct;

@property (nonatomic, strong) NSArray *products;
@property (nonatomic, strong) NSArray *productIdentifiersArray;

@property (nonatomic, strong) NSString *boostPriceString;

//timers
@property (nonatomic, strong) NSTimer *messagesTimer;
@property (nonatomic, strong) NSTimer *ordersTimer;
@property (nonatomic, strong) NSTimer *activityTimer;

//listing
@property (nonatomic) BOOL savingListing;

@end

