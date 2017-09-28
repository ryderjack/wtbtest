//
//  loginEmailController.h
//  wtbtest
//
//  Created by Jack Ryder on 31/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpinKit/RTSpinKitView.h>
#import "MBProgressHUD.h"
#import <MessageUI/MessageUI.h>

@class loginEmailController;

@protocol LoginVCDelegate <NSObject>
- (void)loginVCFacebookPressed;
@end

@interface loginEmailController : UIViewController <UITextFieldDelegate,MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *logInButton;

//hud
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

//warning label
@property (weak, nonatomic) IBOutlet UILabel *warningLabel;

//fb log in
@property (weak, nonatomic) IBOutlet UIButton *facebookLoginButton;

//delegate
@property (nonatomic, weak) id <LoginVCDelegate> delegate;

//reset
@property (weak, nonatomic) IBOutlet UIButton *resetButton;


@end
