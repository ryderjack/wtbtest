//
//  CreateTab.h
//  wtbtest
//
//  Created by Jack Ryder on 08/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "simpleCreateVC.h"
#import "CreateSuccessView.h"
#import "customAlertViewClass.h"

@interface CreateTab : UIViewController <successDelegate,UICollectionViewDelegate, UICollectionViewDataSource,customAlertDelegate>

//currency
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

//buttons
@property (weak, nonatomic) IBOutlet UIButton *bigWantButton;
@property (weak, nonatomic) IBOutlet UIButton *bigSellButton;

//success view
@property (nonatomic, strong) CreateSuccessView *successView;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic) BOOL setupYes;
@property (nonatomic) BOOL completionShowing;
@property (nonatomic, strong) PFObject *justPostedListing;

//success view products
@property (nonatomic, strong) NSArray *WTBArray;
@property (nonatomic, strong) NSArray *buyNowArray;

//success view mode
@property (nonatomic) BOOL sellingSuccessMode;

//intro mode
@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (nonatomic) BOOL introMode;
@property (nonatomic) BOOL createBPressed;
@property (nonatomic) BOOL createdAListing;

//custom alert view
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;
@property (nonatomic) BOOL shownPushAlert;
@end
