//
//  OfferCell.m
//  wtbtest
//
//  Created by Jack Ryder on 07/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "OfferCell.h"

@implementation OfferCell

- (void)awakeFromNib {
    self.itemTitle.adjustsFontSizeToFitWidth = YES;
    self.itemTitle.minimumScaleFactor=0.5;
    
    self.buyerName.adjustsFontSizeToFitWidth = YES;
    self.buyerName.minimumScaleFactor=0.5;
    
    self.priceLabel.adjustsFontSizeToFitWidth = YES;
    self.priceLabel.minimumScaleFactor=0.5;
}

@end
