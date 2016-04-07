//
//  searchResultsController.h
//  wtbtest
//
//  Created by Jack Ryder on 06/04/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface searchResultsController : UITableViewController <UISearchResultsUpdating>

@property (nonatomic, copy) NSString *filterString;

@property (readonly, copy) NSArray *visibleResults;

@end
