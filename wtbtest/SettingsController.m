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
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.navigationItem.title = @"S E T T I N G S";
    
    self.nameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.emailCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.currencyCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.depopCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.contactEmailCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.emailFields.delegate = self;
    self.depopField.delegate = self;
    self.contactEmailField.delegate = self;
    
    [self setImageBorder:self.testingView];
    
    self.currentUser = [PFUser currentUser];
    
    self.currentPaypal = [self.currentUser objectForKey:@"paypal"];
    self.currentContact = [self.currentUser objectForKey:@"email"];
    
    self.nameLabel.text = [NSString stringWithFormat:@"Name: %@",[self.currentUser objectForKey:@"fullname"]];
    
    //check if got paypal email
    if ([self.currentUser objectForKey:@"paypal"]) {
        self.emailFields.placeholder = [NSString stringWithFormat:@"PayPal: %@",self.currentPaypal];
    }
    else{
        self.emailFields.placeholder = @"Enter your PayPal email";
    }
    
    self.contactEmailField.placeholder = [NSString stringWithFormat:@"Email: %@",self.currentContact];
    
    if ([self.currentUser objectForKey:@"building"]) {
        //address been set before
        self.addLabel.text = [NSString stringWithFormat:@"Address: %@ %@ %@ %@ %@",[self.currentUser objectForKey:@"building"], [self.currentUser objectForKey:@"street"], [self.currentUser objectForKey:@"city"], [self.currentUser objectForKey:@"postcode"], [self.currentUser objectForKey:@"phonenumber"]];
    }
    else{
        self.addLabel.text = @"Enter address";
    }
    
    NSString *currency = [[PFUser currentUser]objectForKey:@"currency"];
    if ([currency isEqualToString:@"GBP"]) {
        [self.GBPButton setSelected:YES];
    }
    else if ([currency isEqualToString:@"USD"]) {
        [self.USDButton setSelected:YES];
    }
    else if ([currency isEqualToString:@"EUR"]) {
        [self.EURButton setSelected:YES];
    }
    self.selectedCurrency = @"";
    
    NSString *depopHan = [[PFUser currentUser]objectForKey:@"depopHandle"];
    
    if ([self.currentUser objectForKey:@"depopHandle"]) {
        self.depopField.placeholder = [NSString stringWithFormat:@"Depop: %@", depopHan];
    }
    else{
        self.depopField.placeholder = @"Enter Depop username";
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.testingView setFile:[[PFUser currentUser]objectForKey:@"picture"]];
    [self.testingView loadInBackground];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 5;
    }
    else if (section == 1){
        return 1;
    }
    else if (section == 2){
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
            return self.contactEmailCell;
        }
        else if (indexPath.row == 2) {
            return self.emailCell;
        }
        else if (indexPath.row == 3) {
            return self.addressCell;
        }
        else if (indexPath.row == 4) {
            return self.pictureCelll;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.currencyCell;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return self.depopCell;
        }
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 3) {
            //goto shipping controller
            ShippingController *vc = [[ShippingController alloc]init];
            vc.delegate = self;
            vc.settingsMode = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if (indexPath.row == 4){
            if (!self.picker) {
                self.picker = [[UIImagePickerController alloc] init];
                self.picker.delegate = self;
                self.picker.allowsEditing = NO;
                self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            }
            [self presentViewController:self.picker animated:YES completion:nil];
        }
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.profileImage = info[UIImagePickerControllerOriginalImage];
    self.testingView.image = nil;
    
    PFFile *filePicture = [PFFile fileWithName:@"picture.jpg" data:UIImageJPEGRepresentation(self.profileImage, 0.6)];
    [filePicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         if (error) {
             NSLog(@"error %@", error);
         }
         else{
             [self.testingView setFile:filePicture];
             [self.testingView loadInBackground];
             
             [PFUser currentUser][@"picture"] = filePicture;
             [[PFUser currentUser]saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                 if (succeeded) {
                     NSLog(@"saved!");
                 }
                 else{
                     NSLog(@"error saving %@", error);
                 }
             }];
         }
     }];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.emailFields && ![textField.text isEqualToString:@""]) {
        if ([self NSStringIsValidEmail:self.emailFields.text] == YES) {
            [self.currentUser setObject:self.emailFields.text forKey:@"paypal"];
            [self.currentUser setObject:@"YES" forKey:@"paypalUpdated"];
            
            [self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (error.code == 203) {
                    self.emailFields.text = self.currentPaypal;
                    
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
            self.emailFields.text = self.currentPaypal;
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Invalid email" message:@"Please enter a valid email address. If you think this is a mistake please get in touch!" preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [self presentViewController:alertView animated:YES completion:^{
                self.navigationItem.hidesBackButton = NO;
            }];
        }
    }
    
    else if (textField == self.contactEmailField && ![textField.text isEqualToString:@""]){
        if ([self NSStringIsValidEmail:self.contactEmailField.text] == YES) {
            [self.currentUser setObject:self.contactEmailField.text forKey:@"email"];
            [self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (error.code == 203) {
                    self.contactEmailField.text = self.currentContact;

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
            self.emailFields.text = self.currentContact;
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
    }
    
    NSString *depopString = [self.depopField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (![depopString isEqualToString:@""]) {
        //entered a depop account
        NSString *depopHandle = [self.depopField.text stringByReplacingOccurrencesOfString:@"@" withString:@""];
        depopHandle = [depopHandle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [PFUser currentUser][@"depopHandle"] = depopHandle;
        
        PFQuery *depopQuery = [PFQuery queryWithClassName:@"Depop"];
        [depopQuery whereKey:@"user" equalTo:[PFUser currentUser]];
        [depopQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
//                NSLog(@"already entered their depop handle at some point, update it here");
                object[@"handle"] = depopHandle;
                [object saveInBackground];
            }
            else{
//                NSLog(@"no depop handle currently saved so create a new one");
                PFObject *depopObj = [PFObject objectWithClassName:@"Depop"];
                depopObj[@"user"] = [PFUser currentUser];
                depopObj[@"handle"] = depopHandle;
                NSLog(@"saving");
                [depopObj saveInBackground];
            }
        }];
    }
    else{
        //entered blank depop handle
    }
    [[PFUser currentUser]saveInBackground];
}

- (IBAction)GBPPressed:(id)sender {
    if (self.GBPButton.selected == YES) {
    }
    else{
        self.selectedCurrency = @"GBP";
        [self.GBPButton setSelected:YES];
        [self.EURButton setSelected:NO];
        [self.USDButton setSelected:NO];
    }
}
- (IBAction)USDPressed:(id)sender {
    if (self.USDButton.selected == YES) {
    }
    else{
        self.selectedCurrency = @"USD";
        [self.USDButton setSelected:YES];
        [self.EURButton setSelected:NO];
        [self.GBPButton setSelected:NO];
    }
}
- (IBAction)EURPressed:(id)sender {
    if (self.EURButton.selected == YES) {
    }
    else{
        self.selectedCurrency = @"EUR";
        [self.EURButton setSelected:YES];
        [self.GBPButton setSelected:NO];
        [self.USDButton setSelected:NO];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    header.textLabel.textColor = [UIColor grayColor];
    header.textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    CGRect headerFrame = header.frame;
    header.textLabel.frame = headerFrame;
    header.contentView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    if (section ==1){
        header.textLabel.text = @"    Currency";
    }
    else if (section == 0){
        header.textLabel.text = @"    Account";
    }
    else if (section == 2){
        header.textLabel.text = @"    Depop";
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    if (section ==1){
        return @"    Currency";
    }
    else if (section == 0){
        return @"    Account";
    }
    else if (section == 2){
        return @"    Depop";
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

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = 20;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)addItemViewController:(ShippingController *)controller didFinishEnteringAddress:(NSString *)address{
    self.addLabel.text = address;
}
@end
