//
//  SendToUserCell.m
//  wtbtest
//
//  Created by Jack Ryder on 07/02/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "SendToUserCell.h"

@implementation SendToUserCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.usernameLabel.adjustsFontSizeToFitWidth = YES;
    self.usernameLabel.minimumScaleFactor=0.5;
    
    self.fullnameLabel.adjustsFontSizeToFitWidth = YES;
    self.fullnameLabel.minimumScaleFactor=0.5;
}

@end
