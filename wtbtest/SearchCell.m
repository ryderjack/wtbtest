//
//  SearchCell.m
//  wtbtest
//
//  Created by Jack Ryder on 15/02/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "SearchCell.h"

@implementation SearchCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.usernameLabel.adjustsFontSizeToFitWidth = YES;
    self.usernameLabel.minimumScaleFactor=0.5;
    
    self.nameLabel.adjustsFontSizeToFitWidth = YES;
    self.nameLabel.minimumScaleFactor=0.5;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)followPressed:(id)sender {
    NSLog(@"sender: %@", sender);
    
    [self.delegate followButtonPressed:self];
}

@end
