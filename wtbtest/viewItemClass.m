//
//  viewItemClass.m
//  wtbtest
//
//  Created by Jack Ryder on 17/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "viewItemClass.h"

@implementation viewItemClass


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    self.backgroundColor = [UIColor clearColor];
    self.insideView.layer.cornerRadius = 10;
    
    self.itemImageView.layer.cornerRadius = 40;
    self.itemImageView.layer.masksToBounds = YES;
    self.itemImageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.itemImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    self.descriptionLabel.adjustsFontSizeToFitWidth = YES;
    self.descriptionLabel.minimumScaleFactor=0.5;
    
    self.priceLabel.adjustsFontSizeToFitWidth = YES;
    self.priceLabel.minimumScaleFactor=0.5;
    
    self.sizeLabel.adjustsFontSizeToFitWidth = YES;
    self.sizeLabel.minimumScaleFactor=0.5;
    
    self.timeLabel.adjustsFontSizeToFitWidth = YES;
    self.timeLabel.minimumScaleFactor=0.5;
    
    self.locationLabel.adjustsFontSizeToFitWidth = YES;
    self.locationLabel.minimumScaleFactor=0.5;
}
- (IBAction)visitButtonPressed:(id)sender {
    [self.delegate visitPressed];
}
- (IBAction)imageButtonPressed:(id)sender {
    [self.delegate imagePressed];
}


@end
