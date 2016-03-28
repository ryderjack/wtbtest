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

@interface ProfileController ()

@end

@implementation ProfileController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
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
            //received pressed
            OffersController *vc = [[OffersController alloc]init];
            vc.mode = @"purchased";
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if (indexPath.row == 1){
            //sent pressed
            OffersController *vc = [[OffersController alloc]init];
            vc.mode = @"sold";
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    
}
@end
