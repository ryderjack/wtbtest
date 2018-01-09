//
//  mediumSizeAlertViewClass.h
//  wtbtest
//
//  Created by Jack Ryder on 06/01/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class mediumSizeAlertViewClass;
@protocol mediumSizeAVDelegate <NSObject>
- (void)mediumAlertButtonPressed:(NSString *)mode;
- (void)mediumAlertRemindPressed:(NSString *)mode;
- (void)mediumAlertLeftPressed;
- (void)mediumAlertRighPressed;
@end

@interface mediumSizeAlertViewClass : UIView

@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UILabel *lowerImageLabel;
@property (weak, nonatomic) IBOutlet UIImageView *ppImageView;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;

@property (nonatomic) BOOL connectedMode;
@property (nonatomic) BOOL connectErrorMode;
@property (nonatomic) BOOL alertMode;
@property (nonatomic) BOOL reminderMode;
@property (nonatomic) BOOL disableMode;
@property (nonatomic) BOOL onboardingError;

@property (weak, nonatomic) IBOutlet UILabel *normalAlertLabel;
@property (weak, nonatomic) IBOutlet UILabel *normalAlertTitleLabel;

@property (weak, nonatomic) IBOutlet UIButton *remindMeLaterButton;

//delegate
@property (nonatomic, weak) id <mediumSizeAVDelegate> delegate;

//buy now reminder mode
@property (weak, nonatomic) IBOutlet UIButton *doItLaterButton;
@property (weak, nonatomic) IBOutlet UILabel *reminderMainLabel;
@property (weak, nonatomic) IBOutlet UIImageView *dollarImageView;

//disable buy now pop up
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@end
