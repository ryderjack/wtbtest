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

@class FeedbackController;

@protocol feedbackDelegate <NSObject>
- (void)leftReview;
@end

@interface FeedbackController : UITableViewController <UITextFieldDelegate>
NS_ASSUME_NONNULL_BEGIN
@property (strong, nonatomic) IBOutlet UITableViewCell *starCell;

//star cell
@property (weak, nonatomic) IBOutlet UIButton *firstStar;
@property (weak, nonatomic) IBOutlet UIButton *secondStar;
@property (weak, nonatomic) IBOutlet UIButton *thirdStar;
@property (weak, nonatomic) IBOutlet UIButton *fourthStar;
@property (weak, nonatomic) IBOutlet UIButton *fifthStar;
@property (weak, nonatomic) IBOutlet UITextField *commentField;

@property (weak, nonatomic) IBOutlet UILabel *usersNameLabel;

@property (nonatomic) BOOL isBuyer;

@property (nonatomic, strong) PFUser *user;
@property (nonnull, strong) NSString *IDUser;
@property (nonatomic) BOOL purchased;
@property (nonatomic) int starNumber;

@property (nonatomic, strong) NSString *statusString;
@property (nonatomic, strong) PFObject *convoObject;

//main cell
@property (weak, nonatomic) IBOutlet UILabel *explainLabel;
@property (weak, nonatomic) IBOutlet PFImageView *userImageView;

//spinner
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic, strong) NSArray *profanityList;

//big button
@property (nonatomic, strong) UIButton *longButton;
@property (nonatomic) BOOL buttonShowing;

//delegate
@property (nonatomic, weak) id <feedbackDelegate> delegate;

//rate
@property (nonatomic, strong) UINavigationController *messageNav;


NS_ASSUME_NONNULL_END
@end
