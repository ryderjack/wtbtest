//
//  activityVC.h
//  wtbtest
//
//  Created by Jack Ryder on 09/02/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "activityCell.h"
#import <Parse/Parse.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>

@interface activityVC : UITableViewController <activityCellDelegate>

@property (nonatomic, strong) NSMutableArray *resultsArray;

@property (nonatomic, strong) UIRefreshControl *refresherControl;

//queries
@property (nonatomic) BOOL infinLoadFinished;
@property (nonatomic) BOOL pullFinished;
@property (nonatomic) int skipNumber;
@property (nonatomic, strong) PFQuery *pullQuery;
@property (nonatomic, strong) PFQuery *infinQuery;
@property (nonatomic) BOOL infinEmpty;

//no results labels
@property (nonatomic, strong) UILabel *topLabel;
@property (nonatomic, strong) UILabel *bottomLabel;

//spinner
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

//reload cells after been tapped
@property (nonatomic) BOOL tappedCell;
@property (nonatomic) NSIndexPath *tappedIndex;

//scroll to top from tab bar
-(void)doubleTapScroll;

@end
