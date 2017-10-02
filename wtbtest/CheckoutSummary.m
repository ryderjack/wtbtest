//
//  CheckoutSummary.m
//  wtbtest
//
//  Created by Jack Ryder on 29/09/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "CheckoutSummary.h"
#import "MessageViewController.h"

@interface CheckoutSummary ()

@end

@implementation CheckoutSummary

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.orderSummaryMode) {
        self.title = @"O R D E R";
        
        self.shippedSectionRows = 3;
        
        self.dateFormat = [[NSDateFormatter alloc] init];
        [self.dateFormat setLocale:[NSLocale currentLocale]];

        //don't need to fetch, have all info already - no pointers needed.
        
        //setup listing cell
        self.itemTitleLabel.text = [self.orderObject objectForKey:@"itemTitle"];
        
        [self.itemImageView setFile:[self.orderObject objectForKey:@"itemImage"]];
        [self.itemImageView loadInBackground];
        
        self.firstItemPriceLabel.text = @"";
        
        //setup next steps
        
        //reviews
        if (self.isBuyer) {
            //user is buyer, to do's:
            
            //1. leave feedback
            if ([[self.orderObject objectForKey:@"buyerLeftFeedback"] isEqualToString:@"NO"]) {
                self.leftReviewLabel.text = @"Leave review";
            }
            else{
                self.leftReviewLabel.text = @"Left review";
                [self.leftReviewLabel setTextColor:[UIColor blackColor]];
            }
            
            if ([[self.orderObject objectForKey:@"sellerLeftFeedback"] isEqualToString:@"NO"]) {
                self.gotReviewLabel.text = @"-";
            }
            else{
                self.gotReviewLabel.text = @"View";
            }
        }
        else{
            //user is seller, to do's:
            if ([[self.orderObject objectForKey:@"sellerLeftFeedback"] isEqualToString:@"NO"]) {
                self.leftReviewLabel.text = @"Leave review";
            }
            else{
                self.leftReviewLabel.text = @"Left review";
                [self.leftReviewLabel setTextColor:[UIColor blackColor]];
            }
            
            if ([[self.orderObject objectForKey:@"buyerLeftFeedback"] isEqualToString:@"NO"]) {
                self.gotReviewLabel.text = @"-";
            }
            else{
                self.gotReviewLabel.text = @"View";
            }
        }
        
        //shipping
        if ([[self.orderObject objectForKey:@"shipped"] isEqualToString:@"YES"]) {
//            self.shipped = YES;
//
//            self.shippedSectionRows = 5;
//            [self.tableView reloadData];
            
            [self.dateFormat setDateFormat:@"dd-MMM"];
            NSDate *shippedDate = [self.orderObject objectForKey:@"shippedDate"];
            
            self.shippedLabel.text = [self.dateFormat stringFromDate:shippedDate];
            [self.shippedLabel setTextColor:[UIColor blackColor]];
            
            //show tracking cells - courier and tracking ID
        }
        else if (self.isBuyer != YES){
            self.canShip = YES;
            self.shippedLabel.text = @"Mark as shipped";
        }
        else{
            self.shippedLabel.text = @"Awaiting shipment";
            [self.shippedLabel setTextColor:[UIColor blackColor]];
        }
        
        //setup price cells
        self.totalLabel.text = @"Total Paid";
        self.itemPriceLabel.text = [self.orderObject objectForKey:@"salePriceLabel"];
        self.shippingPriceLabel.text = [self.orderObject objectForKey:@"shippingPriceLabel"];
        self.totalPriceLabel.text = [self.orderObject objectForKey:@"totalPriceLabel"];
        
        self.listingObject = [self.orderObject objectForKey:@"listing"];
        
        [self.dateFormat setDateFormat:@"dd MMM YYYY"];

        if (self.isBuyer) {
            self.messageLabel.text = @"Message Seller";
            self.conditionLabel.text = [NSString stringWithFormat:@"Purchased %@", [self.dateFormat stringFromDate:self.orderObject.createdAt]];
            self.otherUser = [self.orderObject objectForKey:@"sellerUser"];

        }
        else{
            self.messageLabel.text = @"Message Buyer";
            self.conditionLabel.text = [NSString stringWithFormat:@"Sold %@", [self.dateFormat stringFromDate:self.orderObject.createdAt]];
            self.otherUser = [self.orderObject objectForKey:@"buyerUser"];
        }
        
        [self.otherUser fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                self.fetchedUser = YES;
            }
            else{
                NSLog(@"error fetching other user %@", error);
            }
        }];
        
    }
    else{
        self.title = @"C H E C K O U T";
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cancelCross"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        
        self.itemTitleLabel.text = [self.listingObject objectForKey:@"itemTitle"];
        self.conditionLabel.text = [self.listingObject objectForKey:@"condition"];
        
        [self.itemImageView setFile:[self.listingObject objectForKey:@"thumbnail"]];
        [self.itemImageView loadInBackground];
        
        if (self.successMode) {
            //set shipping price & total price
            self.itemPriceLabel.text = self.itemPriceText;
            self.shippingPriceLabel.text = self.shippingText;
            self.totalPriceLabel.text = self.totalPriceText;
        }
        else{
            self.itemPriceLabel.text = [NSString stringWithFormat:@"%@%.2f", self.currencySymbol, self.salePrice];
            
            self.listingCountryCode = [self.listingObject objectForKey:@"countryCode"];
            
            if ([[[PFUser currentUser] objectForKey:@"enteredAddress"]isEqualToString:@"YES"] && [[PFUser currentUser] objectForKey:@"shippingCountryCode"]) {
                self.addAddress = NO;
                
                //now set address label
                self.addressLabel.text = [[PFUser currentUser] objectForKey:@"addressString"];
                
                NSString *countryCode = [[PFUser currentUser] objectForKey:@"shippingCountryCode"];
                
                //now calc shipping based on this address
                float shipping;
                //recalc shipping price & total price based on country
                if ([self.listingCountryCode.lowercaseString isEqualToString:countryCode.lowercaseString]) {
                    //national pricing
                    shipping = [[self.listingObject objectForKey:@"nationalShippingPrice"]floatValue];
                }
                else{
                    //int. pricing
                    shipping = [[self.listingObject objectForKey:@"globalShippingPrice"]floatValue];
                }
                
                self.shippingPriceLabel.text = [NSString stringWithFormat:@"%@%.2f", self.currencySymbol,shipping];
                self.totalPrice = shipping + self.salePrice;
                self.totalPriceLabel.text = [NSString stringWithFormat:@"%@%.2f", self.currencySymbol,self.totalPrice];
                
                //enable pay button
                [self.payButton setEnabled:YES];
                self.payButton.alpha = 1;
            }
            else{
                self.addAddress = YES;
                self.shippingPriceLabel.text = @"-";
                self.totalPriceLabel.text = @"-";
                
                [self.payButton setEnabled:NO];
                self.payButton.alpha = 0.5;
            }
            
            [self.tableView reloadData];
        }
    }

    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    self.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
    self.itemTitleLabel.minimumScaleFactor=0.5;
    
    self.addressCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.addShippingAddressCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.itemPriceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.itemCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.shippingPriceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.totalPriceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.spaceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.footerCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.congratsHeader.selectionStyle = UITableViewCellSelectionStyleNone;
    self.reviewLeftCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.reviewGotCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.shippedCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.messageCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.reportCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.refundCell.selectionStyle = UITableViewCellSelectionStyleNone;


    self.changeAddressPressed.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    self.paypalLabel.titleLabel.numberOfLines = 0;
    self.paypalLabel.titleLabel.textAlignment = NSTextAlignmentCenter;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if (!self.orderSummaryMode) {
        //show pay button but disabled
        if (!self.payButton) {
            self.payButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
            [self.payButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
            
            if (self.successMode) {
                [self.payButton setTitle:@"View Order" forState:UIControlStateNormal];
                [self.payButton setBackgroundColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0]];
                [self.payButton addTarget:self action:@selector(viewOrderPressed) forControlEvents:UIControlEventTouchUpInside];
            }
            else{
                [self.payButton setTitle:@"Pay with PayPal" forState:UIControlStateNormal];
                [self.payButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
                [self.payButton addTarget:self action:@selector(payPressed) forControlEvents:UIControlEventTouchUpInside];
            }
            
            self.payButton.alpha = 0.0f;
            [[UIApplication sharedApplication].keyWindow addSubview:self.payButton];
        }
        
        [self showBarButton];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dismissVC{
    [self hideBarButton];
    [self.delegate dismissedCheckout];
    [self dismissViewControllerAnimated:YES completion:^{
        self.payButton = nil;
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.orderSummaryMode) {
        if (section == 0){
            return 0.01f;
        }
        else{
            return 35.0;
        }
    }
    else{
        if (self.successMode) {
            if (section == 0  || section == 1){
                return 0.01f;
            }
            else{
                return 25.0f;
            }
        }
        else{
            if (self.addAddress) {
                //no gap between 0-1
                if (section == 0 || section == 1){
                    return 0.01f;
                }
                else{
                    return 25.0f;
                }
            }
            else{
                if (section == 0){
                    return 0.01f;
                }
                else{
                    return 25.0f;
                }
            }
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.01;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.orderSummaryMode) {
        if (section == 0){
            return 1;
        }
        else if (section == 1){
            return self.shippedSectionRows;
        }
        else if (section == 2){
            return 3;
        }
        else if (section == 3){
            if (self.isBuyer) {
                return 2;
            }
            else{
                return 3;
            }
        }
        else{
            return 0;
        }
    }
    else{
        if (section == 0){
            return 1;
        }
        else if (section == 1){
            return 1;
        }
        else if (section == 2){
            return 2;
        }
        else if (section == 3){
            if (self.successMode) {
                return 2;
            }
            else{
                return 3;
            }
        }
        else{
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.orderSummaryMode) {
        if (indexPath.section == 0){
            return self.itemCell;
        }
        else if (indexPath.section == 1){
            if (indexPath.row == 0) {
                return self.shippedCell;
            }
            
            if (self.shipped) {
                if (indexPath.row == 1) {
                    return self.trackingCell;
                }
                else if (indexPath.row == 2) {
                    return self.courierCell;
                }
                else if (indexPath.row == 3) {
                    return self.reviewLeftCell;
                }
                else if (indexPath.row == 4) {
                    return self.reviewGotCell;
                }
            }
            else{
                if (indexPath.row == 1) {
                    return self.reviewLeftCell;
                }
                else if (indexPath.row == 2) {
                    return self.reviewGotCell;
                }
            }
        }
        else if (indexPath.section == 2){
            if (indexPath.row == 0) {
                return self.itemPriceCell;
            }
            else if (indexPath.row == 1) {
                return self.shippingPriceCell;
            }
            else if (indexPath.row == 2) {
                return self.totalPriceCell;
            }
        }
        else if (indexPath.section == 3){
            if (self.isBuyer) {
                if (indexPath.row == 0) {
                    return self.messageCell;
                }
                else if (indexPath.row == 1) {
                    return self.reportCell;
                }
            }
            else{
                if (indexPath.row == 0) {
                    return self.messageCell;
                }
                else if (indexPath.row == 1) {
                    return self.refundCell;
                }
                else if (indexPath.row == 2) {
                    return self.reportCell;
                }
            }

        }
    }
    else{
        if (indexPath.section == 0){
            if (self.successMode) {
                return self.congratsHeader;
            }
            else if (self.addAddress) {
                return self.addShippingAddressCell;
            }
            else{
                return self.addressCell;
            }
        }
        else if (indexPath.section == 1){
            return self.itemCell;
        }
        else if (indexPath.section == 2){
            if (indexPath.row == 0) {
                return self.itemPriceCell;
            }
            else{
                return self.shippingPriceCell;
            }
        }
        else if (indexPath.section == 3){
            if (indexPath.row == 0) {
                return self.totalPriceCell;
            }
            
            if (self.successMode) {
                if (indexPath.row == 1) {
                    return self.spaceCell;
                }
            }
            else{
                if (indexPath.row == 1) {
                    return self.footerCell;
                }
                else if (indexPath.row == 2) {
                    return self.spaceCell;
                }
            }
            
        }
    }

    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.orderSummaryMode) {
        
        
        if (indexPath.section == 1) {
            if (indexPath.row == 0) {
                [self markAsShipped];
            }
        }
        
        else if (indexPath.section == 3) {
            if (indexPath.row == 0) {
                [self setupMessages];
            }
            else if (indexPath.row == 1) {
                if (self.isBuyer) {
                    [self reportProblem];
                }
                else{
                    [self refund];
                }
            }
            else if (indexPath.row == 2) {
                [self reportProblem];
            }
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.orderSummaryMode) {
        if (indexPath.section == 0){
            return 87;
        }
        else if (indexPath.section == 1 || indexPath.section == 2){
            return 61;
        }
        else if (indexPath.section == 3){
            return 61;
        }
    }
    else{
        if (indexPath.section == 0){
            if (self.successMode) {
                return 207;
            }
            return 137;
        }
        else if (indexPath.section == 1){
            return 87;
        }
        else if (indexPath.section == 2){
            return 61;
        }
        else if (indexPath.section == 3){
            if (indexPath.row == 0) {
                return 61;
            }
            
            if (self.successMode) {
                if (indexPath.row == 1) {
                    return 60;
                }
            }
            else{
                if (indexPath.row == 1) {
                    return 118;
                }
                else if (indexPath.row == 2) {
                    return 60;
                }
            }
        }
    }

    return 61;

}

-(void)showBarButton{
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.payButton.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                         self.buttonShowing = YES;
                     }];
}

-(void)hideBarButton{
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.payButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                         self.buttonShowing = NO;
                     }];
}

//CHANGE this needs to be a cloud method to avoid timeouts & aid speed
-(void)payPressed{
    
    [self showHUD];
    
    //save order object
    
    //mark listing as sold
    
    //move to success VC
    
    //check status of listing, still available?
    PFQuery *statusQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [statusQuery whereKey:@"objectId" equalTo:self.listingObject.objectId];
    [statusQuery includeKey:@"sellerUser"];
    [statusQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            if ([[object objectForKey:@"status"]isEqualToString:@"live"]) {

                //still available so save order object
                PFObject *saleOrder = [PFObject objectWithClassName:@"saleOrders"];
                saleOrder[@"listing"] = self.listingObject;
                saleOrder[@"buyerUser"] = [PFUser currentUser];
                saleOrder[@"buyerId"] = [PFUser currentUser].objectId;
                
                PFUser *seller = [object objectForKey:@"sellerUser"];
                
                saleOrder[@"sellerId"] = seller.objectId;
                saleOrder[@"sellerUser"] = seller;
                saleOrder[@"status"] = @"pending";

                saleOrder[@"shippingAddress"] = self.addressLabel.text;

                saleOrder[@"salePrice"] = @(self.salePrice);
                saleOrder[@"totalPrice"] = @(self.totalPrice);
                saleOrder[@"currency"] = [self.listingObject objectForKey:@"currency"];
                
                saleOrder[@"salePriceLabel"] = self.itemPriceLabel.text;
                saleOrder[@"shippingPriceLabel"] = self.shippingPriceLabel.text;
                saleOrder[@"totalPriceLabel"] = self.totalPriceLabel.text;
    
                saleOrder[@"itemImage"] = [self.listingObject objectForKey:@"thumbnail"];
                saleOrder[@"itemTitle"] = self.itemTitleLabel.text;
                saleOrder[@"lastUpdated"] = [NSDate date];
    
                float shippingPrice = self.totalPrice - self.salePrice;
                saleOrder[@"shippingPrice"] = @(shippingPrice);
                saleOrder[@"shipped"] = @"NO";

                saleOrder[@"buyerLeftFeedback"] = @"NO";
                saleOrder[@"sellerLeftFeedback"] = @"NO";

                [saleOrder saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {

                        //mark listing as sold
                        [self.listingObject setObject:@"sold" forKey:@"status"];
                        [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                            if (succeeded) {
                                [self hideHUD];
                                
                                [[PFUser currentUser]incrementKey:@"orderNumber"];
                                [[PFUser currentUser]saveInBackground];
                                
                                NSLog(@"saved order!");

                                //goto success screen!
                                CheckoutSummary *vc = [[CheckoutSummary alloc]init];
                                vc.successMode = YES;
                                vc.listingObject = self.listingObject;
                                
                                vc.shippingText  = self.shippingPriceLabel.text;
                                vc.itemPriceText  = self.itemPriceLabel.text;
                                vc.totalPriceText  = self.totalPriceLabel.text;
                                
                                [self.navigationController pushViewController:vc animated:YES];
                                
                                [self hideBarButton];
                                self.payButton = nil;
                            }
                            else{
                                NSLog(@"error saving listing as sold %@",error);
                            }
                        }];
                    }
                    else{
                        NSLog(@"error saving order %@", error);
                    }
                }];
            }
            else{
                NSLog(@"item no longer available");
                return;
            }
        }
        else{
            NSLog(@"error checking listing status %@", error);
        }
    }];
}

