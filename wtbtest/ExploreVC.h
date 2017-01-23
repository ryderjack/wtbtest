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

@interface ExploreVC : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate, FilterDelegate, ExploreCellDelegate, dropDelegate, TheMainSearchViewDelegate, customAlertDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) NSMutableArray *resultIDs;
@property (weak, nonatomic) IBOutlet UILabel *noresultsLabel;
@property (strong, nonatomic) UILabel *noUserLabel;
@property (weak, nonatomic) IBOutlet UIImageView *noResultsImageView;

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

@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

@property (nonatomic, strong) DGActivityIndicatorView *spinner;

@property (nonatomic) BOOL filtersON;
@property (nonatomic) BOOL listingTapped;
@property (nonatomic) BOOL cleverMode;
@property (nonatomic) BOOL ignoreShownTo;

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

//custom alert view
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;
@end
