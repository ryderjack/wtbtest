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
#import "customAlertViewClass.h"
#import "inviteViewClass.h"
#import "TOJRWebView.h"
#import "DetailImageController.h"
#import "BumpingIntroVC.h"

@class ForSaleListing;

@protocol ForSaleListingDelegate <NSObject>
- (void)dismissForSaleListing;
- (void)changedSoldStatus; //could mark as sold or unsold
- (void)deletedItem;
- (void)likedItem;

@end

@interface ForSaleListing : UITableViewController <iCarouselDataSource, iCarouselDelegate,FBSDKAppInviteDialogDelegate,UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate,customAlertDelegate,inviteDelegate,JRWebViewDelegate,DetailImageDelegate,BumpingIntroDelegate>

@property (nonatomic, strong) PFObject *listingObject;
@property (nonatomic, strong) PFObject *WTBObject;

//delegate
@property (nonatomic, weak) id <ForSaleListingDelegate> delegate;

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
@property (weak, nonatomic) IBOutlet UILabel *conditionLabel;
@property (weak, nonatomic) IBOutlet UIButton *usernameButton;
@property (weak, nonatomic) IBOutlet UILabel *itemTitle;
@property (weak, nonatomic) IBOutlet UILabel *sellerTextLabel;

//icons
@property (weak, nonatomic) IBOutlet UIImageView *sizeIcon;
@property (weak, nonatomic) IBOutlet UIImageView *timeIcon;
@property (weak, nonatomic) IBOutlet UIImageView *priceIcon;

//multiple sizes
@property (weak, nonatomic) IBOutlet UIButton *multipleButton;
@property (nonatomic) BOOL alertShowing;
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;

//@property (weak, nonatomic) IBOutlet PFImageView *imageViewTwo;
//seller info
@property (nonatomic, strong) PFUser *seller;
@property (weak, nonatomic) IBOutlet PFImageView *sellerImgView;
@property (nonatomic) BOOL fetchedListing;

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
@property (nonatomic, strong) PFFile *fifthImage;
@property (nonatomic, strong) PFFile *sixthImage;

@property (nonatomic) int numberOfPics;

@property (weak, nonatomic) IBOutlet UILabel *soldLabel;
@property (weak, nonatomic) IBOutlet UIImageView *soldCheckImageVoew;

@property (nonatomic, strong) UIBarButtonItem *infoButton;

//mode
@property (nonatomic) BOOL fromBuyNow;
@property (nonatomic, strong) NSString *source;
@property (nonatomic) BOOL pureWTS;
@property (nonatomic) BOOL relatedProduct;
@property (nonatomic) BOOL affiliateMode;
@property (nonatomic) BOOL fromCreate;
@property (nonatomic) BOOL markAsSoldMode;

//big button
@property (nonatomic, strong) UIButton *longButton;
@property (nonatomic) BOOL buttonShowing;
@property (nonatomic) BOOL barButtonPressed;

//carousel
@property (weak, nonatomic) IBOutlet iCarousel *carouselView;
@property (nonatomic, strong) NSMutableArray *imageArray;

//buttons cell
@property (strong, nonatomic) IBOutlet UITableViewCell *sendCell;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *sendLabel;
@property (weak, nonatomic) IBOutlet UIButton *upVoteButton;
@property (weak, nonatomic) IBOutlet UIButton *reportButton;
@property (weak, nonatomic) IBOutlet UIButton *upVoteLabel;
@property (weak, nonatomic) IBOutlet UIButton *reportLabel;



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

//invite pop up
@property (nonatomic, strong, nullable) inviteViewClass *inviteView;
@property (nonatomic) BOOL inviteAlertShowing;
@property (nonatomic, strong, nullable) UIView *inviteBgView;
@property (nonatomic, strong) UITapGestureRecognizer *inviteTap;
@property (nonatomic) int tabBarHeightInt;

//affiliate
@property (nonatomic, strong) PFObject *affiliateObject;

//web
@property (nonatomic, strong) TOJRWebView *web;

//screenshot & other drop down tracking
@property (nonatomic) BOOL dropShowing;

//blur view
@property (strong, nonatomic) FXBlurView *blurView;

//from push
@property (nonatomic) BOOL fromPush;

//user push preferences
@property (nonatomic) BOOL dontLikePush;


@end
