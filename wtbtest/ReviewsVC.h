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

@interface ReviewsVC : UITableViewController

@property (nonatomic, strong) NSMutableArray *feedbackArray;
@property (nonatomic, strong) PFUser *user;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;


@end
