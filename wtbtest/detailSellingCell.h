//
//  detailSellingCell.h
//  wtbtest
//
//  Created by Jack Ryder on 07/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface detailSellingCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet PFImageView *itemImageView;
@property (weak, nonatomic) IBOutlet UILabel *itemTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemPriceLabel;

@end
