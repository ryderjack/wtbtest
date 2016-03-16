//
//  CheckoutController.h
//  wtbtest
//
//  Created by Jack Ryder on 08/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "ShippingController.h"

@interface CheckoutController : UITableViewController <UITextFieldDelegate, ShippingControllerDelegate>

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *shippingAddressCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *itemPriceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *deliveryCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *feeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *authenticityCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *totalCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *voucherCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *payCell;

//shipping cell
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;

@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *deliverypriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *transactionfeeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *authenticitySwitch;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UITextField *voucherField;

//costs
@property (nonatomic) float price;
@property (nonatomic) float delivery;
@property (nonatomic) float fee;

@property (nonatomic, strong) PFObject *confirmedOfferObject;


@end
