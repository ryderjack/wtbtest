//
//  OrderSummaryController.m
//  wtbtest
//
//  Created by Jack Ryder on 18/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "OrderSummaryController.h"
#import "FeedbackController.h"
#import "MessageViewController.h"
#import "UserProfileController.h"

@interface OrderSummaryController ()

@end

@implementation OrderSummaryController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    self.navigationItem.title = @"Order details";
    
    [self.checkImageView setHidden:YES];
    
    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.simpleImagesCell.selectionStyle = UITableViewCellSelectionStyleNone;
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
    self.dateLabel.adjustsFontSizeToFitWidth = YES;
    self.dateLabel.minimumScaleFactor=0.5;
    
    self.userName.text = @"";
    self.dealsLabel.text = @"Loading";
    
    if (self.fromMessage == YES) {
        UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
        self.navigationItem.leftBarButtonItem = dismissButton;
    }
    
    //fetch offer to setup title cell/totals/images
    self.confirmedOffer = [self.orderObject objectForKey:@"offerObject"];
    [self.confirmedOffer fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            self.itemTitleLabel.text = [self.confirmedOffer objectForKey:@"title"];
            self.conditionLabel.text = [NSString stringWithFormat:@"Condition: %@", [self.confirmedOffer objectForKey:@"condition"]];
            
            //setup currency
            self.currency = [self.confirmedOffer objectForKey:@"currency"];

            if ([self.currency isEqualToString:@"GBP"]) {
                self.currencySymbol = @"£";
            }
            else if ([self.currency isEqualToString:@"EUR"]) {
                self.currencySymbol = @"€";
            }
            else if ([self.currency isEqualToString:@"USD"]) {
                self.currencySymbol = @"$";
            }
            
            self.itemPrice.text = [NSString stringWithFormat: @"%@ %@%.2f", self.currency, self.currencySymbol ,[[self.confirmedOffer objectForKey:@"salePrice"]floatValue]];
            self.totalLabel.text = self.itemPrice.text;

            //setup order image
            if ([self.confirmedOffer objectForKey:@"image"]) {
                [self.firstImageView setFile:[self.confirmedOffer objectForKey:@"image"]];
                [self.firstImageView loadInBackground];
                self.numberOfPics = 1;
            }
            else{
                //if no images been sent
               [self.firstCam setEnabled:NO];
            }
            
            [self.secondCam setEnabled:NO];
            [self.thirdCam setEnabled:NO];
            [self.fourthCam setEnabled:NO];
            
            // set purchase date
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setLocale:[NSLocale currentLocale]];
            [dateFormatter setDateFormat:@"dd MMM YY"];
            self.dateLabel.text = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:self.orderDate]];
            dateFormatter = nil;
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
    
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
    
    PFUser *shippingUser = [[PFUser alloc]init];
    
    if (self.purchased == YES) {
        shippingUser = [PFUser currentUser];
        //could put different prices in here RE buyer price vs seller price
        
        self.addressLabel.text = [NSString stringWithFormat:@"%@\n%@ %@, %@\n%@\n%@\n%@",[shippingUser objectForKey:@"fullname"], [shippingUser objectForKey:@"building"], [shippingUser objectForKey:@"street"], [shippingUser objectForKey:@"city"], [shippingUser objectForKey:@"postcode"], [shippingUser objectForKey:@"country"],[shippingUser objectForKey:@"phonenumber"]];
    }
    else{
        shippingUser = self.otherUser;
    }
        
    [self.otherUser fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            self.userName.text = self.otherUser.username;
            [self.userImageView setFile:[self.otherUser objectForKey:@"picture"]];
            [self.userImageView loadInBackground];
            
            if ([[self.otherUser objectForKey:@"trustedSeller"] isEqualToString:@"YES"]) {
                [self.checkImageView setHidden:NO];
            }
            else{
                [self.checkImageView setHidden:YES];
            }
            
            PFQuery *dealsQuery = [PFQuery queryWithClassName:@"deals"];
            [dealsQuery whereKey:@"User" equalTo:self.otherUser];
            [dealsQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    int starNumber = [[object objectForKey:@"currentRating"] intValue];
                    
                    if (starNumber == 0) {
                        [self.starsImgView setImage:[UIImage imageNamed:@"0star"]];
                    }
                    else if (starNumber == 1){
                        [self.starsImgView setImage:[UIImage imageNamed:@"1star"]];
                    }
                    else if (starNumber == 2){
                        [self.starsImgView setImage:[UIImage imageNamed:@"2star"]];
                    }
                    else if (starNumber == 3){
                        [self.starsImgView setImage:[UIImage imageNamed:@"3star"]];
                    }
                    else if (starNumber == 4){
                        [self.starsImgView setImage:[UIImage imageNamed:@"4star"]];
                    }
                    else if (starNumber == 5){
                        [self.starsImgView setImage:[UIImage imageNamed:@"5star"]];
                    }
                    
                    int purchased = [[object objectForKey:@"purchased"]intValue];
                    int sold = [[object objectForKey:@"sold"] intValue];
                    
                    self.dealsLabel.text = [NSString stringWithFormat:@"Purchased: %d\nSold: %d", purchased, sold];
                }
                else{
                    NSLog(@"error getting deals data!");
                }
            }];
            
            if (self.purchased == NO) {
                //address
                self.addressLabel.text = [NSString stringWithFormat:@"%@\n%@ %@, %@\n%@\n%@\n%@",[shippingUser objectForKey:@"fullname"], [shippingUser objectForKey:@"building"], [shippingUser objectForKey:@"street"], [shippingUser objectForKey:@"city"], [shippingUser objectForKey:@"postcode"],[shippingUser objectForKey:@"country"],[shippingUser objectForKey:@"phonenumber"]];
            }
        }
            
        else{
            NSLog(@"error %@", error);
        }
    }];
    
    // create detail vc for use with camera buttons
    self.detailController = [[DetailImageController alloc]init];
    self.detailController.listingPic = NO;

