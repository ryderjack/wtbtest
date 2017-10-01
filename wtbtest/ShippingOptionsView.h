//
//  ShippingOptionsView.h
//  wtbtest
//
//  Created by Jack Ryder on 28/09/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "LocationView.h"

@class ShippingOptionsView;

@protocol shippingDelegate <NSObject>
- (void)shippingOptionsWithNational:(float)nationalPrice withGlobal:(float)globalPrice withGlobalEnabled:(BOOL)globalOn andCountry:(NSString *)country withCountryCode:(NSString *)code;
@end

@interface ShippingOptionsView : UITableViewController <UITextFieldDelegate, LocationViewControllerDelegate>

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *nationalShippingCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *globalDecisionCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *globalShippingCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *countryCell;


@property (nonatomic, weak) id <shippingDelegate> delegate;

@property (nonatomic) float nationalPrice;
@property (nonatomic) float globalPrice;
@property (nonatomic) BOOL globalEnabled;

@property (nonatomic) int rowNumber;

//textfields
@property (weak, nonatomic) IBOutlet UITextField *nationalTextfield;
@property (weak, nonatomic) IBOutlet UITextField *globalTextfield;
@property (nonatomic, strong) NSString *currencySymbol;
@property (weak, nonatomic) IBOutlet UITextField *countryField;

//switch
@property (weak, nonatomic) IBOutlet UISwitch *globalSwitch;

//dynamic footer w/ label
@property (nonatomic, strong) UIView *countryFooterView;
@property (strong, nonatomic) UILabel *countryFooterLabel;

//country info
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *country;




@end
