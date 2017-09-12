//
//  simpleBannerHeader.m
//  wtbtest
//
//  Created by Jack Ryder on 07/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "simpleBannerHeader.h"

@implementation simpleBannerHeader

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.headerImageView setHidden:YES];
    self.simpleHeaderLabel.adjustsFontSizeToFitWidth = YES;
    self.simpleHeaderLabel.minimumScaleFactor=0.5;
}

@end
