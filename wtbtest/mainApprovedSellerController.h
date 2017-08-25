//
//  mainApprovedSellerController.h
//  wtbtest
//
//  Created by Jack Ryder on 01/06/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>
#import <Parse/Parse.h>
#import "legitCheckController.h"
#import "sellerTutController.h"
#import "customAlertViewClass.h"

@interface mainApprovedSellerController : UITableViewController <legitDelegate,sellerTutDelegate,customAlertDelegate>

@property (strong, nonatomic) IBOutlet UITableViewCell *mainCell;

//cell buttons
@property (weak, nonatomic) IBOutlet UIButton *legitButton;
@property (weak, nonatomic) IBOutlet UIButton *listButton;
@property (weak, nonatomic) IBOutlet UIButton *pushButton;

//update button
@property (nonatomic, strong) UIButton *longButton;
@property (nonatomic) BOOL buttonShowing;
@property (nonatomic) BOOL barButtonPressed;

//status
@property (nonatomic) BOOL legitCheckDone;
@property (nonatomic) BOOL howListDone;
@property (nonatomic) BOOL pushDone;

@property (nonatomic) BOOL submitted;

//hud
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic, strong) PFObject *sellerApplication;

//push prompt
@property (nonatomic, strong) customAlertViewClass *pushAlert;
@property (nonatomic) BOOL shownPushAlert;
@property (nonatomic, strong) UIView *searchBgView;
@property (nonatomic) BOOL settingsMode;

//status labels
@property (weak, nonatomic) IBOutlet UILabel *topStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomStatusLabel;

//explain label
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;

//new request
@property (nonatomic) BOOL newReqMode;

@end
