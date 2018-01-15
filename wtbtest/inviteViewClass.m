//
//  inviteViewClass.m
//  wtbtest
//
//  Created by Jack Ryder on 05/03/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "inviteViewClass.h"

@implementation inviteViewClass


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    if (self.screenshotMode) {
        [self.friendImageOne setHidden:YES];
        [self.friendImageTwo setHidden:YES];
        [self.friendImageThree setHidden:YES];
        
        [self.inviteTitleLabel setHidden:YES];
        [self.friendsLabel setHidden:YES];
        
        [self.screenshotLabel setHidden:NO];
        
        [self.whatsappSSButton setHidden:NO];
        [self.whatsAppLabelSS setHidden:NO];
        
        [self.messengerSSLabel setHidden:NO];
        [self.messengerSSLabel setHidden:NO];
        
        [self.whatsLabel setHidden:YES];
        [self.whatsAppButton setHidden:YES];
        
        [self.messsengerLabel setHidden:YES];
        [self.messengerButton setHidden:YES];
        
        [self.textButton setHidden:YES];
        [self.moreLabel setHidden:YES];

    }
    else{
        [self.screenshotLabel setHidden:YES];
        
        [self.whatsappSSButton setHidden:YES];
        [self.whatsAppLabelSS setHidden:YES];
        
        [self.messengerSSButton setHidden:YES];
        [self.messengerSSLabel setHidden:YES];
        
        // create circular image views
        [self setImageBorder:self.friendImageOne];
        [self setImageBorder:self.friendImageTwo];
        [self setImageBorder:self.friendImageThree];
    }
}

- (IBAction)whatsappPressed:(id)sender {
    [self.delegate whatsappPressed];
}
- (IBAction)messengerPressed:(id)sender {
    [self.delegate messengerPressed];
}
- (IBAction)textPressed:(id)sender {
    [self.delegate textPressed];
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

@end
