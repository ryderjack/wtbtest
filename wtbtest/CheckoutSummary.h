//
//  CheckoutSummary.h
//  wtbtest
//
//  Created by Jack Ryder on 29/09/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "ShippingController.h"
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>
#import <SafariServices/SafariServices.h>

@class CheckoutSummary;

@protocol CheckoutDelegate <NSObject>
- (void)dismissedCheckout;
- (void)PurchasedItemCheckout;
@end

@interface CheckoutSummary : UITableViewController <ShippingControllerDelegate, UITextFieldDelegate, CheckoutDelegate>

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *addShippingAddressCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *addressCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *itemCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *itemPriceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *shippingPriceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *totalPriceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *spaceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *footerCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *congratsHeader;

//delegate
@property (nonatomic, weak) id <CheckoutDelegate> delegate;

@property (nonatomic) BOOL addAddress;

//address
@property (weak, nonatomic) IBOutlet UIButton *addAddressPressed;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UIButton *changeAddressPressed;

//item
@property (weak, nonatomic) IBOutlet UILabel *itemTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *conditionLabel;
@property (weak, nonatomic) IBOutlet PFImageView *itemImageView;
@property (weak, nonatomic) IBOutlet UILabel *itemPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstItemPriceLabel;

//prices
@property (weak, nonatomic) IBOutlet UILabel *shippingPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalPriceLabel;
@property (nonatomic) float salePrice;
@property (nonatomic) float totalPrice;
//@property (nonatomic) float shippingPrice;

@property (nonatomic) NSString *currencySymbol;
@property (nonatomic) NSString *currency;

@property (nonatomic) NSString *shippingText;
@property (nonatomic) NSString *itemPriceText;
@property (nonatomic) NSString *totalPriceText;

@property (nonatomic) BOOL showNationalShippingOnly;

//listing
@property (nonatomic, strong) PFObject *listingObject;
@property (nonatomic) NSString *listingCountryCode;

//pay button
@property (nonatomic, strong) UIButton *payButton;
@property (nonatomic) BOOL buttonShowing;
@property (nonatomic) BOOL isNational;
@property (nonatomic) BOOL gotoShipping;

@property (weak, nonatomic) IBOutlet UIButton *paypalLabel;

//spinner
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

//reviews
@property (weak, nonatomic) IBOutlet UIButton *reviewButton;
@property (nonatomic) BOOL leaveReviewON;
@property (nonatomic) BOOL gotReview;

//support tickets
@property (nonatomic) BOOL tappedSupport;

//checkout success mode
@property (nonatomic) BOOL successMode;
@property (nonatomic) BOOL isBuyer;
@property (nonatomic) BOOL hitPay;

@property (nonatomic, strong) PFObject *orderObject;

@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (nonatomic, strong) NSDateFormatter *dateFormat;

@property (nonatomic, strong) PFUser *otherUser;
@property (nonatomic) BOOL fetchedUser;
@property (nonatomic) BOOL settingUpMessages;
@property (weak, nonatomic) IBOutlet UILabel *congratsHeaderLabel;

//paypal integration stuff
@property (nonatomic) BOOL addedPayPalObservers;
@property (nonatomic, strong) SFSafariViewController *paypalSafariView;
@property (nonatomic, strong) NSString *paypalOrderId;
@property (nonatomic) BOOL sellerErrorShowing;

@property (nonatomic) BOOL checkedSellersPPInfo;
@property (nonatomic) NSString *pairingId;



@end
