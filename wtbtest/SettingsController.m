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
#import "AppConstant.h"
#import "UIImageView+Letters.h"
#import <CLPlacemark+HZContinents.h>

@interface SettingsController ()

@end

@implementation SettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    self.navigationItem.title = @"S E T T I N G S";
    
    self.nameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.usernameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.lastNameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.emailCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.currencyCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.depopCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.contactEmailCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.cmoCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.listAsCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.sellerModeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.notificationsCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.locationLabelCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.bioCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.currencySwipeCell.selectionStyle = UITableViewCellSelectionStyleNone;

    self.emailFields.delegate = self;
    self.depopField.delegate = self;
    self.contactEmailField.delegate = self;
    self.firstNameField.delegate = self;
    self.lastNameField.delegate = self;
    self.bioField.delegate = self;
    
    self.profanityList = @[@"fuck",@"fucking",@"shitting", @"cunt", @"sex", @"wanker", @"nigger", @"penis", @"cock", @"shit", @"dick", @"bastard", @"bump", @"terrible", @"bad", @"depop", @"grailed", @"ebay"];
    self.currencyArray = @[@"GBP", @"USD", @"EUR", @"AUD"];
    
    self.currentUser = [PFUser currentUser];

    //currency swipe view
    self.currencySwipeView.delegate = self;
    self.currencySwipeView.dataSource = self;
    self.currencySwipeView.clipsToBounds = YES;
    self.currencySwipeView.pagingEnabled = NO;
    self.currencySwipeView.truncateFinalPage = NO;
    [self.currencySwipeView setBackgroundColor:[UIColor clearColor]];
    self.currencySwipeView.alignment = SwipeViewAlignmentEdge;
    
    NSString *currency = [self.currentUser objectForKey:@"currency"];
    
    if ([self.currencyArray containsObject:currency]) {
        self.selectedCurrency = currency;
    }
    else{
        self.selectedCurrency = @"";
    }
    
    [self.currencySwipeView reloadData];
    
    [self setImageBorder:self.testingView];
    
    self.currentPaypal = [self.currentUser objectForKey:@"paypal"];
    self.currentContact = [self.currentUser objectForKey:@"email"];
    
    self.usernameLabel.text = [NSString stringWithFormat:@"@%@",self.currentUser.username];
    
    if ([self.currentUser objectForKey:@"firstName"]) {
        self.firstNameField.text = [NSString stringWithFormat:@"%@",[self.currentUser objectForKey:@"firstName"]];
    }
    else{
        self.firstNameField.text = [NSString stringWithFormat:@"%@",[self.currentUser objectForKey:@"fullname"]];
    }
    
    if ([self.currentUser objectForKey:@"lastName"]) {
        self.lastNameField.text = [NSString stringWithFormat:@"%@",[self.currentUser objectForKey:@"lastName"]];
    }
    
    
    //check if got paypal email
    if ([self.currentUser objectForKey:@"paypal"]) {
        self.emailFields.text = [NSString stringWithFormat:@"%@",self.currentPaypal];
    }
    else{
        self.emailFields.placeholder = @"Enter";
    }
    
    //check if got a bio
    if ([self.currentUser objectForKey:@"bio"]) {
        if (![[self.currentUser objectForKey:@"bio"] isEqualToString:@""]) {
            self.bioField.text = [NSString stringWithFormat:@"%@",[self.currentUser objectForKey:@"bio"]];
        }
    }
    else{
        self.bioField.placeholder = @"Enter";
    }
    
    //check if got profile location
    
    if ([self.currentUser objectForKey:@"profileLocation"]) {
        self.locLabel.text = [NSString stringWithFormat:@"%@",[self.currentUser objectForKey:@"profileLocation"]];
    }
    else{
        self.locLabel.text = @"Enter";
    }
    
    self.contactEmailField.text = [NSString stringWithFormat:@"%@",self.currentContact];
    
    if ([[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"]|| [[PFUser currentUser].objectId isEqualToString:@"IIEf7cUvrO"]) {
        //CMO switch setup
        if ([[NSUserDefaults standardUserDefaults]boolForKey:@"CMOModeOn"]==YES) {
            [self.cmoSwitch setOn:YES];
        }
        else{
            [self.cmoSwitch setOn:NO];
        }
        
        //list as X setup
        if ([[NSUserDefaults standardUserDefaults]boolForKey:@"listMode"]==YES) {
            [self.listAsSwitch setOn:YES];
        }
        else{
            [self.listAsSwitch setOn:NO];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setHidden:NO];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if (![self.currentUser objectForKey:@"picture"]) {
        self.changePictureLabel.text = @"Add a profile picture";
        
        NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:15],
                                        NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
        
        [self.testingView setImageWithString:self.currentUser.username color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes];
    }
    else{
        self.changePictureLabel.text = @"Change profile picture";

        [self.testingView setFile:[self.currentUser objectForKey:@"picture"]];
        [self.testingView loadInBackground];
    }

    //setup notifications
    
    //check if any push on
    if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
        [self.pushStatusButton setEnabled:NO];
        [self.pushStatusButton setTitle:@"Push enabled" forState:UIControlStateNormal];

        //push is on
        //check if already ignoring like pushes
        if ([[self.currentUser objectForKey:@"ignoreLikePushes"]isEqualToString:@"YES"]) {
            [self.likeSwitch setOn:NO];
        }
        else{
            [self.likeSwitch setOn:YES];
        }
        
        //check if have facebookId
        if ([self.currentUser objectForKey:@"facebookId"]) {
            if ([[self.currentUser objectForKey:@"ignoreFacebookPushes"]isEqualToString:@"YES"]) {
                [self.fbFriendSwitch setOn:NO];
            }
            else{
                [self.fbFriendSwitch setOn:YES];
            }
        }
        else{
            [self.fbFriendSwitch setOn:NO];
            [self.fbFriendSwitch setEnabled:NO];
        }
        
    }
    else{
        //push is off
        [self.pushStatusButton setEnabled:YES];
        [self.pushStatusButton setTitle:@"Tap to enable Push" forState:UIControlStateNormal];
        
        [self.likeSwitch setEnabled:NO];
        [self.fbFriendSwitch setEnabled:NO];
    }

    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Settings",
                                      }];
    
    if (self.locationAddMode) {
        self.locationAddMode = NO;
        self.autoPopMode = YES;
        
        LocationView *vc = [[LocationView alloc]init];
        vc.delegate = self;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.bioMode) {
        self.bioMode = NO;
        [self.bioField becomeFirstResponder];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"]|| [[PFUser currentUser].objectId isEqualToString:@"IIEf7cUvrO"]) {
        return 5;
    }
    else{
        return 4;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 5;
    }
    else if (section == 1){
        return 3;
    }
    else if (section == 2){
        return 1;
    }
    else if (section == 3){
        return 1;
    }
    else if (section == 4){
        return 3;
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
        else if (indexPath.row == 3) {
            return self.locationLabelCell;
        }
        else if (indexPath.row == 4) {
            return self.bioCell;
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
            return self.pictureCelll;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return self.currencySwipeCell;
        }
    }
