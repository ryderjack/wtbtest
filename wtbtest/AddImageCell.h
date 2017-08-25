//
//  AddImageCell.h
//  wtbtest
//
//  Created by Jack Ryder on 02/05/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@class AddImageCell;

@protocol AddImageCellDelegate <NSObject>
- (void)imageCellDeleteTapped:(AddImageCell *)cell;
@end

@interface AddImageCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet PFImageView *itemImageView;

//delegate
@property (nonatomic, weak) id <AddImageCellDelegate> delegate;

@end
