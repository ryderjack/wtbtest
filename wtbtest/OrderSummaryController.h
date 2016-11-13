//
//  OrderSummaryController.h
//  wtbtest
//
//  Created by Jack Ryder on 18/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "DetailImageController.h"


@interface OrderSummaryController : UITableViewController

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *userCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *shippingCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *itempriceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *deliveryCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *feeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *checkCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *totalCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *buttonCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sellerButtons;
@property (strong, nonatomic) IBOutlet UITableViewCell *simpleImagesCell;

//title cell
@property (weak, nonatomic) IBOutlet UILabel *itemTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *conditionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *titleImageView;
@property (weak, nonatomic) IBOutlet UILabel *actionLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) NSDate *orderDate;

//user cell
@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *dealsLabel;
@property (weak, nonatomic) IBOutlet UIImageView *starsImgView;
@property (weak, nonatomic) IBOutlet PFImageView *userImageView;
@property (weak, nonatomic) IBOutlet PFImageView *checkImageView;

//image cell
@property (weak, nonatomic) IBOutlet PFImageView *firstImageView;
@property (weak, nonatomic) IBOutlet PFImageView *secondImageView;
@property (weak, nonatomic) IBOutlet PFImageView *thirdImageView;
@property (weak, nonatomic) IBOutlet PFImageView *fourthImageView;

//image buttons
@property (weak, nonatomic) IBOutlet UIButton *firstCam;
@property (weak, nonatomic) IBOutlet UIButton *secondCam;
@property (weak, nonatomic) IBOutlet UIButton *thirdCam;
@property (weak, nonatomic) IBOutlet UIButton *fourthCam;

//shipping cell
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;

//main cells
@property (weak, nonatomic) IBOutlet UILabel *itemPrice;
@property (weak, nonatomic) IBOutlet UILabel *deliveryLabel;
@property (weak, nonatomic) IBOutlet UILabel *feeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UILabel *checkLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalCostLabel;

//button cell
@property (nonatomic, strong) PFObject *orderObject;
@property (nonatomic, strong) PFObject *confirmedOffer;
@property (nonatomic, strong) PFUser *otherUser;
@property (weak, nonatomic) IBOutlet UIButton *shippedButton;
@property (nonatomic) BOOL purchased;
@property (nonatomic, strong) NSString *statusString;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;

//in seller buttons
@property (weak, nonatomic) IBOutlet UIButton *feedbackButton;
@property (weak, nonatomic) IBOutlet UIButton *sellerChatButton;
@property (weak, nonatomic) IBOutlet UIButton *otherFeedbackButton;

//detail image vc
@property (nonatomic, strong) DetailImageController *detailController;
@property (nonatomic) int numberOfPics;

//currency
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

//messageMode
@property (nonatomic) BOOL fromMessage;
@end
