//
//  mediumSizeAlertViewClass.m
//  wtbtest
//
//  Created by Jack Ryder on 06/01/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import "mediumSizeAlertViewClass.h"

@implementation mediumSizeAlertViewClass


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    [self.remindMeLaterButton setHidden:YES];
    [self.normalAlertLabel setHidden:YES];
    [self.normalAlertTitleLabel setHidden:YES];
    
    [self.remindMeLaterButton setHidden:YES];
    [self.reminderMainLabel setHidden:YES];
    [self.dollarImageView setHidden:YES];
    [self.doItLaterButton setHidden:YES];

    [self.leftButton setHidden:YES];
    [self.rightButton setHidden:YES];
    
    if(self.connectErrorMode){
        [self.lowerImageLabel setTextColor:[UIColor colorWithRed:1.00 green:0.43 blue:0.50 alpha:1.0]];
        self.lowerImageLabel.text = @"Connection Error";
        self.mainLabel.text = @"Looks like there was an error when connecting your PayPal account\n\nYou need to grant BUMP the relevant permissions when prompted\n\n\n";
        [self.dismissButton setTitle:@"Retry" forState:UIControlStateNormal];
        [self.remindMeLaterButton setHidden:NO];
    }
    else if(self.onboardingError){
        [self.lowerImageLabel setTextColor:[UIColor colorWithRed:1.00 green:0.43 blue:0.50 alpha:1.0]];
        self.lowerImageLabel.text = @"Connection Error";
        self.mainLabel.text = @"Make sure you've completed the full onboarding process\n\nYou also need to grant BUMP the relevant permissions when prompted\n\n\n";
        [self.dismissButton setTitle:@"Retry" forState:UIControlStateNormal];
        [self.remindMeLaterButton setHidden:NO];
    }
    else if(self.alertMode){
        [self.normalAlertLabel setHidden:NO];
        [self.normalAlertTitleLabel setHidden:NO];
        
        [self.ppImageView setHidden:YES];
        [self.mainLabel setHidden:YES];
        [self.lowerImageLabel setHidden:YES];
    }
    else if(self.reminderMode){
        
        [self.dismissButton setTitle:@"Enable Buy Now" forState:UIControlStateNormal];
        
        [self.doItLaterButton setHidden:NO];
        [self.reminderMainLabel setHidden:NO];
        [self.dollarImageView setHidden:NO];

        [self.remindMeLaterButton setHidden:YES];
        [self.normalAlertLabel setHidden:YES];
        [self.normalAlertTitleLabel setHidden:YES];
        
        [self.ppImageView setHidden:YES];
        [self.mainLabel setHidden:YES];
        [self.lowerImageLabel setHidden:YES];
    }
    else if(self.disableMode){
        
        [self.leftButton setHidden:NO];
        [self.rightButton setHidden:NO];
        [self.dollarImageView setHidden:NO];

        self.reminderMainLabel.text = @"Sure you want to disable Buy Now?\n\n10x more likely to sell your item\n\nBuyers can still message you with offers & questions";
        [self.doItLaterButton setTitle:@"Tap for more info" forState:UIControlStateNormal];
        [self.doItLaterButton setTitleColor:[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0] forState:UIControlStateNormal];
        
        [self.doItLaterButton setHidden:NO];
        [self.reminderMainLabel setHidden:NO];
        
        
        [self.remindMeLaterButton setHidden:YES];
        [self.normalAlertLabel setHidden:YES];
        [self.normalAlertTitleLabel setHidden:YES];
        
        [self.remindMeLaterButton setHidden:YES];
        
        [self.ppImageView setHidden:YES];
        [self.mainLabel setHidden:YES];
        [self.lowerImageLabel setHidden:YES];
    }
    
}

- (IBAction)buttonPressed:(id)sender {
    if (self.connectedMode) {
        [self.delegate mediumAlertButtonPressed:@"connected"];
    }
    else if(self.connectErrorMode){
        [self.delegate mediumAlertButtonPressed:@"error"];
    }
    else if(self.alertMode){
        [self.delegate mediumAlertButtonPressed:@"normal"];
    }
    else if(self.reminderMode){
        [self.delegate mediumAlertButtonPressed:@"reminder"];
    }
}
- (IBAction)remindMePressed:(id)sender {
    if (self.connectErrorMode) {
        [self.delegate mediumAlertRemindPressed:@"error"];
    }
    else if (self.disableMode) {
        [self.delegate mediumAlertRemindPressed:@"disable"];
    }
    else{
        [self.delegate mediumAlertRemindPressed:@"normal"];
    }
}

//disable pop up left & right buttons
- (IBAction)mediumAlertRightButtonPressed:(id)sender {
    [self.delegate mediumAlertRighPressed];
}
- (IBAction)mediumAlertLeftButtonPressed:(id)sender {
    [self.delegate mediumAlertLeftPressed];
}


@end