//    else if (indexPath.section == 3){
//        if (indexPath.row == 0) {
//            return self.locationCell;
//        }
//    }
    else if (indexPath.section == 3){
        if (indexPath.row == 0) {
            return self.notificationsCell;
        }
    }
    else if (indexPath.section == 4){
        if (indexPath.row == 0) {
            return self.cmoCell;
        }
        else if (indexPath.row == 1) {
            return self.listAsCell;
        }
        else if (indexPath.row == 2) {
            return self.sellerModeCell;
        }
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
//        if (indexPath.row == 2) {
//            //goto shipping controller
//            ShippingController *vc = [[ShippingController alloc]init];
//            vc.delegate = self;
//            vc.settingsMode = YES;
//            [self.navigationController pushViewController:vc animated:YES];
//        }
        if (indexPath.row == 2){
            if (!self.picker) {
                self.picker = [[UIImagePickerController alloc] init];
                self.picker.delegate = self;
                self.picker.allowsEditing = NO;
                self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            }
            [self presentViewController:self.picker animated:YES completion:nil];
        }
    }
    else if (indexPath.section == 0){
        if (indexPath.row == 3){
            //goto location
            
            LocationView *vc = [[LocationView alloc]init];
            vc.delegate = self;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    self.profileImage = info[UIImagePickerControllerOriginalImage];
    [self showHUD];
//    UIImage *imageToSave = [self.profileImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(750.0, 750.0) interpolationQuality:kCGInterpolationHigh];
    UIImage *imageToSave = [self.profileImage scaleImageToSize:CGSizeMake(400, 400)];
    
    NSData* data = UIImageJPEGRepresentation(imageToSave, 0.7f);
    if (data == nil) {
        NSLog(@"error with data");
        [self hideHUD];
        [picker dismissViewControllerAnimated:YES completion:nil];
        [self showAlertWithTitle:@"Image Error" andMsg:@"Woops, something went wrong. Please try again! If this keeps happening please message Team Bump from Settings"];
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
                        
                        [self updateConvoImages];
                        
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
                
                [Answers logCustomEventWithName:@"Error saving profile PFFile"
                               customAttributes:@{
                                                  @"where":@"Settings"
                                                  }];
            }
        }];
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)textFieldDidEndEditing:(UITextField *)textField{

    //paypal
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
                    }];
                }
                else{
                }
            }];
        }
        else{
            self.emailFields.text = self.currentPaypal;
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Invalid email" message:@"Please enter a valid email address. If you think this is a mistake please get in touch!" preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [self presentViewController:alertView animated:YES completion:nil];
        }
    }
    
    else if (textField == self.contactEmailField && ![textField.text isEqualToString:@""]){
       
        if ([self NSStringIsValidEmail:self.contactEmailField.text] == YES) {
            [self.currentUser setObject:self.contactEmailField.text forKey:@"email"];
            [self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (error.code == 203) {
                    self.contactEmailField.text = @"";

                    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Invalid email" message:@"This email address is already in use. Please try another email." preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    }]];
                    
                    [self presentViewController:alertView animated:YES completion:nil];
                }
            }];
        }
        else{
            self.contactEmailField.text = @"";
            
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Invalid email" message:@"Please enter a valid email address. If you think this is a mistake please send Team Bump a message!" preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [self presentViewController:alertView animated:YES completion:nil];
        }
    }
    else if (textField == self.firstNameField){
        NSString *stringCheck = [self.firstNameField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (![stringCheck isEqualToString:@""] && ![[stringCheck lowercaseString] isEqualToString:@"team"] && ![[stringCheck lowercaseString] isEqualToString:@"bump"]) {
            
            for (NSString *profan in self.profanityList) {
                if ([[self.firstNameField.text lowercaseString] containsString:profan]) {
                    self.firstNameField.text = @"";
                }
            }
            
            if (![self.firstNameField.text isEqualToString:@""]) {
                self.changedName = YES;
                [self.currentUser setObject:[self.firstNameField.text capitalizedString] forKey:@"firstName"];
                [self.currentUser saveInBackground];
            }
            
        }
    }
    else if (textField == self.lastNameField){
        NSString *stringCheck = [self.lastNameField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (![stringCheck isEqualToString:@""] && ![[stringCheck lowercaseString] isEqualToString:@"bump"]) {

            for (NSString *profan in self.profanityList) {
                if ([[self.lastNameField.text lowercaseString] containsString:profan]) {
                    self.lastNameField.text = @"";
                }
            }
            
            if (![self.lastNameField.text isEqualToString:@""]) {
                self.changedName = YES;
                [self.currentUser setObject:[self.lastNameField.text capitalizedString] forKey:@"lastName"];
                [self.currentUser saveInBackground];
            }
        }
    }
    else if (textField == self.bioField){
        [Answers logCustomEventWithName:@"Updated bio in Settings"
                       customAttributes:@{}];
        
        for (NSString *profan in self.profanityList) {
            if ([[self.bioField.text lowercaseString] containsString:profan]) {
                self.bioField.text = @"";
            }
        }
        [self.currentUser setObject:self.bioField.text forKey:@"bio"];
        [self.currentUser saveInBackground];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    //limit chars
    if ([self.profanityList containsObject:string]) {
        return  NO;
    }
    
    if(range.length + range.location > textField.text.length)
    {
        return NO;
    }
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return newLength <= 30;
}

-(void)viewWillDisappear:(BOOL)animated{
    //fail safe
    [self hideHUD];

    if (self.currencyChanged) {
        [self.currentUser  setObject:self.selectedCurrency forKey:@"currency"];
    }
    
    if (self.changedName) {
        
        //check for profanity
        //concatonate first & last names for fullname and fullnameLower
        NSString *fullnameString = @"";
        
        if ([self.firstNameField.text isEqualToString:@""]) {
            //only changed last name
            fullnameString = [NSString stringWithFormat:@"%@ %@",[[self.firstNameField.placeholder capitalizedString]stringByReplacingOccurrencesOfString:@"First: " withString:@""],[self.lastNameField.text capitalizedString]];
        }
        else if ([self.lastNameField.text isEqualToString:@""]) {
            //only changed first name
            fullnameString = [NSString stringWithFormat:@"%@ %@",[self.firstNameField.text capitalizedString],[[self.lastNameField.placeholder capitalizedString]stringByReplacingOccurrencesOfString:@"Last: " withString:@""]];
        }
        else{
            //changed full name
            fullnameString = [NSString stringWithFormat:@"%@ %@",[self.firstNameField.text capitalizedString],[self.lastNameField.text capitalizedString]];
        }
        
        [PFUser currentUser][PF_USER_FULLNAME] = fullnameString;
        [PFUser currentUser][@"fullnameLower"] = [fullnameString lowercaseString];
        [[PFUser currentUser]saveInBackground];
    }
    
    if (self.changedFbPush) {
        //query for bumped object and turn off / on
        PFQuery *bumpedQuery = [PFQuery queryWithClassName:@"Bumped"];
        [bumpedQuery whereKey:@"user" equalTo:self.currentUser];
        [bumpedQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if(objects.count > 0){
                
                for (PFObject *bumped in objects) {
                    if (self.fbFriendSwitch.isOn == YES) {
                        //set to on
                        [bumped setObject:@"live" forKey:@"status"];
                    }
                    else{
                        //set to ignore
                        [bumped setObject:@"ignore" forKey:@"status"];
                    }
                    [bumped saveInBackground];
                }
            }
        }];
    }
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

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *header;
    
    if (@available(iOS 11.0, *)) {
        if ([ [ UIScreen mainScreen ] bounds ].size.width == 375) {
            //iPhone6/7
            header = [[UIView alloc]initWithFrame:CGRectMake(16, 0, self.tableView.frame.size.width, 32)];
        }
        else if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
            //iPhone 6 plus
            header = [[UIView alloc]initWithFrame:CGRectMake(20, 0, self.tableView.frame.size.width, 32)];
        }
        else if([ [ UIScreen mainScreen ] bounds ].size.width == 320){
            //iPhone 4/5
            header = [[UIView alloc]initWithFrame:CGRectMake(16, 0, self.tableView.frame.size.width, 32)];
        }
        else{
            //fall back
            header = [[UIView alloc]initWithFrame:CGRectMake(16, 0, self.tableView.frame.size.width, 32)];
        }
    }
    else{
        header = [[UIView alloc]initWithFrame:CGRectMake(8, 0, self.tableView.frame.size.width, 32)];
    }
    UILabel *textLabel = [[UILabel alloc]initWithFrame:header.frame];
    textLabel.textColor = [UIColor grayColor];
    textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    header.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    [header addSubview:textLabel];
    if (section ==2){
        textLabel.text = @"Currency";
    }
    else if (section == 1){
        textLabel.text = @"Account";
    }
    else if (section == 4){
        textLabel.text = @"Other";
    }
    else if (section == 3){
        textLabel.text = @"Notifications";
    }
    else if (section == 0){
        textLabel.text = @"Me";
    }
    
    return header;
}

//- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
//    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
//
//    header.textLabel.textColor = [UIColor grayColor];
//    header.textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
//    CGRect headerFrame = header.frame;
//    header.textLabel.frame = headerFrame;
//    header.contentView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
//    if (section ==2){
//        header.textLabel.text = @"  Currency";
//    }
//    else if (section == 1){
//        header.textLabel.text = @"  Account";
//    }
//    else if (section == 4){
//        header.textLabel.text = @"  Other";
//    }
////    else if (section == 3){
////        header.textLabel.text = @"  Location";
////    }
//    else if (section == 3){
//        header.textLabel.text = @"  Notifications";
//    }
//    else if (section == 0){
//        header.textLabel.text = @"  Me";
//    }
//}
//
//-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//
//    if (section ==2){
//        return @"  Currency";
//    }
//    else if (section == 0){
//        return @"  Me";
//    }
//    else if (section == 1){
//        return @"  Account";
//    }
////    else if (section == 3){
////        return @"  Location";
////    }
//    else if (section == 3){
//        return @"  Notifications";
//    }
//    else if (section == 4){
//        return @"  Other";
//    }
//
//    return nil;
//}

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
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}
- (IBAction)cmoSwitchChanged:(id)sender {
    if (self.cmoSwitch.on == YES) {
        NSLog(@"ON");
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CMOModeOn"];
    }
    else{
        NSLog(@"OFF");
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CMOModeOn"];
    }
}
- (IBAction)listAsSwitchChanged:(id)sender {
    if (self.listAsSwitch.on == YES) {
        NSLog(@"ON");
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"listMode"];
        
        //prompt for user ID to retrieve
        [self userPrompt];
    }
    else{
        NSLog(@"OFF");
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"listMode"];
    }
}
- (IBAction)sellerModeSwitchChanged:(id)sender {
    if (self.sellerModeSwitch.on == YES) {
        NSLog(@"ON");
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"notSellerMode"];
    }
    else{
        NSLog(@"OFF");
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"notSellerMode"];
    }
}

