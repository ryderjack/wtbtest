//
//  ProfileController.m
//  wtbtest
//
//  Created by Jack Ryder on 07/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ProfileController.h"
#import <Parse/Parse.h>
#import "FBGroupShareViewController.h"
#import "UserProfileController.h"
#import "SettingsController.h"
#import <Crashlytics/Crashlytics.h>
#import "ChatWithBump.h"
#import "ContainerViewController.h"
#import "NavigationController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "AddSizeController.h"
#import "ExplainView.h"
#import "AppDelegate.h"

@interface ProfileController ()

@end

@implementation ProfileController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.showSnapDot == YES) {
        [self.snapSeen setHidden:NO];
        [self.delegate snapSeen];
    }
    else{
        [self.snapSeen setHidden:YES];
    }
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    //version in footer
    UIView *footerView = [[UIView alloc]initWithFrame:CGRectMake(0, -30, self.view.frame.size.width, 30)];
    [footerView setBackgroundColor:self.tableView.backgroundColor];
    UILabel *versionLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, 50, 20)];
    [versionLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:12]];
    versionLabel.textColor = [UIColor lightGrayColor];
    PFInstallation *thisInstall = [PFInstallation currentInstallation];
    versionLabel.text = [NSString stringWithFormat:@"%@", [thisInstall objectForKey:@"appVersion"]];
    [footerView addSubview:versionLabel];
    self.tableView.tableFooterView = footerView;
    
    if (self.modal == YES) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cancelCross"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    
    if (self.unseenTBMsg == YES) {
        NSLog(@"unseen TB msg");
        [self.unreadView setHidden:NO];
    }
    else{
        [self.unreadView setHidden:YES];
    }
    
    //dismiss Invite gesture
    self.tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideInviteView)];
    self.tap.numberOfTapsRequired = 1;
    
