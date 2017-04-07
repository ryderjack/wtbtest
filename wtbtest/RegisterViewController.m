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
#import "MessagesTutorial.h"
#import "Tut1ViewController.h"
#import <Crashlytics/Crashlytics.h>
#import "UIImage+Resize.h"
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/UIImageView+WebCache.h>

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
    
    self.longRegButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
    [self.longRegButton setTitle:@"R E G I S T E R" forState:UIControlStateNormal];
    [self.longRegButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
    [self.longRegButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
    [self.longRegButton addTarget:self action:@selector(regPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.longRegButton.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:self.longRegButton];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.longRegButton.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                         self.regShowing = YES;
                         NSLog(@"showing");
                     }];
    
    //get friends list
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"me/friends"
                                  parameters:@{@"fields": @"id, name"}
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        // Handle the result
        if (!error) {
            //SAVE THEM TOO!!!!
            NSArray* friends = [result objectForKey:@"data"];
            NSLog(@"Found: %lu friends with bump installed", (unsigned long)friends.count);
            NSMutableArray *friendsHoldingArray = [NSMutableArray array];
            
            for (NSDictionary *friend in friends) {
                [friendsHoldingArray addObject:[friend objectForKey:@"id"]];
            }
            
            [[PFUser currentUser]setObject:friendsHoldingArray forKey:@"friends"];
            [[PFUser currentUser] saveInBackground];
            
            if (friends.count > 2) {
                [self setImageBorder:self.friendOneImageView];
                [self setImageBorder:self.friendTwoImageView];
                [self setImageBorder:self.friendThreeImageView];
                
                self.friendsLabel.text = [NSString stringWithFormat:@"%lu friends use Bump", friends.count];
                self.showFriendsCell = YES;
                
                int rowIndex = 0;//your row index where you want to add cell
                int sectionIndex = 1;//your section index
                NSIndexPath *iPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
                NSArray *array = [NSArray arrayWithObject:iPath];
                [self.tableView insertRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationFade];
                
                //set images
                NSURL *picUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", [friends[0] objectForKey:@"id"]]];
                [self.friendOneImageView sd_setImageWithURL:picUrl];
                
                NSURL *picUrl2 = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large",[friends[1] objectForKey:@"id"]]];
                [self.friendTwoImageView sd_setImageWithURL:picUrl2];
                
                NSURL *picUrl3 = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large",[friends[2] objectForKey:@"id"]]];
                [self.friendThreeImageView sd_setImageWithURL:picUrl3];
            }
        }
    }];
}

-(void)viewDidAppear:(BOOL)animated{
    [self startLocationManager];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.pressedCam != YES) {
        [self requestFacebook:self.user];
    }
    if (self.regShowing == NO) {
        self.longRegButton.alpha = 0.0f;
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.longRegButton.alpha = 1.0f;
                         }
                         completion:^(BOOL finished) {
                             self.regShowing = YES;
                         }];
    }
}

- (void)requestFacebook:(PFUser *)user{
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setValue:@"id,name,email,gender,picture,first_name,last_name" forKey:@"fields"];
    
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
    if ([userData objectForKey:@"first_name"]) {
        user[@"firstName"] = [userData objectForKey:@"first_name"];
        user[@"firstNameLower"] = [[userData objectForKey:@"first_name"] lowercaseString];;
    }
    if ([userData objectForKey:@"last_name"]) {
        user[@"lastName"] = [userData objectForKey:@"last_name"];
        user[@"lastNameLower"] = [[userData objectForKey:@"last_name"] lowercaseString];;
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
        [self.profilePicture setImage:[UIImage imageWithData:pic]];
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
        if (self.showFriendsCell == YES) {
            return 2;
        }
        else{
            return 1;
        }
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
        if (self.showFriendsCell == YES) {
            if (indexPath.row == 0) {
                return self.friendsCell;
            }
            else if(indexPath.row == 1){
                return self.regCell;
            }
        }
        else{
            return self.regCell;
        }
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
            return 156;
        }
    }
    else if (indexPath.section ==1){
        if (self.showFriendsCell == YES) {
            if (indexPath.row == 0) {
                return 80;
            }
            else if(indexPath.row == 1){
                return 88;
            }
        }
        else{
            return 88;
        }
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
    self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.width / 2;
    self.profilePicture.layer.masksToBounds = YES;
    self.profilePicture.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.profilePicture.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
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
        
        if ([self.profanityList containsObject:string]) {
            return  NO;
        }
        
        if ([string isEqualToString:@" "]) {
            return NO;
        }
        
        if (![string canBeConvertedToEncoding:NSASCIIStringEncoding]){
            return NO;
        }
        
        if(range.length + range.location > textField.text.length)
        {
            return NO;
        }
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return newLength <= 20;
    }
    return string;
}

