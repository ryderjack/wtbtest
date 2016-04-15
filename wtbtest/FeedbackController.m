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
    
    //reset user cell
    self.userNameLabel.text = @"";
    self.dealsLabel.text = @"";
    
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
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
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
            
            int starNumber = [[self.user objectForKey:@"currentRating"] intValue];
            
            if (starNumber == 0) {
                [self.starView setImage:[UIImage imageNamed:@"0star"]];
            }
            else if (starNumber == 1){
                [self.starView setImage:[UIImage imageNamed:@"1star"]];
            }
            else if (starNumber == 2){
                [self.starView setImage:[UIImage imageNamed:@"2star"]];
            }
            else if (starNumber == 3){
                [self.starView setImage:[UIImage imageNamed:@"3star"]];
            }
            else if (starNumber == 4){
                [self.starView setImage:[UIImage imageNamed:@"4star"]];
            }
            else if (starNumber == 5){
                [self.starView setImage:[UIImage imageNamed:@"5star"]];
            }
            
            int purchased = [[self.user objectForKey:@"purchased"]intValue];
            int sold = [[self.user objectForKey:@"sold"] intValue];
            
            self.dealsLabel.text = [NSString stringWithFormat:@"Purchased: %d\nSold: %d", purchased, sold];
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
    
    [self.feedbackButton setEnabled:NO];
    
    if (self.starNumber == 0 || [self.commentField.text isEqualToString:@""]) {
        self.warningLabel.text = @"Include a rating and a comment";
        [self.feedbackButton setEnabled:YES];
    }
    else{
        PFObject *feedbackObject = [PFObject objectWithClassName:@"feedback"];
        
        [feedbackObject setObject:[NSNumber numberWithInt:self.starNumber] forKey:@"rating"];
        
        if (self.purchased == YES) {
            [feedbackObject setObject:self.user forKey:@"sellerUser"];
            [feedbackObject setObject:[PFUser currentUser] forKey:@"buyerUser"];
        }
        else{
            [feedbackObject setObject:self.user forKey:@"buyerUser"];
            [feedbackObject setObject:[PFUser currentUser] forKey:@"sellerUser"];
        }
        
        [feedbackObject setObject:self.commentField.text forKey:@"comment"];
        [feedbackObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (!error) {
                
                //update order status

                if (self.purchased == YES) {
                    [self.orderObject setObject:[NSNumber numberWithBool:YES] forKey:@"buyerFeedback"];
                }
                else{
                    [self.orderObject setObject:[NSNumber numberWithBool:YES] forKey:@"sellerFeedback"];
                }
                [self.orderObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (!error) {
                        if (self.starNumber == 1) {
                            [self.user incrementKey:@"star1"];
                        }
                        else if (self.starNumber == 2){
                            [self.user incrementKey:@"star2"];
                        }
                        else if (self.starNumber == 3){
                            [self.user incrementKey:@"star3"];
                        }
                        else if (self.starNumber == 4){
                            [self.user incrementKey:@"star4"];
                        }
                        else if (self.starNumber == 5){
                            [self.user incrementKey:@"star5"];
                        }
                        
                        [self.user incrementKey:@"dealsTotal"];
                        
                        if (self.purchased == YES) {
                            [self.user incrementKey:@"sold"];
                        }
                        else{
                            [self.user incrementKey:@"purchased"];
                        }
                        
                        // weight the different stars
                        int star1 = [[self.user objectForKey:@"star1"]intValue]*5;
                        int star2 = [[self.user objectForKey:@"star2"]intValue]*4;
                        int star3 = [[self.user objectForKey:@"star3"]intValue]*3;
                        int star4 = [[self.user objectForKey:@"star4"]intValue]*2;
                        int star5 = [[self.user objectForKey:@"star5"]intValue]*1;
                        
                        NSArray *ratings = [NSArray arrayWithObjects:@(star1), @(star2), @(star3), @(star4), @(star5), nil];
                        int max = [[ratings valueForKeyPath:@"@max.intValue"] intValue];
                        int star = (int) [ratings indexOfObject:@(max)]+1;
                        [self.user setObject:[NSNumber numberWithInt:star] forKey:@"currentRating"];
                        [self.user saveInBackground];
                        
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                    else{
                        NSLog(@"error %@", error);
                        [self.feedbackButton setEnabled:YES];
                    }
                }];
            }
            else{
                NSLog(@"error %@", error);
                [self.feedbackButton setEnabled:YES];
            }
        }];
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