-(void)userPrompt{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"List items as?"
                                          message:@"Enter username (no spaces)"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = @"username";
     }];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:@"DONE"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   UITextField *usernameField = alertController.textFields.firstObject;
                                   [self retrieveUser:usernameField.text];
                               }];
    
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)retrieveUser:(NSString*)username{
    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:@"username" equalTo:username];
    [userQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            [[NSUserDefaults standardUserDefaults] setObject:object.objectId forKey:@"listUser"];
        }
        else{
            [self.listAsSwitch setOn:NO];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"listMode"];
            [self showAlertWithTitle:@"NO USER" andMsg:[NSString stringWithFormat:@"ERROR %@", error]];
        }
    }];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 3) {
        return 130;
    }
    else{
        return 44;
    }
}
- (IBAction)likeSwitchPressed:(id)sender {
    self.changedPush = YES;
    
    if (self.likeSwitch.isOn == YES) {
        //switched on
        [self.currentUser setObject:@"NO" forKey:@"ignoreLikePushes"];
        
        [Answers logCustomEventWithName:@"Turned on Specific Push"
                       customAttributes:@{
                                          @"type":@"Likes",
                                          }];
    }
    else{
        //switched off
        [self.currentUser setObject:@"YES" forKey:@"ignoreLikePushes"];
        
        [Answers logCustomEventWithName:@"Turned off Specific Push"
                       customAttributes:@{
                                          @"type":@"Likes",
                                          }];
    }
}

