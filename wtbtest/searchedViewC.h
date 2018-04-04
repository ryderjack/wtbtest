//
//  searchedViewC.h
//  wtbtest
//
//  Created by Jack Ryder on 21/12/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>
#import "FilterVC.h"
#import "ListingController.h"
#import <MBProgressHUD.h>
#import <DGActivityIndicatorView.h>
#import "ExploreCell.h"
#import "searchBoostedHeader.h"
#import "simpleBannerHeader.h"
#import "CreateWTBPromptFooter.h"

@class searchedViewC;
@protocol searchedViewCDelegate <NSObject>
- (void)cancellingOtherSearch;
-(void)enteredSearchTerm:(NSString *)term inSellingSearch:(BOOL)mode;
@end

@interface searchedViewC : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout, UISearchBarDelegate, FilterDelegate, searchBoostDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) NSMutableArray *filtersArray;
@property (nonatomic, strong) NSMutableArray *filterSizesArray;
@property (nonatomic, strong) NSMutableArray *filterBrandsArray;
@property (nonatomic, strong) NSMutableArray *filterColoursArray;
@property (nonatomic, strong) NSMutableArray *filterContinentsArray;

@property (nonatomic, strong) NSString *filterCategory;

@property (nonatomic) float filterLower;
@property (nonatomic) float filterUpper;

@property (nonatomic, strong) NSString *searchString;

@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;
@property (nonatomic, strong) NSArray *uselessWords;
@property (weak, nonatomic) IBOutlet UILabel *noresultsLabel;

@property (nonatomic, strong) ExploreCell *cell;

@property (nonatomic, strong) NSIndexPath *lastSelected;

@property (nonatomic, strong) DGActivityIndicatorView *spinner;

@property (nonatomic, strong) UISearchBar *searchBar;

//filters
@property (weak, nonatomic) IBOutlet UIButton *filterButton;

//location
@property (nonatomic, strong) PFGeoPoint *currentLocation;

@property (nonatomic, strong) PFQuery *infiniteQuery;
@property (nonatomic, strong) PFQuery *pullQuery;
@property (nonatomic, strong) PFQuery *sizeQuery;

@property (nonatomic) int lastInfinSkipped;
@property (nonatomic) BOOL pullFinished;
@property (nonatomic) BOOL infinFinished;
@property (nonatomic) BOOL viewedListing;

@property (nonatomic, weak) id <searchedViewCDelegate> delegate;

//tab bar
@property (nonatomic, strong) NSNumber *tabBarHeight;

//header
//@property (nonatomic, strong) searchBoostedHeader *headerView;
@property (nonatomic, strong) NSArray *boostedResults;
@property (nonatomic) BOOL showBoostHeader;
@property (nonatomic) int headerSize;
@property (nonatomic) BOOL initialHeaderSizeSetup;

//footer
@property (nonatomic, strong) CreateWTBPromptFooter *promptFooterView;
@property (nonatomic) BOOL showFooter;

//mode
@property (nonatomic) BOOL sellingSearch;
@property (nonatomic) BOOL infinEmpty;

//wanted mode
@property (weak, nonatomic) IBOutlet UILabel *noWantedResultsLabel;

//header
@property (nonatomic, strong) simpleBannerHeader *bannerHeaderView;
@property (nonatomic) int cellHeight;

@end
