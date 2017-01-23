//
//  viewItemClass.h
//  wtbtest
//
//  Created by Jack Ryder on 17/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@class viewItemClass;
@protocol viewItemDelegate <NSObject>
- (void)visitPressed;
- (void)imagePressed;
@end

@interface viewItemClass : UIView
@property (weak, nonatomic) IBOutlet UIView *insideView;
@property (weak, nonatomic) IBOutlet PFImageView *itemImageView;
@property (weak, nonatomic) IBOutlet UIButton *visitButton;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;

@property (nonatomic, weak) id <viewItemDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *imageButton;

@end
