//
//  DetailImageController.h
//  wtbtest
//
//  Created by Jack Ryder on 04/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <MBProgressHUD.h>
#import <DGActivityIndicatorView.h>
#import <iCarousel.h>

@class DetailImageController;

@protocol DetailImageDelegate <NSObject>
- (void)dismissedDetailImageView;
@end

@interface DetailImageController : UIViewController <UIScrollViewDelegate, iCarouselDelegate, iCarouselDataSource>

@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (assign, nonatomic) NSInteger index;

@property (nonatomic, strong) PFObject *listing;
@property (nonatomic) int numberOfPics;
@property (weak, nonatomic) IBOutlet UILabel *tagLabel;
// if its a listing pic then we dont show the tag label

@property (nonatomic) BOOL listingPic;
@property (nonatomic) BOOL messagesPicMode;
@property (nonatomic, strong) UIImage *messagePicture;

@property (nonatomic, strong) NSString *tagText;

@property (nonatomic) BOOL offerMode;

//spinner
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) DGActivityIndicatorView *spinner;

//scroll view
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

//carousel
@property (weak, nonatomic) IBOutlet iCarousel *carousel;
@property (nonatomic) int chosenIndex;

@property (nonatomic, weak) id <DetailImageDelegate> delegate;


@end
