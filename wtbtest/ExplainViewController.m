//
//  ExplainViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 04/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ExplainViewController.h"

@interface ExplainViewController ()

@end

@implementation ExplainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.gridCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.chatCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.cartCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.firstImageView setImage:[UIImage imageNamed:@"compose"]];
    self.labelOne.text = @"Create a listing for an item you wantobuy";
    self.labelTwo.text = @"Sellers see your listing and send you offers to buy their item ";
    self.labelThree.text = @"You choose to accept/reject offers until you reach a deal and the item is paid for and shipped!";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if(indexPath.row == 0){
            return self.titleCell;
        }
        else if(indexPath.row == 1){
            return self.gridCell;
        }
        else if(indexPath.row == 2){
            return self.chatCell;
        }
        else if(indexPath.row == 3){
            return self.cartCell;
        }
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if(indexPath.row == 0){
            return 107;
        }
        else if(indexPath.row == 1){
            return 190;
        }
        else if(indexPath.row == 2){
            return 190;
        }
        else if(indexPath.row == 3){
            return 190;
        }
    }
    return 190;
}
- (IBAction)segmentPressed:(id)sender {
    if (self.segmentControl.selectedSegmentIndex == 1) {
        //sellers selected
        [self.firstImageView setImage:[UIImage imageNamed:@"grid"]];
        self.labelOne.text = @"Browse through items people wantobuy";
        self.labelTwo.text = @"Spot an item you’re selling? Send the buyer an offer to sell";
        self.labelThree.text = @"You choose to accept/reject offers until you reach a deal and the item is paid for and shipped!";
    }
    else{
        //buyers selected
        [self.firstImageView setImage:[UIImage imageNamed:@"compose"]];
        self.labelOne.text = @"Create a listing for an item you wantobuy";
        self.labelTwo.text = @"Sellers see your listing and send you offers to buy their item ";
        self.labelThree.text = @"You choose to accept/reject offers until you reach a deal and the item is paid for and shipped!";
    }
}
- (IBAction)dismissPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
