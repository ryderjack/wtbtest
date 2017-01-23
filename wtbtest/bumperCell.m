//
//  bumperCell.m
//  wtbtest
//
//  Created by Jack Ryder on 17/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "bumperCell.h"

@implementation bumperCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.userImageView.layer.cornerRadius = 25;
    self.userImageView.layer.masksToBounds = YES;
    self.userImageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.userImageView.contentMode = UIViewContentModeScaleAspectFill;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
