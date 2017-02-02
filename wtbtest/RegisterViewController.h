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
#import <ParseUI/ParseUI.h>
#import <ChimpKit.h>
#import <CoreLocation/CoreLocation.h>
#import "TOJRWebView.h"

@interface RegisterViewController : UITableViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ChimpKitRequestDelegate,CLLocationManagerDelegate, JRWebViewDelegate>
NS_ASSUME_NONNULL_BEGIN

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *emailCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *usernameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *pictureCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *regCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *currencyCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *depopCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *friendsCell;

//textfields
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;

//picture cell
@property (weak, nonatomic) IBOutlet PFImageView *profilePicture;

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
@property (weak, nonatomic) IBOutlet UIButton *EURButton;
@property (nonnull, strong) NSString *selectedCurrency;

//profanity
@property (nonatomic, strong) NSArray *profanityList;

//depop
@property (weak, nonatomic) IBOutlet UITextField *depopField;

@property (nonatomic) BOOL pressedCam;

@property (nonatomic, strong) UIImagePickerController *picker;

@property (nonatomic, strong) UIButton *longRegButton;
@property (nonatomic) BOOL regShowing;

//friends
@property (weak, nonatomic) IBOutlet UILabel *friendsLabel;
@property (weak, nonatomic) IBOutlet PFImageView *friendOneImageView;
@property (weak, nonatomic) IBOutlet PFImageView *friendTwoImageView;
@property (weak, nonatomic) IBOutlet PFImageView *friendThreeImageView;
@property (nonatomic) BOOL showFriendsCell;

//location
@property (nonatomic, strong) CLLocationManager *locationManager;

//web
@property (nonatomic, strong) TOJRWebView *webViewController;
NS_ASSUME_NONNULL_END

@end