//    //user will have seen the add prompt now so disable them seeing it
//    if (![[PFUser currentUser]objectForKey:@"snapSeen"]) {
//        [PFUser currentUser][@"snapSeen"] = @"YES";
//        [[PFUser currentUser]saveInBackground];
//    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.tappedTB) {
        self.tappedTB = NO;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setHidden:NO];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:15],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.navigationItem.title = [NSString stringWithFormat:@"@%@", [PFUser currentUser].username];
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Profile"
                                      }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 2;
    }
    else if (section == 1){
        return 2;
    }
    else if (section == 2){
        return 5;
    }
    else if (section == 3){
        return 1;
    }
    else{
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.inviteCell;
        }
        else if (indexPath.row == 1) {
            return self.rateCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.instaCell;
        }
        else if (indexPath.row == 1) {
            return self.feedbackCell;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return self.settingsCell;
        }
        else if (indexPath.row == 1) {
            return self.defaultSizesCell;
        }
        else if (indexPath.row == 2) {
            return self.howItWorks;
        }
        else if (indexPath.row == 3) {
            return self.FAQCell;
        }
        else if (indexPath.row == 4) {
            return self.termsCell;
        }
    }
    else if (indexPath.section == 3){
        if (indexPath.row == 0) {
            return self.logOutCell;
        }
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            //invite pressed
            [self showInviteView];
        }
        else if (indexPath.row == 1) {
            [Answers logCustomEventWithName:@"Show Rate"
                           customAttributes:@{
                                              @"where": @"settings"
                                              }];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showRate" object:self.navigationController];
        }

    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {

            [Answers logCustomEventWithName:@"Insta Follow Pressed"
                           customAttributes:@{}];
            
            NSURL *instaURL = [NSURL URLWithString:@"instagram://user?username=bump_official"];
            if ([[UIApplication sharedApplication] canOpenURL: instaURL]) {
                [[UIApplication sharedApplication] openURL: instaURL];
            }
        }
        else if (indexPath.row == 1) {
            //chat w/ Bump
            if (self.tappedTB) {
                return;
            }
            
            self.tappedTB = YES;
            
            [Answers logCustomEventWithName:@"Chat with Bump pressed"
                           customAttributes:@{}];
            
            //reset profile badges
            [self.delegate TeamBumpInboxTapped];
            
            PFQuery *convoQuery = [PFQuery queryWithClassName:@"teamConvos"];
            NSString *convoId = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
            [convoQuery whereKey:@"convoId" equalTo:convoId];
            [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    //convo exists, go there
                    ChatWithBump *vc = [[ChatWithBump alloc]init];
                    vc.convoId = [object objectForKey:@"convoId"];
                    vc.convoObject = object;
                    vc.otherUser = [PFUser currentUser];
                    vc.showSuggested = YES;
                    [self.unreadView setHidden:YES];
                    [self.navigationController tabBarItem].badgeValue = nil;
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else{
                    //create a new one
                    PFObject *convoObject = [PFObject objectWithClassName:@"teamConvos"];
                    convoObject[@"otherUser"] = [PFUser currentUser];
                    convoObject[@"convoId"] = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
                    convoObject[@"totalMessages"] = @0;
                    [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (succeeded) {
                            //saved, goto VC
                            ChatWithBump *vc = [[ChatWithBump alloc]init];
                            vc.convoId = [convoObject objectForKey:@"convoId"];
                            vc.convoObject = convoObject;
                            vc.otherUser = [PFUser currentUser];
                            vc.showSuggested = YES;
                            [self.unreadView setHidden:YES];
                            [self.navigationController tabBarItem].badgeValue = nil;
                            [self.navigationController pushViewController:vc animated:YES];
                        }
                        else{
                            NSLog(@"error saving convo");
                        }
                    }];
                }
            }];
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            //settings pressed
            [Answers logCustomEventWithName:@"Settings pressed"
                           customAttributes:@{}];
            
            SettingsController *vc = [[SettingsController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if (indexPath.row == 1) {
            //change sizes pressed
            [Answers logCustomEventWithName:@"Change default sizes pressed"
                           customAttributes:@{}];
            
            AddSizeController *vc = [[AddSizeController alloc]init];
            vc.editMode = YES;
            [self presentViewController:vc animated:YES
                             completion:nil];
        }
        else if (indexPath.row == 2) {
            //how it works pressed
//            ContainerViewController *vc = [[ContainerViewController alloc]init];
//            vc.explainMode = YES;
            [Answers logCustomEventWithName:@"How works pressed"
                           customAttributes:@{}];
            
            ExplainView *vc = [[ExplainView alloc]init];
            vc.introMode = NO;
            [self presentViewController:vc animated:YES
                             completion:nil];
        }
        else if (indexPath.row == 3) {
            //FAQs pressed
            [Answers logCustomEventWithName:@"FAQs pressed"
                           customAttributes:@{}];
            
            NSString *URLString = @"http://sobump.com/FAQ/FAQ";
            self.webView = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
            self.webView.showUrlWhileLoading = YES;
            self.webView.showPageTitles = YES;
            self.webView.doneButtonTitle = @"";
            self.webView.payMode = NO;
            self.webView.infoMode = NO;
            self.webView.delegate = self;
            
            NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.webView];
            [self presentViewController:navigationController animated:YES completion:nil];
        }
        else if (indexPath.row == 4) {
            //terms pressed
            [Answers logCustomEventWithName:@"Terms pressed"
                           customAttributes:@{}];
            
            NSString *URLString = @"http://www.sobump.com/terms";
            self.webView = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
            self.webView.title = @"Terms & Conditions";
            self.webView.showUrlWhileLoading = YES;
            self.webView.showPageTitles = NO;
            self.webView.doneButtonTitle = @"";
            //hide toolbar banner
            self.webView.infoMode = NO;
            self.webView.delegate = self;
            NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.webView];
            [self presentViewController:navigationController animated:YES completion:nil];
        }
    }
    else if (indexPath.section == 3){
        if (indexPath.row == 0) {
            //log out pressed
            [Answers logCustomEventWithName:@"Log Out Pressed"
                           customAttributes:@{}];
            [self dismissViewControllerAnimated:YES completion:^{
                
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                appDelegate.tabBarController.selectedIndex = 0;
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"invalidSessionNotification" object:nil];
                });
            }];
        }
    }
}

