//
//  ShippingOptionsView.m
//  wtbtest
//
//  Created by Jack Ryder on 28/09/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "ShippingOptionsView.h"

@interface ShippingOptionsView ()

@end

@implementation ShippingOptionsView

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"S H I P P I N G";
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cancelCross"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.nationalShippingCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.globalShippingCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.globalDecisionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self addDoneButton];

    if (self.globalEnabled) {
        self.rowNumber = 2;
        [self.globalSwitch setOn:YES];

    }
    else{
        self.rowNumber = 1;
        [self.globalSwitch setOn:NO];
    }

    //textfields
    self.globalTextfield.delegate = self;
    self.nationalTextfield.delegate = self;
    
    if (self.globalPrice > 0.00) {
        self.globalTextfield.text = [NSString stringWithFormat:@"%@%.2f",self.currencySymbol,self.globalPrice];
    }
    
    if (self.nationalPrice > 0.00) {
        self.nationalTextfield.text = [NSString stringWithFormat:@"%@%.2f",self.currencySymbol,self.nationalPrice];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 32.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.0;
}


-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *header;
    
    if (@available(iOS 11.0, *)) {
        if ([ [ UIScreen mainScreen ] bounds ].size.width == 375) {
            //iPhone6/7
            header = [[UIView alloc]initWithFrame:CGRectMake(28, 0, self.tableView.frame.size.width, 32)];
        }
        else if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
            //iPhone 6 plus
            header = [[UIView alloc]initWithFrame:CGRectMake(32, 0, self.tableView.frame.size.width, 32)];
        }
        else if([ [ UIScreen mainScreen ] bounds ].size.width == 320){
            //iPhone 4/5
            header = [[UIView alloc]initWithFrame:CGRectMake(28, 0, self.tableView.frame.size.width, 32)];
        }
        else{
            //fall back
            header = [[UIView alloc]initWithFrame:CGRectMake(28, 0, self.tableView.frame.size.width, 32)];
        }
    }
    else{
        header = [[UIView alloc]initWithFrame:CGRectMake(20, 0, self.tableView.frame.size.width, 32)];
    }
    
    UILabel *textLabel = [[UILabel alloc]initWithFrame:header.frame];
    textLabel.textColor = [UIColor grayColor];
    textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    header.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    [header addSubview:textLabel];
    if (section ==0){
        textLabel.text = @"National Shipping";
    }
    else if (section == 1){
        textLabel.text = @"International Shipping";
    }
    
    return header;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0){
        return 1;
    }
    else if (section == 1){
        return self.rowNumber;
    }
    else{
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.nationalShippingCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.globalDecisionCell;
        }
        else if (indexPath.row == 1) {
            return self.globalShippingCell;
        }
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        [self.nationalTextfield becomeFirstResponder];
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 1) {
            [self.globalTextfield becomeFirstResponder];
        }
    }
}
- (IBAction)globalSwitchChanged:(id)sender {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:1];

    if (self.globalSwitch.isOn) {
        //on
        self.globalEnabled = YES;
        self.rowNumber++;
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    }
    else{
        //off
        self.globalEnabled = NO;

        self.rowNumber--;
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self.delegate shippingOptionsWithNational:self.nationalPrice withGlobal:self.globalPrice withGlobalEnabled:self.globalEnabled];
}

