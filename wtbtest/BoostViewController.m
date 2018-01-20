//
//  BoostViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 15/01/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import "BoostViewController.h"

@implementation BoostViewController


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    [self.introLowerLabel setHidden:YES];
    [self.bolttImageView setHidden:YES];
    
    [self.successLowerLabel setHidden:YES];
    [self.lowerTimerLabel setHidden:YES];
    
    if ([self.mode isEqualToString:@"countdown"]) {
//        self.timerLabel.timerType = MZTimerLabelTypeTimer;
//        [self.timerLabel setCountDownTime:100];
//        [self.timerLabel start];
    }
    else if([self.mode isEqualToString:@"success"]){
        self.topLabel.text = @"Congrats your listing is now at the top of the BUMP Feed";
        [self.topLabel sizeToFit];
        
        [self.lowerWaitLabel setHidden:YES];
        [self.timerLabel setHidden:YES];

        [self.bolttImageView setImage:[UIImage imageNamed:@"boltBlue"]];
        [self.bolttImageView setHidden:NO];
        
        [self.successLowerLabel setHidden:NO];
        [self.lowerTimerLabel setHidden:NO];

    }
    else if([self.mode isEqualToString:@"boost"]){
        self.topLabel.text = @"Tap BOOST to put your listing to the top of the BUMP Feed for everyone to see";
        [self.topLabel sizeToFit];
        
        [self.mainButton setTitle:@"B O O S T" forState:UIControlStateNormal];
        
        [self.introLowerLabel setHidden:NO];
        [self.bolttImageView setHidden:NO];
        
        [self.timerLabel setHidden:YES];
        [self.lowerWaitLabel setHidden:YES];
    }
}

- (IBAction)mainButtonPressed:(id)sender {
    
    if ([self.mode isEqualToString:@"boost"]) {
        [self.delegate BoostMainButtonPressedRemindMode:NO];
    }
    else{
        [self.delegate BoostMainButtonPressedRemindMode:YES];
    }
}

@end
