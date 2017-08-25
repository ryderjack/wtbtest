//
//  ListingBannerView.h
//  wtbtest
//
//  Created by Jack Ryder on 24/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@class ListingBannerView;

@protocol bannerDelegate <NSObject>
- (void)bannerTapped;
@end

@interface ListingBannerView : UIView
@property (weak, nonatomic) IBOutlet UILabel *itemTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet PFImageView *itemImageView;

//delegate
@property (nonatomic, weak) id <bannerDelegate> delegate;

@end