//    if ([self.confirmedOffer objectForKey:@"image4"]){
//        self.numberOfPics = 4;
//        [self.firstImageView setFile:[self.confirmedOffer objectForKey:@"image1"]];
//        [self.secondImageView setFile:[self.confirmedOffer objectForKey:@"image2"]];
//        [self.thirdImageView setFile:[self.confirmedOffer objectForKey:@"image3"]];
//        [self.fourthImageView setFile:[self.confirmedOffer objectForKey:@"image4"]];
//    }
//    else if ([self.confirmedOffer objectForKey:@"image3"]){
//        self.numberOfPics = 3;
//        [self.fourthCam setEnabled:NO];
//        
//        [self.firstImageView setFile:[self.confirmedOffer objectForKey:@"image1"]];
//        [self.secondImageView setFile:[self.confirmedOffer objectForKey:@"image2"]];
//        [self.thirdImageView setFile:[self.confirmedOffer objectForKey:@"image3"]];
//    }
//    
//    else if ([self.confirmedOffer objectForKey:@"image2"]) {
//        self.numberOfPics = 2;
//        [self.thirdCam setEnabled:NO];
//        [self.fourthCam setEnabled:NO];
//        
//        [self.firstImageView setFile:[self.confirmedOffer objectForKey:@"image1"]];
//        [self.secondImageView setFile:[self.confirmedOffer objectForKey:@"image2"]];
//    }
//    else{
//        self.numberOfPics = 1;
//        [self.secondCam setEnabled:NO];
//        [self.thirdCam setEnabled:NO];
//        [self.fourthCam setEnabled:NO];
//        
//        [self.firstImageView setFile:[self.confirmedOffer objectForKey:@"image"]];
//    }
    
//    [self.secondImageView loadInBackground];
//    [self.thirdImageView loadInBackground];
//    [self.fourthImageView loadInBackground];
    
    //main cells
    
//    if ([[self.orderObject objectForKey:@"check"]isEqualToString:@"YES"]) {
//        self.checkLabel.text = @"£15.00";
//    }
//    else{
//        self.checkLabel.text = @"-";
//    }
    
//    self.deliveryLabel.text = [NSString stringWithFormat: @"£%.2f",[[self.orderObject objectForKey:@"delivery"]floatValue]];
//    self.feeLabel.text = [NSString stringWithFormat: @"£%.2f",[[self.orderObject objectForKey:@"fee"]floatValue]];
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
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return 2;
    }
    else if (section ==1){
        return 1;
    }
    else if (section ==2){
        return 2;
    }
    else if (section ==3){
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
            if (self.purchased == YES) {
                return 119;
            }
            else{
                return 179;
            }
        }
    }
//    else if (indexPath.section ==1){
//        return 104;
//    }
    else if (indexPath.section ==1){
        return 124;
    }
    else if (indexPath.section ==2){
        return 44;
    }
    else if (indexPath.section ==3){
        return 160;
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
            if (self.purchased == YES) {
                return self.buttonCell;
            }
            else{
                return self.sellerButtons;
            }
        }
    }