- (IBAction)addAddress:(id)sender {
    ShippingController *vc = [[ShippingController alloc]init];
    vc.delegate = self;
    
    [self hideBarButton];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)addedAddress:(NSString *)address withName:(NSString *)name withLineOne:(NSString *)one withLineTwo:(NSString *)two withCity:(NSString *)city withCountry:(NSString *)country fullyEntered:(BOOL)complete{
    if (complete) {
        NSLog(@"done with address");
        float shipping;
        //recalc shipping price & total price based on country
        if ([self.listingCountryCode.lowercaseString isEqualToString:country.lowercaseString]) {
            //national pricing
            shipping = [[self.listingObject objectForKey:@"nationalShippingPrice"]floatValue];
        }
        else{
            //int. pricing
            shipping = [[self.listingObject objectForKey:@"globalShippingPrice"]floatValue];
        }
        
        self.shippingPriceLabel.text = [NSString stringWithFormat:@"%@%.2f", self.currencySymbol,shipping];
        
        self.totalPrice = shipping + self.salePrice;
        self.totalPriceLabel.text = [NSString stringWithFormat:@"%@%.2f", self.currencySymbol,self.totalPrice];
        
        //enable pay button
        [self.payButton setEnabled:YES];
        self.payButton.alpha = 1.0;

        
        //refresh table view to address cell is shown
        self.addAddress = NO;
        
        //update address label
        self.addressLabel.text = address;
        [self.tableView reloadData];
    }
    else{
        NSLog(@"address unfinished");
    }
}

