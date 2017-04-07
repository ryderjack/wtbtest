//
//  simpleCreateVC.h
//  wtbtest
//
//  Created by Jack Ryder on 25/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NavigationController.h"
#import <BASSquareCropperViewController.h>
#import "customAlertViewClass.h"
#import "CreateSuccessView.h"
#import <Parse/Parse.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>
#import "TOJRWebView.h"
#import "CameraController.h"
#import "CategoryDropDown.h"

@class simpleCreateVC;

@protocol simpleCreateVCDelegate <NSObject>
- (void)dismissSimpleCreateVC:(simpleCreateVC *)controller;
@end

@interface simpleCreateVC : UIViewController <UITextFieldDelegate,BASSquareCropperDelegate,successDelegate,UICollectionViewDelegate, UICollectionViewDataSource,customAlertDelegate,JRWebViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,CameraControllerDelegate,categoryDelegate>

//UI
@property (weak, nonatomic) IBOutlet UITextField *titleTextLabel;

//Web
@property (nonatomic, strong) TOJRWebView *JRWebView;

//delegate
@property (nonatomic, weak) id <simpleCreateVCDelegate> delegate;

//images
@property (nonatomic) BOOL shouldSave;
@property (nonatomic) int photostotal;
@property (nonatomic, strong) NSString *imageSource;

//success view
@property (nonatomic, strong) CreateSuccessView *successView;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) NSMutableArray *buyNowArray;
@property (nonatomic, strong) NSMutableArray *buyNowIDs;
@property (nonatomic) BOOL setupYes;
@property (nonatomic) BOOL completionShowing;

//category drop down
@property (nonatomic) BOOL setupCategories;
@property (nonatomic, strong) CategoryDropDown *catView;
@property (nonatomic) BOOL catShowing;
@property (nonatomic, strong) UITapGestureRecognizer *catTap;

//modes
@property (nonatomic) BOOL introMode;
@property (nonatomic) BOOL somethingChanged;
@property (nonatomic) BOOL finishedListing;
@property (nonatomic) BOOL createdListing;

//custom alert view
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;
@property (nonatomic) BOOL shownPushAlert;

//listing
@property (nonatomic, strong) PFObject *listing;
@property (strong, nonatomic) PFGeoPoint *geopoint;
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;
@property (nonatomic, strong) NSString *locationString;
@property (nonatomic, strong) NSString *categorySelected;
@property (nonatomic, strong) UIImage *firstImage;
@property (nonatomic, strong) NSArray *profanityList;
@property (nonatomic) int tapNumber;


//HUD
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic) BOOL hudShowing;
@property (nonatomic) BOOL shouldShowHUD;

//image picker
@property (nonatomic, strong) UIImagePickerController *picker;

//intro stuff
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

//bouncing dismiss button
@property (nonatomic, strong) UIButton *bouncingButton;
@property (nonatomic) BOOL settingUp;

//sell stuff
@property (weak, nonatomic) IBOutlet UIImageView *orImageView;
@property (weak, nonatomic) IBOutlet UIButton *sellButton;
@property (nonatomic) BOOL isSeller;

@end
