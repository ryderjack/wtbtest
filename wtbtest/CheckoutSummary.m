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
#import "Mixpanel/Mixpanel.h"
#import <Intercom/Intercom.h>

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
                self.isNational = YES;
                shipping = [[self.listingObject objectForKey:@"nationalShippingPrice"]floatValue];
            }
            else{
                //int. pricing
                shipping = [[self.listingObject objectForKey:@"globalShippingPrice"]floatValue];
            }
            
            self.shippingPriceLabel.text = [NSString stringWithFormat:@"%@%.2f", self.currencySymbol,shipping];
            self.totalPrice = shipping + self.salePrice;
            self.totalPriceLabel.text = [NSString stringWithFormat:@"%@ %@%.2f", self.currency,self.currencySymbol,self.totalPrice];
            
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
    
    //check item is still available
    if (!self.successMode) {
        PFQuery *statusQuery = [PFQuery queryWithClassName:@"forSaleItems"];
        [statusQuery whereKey:@"objectId" equalTo:self.listingObject.objectId];
        [statusQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                if (![[object objectForKey:@"status"]isEqualToString:@"live"]) {
                    self.sellerErrorShowing = YES;
                    
                    [Answers logCustomEventWithName:@"PayPal Error"
                                   customAttributes:@{
                                                      @"type":@"item no longer available"
                                                      }];
                    
                    [self showAlertWithTitle:@"Item Unavailable" andMsg:@"This item is no longer available, it may have already been purchased or the seller may have removed it from sale"];
                }
            }
            else{
                NSLog(@"error checking checkout item's status");
            }
        }];
    }
    
    if (self.successMode && !self.buttonShowing) {
        [self showBarButton];
    }
    else if(!self.successMode && !self.checkedSellersPPInfo){
        //check if seller's email address is confirmed, if not buyer's payment will be cancelled anyway
        [self getSellersPPAccountStatus];
    }
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    //show pay button but disabled
    if (!self.payButton) {
        self.payButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
        [self.payButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
        
        if (self.successMode) {
            [self.payButton setTitle:@"D I S M I S S" forState:UIControlStateNormal];
            [self.payButton setBackgroundColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0]];
            [self.payButton addTarget:self action:@selector(dismissVC) forControlEvents:UIControlEventTouchUpInside];
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

-(void)payPressed{
    self.paypalOrderId = @"";
    
    if (self.addAddress == YES) {
        [self showAlertWithTitle:@"Shipping Address" andMsg:@"Make sure to add your full shipping address"];
        return;
    }
    
    //tracking
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"tapped_pay_checkout" properties:@{}];
    
    NSString *shippingPrice = [self.shippingPriceLabel.text stringByReplacingOccurrencesOfString:self.currencySymbol withString:@""];
    NSLog(@"%@", shippingPrice);

    NSString *itemPrice = [self.itemPriceLabel.text stringByReplacingOccurrencesOfString:self.currencySymbol withString:@""];
    NSLog(@"%@", itemPrice);

    NSString *totalPrice = [[self.totalPriceLabel.text stringByReplacingOccurrencesOfString:self.currencySymbol withString:@""]stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@ ",self.currency] withString:@""];
    NSLog(@"%@", totalPrice);

    NSString *sellerId = [self.listingObject objectForKey:@"paypalMerchantId"];
    NSLog(@"%@", sellerId);

    NSString *itemTitle = self.itemTitleLabel.text;
    NSLog(@"%@", itemTitle);

    NSString *itemId = self.listingObject.objectId;
    NSLog(@"%@", itemId);

    NSString *currency = [self.listingObject objectForKey:@"currency"];
    NSLog(@"%@", currency);


    NSString *buyerName = [NSString stringWithFormat:@"%@",[[PFUser currentUser] objectForKey:@"fullname"]];;
    NSLog(@"%@", buyerName);

    NSString *lineOne = [NSString stringWithFormat:@"%@",[[PFUser currentUser] objectForKey:@"lineOne"]];
    NSLog(@"%@", lineOne);

    NSString *lineTwo = [NSString stringWithFormat:@"%@",[[PFUser currentUser] objectForKey:@"lineTwo"]];;
    NSLog(@"%@", lineTwo);

    NSString *city = [NSString stringWithFormat:@"%@",[[PFUser currentUser] objectForKey:@"city"]];
    NSLog(@"%@", city);

    NSString *countryCode = [NSString stringWithFormat:@"%@",[[PFUser currentUser] objectForKey:@"shippingCountryCode"]];
    NSLog(@"%@", countryCode);

    NSString *postCode = [NSString stringWithFormat:@"%@",[[PFUser currentUser] objectForKey:@"postcode"]];;
    NSLog(@"%@", postCode);


    //potentially use params here to pass this user's ID for tracking
    [self showHUD];
    NSLog(@"adding in params");
    
    NSDictionary *params = @{
                             @"shippingPrice":shippingPrice,
                             @"itemPrice":itemPrice,
                             @"totalPrice":totalPrice,
                             
                             @"sellerId":sellerId,
                             @"itemTitle": itemTitle,
                             @"itemId":itemId,
                             @"currency":currency,
                             
                             @"buyerName":buyerName,
                             @"lineOne":lineOne,
                             @"lineTwo":lineTwo,
                             @"city":city,
                             @"countryCode":countryCode,
                             @"postCode":postCode
                         };
    
    [PFCloud callFunctionInBackground:@"createPPOrder" withParameters:params block:^(NSDictionary *response, NSError *error) {
        if (!error) {
            [self hideHUD];
            
            NSLog(@"response: %@", response);
            
            if (![response valueForKey:@"orderId"] || ![response valueForKey:@"actionURL"]) {
                [self showAlertWithTitle:@"PayPal Error #800" andMsg:@"Please try again, if the error persists send us an email hello@sobump.com"];
                [Answers logCustomEventWithName:@"PayPal Error"
                               customAttributes:@{
                                                  @"type":@"no orderId or action url in create pp order"
                                                  }];
                return;
            }
            
            self.paypalOrderId = [response valueForKey:@"orderId"];
            NSString *urlString = [response valueForKey:@"actionURL"];
            
            urlString = [urlString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            NSLog(@"URL: %@", urlString);
            
            if (!self.addedPayPalObservers) {
                self.addedPayPalObservers = YES;
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createOrder) name:@"paypalCreatedOrderSuccess" object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createOrderFailed) name:@"paypalCreatedOrderFailed" object:nil];
            }
            self.paypalSafariView = nil;
            
            //trigger PayPal sign in to check order
            self.paypalSafariView = [[SFSafariViewController alloc]initWithURL:[NSURL URLWithString:urlString]];
            if (@available(iOS 11.0, *)) {
                self.paypalSafariView.dismissButtonStyle = UIBarButtonSystemItemCancel;
            }
            
            if (@available(iOS 10.0, *)) {
                self.paypalSafariView.preferredControlTintColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
            }
            
            [self.navigationController presentViewController:self.paypalSafariView animated:YES completion:nil];
        }
        else{
            [self hideHUD];
            NSLog(@"error grabbing paypal order link %@", error);
            [self showAlertWithTitle:@"PayPal Error #801" andMsg:@"Please try again, if the error persists send us an email hello@sobump.com"];
            [Answers logCustomEventWithName:@"PayPal Error"
                           customAttributes:@{
                                              @"type":@"Couldn't grab order link"
                                              }];
            return;
        }
    }];
}

