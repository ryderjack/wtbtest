//
//  ConnectPayPalViewClass.m
//  wtbtest
//
//  Created by Jack Ryder on 06/01/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import "ConnectPayPalViewClass.h"

@implementation ConnectPayPalViewClass

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (IBAction)connectPressed:(id)sender {
    [self.delegate connectPressed];
}
- (IBAction)remindMePressed:(id)sender {
    [self.delegate remindMePressed];
}

@end
