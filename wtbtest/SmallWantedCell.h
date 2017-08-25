//
//  SmallWantedCell.h
//  wtbtest
//
//  Created by Jack Ryder on 11/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface SmallWantedCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet PFImageView *itemImageView;
@property (weak, nonatomic) IBOutlet UILabel *itemLowerLabel;

@end
