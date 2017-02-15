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

@class WelcomeViewController;

@protocol WelcomeDelegate <NSObject>
- (void)welcomeDismissed;
@end

@interface WelcomeViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *tutorialTestButton;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

//delegate
@property (nonatomic, weak) id <WelcomeDelegate> delegate;
@end
