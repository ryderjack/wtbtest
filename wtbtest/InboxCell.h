//
//  InboxCell.h
//  wtbtest
//
//  Created by Jack Ryder on 23/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface InboxCell : UITableViewCell
@property (weak, nonatomic) IBOutlet PFImageView *userPicView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet PFImageView *wtbImageView;
@property (weak, nonatomic) IBOutlet UILabel *wtbTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *wtbPriceLabel;
@property (weak, nonatomic) IBOutlet PFImageView *seenImageView;
@property (weak, nonatomic) IBOutlet PFImageView *unreadDot;


@end
