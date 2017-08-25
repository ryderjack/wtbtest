//
//  detailSellingCell.m
//  wtbtest
//
//  Created by Jack Ryder on 07/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "detailSellingCell.h"

@implementation detailSellingCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
    self.itemTitleLabel.minimumScaleFactor=0.5;
}

@end
