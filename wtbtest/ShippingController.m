//
//  ShippingController.m
//  wtbtest
//
//  Created by Jack Ryder on 09/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ShippingController.h"

@interface ShippingController ()

@end

@implementation ShippingController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"A D D R E S S";
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"customBack"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    
    self.nameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buildingCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.streetnameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.cityCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.postcodeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.phoneNumCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.countryCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.addressLineOne.selectionStyle = UITableViewCellSelectionStyleNone;
    self.addressLineTwo.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.nameField.delegate = self;
    self.buildingField.delegate = self;
    self.streetField.delegate = self;
    self.cityField.delegate = self;
    self.postcodeField.delegate = self;
    self.numberField.delegate = self;
    self.countryField.delegate = self;
    
    self.addressLine1.delegate = self;
    self.addressLine2.delegate = self;
    
    self.currentUser = [PFUser currentUser];
    
    if ([self.currentUser objectForKey:@"addressName"]) {
        self.nameField.text = [self.currentUser objectForKey:@"addressName"];
    }
    else{
        self.nameField.text = [self.currentUser objectForKey:@"fullname"];
    }
    
    //add country picker to textfield
    self.picker = [[CountryPicker alloc]init];
    self.picker.showsSelectionIndicator = YES;
    
    self.countryField.inputView = self.picker;
    self.picker.backgroundColor = [UIColor whiteColor];
    
    if ([self.currentUser objectForKey:@"lineOne"]) {
        self.addressLine1.text = [self.currentUser objectForKey:@"lineOne"];
    }
    if ([self.currentUser objectForKey:@"lineTwo"]) {
        self.addressLine2.text = [self.currentUser objectForKey:@"lineTwo"];
    }
    if ([self.currentUser objectForKey:@"city"]) {
        self.cityField.text = [self.currentUser objectForKey:@"city"];
    }
    if ([self.currentUser objectForKey:@"postcode"]) {
        self.postcodeField.text = [self.currentUser objectForKey:@"postcode"];
    }
    
    if ([self.currentUser objectForKey:@"shippingCountry"]) {
        self.countryField.text = [self.currentUser objectForKey:@"shippingCountry"];
        
        if ([self.currentUser objectForKey:@"shippingCountryCode"]) {
            NSString *countryCode = [self.currentUser objectForKey:@"shippingCountryCode"];
            self.picker.selectedCountryCode = countryCode;
        }
    }
    else{
        self.picker.selectedLocale = [NSLocale currentLocale];
        NSString *selected = self.picker.selectedCountryName;
        self.countryField.text = selected;
    }
    
    [self addDoneButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField == self.countryField) {
        return NO;
    }
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.countryField) {
        NSString *selected = self.picker.selectedCountryName;
        textField.text = selected;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section ==0){
        if (indexPath.row == 0){
            return self.nameCell;
        }
        else if (indexPath.row == 1){
            return self.addressLineOne;
        }
        else if (indexPath.row == 2){
            return self.addressLineTwo;
        }
        else if (indexPath.row == 3){
            return self.cityCell;
        }
        else if (indexPath.row == 4){
            return self.postcodeCell;
        }
        else if (indexPath.row == 5){
            return self.countryCell;
        }
//        else if (indexPath.row == 6){
//            return self.phoneNumCell;
//        }
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    return 44;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    self.somethingChanged = YES;
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if (textField == self.nameField) {
        [self.addressLine1 becomeFirstResponder];
    }
    else if (textField == self.addressLine1) {
        [self.addressLine2 becomeFirstResponder];
    }
    else if (textField == self.addressLine2) {
        [self.cityField becomeFirstResponder];
    }
    else if (textField == self.cityField) {
        [self.postcodeField becomeFirstResponder];
    }
    else if (textField == self.postcodeField) {
        [self.countryField becomeFirstResponder];
    }
    else{
        [textField resignFirstResponder];
    }
    return YES;
}

