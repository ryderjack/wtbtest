//
//  InboxCell.m
//  wtbtest
//
//  Created by Jack Ryder on 23/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "InboxCell.h"

@implementation InboxCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.usernameLabel.adjustsFontSizeToFitWidth = YES;
    self.usernameLabel.minimumScaleFactor=0.5;
    
    self.wtbTitleLabel.adjustsFontSizeToFitWidth = YES;
    self.wtbTitleLabel.minimumScaleFactor=0.5;
    
    self.wtbPriceLabel.adjustsFontSizeToFitWidth = YES;
    self.wtbPriceLabel.minimumScaleFactor=0.5;
    
    self.timeLabel.adjustsFontSizeToFitWidth = YES;
    self.timeLabel.minimumScaleFactor=0.5;    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
