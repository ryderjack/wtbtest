//
//  engageTracker.m
//  wtbtest
//
//  Created by Jack Ryder on 20/06/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "engageTracker.h"

@implementation engageTracker


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    self.doneButton.alpha = 0.0;
    self.numberSelected = 0;
}

- (IBAction)onePressed:(id)sender {
    if (self.onePressed.selected == YES) {
        //deselect
        [self.onePressed setSelected:NO];
        self.numberSelected = 0;

    }
    else{
        [self.onePressed setSelected:YES];
        self.numberSelected = 1;

        [self.twoPressed setSelected:NO];
        [self.threePressed setSelected:NO];
        [self.fourPressed setSelected:NO];
        [self.fivePressed setSelected:NO];

    }
    [self showHideDoneButton];

}
- (IBAction)twoPressed:(id)sender {
    if (self.twoPressed.selected == YES) {
        //deselect
        [self.twoPressed setSelected:NO];
        self.numberSelected = 0;

    }
    else{
        [self.twoPressed setSelected:YES];
        self.numberSelected = 2;

        [self.onePressed setSelected:NO];
        [self.threePressed setSelected:NO];
        [self.fourPressed setSelected:NO];
        [self.fivePressed setSelected:NO];
        
    }
    [self showHideDoneButton];

}
- (IBAction)threePressed:(id)sender {
    if (self.threePressed.selected == YES) {
        //deselect
        [self.threePressed setSelected:NO];
        self.numberSelected = 0;

    }
    else{
        [self.threePressed setSelected:YES];
        self.numberSelected = 3;

        [self.onePressed setSelected:NO];
        [self.twoPressed setSelected:NO];
        [self.fourPressed setSelected:NO];
        [self.fivePressed setSelected:NO];
        
    }
    [self showHideDoneButton];

}
- (IBAction)fourPressed:(id)sender {
    if (self.fourPressed.selected == YES) {
        //deselect
        [self.fourPressed setSelected:NO];
        self.numberSelected = 0;

    }
    else{
        [self.fourPressed setSelected:YES];
        self.numberSelected = 4;

        [self.onePressed setSelected:NO];
        [self.twoPressed setSelected:NO];
        [self.threePressed setSelected:NO];
        [self.fivePressed setSelected:NO];
    }
    [self showHideDoneButton];

}
- (IBAction)fivePressed:(id)sender {
    if (self.fivePressed.selected == YES) {
        //deselect
        [self.fivePressed setSelected:NO];
        self.numberSelected = 0;
    }
    else{
        [self.fivePressed setSelected:YES];
        self.numberSelected = 5;
        
        [self.onePressed setSelected:NO];
        [self.twoPressed setSelected:NO];
        [self.threePressed setSelected:NO];
        [self.fourPressed setSelected:NO];
    }
    
    [self showHideDoneButton];
}

-(void)showDoneButton{
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.doneButton.alpha = 1.0f;
                         self.bottomLabel.alpha = 0.0;
                         
                     }
                     completion:^(BOOL finished) {
                         self.doneShowing = YES;
                     }];
    
}

-(void)hideDoneButton{

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.doneButton.alpha = 0.0f;
                         self.bottomLabel.alpha = 1.0;
                         
                     }
                     completion:^(BOOL finished) {
                         self.doneShowing = NO;
                     }];
}
- (IBAction)donePressed:(id)sender {
    if (self.numberSelected != 0) {
//        [self.delegate donePressedWithNumber:self.numberSelected];
    }
}

-(void)showHideDoneButton{
    if (self.numberSelected == 0) {
        //hide
        [self hideDoneButton];
    }
    else{
        //show
        [self showDoneButton];
    }
}
- (IBAction)addPicPressed:(id)sender {
    [self.delegate addImagePressed];
}
@end
