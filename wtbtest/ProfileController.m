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
#import <Intercom/Intercom.h>

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
    
    if ([[[PFUser currentUser] objectForKey:@"orderNumber"]intValue] > 0) {
        self.showOrderStuff = YES;
    }
    
    self.modPerformanceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if ([[[PFUser currentUser]objectForKey:@"paidMod"]isEqualToString:@"YES"]) {
        self.paidMod = YES;
        [self.tableView reloadData];
        
        [Answers logCustomEventWithName:@"Mod Checking Performance"
                       customAttributes:@{
                                          @"modName":[PFUser currentUser].username,
                                          @"modId":[PFUser currentUser].objectId
                                          }];
    
        //find out their performance this month
        
        //get difference between start date and now
        PFQuery *modQuery = [PFQuery queryWithClassName:@"modUsers"];
        [modQuery whereKey:@"status" equalTo:@"live"];
        [modQuery whereKey:@"user" equalTo:[PFUser currentUser]];
        [modQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                
                //setup progress bar
                self.progressBarNew.type               = YLProgressBarTypeFlat;
                self.progressBarNew.progressTintColor  = [UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0];
                self.progressBarNew.hideStripes        = YES;
                self.progressBarNew.uniformTintColor = YES;
                self.progressBarNew.trackTintColor = [UIColor colorWithRed:0.86 green:0.93 blue:1.00 alpha:1.0];
                [self.progressBarNew setProgress:0.00];
                
                NSDate *startDate = [object objectForKey:@"startDate"];
                
                NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:startDate];
                double secondsInAMonth = 2620800;

                //months are calculated by 7 x 52 weeks then / 12 for an average
                float monthsSinceSigningUp = distanceBetweenDates / secondsInAMonth;
                
                //round the float down to nearest int to get the start of the month we need
                int startMonth = floor(monthsSinceSigningUp);
                
                //now use this number to calc the start date (by incrementing when they started by the startMonth var) & end dates to query performance from
                NSDateComponents *component = [[NSDateComponents alloc] init];
                component.month = startMonth;
                NSCalendar *theCalendar = [NSCalendar currentCalendar];
                NSDate *newStartDate = [theCalendar dateByAddingComponents:component toDate:startDate options:0];
                
                NSDateComponents *endComponent = [[NSDateComponents alloc] init];
                endComponent.month = 1;
                NSDate *endDate = [theCalendar dateByAddingComponents:endComponent toDate:newStartDate options:0];

                PFQuery *modPerformance = [PFQuery queryWithClassName:@"ModPerformance"];
                [modPerformance whereKey:@"status" equalTo:@"live"];
                modPerformance.limit = 2000;
                [modPerformance whereKey:@"createdAt" greaterThanOrEqualTo:newStartDate];
                [modPerformance whereKey:@"createdAt" lessThan:endDate];
                [modPerformance whereKey:@"unbanned" equalTo:@"NO"];
                [modPerformance whereKey:@"modId" equalTo:[PFUser currentUser].objectId];
                [modPerformance findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (objects) {
                        int currentScore = (int)objects.count;
                        int earnings = 0;
                        
                        //goals
                        int nextGoal = 100;
                        int goalEarnings = 50;

                        
                        //now calc what pay bracket that's in
                        if (currentScore >= 100 && currentScore <= 200) {
                            earnings = 50;
                            nextGoal = 200;
                            goalEarnings = 75;
                        }
                        else if(currentScore >= 201 && currentScore <= 450) {
                            earnings = 75;
                            nextGoal = 450;
                            goalEarnings = 125;
                        }
                        else if(currentScore >= 451 && currentScore <= 650) {
                            earnings = 125;
                            nextGoal = 650;
                            goalEarnings = 200;
                        }
                        else if(currentScore >= 651 && currentScore <= 1500) {
                            earnings = 200;
                            nextGoal = 1500;
                            goalEarnings = 350;
                        }
                        else if(currentScore >= 1500) {
                            earnings = 350;
                            nextGoal = 1500;
                        }
                        else{
                            //below 100
                        }
                        
                        //setup current progress
                        if (currentScore < 100) {
                            self.currentProgressLabel.text = [NSString stringWithFormat:@"%d\nPoints\n⚡️", currentScore];
                        }
                        else{
                            self.currentProgressLabel.text = [NSString stringWithFormat:@"%d\nPoints\nEarnings £%d", currentScore, earnings];
                        }
                        
                        //setup goal side of things
                        if (currentScore >= 1500) {
                            self.goalLabel.text = @"🤑";
                            
                            //give slight delay
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                [self.progressBarNew setProgress:1.0 animated:YES];
                            });
                        }
                        else{
                            //calc remaining
                            int remaining = nextGoal - currentScore;
                            self.remainingLabel.text = [NSString stringWithFormat:@"%d\nRemaining", remaining];
                            
                            self.goalLabel.text = [NSString stringWithFormat:@"%d\nNext Goal\n£%d", nextGoal, goalEarnings];
                            
                            
                            //setup progress bar
                            float scoreFloat = (float)currentScore;
                            float goalFloat = (float)nextGoal;

                            float progress = (scoreFloat/goalFloat);
                            
                            NSLog(@"%.2f progress   %.2f   %.2f", progress, scoreFloat, goalFloat);
                            
                            
                            //give slight delay
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                [self.progressBarNew setProgress:progress animated:YES];
                            });
                        }
                    }
                    else{
                        NSLog(@"error grabbing performance data %@", error);
                    }
                }];
            }
            else{
                NSLog(@"error finding user's mod profile %@", error);
            }
        }];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newIntercomMessage) name:@"NewTBMessage" object:nil];
    
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
    [self setImageBorder:self.unreadView];
    [self setImageBorder:self.unreadSupportView];

    if (self.unseenTBMsg == YES) {
        [self.unreadView setHidden:NO];
    }
    else{
        [self.unreadView setHidden:YES];
    }
    
