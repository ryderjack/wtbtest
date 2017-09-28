//
//  ShippingOptionsView.h
//  wtbtest
//
//  Created by Jack Ryder on 28/09/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ShippingOptionsView;

@protocol shippingDelegate <NSObject>
- (void)shippingOptionsWithNational:(float)nationalPrice withGlobal:(float)globalPrice withGlobalEnabled:(BOOL)globalOn;
@end

@interface ShippingOptionsView : UITableViewController <UITextFieldDelegate>

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *nationalShippingCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *globalDecisionCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *globalShippingCell;


@property (nonatomic, weak) id <shippingDelegate> delegate;

@property (nonatomic) float nationalPrice;
@property (nonatomic) float globalPrice;
@property (nonatomic) BOOL globalEnabled;

@property (nonatomic) int rowNumber;

//textfields
@property (weak, nonatomic) IBOutlet UITextField *nationalTextfield;
@property (weak, nonatomic) IBOutlet UITextField *globalTextfield;
@property (nonatomic, strong) NSString *currencySymbol;

//switch
@property (weak, nonatomic) IBOutlet UISwitch *globalSwitch;



@end
