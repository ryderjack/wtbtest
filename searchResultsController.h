//
//  searchResultsController.h
//  wtbtest
//
//  Created by Jack Ryder on 06/04/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@class searchResultsController;

@protocol searchResultsDelegate <NSObject>
- (void)favouriteTapped:(NSString *)favourite;
- (void)userTapped:(PFUser *)user;
- (void)willdiss:(BOOL)response;
@end

@interface searchResultsController : UITableViewController <UISearchResultsUpdating>

@property (nonatomic, weak) id <searchResultsDelegate> delegate;
@property (nonatomic, strong) NSArray *itemResults;
@property (nonatomic, strong) NSArray *userResults;

@property (nonatomic, strong) NSMutableArray *visibleResults;
@property (nonatomic) BOOL filterEnabled;
@property (nonatomic) BOOL userSearch;

@property (nonatomic, strong) PFQuery *appearUserQuery;
@property (nonatomic) BOOL queryAllowed;

@property (nonatomic) BOOL cancelClicked;

@end
