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

@interface InboxViewController : UITableViewController

@property (nonatomic, strong) InboxCell *cell;
@property (nonatomic, strong) NSMutableArray *convoObjects;

@property (nonatomic, strong) NSMutableArray *unseenConvos;

@property (nonatomic, strong) NSString *selectedConvo;

@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

@property (nonatomic, strong) NSDateFormatter *dateFormat;

@property (nonatomic, strong) PFQuery *infiniteQuery;
@property (nonatomic, strong) PFQuery *pullQuery;

@property (nonatomic) int lastSkipped;
@property (nonatomic) BOOL pullFinished;
@property (nonatomic) BOOL infinFinished;

@property (nonatomic, strong) UILabel *topLabel;
@property (nonatomic, strong) UILabel *bottomLabel;

@property (nonatomic) BOOL justViewedMsg;

@end
