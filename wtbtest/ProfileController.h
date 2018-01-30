//
//  ProfileController.h
//  wtbtest
//
//  Created by Jack Ryder on 07/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "inviteViewClass.h"
#import "segmentedTableView.h"
#import <YLProgressBar/YLProgressBar.h>

@class ProfileController;

@protocol ProfileSettingsDelegate <NSObject>
- (void)TeamBumpInboxTapped;
- (void)supportTapped;
- (void)snapSeen;
@end

@interface ProfileController : UITableViewController <MFMailComposeViewControllerDelegate, inviteDelegate,segmentedViewDelegate>

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *receivedOffers;
@property (strong, nonatomic) IBOutlet UITableViewCell *sentOffers;
@property (strong, nonatomic) IBOutlet UITableViewCell *purchasedItems;
@property (strong, nonatomic) IBOutlet UITableViewCell *soldItems;
@property (strong, nonatomic) IBOutlet UITableViewCell *settingsCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *profileCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *howItWorks;
@property (strong, nonatomic) IBOutlet UITableViewCell *feedbackCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *savedLaterCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *inviteCell;

@property (strong, nonatomic) IBOutlet UITableViewCell *modPerformanceCell;
@property (weak, nonatomic) IBOutlet UIImageView *unreadView;
@property (weak, nonatomic) IBOutlet UIImageView *unreadSupportView;

@property (strong, nonatomic) IBOutlet UITableViewCell *termsCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *rateCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *snapchatCell;
@property (weak, nonatomic) IBOutlet UIImageView *snapSeen;
@property (strong, nonatomic) IBOutlet UITableViewCell *defaultSizesCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *FAQCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *instaCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *logOutCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *orderSupportCell;

//delegate
@property (nonatomic, weak) id <ProfileSettingsDelegate> delegate;

//modes
@property (nonatomic) BOOL modal;
@property (nonatomic) BOOL showOrderStuff;

//Team Bump
@property (nonatomic) BOOL unseenTBMsg;
@property (nonatomic) BOOL unseenSupport;

@property (nonatomic) BOOL showSnapDot;
@property (nonatomic) BOOL tappedTB;

//invite pop up
@property (nonatomic, strong) inviteViewClass *inviteView;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic) BOOL alertShowing;
@property (nonatomic, strong) UITapGestureRecognizer *tap;

//mod performance cell
@property (weak, nonatomic) IBOutlet UILabel *currentProgressLabel;
@property (weak, nonatomic) IBOutlet UILabel *goalLabel;
@property (weak, nonatomic) IBOutlet UILabel *remainingLabel;
@property (nonatomic) BOOL paidMod;
@property (weak, nonatomic) IBOutlet YLProgressBar *progressBarNew;

@end