-(void)paidPressed{
    //do nothing
}

-(void)cancelWebPressed{
    [self.webView dismissViewControllerAnimated:YES completion:nil];
}

-(void)cameraPressed{
    //do nothing
}

-(void)screeshotPressed:(UIImage *)screenshot withTaps:(int)taps{
    //do nothing
}

- (void)showEmail{
    NSString *emailTitle = @"Help us make Bump better!";
    NSString *messageBody = @"Yo\n\n Tell us how we can make Bump even better or any problems you've faced! We promise to reply within an hour.\nPS send us screenshots of anything not working properly!";
    NSArray *toRecipents = [NSArray arrayWithObject:@"hello@sobump.com"];
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    if (!mc) {
        //no email accounts setup so return
        return;
    }
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];
    [self presentViewController:mc animated:YES completion:NULL];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultSent:
            break;
        case MFMailComposeResultFailed:
            break;
        default:
            break;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)cancelPressed{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - invite view delegates

-(void)showInviteView{
    [Answers logCustomEventWithName:@"Invite Showing"
                   customAttributes:@{
                                      @"where": @"settings"
                                      }];
    
    if (self.alertShowing == YES) {
        return;
    }
    
    self.alertShowing = YES;
    self.bgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.bgView.alpha = 0.0;
    [self.bgView setBackgroundColor:[UIColor blackColor]];
    [[UIApplication sharedApplication].keyWindow addSubview:self.bgView];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.bgView.alpha = 0.6f;
                     }
                     completion:nil];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"inviteView" owner:self options:nil];
    self.inviteView = (inviteViewClass *)[nib objectAtIndex:0];
    self.inviteView.delegate = self;
    
    //setup images
    NSMutableArray *friendsArray = [NSMutableArray arrayWithArray:[[PFUser currentUser] objectForKey:@"friends"]];
    
    //manage friends count label
    if (friendsArray.count > 5) {
        self.inviteView.friendsLabel.text = [NSString stringWithFormat:@"%lu friends use Bump", (unsigned long)friendsArray.count];
    }
    else{
        self.inviteView.friendsLabel.text = @"Help us grow 🚀";
    }
    
    if (friendsArray.count > 0) {
        [self shuffle:friendsArray];
        if (friendsArray.count >2) {
            NSURL *picUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", friendsArray[0]]];
            [self.inviteView.friendImageOne sd_setImageWithURL:picUrl];
            
            NSURL *picUrl2 = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large",friendsArray[1]]];
            [self.inviteView.friendImageTwo sd_setImageWithURL:picUrl2];
            
            NSURL *picUrl3 = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large",friendsArray[2]]];
            [self.inviteView.friendImageThree sd_setImageWithURL:picUrl3];
        }
        else if (friendsArray.count == 2){
            NSURL *picUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", friendsArray[0]]];
            [self.inviteView.friendImageOne sd_setImageWithURL:picUrl];
            
            NSURL *picUrl2 = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large",friendsArray[1]]];
            [self.inviteView.friendImageTwo sd_setImageWithURL:picUrl2];
            
            NSURL *picUrl3 = [NSURL URLWithString:@"https://graph.facebook.com/781237282045226/picture?type=large"]; //use viv's image to fill gap
            [self.inviteView.friendImageThree sd_setImageWithURL:picUrl3];
        }
        else if (friendsArray.count == 1){
            NSURL *picUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", friendsArray[0]]];
            [self.inviteView.friendImageOne sd_setImageWithURL:picUrl];
            
            NSURL *picUrl2 = [NSURL URLWithString:@"https://graph.facebook.com/781237282045226/picture?type=large"]; //use viv's image
            [self.inviteView.friendImageTwo sd_setImageWithURL:picUrl2];
            
            NSURL *picUrl3 = [NSURL URLWithString:@"https://graph.facebook.com/10154993039808844/picture?type=large"]; //use tayler's image to fill gap
            [self.inviteView.friendImageThree sd_setImageWithURL:picUrl3];
        }
    }
    else{
        NSURL *picUrl = [NSURL URLWithString:@"https://graph.facebook.com/10207070036095375/picture?type=large"]; //use matsisland's image
        [self.inviteView.friendImageOne sd_setImageWithURL:picUrl];
        
        NSURL *picUrl2 = [NSURL URLWithString:@"https://graph.facebook.com/781237282045226/picture?type=large"]; //use viv's image
        [self.inviteView.friendImageTwo sd_setImageWithURL:picUrl2];
        NSURL *picUrl3 = [NSURL URLWithString:@"https://graph.facebook.com/10154993039808844/picture?type=large"]; //use tayler's image to fill gap
        [self.inviteView.friendImageThree sd_setImageWithURL:picUrl3];
    }
    
    [self.inviteView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -300, 300, 300)];
    
    self.inviteView.layer.cornerRadius = 10;
    self.inviteView.layer.masksToBounds = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.inviteView];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            [self.inviteView setFrame:CGRectMake(0, 0, 300, 300)];
                            self.inviteView.center = self.view.center;
                        }
                     completion:^(BOOL finished) {
                         [self.bgView addGestureRecognizer:self.tap];
                     }];
}

