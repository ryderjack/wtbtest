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
#import "customAlertViewClass.h"
#import "LocationView.h"
#import <SwipeView/SwipeView.h>
#import <SafariServices/SafariServices.h>

@class SettingsController;

@protocol SettingsDelegate <NSObject>
- (void)dismissedSettings;
@end

@interface SettingsController : UITableViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,customAlertDelegate,LocationViewControllerDelegate,SwipeViewDataSource,SwipeViewDelegate,SFSafariViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UITableViewCell *addressCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *emailCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *currencyCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *pictureCelll;
@property (strong, nonatomic) IBOutlet UITableViewCell *contactEmailCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *lastNameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *usernameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *cmoCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *listAsCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sellerModeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *locationLabelCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *bioCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *currencySwipeCell;

//textfields
@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UILabel *addLabel;
@property (weak, nonatomic) IBOutlet UITextField *contactEmailField;

@property (nonatomic, strong) PFUser *currentUser;

@property (nonnull, strong) NSString *currentPaypal;
@property (nonnull, strong) NSString *currentContact;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;

@property (nonatomic) BOOL changePayPal;
@property (nonatomic) BOOL locationAddMode;
@property (nonatomic) BOOL autoPopMode;

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
@property (nonatomic) BOOL changedName;

//picture cell
@property (weak, nonatomic) IBOutlet UILabel *changePictureLabel;

//Sam's CMO mode
@property (weak, nonatomic) IBOutlet UISwitch *cmoSwitch;

//Sam's List as mode
@property (weak, nonatomic) IBOutlet UISwitch *listAsSwitch;

//seller mode
@property (weak, nonatomic) IBOutlet UISwitch *sellerModeSwitch;

//notifications
@property (nonatomic) BOOL changedPush;
@property (nonatomic) BOOL changedFbPush;

@property (weak, nonatomic) IBOutlet UIButton *pushStatusButton;

@property (weak, nonatomic) IBOutlet UISwitch *likeSwitch;
@property (strong, nonatomic) IBOutlet UITableViewCell *notificationsCell;
@property (weak, nonatomic) IBOutlet UISwitch *fbFriendSwitch;

//push prompt
@property (nonatomic, strong, nullable) customAlertViewClass *pushAlert;
@property (nonatomic) BOOL shownPushAlert;
@property (nonatomic, strong, nullable) UIView *searchBgView;
@property (nonatomic) BOOL settingsMode;

//location cell
@property (weak, nonatomic) IBOutlet UILabel *locLabel;

//bio cell
@property (weak, nonatomic) IBOutlet UITextField *bioField;
@property (nonatomic) BOOL bioMode;

//currency cell
@property (weak, nonatomic) IBOutlet SwipeView *currencySwipeView;
@property (nonatomic, strong) NSArray *currencyArray;
@property (nonatomic) BOOL currencyChanged;

//paypal
@property (weak, nonatomic) IBOutlet UILabel *paypalAccountLabel;
@property (nonatomic) BOOL paypalConnected;

//paypal onboarding
@property (nonatomic, strong) SFSafariViewController *paypalSafariView;
@property (nonatomic) BOOL addedPayPalObservers;
@property (nonatomic, strong) NSString *merchantId;

//temp
@property (strong, nonatomic) IBOutlet UITableViewCell *paypalEmailCell;
@property (weak, nonatomic) IBOutlet UITextField *paypalTextField;

//delegate
@property (nonatomic, weak) id <SettingsDelegate> delegate;

@end
