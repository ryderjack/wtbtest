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

@interface ForSaleListing : UITableViewController

@property (nonatomic, strong) PFObject *listingObject;
@property (nonatomic, strong) PFObject *WTBObject;

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *mainCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sellerCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *infoCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *descriptionCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *buttonCell;
@property (weak, nonatomic) IBOutlet PFImageView *itemImageView;

@property (weak, nonatomic) IBOutlet UIPageControl *pageIndicator;
@property (strong, nonatomic) IBOutlet UITableViewCell *image2Cell;

//labels
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *IDLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UIButton *messageSellerButton;

@property (weak, nonatomic) IBOutlet PFImageView *imageViewTwo;
//seller info
@property (weak, nonatomic) IBOutlet UIImageView *starImageView;
@property (weak, nonatomic) IBOutlet UILabel *sellerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *pastDealsLabel;
@property (weak, nonatomic) IBOutlet PFImageView *sellerImgView;
@property (weak, nonatomic) IBOutlet UIButton *sellerButton;

//spinner
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

@property (nonatomic, strong) PFUser *seller;

@property (nonatomic, strong) PFFile *firstImage;
@property (nonatomic, strong) PFFile *secondImage;
@property (nonatomic, strong) PFFile *thirdImage;
@property (nonatomic, strong) PFFile *fourthImage;
@property (nonatomic) int numberOfPics;

@end
