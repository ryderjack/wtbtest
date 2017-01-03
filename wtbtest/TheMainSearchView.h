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

@class TheMainSearchView;
@protocol TheMainSearchViewDelegate <NSObject>
- (void)cancellingMainSearch;
@end

@interface TheMainSearchView : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, searchedViewCDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;

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


@end
