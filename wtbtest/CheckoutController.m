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
    
    self.priceLabel.text = [NSString stringWithFormat:@"£%.2f", [[self.confirmedOfferObject objectForKey:@"salePrice"] floatValue]];
    self.deliverypriceLabel.text = [NSString stringWithFormat:@"£%.2f", [[self.confirmedOfferObject objectForKey:@"deliveryCost"] floatValue]];
    
    //setup values
    self.price = [[self.confirmedOfferObject objectForKey:@"salePrice"] floatValue];
    self.delivery = [[self.confirmedOfferObject objectForKey:@"deliveryCost"] floatValue];
    self.fee = (self.price + self.delivery)*0.05;
    float total = (self.price + self.delivery + self.fee);
    self.transactionfeeLabel.text = [NSString stringWithFormat:@"£%.2f", self.fee];
    self.totalLabel.text = [NSString stringWithFormat:@"£%.2f",(total + 15)];
    
    self.addressLabel.adjustsFontSizeToFitWidth = YES;
    self.addressLabel.minimumScaleFactor=0.5;
    
    //shipping address
    PFUser *currentUser = [PFUser currentUser];
    
    if ([currentUser objectForKey:@"building"]) {
        //address been set before
        self.addressLabel.text = [NSString stringWithFormat:@"%@\n%@ %@\n%@\n%@\n%@",[currentUser objectForKey:@"fullname"], [currentUser objectForKey:@"building"], [currentUser objectForKey:@"street"], [currentUser objectForKey:@"city"], [currentUser objectForKey:@"postcode"], [currentUser objectForKey:@"phonenumber"]];
    }
    else{
        self.addressLabel.text = [NSString stringWithFormat:@"%@",[currentUser objectForKey:@"fullname"]];
    }

    
    //paypal icons in footer
    UIView *footerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    [footerView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    UIImageView *payp = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"paypalicons"]];
    [payp setFrame:CGRectMake((self.tableView.frame.size.width/2)-60, 20, 120, 18)];
    [footerView addSubview:payp];
    self.tableView.tableFooterView = footerView;
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
        return 4;
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
    //show paypal then create an order object
    
    [self.confirmedOfferObject setObject:@"purchased" forKey:@"status"];
    [self.confirmedOfferObject saveInBackground];
    
    PFObject *orderObject =[PFObject objectWithClassName:@"orders"];
    [orderObject setObject:self.confirmedOfferObject forKey:@"offerObject"];
    [orderObject setObject:[PFUser currentUser] forKey:@"buyerUser"];
    [orderObject setObject:[self.confirmedOfferObject objectForKey:@"sellerUser"] forKey:@"sellerUser"];
    [orderObject setObject:@"paid" forKey:@"status"];
    [orderObject setObject:@"YES" forKey:@"check"];
    
    NSString *prefixToRemove = @"£";
    NSString *fee = [[NSString alloc]init];
    fee = [self.transactionfeeLabel.text substringFromIndex:[prefixToRemove length]];
    
    [orderObject setObject:fee forKey:@"fee"];
    
    NSString *buyerTotal = [[NSString alloc]init];
    buyerTotal = [self.totalLabel.text substringFromIndex:[prefixToRemove length]];
    [orderObject setObject:buyerTotal forKey:@"buyerTotal"];
    
    [orderObject setObject:[self.confirmedOfferObject objectForKey:@"totalCost"] forKey:@"sellerTotal"];
    [orderObject setObject:[self.confirmedOfferObject objectForKey:@"salePrice"] forKey:@"salePrice"];
    NSString *delivery = [[NSString alloc]init];
    delivery = [self.deliverypriceLabel.text substringFromIndex:[prefixToRemove length]];
    
    [orderObject setObject:delivery forKey:@"delivery"];
    
    [orderObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            NSLog(@"order placed! %@", orderObject.objectId);
            ListingCompleteView *vc = [[ListingCompleteView alloc]init];
            vc.orderMode = YES;
            vc.orderTitle = [self.confirmedOfferObject objectForKey:@"title"];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            NSLog(@"error saving %@", error);
        }
    }];
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    
    [footerView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
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
        else if (indexPath.row == 1){
            return self.deliveryCell;
        }
        else if (indexPath.row == 2){
            return self.feeCell;
        }
        else if (indexPath.row == 3){
            return self.authenticityCell;
        }
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
        else if (indexPath.row == 1){
            return 44;
        }
        else if (indexPath.row == 2){
            return 44;
        }
        else if (indexPath.row == 3){
            return 126;
        }
    }
    else if (indexPath.section == 2 || indexPath.section == 3 || indexPath.section == 4){
        return 44;
    }
    return 44;
}
- (IBAction)switchChanged:(id)sender {
    if (self.authenticitySwitch.isSelected == YES) {
        [self.authenticitySwitch setSelected:NO];
        float total = (self.price + self.delivery + self.fee);
        self.totalLabel.text = [NSString stringWithFormat:@"£%.2f",(total + 15)];
    }
    else{
        [self.authenticitySwitch setSelected:YES];
        NSLog(self.authenticitySwitch.isSelected ? @"Yes" : @"No");
        float total = (self.price + self.delivery + self.fee);
        self.totalLabel.text = [NSString stringWithFormat:@"£%.2f",(total)];
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
    if (section ==3 || section == 4 || section == 2) {
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
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(void)removeKeyboard{
    [self.voucherField resignFirstResponder];
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
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section ==0){
        if(indexPath.row == 0){
            ShippingController *vc = [[ShippingController alloc]init];
            vc.delegate = self;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

-(void)addItemViewController:(ShippingController *)controller didFinishEnteringAddress:(NSString *)address{
    self.addressLabel.text = address;
}

@end