//    else if (indexPath.section == 1){
//        if (indexPath.row == 0) {
//            return self.simpleImagesCell;
//        }
//    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.shippingCell;
        }
    }
    else if (indexPath.section ==2){
        if (indexPath.row == 0){
            return self.itempriceCell;
        }
        else if (indexPath.row == 1){
            return self.totalCell;
        }
    }
    else if (indexPath.section == 3){
        if (indexPath.row == 0) {
            return self.userCell;
        }
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 2 || section == 0 || section == 3)
        return 0.0f;
    else if (section == 1){
        return 1.0f;
    }
    return 32.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section ==3 || section == 4 || section == 5 || section == 2) {
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
    self.userImageView.layer.cornerRadius = 25;
    self.userImageView.layer.masksToBounds = YES;
    self.userImageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.userImageView.contentMode = UIViewContentModeScaleAspectFill;
}
- (IBAction)feedbackPressed:(id)sender {
    FeedbackController *vc = [[FeedbackController alloc]init];
    vc.IDUser = self.otherUser.objectId;
    vc.purchased = self.purchased;
    vc.orderObject = self.orderObject;
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)reportPressed:(id)sender {
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Report" message:@"Bump takes inappropriate behaviour very seriously.\nIf you feel like this transaction has violated our terms let us know so we can make your experience on Bump as brilliant as possible. Call +447590554897 if you'd like to speak to one of the team immediately." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        PFObject *reportObject = [PFObject objectWithClassName:@"Reported"];
        reportObject[@"reportedUser"] = self.otherUser;
        reportObject[@"reporter"] = [PFUser currentUser];
        reportObject[@"order"] = self.orderObject;
        reportObject[@"offer"] = self.confirmedOffer;
        [reportObject saveInBackground];
    }]];
    
    [self presentViewController:alertView animated:YES completion:nil];
}
- (IBAction)chatPressed:(id)sender {
    [self.chatButton setEnabled:NO];
    [self.sellerChatButton setEnabled:NO];
    
    MessageViewController *vc = [[MessageViewController alloc]init];
    PFObject *convoObject = [self.confirmedOffer objectForKey:@"convo"];
    [convoObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (!error) {
            vc.convoId = [convoObject objectForKey:@"convoId"];
            vc.convoObject = convoObject;
            
            if ([[convoObject objectForKey:@"pureWTS"]isEqualToString:@"YES"]) {
                //no WTB
                vc.pureWTS = YES;
            }
            else{
                vc.listing = [self.confirmedOffer objectForKey:@"wtbListing"];
            }
            if (self.purchased == YES) {
                //other user is seller, current is buyer
                vc.otherUser = [PFUser currentUser];
            }
            else{
                //other is buyer, current is seller
                vc.otherUser = self.otherUser;
            }
            vc.otherUserName = self.otherUser.username;
            [self.chatButton setEnabled:YES];
            [self.sellerChatButton setEnabled:YES];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            NSLog(@"error fetching convo %@", error);
            [self.chatButton setEnabled:YES];
            [self.sellerChatButton setEnabled:YES];
        }
    }];
}

- (IBAction)markAsShipped:(id)sender {
    if (self.shippedButton.selected == YES) {
       
        [self.shippedButton setSelected:NO];
        [self.orderObject setObject:[NSNumber numberWithBool:NO] forKey:@"shipped"];
        [self setUpTitle];
    }
    else{
        [self.shippedButton setSelected:YES];
        [self.orderObject setObject:[NSNumber numberWithBool:YES] forKey:@"shipped"];
        [self setUpTitle];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.orderObject saveInBackground];
}

-(void)viewWillAppear:(BOOL)animated{
    [self setUpTitle];
}
- (IBAction)firstCamPressed:(id)sender {
    [self presentDetailImage];
}
- (IBAction)secondCamPressed:(id)sender {
    [self presentDetailImage];
}
- (IBAction)thirdCamPressed:(id)sender {
    [self presentDetailImage];
}
- (IBAction)fourthCamPressed:(id)sender {
    [self presentDetailImage];
}

-(void)presentDetailImage{
    if (self.numberOfPics == 1) {
        self.detailController.numberOfPics = 1;
        self.detailController.listing = [self.orderObject objectForKey:@"offerObject"];
        self.detailController.offerMode = YES;
    }
//    else if (self.numberOfPics == 2){
//        self.detailController.numberOfPics = 2;
//        self.detailController.listing = [self.orderObject objectForKey:@"offerObject"];
//    }
//    else if (self.numberOfPics == 3){
//        self.detailController.numberOfPics = 3;
//        self.detailController.listing = [self.orderObject objectForKey:@"offerObject"];
//    }
//    else if (self.numberOfPics == 4){
//        self.detailController.numberOfPics = 4;
//        self.detailController.listing = [self.orderObject objectForKey:@"offerObject"];
//    }
    self.detailController.tagText = [self.orderObject objectForKey:@"tagString"];
    
    [self presentViewController:self.detailController animated:YES completion:nil];
}

