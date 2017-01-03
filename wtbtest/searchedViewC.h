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

@class searchedViewC;
@protocol searchedViewCDelegate <NSObject>
- (void)cancellingOtherSearch;
-(void)enteredSearchTerm:(NSString *)term;
@end

@interface searchedViewC : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout, ExploreCellDelegate, UISearchBarDelegate, FilterDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) NSMutableArray *filtersArray;
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
@property (weak, nonatomic) IBOutlet UIImageView *filterBGView;

//location
@property (nonatomic, strong) PFGeoPoint *currentLocation;

@property (nonatomic, strong) PFQuery *infiniteQuery;
@property (nonatomic, strong) PFQuery *pullQuery;
@property (nonatomic) int lastInfinSkipped;
@property (nonatomic) BOOL pullFinished;
@property (nonatomic) BOOL infinFinished;

@property (nonatomic, weak) id <searchedViewCDelegate> delegate;

@end
