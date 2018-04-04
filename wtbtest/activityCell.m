//
//  activityCell.m
//  wtbtest
//
//  Created by Jack Ryder on 09/02/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import "activityCell.h"

@implementation activityCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)actionButtonPressed:(id)sender {
    [self.delegate cellButtonPressed:self];
}

@end
