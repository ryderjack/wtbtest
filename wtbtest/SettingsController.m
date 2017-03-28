//
//  SettingsController.m
//  wtbtest
//
//  Created by Jack Ryder on 27/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "SettingsController.h"
#import <Crashlytics/Crashlytics.h>
#import "UIImage+Resize.h"

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
    self.usernameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.lastNameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.emailCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.currencyCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.depopCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.contactEmailCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.emailFields.delegate = self;
    self.depopField.delegate = self;
    self.contactEmailField.delegate = self;
    self.firstNameField.delegate = self;
    self.lastNameField.delegate = self;

    self.profanityList = @[@"fuck",@"fucking",@"shitting", @"cunt", @"sex", @"wanker", @"nigger", @"penis", @"cock", @"shit", @"dick", @"bastard"];
    
    [self setImageBorder:self.testingView];
    
    self.currentUser = [PFUser currentUser];
    
    self.currentPaypal = [self.currentUser objectForKey:@"paypal"];
    self.currentContact = [self.currentUser objectForKey:@"email"];
    
    self.usernameLabel.text = [NSString stringWithFormat:@"Username: %@",self.currentUser.username];
    
    if ([self.currentUser objectForKey:@"firstName"]) {
        self.firstNameField.placeholder = [NSString stringWithFormat:@"First: %@",[self.currentUser objectForKey:@"firstName"]];
    }
    else{
        self.firstNameField.placeholder = [NSString stringWithFormat:@"First: %@",[self.currentUser objectForKey:@"fullname"]];
    }
    
    if ([self.currentUser objectForKey:@"lastName"]) {
        self.lastNameField.placeholder = [NSString stringWithFormat:@"Last: %@",[self.currentUser objectForKey:@"lastName"]];
    }
    
    
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
    
    NSString *currency = [self.currentUser objectForKey:@"currency"];
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
    
    NSString *depopHan = [self.currentUser objectForKey:@"depopHandle"];
    
    if ([self.currentUser objectForKey:@"depopHandle"]) {
        self.depopField.placeholder = [NSString stringWithFormat:@"Depop: %@", depopHan];
    }
    else{
        self.depopField.placeholder = @"Enter Depop username";
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.testingView setFile:[self.currentUser objectForKey:@"picture"]];
    [self.testingView loadInBackground];
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Settings",
                                      }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    }
    else if (section == 1){
        return 4;
    }
    else if (section == 2){
        return 1;
    }
    else if (section == 3){
        return 1;
    }
    else{
       return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return self.usernameCell;
        }
        else if (indexPath.row == 1) {
            return self.nameCell;
        }
        else if (indexPath.row == 2) {
            return self.lastNameCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.contactEmailCell;
        }
        else if (indexPath.row == 1) {
            return self.emailCell;
        }
        else if (indexPath.row == 2) {
            return self.addressCell;
        }
        else if (indexPath.row == 3) {
            return self.pictureCelll;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return self.currencyCell;
        }
    }
    else if (indexPath.section == 3){
        if (indexPath.row == 0) {
            return self.depopCell;
        }
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        if (indexPath.row == 2) {
            //goto shipping controller
            ShippingController *vc = [[ShippingController alloc]init];
            vc.delegate = self;
            vc.settingsMode = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if (indexPath.row == 3){
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

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    NSLog(@"INFO: %@", info);
    
    self.profileImage = info[UIImagePickerControllerOriginalImage];
    [self showHUD];
//    UIImage *imageToSave = [self.profileImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(750.0, 750.0) interpolationQuality:kCGInterpolationHigh];
    UIImage *imageToSave = [self.profileImage scaleImageToSize:CGSizeMake(750, 750)];

    
    NSData* data = UIImageJPEGRepresentation(imageToSave, 0.7f);
    if (data == nil) {
        NSLog(@"error with data");
        [self hideHUD];
        [picker dismissViewControllerAnimated:YES completion:nil];
        [self showAlertWithTitle:@"Image Error" andMsg:@"Woops, something went wrong. Please try again! If this keeps happening please message Team Bump from your profile"];
        [Answers logCustomEventWithName:@"PFFile Nil Data"
                       customAttributes:@{
                                          @"pageName":@"settings"
                                          }];
    }
    else{
//        self.testingView.image = nil;
        PFFile *filePicture = [PFFile fileWithName:@"picture.jpg" data:data];
        [filePicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                [self.testingView setFile:filePicture];
                [self.testingView loadInBackground];
                
                self.currentUser [@"picture"] = filePicture;
                [self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        NSLog(@"saved!");
                        [self hideHUD];
                    }
                    else{
                        NSLog(@"error saving %@", error);
                        [self hideHUD];
                    }
                }];
            }
            else{
                NSLog(@"error saving file %@", error);
                [self hideHUD];
            }
        }];
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
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
    else if (textField == self.firstNameField){
        NSString *stringCheck = [self.firstNameField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (![stringCheck isEqualToString:@""]) {
            NSArray *names = [self.firstNameField.text componentsSeparatedByString:@" "];
            
            if (![names containsObject:self.profanityList]) {
                [self.currentUser setObject:[self.firstNameField.text capitalizedString] forKey:@"firstName"];
                [self.currentUser saveInBackground];
            }
        }
        self.navigationItem.hidesBackButton = NO;
    }
    else if (textField == self.lastNameField){
        NSString *stringCheck = [self.lastNameField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (![stringCheck isEqualToString:@""]) {
            NSArray *names = [self.lastNameField.text componentsSeparatedByString:@" "];
            
            if (![names containsObject:self.profanityList]) {
                [self.currentUser setObject:[self.lastNameField.text capitalizedString] forKey:@"lastName"];
                [self.currentUser saveInBackground];
            }
        }
        self.navigationItem.hidesBackButton = NO;
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
        [self.currentUser  setObject:self.selectedCurrency forKey:@"currency"];
    }
    
    NSString *depopString = [self.depopField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (![depopString isEqualToString:@""]) {
        [Answers logCustomEventWithName:@"Entered Depop handle"
                       customAttributes:@{}];
        //entered a depop account
        NSString *depopHandle = [self.depopField.text stringByReplacingOccurrencesOfString:@"@" withString:@""];
        depopHandle = [depopHandle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.currentUser [@"depopHandle"] = depopHandle;
        
        PFQuery *depopQuery = [PFQuery queryWithClassName:@"Depop"];
        [depopQuery whereKey:@"user" equalTo:self.currentUser ];
        [depopQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
//                NSLog(@"already entered their depop handle at some point, update it here");
                object[@"handle"] = depopHandle;
                [object saveInBackground];
            }
            else{
//                NSLog(@"no depop handle currently saved so create a new one");
                PFObject *depopObj = [PFObject objectWithClassName:@"Depop"];
                depopObj[@"user"] = self.currentUser ;
                depopObj[@"handle"] = depopHandle;
                NSLog(@"saving");
                [depopObj saveInBackground];
            }
        }];
    }
    else{
        //entered blank depop handle
    }
    
    [self.currentUser setObject:@"YES" forKey:@"paypalUpdated"];
    [self.currentUser saveInBackground];
    [self hideHUD];
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
    if (section ==2){
        header.textLabel.text = @"  Currency";
    }
    else if (section == 1){
        header.textLabel.text = @"  Account";
    }
    else if (section == 3){
        header.textLabel.text = @"  Other";
    }
    else if (section == 0){
        header.textLabel.text = @"  Me";
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    if (section ==2){
        return @"  Currency";
    }
    else if (section == 0){
        return @"  Me";
    }
    else if (section == 1){
        return @"  Account";
    }
    else if (section == 3){
        return @"  Other";
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

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    if (!self.spinner) {
        self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    }
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

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}
@end
