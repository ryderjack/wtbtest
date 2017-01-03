//
//  ExploreCell.m
//  
//
//  Created by Jack Ryder on 29/02/2016.
//
//

#import "ExploreCell.h"

@implementation ExploreCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor=0.5;
    
    self.titleLabel.numberOfLines = 2;
    
    self.priceLabel.adjustsFontSizeToFitWidth = YES;
    self.priceLabel.minimumScaleFactor=0.5;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(bumpButtonPressed:)];
    tap.numberOfTapsRequired = 1;
    [self.transView addGestureRecognizer:tap];
}
- (IBAction)bumpButtonPressed:(id)sender {
    [self.delegate cellTapped:self];
}

@end
