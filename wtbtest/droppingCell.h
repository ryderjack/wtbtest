//
//  droppingCell.h
//  wtbtest
//
//  Created by Jack Ryder on 22/02/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface droppingCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet PFImageView *dropImageView;
@property (weak, nonatomic) IBOutlet UILabel *dropLabel;
@property (weak, nonatomic) IBOutlet UIView *outerView;

@end
