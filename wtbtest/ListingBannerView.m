//
//  ListingBannerView.m
//  wtbtest
//
//  Created by Jack Ryder on 24/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "ListingBannerView.h"

@implementation ListingBannerView


- (void)drawRect:(CGRect)rect {
    // Drawing code
    self.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
    self.itemTitleLabel.minimumScaleFactor=0.5;
    
//    [self.buyButton setHidden:YES];
}

- (IBAction)bannerButtonTapped:(id)sender {
    [self.delegate bannerTapped];
}
- (IBAction)buyButtonTapped:(id)sender {
    [self.delegate buyButtonBannerTapped];
}

@end
