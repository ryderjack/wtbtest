//
//  notificatView.m
//  wtbtest
//
//  Created by Jack Ryder on 15/12/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "notificatView.h"

@implementation notificatView

- (void)drawRect:(CGRect)rect {
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    self.mainLabel.minimumScaleFactor=0.5;
    
//    if (self.sentMode != YES) {
//        self.imageView.layer.cornerRadius = 4;
//        self.imageView.layer.masksToBounds = YES;
//    }

}
- (IBAction)buttonTapped:(id)sender {
    [self.delegate bumpTappedForListing:self.listingID];
}

@end
