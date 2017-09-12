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
    [self.headerRetryButton setHidden:YES];
    [self.headerCancelButton setHidden:YES];

    self.simpleHeaderLabel.adjustsFontSizeToFitWidth = YES;
    self.simpleHeaderLabel.minimumScaleFactor=0.5;
    [self.progressView setHidden:YES];

}

@end
