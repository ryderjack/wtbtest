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
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor=0.5;
}

@end
