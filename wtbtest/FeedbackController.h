//
//  FeedbackController.h
//  wtbtest
//
//  Created by Jack Ryder on 24/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>

@interface FeedbackController : UITableViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITableViewCell *userCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *starCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *buttonCell;

//user cell
@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dealsLabel;
@property (weak, nonatomic) IBOutlet UIImageView *starView;
@property (weak, nonatomic) IBOutlet PFImageView *pictureView;

//star cell
@property (weak, nonatomic) IBOutlet UIButton *firstStar;
@property (weak, nonatomic) IBOutlet UIButton *secondStar;
@property (weak, nonatomic) IBOutlet UIButton *thirdStar;
@property (weak, nonatomic) IBOutlet UIButton *fourthStar;
@property (weak, nonatomic) IBOutlet UIButton *fifthStar;
@property (weak, nonatomic) IBOutlet UITextField *commentField;

//button cell
@property (weak, nonatomic) IBOutlet UIButton *feedbackButton;
@property (weak, nonatomic) IBOutlet UIButton *problemButton;

@property (nonatomic, strong) PFUser *user;
@property (nonnull, strong) NSString *IDUser;
@property (nonatomic) BOOL purchased;
@property (nonatomic) int starNumber;
@property (weak, nonatomic) IBOutlet UILabel *warningLabel;

@property (nonatomic, strong) PFObject *orderObject;
@property (nonatomic, strong) NSString *statusString;


//spinner
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

@end
