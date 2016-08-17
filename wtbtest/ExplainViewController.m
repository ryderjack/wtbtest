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
    
    self.labelOne.adjustsFontSizeToFitWidth = YES;
    self.labelOne.minimumScaleFactor=0.5;
    
    self.labelTwo.adjustsFontSizeToFitWidth = YES;
    self.labelTwo.minimumScaleFactor=0.5;
    
    self.labelThree.adjustsFontSizeToFitWidth = YES;
    self.labelThree.minimumScaleFactor=0.5;
    
    self.titleLabel.text = @"How does Bump work?";
    [self.segmentControl setHidden:NO];
    [self.firstImageView setImage:[UIImage imageNamed:@"compose"]];
    [self.secondImageView setImage:[UIImage imageNamed:@"chat"]];
    [self.thirdImageView setImage:[UIImage imageNamed:@"cart"]];
    
    self.labelOne.text = @"Create a listing for an item you want";
    self.labelTwo.text = @"Sellers see your listing and send you offers to buy their item ";
    self.labelThree.text = @"Choose to accept/reject offers until you reach a deal, pay and its shipped!";
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
            self.labelOne.text = @"Browse through items people are looking to purchase";
            self.labelTwo.text = @"Spot an item you’re selling? Send the buyer an offer to buy your item";
            self.labelThree.text = @"Chat until you reach a deal, receive payment and then ship!";
        }
        else{
            //buyers selected
            [self.firstImageView setImage:[UIImage imageNamed:@"compose"]];
            self.labelOne.text = @"Create a listing for an item you want";
            self.labelTwo.text = @"Sellers see your listing and send you offers to buy their item";
            self.labelThree.text = @"Accept your ideal offer, pay and its shipped!";
        }
}
- (IBAction)dismissPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
