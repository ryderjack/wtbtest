//
//  boostController.m
//  wtbtest
//
//  Created by Jack Ryder on 21/05/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "boostController.h"
#import <Crashlytics/Crashlytics.h>
#import <CommonCrypto/CommonCrypto.h>

@interface boostController ()

@end

@implementation boostController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.products = [NSArray array];
    self.productIdentifiersArray = @[@"ryderjack.wtbtest.featuredBoost",@"ryderjack.wtbtest.highlightBoost",@"ryderjack.wtbtest.searchBoost"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(featurePurchasedBoost:) name:@"featurePurchased" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchPurchasedBoost:) name:@"searchPurchased" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(highlightPurchasedBoost:) name:@"highlightPurchased" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHUD) name:@"purchaseStarted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideHUD) name:@"purchaseDeferred" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPurchaseError) name:@"purchaseError" object:nil];

    self.boost1Cell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.boost2Cell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.boost3Cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (self.introMode != YES) {
        self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
        [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
        [self.longButton addTarget:self action:@selector(BarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        self.longButton.alpha = 0.0f;
        [self.longButton setTitle:@"D I S M I S S" forState:UIControlStateNormal];
        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:0.8]];
        [self.longButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];
        [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
        [self.longButton setEnabled:NO];

        [self showBarButton];
    }
    
    self.featuredLabel.adjustsFontSizeToFitWidth = YES;
    self.featuredLabel.minimumScaleFactor=0.5;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    //check if can even make payments
    if([SKPaymentQueue canMakePayments] != YES){
        self.savingInProcess = YES;
        [self showAlertWithTitle:@"In-App Purchases" andMsg:@"Your Apple account is not configured to make in-app purchases on Bump, if you're stuck send us a message!"];
    }
    
    [self.highlightBuyButton setEnabled:NO];
    [self.searchBoostButton setEnabled:NO];
    [self.featuredBoostButton setEnabled:NO];

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Boost Controller"
                                      }];
    
    [self validateProductIdentifiers:self.productIdentifiersArray];
    
    if (self.introMode == YES && self.buttonShowing == NO && !self.longButton) {
        self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
        [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
        [self.longButton addTarget:self action:@selector(BarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        self.longButton.alpha = 0.0f;
        [self.longButton setTitle:@"D I S M I S S" forState:UIControlStateNormal];
        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:0.8]];
        [self.longButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];
        [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];

        [self.longButton setEnabled:NO];
        [self showBarButton];
    }
    else if (self.buttonShowing != YES) {
        [self showBarButton];
    }

    [self.listing fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            
            double secondsInADay = 86400;
            double secondsInAnHour = 3600;
            
            if ([self.listing objectForKey:@"highlighted"]) {
                
                NSDate *expiryDate = [self.listing objectForKey:@"highlightExpiry"];
    
                if ([[self.listing objectForKey:@"highlighted"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedDescending) {
                    
                    NSTimeInterval distanceBetweenDates = [expiryDate timeIntervalSinceDate:[NSDate date]];
                    NSInteger daysLeftWithBoost = distanceBetweenDates / secondsInADay;
                    
                    self.highlightOn = YES;
                    [self.highlightBuyButton setEnabled:NO];
                    [self.highlightBuyButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
                    
                    //set remaining time
                    float minsBetweenDates = (distanceBetweenDates / secondsInAnHour)*60;
                    
                    if (minsBetweenDates > 0 && minsBetweenDates < 1) {
                        //seconds
                        self.highlightPriceLabel.text = [NSString stringWithFormat:@"%lds left",(long)(minsBetweenDates*60)];
                    }
                    else if (minsBetweenDates >= 1 && minsBetweenDates <60){
                        //mins
                        self.highlightPriceLabel.text = [NSString stringWithFormat:@"%ldm left",(long)minsBetweenDates];
                    }
                    else if (minsBetweenDates >= 60 && minsBetweenDates <1440){
                        //hours
                        self.highlightPriceLabel.text = [NSString stringWithFormat:@"%ldh left",(long)(minsBetweenDates/60)];
                    }
                    else{
                        //days
                        self.highlightPriceLabel.text = [NSString stringWithFormat:@"%ldd left",(long)daysLeftWithBoost];
                    }
                    
                }
                //expiry date is later in time than now so must have expired
                else if ([[self.listing objectForKey:@"highlighted"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedAscending) {
                    [self.listing removeObjectForKey:@"highlighted"];
                    [self.listing saveInBackground];
                    
                    [self.highlightBuyButton setEnabled:YES];
                }
                else{
                    [self.highlightBuyButton setEnabled:YES];
                }
            }
            else{
                [self.highlightBuyButton setEnabled:YES];
            }
            
            if ([self.listing objectForKey:@"searchBoost"]) {
                
                NSDate *expiryDate = [self.listing objectForKey:@"searchBoostExpiry"];
                
                if ([[self.listing objectForKey:@"searchBoost"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedDescending) {
                    self.searchOn = YES;
                    [self.searchBoostButton setEnabled:NO];
                    [self.searchBoostButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
                    
//                    NSLog(@"SEARCH ALREADY ENABLED");
                    
                    NSTimeInterval distanceBetweenDates = [[self.listing objectForKey:@"searchBoostExpiry"] timeIntervalSinceDate:[NSDate date]];
                    NSInteger daysLeftBoost = distanceBetweenDates / secondsInADay;

                    //set remaining time
                    float minsBetweenDates = (distanceBetweenDates / secondsInAnHour)*60;
                    if (minsBetweenDates > 0 && minsBetweenDates < 1) {
                        //seconds
                        self.searchPriceLabel.text = [NSString stringWithFormat:@"%lds left",(long)(minsBetweenDates*60)];
                    }
                    else if (minsBetweenDates >= 1 && minsBetweenDates <60){
                        //mins
                        self.searchPriceLabel.text = [NSString stringWithFormat:@"%ldm left",(long)minsBetweenDates];
                    }
                    else if (minsBetweenDates >= 60 && minsBetweenDates <1440){
                        //hours
                        self.searchPriceLabel.text = [NSString stringWithFormat:@"%ldh left",(long)(minsBetweenDates/60)];
                    }
                    else{
                        //days
                        self.searchPriceLabel.text = [NSString stringWithFormat:@"%ldd left",(long)daysLeftBoost];
                    }
                }
                else if ([[self.listing objectForKey:@"searchBoost"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedAscending) {
                    [self.listing removeObjectForKey:@"searchBoost"];
                    [self.listing saveInBackground];
                    
                    [self.searchBoostButton setEnabled:YES];

                }
                else{
                    [self.searchBoostButton setEnabled:YES];
                }
            }
            else{
                [self.searchBoostButton setEnabled:YES];
            }
            
            if ([self.listing objectForKey:@"featuredBoost"]) {
                
                NSDate *expiryDate = [self.listing objectForKey:@"featuredBoostExpiry"];
                
                if ([[self.listing objectForKey:@"featuredBoost"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedDescending) {
                    self.featuredOn = YES;
                    [self.featuredBoostButton setEnabled:NO];
                    [self.featuredBoostButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
                    
                    NSTimeInterval distanceBetweenDates = [[self.listing objectForKey:@"featuredBoostExpiry"] timeIntervalSinceDate:[NSDate date]];
                    NSInteger daysLeftBoost = distanceBetweenDates / secondsInADay;
                    
                    //set remaining time
                    float minsBetweenDates = (distanceBetweenDates / secondsInAnHour)*60;
                    if (minsBetweenDates > 0 && minsBetweenDates < 1) {
                        //seconds
                        self.featuredPriceLabel.text = [NSString stringWithFormat:@"%lds left",(long)(minsBetweenDates*60)];
                    }
                    else if (minsBetweenDates >= 1 && minsBetweenDates <60){
                        //mins
                        self.featuredPriceLabel.text = [NSString stringWithFormat:@"%ldm left",(long)minsBetweenDates];
                    }
                    else if (minsBetweenDates >= 60 && minsBetweenDates <1440){
                        //hours
                        self.featuredPriceLabel.text = [NSString stringWithFormat:@"%ldh left",(long)(minsBetweenDates/60)];
                    }
                    else{
                        //days
                        self.featuredPriceLabel.text = [NSString stringWithFormat:@"%ldd left",(long)daysLeftBoost];
                    }
                }
                else if ([[self.listing objectForKey:@"featuredBoost"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedAscending) {
                    [self.listing removeObjectForKey:@"featuredBoost"];
                    [self.listing saveInBackground];
                    
                    [self.featuredBoostButton setEnabled:YES];
                }
                else{
                    [self.featuredBoostButton setEnabled:YES];
                }
            }
            else{
                [self.featuredBoostButton setEnabled:YES];
                NSLog(@"featured button enabled!");
            }
            
            //check for free boosts
            
            PFQuery *freeBoostsQuery = [PFQuery queryWithClassName:@"freeBoosts"];
            [freeBoostsQuery whereKey:@"user" equalTo:[PFUser currentUser]];
            [freeBoostsQuery whereKey:@"status" equalTo:@"live"];
            [freeBoostsQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (objects.count >= 1) {
                    
                    for (PFObject *freeBoost in objects) {
                        [freeBoost setObject:@"expired" forKey:@"status"];
                        [freeBoost saveInBackground];
                    }
                    
                    //user has a free boost
                    self.freeBoost = YES;
                    
                    //change button labels (only if not on)
                    
                    if (self.featuredOn != YES) {
                        [self.featuredBoostButton setTitle:@"FREE" forState:UIControlStateNormal];
                        self.featuredPriceLabel.text = @"";
                    }
                    
                    if (self.searchOn != YES) {
                        [self.searchBoostButton setTitle:@"FREE" forState:UIControlStateNormal];
                        self.searchPriceLabel.text = @"";
                    }
                    
                    if (self.highlightOn != YES) {
                        [self.highlightBuyButton setTitle:@"FREE" forState:UIControlStateNormal];
                        self.highlightPriceLabel.text = @"";
                    }
                }
                else{
                    //no free boost
                    self.freeBoost = NO;

                }
            }];
        }
        else{
            NSLog(@"error fetching listing! %@", error);
            [self showAlertWithTitle:@"Connection Error" andMsg:@"Make sure you're connected to the internet!"];
        }
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.topSpaceCell;
        }
        else if (indexPath.row == 1) {
            return self.boost1Cell;
        }
        else if (indexPath.row == 2) {
            return self.boost2Cell;
        }
        else if (indexPath.row == 3) {
            return self.boost3Cell;
        }
        else if (indexPath.row == 4) {
            return self.spaceCell;
        }
        return nil;
    }
    else{
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row != 4 && indexPath.row != 0) {
        return 220;
    }
    else if (indexPath.row == 0){
        return 20;
    }
    else{
        return 60;
    }
}

-(void)showBarButton{
    self.buttonShowing = YES;
    self.longButton.alpha = 0.0f;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.longButton.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)hideBarButton{
    self.buttonShowing = NO;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self hideBarButton];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    self.longButton = nil;
}

-(void)BarButtonPressed{
    [self.longButton setEnabled:NO];
    
    //track what is purchased together
    if (self.highlightPurchased == YES && self.featuredPurchased == YES && self.searchPurchased == YES) {
        [Answers logCustomEventWithName:@"Multiple Purchases Made"
                       customAttributes:@{
                                          @"combo":@"All 3"
                                          }];
    }
    else if (self.highlightPurchased == NO && self.featuredPurchased == YES && self.searchPurchased == YES) {
        [Answers logCustomEventWithName:@"Multiple Purchases Made"
                       customAttributes:@{
                                          @"combo":@"Featured & Search Boost"
                                          }];
    }
    else if (self.highlightPurchased == YES && self.featuredPurchased == NO && self.searchPurchased == YES) {
        [Answers logCustomEventWithName:@"Multiple Purchases Made"
                       customAttributes:@{
                                          @"combo":@"Highlight & Search Boost"
                                          }];
    }
    
    [self hideHUD];
    
    //update listing VC with correct Boost icon
    if (self.featuredPurchased == YES) {
        [self.delegate dismissedWithPurchase:@"featured"];
    }
    else if (self.highlightPurchased == YES){
        [self.delegate dismissedWithPurchase:@"highlight"];
    }
    else if (self.searchPurchased == YES){
        [self.delegate dismissedWithPurchase:@"search"];
    }
    
    [self.delegate dismissedWithPurchase:@""];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)highlightBuyPressed:(id)sender {
    
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"processingPurchase"] == YES) {
        [self showAlertWithTitle:@"Purchase In Progress" andMsg:@"Processing your purchase, hang tight! If you think this is an error then send Team Bump a message"];
        return;
    }
    
    if (self.featuredOn == YES) {
        
        [Answers logCustomEventWithName:@"Highlight Failed as already have Highlight"
                       customAttributes:@{}];
        
        if (![self.listing objectForKey:@"featuredBoostExpiry"]) {
            //must have just purchased featured for featureOn to be YES
            [self showAlertWithTitle:@"Heads up" andMsg:@"You won't be able to purchase this Boost until your Feature Boost has ended"];
        }
        else{
            NSTimeInterval distanceBetweenDates = [[self.listing objectForKey:@"featuredBoostExpiry"] timeIntervalSinceDate:[NSDate date]];
            double secondsInADay = 86400;
            NSInteger daysSinceBoost = distanceBetweenDates / secondsInADay;
            
            [self showAlertWithTitle:@"Heads up" andMsg:[NSString stringWithFormat:@"You won't be able to purchase this Boost until your Feature Boost has ended in %ld days",(long)daysSinceBoost]];
        }

        return;
    }
    
    if (self.savingInProcess == YES || !self.highlightProduct) {
        return;
    }
    self.savingInProcess = YES;

    [[NSUserDefaults standardUserDefaults] setObject:self.listing.objectId forKey:@"pendingListingPurchase"];
    
    if (self.freeBoost == YES) {
        [self showHUD];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseComplete" object:@"ryderjack.wtbtest.highlightBoost"];
    }
    else{
        
        //block out further purchaes whilst this is processing
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"processingPurchase"];
        
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:self.highlightProduct];
        payment.quantity = 1;
        payment.applicationUsername = [self hashedValueForAccountName:[PFUser currentUser].username];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}
- (IBAction)searchBuyPressed:(id)sender {
    
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"processingPurchase"] == YES) {
        [self showAlertWithTitle:@"Purchase In Progress" andMsg:@"Processing your purchase, hang tight! If you think this is an error then send Team Bump a message"];
        return;
    }
    
    if (self.savingInProcess == YES || !self.searchBoostProduct) {
        return;
    }
    self.savingInProcess = YES;
    
    [[NSUserDefaults standardUserDefaults] setObject:self.listing.objectId forKey:@"pendingListingPurchase"];
    
    if (self.freeBoost == YES) {
        [self showHUD];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseComplete" object:@"ryderjack.wtbtest.searchBoost"];
    }
    else{
        
        //block out further purchaes whilst this is processing
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"processingPurchase"];
        
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:self.searchBoostProduct];
        payment.quantity = 1;
        payment.applicationUsername = [self hashedValueForAccountName:[PFUser currentUser].username];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }

}
- (IBAction)featuredBuyPressed:(id)sender {
    
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"processingPurchase"] == YES) {
        [self showAlertWithTitle:@"Purchase In Progress" andMsg:@"Processing your purchase, hang tight! If you think this is a mistake then send Team Bump a message"];
        return;
    }
    
    if (self.highlightOn == YES) {
        
        [Answers logCustomEventWithName:@"Feature Failed as already have Highlight"
                       customAttributes:@{}];
        
        if (![self.listing objectForKey:@"highlightExpiry"]) {
            //must have just purchased highlight for highlightOn to be YES and self.listing hasn't been refreshed in this VC
            [self showAlertWithTitle:@"Heads up" andMsg:@"You won't be able to purchase this Boost until your Highlight Boost has ended"];
        }
        else{
            NSTimeInterval distanceBetweenDates = [[self.listing objectForKey:@"highlightExpiry"] timeIntervalSinceDate:[NSDate date]];
            double secondsInADay = 86400;
            NSInteger daysSinceBoost = distanceBetweenDates / secondsInADay;
            
            [self showAlertWithTitle:@"Heads up" andMsg:[NSString stringWithFormat:@"You won't be able to purchase this Boost until your Highlight Boost has ended in %ld days",(long)daysSinceBoost]];
        }
        
        return;
    }
    
    if (self.savingInProcess == YES || !self.featuredProduct) {
        return;
    }
    self.savingInProcess = YES;
    
    [[NSUserDefaults standardUserDefaults] setObject:self.listing.objectId forKey:@"pendingListingPurchase"];
    
    if (self.freeBoost == YES) {
        [self showHUD];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseComplete" object:@"ryderjack.wtbtest.featuredBoost"];
    }
    else{
        
        //block out further purchaes whilst this is processing
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"processingPurchase"];

        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:self.featuredProduct];
        payment.quantity = 1;
        payment.applicationUsername = [self hashedValueForAccountName:[PFUser currentUser].username];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
    self.hudShowing = YES;
    self.shouldShowHUD = YES;
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
        self.hudShowing = NO;
        self.shouldShowHUD = NO;
    });
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];

    [self presentViewController:alertView animated:YES completion:nil];
}

