//
//  ReviewCell.m
//  wtbtest
//
//  Created by Jack Ryder on 09/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ReviewCell.h"

@implementation ReviewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.commentLabel.adjustsFontSizeToFitWidth = YES;
    self.commentLabel.minimumScaleFactor=0.5;

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)reviewListingButtonPressed:(id)sender {
    [self.delegate listingCellButtonPressed:self];
}

@end
