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

@interface SettingsController : UITableViewController <ShippingControllerDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITableViewCell *addressCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *emailCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *nameCell;

//textfields
@property (weak, nonatomic) IBOutlet UITextField *emailFields;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addLabel;

@property (nonatomic, strong) PFUser *currentUser;


@end
