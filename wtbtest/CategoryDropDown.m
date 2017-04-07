//
//  CategoryDropDown.m
//  wtbtest
//
//  Created by Jack Ryder on 03/04/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "CategoryDropDown.h"

@implementation CategoryDropDown


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//    
//
//}

- (IBAction)otherPressed:(id)sender {
    [self.delegate otherPressed];
}

- (IBAction)footwearPressed:(id)sender {
    [self.delegate footPressed];
}
- (IBAction)clothingPressed:(id)sender {
    [self.delegate clothingPressed];
}


@end
