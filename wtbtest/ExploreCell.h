//
//  ExploreCell.h
//  
//
//  Created by Jack Ryder on 29/02/2016.
//
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@class ExploreCell;

@protocol ExploreCellDelegate <NSObject>
- (void)cellTapped:(ExploreCell *)cell;
@end

@interface ExploreCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet PFImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UIButton *bumpButton;
@property (weak, nonatomic) IBOutlet UIView *transView;

@property (nonatomic, weak) id <ExploreCellDelegate> delegate;

@end
