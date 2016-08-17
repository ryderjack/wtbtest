//
//  SettingsController.m
//  wtbtest
//
//  Created by Jack Ryder on 27/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "SettingsController.h"


@interface SettingsController ()

@end

@implementation SettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.navigationItem.title = @"Settings";
    
    self.nameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.emailCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.addressCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.currencyCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.emailFields.delegate = self;
    
    self.currentUser = [PFUser currentUser];
    
    self.currentEmail = [self.currentUser objectForKey:@"email"];
    
    self.nameLabel.text = [NSString stringWithFormat:@"Name: %@",[self.currentUser objectForKey:@"fullname"]];
    self.emailFields.placeholder = [NSString stringWithFormat:@"PayPal email: %@",self.currentEmail];
    
    if ([self.currentUser objectForKey:@"building"]) {
        //address been set before
        self.addLabel.text = [NSString stringWithFormat:@"%@ %@ %@ %@ %@",[self.currentUser objectForKey:@"building"], [self.currentUser objectForKey:@"street"], [self.currentUser objectForKey:@"city"], [self.currentUser objectForKey:@"postcode"], [self.currentUser objectForKey:@"phonenumber"]];
    }
    else{
        self.addLabel.text = @"Address";
    }
    
    NSString *currency = [[PFUser currentUser]objectForKey:@"currency"];
    if ([currency isEqualToString:@"GBP"]) {
        [self.GBPButton setSelected:YES];
    }
    else if ([currency isEqualToString:@"USD"]) {
        [self.USDButton setSelected:YES];
    }
    else if ([currency isEqualToString:@"AUD"]) {
        [self.AUDButton setSelected:YES];
    }
    self.selectedCurrency = @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    }
    else if (section == 1){
        return 1;
    }
    else{
       return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return self.nameCell;
        }
        else if (indexPath.row == 1) {
            return self.emailCell;
        }
        else if (indexPath.row == 2) {
            return self.addressCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.currencyCell;
        }
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 2) {
            //goto shipping controller
            ShippingController *vc = [[ShippingController alloc]init];
            vc.delegate = self;
            vc.settingsMode = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

-(void)addItemViewController:(ShippingController *)controller didFinishEnteringAddress:(NSString *)address{
    self.addLabel.text = address;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.emailFields && ![textField.text isEqualToString:@""]) {
        if ([self NSStringIsValidEmail:self.emailFields.text] == YES) {
            [self.currentUser setObject:self.emailFields.text forKey:@"email"];
            [self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (error.code == 203) {
                    self.emailFields.text = self.currentEmail;
                    [self.currentUser saveInBackground];
                    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Invalid email" message:@"This email address is already in use. Please try another email." preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    }]];
                    
                    [self presentViewController:alertView animated:YES completion:^{
                       self.navigationItem.hidesBackButton = NO;
                    }];
                }
                else{
                    self.navigationItem.hidesBackButton = NO;
                }
            }];
        }
        else{
            self.emailFields.text = self.currentEmail;
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Invalid email" message:@"Please enter a valid email address. If you think this is a mistake please get in touch!" preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [self presentViewController:alertView animated:YES completion:^{
                self.navigationItem.hidesBackButton = NO;
            }];
        }
    }
    else{
        self.navigationItem.hidesBackButton = NO;
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(void)viewWillDisappear:(BOOL)animated{
    if (![self.selectedCurrency isEqualToString:@""]) {
        [[PFUser currentUser] setObject:self.selectedCurrency forKey:@"currency"];
        [[PFUser currentUser]saveInBackground];
    }
}

- (IBAction)GBPPressed:(id)sender {
    if (self.GBPButton.selected == YES) {
    }
    else{
        self.selectedCurrency = @"GBP";
        [self.GBPButton setSelected:YES];
        [self.AUDButton setSelected:NO];
        [self.USDButton setSelected:NO];
    }
}
- (IBAction)USDPressed:(id)sender {
    if (self.USDButton.selected == YES) {
    }
    else{
        self.selectedCurrency = @"USD";
        [self.USDButton setSelected:YES];
        [self.AUDButton setSelected:NO];
        [self.GBPButton setSelected:NO];
    }
}
- (IBAction)AUDPressed:(id)sender {
    if (self.AUDButton.selected == YES) {
    }
    else{
        self.selectedCurrency = @"AUD";
        [self.AUDButton setSelected:YES];
        [self.GBPButton setSelected:NO];
        [self.USDButton setSelected:NO];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    header.textLabel.textColor = [UIColor grayColor];
    header.textLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:12];
    CGRect headerFrame = header.frame;
    header.textLabel.frame = headerFrame;
    header.contentView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    if (section ==1){
        header.textLabel.text = @"    Currency";
    }
    else if (section == 0){
        header.textLabel.text = @"    Account";
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    if (section ==1){
        return @"    Currency";
    }
    else if (section == 0){
        return @"    Account";
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{

    return 32.0f;
}

-(BOOL) NSStringIsValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = NO;
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    self.navigationItem.hidesBackButton = YES;
}
@end
