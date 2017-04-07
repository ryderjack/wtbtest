//
//  UserProfileController.h
//  wtbtest
//
//  Created by Jack Ryder on 26/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <MBProgressHUD.h>
#import <DGActivityIndicatorView.h>
#import <SpinKit/RTSpinKitView.h>
#import "BLKDelegateSplitter.h"
#import "TOJRWebView.h"
#import "BLKFlexibleHeightBar.h"
#import "HMSegmentedControl.h"
#import "ProfileController.h"
@interface UserProfileController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, JRWebViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ProfileSettingsDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *WTBArray;
@property (nonatomic, strong) NSArray *forSaleArray;
@property (nonatomic, strong) NSMutableArray *bumpedArray;
@property (nonatomic, strong) NSMutableArray *bumpedIds;


@property (nonatomic, strong) NSMutableArray *feedbackArray;
@property (nonatomic, strong) PFUser *user;

//currency
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

//user
@property (nonatomic, strong) NSString *usernameToList;
@property (nonatomic) BOOL isSeller;
@property (nonatomic) BOOL forSalePressed;
@property (nonatomic) BOOL WTBPressed;
@property (nonatomic) BOOL bumpedPressed;
@property (nonatomic) BOOL saleMode; //from buy now tab
@property (nonatomic) BOOL wantedMode; //user is not a seller so just display wanted & bumped
@property (nonatomic) BOOL noDeals;

//modes
@property (nonatomic) BOOL fromSearch;
@property (nonatomic) BOOL tabMode;

//which segment is showing
@property (nonatomic) BOOL WTBSelected;
@property (nonatomic) BOOL WTSSelected;
@property (nonatomic) BOOL bumpsSelected;

//spinner
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) DGActivityIndicatorView *imageSpinner;
@property (nonatomic, strong) MBProgressHUD *imageHud;

//multi delegates
@property (nonatomic, strong) BLKDelegateSplitter *splitter;

//headerview setup
@property (nonatomic, strong) PFImageView *smallImageView;
@property (nonatomic, strong) PFImageView *userImageView;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *middleUsernameLabel;
@property (nonatomic, strong) UILabel *nameAndLoc;
@property (nonatomic, strong) UILabel *smallNameAndLoc;
@property (nonatomic, strong) PFImageView *starImageView;
@property (nonatomic, strong) NSString *reviewsString;
@property (nonatomic, strong) UIButton *dotsButton;
@property (nonatomic, strong) UIButton *FBButton;
@property (nonatomic, strong) BLKFlexibleHeightBar *myBar;
@property (nonatomic, strong) UIButton *reviewsButton;
@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) PFImageView *editImageView;
@property (nonatomic, strong) UIButton *backButton;

//web view
@property (nonatomic, strong) TOJRWebView *webView;

//custom segment control
@property (nonatomic, strong) HMSegmentedControl *segmentedControl;
@property (nonatomic) int numberOfSegments;

//image picker
@property (nonatomic, strong) UIImage *profileImage;
@property (nonatomic, strong) UIImagePickerController *picker;

//prompts for new user w/ empty profile
//WTBs
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UILabel *actionLabel;

//Bumps
@property (weak, nonatomic) IBOutlet UIImageView *bumpImageView;
@property (weak, nonatomic) IBOutlet UILabel *bumpLabel;

@property (nonatomic, strong) NSDateFormatter *inputDateFormatter;

//team bump messages
@property (nonatomic) int messagesUnseen;
@property (nonatomic) BOOL showSnap;

@end
