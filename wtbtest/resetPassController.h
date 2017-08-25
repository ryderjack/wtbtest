//
//  resetPassController.h
//  wtbtest
//
//  Created by Jack Ryder on 01/08/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>
#import <Parse/Parse.h>

@interface resetPassController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UITextField *mainTextField;
@property (weak, nonatomic) IBOutlet UILabel *warningLabel;

//hud
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

//mode
@property (nonatomic) BOOL resetMode;
@property (nonatomic, strong) NSString *userId;

@property (nonatomic) BOOL dontMatchError;

//retrieved user
@property (nonatomic, strong) PFUser *retrievedUser;

@end