#pragma mark - HUD


-(void)showHUD{
    
    if (!self.spinner) {
        self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    }
    
    [self.spinner startAnimating];
    
    if (!self.hud) {
        self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        self.hud.square = YES;
        self.hud.mode = MBProgressHUDModeCustomView;
        self.hud.customView = self.spinner;
    }

}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.hud = nil;
        self.spinner = nil;
    });
}

-(void)viewOrderPressed{
    
}

#pragma mark - order summary only buttons

-(void)setupMessages{
    if (!self.fetchedUser || self.settingUpMessages) {
        return;
    }
    
    self.settingUpMessages = YES;
    
    [self showHUD];
    
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"convos"];
    
    if (self.isBuyer) {
        [convoQuery whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
        
        [convoQuery whereKey:@"convoId" equalTo: [NSString stringWithFormat:@"%@%@%@",[PFUser currentUser].objectId,self.otherUser.objectId, self.listingObject.objectId]];
    }
    else{
        [convoQuery whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
        
        [convoQuery whereKey:@"convoId" equalTo: [NSString stringWithFormat:@"%@%@%@",self.otherUser.objectId,[PFUser currentUser].objectId, self.listingObject.objectId]];
    }
    
    [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //convo exists, goto that one but pretype a message like "I'm interested in your Supreme bogo" etc.
            MessageViewController *vc = [[MessageViewController alloc]init];
            vc.convoId = [object objectForKey:@"convoId"];
            vc.convoObject = object;
            vc.listing = self.listingObject;
            vc.otherUser = self.otherUser;
            vc.otherUserName = @"";
            
            if (self.isBuyer) {
                vc.userIsBuyer = YES;
            }
            
            vc.pureWTS = YES;
            
            [self hideHUD];
            self.settingUpMessages = NO;

            [self.navigationController pushViewController:vc animated:YES];            
        }
        else{
            NSLog(@"error setting up messages %@", error);
            [self hideHUD];
            self.settingUpMessages = NO;
        }
    }];
}

