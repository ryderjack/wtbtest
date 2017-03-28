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
    
    // create circular image views
    [self setImageBorder:self.friendImageOne];
    [self setImageBorder:self.friendImageTwo];
    [self setImageBorder:self.friendImageThree];
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
