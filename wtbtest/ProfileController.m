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
#import "SummaryCollectionView.h"
#import "UserProfileController.h"
#import "SettingsController.h"
#import "ExplainViewController.h"

@interface ProfileController ()

@end

@implementation ProfileController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    //paypal icons in footer
    UIView *footerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    [footerView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
//    UILabel *versionLabel = [[UILabel alloc]initWithFrame:CGRectMake(12, 0, 30, 30)];
    
    //insert version when have current installation data via push
    self.tableView.tableFooterView = footerView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.title = [NSString stringWithFormat:@"%@", [PFUser currentUser].username];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
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
            vc.setting = @"process";
            [self presentViewController:vc animated:YES completion:nil];
        }
        else if (indexPath.row == 1) {
            //send us feedback
            [self showEmail];
        }
    }
}

- (void)showEmail{
    NSString *emailTitle = @"Help us make bump better!";
    NSString *messageBody = @"Yo\n\n Tell us how we can make bump even better or any problems you've faced! We promise to reply within an hour.";
    NSArray *toRecipents = [NSArray arrayWithObject:@"ryder_jack@hotmail.co.uk"];
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
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
