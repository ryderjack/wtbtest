//
//  ShippingController.h
//  wtbtest
//
//  Created by Jack Ryder on 09/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@class ShippingController;

@protocol ShippingControllerDelegate <NSObject>
- (void)addItemViewController:(ShippingController *)controller didFinishEnteringAddress:(NSString *)address;
@end

@interface ShippingController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, weak) id <ShippingControllerDelegate> delegate;

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *buildingCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *streetnameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *cityCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *postcodeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *phoneNumCell;
@property (weak, nonatomic) IBOutlet UILabel *warningLabel;

//text fields
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *buildingField;
@property (weak, nonatomic) IBOutlet UITextField *streetField;
@property (weak, nonatomic) IBOutlet UITextField *cityField;
@property (weak, nonatomic) IBOutlet UITextField *postcodeField;
@property (weak, nonatomic) IBOutlet UITextField *numberField;

@property (nonatomic) PFUser *currentUser;
@property (nonatomic) BOOL settingsMode;



@end
