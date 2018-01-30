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
#import "simpleBannerHeader.h"
#import <SpinKit/RTSpinKitView.h>
#import "TOJRWebView.h"
#import "customAlertViewClass.h"
#import "TheMainSearchView.h"
#import <CoreLocation/CoreLocation.h>
#import "WelcomeViewController.h"
#import "RateCustomView.h"
#import "notificatView.h"
#import "FilterVC.h"
#import <YLProgressBar/YLProgressBar.h>
#import "BrowseLocation.h"
#import "engageTracker.h"
#import "ConnectPayPalViewClass.h"
#import "mediumSizeAlertViewClass.h"
#import <SafariServices/SafariServices.h>
#import "SettingsController.h"

@interface PurchaseTab : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,customAlertDelegate,UISearchBarDelegate,TheMainSearchViewDelegate,CLLocationManagerDelegate,dropDelegate,WelcomeDelegate,rateDelegate,FilterDelegate,inviteDelegate, BrowseLocationDelegate,ConnectPPDelegate,mediumSizeAVDelegate,SFSafariViewControllerDelegate,SettingsDelegate>

//cv
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

//search bar
@property (nonatomic, strong) UISearchBar *navSearchbar;

//currency
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

//products
@property (nonatomic, strong) NSMutableArray *products;
@property (nonatomic, strong) NSMutableArray *productIds;


//spinner
@property (nonatomic, strong) DGActivityIndicatorView *spinner;
@property (nonatomic, strong) DGActivityIndicatorView *hudSpinner;

//hud
@property (nonatomic, strong) RTSpinKitView *spinnerHUD;
@property (nonatomic, strong) MBProgressHUD *hud;

//get latest for-sale items
@property (nonatomic) BOOL pullFinished;
@property (nonatomic) BOOL infinFinished;
@property (nonatomic, strong) PFQuery *infiniteQuery;
@property (nonatomic, strong) PFQuery *pullQuery;
@property (nonatomic) int skipped;

@property (nonatomic) int skipNumb;

//prompt button
@property (weak, nonatomic) IBOutlet UIButton *anotherPromptButton;

//featured
@property (nonatomic) BOOL featuredFinished;

//header
@property (nonatomic, strong) simpleBannerHeader *headerView;
@property (nonatomic) BOOL postingMode;
@property (nonatomic) BOOL failedPosting;

@property (nonatomic) BOOL showEmailReminder;

@property (nonatomic, strong) UIImage *bannerImage;
@property (nonatomic, strong) PFObject *postingItem;

@property (nonatomic, strong) YLProgressBar *progressBar;


//array of WTB indexes
@property (nonatomic, strong) NSMutableArray *listingIndexesArray;
@property (nonatomic, strong) NSMutableArray *addedIndexes;

//custom alert view
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;
@property (nonatomic) BOOL alertShowing;
@property (nonatomic) BOOL dropIntro;

@property (nonatomic) BOOL tappedItem;
@property (nonatomic) BOOL wantedListing;


//location
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) BOOL locationAllowed;
@property (nonatomic, strong) PFGeoPoint *currentLocation;

//invite pop up
@property (nonatomic, strong, nullable) inviteViewClass *inviteView;
@property (nonatomic, strong, nullable) UIView *bgView;
@property (nonatomic, strong) UITapGestureRecognizer *tap;

//push alert #2 (1st is upon signup)
@property (nonatomic, strong) customAlertViewClass *pushAlert;
@property (nonatomic) BOOL shownPushAlert;

//custom rate
@property (nonatomic, strong) RateCustomView *rateView;
@property (nonatomic) BOOL lowRating;
@property (nonatomic, strong) UINavigationController *messageNav;

//bump in app notification
@property (nonatomic, strong) notificatView *dropDown;
@property (nonatomic, strong) NSIndexPath *lastSelected;
@property (nonatomic) BOOL screenshotShowing;

@property (nonatomic) BOOL justABump;
@property (nonatomic) BOOL justAMessage;

//boost
@property (nonatomic) BOOL justABOOST;
@property (nonatomic, strong) PFObject *boostListing;

@property (nonatomic) NSArray *wantedWords;
@property (nonatomic) NSArray *searchWords;
@property (nonatomic) BOOL sendMode;

//filter button
@property (weak, nonatomic) IBOutlet UIButton *filterButton;
@property (nonatomic, strong) NSMutableArray *filtersArray;
@property (nonatomic, strong) NSMutableArray *filterSizesArray;
@property (nonatomic, strong) NSMutableArray *filterBrandsArray;
@property (nonatomic, strong) NSMutableArray *filterColoursArray;
@property (nonatomic, strong) NSMutableArray *filterContinentsArray;

@property (nonatomic, strong) NSString *filterCategory;
@property (nonatomic) float filterLower;
@property (nonatomic) float filterUpper;

@property (weak, nonatomic) IBOutlet UILabel *noResultsLabel;
@property (nonatomic) BOOL filterIntro;

//floating location
@property (weak, nonatomic) IBOutlet UIButton *floatingLocationButton;
@property (nonatomic) float lastLocButtonY;

//@property (nonatomic) int skipNumb;

//scroll to top
-(void)doubleTapScroll;

//location string
@property (nonatomic, strong) NSString *locationFilter;
@property (weak, nonatomic) IBOutlet UIButton *locationBut;

//location filter view
@property (nonatomic, strong) BrowseLocation *locationFilterView;
@property (nonatomic) BOOL locationFilterShowing;

//how to buy intro
@property (nonatomic, strong) engageTracker *buyIntroView;
@property (nonatomic) BOOL buyIntroShowing;

//connect paypal intro
@property (nonatomic) BOOL showConnectPPPopUp;

@property (nonatomic, strong) ConnectPayPalViewClass *connectPPView;
@property (nonatomic) BOOL connectPPShowing;

@property (nonatomic, strong) mediumSizeAlertViewClass *connectedPPSuccessView;
@property (nonatomic, strong) mediumSizeAlertViewClass *ppAlertView;

//paypal onboarding
@property (nonatomic, strong) SFSafariViewController *paypalSafariView;
@property (nonatomic) BOOL addedPayPalObservers;
@property (nonatomic) BOOL paypalEnabled;
@property (nonatomic, strong) NSString *merchantId;
@property (nonatomic) BOOL existingUserPPAlert;
@property (nonatomic) BOOL onboardingError;
@property (nonatomic) BOOL emailMode;

//refresh control
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic) int cellHeight;
@end