-(void)createOrderFailed{
    NSLog(@"didn't authenticate order");
    [Answers logCustomEventWithName:@"Cancelled Order"
                   customAttributes:@{}];
    
    [self removePPObservers];
    [self.paypalSafariView dismissViewControllerAnimated:YES completion:nil];
}

-(void)removePPObservers{
    self.addedPayPalObservers = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"paypalCreatedOrderSuccess" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"paypalCreatedOrderFailed" object:nil];
}

-(void)createOrder{
    [self removePPObservers];
    [self.paypalSafariView dismissViewControllerAnimated:YES completion:nil];

    [Answers logCustomEventWithName:@"Create Order Called"
                   customAttributes:@{}];
    
    [self showHUD];
    
    NSLog(@"adding in params for create bump order %@", self.otherUser.objectId);
    
    float shippingPrice = self.totalPrice - self.salePrice;
    
    NSDictionary *params = @{
                             @"listingId":self.listingObject.objectId,
                             @"paypalOrderId":self.paypalOrderId,
                             @"merchantId" : [self.listingObject objectForKey:@"paypalMerchantId"],
                             
                             @"buyerId":[PFUser currentUser].objectId,

                             @"shippingAddress":self.addressLabel.text,
                             
                             @"salePrice":@(self.salePrice),
                             @"totalPrice":@(self.totalPrice),
                             @"shippingPrice":@(shippingPrice),
                             
                             @"salePriceLabel":self.itemPriceLabel.text,
                             @"shippingPriceLabel":self.shippingPriceLabel.text,
                             @"totalPriceLabel":self.totalPriceLabel.text,
                             
                             @"itemTitle":self.itemTitleLabel.text,
                             @"itemSize":self.conditionLabel.text,
                             
                             @"invoiceId":[NSString stringWithFormat:@"invoice_%@",self.listingObject.objectId],
                             @"currency" : self.currency
                             };
    
    [PFCloud callFunctionInBackground:@"createBUMPOrder" withParameters:params block:^(NSString *orderId, NSError *error) {
        if (!error) {
            NSLog(@"order creation success for orderId: %@", orderId);
            
            orderId = [orderId stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            
            PFObject *order = [PFObject objectWithoutDataWithClassName:@"saleOrders" objectId:orderId];
            [order fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    
                    [self hideHUD];
                    
                    NSString *priceStr = [NSString stringWithFormat:@"%.2f",self.totalPrice];
                    
                    if (priceStr != nil && self.currency) {
                        [Answers logPurchaseWithPrice:[NSDecimalNumber decimalNumberWithString:priceStr]
                                             currency:self.currency
                                              success:@YES
                                             itemName:self.itemTitleLabel.text
                                             itemType:@""
                                               itemId:self.listingObject.objectId
                                     customAttributes:@{
                                                        @"orderId":orderId
                                                        }];
                    }
                    
                    NSString *category = @"";
                    category = [self.listingObject objectForKey:@"category"];
                    
                    Mixpanel *mixpanel = [Mixpanel sharedInstance];
                    [mixpanel track:@"purchased_item" properties:@{
                                                                      @"categpry":category,
                                                                      @"totalPrice":@(self.totalPrice),
                                                                      @"currency":self.currency,
                                                                      @"nationalShipping": [NSNumber numberWithBool:self.isNational],
                                                                      @"itemId":self.listingObject.objectId,
                                                                      @"invoiceId":[NSString stringWithFormat:@"invoice_%@",self.listingObject.objectId]
                                                                      }];
//                    [mixpanel.people trackCharge:@(self.totalPrice)];
                    
                    [Intercom logEventWithName:@"order_placed" metaData: @{
                                                                             @"category":category,
                                                                             @"totalPrice":@(self.totalPrice),
                                                                             @"currency":self.currency,
                                                                             @"itemId":self.listingObject.objectId,
                                                                             @"invoiceId":[NSString stringWithFormat:@"invoice_%@",self.listingObject.objectId]
                                                                             }];
                    CheckoutSummary *vc = [[CheckoutSummary alloc]init];
                    vc.successMode = YES;
                    vc.listingObject = self.listingObject;
                    vc.orderObject = order;
                    vc.delegate = self;
                    
                    vc.shippingText  = self.shippingPriceLabel.text;
                    vc.itemPriceText  = self.itemPriceLabel.text;
                    vc.totalPriceText  = self.totalPriceLabel.text;
                    
                    [self.navigationController pushViewController:vc animated:YES];
                    
                    [self hideBarButton];
                    self.payButton = nil;
                }
                else{
                    //CHECK test this
                    [self hideHUD];
                    NSLog(@"error fetching order %@", error);
                    [self showAlertWithTitle:@"Order Error #400" andMsg:@"We couldn't fetch your order, make sure you're connected to the internet!"];
                    [self dismissVC];
                }
            }];
        }
        else{
            if ([error.description containsString:@"Item no longer available"]) {
                NSLog(@"error creating BUMP order %@", error);
                [self showAlertWithTitle:@"Item Unavailable" andMsg:@"This item is no longer available on BUMP - Don't worry, you haven't been charged. Check out what else is for sale on BUMP"];
                [Answers logCustomEventWithName:@"Item Unavailable warning"
                               customAttributes:@{}];
            }
            else{
                NSLog(@"error creating BUMP order %@", error);
                [self showAlertWithTitle:@"PayPal Error #802" andMsg:@"You haven't been charged as there was an error creating your PayPal order. Please try again and if the error persists just send us an email to hello@sobump.com"];
                
                [Answers logCustomEventWithName:@"PayPal Error"
                               customAttributes:@{
                                                  @"type":@"Couldn't create bump pp order"
                                                  }];
            }
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
            self.isNational = YES;
            shipping = [[self.listingObject objectForKey:@"nationalShippingPrice"]floatValue];
        }
        else{
            //int. pricing
            shipping = [[self.listingObject objectForKey:@"globalShippingPrice"]floatValue];
        }
        
        self.shippingPriceLabel.text = [NSString stringWithFormat:@"%@%.2f", self.currencySymbol,shipping];
        
        self.totalPrice = shipping + self.salePrice;
        self.totalPriceLabel.text = [NSString stringWithFormat:@"%@ %@%.2f",self.currency,self.currencySymbol,self.totalPrice];
        
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
        if (self.sellerErrorShowing) {
            self.sellerErrorShowing = NO;
            [self dismissVC];
        }
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
    if (@available(iOS 10.0, *)) {
        paypalSafariView.preferredControlTintColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
    }
    [self.navigationController presentViewController:paypalSafariView animated:YES completion:nil];
}

-(void)getSellersPPAccountStatus{
    
    self.checkedSellersPPInfo = YES;
    
    if (![self.listingObject objectForKey:@"paypalMerchantId"]) {
        [Answers logCustomEventWithName:@"No Merchant ID on listing Error"
                       customAttributes:@{}];
        return;
    }
    PFUser *seller = [self.listingObject objectForKey:@"sellerUser"];
    
    NSString *notifyMessage = [NSString stringWithFormat:@"Hey,\n\nSomeone just tried to buy your item '%@' but you need to confirm your PayPal email address before you can accept any payments.\n\nPlease confirm your PayPal email address immediately so buyers can purchase your items on BUMP.",self.itemTitleLabel.text];
    
    NSDictionary *params = @{
                             @"merchantId":[self.listingObject objectForKey:@"paypalMerchantId"],
                             @"sellerId":seller.objectId,
                             @"listingId" : self.listingObject.objectId,
                             @"message":notifyMessage
                             };

    [PFCloud callFunctionInBackground:@"getSellersAccountStatus" withParameters:params block:^(NSDictionary *response, NSError *error) {
        if (!error) {
            //now check if response is good to go
            if ([response valueForKey:@"recievable"] && [response valueForKey:@"email"]) {
                
                BOOL permissionsGranted = [[response valueForKey:@"recievable"]boolValue];
                BOOL emailConfirmed = [[response valueForKey:@"email"]boolValue];
                
                NSLog(permissionsGranted ? @"pp permissions granted" : @"pp permissions NOT granted");
                NSLog(emailConfirmed ? @"pp email confirmed" : @"pp email NOT confirmed");
                
                if (permissionsGranted && emailConfirmed) {
                    
                    //good to buy!

                }
                else{
                    //seller can't accept payments until they've confirmed their email, let buyer know
                    self.sellerErrorShowing = YES;
                    [self showAlertWithTitle:@"Seller Error" andMsg:@"This seller hasn't confirmed their PayPal email address yet which means they can't accept payments at this time. We've given them a hurry up so the item should be available to purchase soon"];
                    
                    [Answers logCustomEventWithName:@"Buyer shown Merchant email error"
                                   customAttributes:@{}];
                }
            }
            else{
                //don't have receivable & merchant Id info in response, log error
                
                [Answers logCustomEventWithName:@"PayPal Error"
                               customAttributes:@{
                                                  @"type":@"No receivable / merchant ID in response in checkout summary"
                                                  }];
            }
        }
        else{
//            [self hidHUD];
            NSLog(@"error getting the account status %@", error);
            
            [Answers logCustomEventWithName:@"PayPal Error"
                           customAttributes:@{
                                              @"type":@"Error getting account status in checkout summary"
                                              }];
        }
    }];
}
@end
