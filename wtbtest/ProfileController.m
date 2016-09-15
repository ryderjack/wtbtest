//
//  ProfileController.m
//  wtbtest
//
//  Created by Jack Ryder on 07/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ProfileController.h"
#import <Parse/Parse.h>
#import "OffersController.h"
#import "FBGroupShareViewController.h"
#import "UserProfileController.h"
#import "SettingsController.h"
#import "ExplainViewController.h"
#import "Flurry.h"
#import <Crashlytics/Crashlytics.h>

@interface ProfileController ()

@end

@implementation ProfileController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    //version in footer
    UIView *footerView = [[UIView alloc]initWithFrame:CGRectMake(0, -30, self.view.frame.size.width, 30)];
    [footerView setBackgroundColor:self.tableView.backgroundColor];
    UILabel *versionLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, 50, 20)];
    [versionLabel setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:12]];
    versionLabel.textColor = [UIColor lightGrayColor];
    PFInstallation *thisInstall = [PFInstallation currentInstallation];
    versionLabel.text = [NSString stringWithFormat:@"%@", [thisInstall objectForKey:@"appVersion"]];
    [footerView addSubview:versionLabel];
    self.tableView.tableFooterView = footerView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.title = [NSString stringWithFormat:@"%@", [PFUser currentUser].username];
    [Flurry logEvent:@"Profile_Tapped"];
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
        return 1;
    }
    else if (section == 3){
        return 2;
    }
    else{
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.profileCell;
        }
        else if (indexPath.row == 1) {
            return self.savedLaterCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.purchasedItems;
        }
        else if (indexPath.row == 1) {
            return self.soldItems;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return self.settingsCell;
        }
    }
    else if (indexPath.section == 3){
        if (indexPath.row == 0) {
            return self.howItWorks;
        }
        else if (indexPath.row == 1) {
            return self.feedbackCell;
        }
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            //profile pressed
            UserProfileController *vc = [[UserProfileController alloc]init];
            vc.user = [PFUser currentUser];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if (indexPath.row == 1){
            //saved for later pressed
            OffersController *vc = [[OffersController alloc]init];
            vc.mode = @"saved";
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            //purchase pressed
            OffersController *vc = [[OffersController alloc]init];
            vc.mode = @"purchased";
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if (indexPath.row == 1){
            //sold pressed
            OffersController *vc = [[OffersController alloc]init];
            vc.mode = @"sold";
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            //settings pressed
            SettingsController *vc = [[SettingsController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else if (indexPath.section == 3){
        if (indexPath.row == 0) {
            //how it works pressed
            ExplainViewController *vc = [[ExplainViewController alloc]init];
            [self presentViewController:vc animated:YES completion:nil];
        }
        else if (indexPath.row == 1) {
            //send us feedback
            [self showEmail];
        }
    }
}

- (void)showEmail{
    NSString *emailTitle = @"Help us make Bump better!";
    NSString *messageBody = @"Yo\n\n Tell us how we can make Bump even better or any problems you've faced! We promise to reply within an hour.\nPS send us screenshots of anything not working properly!";
    NSArray *toRecipents = [NSArray arrayWithObject:@"hello@supbump.com"];
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

@end
