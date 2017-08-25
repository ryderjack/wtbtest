//
//  SmallWantedCell.m
//  wtbtest
//
//  Created by Jack Ryder on 11/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "SmallWantedCell.h"

@implementation SmallWantedCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.itemLowerLabel.adjustsFontSizeToFitWidth = YES;
    self.itemLowerLabel.minimumScaleFactor=0.5;
}

@end
