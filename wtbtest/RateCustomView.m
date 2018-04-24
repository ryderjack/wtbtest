//
//  RateCustomView.m
//  wtbtest
//
//  Created by Jack Ryder on 15/03/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "RateCustomView.h"

@implementation RateCustomView


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    self.starNumber = 0;
    
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor=0.5;
    
    self.descriptionLabel.adjustsFontSizeToFitWidth = YES;
    self.descriptionLabel.minimumScaleFactor=0.5;
}

- (IBAction)ratePressed:(id)sender {
    [self.delegate ratePressedWithNumber:self.starNumber];
}
- (IBAction)dismissPressed:(id)sender {
    [self.delegate dismissRatePressed];
}
- (IBAction)firstStarPressed:(id)sender {
    self.starNumber = 1;

    if (self.firstStar.selected == YES) {
        [self.secondStar setSelected:NO];
        [self.thirdStar setSelected:NO];
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
    else{
        [self.firstStar setSelected:YES];
    }
    [self.secondStar setSelected:NO];
    [self.thirdStar setSelected:NO];
    [self.fourthStar setSelected:NO];
    [self.fifthStar setSelected:NO];
}
- (IBAction)secondStarPressed:(id)sender {
    self.starNumber = 2;

    if (self.secondStar.selected == YES) {
        [self.thirdStar setSelected:NO];
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
    else{
        [self.secondStar setSelected:YES];
        
        [self.firstStar setSelected:YES];
        [self.thirdStar setSelected:NO];
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
}
- (IBAction)thirdStarPressed:(id)sender {
    self.starNumber = 3;

    if (self.thirdStar.selected == YES) {
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
    else{
        [self.thirdStar setSelected:YES];
        
        [self.firstStar setSelected:YES];
        [self.secondStar setSelected:YES];
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
}
- (IBAction)fourthStarPressed:(id)sender {
    self.starNumber = 4;

    if (self.fourthStar.selected == YES) {
        [self.fifthStar setSelected:NO];
    }
    else{
        [self.fourthStar setSelected:YES];
        
        [self.firstStar setSelected:YES];
        [self.secondStar setSelected:YES];
        [self.thirdStar setSelected:YES];
        [self.fifthStar setSelected:NO];
    }
}
- (IBAction)fifthStarPressed:(id)sender {
    self.starNumber = 5;

    if (self.fifthStar.selected == YES) {
    }
    else{
        [self.fifthStar setSelected:YES];
        
        [self.firstStar setSelected:YES];
        [self.secondStar setSelected:YES];
        [self.thirdStar setSelected:YES];
        [self.fourthStar setSelected:YES];
        
        [self.delegate ratePressedWithNumber:self.starNumber];

    }
}

@end
