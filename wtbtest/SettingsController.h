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
#import <ParseUI/ParseUI.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>

@interface SettingsController : UITableViewController <ShippingControllerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
NS_ASSUME_NONNULL_BEGIN
@property (strong, nonatomic) IBOutlet UITableViewCell *addressCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *emailCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *currencyCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *depopCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *pictureCelll;
@property (strong, nonatomic) IBOutlet UITableViewCell *contactEmailCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *lastNameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *usernameCell;

//textfields
@property (weak, nonatomic) IBOutlet UITextField *emailFields;
@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UILabel *addLabel;
@property (weak, nonatomic) IBOutlet UITextField *contactEmailField;

@property (nonatomic, strong) PFUser *currentUser;

@property (nonnull, strong) NSString *currentPaypal;
@property (nonnull, strong) NSString *currentContact;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;


//buttons
@property (weak, nonatomic) IBOutlet UIButton *GBPButton;
@property (weak, nonatomic) IBOutlet UIButton *USDButton;
@property (weak, nonatomic) IBOutlet UIButton *EURButton;
@property (nonnull, strong) NSString *selectedCurrency;
@property (weak, nonatomic) IBOutlet UITextField *depopField;
@property (weak, nonatomic) IBOutlet PFImageView *testingView;

@property (nonatomic, strong) UIImage *profileImage;
@property (nonatomic, strong) UIImagePickerController *picker;

//spinner
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

//other
@property (nonatomic, strong) NSArray *profanityList;

NS_ASSUME_NONNULL_END
@end