- (IBAction)fbFriendSwitchPressed:(id)sender {
    self.changedPush = YES;
    
    if (self.fbFriendSwitch.isOn == YES) {
        //switched on
        [self.currentUser setObject:@"NO" forKey:@"ignoreFacebookPushes"];
        
        [Answers logCustomEventWithName:@"Turned on Specific Push"
                       customAttributes:@{
                                          @"type":@"Facebook",
                                          }];
    }
    else{
        //switched off
        [self.currentUser setObject:@"YES" forKey:@"ignoreFacebookPushes"];
        
        [Answers logCustomEventWithName:@"Turned off Specific Push"
                       customAttributes:@{
                                          @"type":@"Facebook",
                                          }];
    }
}
- (IBAction)pushEnablePressed:(id)sender {
    //if user has declined then show normal dialog, or take to settings
    [Answers logCustomEventWithName:@"Enable Push Pressed"
                   customAttributes:@{
                                      @"where":@"Settings",
                                      }];
    [self showPushPrompt];
}

#pragma push prompt methods

-(void)showPushPrompt{
    self.shownPushAlert = YES;
    self.searchBgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.searchBgView.alpha = 0.0;
    [self.searchBgView setBackgroundColor:[UIColor blackColor]];
    [[UIApplication sharedApplication].keyWindow addSubview:self.searchBgView];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.searchBgView.alpha = 0.6f;
                     }
                     completion:nil];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"customAlertView" owner:self options:nil];
    self.pushAlert = (customAlertViewClass *)[nib objectAtIndex:0];
    self.pushAlert.delegate = self;
    self.pushAlert.titleLabel.text = @"Enable Push";
    
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"declinedPushPermissions"]) {
        //show normal prompt
        self.pushAlert.messageLabel.text = @"Get notified when buyers message you on Bump";
        [self.pushAlert.secondButton setTitle:@"E N A B L E" forState:UIControlStateNormal];
        self.settingsMode = NO;
    }
    else{
        //show prompt to goto settings and turn push back on
        self.pushAlert.messageLabel.text = @"Get notified when buyers message you - Goto Settings now to enable Push";
        [self.pushAlert.secondButton setTitle:@"S E T T I N G S" forState:UIControlStateNormal];
        self.settingsMode = YES;
    }
    
    self.pushAlert.numberOfButtons = 2;
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, -157, 250, 157)];
    }
    else{
        [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, -188, 300, 188)]; //iPhone 6/7 specific
    }
    
    self.pushAlert.layer.cornerRadius = 10;
    self.pushAlert.layer.masksToBounds = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.pushAlert];
    
    [UIView animateWithDuration:0.5
                          delay:0.2
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.pushAlert setFrame:CGRectMake(0, 0, 250, 157)];
                            }
                            else{
                                [self.pushAlert setFrame:CGRectMake(0, 0, 300, 188)]; //iPhone 6/7 specific
                            }
                            self.pushAlert.center = self.view.center;
                            
                        }
                     completion:nil];
}

