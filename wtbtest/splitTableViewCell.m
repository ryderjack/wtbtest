//
//  splitTableViewCell.m
//  wtbtest
//
//  Created by Jack Ryder on 01/10/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "splitTableViewCell.h"

@implementation splitTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
        
    self.bottomLabel.adjustsFontSizeToFitWidth = YES;
    self.bottomLabel.minimumScaleFactor=0.5;
    
    //round the corners
    [self.unreadIcon.layer setCornerRadius:2.5];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
