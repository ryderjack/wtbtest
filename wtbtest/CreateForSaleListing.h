//
//  CreateForSaleListing.h
//  wtbtest
//
//  Created by Jack Ryder on 01/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectViewController.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "CameraController.h"
#import <BASSquareCropperViewController.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>
#import "TOJRWebView.h"
#import <QBImagePickerController/QBImagePickerController.h>
#import "AddImageCell.h"
#import <LXReorderableCollectionViewFlowLayout.h>
#import "ConditionsOptionsTableView.h"
#import <SwipeView/SwipeView.h>

@class CreateForSaleListing;

@protocol CreateForSaleDelegate <NSObject>
- (void)showForSaleSuccessForListing:(PFObject *)listing;
@end

@interface CreateForSaleListing : UITableViewController<UIAlertViewDelegate, UITextFieldDelegate, UITextViewDelegate, SelectViewControllerDelegate, CameraControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIWebViewDelegate, BASSquareCropperDelegate,JRWebViewDelegate,QBImagePickerControllerDelegate,UICollectionViewDelegate, LXReorderableCollectionViewDataSource,LXReorderableCollectionViewDelegateFlowLayout,AddImageCellDelegate,ConditionsDelegate,SwipeViewDelegate, SwipeViewDataSource,UIGestureRecognizerDelegate>

//delegate
@property (nonatomic, weak) id <CreateForSaleDelegate> delegate;

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *conditionCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *categoryCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sizeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *locationCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *descriptionCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *payCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *spaceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *imagesCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *itemTitleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *colourCell;

//camera buttons
@property (nonatomic, strong) UIButton *firstCam;
@property (nonatomic, strong) UIButton *secondCam;
@property (nonatomic, strong) UIButton *thirdCam;
@property (nonatomic, strong) UIButton *fourthCam;
@property (nonatomic, strong) UIButton *fifthCam;
@property (nonatomic, strong) UIButton *sixthCam;

//add multiple images at once
@property (nonatomic) BOOL multipleMode;
@property (nonatomic, strong) NSMutableArray *imagesToProcess;

//text fields
@property (weak, nonatomic) IBOutlet UITextView *descriptionField;
@property (weak, nonatomic) IBOutlet UITextField *payField;

//choices
@property (weak, nonatomic) IBOutlet UILabel *chooseCondition;
@property (weak, nonatomic) IBOutlet UILabel *chooseCategroy;
@property (weak, nonatomic) IBOutlet UILabel *chooseSize;
@property (weak, nonatomic) IBOutlet UILabel *chooseLocation;

//other
@property (nonatomic) int camButtonTapped;
@property (nonatomic) int photostotal;

@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

@property (nonatomic, strong) NSArray *profanityList;
@property (nonatomic, strong) NSArray *flagWords;

//sizes
@property (nonatomic, strong) NSArray *multipleSizeArray;
@property (nonatomic, strong) NSArray *multipleSizeAcronymArray;
@property (nonatomic, strong) NSMutableArray *finalSizeArray;

@property (nonatomic, strong) NSString *selection;
@property (nonatomic, strong) NSString *genderSize;

//hud
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

//cam
@property (nonatomic, strong) UIImagePickerController *picker;

//edit
@property (nonatomic) BOOL editMode;
@property (nonatomic) BOOL fromSuccess;

@property (nonatomic, strong) PFObject *listing;

@property (nonatomic, strong) NSString *usernameToCheck;
@property (nonatomic, strong) PFUser *cabin;
@property (nonatomic) BOOL somethingChanged;

//big button
@property (nonatomic, strong) UIButton *longButton;
@property (nonatomic) BOOL buttonShowing;
@property (nonatomic) BOOL introMode;

//web
@property (nonatomic, strong) TOJRWebView *webViewController;

//images
@property (nonatomic, strong) NSMutableArray *placeholderAssetArray;

//new image cell w/ CV
@property (weak, nonatomic) IBOutlet UICollectionView *imgCollectionView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@property (nonatomic, strong) NSMutableArray *filesArray;

@property (nonatomic) int cellWidth;

//item title cell
@property (weak, nonatomic) IBOutlet UITextField *itemTitleTextField;

//colour
@property (weak, nonatomic) IBOutlet UILabel *colourLabel;
@property (weak, nonatomic) IBOutlet SwipeView *colourSwipeView;

@property (nonatomic, strong) NSArray *coloursArray;
@property (nonatomic, strong) NSArray *colourValuesArray;

@property (weak, nonatomic) IBOutlet UILabel *chooseColourLabel;

@property (nonatomic, strong) NSString *chosenColour;
@property (nonatomic, strong) NSMutableArray *chosenColourSArray;

@property (weak, nonatomic) IBOutlet UIImageView *chosenColourImageView;
@property (weak, nonatomic) IBOutlet UIImageView *secondChosenColourImageView;

@property (nonatomic, strong) UIButton *dismissColourButton;

//image saving
@property (nonatomic, strong) UIImage *itemImage;
@property (nonatomic, strong) UIImage *placeHolderImage;


//sam's mode
@property(nonatomic) BOOL listingAsMode;

//verified user check
@property (nonatomic) BOOL verified;

//banned user check
@property(nonatomic) BOOL banMode;

//ignore 2photos requirement for listings created before its introduction that are in edit mode
@property (nonatomic) BOOL ignore2Pics;

//location
@property (strong, nonatomic) PFGeoPoint *geopoint;
@property (strong, nonatomic) NSString *locationString;

@end
