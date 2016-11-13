//
//  CreateViewController.h
//  wtbtest
//
//  Created by Jack Ryder on 25/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectViewController.h"
#import "LocationView.h"
#import "ListingCompleteView.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "CameraController.h"
#import <BASSquareCropperViewController.h>
#import <TOWebViewController.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>

@class CreateViewController;

@protocol CreateViewControllerDelegate <NSObject>
- (void)dismissCreateController:(CreateViewController *)controller;
@end


@interface CreateViewController : UITableViewController <UIAlertViewDelegate, UITextFieldDelegate, UITextViewDelegate, SelectViewControllerDelegate, LocationViewControllerDelegate, ListingCompleteDelegate, CameraControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIWebViewDelegate, BASSquareCropperDelegate, TOWebDelegate>

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *picCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *condCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *catCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sizeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *locCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *deliveryCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *payCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *infoCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *buttonCell;

//delegate
@property (nonatomic, weak) id <CreateViewControllerDelegate> delegate;

//choose buttons
@property (weak, nonatomic) IBOutlet UILabel *chooseCondition;
@property (weak, nonatomic) IBOutlet UILabel *chooseCategroy;
@property (weak, nonatomic) IBOutlet UILabel *chooseSize;
@property (weak, nonatomic) IBOutlet UILabel *chooseLocation;
@property (weak, nonatomic) IBOutlet UILabel *chooseDelivery;

@property (strong, nonatomic) PFGeoPoint *geopoint;

//text fields
@property (weak, nonatomic) IBOutlet UITextField *titleField;
@property (weak, nonatomic) IBOutlet UITextView *extraField;
@property (weak, nonatomic) IBOutlet UITextField *payField;

//camera buttons
@property (weak, nonatomic) IBOutlet UIButton *firstCam;
@property (weak, nonatomic) IBOutlet UIButton *secondCam;
@property (weak, nonatomic) IBOutlet UIButton *thirdCam;
@property (weak, nonatomic) IBOutlet UIButton *fourthCam;

//delete buttons
@property (weak, nonatomic) IBOutlet UIButton *firstDelete;
@property (weak, nonatomic) IBOutlet UIButton *secondDelete;
@property (weak, nonatomic) IBOutlet UIButton *thirdDelete;
@property (weak, nonatomic) IBOutlet UIButton *fourthDelete;

//images & image views
@property (nonatomic, strong) UIImage *firstImage;
@property (nonatomic, strong) UIImage *secondImage;
@property (nonatomic, strong) UIImage *thirdImage;
@property (nonatomic, strong) UIImage *fourthImage;
@property (weak, nonatomic) IBOutlet PFImageView *firstImageView;
@property (nonatomic) int camButtonTapped;
@property (nonatomic) int photostotal;
@property (weak, nonatomic) IBOutlet PFImageView *secondImageView;
@property (weak, nonatomic) IBOutlet PFImageView *thirdImageView;
@property (weak, nonatomic) IBOutlet PFImageView *fourthImageView;

@property (nonatomic, strong) NSString *selection;
@property (weak, nonatomic) IBOutlet UILabel *warningLabel;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *lastId;

@property (nonatomic, strong) PFObject *listing;

@property (nonatomic, strong) NSString *genderSize;
@property (nonatomic, strong) NSString *firstSize;
@property (nonatomic, strong) NSString *secondSize;
@property (nonatomic, strong) NSString *thirdSize;


@property (nonatomic) BOOL editFromListing;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (nonatomic, strong) UIBarButtonItem *resetButton;

@property (nonatomic, strong) NSArray *sizesArray;
@property (nonatomic, strong) TOWebViewController *webViewController;

@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic) BOOL hudShowing;
@property (nonatomic) BOOL shouldShowHUD;

@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

@property (nonatomic, strong) NSArray *profanityList;

@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (nonatomic) BOOL introMode;

@property (nonatomic, strong) UIImagePickerController *picker;
@end
