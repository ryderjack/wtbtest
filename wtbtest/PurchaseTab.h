//
//  PurchaseTab.h
//  wtbtest
//
//  Created by Jack Ryder on 20/02/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MBProgressHUD.h>
#import <DGActivityIndicatorView.h>
#import <Parse/Parse.h>
#import <iCarousel.h>
#import "PurchaseTabHeader.h"
#import "droppingTodayView.h"
#import <SpinKit/RTSpinKitView.h>
#import "TOJRWebView.h"
#import "customAlertViewClass.h"

@interface PurchaseTab : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,iCarouselDataSource, iCarouselDelegate, JRWebViewDelegate,customAlertDelegate>

//cv
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

//products
@property (nonatomic, strong) NSMutableArray *products;
@property (nonatomic, strong) NSMutableArray *addedIDs;
@property (nonatomic, strong) NSMutableArray *WTBMatches;
@property (nonatomic, strong) NSMutableArray *featured;
@property (nonatomic, strong) NSMutableArray *infinMatches;

//spinner
@property (nonatomic, strong) DGActivityIndicatorView *spinner;

//hud
@property (nonatomic, strong) RTSpinKitView *spinnerHUD;
@property (nonatomic, strong) MBProgressHUD *hud;

//get related for-sale items
@property (nonatomic) BOOL pullFinished;
@property (nonatomic) BOOL infinFinished;
@property (nonatomic) BOOL finalLoading;
@property (nonatomic, strong) PFQuery *infiniteQuery;
@property (nonatomic, strong) PFQuery *pullQuery;
@property (nonatomic) int skipped;
@property (nonatomic) int infinFinalMode;

//prompt button
@property (weak, nonatomic) IBOutlet UIButton *anotherPromptButton;

//featured
@property (nonatomic) BOOL featuredFinished;

//header
@property (nonatomic, strong) PurchaseTabHeader *headerView;
@property (nonatomic, strong) iCarousel *carousel;
@property (nonatomic, strong) droppingTodayView *scheduledView;
@property (nonatomic, strong) droppingTodayView *shopView;
@property (nonatomic, strong) NSTimer *scrollTimer;
@property (nonatomic) BOOL pausedInProgress;
@property (nonatomic) BOOL autoScroll;

//shop
@property (nonatomic, strong) NSArray *shopArray;
@property (nonatomic, strong) NSArray *supArray;
@property (nonatomic, strong) NSArray *yeezyArray;
@property (nonatomic, strong) NSArray *palaceArray;

@property (nonatomic) BOOL yeezySeen;
@property (nonatomic) BOOL supremeSeen;
@property (nonatomic) BOOL palaceSeen;

@property (nonatomic) BOOL tappedItem;
@property (nonatomic, strong) NSString *selectedShop;

@property (nonatomic, strong) NSMutableArray *supSeenArray;
@property (nonatomic, strong) NSMutableArray *yeezySeenArray;
@property (nonatomic, strong) NSMutableArray *palaceSeenArray;

@property (nonatomic) BOOL shopLoadAgain;
@property (nonatomic) BOOL supLoadAgain;
@property (nonatomic) BOOL yeezyLoadAgain;
@property (nonatomic) BOOL palaceLoadAgain;

//scheduled releases
@property (nonatomic, strong) NSMutableArray *scheduledArray;
@property (nonatomic, strong) NSDate *thisMorning;
@property (nonatomic) BOOL showDropPageToo;
@property (nonatomic) BOOL TBCMode;
@property (nonatomic) BOOL updatingDates;
@property (nonatomic, strong) NSDateFormatter *dayOfWeekFormatter;

//web
@property (nonatomic, strong) TOJRWebView *web;

//array of WTB indexes
@property (nonatomic, strong) NSMutableArray *listingIndexesArray;
@property (nonatomic, strong) NSMutableArray *addedIndexes;

//custom alert view
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic) BOOL alertShowing;
@property (nonatomic) BOOL dropIntro;

//seller
@property (nonatomic) BOOL isSeller;
@property (nonatomic, strong) NSString *usernameToList;

//affiliate products
@property (nonatomic, strong) NSMutableArray *affiliateProducts;
@property (nonatomic) int affiliateIndex;
@property (nonatomic) int indexToAdd;
@property (nonatomic) BOOL showAffiliates;
@property (nonatomic, strong) NSMutableArray *affiliatesSeen;
@property (nonatomic) BOOL cleverMode;

//if affiliates is on then this is 26, else 30
@property (nonatomic) int retrieveLimit;
@property (nonatomic) int remainingAffiliates;

//scroll to top
-(void)doubleTapScroll;
-(void)getAffiliateData;

@end
