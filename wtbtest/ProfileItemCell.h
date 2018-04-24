//
//  ProfileItemCell.h
//  wtbtest
//
//  Created by Jack Ryder on 09/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface ProfileItemCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet PFImageView *itemImageView;
@property (weak, nonatomic) IBOutlet UIImageView *purchasedImageView;
@property (weak, nonatomic) IBOutlet UIImageView *boostImageView;
@property (weak, nonatomic) IBOutlet UIImageView *boost2ImageView;

@property (weak, nonatomic) IBOutlet UIImageView *topRightImageView;
@end
