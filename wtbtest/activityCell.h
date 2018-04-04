//
//  activityCell.h
//  wtbtest
//
//  Created by Jack Ryder on 09/02/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@class activityCell;
@protocol activityCellDelegate <NSObject>
- (void)cellButtonPressed: (activityCell *)cell;
@end

@interface activityCell : UITableViewCell
@property (weak, nonatomic) IBOutlet PFImageView *cellImageView;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;

@property (nonatomic, weak) id <activityCellDelegate> delegate;

@end
