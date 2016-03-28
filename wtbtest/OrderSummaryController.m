//
//  OrderSummaryController.m
//  wtbtest
//
//  Created by Jack Ryder on 18/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "OrderSummaryController.h"
#import "FeedbackController.h"

@interface OrderSummaryController ()

@end

@implementation OrderSummaryController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    self.navigationItem.title = @"Order details";
    
    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.imageCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.shippingCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.feeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.checkCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.itempriceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.totalCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.userCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.feeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.deliveryCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.sellerButtons.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
    self.itemTitleLabel.minimumScaleFactor=0.5;
    
    self.userName.adjustsFontSizeToFitWidth = YES;
    self.userName.minimumScaleFactor=0.5;
    
    self.dealsLabel.adjustsFontSizeToFitWidth = YES;
    self.dealsLabel.minimumScaleFactor=0.5;
    
    self.addressLabel.adjustsFontSizeToFitWidth = YES;
    self.addressLabel.minimumScaleFactor=0.5;
    
    self.totalCostLabel.adjustsFontSizeToFitWidth = YES;
    self.totalCostLabel.minimumScaleFactor=0.5;
    
    //setup title cell
    
    self.confirmedOffer = [self.orderObject objectForKey:@"offerObject"];
    
    [self.confirmedOffer fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            self.itemTitleLabel.text = [self.confirmedOffer objectForKey:@"title"];
            self.conditionLabel.text = [NSString stringWithFormat:@"Condition: %@", [self.confirmedOffer objectForKey:@"condition"]];
            
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
    
    //Status key
    // paid = paid
    // paidshipped = paid for and been marked as shipped
    // paidshippedfb = paid, shipped and feedback has been left
    // paidfb = paid, not marked as shipped but feedback has been left
    
    if ([[self.orderObject objectForKey:@"status"]isEqualToString:@"paid"]) {
        [self.titleImageView setImage:[UIImage imageNamed:@"trackingpaid"]];
        [self.shippedButton setSelected:NO];
        //use statusString as a local version of what the key value is to avoid multiple saves. The finally saved on willDisappear
        self.statusString = @"paid";
    }
    else if ([[self.orderObject objectForKey:@"status"]isEqualToString:@"paidshipped"]) {
        [self.titleImageView setImage:[UIImage imageNamed:@"trackingshipped"]];
        [self.shippedButton setSelected:YES];
        self.statusString = @"paidshipped";
    }
    else if ([[self.orderObject objectForKey:@"status"]isEqualToString:@"paidshippedfb"]) {
        [self.titleImageView setImage:[UIImage imageNamed:@"trackingfeedback"]];
        [self.shippedButton setSelected:YES];
        self.statusString = @"paidshippedfb";
    }
    else if ([[self.orderObject objectForKey:@"status"]isEqualToString:@"paidfb"]) {
        [self.titleImageView setImage:[UIImage imageNamed:@"feedbacknotshipped"]];
        [self.shippedButton setSelected:NO];
        self.statusString = @"paidfb";
    }
    
    //setup user cell
    
    [self setImageBorder];
    
    self.otherUser = [[PFUser alloc]init];
    
    if (self.purchased == YES) {
        self.actionLabel.text = @"You purchased:";
        self.otherUser = [self.orderObject objectForKey:@"sellerUser"];
        self.aboutLabel.text = @"About the seller";
    }
    else{
        self.actionLabel.text = @"You sold:";
        self.otherUser = [self.orderObject objectForKey:@"buyerUser"];
        self.aboutLabel.text = @"About the buyer";
        self.totalCostLabel.text = @"Amount received";
    }
    
    [self.otherUser fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            self.userName.text = self.otherUser.username;
            [self.userImageView setFile:[self.otherUser objectForKey:@"picture"]];
            [self.userImageView loadInBackground];
            
            NSString *purchased = [self.otherUser objectForKey:@"purchased"];
            NSString *sold = [self.otherUser objectForKey:@"sold"];
            
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
    
    //setup images cell
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self.explainLabel.text];
    NSRange selectedRange = NSMakeRange(54, 4); // 4 characters, starting at index 22
    
    [string beginEditing];
    [string addAttribute:NSForegroundColorAttributeName
                   value:[UIColor colorWithRed:0.29 green:0.565 blue:0.886 alpha:1]
                   range:selectedRange];
    
    [string endEditing];
    [self.explainLabel setAttributedText:string];
    
    if ([self.confirmedOffer objectForKey:@"image4"]){
        [self.firstImageView setFile:[self.confirmedOffer objectForKey:@"image1"]];
        [self.secondImageView setFile:[self.confirmedOffer objectForKey:@"image2"]];
        [self.thirdImageView setFile:[self.confirmedOffer objectForKey:@"image3"]];
        [self.fourthImageView setFile:[self.confirmedOffer objectForKey:@"image4"]];
    }
    else if ([self.confirmedOffer objectForKey:@"image3"]){
        [self.firstImageView setFile:[self.confirmedOffer objectForKey:@"image1"]];
        [self.secondImageView setFile:[self.confirmedOffer objectForKey:@"image2"]];
        [self.thirdImageView setFile:[self.confirmedOffer objectForKey:@"image3"]];
    }
    
    else if ([self.confirmedOffer objectForKey:@"image2"]) {
        [self.firstImageView setFile:[self.confirmedOffer objectForKey:@"image1"]];
        [self.secondImageView setFile:[self.confirmedOffer objectForKey:@"image2"]];
    }
    else{
        [self.firstImageView setFile:[self.confirmedOffer objectForKey:@"image1"]];
    }
    [self.firstImageView loadInBackground];
    [self.secondImageView loadInBackground];
    [self.thirdImageView loadInBackground];
    [self.fourthImageView loadInBackground];
    
    //shipping cell
    
    PFUser *shippingUser = [[PFUser alloc]init];
    
    if (self.purchased == YES) {
        shippingUser = [PFUser currentUser];
        self.totalLabel.text = [NSString stringWithFormat: @"£%@",[self.orderObject objectForKey:@"buyerTotal"]];
    }
    else{
        shippingUser = self.otherUser;
        self.totalLabel.text = [NSString stringWithFormat: @"£%@",[self.orderObject objectForKey:@"sellerTotal"]];
    }
    
    self.addressLabel.text = [NSString stringWithFormat:@"%@\n%@ %@, %@\n%@\n%@",[shippingUser objectForKey:@"fullname"], [shippingUser objectForKey:@"building"], [shippingUser objectForKey:@"street"], [shippingUser objectForKey:@"city"], [shippingUser objectForKey:@"postcode"], [shippingUser objectForKey:@"phonenumber"]];
    
    //main cells
    
    if ([[self.orderObject objectForKey:@"check"]isEqualToString:@"YES"]) {
        self.checkLabel.text = @"£15.00";
    }
    else{
        self.checkLabel.text = @"-";
    }
    
    self.itemPrice.text = [NSString stringWithFormat: @"£%@",[self.orderObject objectForKey:@"salePrice"]];
    self.deliveryLabel.text = [NSString stringWithFormat: @"£%@",[self.orderObject objectForKey:@"delivery"]];
    self.feeLabel.text = [NSString stringWithFormat: @"£%@",[self.orderObject objectForKey:@"fee"]];
    
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
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return 2;
    }
    else if (section ==1){
        return 1;
    }
    else if (section ==2){
        return 1;
    }
    else if (section ==3){
        if (self.purchased == YES) {
            return 4;
        }
        else{
            return 2;
        }
    }
    else if (section ==4){
        return 1;
    }
    else if (section ==5){
        return 1;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 184;
        }
        else if (indexPath.row == 1){
            return 160;
        }
    }
    else if (indexPath.section ==1){
        return 147;
    }
    else if (indexPath.section ==2){
        return 124;
    }
    else if (indexPath.section ==3 || indexPath.section == 4){
        return 44;
    }
    else if (indexPath.section ==5){
        if (self.purchased == YES) {
            return 299;
        }
        else{
            return 359;
        }
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.titleCell;
        }
        else if (indexPath.row == 1){
            return self.userCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.imageCell;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return self.shippingCell;
        }
    }
    else if (indexPath.section ==3){
        if (indexPath.row == 0){
            return self.itempriceCell;
        }
        else if (indexPath.row == 1){
            return self.deliveryCell;
        }
        else if (indexPath.row == 2){
            return self.feeCell;
        }
        else if (indexPath.row == 3){
            return self.checkCell;
        }
    }
    else if (indexPath.section == 4){
        if (indexPath.row == 0) {
            return self.totalCell;
        }
    }
    else if (indexPath.section == 5){
        if (indexPath.row == 0) {
            if (self.purchased == YES) {
                return self.buttonCell;
            }
            else{
                return self.sellerButtons;
            }
        }
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 2 || section == 0)
        return 0.0f;
    else if (section == 1){
        return 1.0f;
    }
    return 32.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section ==3 || section == 4 || section == 5 || section == 6 || section == 0 || section == 2) {
        return 0.0;
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

-(void)setImageBorder{
    self.userImageView.layer.cornerRadius = self.userImageView.frame.size.width / 2;
    self.userImageView.layer.masksToBounds = YES;
    
    self.userImageView.layer.borderWidth = 1.0f;
    self.userImageView.layer.borderColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1].CGColor;
    
    self.userImageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.userImageView.contentMode = UIViewContentModeScaleAspectFill;
}
- (IBAction)feedbackPressed:(id)sender {
    FeedbackController *vc = [[FeedbackController alloc]init];
    vc.user = self.otherUser;
    vc.purchased = self.purchased;
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)reportPressed:(id)sender {
}
- (IBAction)askPressed:(id)sender {
}
- (IBAction)cancelPressed:(id)sender {
}
- (IBAction)viewogpressed:(id)sender {
}
- (IBAction)markAsShipped:(id)sender {
    if (self.shippedButton.selected == YES) {
        [self.shippedButton setSelected:NO];
        
        if ([self.statusString isEqualToString:@"paidshipped"]) {
            [self.orderObject setObject:@"paid" forKey:@"status"];
            [self.titleImageView setImage:[UIImage imageNamed:@"trackingpaid"]];
            self.statusString = @"paid";
        }
        else if ([self.statusString isEqualToString:@"paidshippedfb"]) {
            [self.orderObject setObject:@"paidfb" forKey:@"status"];
            [self.titleImageView setImage:[UIImage imageNamed:@"feedbacknotshipped"]];
            self.statusString = @"paidfb";
        }
    }
    else{
        [self.shippedButton setSelected:YES];
        [self.titleImageView setImage:[UIImage imageNamed:@"trackingshipped"]];
        [self.orderObject setObject:@"paidshipped" forKey:@"status"];
        self.statusString = @"paidshipped";
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.orderObject saveInBackground];
}
@end
