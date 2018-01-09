//
//  ShippingController.h
//  wtbtest
//
//  Created by Jack Ryder on 09/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <CountryPicker/CountryPicker.h>

@class ShippingController;

@protocol ShippingControllerDelegate <NSObject>
- (void)addedAddress:(NSString *)address withName:(NSString *)name withLineOne:(NSString *)one withLineTwo:(NSString *)two withCity:(NSString *)city withCountry:(NSString *)country fullyEntered:(BOOL)complete;
@end

@interface ShippingController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, weak) id <ShippingControllerDelegate> delegate;

@property (nonatomic, strong) UIBarButtonItem *cancelButton;

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *buildingCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *streetnameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *cityCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *postcodeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *phoneNumCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *countryCell;

@property (strong, nonatomic) IBOutlet UITableViewCell *addressLineOne;
@property (strong, nonatomic) IBOutlet UITableViewCell *addressLineTwo;

//text fields
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *buildingField;
@property (weak, nonatomic) IBOutlet UITextField *streetField;

@property (weak, nonatomic) IBOutlet UITextField *cityField;
@property (weak, nonatomic) IBOutlet UITextField *postcodeField;
@property (weak, nonatomic) IBOutlet UITextField *numberField;
@property (weak, nonatomic) IBOutlet UITextField *countryField;
@property (weak, nonatomic) IBOutlet UITextField *addressLine1;
@property (weak, nonatomic) IBOutlet UITextField *addressLine2;

@property (nonatomic) PFUser *currentUser;
@property (nonatomic) BOOL settingsMode;
@property (nonatomic) BOOL somethingChanged;
@property (nonatomic, strong) CountryPicker *picker;
@property (nonatomic) BOOL somethingMissing;


@end