-(void)setUpTitle{
    if (self.purchased == YES) {
        //user is the buyer
        
        if ([[self.orderObject objectForKey:@"paid"]boolValue] == YES && [[self.orderObject objectForKey:@"shipped"]boolValue] == YES && [[self.orderObject objectForKey:@"buyerFeedback"]boolValue] == YES) {
            
            // all status points done!
            
            [self.titleImageView setImage:[UIImage imageNamed:@"trackingfeedback"]];
            [self.shippedButton setSelected:YES];
            
            [self.otherFeedbackButton setImage:[UIImage imageNamed:@"leftFbButton"] forState:UIControlStateNormal];
            [self.otherFeedbackButton setEnabled:NO];
        }
        else if ([[self.orderObject objectForKey:@"paid"]boolValue] == YES && [[self.orderObject objectForKey:@"shipped"]boolValue] == YES && [[self.orderObject objectForKey:@"buyerFeedback"]boolValue] == NO){
            
            // only feedback left
            
            NSLog(@"need to leave feedback");
            
            [self.titleImageView setImage:[UIImage imageNamed:@"trackingshipped"]];
            [self.shippedButton setSelected:YES];
        }
        else if ([[self.orderObject objectForKey:@"paid"]boolValue] == YES && [[self.orderObject objectForKey:@"shipped"]boolValue] == NO && [[self.orderObject objectForKey:@"buyerFeedback"]boolValue] == YES){
            
            // still needs to be shipped
            
            [self.titleImageView setImage:[UIImage imageNamed:@"feedbacknotshipped"]];
            [self.shippedButton setSelected:NO];
            self.statusString = @"paidfb";
            
            [self.otherFeedbackButton setImage:[UIImage imageNamed:@"leftFbButton"] forState:UIControlStateNormal];
            [self.otherFeedbackButton setEnabled:NO];
            
        }
        else if ([[self.orderObject objectForKey:@"paid"]boolValue] == YES && [[self.orderObject objectForKey:@"shipped"]boolValue] == NO && [[self.orderObject objectForKey:@"buyerFeedback"]boolValue] == NO){
            
            // only paid
            
            NSLog(@"need to leave feedback and needs to be shipped");
            
            [self.titleImageView setImage:[UIImage imageNamed:@"trackingpaid"]];
            [self.shippedButton setSelected:NO];
        }
    }
    else{
        //user is the seller
        
        if ([[self.orderObject objectForKey:@"paid"]boolValue] == YES && [[self.orderObject objectForKey:@"shipped"]boolValue] == YES && [[self.orderObject objectForKey:@"sellerFeedback"]boolValue] == YES) {
            
            // all status points done!
            
            NSLog(@"done! for seller");

            [self.titleImageView setImage:[UIImage imageNamed:@"trackingfeedback"]];
            [self.shippedButton setSelected:YES];
            
            [self.feedbackButton setImage:[UIImage imageNamed:@"leftFbButton"] forState:UIControlStateNormal];
            [self.feedbackButton setEnabled:NO];
        }
        else if ([[self.orderObject objectForKey:@"paid"]boolValue] == YES && [[self.orderObject objectForKey:@"shipped"]boolValue] == YES && [[self.orderObject objectForKey:@"sellerFeedback"]boolValue] == NO){
            
            // only feedback left
            
            NSLog(@"need to leave feedback");
            
            [self.titleImageView setImage:[UIImage imageNamed:@"trackingshipped"]];
            [self.shippedButton setSelected:YES];
        }
        else if ([[self.orderObject objectForKey:@"paid"]boolValue] == YES && [[self.orderObject objectForKey:@"shipped"]boolValue] == NO && [[self.orderObject objectForKey:@"sellerFeedback"]boolValue] == YES){
            
            // still needs to be shipped
            
            [self.titleImageView setImage:[UIImage imageNamed:@"feedbacknotshipped"]];
            [self.shippedButton setSelected:NO];
            
            [self.feedbackButton setImage:[UIImage imageNamed:@"leftFbButton"] forState:UIControlStateNormal];
            [self.feedbackButton setEnabled:NO];
            
        }
        else if ([[self.orderObject objectForKey:@"paid"]boolValue] == YES && [[self.orderObject objectForKey:@"shipped"]boolValue] == NO && [[self.orderObject objectForKey:@"sellerFeedback"]boolValue] == NO){
            
            // only paid
            
            NSLog(@"need to leave feedback and needs to be shipped");
            
            [self.titleImageView setImage:[UIImage imageNamed:@"trackingpaid"]];
            [self.shippedButton setSelected:NO];
        }
    }
}
- (IBAction)buyerPressed:(id)sender {
    UserProfileController *vc = [[UserProfileController alloc]init];
    vc.user = self.otherUser;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)dismissVC{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