-(void)donePressed{
    //check push status
//    double delayInSeconds = 5.0;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        [self checkPushStatus];
//    });
//    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.searchBgView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         self.searchBgView = nil;
                     }];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, 1000, 250, 157)];
                            }
                            else{
                                [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, 1000, 300, 188)]; //iPhone 6/7 specific
                            }
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         [self.pushAlert setAlpha:0.0];
                         [self.pushAlert removeFromSuperview];
                         self.pushAlert = nil;
                     }];
}

#pragma custom alert delegates

-(void)firstPressed{
    //cancelled
    [self donePressed];
}
-(void)secondPressed{
    
    if (self.settingsMode == YES) {
        //take user to settings
        NSString *settings = UIApplicationOpenSettingsURLString;
        NSURL *settingsURL = [NSURL URLWithString:settings];
        [[UIApplication sharedApplication]openURL:settingsURL];
    }
    else{
        //push reminder
        [Answers logCustomEventWithName:@"Accepted Push Permissions"
                       customAttributes:@{
                                          @"mode":@"seller application",
                                          @"username":[PFUser currentUser].username
                                          }];
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"askedForPushPermission"];
        [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"declinedPushPermissions"];
        
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    [self donePressed];
}

#pragma mark - location delegates

-(void)selectedPlacemark:(CLPlacemark *)placemark{
    
    NSString *titleString;
    
    if (!placemark.locality) {
        titleString = [NSString stringWithFormat:@"%@",placemark.country];
    }
    else{
        titleString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
    }
    
    if (![titleString containsString:@"(null)"]) { //protect against saving erroneous location
        
        self.locLabel.text = titleString;
        
        [[PFUser currentUser]setObject:titleString forKey:@"profileLocation"];
        
        if (![[placemark continent] isEqualToString:@""]) {
            [[PFUser currentUser]setObject:[placemark continent] forKey:@"continent"];
        }
        
        //get geopoint for new location for this user's listings
        PFGeoPoint *geopoint = [PFGeoPoint geoPointWithLocation:placemark.location];
        if (geopoint) {
            [[PFUser currentUser]setObject:geopoint forKey:@"geopoint"];
        }
        
        if (![[placemark country]isEqualToString:@""]) {
            [[PFUser currentUser]setObject:[placemark country] forKey:@"country"];
            [[PFUser currentUser]setObject:[placemark ISOcountryCode] forKey:@"countryCode"];
        }
        
        [[PFUser currentUser]saveInBackground];
        
        //for when users are here from shipping vc and just need to quickly add a location
        if (self.autoPopMode) {
            self.autoPopMode = NO;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

-(void)updateConvoImages{
    //update user's top 20 recent convos to include the user's profile picture
    //query for convos where I'm the buyer then update buyerPicture & same for sellerPicture
   
    PFQuery *convoQ = [PFQuery queryWithClassName:@"convos"];
    [convoQ whereKey:@"totalMessages" greaterThan:@0];
//    [convoQ whereKeyExists:@"buyerUser"];
    [convoQ whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
    [convoQ orderByDescending:@"lastSentDate"];
    convoQ.limit = 20;
    [convoQ findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            for (PFObject *convo in objects) {
                convo[@"buyerPicture"] = [[PFUser currentUser] objectForKey:@"picture"];
                [convo saveInBackground];
            }
            
        }
        else{
            [Answers logCustomEventWithName:@"Error retrieving user's buyer convos to change pic"
                           customAttributes:@{
                                              @"where":@"Settings",
                                              }];
        }
    }];
    
    PFQuery *sellingConvoQ = [PFQuery queryWithClassName:@"convos"];
    [sellingConvoQ whereKey:@"totalMessages" greaterThan:@0];
    [sellingConvoQ whereKeyExists:@"sellerUser"];
    [sellingConvoQ whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
    [sellingConvoQ orderByDescending:@"lastSentDate"];
    sellingConvoQ.limit = 20;
    [sellingConvoQ findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            for (PFObject *convo in objects) {
                convo[@"sellerPicture"] = [[PFUser currentUser] objectForKey:@"picture"];
                [convo saveInBackground];
            }
            
        }
        else{
            [Answers logCustomEventWithName:@"Error retrieving user's seller convos to change pic"
                           customAttributes:@{
                                              @"where":@"Settings",
                                              }];
        }
    }];
}


#pragma mark - swipe view delegates

-(UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view{
    
    UILabel *messageLabel = nil;
    
    if (view == nil)
    {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80,30)];
        messageLabel = [[UILabel alloc]initWithFrame:CGRectMake(5,0, 70, 30)];
        messageLabel.layer.cornerRadius = 7;
        messageLabel.layer.masksToBounds = YES;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        [messageLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
        [view addSubview:messageLabel];
    }
    else
    {
        messageLabel = [[view subviews] lastObject];
    }
    
    //set brand label
    messageLabel.text = [self.currencyArray objectAtIndex:index];
    
    //set image
    if ([self.selectedCurrency isEqualToString:messageLabel.text]) {
        //selected
        messageLabel.backgroundColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
        messageLabel.textColor = [UIColor whiteColor];
        
    }
    else{
        //unselected
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.textColor = [UIColor blackColor];
    }
    
    return view;
}
-(void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index{
    
    NSString *selected = [self.currencyArray objectAtIndex:index];
    
    if (![self.selectedCurrency isEqualToString:selected]) {
        self.currencyChanged = YES;
        
        //deselect currently selected currency
        UIView *prevView = [self.currencySwipeView itemViewAtIndex:[self.currencyArray indexOfObject:self.selectedCurrency]];
        UILabel *messageLabel = [[prevView subviews] lastObject];
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.textColor = [UIColor blackColor];
        
        //select new currency
        self.selectedCurrency = selected;
        UIView *newView = [self.currencySwipeView itemViewAtIndex:index];
        UILabel *newMessageLabel = [[newView subviews] lastObject];
        newMessageLabel.backgroundColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
        newMessageLabel.textColor = [UIColor whiteColor];
    }
}

-(NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView{
    
    return self.currencyArray.count;
}
@end
