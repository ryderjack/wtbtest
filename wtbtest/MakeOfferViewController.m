//
//  MakeOfferViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 05/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "MakeOfferViewController.h"

@interface MakeOfferViewController ()

@end

@implementation MakeOfferViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Make an offer";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.picCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.conditionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.extraCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.deliveryCostCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.methodCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buyerCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.saleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.locationCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.sizeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.totalCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.itemTitle.adjustsFontSizeToFitWidth = YES;
    self.itemTitle.minimumScaleFactor=0.5;
    
    self.buyerName.adjustsFontSizeToFitWidth = YES;
    self.buyerName.minimumScaleFactor=0.5;
    
    self.itemTitle.text = [self.listingObject objectForKey:@"title"];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return 1;
    }
    else if (section ==1){
        return 1;
    }
    else if (section ==2){
        return 1;
    }
    else if (section ==3){
        return 6;
    }
    else if (section ==4){
        return 1;
    }
    else if (section ==5){
        return 1;
    }
    else if (section ==6){
        return 1;
    }
    return 1;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.titleCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.buyerCell;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return self.picCell;
        }
    }
    else if (indexPath.section ==3){
        if (indexPath.row == 0){
            return self.saleCell;
        }
        else if (indexPath.row == 1){
            return self.conditionCell;
        }
        else if (indexPath.row == 2){
            return self.sizeCell;
        }
        else if (indexPath.row == 3){
            return self.locationCell;
        }
        else if (indexPath.row == 4){
            return self.methodCell;
        }
        else if (indexPath.row == 5){
            return self.deliveryCostCell;
        }
    }
    else if (indexPath.section == 4){
        if (indexPath.row == 0) {
            return self.totalCell;
        }
    }
    else if (indexPath.section == 5){
        if (indexPath.row == 0) {
            return self.extraCell;
        }
    }
    else if (indexPath.section == 6){
        if (indexPath.row == 0) {
            return self.buttonCell;
        }
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 90;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return 130;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return 190;
        }
    }
    else if (indexPath.section ==3){
        if (indexPath.row == 0){
            return 44;
        }
        else if (indexPath.row == 1){
            return 44;
        }
        else if (indexPath.row == 2){
            return 44;
        }
        else if (indexPath.row == 3){
            return 44;
        }
        else if (indexPath.row == 4){
            return 44;
        }
        else if (indexPath.row == 5){
            return 44;
        }
    }
    else if (indexPath.section == 4){
        if (indexPath.row == 0) {
            return 44;
        }
    }
    else if (indexPath.section == 5){
        if (indexPath.row == 0) {
            return 104;
        }
    }
    else if (indexPath.section == 6){
        if (indexPath.row == 0) {
            return 142;
        }
    }
    return 100;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 3 || section == 0 || section == 2 || section == 1)
        return 0.0f;
    return 32.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section ==3 || section == 4 || section == 5 || section == 6 || section == 0) {
        return 0.0;
    }
    return 32.0f;
}

@end
