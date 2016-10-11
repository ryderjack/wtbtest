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
#import "searchResultsController.h"
#import <MBProgressHUD.h>
#import <DGActivityIndicatorView.h>

@interface ExploreVC : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate, FilterDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate, searchResultsDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *results;
@property (weak, nonatomic) IBOutlet UILabel *noresultsLabel;
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

@property (nonatomic, strong) NSMutableArray *filtersArray;

//search
@property (strong, nonatomic) UISearchController *searchController;
@property (nonatomic, strong) NSString *searchString;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic) BOOL searchEnabled;
@property (nonatomic, strong) searchResultsController *resultsController;

@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

@property (nonatomic, strong) DGActivityIndicatorView *spinner;

@property (nonatomic) BOOL filtersTapped;
@property (nonatomic) BOOL searchShowing;
@property (nonatomic) BOOL resultsShowing;
@property (nonatomic) BOOL listingTapped;

@property (nonatomic, strong) NSArray *uselessWords;
@end
