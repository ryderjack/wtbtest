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

@interface ProfileController : UITableViewController <MFMailComposeViewControllerDelegate, JRWebViewDelegate>

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
@property (weak, nonatomic) IBOutlet UIImageView *unreadView;
@property (strong, nonatomic) IBOutlet UITableViewCell *termsCell;

//web
@property (nonatomic, strong) TOJRWebView *webView;

@end
