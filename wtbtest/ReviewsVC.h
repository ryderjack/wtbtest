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

@interface ReviewsVC : UITableViewController <feedbackDelegate>

@property (nonatomic, strong) NSMutableArray *feedbackArray;
@property (nonatomic, strong) NSArray *totalFeedback;

@property (nonatomic, strong) PFUser *user;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) PFObject *selectedFbObject;

@end
