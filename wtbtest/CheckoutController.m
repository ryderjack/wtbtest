//
//  CheckoutController.m
//  wtbtest
//
//  Created by Jack Ryder on 08/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "CheckoutController.h"
#import "ListingCompleteView.h"

@interface CheckoutController ()

@end

@implementation CheckoutController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Purchase";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.payCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.totalCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.itemPriceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.feeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.authenticityCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.voucherCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.priceField.delegate = self;
    self.voucherField.delegate = self;
    
    [self.confirmedOfferObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (!error) {
            self.currency = [self.confirmedOfferObject objectForKey:@"currency"];
            self.currencySymbol = [self.confirmedOfferObject objectForKey:@"symbol"];
            
            self.priceField.text = [NSString stringWithFormat:@"%@%.2f",self.currencySymbol ,[[self.confirmedOfferObject objectForKey:@"salePrice"] floatValue]];
            self.price = [[self.confirmedOfferObject objectForKey:@"salePrice"] floatValue];
            self.totalLabel.text = [NSString stringWithFormat:@"%@ %@%.2f",self.currency ,self.currencySymbol,self.price];
        }
        else{
            [self showError];
        }
    }];
    
//    self.deliverypriceLabel.text = [NSString stringWithFormat:@"£%.2f", [[self.confirmedOfferObject objectForKey:@"deliveryCost"] floatValue]];
    
    //setup values
    
