//
//  selectCell.m
//  wtbtest
//
//  Created by Jack Ryder on 23/04/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "selectCell.h"

@implementation selectCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)segmentChanged:(id)sender {
    if (self.segmentControl.selectedSegmentIndex == 0) {
        self.firstSelected = YES;
        [self.delegate genderSelected:@"Mens"];
    }
    else{
        self.firstSelected = NO;
        [self.delegate genderSelected:@"Womens"];
    }
}

@end