-(void)saveStuff{
    [self.navigationItem.leftBarButtonItem setEnabled:NO];

    NSString *name = [self.nameField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *postcode = [self.postcodeField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *country = [self.countryField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *city = [self.cityField.text stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSString *line1 = [self.addressLine1.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *line2 = [self.addressLine2.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSMutableString *postcodeStr = [self.postcodeField.text mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)postcodeStr, NULL, kCFStringTransformStripCombiningMarks, NO); //remove accents from postcodes
    

    //check if line 2 is empty
    if ([name isEqualToString:@""] || [line1 isEqualToString:@""]|| [postcode isEqualToString:@""] || [country isEqualToString:@""] || [city isEqualToString:@""]) {
        
        NSString *addressString;
        
        if ([line2 isEqualToString:@""]) {
            addressString = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@",self.nameField.text, self.addressLine1.text,self.cityField.text,postcodeStr,self.countryField.text];
            
            //user hasn't entered a line 2 so delete if exists
            if ([self.currentUser objectForKey:@"lineTwo"]) {
                [self.currentUser removeObjectForKey:@"lineTwo"];
            }
        }
        else{
            addressString = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@",self.nameField.text, self.addressLine1.text, self.addressLine2.text,self.cityField.text,postcodeStr,self.countryField.text];
        }
        
        [self.delegate addedAddress:addressString withName:self.nameField.text withLineOne:self.addressLine1.text withLineTwo:self.addressLine2.text withCity:self.cityField.text withCountry:self.picker.selectedCountryCode fullyEntered:NO];
        self.somethingMissing = YES;
    }
    else{
        //pass back & save to current user
        NSString *addressString;
        
        if ([line2 isEqualToString:@""]) {
            addressString = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@",self.nameField.text, self.addressLine1.text,self.cityField.text,postcodeStr,self.countryField.text];
            
            //user hasn't entered a line 2 so delete if exists
            if ([self.currentUser objectForKey:@"lineTwo"]) {
                [self.currentUser removeObjectForKey:@"lineTwo"];
            }
        }
        else{
            addressString = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@",self.nameField.text, self.addressLine1.text, self.addressLine2.text,self.cityField.text,postcodeStr,self.countryField.text];
        }
        
        [self.delegate addedAddress:addressString withName:self.nameField.text withLineOne:self.addressLine1.text withLineTwo:self.addressLine2.text withCity:self.cityField.text withCountry:self.picker.selectedCountryCode fullyEntered:YES];
        
        [self.currentUser setObject:@"YES" forKey:@"enteredAddress"];
        [self.currentUser setObject:addressString forKey:@"addressString"];
    }
    
    //set what we have on the user object
    if (![name isEqualToString:@""] && name.length > 3) {
        [self.currentUser setObject:[self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"addressName"];
    }
    
    if (![line1 isEqualToString:@""]) {
        [self.currentUser setObject:[self.addressLine1.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"lineOne"];
    }
    
    if (![line2 isEqualToString:@""]) {
        [self.currentUser setObject:[self.addressLine2.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"lineTwo"];
    }
    
    if (![postcode isEqualToString:@""]) {
        [self.currentUser setObject:[postcodeStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"postcode"];
    }
    
    if (![country isEqualToString:@""]) {
        [self.currentUser setObject:[self.countryField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"shippingCountry"];
        [self.currentUser setObject:self.picker.selectedCountryCode forKey:@"shippingCountryCode"];
    }
    
    if (![city isEqualToString:@""]) {
        [self.currentUser setObject:[self.cityField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"city"];
    }
    
    [self.currentUser saveInBackground];
    
    if (self.somethingMissing) {
        if ([name isEqualToString:@""] || name.length < 3) {
            [self showMissingAlertWithTitle:@"Name Missing" andMessage:@"Please make sure you completely enter your full name"];
        }
        
        else if ([line1 isEqualToString:@""]) {
            [self showMissingAlertWithTitle:@"Address Line 1 Missing" andMessage:@"Please make sure you completely enter line 1 of your shipping address"];
        }
        
        else if ([postcode isEqualToString:@""]) {
            [self showMissingAlertWithTitle:@"Zipcode/postcode Missing" andMessage:@"Please make sure you completely enter your full zipcode/postcode"];
        }
        
        else if ([country isEqualToString:@""]) {
            [self showMissingAlertWithTitle:@"Country Missing" andMessage:@"Please select a shipping country"];
        }
        
        else if ([city isEqualToString:@""]) {
            [self showMissingAlertWithTitle:@"City Missing" andMessage:@"Please make sure you completely enter the city field of your shipping address"];
        }
        else{
            [self showMissingAlertWithTitle:@"Information Missing" andMessage:@"Please make sure you completely enter your full shipping address"];
        }
    }
    else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showMissingAlertWithTitle:(NSString *)title andMessage:(NSString *)message{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Stay" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.cancelButton setEnabled:YES];
        self.somethingMissing = NO;
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Leave" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    
    [self presentViewController:alertView animated:YES completion:nil];
}

- (void)addDoneButton {
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
    [keyboardToolbar sizeToFit];

    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self.view action:@selector(endEditing:)];
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    [doneBarButton setTintColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1]];
    keyboardToolbar.barTintColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];

    self.numberField.inputAccessoryView = keyboardToolbar;
    self.countryField.inputAccessoryView = keyboardToolbar;
    
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

-(void)dismissVC{
    if (self.somethingChanged) {
        [self saveStuff];
    }
    else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}
@end
