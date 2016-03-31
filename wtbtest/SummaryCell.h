//
//  SummaryCell.h
//  wtbtest
//
//  Created by Jack Ryder on 29/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface SummaryCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet PFImageView *itemImage;
@property (weak, nonatomic) IBOutlet UILabel *itemTitle;
@property (weak, nonatomic) IBOutlet UILabel *itemPrice;
@property (weak, nonatomic) IBOutlet UIImageView *paidImageView;
@property (weak, nonatomic) IBOutlet UIImageView *shipImageView;
@property (weak, nonatomic) IBOutlet UIImageView *fbImageView;
@property (weak, nonatomic) IBOutlet UILabel *alertLabel;
@property (weak, nonatomic) IBOutlet UIImageView *alertImageView;

@end
