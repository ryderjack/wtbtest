//
//  RegisterViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 23/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "RegisterViewController.h"
#import "WelcomeViewController.h"
#import "ContainerViewController.h"
#import "NavigationController.h"
#import "AppConstant.h"
#import <TOWebViewController.h>
#import "MessagesTutorial.h"

@interface RegisterViewController ()
@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    
    //hide first table view header
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
    
    self.nameField.delegate = self;
    self.emailField.delegate = self;
    self.usernameField.delegate = self;
    self.depopField.delegate = self;
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeKeyboard)];
    tapGesture.numberOfTapsRequired = 1;
    [self.tableView addGestureRecognizer:tapGesture];
    self.warningLabel.text = @"";
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.selectedCurrency = @"GBP";
    [self.GBPButton setSelected:YES];
    
    self.profanityList = @[@"fuck", @"cunt", @"sex", @"wanker", @"nigger", @"penis", @"cock", @"shit", @"dick", @"bastard", @"#", @"?", @"!", @"£", @"/", @"(", @")", @":", @",", @"'", @"$", @" ",@"<", @">", @"+", @"=", @"%", @"[", @"]", @"{", @"}", @"^", @"..fuckfuck"];
    
    if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications] == NO) {
        NSLog(@"tapped no to notifications");
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.pressedCam != YES) {
        [self requestFacebook:self.user];
    }
}

- (void)requestFacebook:(PFUser *)user{
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setValue:@"id,name,email,gender,picture,first_name" forKey:@"fields"];
    
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:parameters]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                  id result, NSError *error) {
         if (error == nil)
         {
             NSDictionary *userData = (NSDictionary *)result;
             NSLog(@"user data %@", userData);
             [self processFacebook:user UserData:userData];
         }
         else{
             NSLog(@"error %@", error);
             [PFUser logOut];
         }
     }];
}

- (void)processFacebook:(PFUser *)user UserData:(NSDictionary *)userData
{
    if ([userData objectForKey:@"email"]) {
        self.emailField.text = [userData objectForKey:@"email"];
    }
    if ([userData objectForKey:@"name"]) {
        self.nameField.text = [userData objectForKey:@"name"];
    }
    if ([userData objectForKey:@"id"]) {
        user[PF_USER_FACEBOOKID] = userData[@"id"];
    }
    if ([userData objectForKey:@"gender"]) {
        user[PF_USER_GENDER] = userData[@"gender"];
    }
    if ([userData objectForKey:@"picture"]) {
        NSString *userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", userData[@"id"]];
        NSURL *picUrl = [NSURL URLWithString:userImageURL];
        NSData *pic = [NSData dataWithContentsOfURL:picUrl];
        [self.profileImageView setImage:[UIImage imageWithData:pic]];
        [self setImageBorder];
        
        // setup feedback
        PFObject *dealsData = [PFObject objectWithClassName:@"deals"];
        [dealsData setObject:[PFUser currentUser] forKey:@"User"];
        [dealsData setObject:@0 forKey:@"star1"];
        [dealsData setObject:@0 forKey:@"star2"];
        [dealsData setObject:@0 forKey:@"star3"];
        [dealsData setObject:@0 forKey:@"star4"];
        [dealsData setObject:@0 forKey:@"star5"];
        
        [dealsData setObject:@0 forKey:@"dealsTotal"];
        [dealsData setObject:@0 forKey:@"sold"];
        [dealsData setObject:@0 forKey:@"purchased"];
        [dealsData setObject:@0 forKey:@"currentRating"];
        [dealsData saveInBackground];
        
        //save image
        PFFile *picFile = [PFFile fileWithData:pic];
        self.user[PF_USER_PICTURE] = picFile;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0){
        return 6;
    }
    else if (section == 1){
        return 1;
    }
    else{
      return 0;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.titleCell;
        }
        else if(indexPath.row == 1){
            return self.nameCell;
        }
        else if(indexPath.row == 2){
            return self.emailCell;
        }
        else if(indexPath.row == 3){
            return self.usernameCell;
        }
        else if(indexPath.row == 4){
            return self.currencyCell;
        }
        else if(indexPath.row == 5){
            return self.pictureCell;
        }
    }
    else if (indexPath.section ==1){
        return self.regCell;
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 58;
        }
        else if(indexPath.row == 1 ||indexPath.row == 2 ||indexPath.row == 3 ||indexPath.row == 4){
            return 44;
        }
        else if(indexPath.row == 5){
            return 147;
        }
    }
    else if (indexPath.section ==1){
        return 140;
    }
    return 44;
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

