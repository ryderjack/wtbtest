//
//  simpleBannerHeader.h
//  wtbtest
//
//  Created by Jack Ryder on 07/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface simpleBannerHeader : UICollectionReusableView
@property (weak, nonatomic) IBOutlet UILabel *simpleHeaderLabel;
@property (weak, nonatomic) IBOutlet PFImageView *headerImageView;
@property (weak, nonatomic) IBOutlet UIButton *headerRetryButton;
@property (weak, nonatomic) IBOutlet UIButton *headerCancelButton;
@property (weak, nonatomic) IBOutlet UIView *progressView;

@end