-(void)hideInviteView{
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.bgView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         self.bgView = nil;
                         [self.bgView removeGestureRecognizer:self.tap];
                     }];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            [self.inviteView setFrame:CGRectMake((self.view.frame.size.width/2)-150, 1000, 300, 300)];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         self.alertShowing = NO;
                         [self.inviteView setAlpha:0.0];
                         self.inviteView = nil;
                     }];
}


-(void)whatsappPressed{
    [Answers logCustomEventWithName:@"Share Pressed"
                   customAttributes:@{
                                      @"type":@"whatsapp"
                                      }];
    NSString *shareString = @"Check out Bump for iOS - buy & sell streetwear quickly and with ZERO fees 👟\n\nAvailable here: http://sobump.com";
    NSURL *whatsappURL = [NSURL URLWithString:[NSString stringWithFormat:@"whatsapp://send?text=%@",[self urlencode:shareString]]];
    if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
        [[UIApplication sharedApplication] openURL: whatsappURL];
    }
}

-(void)messengerPressed{
    [Answers logCustomEventWithName:@"Share Pressed"
                   customAttributes:@{
                                      @"type":@"messenger"
                                      }];
    NSURL *messengerURL = [NSURL URLWithString:@"fb-messenger://share/?link=http://sobump.com"];
    if ([[UIApplication sharedApplication] canOpenURL: messengerURL]) {
        [[UIApplication sharedApplication] openURL: messengerURL];
    }
}

-(void)textPressed{
    [self hideInviteView];
    [Answers logCustomEventWithName:@"Share Pressed"
                   customAttributes:@{
                                      @"type":@"share sheet"
                                      }];
    NSMutableArray *items = [NSMutableArray new];
    [items addObject:@"Check out Bump for iOS - buy & sell streetwear quickly and with ZERO fees 👟\n\nAvailable here: http://sobump.com"];
    UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (void)shuffle:(NSMutableArray *)array
{
    NSUInteger count = [array count];
    if (count <= 1) return;
    for (NSUInteger i = 0; i < count - 1; ++i) {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t )remainingCount);
        [array exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
}

- (NSString *)urlencode:(NSString *)stringToEncode{
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[stringToEncode UTF8String];
    int sourceLen = (int)strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}
@end
