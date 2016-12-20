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
}
- (IBAction)buttonTapped:(id)sender {
    [self.delegate bumpTappedForListing:self.listingID];
}

@end
