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
@property (nonatomic, strong) NSArray *convoObjects;

@property (nonatomic, strong) NSMutableArray *unseenMessages;

@property (nonatomic, strong) NSString *selectedConvo;

@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

//@property (nonatomic, strong) PFLiveQueryClient *client;
//@property (nonatomic, strong) PFQuery *query;
//@property (nonatomic, strong) PFLiveQuerySubscription *subscription;

@property (nonatomic, strong) NSDateFormatter *dateFormat;

@end