- (void)validateProductIdentifiers:(NSArray *)productIdentifiers
{
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
                                          initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    
    // Keep a strong reference to the request.
    self.request = productsRequest;
    productsRequest.delegate = self;
    [productsRequest start];
}

// SKProductsRequestDelegate protocol method
- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response
{
    self.products = response.products;
    
//    for (NSString *invalidIdentifier in response.invalidProductIdentifiers) {
//        // Handle any invalid product identifiers.
//        
//    }
    
//    NSLog(@"products %@", self.products);
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    NSDecimalNumberHandler *handler = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown
                                                                                             scale:2
                                                                                  raiseOnExactness:NO
                                                                                   raiseOnOverflow:NO
                                                                                  raiseOnUnderflow:NO
                                                                               raiseOnDivideByZero:NO];
    NSDecimalNumber *divisor = [[NSDecimalNumber alloc] initWithInt:5];

    for (SKProduct *product in self.products) {
        
        if ([product.localizedTitle isEqualToString:@"Featured"]) {
            
            //if listing already has this on, don't change the labels
            if (self.featuredOn == YES) {
                continue;
            }
            
            //set button title w/ price
            [numberFormatter setLocale:product.priceLocale];
            NSString *formattedPrice = [numberFormatter stringFromNumber:product.price];
            
            //if user has a free bost then don't change the labels!
            if (self.freeBoost != YES) {
                [self.featuredBoostButton setTitle:formattedPrice forState:UIControlStateNormal];
                
                //set per day price label
                NSDecimalNumber *perDay = [product.price decimalNumberByDividingBy:divisor withBehavior:handler];
                NSString *formattedDayPrice = [numberFormatter stringFromNumber:perDay];
                self.featuredPriceLabel.text = [NSString stringWithFormat:@"%@ / Day", formattedDayPrice];
            }
    
            self.featuredProduct = product;
        }
        else if ([product.localizedTitle isEqualToString:@"Search Boost"]) {
            
            //if listing already has this on, don't change the labels
            if (self.searchOn == YES) {
                continue;
            }
            
            
            if (self.freeBoost != YES) {
                //set button title w/ price
                [numberFormatter setLocale:product.priceLocale];
                NSString *formattedPrice = [numberFormatter stringFromNumber:product.price];
                [self.searchBoostButton setTitle:formattedPrice forState:UIControlStateNormal];
                
                //set per day price label
                NSDecimalNumber *perDay = [product.price decimalNumberByDividingBy:divisor withBehavior:handler];
                NSString *formattedDayPrice = [numberFormatter stringFromNumber:perDay];
                self.searchPriceLabel.text = [NSString stringWithFormat:@"%@ / Day", formattedDayPrice];
            }

            
            self.searchBoostProduct = product;
        }
        else if ([product.localizedTitle isEqualToString:@"Highlight Boost"]) {
            //set button title w/ price
            
            //if listing already has this on, don't change the labels
            if (self.highlightOn == YES) {
                continue;
            }
            
            if (self.freeBoost != YES) {
                [numberFormatter setLocale:product.priceLocale];
                NSString *formattedPrice = [numberFormatter stringFromNumber:product.price];
                [self.highlightBuyButton setTitle:formattedPrice forState:UIControlStateNormal];
                
                //set per day price label
                NSDecimalNumber *perDay = [product.price decimalNumberByDividingBy:divisor withBehavior:handler];
                NSString *formattedDayPrice = [numberFormatter stringFromNumber:perDay];
                self.highlightPriceLabel.text = [NSString stringWithFormat:@"%@ / Day", formattedDayPrice];
            }
            
            self.highlightProduct = product;
        }
    }
    //need to wait for this to finish before letting user dismiss
    [self.longButton setEnabled:YES];
}