//    self.delivery = [[self.confirmedOfferObject objectForKey:@"deliveryCost"] floatValue];
//    self.fee = (self.price + self.delivery)*0.05;
//    self.fee = 0;
//    float total = (self.price + self.delivery ); //+ self.fee
//    self.transactionfeeLabel.text = [NSString stringWithFormat:@"£%.2f", self.fee];
//    self.totalLabel.text = [NSString stringWithFormat:@"£%.2f",(total + 15)];
    
    self.addressLabel.adjustsFontSizeToFitWidth = YES;
    self.addressLabel.minimumScaleFactor=0.5;
    
    //shipping address
    PFUser *currentUser = [PFUser currentUser];
    
    if ([currentUser objectForKey:@"building"]) {
        //address been set before
        self.addressLabel.text = [NSString stringWithFormat:@"%@\n%@ %@\n%@\n%@\n%@\n%@",[currentUser objectForKey:@"fullname"], [currentUser objectForKey:@"building"], [currentUser objectForKey:@"street"], [currentUser objectForKey:@"city"], [currentUser objectForKey:@"postcode"],[currentUser objectForKey:@"country"] ,[currentUser objectForKey:@"phonenumber"]];
    }
    else{
        self.addressLabel.text = @"Add address";
    }
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];

    //paypal icons in footer
    UIView *footerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    [footerView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    UIImageView *payp = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"paypalicons"]];
    [payp setFrame:CGRectMake((self.tableView.frame.size.width/2)-60, 20, 120, 18)];
    [footerView addSubview:payp];
    self.tableView.tableFooterView = footerView;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return 1;
    }
    else if (section == 1){
        return 1; //should be 4 with fee cell & delivery cell & authenticity
    }
    else if (section == 2){
        return 1;
    }
    else if (section ==3){
        return 1;
    }
    else if (section == 4){
        return 1;
    }
    return 1;
}
- (IBAction)payPressed:(id)sender {
    [self.payButton setEnabled:NO];
    //show paypal then create an order object
    
    if ([self.addressLabel.text isEqualToString:@"Add address"]) {
        // havent entered address
        [self.payButton setEnabled:YES];
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"Shipping address"
                                      message:@"Add a valid shipping address!"
                                      preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    else if ([self.priceField.text isEqualToString:[NSString stringWithFormat:@"%@", self.currencySymbol]]){
        // havent entered valid price
        [self.payButton setEnabled:YES];
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"Price"
                                      message:@"Add a valid item price to pay"
                                      preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    else{
        [self showPaypal];
    }
}

-(void)showPaypal{
    NSString *URLString = @"https://www.paypal.com/myaccount/transfer/buy";
    self.webViewController = [[TOWebViewController alloc] initWithURL:[NSURL URLWithString:URLString]];
    self.webViewController.title = @"PayPal";
    self.webViewController.showUrlWhileLoading = YES;
    self.webViewController.showPageTitles = NO;
    self.webViewController.delegate = self;
    self.webViewController.doneButtonTitle = @"Paid";
    self.webViewController.paypalMode = YES;
    self.webViewController.emailToPay = self.sellerEmail;
    self.webViewController.amountToPay = self.totalLabel.text;
    self.webViewController.infoMode = YES;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.webViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)createOrder{
    [self showHUD];
    PFObject *orderObject =[PFObject objectWithClassName:@"orders"];
    [orderObject setObject:self.confirmedOfferObject forKey:@"offerObject"];
    [orderObject setObject:[PFUser currentUser] forKey:@"buyerUser"];
    [orderObject setObject:[self.confirmedOfferObject objectForKey:@"sellerUser"] forKey:@"sellerUser"];
    [orderObject setObject:[self.confirmedOfferObject objectForKey:@"title"] forKey:@"title"];
    [orderObject setObject:@"waiting" forKey:@"status"];
    [orderObject setObject:[self.confirmedOfferObject objectForKey:@"salePrice"] forKey:@"salePrice"];
    [orderObject setObject:[self.confirmedOfferObject objectForKey:@"currency"] forKey:@"currency"];
    [orderObject setObject:[NSNumber numberWithBool:NO] forKey:@"paid"];
    [orderObject setObject:[NSNumber numberWithBool:NO] forKey:@"shipped"];
    [orderObject setObject:[NSNumber numberWithBool:NO] forKey:@"sellerFeedback"];
    [orderObject setObject:[NSNumber numberWithBool:NO] forKey:@"buyerFeedback"];
    
    NSString *prefixToRemove = [NSString stringWithFormat:@"%@", self.currencySymbol];
    NSString *buyerTotal = [[NSString alloc]init];
    buyerTotal = [self.totalLabel.text substringFromIndex:[prefixToRemove length]];
    float buyerTotalFloat = [buyerTotal floatValue];
    orderObject[@"buyerTotal"] = @(buyerTotalFloat);
        
    [orderObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            NSLog(@"order placed! %@", orderObject);
            
            [self.convo setObject:orderObject forKey:@"order"];
            [self.convo setObject:self.confirmedOfferObject forKey:@"offer"];
            [self.convo setObject:[self.confirmedOfferObject objectForKey:@"wtbListing"] forKey:@"listing"];
            [self.convo saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    NSLog(@"success! saving convo");
                    [self.confirmedOfferObject setObject:@"waiting" forKey:@"status"];
                    [self.confirmedOfferObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (succeeded) {
                            NSLog(@"success! saving offer");
                            [self hideHUD];
                            [self.navigationController popViewControllerAnimated:YES];
                        }
                        else{
                            NSLog(@"error saving offer status %@", error);
                            [self hideHUD];
                            [self.navigationController popViewControllerAnimated:YES];
                        }
                    }];
                }
                else{
                    NSLog(@"error saving convo obj %@", error);
                    [self hideHUD];
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }];
            
//            ListingCompleteView *vc = [[ListingCompleteView alloc]init];
//            vc.orderMode = YES;
//            vc.orderTitle = [self.confirmedOfferObject objectForKey:@"title"];
//            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            [self hideHUD];
            [self.payButton setEnabled:YES];
            NSLog(@"error saving %@", error);
            [self showError];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    
    [footerView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    if (section == 2) {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, tableView.bounds.size.width, 20)];
        label.text = @"Avoid gifting payments to maximise protection";
        label.textColor = [UIColor lightGrayColor];
        [label setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:11]];
        [footerView addSubview:label];
    }
    return footerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.shippingAddressCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.itemPriceCell;
        }
//        else if (indexPath.row == 1){
//            return self.deliveryCell;
//        }
//        else if (indexPath.row == 1){
//            return self.authenticityCell;
//        }
//        else if (indexPath.row == 3){ should be above authenticity
//            return self.feeCell;
//        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return self.totalCell;
        }
    }
    else if (indexPath.section ==3){
        if (indexPath.row == 0){
            return self.voucherCell;
        }
    }
    else if (indexPath.section == 4){
        if (indexPath.row == 0) {
            return self.payCell;
        }
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 124;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return 44;
        }
