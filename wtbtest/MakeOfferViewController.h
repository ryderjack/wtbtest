//
//  MakeOfferViewController.h
//  wtbtest
//
//  Created by Jack Ryder on 05/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface MakeOfferViewController : UITableViewController

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *buyerCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *picCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *saleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *conditionCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sizeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *locationCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *methodCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *deliveryCostCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *totalCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *extraCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *buttonCell;

//titleCell
@property (weak, nonatomic) IBOutlet UILabel *itemTitle;

//buyerCell
@property (weak, nonatomic) IBOutlet UILabel *buyerName;
@property (weak, nonatomic) IBOutlet PFImageView *profileView;
@property (weak, nonatomic) IBOutlet UIImageView *starView;

//picCell
@property (weak, nonatomic) IBOutlet UILabel *explainLabel;

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

@property (nonatomic) int camButtonTapped;
@property (nonatomic) int photostotal;

@property (weak, nonatomic) IBOutlet UIImageView *firstImageView;
@property (weak, nonatomic) IBOutlet UIImageView *secondImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thirdImageView;
@property (weak, nonatomic) IBOutlet UIImageView *fourthImageView;

//mainCells
@property (weak, nonatomic) IBOutlet UITextField *priceField;
@property (weak, nonatomic) IBOutlet UITextField *deliveryField;
@property (weak, nonatomic) IBOutlet UITextView *extraFiel;

//choose buttons
@property (weak, nonatomic) IBOutlet UILabel *chooseCondition;
@property (weak, nonatomic) IBOutlet UILabel *chooseSize;
@property (weak, nonatomic) IBOutlet UILabel *chooseLocation;
@property (weak, nonatomic) IBOutlet UILabel *chooseDelivery;

@property (nonatomic, strong) PFObject *listingObject;

@end
