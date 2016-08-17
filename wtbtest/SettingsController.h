//
//  SettingsController.h
//  wtbtest
//
//  Created by Jack Ryder on 27/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "ShippingController.h"

@interface SettingsController : UITableViewController <ShippingControllerDelegate, UITextFieldDelegate>
NS_ASSUME_NONNULL_BEGIN
@property (strong, nonatomic) IBOutlet UITableViewCell *addressCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *emailCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *currencyCell;

//textfields
@property (weak, nonatomic) IBOutlet UITextField *emailFields;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addLabel;

@property (nonatomic, strong) PFUser *currentUser;

@property (nonnull, strong) NSString *currentEmail;

//buttons
@property (weak, nonatomic) IBOutlet UIButton *GBPButton;
@property (weak, nonatomic) IBOutlet UIButton *USDButton;
@property (weak, nonatomic) IBOutlet UIButton *AUDButton;
@property (nonnull, strong) NSString *selectedCurrency;
NS_ASSUME_NONNULL_END
@end
