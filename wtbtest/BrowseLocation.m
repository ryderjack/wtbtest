//
//  BrowseLocation.m
//  wtbtest
//
//  Created by Jack Ryder on 19/09/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "BrowseLocation.h"

@implementation BrowseLocation

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (IBAction)aroundMePressed:(id)sender {
    [self.delegate locationPressed:@"Around"];
}
- (IBAction)AsiaPressed:(id)sender {
    [self.delegate locationPressed:@"Asia"];
}
- (IBAction)EuropePressed:(id)sender {
    [self.delegate locationPressed:@"Europe"];
}
- (IBAction)GlobalPressed:(id)sender {
    [self.delegate locationPressed:@"Global"];
}
- (IBAction)AmericaPressed:(id)sender {
    [self.delegate locationPressed:@"America"];
}

@end
