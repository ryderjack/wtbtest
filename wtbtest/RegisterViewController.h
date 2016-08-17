//
//  RegisterViewController.h
//  wtbtest
//
//  Created by Jack Ryder on 23/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <Parse.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>

@interface RegisterViewController : UITableViewController <UITextFieldDelegate>
NS_ASSUME_NONNULL_BEGIN

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *emailCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *usernameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *pictureCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *regCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *currencyCell;

//textfields
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;

@property (weak, nonatomic) IBOutlet UIButton *chooseFromLib;

//picture cell
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIButton *takePic;

//user
@property (strong, nonatomic) PFUser *user;

@property (weak, nonatomic) IBOutlet UIButton *regButton;
//warning
@property (weak, nonatomic) IBOutlet UILabel *warningLabel;

@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

//currency buttons
@property (weak, nonatomic) IBOutlet UIButton *GBPButton;
@property (weak, nonatomic) IBOutlet UIButton *USDButton;
@property (weak, nonatomic) IBOutlet UIButton *AUDButton;
@property (nonnull, strong) NSString *selectedCurrency;

//profanity
@property (nonatomic, strong) NSArray *profanityList;
NS_ASSUME_NONNULL_END

@end
