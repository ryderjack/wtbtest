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
}

@end