//        else if (indexPath.row == 1){
//            return 126;
//        }
//        else if (indexPath.row == 2){
//            return 44;
//        }
//        else if (indexPath.row == 3){ swap with one above!
//            return 44;
//        }
    }
    else if (indexPath.section == 2 || indexPath.section == 3 || indexPath.section == 4){
        return 44;
    }
    return 44;
}
- (IBAction)switchChanged:(id)sender {
    if (self.authenticitySwitch.isSelected == YES) {
        [self.authenticitySwitch setSelected:NO];
        float total = (self.price + self.delivery ); //+ self.fee
        self.totalLabel.text = [NSString stringWithFormat:@"%@%.2f",self.currencySymbol,(total + 15)];
    }
    else{
        [self.authenticitySwitch setSelected:YES];
        NSLog(self.authenticitySwitch.isSelected ? @"Yes" : @"No");
        float total = (self.price + self.delivery); //+ self.fee
        self.totalLabel.text = [NSString stringWithFormat:@"%@%.2f",self.currencySymbol,(total)];
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0 || section == 1 || section == 2)
        return 0.0f;
    else
    return 32.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section ==3 || section == 4) {
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
-(void)textFieldDidEndEditing:(UITextField *)textField{
    //query if voucher code is legit and display a tick if so + another savings cell?
    self.totalLabel.text = [NSString stringWithFormat:@"%@ %@",self.currency ,self.priceField.text];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section ==0){
        if(indexPath.row == 0){
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            ShippingController *vc = [[ShippingController alloc]init];
            vc.delegate = self;
            vc.settingsMode = NO;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

-(void)addItemViewController:(ShippingController *)controller didFinishEnteringAddress:(NSString *)address{
    self.addressLabel.text = address;
}

//text field delegates

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.priceField) {
        // Check for deletion of the £ sign
        if (range.location == 0 && [textField.text hasPrefix:[NSString stringWithFormat:@"%@", self.currencySymbol]])
            return NO;
        
        NSString *updatedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray *stringsArray = [updatedText componentsSeparatedByString:@"."];
        
        // Check for an absurdly large amount
        if (stringsArray.count > 0)
        {
            NSString *dollarAmount = stringsArray[0];
            if (dollarAmount.length > 6)
                return NO;
            
            // not allowed to enter all 9s
            if ([dollarAmount isEqualToString:[NSString stringWithFormat:@"%@99999", self.currencySymbol]]) {
                return NO;
            }
        }
        
        return YES;
    }
    
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    if (textField == self.priceField) {
        self.priceField.text = [NSString stringWithFormat:@"%@", self.currencySymbol];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(void)removeKeyboard{
    [self.voucherField resignFirstResponder];
    [self.priceField resignFirstResponder];
}

-(void)didPressDone:(UIImage *)screenshot{
    [self.webViewController dismissViewControllerAnimated:YES completion:nil];
    [self createOrder];
    
    //send push to other user
    NSString *pushString = [NSString stringWithFormat:@"%@ has said they've paid for %@, check and confirm now.",[[PFUser currentUser]username], [self.confirmedOfferObject objectForKey:@"title"]];
    NSDictionary *params = @{@"userId": self.otherUserId, @"message": pushString, @"sender": [PFUser currentUser].username};
    [PFCloud callFunctionInBackground:@"sendPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
        if (!error) {
            NSLog(@"response sending paid push %@", response);
        }
        else{
            NSLog(@"image push error %@", error);
        }
    }];
    
    //invalidate all other offers in convo
    PFQuery *offerQuery = [PFQuery queryWithClassName:@"offers"];
    [offerQuery whereKey:@"convo" equalTo:self.convo];
    [offerQuery whereKey:@"objectId" notEqualTo:self.confirmedOfferObject.objectId];
    [offerQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            for (PFObject *offer in objects) {
                [offer setObject:@"expired" forKey:@"status"];
                [offer saveInBackground];
            }
        }
        else{
            NSLog(@"no other offers outstanding");
        }
    }];
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
}

-(void)showError{
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Error"
                                  message:@"Make sure you're connected to the internet!"
                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
