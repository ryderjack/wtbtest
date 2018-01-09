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
#import <CoreLocation/CoreLocation.h>
#import "AddSizeController.h"
#import <MessageUI/MessageUI.h>
#import <SwipeView/SwipeView.h>

@class RegisterViewController;

@protocol RegVCDelegate <NSObject>
- (void)RegVCFacebookPressed;
- (void)RegVCLoginPressed;
@end

@interface RegisterViewController : UITableViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,CLLocationManagerDelegate,sizeDelegate,MFMailComposeViewControllerDelegate,SwipeViewDelegate,SwipeViewDataSource>
NS_ASSUME_NONNULL_BEGIN

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *emailCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *usernameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *pictureCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *regCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *currencyCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *friendsCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *secondNameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *passwordCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *spaceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *currencySwipeCell;

//textfields
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

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

//currency swipe view
@property (weak, nonatomic) IBOutlet SwipeView *currencySwipeView;
@property (nonatomic, strong) NSArray *currencyArray;

//profanity
@property (nonatomic, strong) NSArray *profanityList;

//depop
@property (weak, nonatomic) IBOutlet UITextField *depopField;

//image
@property (nonatomic) BOOL pressedCam;
@property (nonatomic, strong) UIImagePickerController *picker;
@property (nonatomic) BOOL imageSaved;

//reg button
@property (nonatomic, strong) UIButton *longRegButton;
@property (nonatomic) BOOL regShowing;
@property (nonatomic) BOOL regPressedWithoutSave;

//friends
@property (weak, nonatomic) IBOutlet UILabel *friendsLabel;
@property (weak, nonatomic) IBOutlet PFImageView *friendOneImageView;
@property (weak, nonatomic) IBOutlet PFImageView *friendTwoImageView;
@property (weak, nonatomic) IBOutlet PFImageView *friendThreeImageView;
@property (nonatomic) BOOL showFriendsCell;

//location
@property (nonatomic, strong) CLLocationManager *locationManager;

//reg mode (email vs facebook)
@property (nonatomic) BOOL emailMode;
@property (nonatomic) BOOL checkedEmail;
@property (nonatomic) BOOL somethingChanged;

//title buttons
@property (weak, nonatomic) IBOutlet UIButton *helpButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelCrossButton;

//delegate
@property (nonatomic, weak) id <RegVCDelegate> delegate;

//ban mode
@property (nonatomic) BOOL banMode;


NS_ASSUME_NONNULL_END

@property (nonatomic, strong) PFFile * _Nullable imageFile;

@end
