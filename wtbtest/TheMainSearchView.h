//
//  TheMainSearchView.h
//  
//
//  Created by Jack Ryder on 22/12/2016.
//
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "searchedViewC.h"
#import "HMSegmentedControl.h"

@class TheMainSearchView;
@protocol TheMainSearchViewDelegate <NSObject>
- (void)cancellingMainSearch;
@end

@interface TheMainSearchView : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, searchedViewCDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *userResults;
@property (nonatomic, strong) NSArray *listingResults;
@property (nonatomic) BOOL userSearch;

@property (nonatomic, strong) NSString *searchString;

@property (nonatomic, strong) UISearchBar *searchBar;

@property (strong, nonatomic) UILabel *noUserLabel;

@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

@property (nonatomic, weak) id <TheMainSearchViewDelegate> delegate;

@property (nonatomic, strong) PFGeoPoint *geoPoint;

//custom segment control
@property (nonatomic, strong) HMSegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIView *placeholderView;


@end
