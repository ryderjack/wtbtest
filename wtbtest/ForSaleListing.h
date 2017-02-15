//
//  ForSaleListing.h
//  wtbtest
//
//  Created by Jack Ryder on 04/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>
#import <iCarousel.h>
#import "SendDialogBox.h"
#import <FBSDKShareKit/FBSDKShareKit.h>

@interface ForSaleListing : UITableViewController <iCarouselDataSource, iCarouselDelegate,FBSDKAppInviteDialogDelegate,UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) PFObject *listingObject;
@property (nonatomic, strong) PFObject *WTBObject;

//cells

@property (strong, nonatomic) IBOutlet UITableViewCell *infoCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *descriptionCell;
@property (weak, nonatomic) IBOutlet UIPageControl *pageIndicator;
@property (strong, nonatomic) IBOutlet UITableViewCell *image2Cell;
@property (strong, nonatomic) IBOutlet UITableViewCell *spaceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *carouselCell;

//labels
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *IDLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet PFImageView *imageViewTwo;
//seller info
@property (nonatomic, strong) PFUser *seller;
@property (weak, nonatomic) IBOutlet PFImageView *sellerImgView;

//spinner
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

//image
@property (nonatomic, strong) PFFile *firstImage;
@property (nonatomic, strong) PFFile *secondImage;
@property (nonatomic, strong) PFFile *thirdImage;
@property (nonatomic, strong) PFFile *fourthImage;
@property (nonatomic) int numberOfPics;

@property (weak, nonatomic) IBOutlet UILabel *soldLabel;
@property (weak, nonatomic) IBOutlet UIImageView *soldCheckImageVoew;

@property (nonatomic, strong) UIBarButtonItem *infoButton;

@property (nonatomic, strong) NSString *source;
@property (nonatomic) BOOL pureWTS;
@property (nonatomic) BOOL relatedProduct;
@property (weak, nonatomic) IBOutlet PFImageView *trustedCheck;

//big button
@property (nonatomic, strong) UIButton *longButton;
@property (nonatomic) BOOL buttonShowing;

//carousel
@property (weak, nonatomic) IBOutlet iCarousel *carouselView;
@property (nonatomic, strong) NSMutableArray *imageArray;

//send cell
@property (strong, nonatomic) IBOutlet UITableViewCell *sendCell;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

//send dialog box
@property (nonatomic, strong) SendDialogBox *sendBox;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic) BOOL setupBox;
@property (nonatomic, strong) NSMutableArray *facebookUsers;
@property (nonatomic) BOOL sendMode;
@property (nonatomic) int friendIndexSelected;
@property (nonatomic) BOOL selectedFriend;
@property (nonatomic) BOOL hidingSendBox;
@property (nonatomic) BOOL changeKeyboard;
@property (nonatomic) BOOL wasShowing;

@end