// Custom method to calculate the SHA-256 hash using Common Crypto
- (NSString *)hashedValueForAccountName:(NSString*)userAccountName
{
    const int HASH_SIZE = 32;
    unsigned char hashedChars[HASH_SIZE];
    const char *accountName = [userAccountName UTF8String];
    size_t accountNameLen = strlen(accountName);
    
    // Confirm that the length of the user name is small enough
    // to be recast when calling the hash function.
    if (accountNameLen > UINT32_MAX) {
        NSLog(@"Account name too long to hash: %@", userAccountName);
        return nil;
    }
    CC_SHA256(accountName, (CC_LONG)accountNameLen, hashedChars);
    
    // Convert the array of bytes into a string showing its hex representation.
    NSMutableString *userAccountHash = [[NSMutableString alloc] init];
    for (int i = 0; i < HASH_SIZE; i++) {
        // Add a dash every four bytes, for readability.
        if (i != 0 && i%4 == 0) {
            [userAccountHash appendString:@"-"];
        }
        [userAccountHash appendFormat:@"%02x", hashedChars[i]];
    }
    
    return userAccountHash;
}

#pragma mark - callbacks after successful purchase to update UI

-(void)featurePurchasedBoost:(NSNotification*)note {
    
    BOOL success = [[note object]boolValue];
    
    [self hideHUD];
    
    if (success ==  YES) {
        //boost saved!
        
        // change the button image
        [self.featuredBoostButton setTitle:@"" forState:UIControlStateNormal];
        [self.featuredBoostButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
        [self.featuredBoostButton setEnabled:NO];
        
        self.featuredPriceLabel.text = @"5d left";
        
        self.savingInProcess = NO;
        self.featuredPurchased = YES;
        self.featuredOn = YES;
        
        if (self.freeBoost) {
            self.freeBoost = NO;
            [self refreshLabels];
        }

    }
    else{
        //error saving
        
        [self hideHUD];
        
        [self.featuredBoostButton setEnabled:YES];
        self.savingInProcess = NO;
    }
}

-(void)searchPurchasedBoost:(NSNotification*)note {
    
    BOOL success = [[note object]boolValue];
    
    [self hideHUD];
    
    if (success ==  YES) {
        //boost saved!
        
        [self.searchBoostButton setTitle:@"" forState:UIControlStateNormal];
        [self.searchBoostButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
        [self.searchBoostButton setEnabled:NO];
        
        self.searchPriceLabel.text = @"5d left";

        self.savingInProcess = NO;
        self.searchPurchased = YES;
        self.searchOn = YES;
        
        if (self.freeBoost) {
            self.freeBoost = NO;
            [self refreshLabels];
        }
    }
    else{
        //error saving
        
        [self hideHUD];
        
        [self.searchBoostButton setEnabled:YES];
        self.savingInProcess = NO;
    }
}

-(void)highlightPurchasedBoost:(NSNotification*)note {
    
    BOOL success = [[note object]boolValue];
    
    [self hideHUD];
    
    if (success ==  YES) {
        //boost saved!
        
        [self.highlightBuyButton setTitle:@"" forState:UIControlStateNormal];
        [self.highlightBuyButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
        [self.highlightBuyButton setEnabled:NO];
        
        self.highlightPriceLabel.text = @"5d left";
        
        self.savingInProcess = NO;
        self.highlightPurchased = YES;
        self.highlightOn = YES;
        
        if (self.freeBoost) {
            self.freeBoost = NO;
            [self refreshLabels];
        }
    }
    else{
        //error saving
        
        [self hideHUD];
        
        [self.highlightBuyButton setEnabled:YES];
        self.savingInProcess = NO;
        
    }
}

-(void)showPurchaseError{
    [self showAlertWithTitle:@"Error Saving Purchase" andMsg:@"Make sure you're connected to the internet and then restart Bump to access your purchase 🤙"];
}

-(void)refreshLabels{
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    NSDecimalNumberHandler *handler = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown
                                                                                             scale:2
                                                                                  raiseOnExactness:NO
                                                                                   raiseOnOverflow:NO
                                                                                  raiseOnUnderflow:NO
                                                                               raiseOnDivideByZero:NO];
    NSDecimalNumber *divisor = [[NSDecimalNumber alloc] initWithInt:5];
    
    if (!self.featuredOn) {
        NSLog(@"featured not on so set the price");
        [numberFormatter setLocale:self.featuredProduct.priceLocale];
        NSString *formattedPrice = [numberFormatter stringFromNumber:self.featuredProduct.price];
        
        [self.featuredBoostButton setTitle:formattedPrice forState:UIControlStateNormal];
        
        //set per day price label
        NSDecimalNumber *perDay = [self.featuredProduct.price decimalNumberByDividingBy:divisor withBehavior:handler];
        NSString *formattedDayPrice = [numberFormatter stringFromNumber:perDay];
        self.featuredPriceLabel.text = [NSString stringWithFormat:@"%@ / Day", formattedDayPrice];
    }
    
    if (!self.searchOn) {
        [numberFormatter setLocale:self.searchBoostProduct.priceLocale];
        NSString *formattedPrice = [numberFormatter stringFromNumber:self.searchBoostProduct.price];
        
        [self.searchBoostButton setTitle:formattedPrice forState:UIControlStateNormal];
        
        //set per day price label
        NSDecimalNumber *perDay = [self.searchBoostProduct.price decimalNumberByDividingBy:divisor withBehavior:handler];
        NSString *formattedDayPrice = [numberFormatter stringFromNumber:perDay];
        self.searchPriceLabel.text = [NSString stringWithFormat:@"%@ / Day", formattedDayPrice];
    }
    
    if (!self.highlightOn) {
        [numberFormatter setLocale:self.highlightProduct.priceLocale];
        NSString *formattedPrice = [numberFormatter stringFromNumber:self.highlightProduct.price];
        
        [self.highlightBuyButton setTitle:formattedPrice forState:UIControlStateNormal];
        
        //set per day price label
        NSDecimalNumber *perDay = [self.highlightProduct.price decimalNumberByDividingBy:divisor withBehavior:handler];
        NSString *formattedDayPrice = [numberFormatter stringFromNumber:perDay];
        self.highlightPriceLabel.text = [NSString stringWithFormat:@"%@ / Day", formattedDayPrice];
    }
}
@end
