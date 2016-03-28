//
//  OrderSummaryController.h
//  wtbtest
//
//  Created by Jack Ryder on 18/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface OrderSummaryController : UITableViewController

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *userCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *imageCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *shippingCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *itempriceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *deliveryCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *feeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *checkCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *totalCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *buttonCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sellerButtons;

//title cell
@property (weak, nonatomic) IBOutlet UILabel *itemTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *conditionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *titleImageView;
@property (weak, nonatomic) IBOutlet UILabel *actionLabel;

//user cell
@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *dealsLabel;
@property (weak, nonatomic) IBOutlet UIImageView *starsImgView;
@property (weak, nonatomic) IBOutlet PFImageView *userImageView;

//image cell
@property (weak, nonatomic) IBOutlet PFImageView *firstImageView;
@property (weak, nonatomic) IBOutlet PFImageView *secondImageView;
@property (weak, nonatomic) IBOutlet PFImageView *thirdImageView;
@property (weak, nonatomic) IBOutlet PFImageView *fourthImageView;
@property (weak, nonatomic) IBOutlet UILabel *explainLabel;

//shipping cell
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;

//main cells
@property (weak, nonatomic) IBOutlet UILabel *itemPrice;
@property (weak, nonatomic) IBOutlet UILabel *deliveryLabel;
@property (weak, nonatomic) IBOutlet UILabel *feeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UILabel *checkLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalCostLabel;

//button cell

@property (nonatomic, strong) PFObject *orderObject;
@property (nonatomic, strong) PFObject *confirmedOffer;
@property (nonatomic, strong) PFUser *otherUser;
@property (weak, nonatomic) IBOutlet UIButton *shippedButton;
@property (nonatomic) BOOL purchased;
@property (nonatomic, strong) NSString *statusString;
@end
