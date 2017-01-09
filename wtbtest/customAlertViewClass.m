//
//  customAlertViewClass.m
//  wtbtest
//
//  Created by Jack Ryder on 08/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "customAlertViewClass.h"

@implementation customAlertViewClass


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    self.messageLabel.adjustsFontSizeToFitWidth = YES;
    self.messageLabel.minimumScaleFactor=0.5;
    
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor=0.5;
    
    if (self.numberOfButtons == 2) {
        [self.doneButton setHidden:YES];
        [self.firstButton setHidden:NO];
        [self.secondButton setHidden:NO];
    }
    else{
        [self.doneButton setHidden:NO];
        [self.firstButton setHidden:YES];
        [self.secondButton setHidden:YES];
    }
}
- (IBAction)doneButtonPressed:(id)sender {
    NSLog(@"done pressed");
    [self.delegate donePressed];
}
- (IBAction)firstPressed:(id)sender {
    [self.delegate firstPressed];
}

- (IBAction)secondPressed:(id)sender {
    [self.delegate secondPressed];
}


@end
