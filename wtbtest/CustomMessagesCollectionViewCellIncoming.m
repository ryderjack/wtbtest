//
//  CustomMessagesCollectionViewCellIncoming.m
//  wtbtest
//
//  Created by Jack Ryder on 07/02/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "CustomMessagesCollectionViewCellIncoming.h"

@implementation CustomMessagesCollectionViewCellIncoming

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.messageBubbleTopLabel.textAlignment = NSTextAlignmentLeft;
    self.cellBottomLabel.textAlignment = NSTextAlignmentLeft;
}

+ (UINib *)nib
{
    return [UINib nibWithNibName:@"CustomMessagesCollectionViewCellIncoming" bundle:nil];
}

+ (NSString *)cellReuseIdentifier
{
    return @"CustomMessagesCollectionViewCellIncoming";
}

@end
