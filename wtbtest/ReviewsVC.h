//
//  ReviewsVC.h
//  wtbtest
//
//  Created by Jack Ryder on 09/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "FeedbackController.h"
#import "HMSegmentedControl.h"

@interface ReviewsVC : UITableViewController <feedbackDelegate>

@property (nonatomic, strong) NSArray *totalFeedback;
@property (nonatomic, strong) NSMutableArray *purchasedFeedback;
@property (nonatomic, strong) NSMutableArray *soldFeedback;

@property (nonatomic, strong) PFUser *user;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) PFObject *selectedFbObject;

@property (nonatomic) BOOL singleMode;
@property (nonatomic, strong) PFObject *feedbackObject;

//header
@property (nonatomic, strong) HMSegmentedControl *segmentedControl;

//no results label
@property (nonatomic, strong) UILabel *noResultsLabel;

@end
