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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.receivedOffers;
        }
        else if (indexPath.row == 1) {
            return self.sentOffers;
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
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            //received pressed
            OffersController *vc = [[OffersController alloc]init];
            vc.mode = @"received";
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if (indexPath.row == 1){
            //sent pressed
            OffersController *vc = [[OffersController alloc]init];
            vc.mode = @"sent";
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
    
}
@end
