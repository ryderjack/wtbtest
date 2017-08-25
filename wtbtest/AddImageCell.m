//
//  AddImageCell.m
//  wtbtest
//
//  Created by Jack Ryder on 02/05/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "AddImageCell.h"

@implementation AddImageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    [self.deleteButton setHidden:YES];
    
    self.itemImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.itemImageView.layer.cornerRadius = 4;
    self.itemImageView.layer.masksToBounds = YES;
}
- (IBAction)deleteCellButtonPressed:(id)sender {
    [self.delegate imageCellDeleteTapped:self];
}

@end
