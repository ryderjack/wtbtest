//
//  WelcomeViewController.h
//  wtbtest
//
//  Created by Jack Ryder on 23/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>
#import <SwipeView/SwipeView.h>
#import "loginEmailController.h"
#import "RegisterViewController.h"

@class WelcomeViewController;

@protocol WelcomeDelegate <NSObject>
- (void)welcomeDismissed;
@end

@interface WelcomeViewController : UIViewController <SwipeViewDelegate, SwipeViewDataSource,LoginVCDelegate,RegVCDelegate>
@property (weak, nonatomic) IBOutlet UIButton *tutorialTestButton;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

//delegate
@property (nonatomic, weak) id <WelcomeDelegate> delegate;

//brand swipe view
@property (weak, nonatomic) IBOutlet SwipeView *brandSwipeView;
@property (nonatomic, strong) NSArray *brandArray;

@end
