//
//  boostController.h
//  wtbtest
//
//  Created by Jack Ryder on 21/05/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>
#import <StoreKit/StoreKit.h>

@class boostController;

@protocol boostDelegate <NSObject>
- (void)dismissedWithPurchase:(NSString *)purchase;
@end

@interface boostController : UITableViewController <SKProductsRequestDelegate>

//delegate
@property (nonatomic, weak) id <boostDelegate> delegate;

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *boost1Cell;
@property (strong, nonatomic) IBOutlet UITableViewCell *boost2Cell;
@property (strong, nonatomic) IBOutlet UITableViewCell *boost3Cell;
@property (strong, nonatomic) IBOutlet UITableViewCell *spaceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *topSpaceCell;

//big button
@property (nonatomic, strong) UIButton *longButton;
@property (nonatomic) BOOL buttonShowing;
@property (nonatomic) BOOL introMode;

//labels
@property (weak, nonatomic) IBOutlet UILabel *featuredLabel;

//price labels
@property (weak, nonatomic) IBOutlet UILabel *highlightPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *searchPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *featuredPriceLabel;

//buttons
@property (weak, nonatomic) IBOutlet UIButton *highlightBuyButton;
@property (weak, nonatomic) IBOutlet UIButton *searchBoostButton;
@property (weak, nonatomic) IBOutlet UIButton *featuredBoostButton;


//listing
@property (nonatomic, strong) PFObject *listing;
@property (nonatomic) BOOL savingInProcess;
@property (nonatomic) BOOL highlightOn;
@property (nonatomic) BOOL featuredOn;
@property (nonatomic) BOOL searchOn;

@property (nonatomic) BOOL highlightPurchased;
@property (nonatomic) BOOL searchPurchased;
@property (nonatomic) BOOL featuredPurchased;


//HUD
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic) BOOL hudShowing;
@property (nonatomic) BOOL shouldShowHUD;

//new icons
@property (weak, nonatomic) IBOutlet UIImageView *highlightNewIcon;
@property (weak, nonatomic) IBOutlet UIImageView *searchNewIcon;
@property (weak, nonatomic) IBOutlet UIImageView *featuredNewIcon;

//app store
@property (nonatomic, strong) SKProductsRequest *request;
@property (nonatomic, strong) NSArray *products;
@property (nonatomic, strong) NSArray *productIdentifiersArray;

@property (nonatomic, strong) SKProduct *featuredProduct;
@property (nonatomic, strong) SKProduct *searchBoostProduct;
@property (nonatomic, strong) SKProduct *highlightProduct;

//free boost
@property (nonatomic) BOOL freeBoost;


@end