#pragma mark - Text field delegate methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    textField.text = [NSString stringWithFormat:@"%@", self.currencySymbol];
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    
    NSLog(@"did end editing");
    if ([textField.text isEqualToString:self.currencySymbol]) {
        textField.text = @"";
        return;
    }
    
    NSString *prefixToRemove = [NSString stringWithFormat:@"%@", self.currencySymbol];
    NSString *priceString = [[NSString alloc]init];
    priceString = [textField.text substringFromIndex:[prefixToRemove length]];
    
    NSArray *priceArray = [priceString componentsSeparatedByString:@"."];
    
    NSMutableArray *priceArrayMutable = [NSMutableArray arrayWithArray:priceArray];
    
    [priceArrayMutable removeObject:@""];
    
    priceArray = priceArrayMutable;
    
    if (priceArray.count == 0) {
        //entered nothing
        priceString = @"0.00";
    }
    else if (priceArray.count > 2) {
        //multiple decimal points added
        priceString = @"0.00";
    }
    else if (priceArray.count == 1){
        //just entered an int
        NSString *intAmount = priceArray[0];
        
        //check if just zeros
        if ([[intAmount stringByReplacingOccurrencesOfString:@"0" withString:@""]isEqualToString:@""]) {
            intAmount = @"0";
        }
        
        //            NSLog(@"length of this int %@   int %lu",intAmount ,(unsigned long)intAmount.length);
        priceString = [NSString stringWithFormat:@"%@.00", intAmount];
    }
    else if (priceArray.count > 1){
        
        NSString *intAmount = priceArray[0];
        
        //check if its just all zeros
        if ([[intAmount stringByReplacingOccurrencesOfString:@"0" withString:@""]isEqualToString:@""]) {
            intAmount = @"0";
        }
        else if (intAmount.length == 1){
            NSLog(@"single digit then a decimal point");
        }
        else{
            //all good
            NSLog(@"length of int %lu", (unsigned long)intAmount.length);
        }
        
        NSMutableString *centAmount = priceArray[1];
        if (centAmount.length == 2){
            //all good
            NSLog(@"all good");
        }
        else if (centAmount.length == 1){
            NSLog(@"got 1 decimal place");
            centAmount = [NSMutableString stringWithFormat:@"%@0", centAmount];
        }
        else{
            NSLog(@"point but no numbers after it");
            centAmount = [NSMutableString stringWithFormat:@"00"];
        }
        
        priceString = [NSString stringWithFormat:@"%@.%@", intAmount, centAmount];
    }
    else{
        if ([[priceString stringByReplacingOccurrencesOfString:@"0" withString:@""]isEqualToString:@""]) {
            priceString = @"0.00";
        }
        else{
            priceString = [NSString stringWithFormat:@"%@.00", priceString];
        }
        NSLog(@"no decimal point so price is %@", priceString);
    }
    
    if ([priceString isEqualToString:@"0.00"] || [priceString isEqualToString:@""] || [priceString isEqualToString:[NSString stringWithFormat:@".00"]] || [priceString isEqualToString:@"  "]) {
        //invalid price number
        NSLog(@"invalid price number");
        textField.text = @"";
        
        if (textField == self.nationalTextfield) {
            self.nationalPrice =0.00;
        }
        else{
            self.globalPrice =0.00;
        }
    }
    else{
        textField.text = [NSString stringWithFormat:@"%@%@", self.currencySymbol, priceString];
        
        if (textField == self.nationalTextfield) {
            self.nationalPrice = [priceString floatValue];
        }
        else{
            self.globalPrice = [priceString floatValue];
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Check for deletion of the currency sign
    if (range.location == 0 && [textField.text hasPrefix:[NSString stringWithFormat:@"%@", self.currencySymbol]])
        return NO;
    
    NSString *updatedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSArray *stringsArray = [updatedText componentsSeparatedByString:@"."];
    
    //check for multiple decimal points
    if (stringsArray.count > 2) {
        return NO;
    }
    
    //        //check for entering decimal point before any numbers
    if ([string isEqualToString:@"."] && [textField.text isEqualToString:self.currencySymbol]) {
        textField.text = [NSString stringWithFormat:@"%@0", self.currencySymbol];
        return YES;
    }
    
    // Check for an absurdly large amount & 0
    if (stringsArray.count > 0)
    {
        NSString *dollarAmount = stringsArray[0];
        
        if (stringsArray.count > 1) {
            NSString *centAmount = stringsArray[1];
            
            //DONT LET ADD MORE NUMBERS IF ALREADY HAVE 2 NUMBERS AFTER DECIMAL POINT
            if ([centAmount length] > 2) {
                return NO;
            }
        }
        if (dollarAmount.length > 6)
            return NO;
        // not allowed to enter all 9s
        if ([dollarAmount isEqualToString:[NSString stringWithFormat:@"%@99999", self.currencySymbol]]) {
            return NO;
        }
    }
    
    return YES;
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
    
    [doneBarButton setTintColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1]];
    keyboardToolbar.barTintColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];
    
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    self.nationalTextfield.inputAccessoryView = keyboardToolbar;
    self.globalTextfield.inputAccessoryView = keyboardToolbar;
}

-(void)dismissVC{
    if (self.globalEnabled && [self.globalTextfield.text isEqualToString:@""]) {
        [self showAlertWithTitle:@"International Shipping" andMsg:@"Enter an international shipping price or disable internation shipping"];
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
@end
