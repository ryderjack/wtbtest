//
//  InboxViewController.h
//  wtbtest
//
//  Created by Jack Ryder on 17/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InboxCell.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "MessageViewController.h"
#import "HMSegmentedControl.h"

@interface InboxViewController : UITableViewController <messagesDelegate>

@property (nonatomic, strong) InboxCell *cell;
@property (nonatomic, strong) NSMutableArray *convoObjects;

@property (nonatomic, strong) NSMutableArray *unseenConvos;

@property (nonatomic, strong) NSString *selectedConvo;

@property (nonatomic, strong) NSDateFormatter *dateFormat;

@property (nonatomic, strong) PFQuery *infiniteQuery;
@property (nonatomic, strong) PFQuery *pullQuery;
@property (nonatomic) int lastSkipped;
@property (nonatomic) BOOL pullFinished;
@property (nonatomic) BOOL infinFinished;

//selling query setup
@property (nonatomic, strong) PFQuery *sellingInfiniteQuery;
@property (nonatomic, strong) PFQuery *sellingPullQuery;
@property (nonatomic) int sellingSkipped;
@property (nonatomic) BOOL sellingPullFinished;
@property (nonatomic) BOOL sellingInfinFinished;

//buying query setup
@property (nonatomic, strong) PFQuery *buyingInfiniteQuery;
@property (nonatomic, strong) PFQuery *buyingPullQuery;
@property (nonatomic) int buyingSkipped;
@property (nonatomic) BOOL buyingPullFinished;
@property (nonatomic) BOOL buyingInfinFinished;

@property (nonatomic, strong) UILabel *topLabel;
@property (nonatomic, strong) UILabel *bottomLabel;

@property (nonatomic) BOOL justViewedMsg;

@property (nonatomic, strong) PFObject *lastConvo;
@property (nonatomic, strong) NSDate *lastSentDate;

@property (nonatomic, strong) NSIndexPath *lastConvoIndex;
@property (nonatomic, strong) NSIndexPath *lastBuyingIndex;
@property (nonatomic, strong) NSIndexPath *lastSellingIndex;


@property (nonatomic, strong) PFInstallation *currentInstallation;

//updating inbox cell
@property (nonatomic, strong) PFObject *lastMessageInConvo;
@property (nonatomic) BOOL updatingLastMessage;

//custom segment control
@property (nonatomic, strong) HMSegmentedControl *segmentedControl;

//inbox modes
@property (nonatomic, strong) NSMutableArray *buyingConvos;
@property (nonatomic, strong) NSMutableArray *buyingConvoIds;

@property (nonatomic, strong) NSMutableArray *sellingConvos;
@property (nonatomic, strong) NSMutableArray *sellingConvoIds;

@property (nonatomic, strong) NSMutableArray *allConvoIds;

//segment control unread badges
@property (nonatomic, strong) UIView *allBadge;
@property (nonatomic, strong) UIView *buyingBadge;
@property (nonatomic, strong) UIView *sellingBadge;


-(void)doubleTapScroll;

@end
