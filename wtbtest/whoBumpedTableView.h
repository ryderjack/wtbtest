//
//  whoBumpedTableView.h
//  wtbtest
//
//  Created by Jack Ryder on 17/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <UIKit/UIKit.h>
#import "SearchCell.h"
#import "HMSegmentedControl.h"
#import <MBProgressHUD.h>
#import <SpinKit/RTSpinKitView.h>

@interface whoBumpedTableView : UITableViewController <SearchCellDelegate>

@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) NSArray *bumpArray;

//modes
@property (nonatomic, strong) NSString *mode;

//following/followers
@property (nonatomic, strong) PFUser *user;

//check if user is looking at their own following page
//this is so we can update local dic if needs be
@property (nonatomic) BOOL ownFollowing;

//queries
@property (nonatomic) BOOL infinLoadFinished;
@property (nonatomic) BOOL pullFinished;
@property (nonatomic) int skipNumber;
@property (nonatomic, strong) PFQuery *pullQuery;
@property (nonatomic, strong) PFQuery *infinQuery;
@property (nonatomic) BOOL infinEmpty;

//likes
@property (nonatomic) BOOL firstLoad;
@property (nonatomic, strong) NSString *listingId;

//suggested
@property (nonatomic, strong) NSArray *followingArray;
@property (nonatomic, strong) HMSegmentedControl *segmentedControl;
@property (nonatomic, strong) NSMutableArray *suggestedResults;
@property (nonatomic, strong) NSMutableArray *suggestedResultsIds;

@property (nonatomic, strong) UIView *suggestedView;

//facebook
@property (nonatomic, strong) NSMutableArray *facebookResults;
@property (nonatomic, strong) NSArray *friendsArray;
@property (nonatomic, strong) NSMutableArray *facebookIdResults;

@property (nonatomic) BOOL fbEmpty;
@property (nonatomic) int fbSkip;

@property (nonatomic) BOOL fbPullFinished;
@property (nonatomic) BOOL fbInfinFinished;

@property (nonatomic, strong) UIView *facebookView;

@property (nonatomic) BOOL inviteMode;

@property (nonatomic) BOOL connectedPayPal;
@property (nonatomic, strong) NSString *facebookId;

@property (nonatomic) BOOL tappedCell;
@property (nonatomic) NSIndexPath *tappedIndex;

//hud
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

//suggested query
@property (nonatomic, strong) PFQuery *suggestedQuery;
@property (nonatomic, strong) PFQuery *suggestedInfinQuery;

@end
