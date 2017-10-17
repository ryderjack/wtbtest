//
//  segmentedTableView.h
//  wtbtest
//
//  Created by Jack Ryder on 01/10/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "HMSegmentedControl.h"

@class segmentedTableView;

@protocol segmentedViewDelegate <NSObject>
- (void)dismissUnreadSupport;
@end

@interface segmentedTableView : UITableViewController

//delegate
@property (nonatomic, weak) id <segmentedViewDelegate> delegate;

@property (nonatomic, strong) NSMutableArray *purchased;
@property (nonatomic, strong) NSMutableArray *sold;

//custom segment control
@property (nonatomic, strong) HMSegmentedControl *segmentedControl;

//quries - first & second refer to the segments from the segment control
@property (nonatomic, strong) PFQuery *firstInfin;
@property (nonatomic, strong) PFQuery *firstPull;

@property (nonatomic, strong) PFQuery *secondInfin;
@property (nonatomic, strong) PFQuery *secondPull;

@property (nonatomic) int firstSkipped;
@property (nonatomic) int secondSkipped;

@property (nonatomic) BOOL firstPullFinished;
@property (nonatomic) BOOL firstInfinFinished;

@property (nonatomic) BOOL secondPullFinished;
@property (nonatomic) BOOL secondInfinFinished;

@property (nonatomic, strong) NSDateFormatter *dateFormat;

//mode
@property (nonatomic) BOOL supportMode;

//no results label
@property (nonatomic, strong) UILabel *noResultsLabel;

//support unseen total
@property (nonatomic) int supportUnseen;


@end