//    if (self.unseenSupport == YES) {
//        //show unread icon in suport cell
//        [self.unreadSupportView setHidden:NO];
//    }
//    else{
//        [self.unreadSupportView setHidden:YES];
//    }
    
    //dismiss Invite gesture
    self.tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideInviteView)];
    self.tap.numberOfTapsRequired = 1;
}

//handle new intercom messages here too in case user is on here when new message arrives
-(void)newIntercomMessage{
    self.unseenTBMsg = YES;
    [self.unreadView setHidden:NO];
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = 5;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
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
    if (self.paidMod) {
        return 5;
    }
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 1;
    }
    else if (section == 1){
        return 3;
    }
    else if (section == 2){
        return 5;
    }
    else if (section == 3){
        return 1;
    }
    else if (section == 4){
        return 1;
    }
    else{
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.inviteCell;
        }
        else if (indexPath.row == 1) {
            return self.rateCell;
        }
        else if (indexPath.row == 2) {
            return self.instaCell;
        }
    }
    else if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.feedbackCell;
        }
//        else if (indexPath.row == 1) {
//            return self.orderSupportCell;
//        }
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
    else if (indexPath.section == 4){
        if (indexPath.row == 0) {
            return self.modPerformanceCell;
        }
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 4){
        return 190;
    }
    return 44;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section == 4) {
        UIView *header;
        
        if (@available(iOS 11.0, *)) {
            if ([ [ UIScreen mainScreen ] bounds ].size.width == 375) {
                //iPhone6/7
                header = [[UIView alloc]initWithFrame:CGRectMake(16, -5, self.tableView.frame.size.width, 15)];
            }
            else if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
                //iPhone 6 plus
                header = [[UIView alloc]initWithFrame:CGRectMake(20, -5, self.tableView.frame.size.width, 15)];
            }
            else if([ [ UIScreen mainScreen ] bounds ].size.width == 320){
                //iPhone 4/5
                header = [[UIView alloc]initWithFrame:CGRectMake(16, -5, self.tableView.frame.size.width, 15)];
            }
            else{
                //fall back
                header = [[UIView alloc]initWithFrame:CGRectMake(16, -5, self.tableView.frame.size.width, 15)];
            }
        }
        else{
            header = [[UIView alloc]initWithFrame:CGRectMake(8, 0, self.tableView.frame.size.width, 32)];
        }
        UILabel *textLabel = [[UILabel alloc]initWithFrame:header.frame];
        textLabel.textColor = [UIColor grayColor];
        textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        header.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
        
        [header addSubview:textLabel];
        textLabel.text = @"Mod Performance";
        return header;
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section == 1){
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
        else if (indexPath.row == 2) {
            
            [Answers logCustomEventWithName:@"Insta Follow Pressed"
                           customAttributes:@{}];
            
            NSURL *instaURL = [NSURL URLWithString:@"instagram://user?username=bump_official"];
            if ([[UIApplication sharedApplication] canOpenURL: instaURL]) {
                [[UIApplication sharedApplication] openURL: instaURL];
            }
            else{
                NSString *URLString = @"http://instagram.com/bump_official";
                SFSafariViewController *safariView = [[SFSafariViewController alloc]initWithURL:[NSURL URLWithString:URLString]];
                if (@available(iOS 11.0, *)) {
                    safariView.dismissButtonStyle = UIBarButtonSystemItemCancel;
                }
                
                if (@available(iOS 10.0, *)) {
                    safariView.preferredControlTintColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
                }
                
                [self.navigationController presentViewController:safariView animated:YES completion:nil];
            }
        }
    }
    else if (indexPath.section == 0){
        if (indexPath.row == 1) {
            [Answers logCustomEventWithName:@"Support Pressed in Settings"
                           customAttributes:@{}];
            
            //show the unread when any support tickets are unread
            
            //goto support tickets table view
            segmentedTableView *vc = [[segmentedTableView alloc]init];
            vc.supportMode = YES;
            vc.delegate = self;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if (indexPath.row == 0) {
            //chat w/ Bump
//            if (self.tappedTB) {
//                return;
//            }
            
//            self.tappedTB = YES;
            
            //reset profile badges & hide unread icon? or do we still display it after user has tapped & still unseen convo's
            [self.unreadView setHidden:YES];

            [Answers logCustomEventWithName:@"Chat with Bump pressed"
                           customAttributes:@{}];
            
            [Intercom presentMessenger];
            
//
//            PFQuery *convoQuery = [PFQuery queryWithClassName:@"teamConvos"];
//            NSString *convoId = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
//            [convoQuery whereKey:@"convoId" equalTo:convoId];
//            [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
//                if (object) {
//                    //convo exists, go there
//                    ChatWithBump *vc = [[ChatWithBump alloc]init];
//                    vc.convoId = [object objectForKey:@"convoId"];
//                    vc.convoObject = object;
//                    vc.otherUser = [PFUser currentUser];
//                    vc.showSuggested = YES;
//                    [self.navigationController tabBarItem].badgeValue = nil;
//                    [self.navigationController pushViewController:vc animated:YES];
//                }
//                else{
//                    //create a new one
//                    PFObject *convoObject = [PFObject objectWithClassName:@"teamConvos"];
//                    convoObject[@"otherUser"] = [PFUser currentUser];
//                    convoObject[@"convoId"] = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
//                    convoObject[@"totalMessages"] = @0;
//                    [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//                        if (succeeded) {
//                            //saved, goto VC
//                            ChatWithBump *vc = [[ChatWithBump alloc]init];
//                            vc.convoId = [convoObject objectForKey:@"convoId"];
//                            vc.convoObject = convoObject;
//                            vc.otherUser = [PFUser currentUser];
//                            vc.showSuggested = YES;
//                            [self.unreadView setHidden:YES];
//                            [self.navigationController tabBarItem].badgeValue = nil;
//                            [self.navigationController pushViewController:vc animated:YES];
//                        }
//                        else{
//                            NSLog(@"error saving convo");
//                        }
//                    }];
//                }
//            }];
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
            
            NSString *URLString = @"http://help.sobump.com/";
            SFSafariViewController *safariView = [[SFSafariViewController alloc]initWithURL:[NSURL URLWithString:URLString]];
            if (@available(iOS 11.0, *)) {
                safariView.dismissButtonStyle = UIBarButtonSystemItemCancel;
            }

            if (@available(iOS 10.0, *)) {
                safariView.preferredControlTintColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
            }
            
            [self.navigationController presentViewController:safariView animated:YES completion:nil];
        }
        else if (indexPath.row == 4) {
            //terms pressed
            [Answers logCustomEventWithName:@"Terms pressed"
                           customAttributes:@{}];
            
            NSString *URLString = @"http://www.sobump.com/terms";
            SFSafariViewController *safariView = [[SFSafariViewController alloc]initWithURL:[NSURL URLWithString:URLString]];
            if (@available(iOS 11.0, *)) {
                safariView.dismissButtonStyle = UIBarButtonSystemItemCancel;
            }
            
            if (@available(iOS 10.0, *)) {
                safariView.preferredControlTintColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
            }
            
            [self.navigationController presentViewController:safariView animated:YES completion:nil];
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

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    //if intercom unread is 0, reset settings icon on profile
    int intercomUnread = (int)[Intercom unreadConversationCount];
    if (intercomUnread == 0) {
        [self.delegate TeamBumpInboxTapped];
    }
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
        self.inviteView.friendsLabel.text = [NSString stringWithFormat:@"%lu friends use BUMP", (unsigned long)friendsArray.count];
    }
    else{
        self.inviteView.friendsLabel.text = @"Grow the BUMP Community";
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
    
    [Intercom logEventWithName:@"invite_whatsapp_pressed" metaData: @{}];
    
    NSString *shareString = @"Check out BUMP for iOS - Safely Buy & Sell Streetwear\n\nAvailable here: https://sobump.com";
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
    
    [Intercom logEventWithName:@"invite_messenger_pressed" metaData: @{}];

    NSURL *messengerURL = [NSURL URLWithString:@"fb-messenger://share/?link=https://sobump.com"];
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
    
    [Intercom logEventWithName:@"invite_text_pressed" metaData: @{}];

    NSMutableArray *items = [NSMutableArray new];
    [items addObject:@"Check out BUMP for iOS - Safely Buy & Sell Streetwear\n\nAvailable here: http://sobump.com"];
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

-(void)dismissUnreadSupport{
    NSLog(@"dismiss unread in profile controller");
    [self.delegate supportTapped];
}

@end
