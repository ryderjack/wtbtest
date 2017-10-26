//
//  CheckoutSummary.m
//  wtbtest
//
//  Created by Jack Ryder on 29/09/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "CheckoutSummary.h"
#import "MessageViewController.h"
#import <Crashlytics/Crashlytics.h>
#import "ForSaleListing.h"
#import "NavigationController.h"
#import "ReviewsVC.h"
#import "ChatWithBump.h"
#import "OrderSummaryView.h"
#import <SafariServices/SafariServices.h>

@interface CheckoutSummary ()

@end

@implementation CheckoutSummary

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"C H E C K O U T";
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cancelCross"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.itemTitleLabel.text = [self.listingObject objectForKey:@"itemTitle"];
    
    //format size label correctly
    NSString *sizeLabel = @"";
    
    if ([[self.listingObject objectForKey:@"category"]isEqualToString:@"Accessories"]) {
        sizeLabel = @"Accessory";
    }
    else if ([[self.listingObject objectForKey:@"category"]isEqualToString:@"Tops"] || [[self.listingObject objectForKey:@"category"]isEqualToString:@"Bottoms"] || [[self.listingObject objectForKey:@"category"]isEqualToString:@"Outerwear"]) {
        if ([[self.listingObject objectForKey:@"sizeLabel"] isEqualToString:@"XXL"]){
            sizeLabel = [NSString stringWithFormat:@"XXLarge"];
        }
        else if ([[self.listingObject objectForKey:@"sizeLabel"] isEqualToString:@"XL"]){
            sizeLabel = [NSString stringWithFormat:@"XLarge"];
        }
        else if ([[self.listingObject objectForKey:@"sizeLabel"] isEqualToString:@"L"]){
            sizeLabel = [NSString stringWithFormat:@"Large"];
        }
        else if ([[self.listingObject objectForKey:@"sizeLabel"] isEqualToString:@"M"]){
            sizeLabel = [NSString stringWithFormat:@"Medium"];
        }
        else if ([[self.listingObject objectForKey:@"sizeLabel"] isEqualToString:@"S"]){
            sizeLabel = [NSString stringWithFormat:@"Small"];
        }
        else if ([[self.listingObject objectForKey:@"sizeLabel"] isEqualToString:@"XS"]){
            sizeLabel = [NSString stringWithFormat:@"XSmall"];
        }
        else if ([[self.listingObject objectForKey:@"sizeLabel"] isEqualToString:@"XXS"]){
            sizeLabel = [NSString stringWithFormat:@"XXSmall"];
        }
        else{
            sizeLabel = [NSString stringWithFormat:@"%@",[self.listingObject objectForKey:@"sizeLabel"]];
        }
    }
    else if ([[self.listingObject objectForKey:@"category"]isEqualToString:@"Footwear"]) {
        sizeLabel = [NSString stringWithFormat:@"%@",[self.listingObject objectForKey:@"sizeLabel"]];
    }
    
    self.conditionLabel.text = sizeLabel;
    
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

    self.changeAddressPressed.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    self.paypalLabel.titleLabel.numberOfLines = 0;
    self.paypalLabel.titleLabel.textAlignment = NSTextAlignmentCenter;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (self.successMode && !self.buttonShowing) {
        [self showBarButton];
    }
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dismissVC{
    [self hideBarButton];
    
    if (self.successMode) {
        NSLog(@"call purchased delegate");
        [self.delegate PurchasedItemCheckout];
    }
    else{
        [self.delegate dismissedCheckout];
    }
    
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

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.01;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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

    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
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
                saleOrder[@"status"] = @"live"; //CHANGE

                saleOrder[@"shippingAddress"] = self.addressLabel.text;

                saleOrder[@"salePrice"] = @(self.salePrice);
                saleOrder[@"totalPrice"] = @(self.totalPrice);
                saleOrder[@"currency"] = [self.listingObject objectForKey:@"currency"];
                
                saleOrder[@"salePriceLabel"] = self.itemPriceLabel.text;
                saleOrder[@"shippingPriceLabel"] = self.shippingPriceLabel.text;
                saleOrder[@"totalPriceLabel"] = self.totalPriceLabel.text;
    
                saleOrder[@"itemImage"] = [self.listingObject objectForKey:@"thumbnail"];
                saleOrder[@"itemTitle"] = self.itemTitleLabel.text;
                
                //condition label now shows size
                saleOrder[@"itemSize"] = self.conditionLabel.text;
                saleOrder[@"lastUpdated"] = [NSDate date];
    
                float shippingPrice = self.totalPrice - self.salePrice;
                saleOrder[@"shippingPrice"] = @(shippingPrice);
                saleOrder[@"shipped"] = @"NO";

                saleOrder[@"buyerLeftFeedback"] = @"NO";
                saleOrder[@"sellerLeftFeedback"] = @"NO";
                
                saleOrder[@"sellerUnseen"] = @1;
                saleOrder[@"buyerUnseen"] = @1;

                [saleOrder saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {

                        //mark listing as sold
                        [self.listingObject setObject:@"sold" forKey:@"status"];
                        [self.listingObject setObject:@"YES" forKey:@"purchased"];
                        [self.listingObject setObject:[PFUser currentUser].objectId forKey:@"buyerId"];
                        [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                            if (succeeded) {
                                [self hideHUD];
                                
                                //increment buyer's order number
                                [[PFUser currentUser]incrementKey:@"orderNumber"];
                                [[PFUser currentUser]saveInBackground];
                                
                                //increment seller's order number
//                                NSDictionary *params = @{@"sellerId": self.otherUser.objectId};
//                                [PFCloud callFunctionInBackground:@"incrementOrderNumber" withParameters:params block:^(NSDictionary *response, NSError *error) {
//                                    if (!error) {
//                                        NSLog(@"increment sucessful %@", response);
//                                    }
//                                    else{
//                                        NSLog(@"error incrementing seller's order number %@", error);
//                                    }
//                                }];
                                
//                                NSString *pushString = [NSString stringWithFormat:@"Item Sold: %@ for %@", self.itemTitleLabel.text, self.totalLabel.text];
                                
//                                NSDictionary *params = @{@"userId": self.otherUser.objectId, @"message": pushString, @"sender": [PFUser currentUser].username, @"bumpValue": @"NO", @"listingID": self.orderObject.objectId};
//                                [PFCloud callFunctionInBackground:@"sendNewPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
//                                    if (!error) {
//                                        NSLog(@"response sending sold push %@", response);
//
//                                        [Answers logCustomEventWithName:@"Sent Sold Push"
//                                                       customAttributes:@{
//                                                                          @"success":@"YES"
//                                                                          }];
//                                    }
//                                    else{
//                                        NSLog(@"sold push error %@", error);
//
//                                        [Answers logCustomEventWithName:@"Sent Sold Push"
//                                                       customAttributes:@{
//                                                                          @"success":@"NO",
//                                                                          @"error" : error.description
//                                                                          }];
//                                    }
//                                }];
                                
                                NSLog(@"saved order!");

                                //goto success screen!
                                CheckoutSummary *vc = [[CheckoutSummary alloc]init];
                                vc.successMode = YES;
                                vc.listingObject = self.listingObject;
                                vc.orderObject = saleOrder;
                                vc.delegate = self;
                                
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
    OrderSummaryView *vc = [[OrderSummaryView alloc]init];
    vc.isBuyer = YES;
    vc.orderObject = self.orderObject;
    [self.navigationController pushViewController:vc animated:YES];
    
    [self hideBarButton];
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

#pragma mark - success delegates
-(void)dismissedCheckout{
    [self.delegate dismissedCheckout];
}

-(void)PurchasedItemCheckout{
    //post notification that forces profile tab badge to be recalculated
    [[NSNotificationCenter defaultCenter] postNotificationName:@"orderPlaced" object:nil];
    [self.delegate PurchasedItemCheckout];
}
- (IBAction)paypalFooterPressed:(id)sender {
    SFSafariViewController *paypalSafariView = [[SFSafariViewController alloc]initWithURL:[NSURL URLWithString:@"https://www.paypal.com/gb/webapps/mpp/paypal-safety-and-security"]];
    if (@available(iOS 11.0, *)) {
        paypalSafariView.dismissButtonStyle = UIBarButtonSystemItemCancel;
    }
    paypalSafariView.preferredControlTintColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];

    [self.navigationController presentViewController:paypalSafariView animated:YES completion:nil];
}
@end
