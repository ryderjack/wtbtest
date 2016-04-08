//
//  searchResultsController.h
//  wtbtest
//
//  Created by Jack Ryder on 06/04/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class searchResultsController;

@protocol searchResultsDelegate <NSObject>
- (void)favouriteTapped:(NSString *)favourite;
@end

@interface searchResultsController : UITableViewController <UISearchResultsUpdating>

@property (nonatomic, weak) id <searchResultsDelegate> delegate;
@property (nonatomic, strong) NSArray *allResults;
@property (nonatomic, strong) NSMutableArray *visibleResults;
@property (nonatomic) BOOL filterEnabled;
@end
