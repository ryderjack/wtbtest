//
//  ProfileController.h
//  wtbtest
//
//  Created by Jack Ryder on 07/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "TOJRWebView.h"
#import "inviteViewClass.h"

@class ProfileController;

@protocol ProfileSettingsDelegate <NSObject>
- (void)TeamBumpInboxTapped;
@end

@interface ProfileController : UITableViewController <MFMailComposeViewControllerDelegate, JRWebViewDelegate, inviteDelegate>

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
@property (weak, nonatomic) IBOutlet UIImageView *unreadView;
@property (strong, nonatomic) IBOutlet UITableViewCell *termsCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *rateCell;

//delegate
@property (nonatomic, weak) id <ProfileSettingsDelegate> delegate;

//modes
@property (nonatomic) BOOL modal;

//Team Bump
@property (nonatomic) BOOL unseenTBMsg;

//web
@property (nonatomic, strong) TOJRWebView *webView;

//invite pop up
@property (nonatomic, strong) inviteViewClass *inviteView;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic) BOOL alertShowing;
@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end
