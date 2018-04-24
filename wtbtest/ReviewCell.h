//
//  ReviewCell.h
//  wtbtest
//
//  Created by Jack Ryder on 09/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@class ReviewCell;
@protocol ReviewCellDelegate <NSObject>
- (void)listingCellButtonPressed: (ReviewCell *)cell;
@end

@interface ReviewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet PFImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *starImageView;
@property (weak, nonatomic) IBOutlet PFImageView *itemImageView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *listingButton;

@property (nonatomic, weak) id <ReviewCellDelegate> delegate;

@end
