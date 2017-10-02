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

@class CheckoutSummary;

@protocol CheckoutDelegate <NSObject>
- (void)dismissedCheckout;
@end

@interface CheckoutSummary : UITableViewController <ShippingControllerDelegate>

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

@property (nonatomic) NSString *currencySymbol;

@property (nonatomic) NSString *shippingText;
@property (nonatomic) NSString *itemPriceText;
@property (nonatomic) NSString *totalPriceText;

//listing
@property (nonatomic, strong) PFObject *listingObject;
@property (nonatomic) NSString *listingCountryCode;

//pay button
@property (nonatomic, strong) UIButton *payButton;
@property (nonatomic) BOOL buttonShowing;
@property (nonatomic) BOOL isNational;

@property (weak, nonatomic) IBOutlet UIButton *paypalLabel;

//spinner
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

//checkout success mode
@property (nonatomic) BOOL successMode;
@end
