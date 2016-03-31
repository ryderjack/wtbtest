//
//  FeedbackController.m
//  wtbtest
//
//  Created by Jack Ryder on 24/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "FeedbackController.h"

@interface FeedbackController ()

@end

@implementation FeedbackController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.starNumber = 0;
    self.warningLabel.text = @"";
    
    self.navigationItem.title = @"Leave feedback";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.userCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.starCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    [self setImageBorder];
    self.commentField.delegate= self;
    
    self.user = [[PFUser alloc]init];
    
    if (self.purchased == YES) {
        self.aboutLabel.text = @"About the seller";
    }
    else{
        self.aboutLabel.text = @"About the buyer";
    }
    
    self.user = [[PFUser alloc]init];
    self.user.objectId = self.IDUser;
    [self.user fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            self.userNameLabel.text = self.user.username;
            [self.pictureView setFile:[self.user objectForKey:@"picture"]];
            [self.pictureView loadInBackground];
            
            NSString *purchased = [self.user objectForKey:@"purchased"];
            NSString *sold = [self.user objectForKey:@"sold"];
            
            if (!purchased) {
                purchased = @"0";
            }
            if (!sold) {
                sold = @"0";
            }
            self.dealsLabel.text = [NSString stringWithFormat:@"Purchased: %@\nSold: %@", purchased, sold];
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return 1;
    }
    else if (section == 1){
         return 1;
    }
    else if (section == 2){
        return 1;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.userCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0){
            return self.starCell;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0){
            return self.buttonCell;
        }
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 130;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0){
            return 184;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0){
            return 157;
        }
    }
    
    return 100;
}
- (IBAction)leaveFeedbackPressed:(id)sender {
    if (self.starNumber == 0 || [self.commentField.text isEqualToString:@""]) {
        self.warningLabel.text = @"Include a rating and a comment";
    }
    else{
        //save
    }
}
- (IBAction)reportPressed:(id)sender {
}
- (IBAction)firstStarPressed:(id)sender {
    if (self.firstStar.selected == YES) {
        [self.secondStar setSelected:NO];
        [self.thirdStar setSelected:NO];
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
    else{
        [self.firstStar setSelected:YES];
        self.starNumber = 1;
    }
    [self.secondStar setSelected:NO];
    [self.thirdStar setSelected:NO];
    [self.fourthStar setSelected:NO];
    [self.fifthStar setSelected:NO];
}
- (IBAction)secondStarPressed:(id)sender {
    if (self.secondStar.selected == YES) {
        [self.thirdStar setSelected:NO];
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
    else{
        [self.secondStar setSelected:YES];
        self.starNumber = 2;
        
        [self.firstStar setSelected:YES];
        [self.thirdStar setSelected:NO];
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
}
- (IBAction)thirdStarPressed:(id)sender {
    if (self.thirdStar.selected == YES) {
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
    else{
        [self.thirdStar setSelected:YES];
        self.starNumber = 3;
        
        [self.firstStar setSelected:YES];
        [self.secondStar setSelected:YES];
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
}
- (IBAction)fourthStarPressed:(id)sender {
    if (self.fourthStar.selected == YES) {
        [self.fifthStar setSelected:NO];
    }
    else{
        [self.fourthStar setSelected:YES];
        self.starNumber = 4;
        
        [self.firstStar setSelected:YES];
        [self.secondStar setSelected:YES];
        [self.thirdStar setSelected:YES];
        [self.fifthStar setSelected:NO];
    }
}
- (IBAction)fifthStarPressed:(id)sender {
    if (self.fifthStar.selected == YES) {
    }
    else{
        [self.fifthStar setSelected:YES];
        self.starNumber = 5;
        
        [self.firstStar setSelected:YES];
        [self.secondStar setSelected:YES];
        [self.thirdStar setSelected:YES];
        [self.fourthStar setSelected:YES];
    }
}
-(void)setImageBorder{
    self.pictureView.layer.cornerRadius = self.pictureView.frame.size.width / 2;
    self.pictureView.layer.masksToBounds = YES;
    
    self.pictureView.layer.borderWidth = 1.0f;
    self.pictureView.layer.borderColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1].CGColor;
    
    self.pictureView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.pictureView.contentMode = UIViewContentModeScaleAspectFill;
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0 || section == 1) {
        return 0.0f;
    }
    return 32.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section == 2) {
        return 0.0f;
    }
    return 32.0f;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    
    [headerView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    return headerView;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    
    [footerView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    return footerView;
}
@end