- (IBAction)regPressed:(id)sender {
    
    [self.regButton setEnabled:NO];
    
    if ([self.profanityList containsObject:self.usernameField.text.lowercaseString]) {
        self.usernameField.text = @"";
        self.warningLabel.text = @"Choose a username";
        [self.regButton setEnabled:YES];
        return;
    }
    
    //check values entered
    NSString *name = [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *email = [self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *username = [self.usernameField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if ([name length] == 0 || [email length] == 0 || [username length] == 0 || [self.selectedCurrency isEqualToString:@""])  {
        self.warningLabel.text = @"Complete all the fields";
        [self.regButton setEnabled:YES];
    }
    else{
        if ([self NSStringIsValidEmail:self.emailField.text] == NO) {
            self.warningLabel.text = @"Enter a valid email";
            self.emailField.textColor = [UIColor colorWithRed:1 green:0.294 blue:0.38 alpha:1];
            [self.regButton setEnabled:YES];
        }
        else{
            [self showHUD];
            [self.spinner startAnimating];
            [Answers logCustomEventWithName:@"Selected currency"
                           customAttributes:@{
                                              @"currency":self.selectedCurrency,
                                              }];
            
            //check username entered is unique
            PFQuery *usernameQuery = [PFQuery queryWithClassName:@"_User"];
            [usernameQuery whereKey:@"username" equalTo:username];
            [usernameQuery countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
                if (!error) {
                    if (number == 0) {
                        NSLog(@"username is available!");
                        self.user[PF_USER_FULLNAME] = name;
                        self.user[@"fullnameLower"] = [name lowercaseString];
                        self.user[PF_USER_EMAIL] = email;
                        self.user[@"paypal"] = email;
                        self.user[PF_USER_USERNAME] = [username lowercaseString];
                        self.user[@"currency"] = self.selectedCurrency;
                        self.user[@"completedReg"] = @"YES";
                        self.user[@"indexedListings"] = @"YES";
                        self.user[@"bumpArray"] = @[];
                        self.user[@"snapSeen"] = @"YES";
                        [self.user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                         {
                             if (succeeded)
                             {
                                 //opt in for the welcome email
                                 NSDictionary *params = @{@"id": @"a9803761de",@"double_optin":@NO,@"email": @{@"email":email}, @"merge_vars": @{@"FNAME": [self.user objectForKey:@"firstName"], @"LName":[self.user objectForKey:@"lastName"]}};
                                 
                                 [[ChimpKit sharedKit] callApiMethod:@"lists/subscribe" withParams:params andCompletionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                     //        NSLog(@"HTTP Status Code: %d", response.statusCode);
                                     NSLog(@"Response String: %@", response);
                                     //
                                     if (error) {
                                         //Handle connection error
                                         NSLog(@"Chimp Error, %@", error);
                                         [Answers logCustomEventWithName:@"welcome email error"
                                                        customAttributes:@{
                                                                           @"error":error
                                                                           }];
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             //Update UI here
                                         });
                                     } else {
                                         NSError *parseError = nil;
                                         id response = [NSJSONSerialization JSONObjectWithData:data
                                                                                       options:0
                                                                                         error:&parseError];
                                         if ([response isKindOfClass:[NSDictionary class]]) {
                                             id email = [response objectForKey:@"email"];
                                             if ([email isKindOfClass:[NSString class]]) {
                                                 //Successfully subscribed email address
                                                 NSLog(@"success with the chimp!");
                                                 
                                                 [Answers logCustomEventWithName:@"Sent welcome email"
                                                                customAttributes:@{}];
                                                 
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     //Update UI here
                                                 });
                                             }
                                         }
                                     }
                                 }];
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
                                         NSString *messageString = @"🙌 Welcome to Bump 🙌\n\n👟 Want to buy streetwear?\nCreate wanted listings in seconds that tell sellers what you're looking for, then check out items you can buy straight away on Bump.\n\n🤑 Selling something?\nUse the search tools to find people that want what you're selling and send them a message!\n\n💥 Discover\nTap the shopping cart icon to browse items for sale as well as the latest sneaker releases & schedule reminders too.\n\nGot any questions? Just send us a message 👊\n\nSophie @ Team Bump";
                                         
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

                                 //save Bumped Obj
                                 PFObject *bumpedObj = [PFObject objectWithClassName:@"Bumped"];
                                 [bumpedObj setObject:[self.user objectForKey:@"facebookId"] forKey:@"facebookId"];
                                 [bumpedObj setObject:self.user forKey:@"user"];
                                 [bumpedObj setObject:[NSDate date] forKey:@"safeDate"];
                                 [bumpedObj setObject:@0 forKey:@"timesBumped"];
                                 [bumpedObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                     if (succeeded) {
                                         NSLog(@"saved bumped obj");
                                     }
                                 }];
                                 
                                 [self hideHUD];
                                 
                                 //show add size modal first
                                 AddSizeController *vc = [[AddSizeController alloc]init];
                                 vc.delegate = self;
                                 [self.navigationController presentViewController:vc animated:YES completion:nil];

                                 //progress to tutorial
//                                 Tut1ViewController *vc = [[Tut1ViewController alloc]init];
//                                 vc.clickMode = YES;
//                                 [self.navigationController pushViewController:vc animated:YES];
                             }
                             else
                             {
                                 [self.regButton setEnabled:YES];
                                 [self hideHUD];
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
                        [self hideHUD];
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
    self.webViewController = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
    self.webViewController.title = @"Terms & Conditions";
    self.webViewController.showUrlWhileLoading = YES;
    self.webViewController.showPageTitles = NO;
    self.webViewController.doneButtonTitle = @"";
    self.webViewController.delegate = self;
    //hide toolbar banner
    self.webViewController.infoMode = NO;
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.webViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)paidPressed{
    //do nothing
}

-(void)cancelWebPressed{
    [self.webViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)cameraPressed{
    //do nothing
}

-(void)screeshotPressed:(UIImage *)screenshot withTaps:(int)taps{
    //do nothing
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(nonnull NSDictionary<NSString *,id> *)info{
    
    self.pressedCam = YES;
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    
    [self showHUD];
//    UIImage *imageToSave = [chosenImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(750.0, 750.0) interpolationQuality:kCGInterpolationHigh];
    
    UIImage *imageToSave = [chosenImage scaleImageToSize:CGSizeMake(750, 750)];

    NSData* data = UIImageJPEGRepresentation(imageToSave, 0.7f);
    if (data == nil) {
        NSLog(@"error with data");
        [self hideHUD];
        [picker dismissViewControllerAnimated:YES completion:nil];
        [self showAlertWithTitle:@"Image Error" andMsg:@"Woops, something went wrong. Please try again!"];
        [Answers logCustomEventWithName:@"PFFile Nil Data"
                       customAttributes:@{
                                          @"pageName":@"Reg"
                                          }];
    }
    else{
        PFFile *filePicture = [PFFile fileWithName:@"picture.jpg" data:data];
        
        [filePicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                self.profilePicture.image = nil;
                [self.profilePicture setFile:filePicture];
                [self.profilePicture loadInBackground];
                [self hideHUD];
                
                self.user[PF_USER_PICTURE] = filePicture;
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
    self.pressedCam = YES;
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longRegButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                         self.regShowing = NO;
                     }];
}

- (void) startLocationManager {
    
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _locationManager.distanceFilter = 5;
        _locationManager.delegate = self;
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        [_locationManager startUpdatingLocation];
    }
    [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"askedForLocationPermission"];
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

- (UIImage *)scaleImageToSize:(CGSize)newSize ofImage: (UIImage *)image {
    
    CGRect scaledImageRect = CGRectZero;
    
    CGFloat aspectWidth = newSize.width / image.size.width;
    CGFloat aspectHeight = newSize.height / image.size.height;
    CGFloat aspectRatio = MAX ( aspectWidth, aspectHeight );
    
    scaledImageRect.size.width = image.size.width * aspectRatio;
    scaledImageRect.size.height = image.size.height * aspectRatio;
    scaledImageRect.origin.x = (newSize.width - scaledImageRect.size.width) / 2.0f;
    scaledImageRect.origin.y = (newSize.height - scaledImageRect.size.height) / 2.0f;
    
    UIGraphicsBeginImageContextWithOptions( newSize, NO, 0 );
    [image drawInRect:scaledImageRect];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
    
}

-(void)addSizeDismissed{
    //progress to tutorial
     Tut1ViewController *vc = [[Tut1ViewController alloc]init];
     vc.clickMode = YES;
     [self.navigationController pushViewController:vc animated:YES];
}
@end
