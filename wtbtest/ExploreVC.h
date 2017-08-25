//
//  ExploreVC.h
//  
//
//  Created by Jack Ryder on 29/02/2016.
//
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>
#import "FilterVC.h"
#import "ListingController.h"
#import <MBProgressHUD.h>
#import <DGActivityIndicatorView.h>
#import "ExploreCell.h"
#import "BumpVC.h"
#import "notificatView.h"
#import "TheMainSearchView.h"
#import "searchedViewC.h"
#import "customAlertViewClass.h"
#import "HMSegmentedControl.h"
#import "WelcomeViewController.h"
#import "TOJRWebView.h"
#import "RateCustomView.h"
#import "inviteViewClass.h"
#import "HomeHeaderView.h"
#import "engageTracker.h"
#import <SwipeView/SwipeView.h>

@interface ExploreVC : UIViewController <UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, FilterDelegate, ExploreCellDelegate, dropDelegate, TheMainSearchViewDelegate, customAlertDelegate, WelcomeDelegate, JRWebViewDelegate,rateDelegate,inviteDelegate,UISearchBarDelegate,HeaderDelegate, engageDelegate,SwipeViewDelegate, SwipeViewDataSource>

//location
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) BOOL locationAllowed;
@property (nonatomic, strong) PFGeoPoint *currentLocation;

@property (nonatomic, strong) PFQuery *infiniteQuery;
@property (nonatomic, strong) PFQuery *pullQuery;
@property (nonatomic) int lastInfinSkipped;
@property (nonatomic) BOOL pullFinished;
@property (nonatomic) BOOL infinFinished;
@property (weak, nonatomic) IBOutlet UIButton *filterButton;
@property (weak, nonatomic) IBOutlet UIImageView *filterBGView;

@property (nonatomic, strong) NSMutableArray *filtersArray;

//currency
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

@property (nonatomic, strong) DGActivityIndicatorView *spinner;

@property (nonatomic) BOOL featuredMode;
@property (nonatomic) BOOL filtersON;
@property (nonatomic) BOOL listingTapped;
@property (nonatomic) BOOL cleverMode;
@property (nonatomic) BOOL ignoreShownTo;
@property (nonatomic) BOOL ignoreShownToLatest;
@property (nonatomic) BOOL triedAlready;

@property (nonatomic) int pullLimit;
@property (nonatomic) int infinLimit;

@property (nonatomic) BOOL incompletePreviousPull;
@property (nonatomic) BOOL infinIncompletePreviousPull;
@property (nonatomic) BOOL recallMode;

@property (nonatomic, strong) NSArray *uselessWords;

//cell
@property (nonatomic, strong) ExploreCell *cell;
@property (nonatomic, strong) NSArray *calcdKeywords;

//bump in app notification
@property (nonatomic, strong) notificatView *dropDown;
@property (nonatomic, strong) NSIndexPath *lastSelected;
@property (nonatomic) BOOL justABump;
@property (nonatomic) NSArray *wantedWords;
@property (nonatomic) NSArray *searchWords;
@property (nonatomic) BOOL sendMode;

//custom alert view
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;
@property (nonatomic) BOOL searchIntroShowing;

//message sent in app notification
@property (nonatomic) BOOL justAMessage;

//segment control in header
@property (nonatomic, strong) HMSegmentedControl *segmentedControl;
@property (nonatomic) BOOL latestMode;

//push alert #2 (1st is upon signup)
@property (nonatomic, strong) customAlertViewClass *pushAlert;
@property (nonatomic) BOOL shownPushAlert;

//thrown user back to welcome VC
@property (nonatomic) BOOL welcomeShowing;

//web view for releases
@property (nonatomic, strong) TOJRWebView *web;

//custom rate
@property (nonatomic, strong) RateCustomView *rateView;
@property (nonatomic) BOOL lowRating;
@property (nonatomic, strong) UINavigationController *messageNav;

//engagement question pop up
@property (nonatomic, strong) engageTracker *engageView;
@property (nonatomic, strong) UINavigationController *engageQNav;

//invite pop up
@property (nonatomic, strong, nullable) inviteViewClass *inviteView;
@property (nonatomic, strong, nullable) UIView *bgView;
@property (nonatomic) BOOL alertShowing;
@property (nonatomic, strong) UITapGestureRecognizer *tap;

//header
@property (nonatomic, strong) NSArray *homeItems;
@property (nonatomic, strong) HomeHeaderView *headerView;
@property (nonatomic) BOOL gotCarousel;

//table view stuff
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet SwipeView *wantedSwipeView;
@property (weak, nonatomic) IBOutlet SwipeView *sellingSwipeView;

@property (nonatomic, strong) NSMutableArray *wantedMatches;
@property (nonatomic, strong) NSMutableArray *sellingMatches;

@property (weak, nonatomic) IBOutlet UILabel *noForSaleItemLabel;
@property (weak, nonatomic) IBOutlet UILabel *noWantedListingLabel;

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *wantedCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sellingCell;

-(void)doubleTapScroll;
@end