-(void)refund{
}

-(void)reportProblem{
}

-(void)markAsShipped{
    
    self.shipped = YES;
    self.shippedSectionRows = 5;
    
    NSIndexPath *trackingPath = [NSIndexPath indexPathForRow:1 inSection:1];
    NSIndexPath *courierPath = [NSIndexPath indexPathForRow:2 inSection:1];
    [self.tableView insertRowsAtIndexPaths:@[trackingPath, courierPath] withRowAnimation:UITableViewRowAnimationFade];
    
//    if (self.canShip) {
//        self.canShip = NO;
//        [self showHUD];
//        [self.orderObject setObject:@"YES" forKey:@"shipped"];
//        [self.orderObject setObject:[NSDate date] forKey:@"shippedDate"];
//        [self.orderObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//            if (succeeded) {
//                [self hideHUD];
//
//                //CHANGE send a push to the buyer
//
//                [self.dateFormat setDateFormat:@"dd-MMM"];
//                NSDate *shippedDate = [NSDate date];
//
//                self.shippedLabel.text = [self.dateFormat stringFromDate:shippedDate];
//                [self.shippedLabel setTextColor:[UIColor blackColor]];
//
//                //now show add tracking ID & Courier cells
//                self.shipped = YES;
//                self.shippedSectionRows = 5;
//
//                NSIndexPath *trackingPath = [NSIndexPath indexPathForRow:1 inSection:1];
//                NSIndexPath *courierPath = [NSIndexPath indexPathForRow:2 inSection:1];
//                [self.tableView insertRowsAtIndexPaths:@[trackingPath, courierPath] withRowAnimation:UITableViewRowAnimationFade];
//
//            }
//            else{
//                [self hideHUD];
//                self.canShip = YES;
//                NSLog(@"error marking as shipped");
//            }
//        }];
//    }

}
@end
