//
//  ExplainViewController.h
//  wtbtest
//
//  Created by Jack Ryder on 04/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CreateViewController.h"

@interface ExplainViewController : UITableViewController <CreateViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *gridCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *chatCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *cartCell;

@property (weak, nonatomic) IBOutlet UILabel *labelOne;
@property (weak, nonatomic) IBOutlet UILabel *labelTwo;
@property (weak, nonatomic) IBOutlet UILabel *labelThree;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UIImageView *firstImageView;
@property (weak, nonatomic) IBOutlet UIImageView *secondImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thirdImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (nonatomic) BOOL introMode;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@end
