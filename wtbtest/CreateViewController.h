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
#import <DZNPhotoPickerController/DZNPhotoPickerController.h>

@interface CreateViewController : UITableViewController <UIAlertViewDelegate, UITextFieldDelegate, UITextViewDelegate, SelectViewControllerDelegate, LocationViewControllerDelegate, ListingCompleteDelegate, CameraControllerDelegate, DZNPhotoPickerControllerDelegate, UINavigationControllerDelegate>

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
@property (nonatomic) BOOL editFromListing;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@end
