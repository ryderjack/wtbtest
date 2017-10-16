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

@interface FeedbackController : UITableViewController <UITextViewDelegate>
NS_ASSUME_NONNULL_BEGIN
@property (strong, nonatomic) IBOutlet UITableViewCell *starCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *commentCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *spaceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *supportCell;

//star cell
@property (weak, nonatomic) IBOutlet UIButton *firstStar;
@property (weak, nonatomic) IBOutlet UIButton *secondStar;
@property (weak, nonatomic) IBOutlet UIButton *thirdStar;
@property (weak, nonatomic) IBOutlet UIButton *fourthStar;
@property (weak, nonatomic) IBOutlet UIButton *fifthStar;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;

//comment cell
@property (weak, nonatomic) IBOutlet UITextView *commentView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;

//order
@property (nonatomic, strong) PFObject *orderObject;

//edit mode
@property (nonatomic) BOOL editMode;
@property (nonatomic, strong) PFObject *editFBObject;
@property (nonatomic) int previousReview;

//general
@property (nonatomic, strong) PFUser *user;
@property (nonatomic) BOOL purchased;
@property (nonatomic) int starNumber;
@property (nonatomic) BOOL fetchedUser;

@property (nonatomic) BOOL sentPush;

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

//support
@property (nonatomic) BOOL tappedSupport;

NS_ASSUME_NONNULL_END
@end
