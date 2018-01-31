//
//  OrderSummaryView.h
//  wtbtest
//
//  Created by Jack Ryder on 17/10/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>
#import "FeedbackController.h"

@interface OrderSummaryView : UITableViewController <feedbackDelegate>

//basics
@property (nonatomic, strong) PFObject *orderObject;
@property (nonatomic, strong) PFObject *listingObject;
@property (nonatomic, strong) PFUser *otherUser;

@property (nonatomic) BOOL isBuyer;
@property (nonatomic) BOOL fetchedUser;
@property (nonatomic) BOOL tappedSupport;
@property (nonatomic) BOOL settingUpMessages;

@property (nonatomic, strong) NSDateFormatter *dateFormat;
@property (nonatomic) int rowNumber;

//spinner
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

//progress
@property (nonatomic) BOOL gotFeedback;
@property (nonatomic) BOOL shipped;
@property (nonatomic) BOOL leftFeedback;
@property (nonatomic) BOOL addedTracking;
@property (nonatomic) BOOL refundRequested;
@property (nonatomic) BOOL refundSent;
@property (nonatomic) BOOL paymentPending;
@property (nonatomic) BOOL paymentFailed;
@property (nonatomic) BOOL refundCancelled;

//cell heights
@property (nonatomic) int transCellHeight;
@property (nonatomic) int titleCellHeight;
@property (nonatomic) int gotFBCellHeight;
@property (nonatomic) int leftFBCellHeight;
@property (nonatomic) int leaveFBCellHeight;
@property (nonatomic) int paymentCellHeight;
@property (nonatomic) int shippingCellHeight;

//title cell
@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *nextStepLabel;
@property (weak, nonatomic) IBOutlet UIButton *viewListingButton;
@property (weak, nonatomic) IBOutlet PFImageView *itemImageView;
@property (weak, nonatomic) IBOutlet UIButton *nextStepButton;

//transaction cell
@property (strong, nonatomic) IBOutlet UITableViewCell *transactionCell;
@property (weak, nonatomic) IBOutlet PFImageView *otherUserImageView;
@property (weak, nonatomic) IBOutlet UILabel *dealLabel;
@property (weak, nonatomic) IBOutlet UIButton *messageButton;
@property (weak, nonatomic) IBOutlet UIButton *viewUserButton;

//payment cell
@property (weak, nonatomic) IBOutlet UILabel *paymentLabel;
@property (weak, nonatomic) IBOutlet UILabel *shippingPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalPriceLabel;
@property (weak, nonatomic) IBOutlet UIButton *refundButton;
@property (weak, nonatomic) IBOutlet UILabel *itemPriceLabel;
@property (strong, nonatomic) IBOutlet UITableViewCell *paymentCell;
@property (weak, nonatomic) IBOutlet PFImageView *paymentImageView;
@property (weak, nonatomic) IBOutlet UILabel *feePriceLabel;

//buyer's payment cell
@property (strong, nonatomic) IBOutlet UITableViewCell *buyerPaymentCell;
@property (weak, nonatomic) IBOutlet UILabel *buyerPaymentLabel;
@property (weak, nonatomic) IBOutlet UILabel *buyerItemPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *buyerShippingPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *buyerTotalPriceLabel;
@property (weak, nonatomic) IBOutlet UIButton *buyerRefundButton;
@property (weak, nonatomic) IBOutlet PFImageView *buyerPaymentImageView;

//shipping cell
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet PFImageView *shippingImageView;
@property (weak, nonatomic) IBOutlet UILabel *shippingMainLabel;
@property (weak, nonatomic) IBOutlet UIButton *shippingButton;
@property (strong, nonatomic) IBOutlet UITableViewCell *shippingCell;

//leave feedback cell
@property (weak, nonatomic) IBOutlet UIButton *leaveFeedbackButton;
@property (strong, nonatomic) IBOutlet UITableViewCell *leaveFeedbackCell;

//left feedback cell
@property (weak, nonatomic) IBOutlet UILabel *leftFeedbackLabel;
@property (weak, nonatomic) IBOutlet PFImageView *leftStarImageView;
@property (strong, nonatomic) IBOutlet UITableViewCell *leftFeedbackCell;

//got feedback cell
@property (weak, nonatomic) IBOutlet UILabel *gotFeedbackLabel;
@property (weak, nonatomic) IBOutlet PFImageView *gotStarImageView;
@property (weak, nonatomic) IBOutlet UIButton *viewFeedbackButton;
@property (strong, nonatomic) IBOutlet UITableViewCell *gotFeedbackCell;


@end