//these methods hide the first header in table view
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 1.0f;
    return 32.0f;
}

- (NSString*) tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    } else {
        return @"";
    }
}
- (IBAction)dismissPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)setImageBorder{
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2;
    self.profileImageView.layer.masksToBounds = YES;
    self.profileImageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.usernameField) {
        if ([self.profanityList containsObject:textField.text.lowercaseString]) {
            textField.text = @"";
        }
        if ([textField.text containsString:@" "]) {
            textField.text = @"";
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    if (textField == self.usernameField) {
        
        if ([string isEqualToString:@" "]) {
            return NO;
        }
        
        if(range.length + range.location > textField.text.length)
        {
            return NO;
        }
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return newLength <= 10;
    }
    return string;
}

- (IBAction)regPressed:(id)sender {
    
    [self.regButton setEnabled:NO];
    
    if ([self.profanityList containsObject:self.usernameField.text.lowercaseString]) {
        self.usernameField.text = @"";
    }
    
    //check values entered
    NSString *name = [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *email = [self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *username = [self.usernameField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if ([name length] == 0 || [email length] == 0 || [username length] == 0 || [self.selectedCurrency isEqualToString:@""])  {
        
        self.warningLabel.text = @"Enter all of the above!";
        [self.regButton setEnabled:YES];
    }
    else{
        if ([self NSStringIsValidEmail:self.emailField.text] == NO) {
            self.warningLabel.text = @"Enter a valid email";
            self.emailField.textColor = [UIColor colorWithRed:1 green:0.294 blue:0.38 alpha:1];
            [self.regButton setEnabled:YES];
        }
        else{
            self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.hud.square = YES;
            self.hud.mode = MBProgressHUDModeCustomView;
            self.hud.customView = self.spinner;
            [self.spinner startAnimating];
            
            //check username entered is unique
            PFQuery *usernameQuery = [PFQuery queryWithClassName:@"_User"];
            [usernameQuery whereKey:@"username" equalTo:username];
            [usernameQuery countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
                if (!error) {
                    if (number == 0) {
                        NSLog(@"username is available!");
                        self.user[PF_USER_FULLNAME] = name;
                        self.user[PF_USER_EMAIL] = email;
                        self.user[@"paypal"] = email;
                        self.user[PF_USER_USERNAME] = [username lowercaseString];
                        self.user[@"currency"] = self.selectedCurrency;
                        self.user[@"completedReg"] = @"YES";
                        
//                        if (![self.depopField.text isEqualToString:@""]) {
//                            //entered a depop account
//                            NSString *depopHandle = [self.depopField.text stringByReplacingOccurrencesOfString:@"@" withString:@""];
//                            [depopHandle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//                            self.user[@"depopHandle"] = depopHandle;
//                            PFObject *depopObj = [PFObject objectWithClassName:@"Depop"];
//                            depopObj[@"user"] = self.user;
//                            depopObj[@"handle"] = depopHandle;
//                            [depopObj saveInBackground];
//                        }
                        
                        [self.user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                         {
                             if (succeeded)
                             {
                                 NSLog(@"saved new user! %@", [PFUser currentUser]);
                                 [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showHowWorks"];
                                 
                                 //update installation object w/ current user
                                 PFInstallation *installation = [PFInstallation currentInstallation];
                                 [installation setObject:[PFUser currentUser] forKey:@"user"];
                                 [installation setObject:[PFUser currentUser].objectId forKey:@"userId"];
                                 [installation saveInBackground];
                                 
                                 //create team bump convo
                                 PFObject *convoObject = [PFObject objectWithClassName:@"teamConvos"];
                                 convoObject[@"otherUser"] = [PFUser currentUser];
                                 convoObject[@"convoId"] = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
                                 convoObject[@"totalMessages"] = @0;
                                 [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                     if (succeeded) {
                                         NSString *messageString = @"Welcome to Bump 🙌\n\nWant to buy something? 💎\nCreate listings for items you want then sit back and wait for sellers to send you offers to buy their stuff (Plus there's ZERO fees). Bump also recommends related items to you - just tap the cart icon!\n\nSelling something? 🤑\nUse the search & filter tools to find people that want what you're selling and then send them an offer to buy your item.\n\nHow to sell? 📲\nJust tap the tag icon in a chat and hit 'Send an offer'. Buyers can then tap the offer message to complete the purchase using PayPal without leaving Bump!\n\nGot any questions? Just message us here - we're available 24/7/365 #wehavenolife\n\nHappy Bumping!\nTeam Bump";
                                         
                                         //saved, create intro message
                                         PFObject *messageObject = [PFObject objectWithClassName:@"teamBumpMsgs"];
                                         messageObject[@"message"] = messageString;
                                         messageObject[@"sender"] = [PFUser currentUser];
                                         messageObject[@"senderId"] = @"BUMP";
                                         messageObject[@"senderName"] = @"Team Bump";
                                         messageObject[@"convoId"] = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
                                         messageObject[@"status"] = @"sent";
                                         messageObject[@"offer"] = @"NO";
                                         messageObject[@"mediaMessage"] = @"NO";
                                         [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                             if (succeeded == YES) {
                                                 
//                                                 NSLog(@"saved message, here it is: %@", messageObject);
                                                 
                                                 //update convo
                                                 [convoObject incrementKey:@"totalMessages"];
                                                 [convoObject setObject:messageObject forKey:@"lastSent"];
                                                 [convoObject setObject:[NSDate date] forKey:@"lastSentDate"];
                                                 [convoObject incrementKey:@"userUnseen"];
                                                 [convoObject saveInBackground];

                                             }
                                             else{
                                                 NSLog(@"error sending message %@", error);
                                             }
                                         }];
                                         

                                     }
                                     else{
                                         NSLog(@"error saving convo");
                                     }
                                 }];

                                 //progress to tutorial
                                 [self dismissHUD];
                                 ContainerViewController *vc = [[ContainerViewController alloc]init];
                                 [self.navigationController pushViewController:vc animated:YES];
                                 
                                 //MessagesTutorial *vc = [[MessagesTutorial alloc]init];
                                 //vc.introMode = YES;
                                 //[self.navigationController pushViewController:vc animated:YES];
                             }
                             else
                             {
                                 [self.regButton setEnabled:YES];
                                 [self dismissHUD];
                                 NSLog(@"error %@", error);
                                 UIAlertController * alert=   [UIAlertController
                                                               alertControllerWithTitle:@"Error"
                                                               message:@"Make sure you're connected to the internet!"
                                                               preferredStyle:UIAlertControllerStyleAlert];
                                 UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                                 [alert addAction:ok];
                                 [self presentViewController:alert animated:YES completion:nil];
                             }
                         }];
                    }
                    else{
                        NSLog(@"username taken");
                        [self dismissHUD];
                        [self.regButton setEnabled:YES];
                        self.warningLabel.text = @"Username taken";
                        self.usernameField.textColor = [UIColor colorWithRed:1 green:0.294 blue:0.38 alpha:1];
                    }
                }
                else{
                    NSLog(@"error checking username");
                    self.warningLabel.text = @"Error with username";
                    [self.regButton setEnabled:YES];
                }
            }];
        }
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}
-(void)removeKeyboard{
    [self.nameField resignFirstResponder];
    [self.emailField resignFirstResponder];
    [self.usernameField resignFirstResponder];
    [self.depopField resignFirstResponder];
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

-(void)dismissHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
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
- (IBAction)AUDPressed:(id)sender {
    if (self.EURButton.selected == YES) {
    }
    else{
        self.selectedCurrency = @"EUR";
        [self.EURButton setSelected:YES];
        [self.GBPButton setSelected:NO];
        [self.USDButton setSelected:NO];
    }
}
- (IBAction)termsPressed:(id)sender {
    NSString *URLString = @"http://www.sobump.com/terms.html";
    TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURL:[NSURL URLWithString:URLString]];
    webViewController.title = @"Terms & Conditions";
    webViewController.showUrlWhileLoading = YES;
    webViewController.showPageTitles = NO;
    webViewController.doneButtonTitle = @"";
    webViewController.paypalMode = NO;
    //hide toolbar banner
    webViewController.infoMode = NO;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}
- (IBAction)depopInfoPressed:(id)sender {
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Depop matching"
                                  message:@"Already selling loads of stuff on depop? Let us know your depop handle and our clever code will check out your account then let you know on Bump when someone wants what you're selling.\nSit back and relax 🐸☕️"
                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}
- (IBAction)pressedChoose:(id)sender {
    if (!self.picker) {
        self.picker = [[UIImagePickerController alloc] init];
        self.picker.delegate = self;
        self.picker.allowsEditing = NO;
        self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    [self presentViewController:self.picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.profileImageView.image = info[UIImagePickerControllerOriginalImage];
    NSData* data = UIImageJPEGRepresentation(self.profileImageView.image, 0.5f);
    PFFile *imageFile = [PFFile fileWithName:@"Image.jpg" data:data];
    self.user[PF_USER_PICTURE] = imageFile;
    self.pressedCam = YES;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    self.pressedCam = YES;
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
