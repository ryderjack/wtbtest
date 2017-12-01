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
#import "ExplainView.h"
#import "AppDelegate.h"
#import "Mixpanel/Mixpanel.h"
#import <Intercom/Intercom.h>

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
    self.lastNameField.delegate = self;
    self.passwordField.delegate = self;
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    //currency swipe view
    self.currencySwipeView.delegate = self;
    self.currencySwipeView.dataSource = self;
    self.currencySwipeView.clipsToBounds = YES;
    self.currencySwipeView.pagingEnabled = NO;
    self.currencySwipeView.truncateFinalPage = NO;
    [self.currencySwipeView setBackgroundColor:[UIColor clearColor]];
    self.currencySwipeView.alignment = SwipeViewAlignmentEdge;
    [self.currencySwipeView reloadData];
    
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeKeyboard)];
    tapGesture.numberOfTapsRequired = 1;
    [self.tableView addGestureRecognizer:tapGesture];
    self.warningLabel.text = @"";
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    //use phone data to preselect the local currency
    NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
    
    if (countryCode) {
        
        if ([countryCode isEqualToString:@"GB"]) {
            self.selectedCurrency = @"GBP";
        }
        else if ([countryCode isEqualToString:@"US"] || [countryCode isEqualToString:@"CA"]) {
            self.selectedCurrency = @"USD";
        }
        else if ([countryCode isEqualToString:@"IT"] ||[countryCode isEqualToString:@"DE"] || [countryCode isEqualToString:@"FR"] || [countryCode isEqualToString:@"NL"] || [countryCode isEqualToString:@"AT"]) {
            self.selectedCurrency = @"EUR";
        }
        else if ([countryCode isEqualToString:@"AU"]) {
            self.selectedCurrency = @"AUD";
        }
        else{
            self.selectedCurrency = @"USD";
        }
    }
    else{
        self.selectedCurrency = @"USD";
    }
    
    [self setImageBorder];
    
    self.profanityList = @[@"fuck", @"cunt", @"sex", @"wanker", @"nigger", @"penis", @"cock", @"shit", @"dick", @"bastard", @"#", @"?", @"!", @"£", @"/", @"(", @")", @":", @",", @"'", @"$", @" ",@"<", @">", @"+", @"=", @"%", @"[", @"]", @"{", @"}", @"^", @"..fuckfuck"];
    self.currencyArray = @[@"GBP", @"USD", @"EUR", @"AUD"];
    
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
    
    if (self.emailMode != YES) {
        //get friends list
        [self getFriends];
        
        //setup deals data
        [self setupFeedback];
        
        self.nameField.placeholder = @"Name";
    }
    else{
        self.nameField.placeholder = @"First name";
        [self addDoneButton];
    }
    
    //check if device banned and trying to create a new account
    PFInstallation *installation = [PFInstallation currentInstallation];
    PFQuery *bannedInstallsQuery = [PFQuery queryWithClassName:@"bannedUsers"];
    
    if (installation.deviceToken) {
        [bannedInstallsQuery whereKey:@"deviceToken" equalTo:installation.deviceToken];
    }
    else{
        //to prevent simulator returning loads of results and fucking up banning logic
        [bannedInstallsQuery whereKey:@"deviceToken" equalTo:@"thisISNothing"];
    }
    
    [bannedInstallsQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //user is banned - log them out
            
            [Answers logCustomEventWithName:@"Preventing Banned User Signing Up"
                           customAttributes:@{}];
            
            self.banMode = YES;
            [self showAlertWithTitle:@"Restricted" andMsg:@"If you feel you're seeing this as a mistake then let us know hello@sobump.com"];
        }
        else{
            //do final check against NSUserDefaults incase user was banned without device token coz didn't enable push
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"banned"] isEqualToString:@"YES"]) {
                //user is banned - log them out
                
                [Answers logCustomEventWithName:@"Preventing Banned User Signing Up"
                               customAttributes:@{
                                                  @"trigger":@"defaults"
                                                  }];
                
                self.banMode = YES;
                [self showAlertWithTitle:@"Restricted" andMsg:@"If you feel you're seeing this as a mistake then let us know hello@sobump.com"];
                return;
            }
        }
    }];
}

-(void)getFriends{
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"me/friends/?limit=5000"
                                  parameters:@{@"fields": @"id, name"}
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        // Handle the result
        if (!error) {
            //SAVE THEM TOO!!!!
            NSArray* friends = [result objectForKey:@"data"];
            NSLog(@"Found: %lu friends with BUMP installed", (unsigned long)friends.count);
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
                
                self.friendsLabel.text = [NSString stringWithFormat:@"%lu friends use BUMP", (unsigned long)friends.count];
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
    
    if (self.emailMode && self.pressedCam != YES) {
        [self.nameField becomeFirstResponder];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (self.pressedCam != YES && self.emailMode != YES) {
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
             [Intercom reset];

         }
     }];
}

- (void)processFacebook:(PFUser *)user UserData:(NSDictionary *)userData
{
    if ([userData objectForKey:@"email"]) {
        self.emailField.text = [userData objectForKey:@"email"];
        
        if (self.checkedEmail != YES) {
            [self checkEmailExists];
        }
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
        NSData *picData = [NSData dataWithContentsOfURL:picUrl];
        
        //save image
        if (picData == nil) {
            
            [self showAlertWithTitle:@"Facebook Image Error" andMsg:@"Woops, we couldn't retrieve your profile picture. Please add one from your camera roll!"];
            [Answers logCustomEventWithName:@"PFFile Nil Data"
                           customAttributes:@{
                                              @"pageName":@"Reg FB"
                                              }];
        }
        else{
            //to avoid being saved as .bin file
            PFFile *picFile = [PFFile fileWithData:picData contentType:@"image/jpeg"];
            [picFile saveInBackground]; //speed up reg save
            
            self.user[PF_USER_PICTURE] = picFile;
        }
    }
}

-(void)setupFeedback{
    // setup feedback
    NSLog(@"setting up feedback");
    
    PFObject *dealsData = [PFObject objectWithClassName:@"deals"];
    [dealsData setObject:self.user forKey:@"User"];
    [dealsData setObject:@0 forKey:@"star1"];
    [dealsData setObject:@0 forKey:@"star2"];
    [dealsData setObject:@0 forKey:@"star3"];
    [dealsData setObject:@0 forKey:@"star4"];
    [dealsData setObject:@0 forKey:@"star5"];
    
    [dealsData setObject:@0 forKey:@"dealsTotal"];
    [dealsData setObject:@0 forKey:@"currentRating"];
    

    [dealsData saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            NSLog(@"saved feedback");

            //already have deals info saved
            self.user[@"dealsSaved"] = @"YES";
            [self.user saveInBackground];
        }
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.emailMode == YES) {
        //sign up with email
        if (section == 0){
            return 7;
        }
        else if (section == 1){
            return 2;
        }
        else{
            return 0;
        }
    }
    else{
        //sign up with fb
        if (section == 0){
            return 5;
        }
        else if (section == 1){
            if (self.showFriendsCell == YES) {
                return 3;
            }
            else{
                return 2;
            }
        }
        else{
            return 0;
        }
    }

}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.emailMode == YES) {
        if (indexPath.section == 0){
            if(indexPath.row == 0){
                return self.titleCell;
            }
//            else if (indexPath.row == 1) {
//                return self.pictureCell;
//            }
            else if(indexPath.row == 1){
                return self.nameCell;
            }
            else if(indexPath.row == 2){
                return self.secondNameCell;
            }
            else if(indexPath.row == 3){
                return self.emailCell;
            }
            else if(indexPath.row == 4){
                return self.usernameCell;
            }
            else if(indexPath.row == 5){
                return self.passwordCell;
            }
            else if(indexPath.row == 6){
                return self.currencySwipeCell;
            }
        }
        else if (indexPath.section ==1){
            if (indexPath.row == 0) {
                return self.regCell;
            }
            else{
                return self.spaceCell;
            }
        }
        return nil;
    }
    else{
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
                return self.currencySwipeCell;
            }
//            else if(indexPath.row == 5){
//                return self.pictureCell;
//            }

        }
        else if (indexPath.section ==1){
            if (self.showFriendsCell == YES) {
                if (indexPath.row == 0) {
                    return self.friendsCell;
                }
                else if(indexPath.row == 1){
                    return self.regCell;
                }
                else if(indexPath.row == 2){
                    return self.spaceCell;
                }
            }
            else{
                if(indexPath.row == 0){
                    return self.regCell;
                }
                else if(indexPath.row == 1){
                    return self.spaceCell;
                }
            }
        }
        return nil;
    }

}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.emailMode == YES) {
        if (indexPath.section == 0){
            if (indexPath.row == 0) {
                return 58;
            }
            else if(indexPath.row == 1 ||indexPath.row == 2 ||indexPath.row == 3 ||indexPath.row == 4 ||indexPath.row == 5||indexPath.row == 6){
                return 44;
            }
//            else if(indexPath.row == 1){
//                return 156;
//            }
        }
        else if (indexPath.section ==1){
            if (indexPath.row == 0) {
                return 88;
            }
            else if(indexPath.row == 1){
                return 60;
            }
        }
        return 44;
    }
    else{
        if (indexPath.section == 0){
            if (indexPath.row == 0) {
                return 58;
            }
            else if(indexPath.row == 1 ||indexPath.row == 2 ||indexPath.row == 3 ||indexPath.row == 4){
                return 44;
            }
//            else if(indexPath.row == 5){
//                return 156;
//            }
        }
        else if (indexPath.section ==1){
            if (self.showFriendsCell == YES) {
                if (indexPath.row == 0) {
                    return 80;
                }
                else if(indexPath.row == 1){
                    return 88;
                }
                else if(indexPath.row == 2){
                    return 60;
                }
            }
            else{
                return 88;
            }
        }
        return 44;
    }
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

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    //reset colour to black
    textField.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
    
    if (textField != self.nameField) {
        self.somethingChanged = YES;
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    self.warningLabel.text = @"";
    
    if (textField == self.usernameField) {
        if ([self.profanityList containsObject:textField.text.lowercaseString]) {
            textField.text = @"";
        }
        if ([textField.text containsString:@" "]) {
            textField.text = @"";
        }
    }
    else if (textField == self.emailField && self.emailMode){
        
        if ([self.emailField.text isEqualToString:@""]) {
            self.warningLabel.text = @"";
        }
        else if ([self NSStringIsValidEmail:self.emailField.text] == NO) {
            self.warningLabel.text = @"Enter a valid email";
            self.emailField.textColor = [UIColor colorWithRed:1 green:0.294 blue:0.38 alpha:1];
        }
        else{
            self.warningLabel.text = @"";
            self.emailField.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
            [self checkEmailExists];
        }
    }
    else if (textField == self.passwordField){
        if (self.passwordField) {
            NSString *pass = [self.passwordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([pass length] < 8 && [pass length] != 0) {
                [self showAlertWithTitle:@"Password Length" andMsg:@"Passwords must be at least 8 characters with no spaces"];
            }
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
    else if (textField == self.passwordField){
        //no spaces or emoji's
        if ([string isEqualToString:@" "]) {
            return NO;
        }
        
        if (![string canBeConvertedToEncoding:NSASCIIStringEncoding]){
            return NO;
        }
    }
    return string;
}

- (IBAction)regPressed:(id)sender {
    
    [self.regButton setEnabled:NO];
    [self.cancelCrossButton setEnabled:NO];
    [self.helpButton setEnabled:NO];
    
    if ([self.profanityList containsObject:self.usernameField.text.lowercaseString]) {
        self.usernameField.text = @"";
        self.warningLabel.text = @"Invalid username";
        [self.regButton setEnabled:YES];
        [self.helpButton setEnabled:YES];
        [self.cancelCrossButton setEnabled:YES];
        return;
    }
    
    //check values entered
    NSString *name = [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *email = [[self.emailField.text lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *username = [self.usernameField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *lastName = @"";
    NSString *pass = @"";

    if (self.emailMode == YES) {
        lastName = [self.lastNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        pass = [self.passwordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    else{
        //fill this with random word to pass the checks as facebook will have prefilled this
        lastName = @"yo";
        pass = @"12345678";
    }
    
    if ([name length] == 0 || [email length] == 0 || [username length] == 0 || [lastName length] == 0 ||[pass length] < 8 || [self.selectedCurrency isEqualToString:@""])  {
        self.warningLabel.text = @"Complete all the fields";
        [self.regButton setEnabled:YES];
        [self.cancelCrossButton setEnabled:YES];
        [self.helpButton setEnabled:YES];
    }
//    else if (self.profilePicture.image == nil && self.emailMode != YES){
//        //haven't added a picture (only required
//        self.warningLabel.text = @"Add a profile picture";
//        [self.regButton setEnabled:YES];
//        [self.cancelCrossButton setEnabled:YES];
//        [self.helpButton setEnabled:YES];
//    }
    else{
        if ([self NSStringIsValidEmail:self.emailField.text] == NO) {
            self.warningLabel.text = @"Enter a valid email";
            self.emailField.textColor = [UIColor colorWithRed:1 green:0.294 blue:0.38 alpha:1];
            [self.regButton setEnabled:YES];
            [self.cancelCrossButton setEnabled:YES];
            [self.helpButton setEnabled:YES];
            return;
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
            [usernameQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (!object) { 
                    NSLog(@"username is available!");
                    
                    //now do saving
                    if (self.emailMode) {
                        self.user.password = pass;
                        self.user.username = [username lowercaseString];
                        
                        //sign user up first then save stuff
                        
                        [self.user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                            if (succeeded) {
                                NSLog(@"signed up!");
                                [self saveUser];
                            }
                            else{
                                NSLog(@"signup failed %@", error);
                                
                                [Answers logCustomEventWithName:@"Email Signup error"
                                               customAttributes:@{
                                                                  @"error":error
                                                                  }];
                                
                                [self hideHUD];
                                [self.regButton setEnabled:YES];
                                [self.helpButton setEnabled:YES];
                                [self.cancelCrossButton setEnabled:YES];
                                [self showAlertWithTitle:@"Sign up Error" andMsg:[NSString stringWithFormat:@"%@", error]];
                            }
                        }];
                        
                    }
                    else{
                        //just save, signed up via fb
                        [self saveUser];
                    }
                    
                }
                else{
                    NSLog(@"username taken");
                    [self hideHUD];
                    [self.regButton setEnabled:YES];
                    [self.helpButton setEnabled:YES];
                    [self.cancelCrossButton setEnabled:YES];
                    self.warningLabel.text = @"Username taken";
                    self.usernameField.textColor = [UIColor colorWithRed:1 green:0.294 blue:0.38 alpha:1];
                }
            }];
        }
    }
}

-(void)saveUser{
    
    //check values entered
    NSString *name = [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *email = [[self.emailField.text lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *username = [self.usernameField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *lastName = @"";
    NSString *pass = @"";
    
    if (self.emailMode == YES) {
        lastName = [self.lastNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        pass = [self.passwordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    if (self.emailMode) {
        
        //need to set first and last names and full name / full name lower
        self.user[PF_USER_FULLNAME] = [NSString stringWithFormat:@"%@ %@", [name capitalizedString],[lastName capitalizedString]];
        self.user[@"fullnameLower"] = [[NSString stringWithFormat:@"%@ %@", name,lastName] lowercaseString];
        
        self.user[@"firstName"] = [name capitalizedString];
        self.user[@"firstNameLower"] = [name lowercaseString];
        
        self.user[@"lastName"] = [lastName capitalizedString];
        self.user[@"lastNameLower"] = [lastName lowercaseString];
                
        //save password
        self.user.password = pass;
        
    }
    else{
        //just need to set fullname since its fb mode
        self.user[PF_USER_FULLNAME] = [name capitalizedString];
        self.user[@"fullnameLower"] = [name lowercaseString];
    }
    
    self.user[PF_USER_EMAIL] = email;
    self.user[PF_USER_USERNAME] = [username lowercaseString];
    self.user[@"currency"] = self.selectedCurrency;
    self.user[@"completedReg"] = @"YES";
    self.user[@"bumpArray"] = @[];
    [self.user setObject:[NSDate date] forKey:@"lastActive"];
    [self.user addObject:[NSDate date] forKey:@"activeSessions"];
    
    //add device token to user obj so simple to track and ban
    PFInstallation *installation = [PFInstallation currentInstallation];
    if (installation.deviceToken) {
        [self.user setObject:installation.deviceToken forKey:@"deviceToken"];
    }
    
    [self.user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         if (succeeded)
         {
             
             NSLog(@"saved user: %@", [PFUser currentUser]);
             
             //update Intercom with user info
             ICMUserAttributes *userAttributes = [ICMUserAttributes new];
             userAttributes.name = [name capitalizedString];
             userAttributes.email = email;
             userAttributes.signedUpAt = [NSDate date];
             
             //set user as tabUser
             AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
             appDelegate.profileView.user = self.user;
             
             Mixpanel *mixpanel = [Mixpanel sharedInstance];
             [mixpanel identify:self.user.objectId];

             //tracking & deals data setup
             if (self.emailMode) {
                 //setup deals data
                 [mixpanel registerSuperProperties:@{
                                                     @"Source": @"Email",
                                                     @"currency": self.selectedCurrency
                                                     }];
                 
                 [mixpanel track:@"Signup" properties:@{}];
                 
                 [self setupFeedback];
                 
                 [Answers logSignUpWithMethod:@"Email"
                                      success:@YES
                             customAttributes:@{}];
                 
                 //finish adding custom intercom attributes
                 userAttributes.customAttributes = @{@"email_sign_up" : @YES,
                                                     @"currency": self.selectedCurrency};
                
                 [Intercom updateUser:userAttributes];
                 
                 //send confirmation email
                 [self sendConfirmationEmail];
                 
             }
             else{
                 //finish adding custom intercom attributes
                 userAttributes.customAttributes = @{@"email_sign_up" : @NO,
                                                     @"currency": self.selectedCurrency};
                 [Intercom updateUser:userAttributes];
                 
                 //add mixpanel info
                 [mixpanel registerSuperProperties:@{@"Source": @"Facebook",
                                                     @"currency": self.selectedCurrency
                                                     }];
//                 [mixpanel.people set:@{@"email_sign_up" : @NO,
//                                        @"currency"      : self.selectedCurrency
//                                        }];
                 
                 [mixpanel track:@"Signup" properties:@{}];
                 
                 [Answers logSignUpWithMethod:@"Facebook"
                                      success:@YES
                             customAttributes:@{}];
                 
                 NSDictionary *params = @{@"toEmail": email};
                 [PFCloud callFunctionInBackground:@"sendWelcomeEmail" withParameters:params block:^(NSDictionary *response, NSError *error) {
                     if (!error) {
                         
                         [Answers logCustomEventWithName:@"Sent Welcome Email"
                                        customAttributes:@{}];

                     }
                     else{
                         NSLog(@"email error %@", error);
                         
                         [Answers logCustomEventWithName:@"Error sending Welcome Email"
                                        customAttributes:@{}];
                     }
                 }];
             }

             [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showHowWorks"];
             
             PFInstallation *installation = [PFInstallation currentInstallation];
             [installation setObject:[PFUser currentUser] forKey:@"user"];
             [installation setObject:[PFUser currentUser].objectId forKey:@"userId"];
             [installation saveInBackground];
             
             //create team bump convo
//             PFObject *convoObject = [PFObject objectWithClassName:@"teamConvos"];
//             convoObject[@"otherUser"] = [PFUser currentUser];
//             convoObject[@"convoId"] = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
//             convoObject[@"totalMessages"] = @0;
//             [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//                 if (succeeded) {
//                     NSString *messageString = @"🙌 Welcome to BUMP 🙌\n\nBuying\nBrowse the latest items for sale, search through items by tapping the search bar at the top of the home tab, and create wanted listings so sellers can see what you want\n\nSelling\nList an item by tapping the tag icon or search through wanted listings to sell even faster\n\n💥 Got any questions? Just send us a message\n\nSophie @ Team BUMP";
//
//                     //saved, create intro message
//                     PFObject *messageObject = [PFObject objectWithClassName:@"teamBumpMsgs"];
//                     messageObject[@"message"] = messageString;
//                     messageObject[@"sender"] = [PFUser currentUser];
//                     messageObject[@"senderId"] = @"BUMP";
//                     messageObject[@"senderName"] = @"Team Bump";
//                     messageObject[@"convoId"] = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
//                     messageObject[@"status"] = @"sent";
//                     messageObject[@"offer"] = @"NO";
//                     messageObject[@"mediaMessage"] = @"NO";
//                     [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//                         if (succeeded == YES) {
//
//                             //                                                 NSLog(@"saved message, here it is: %@", messageObject);
//
//                             //post notification to display tab bar badge and unseen TB icon
//                             AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//                             [[appDelegate.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:@"1"];
//                             [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NewTBMessageReg"];
//
//                             //update convo
//                             [convoObject incrementKey:@"totalMessages"];
//                             [convoObject setObject:messageObject forKey:@"lastSent"];
//                             [convoObject setObject:[NSDate date] forKey:@"lastSentDate"];
//                             [convoObject incrementKey:@"userUnseen"];
//                             [convoObject saveInBackground];
//                         }
//                         else{
//                             NSLog(@"error sending message %@", error);
//                         }
//                     }];
//                 }
//                 else{
//                     NSLog(@"error saving convo");
//                 }
//             }];
             
             if (self.emailMode != YES) {
                 //save Bumped Obj
                 PFObject *bumpedObj = [PFObject objectWithClassName:@"Bumped"];
                 [bumpedObj setObject:[self.user objectForKey:@"facebookId"] forKey:@"facebookId"];
                 [bumpedObj setObject:self.user forKey:@"user"];
                 [bumpedObj setObject:[NSDate date] forKey:@"safeDate"];
                 [bumpedObj setObject:@0 forKey:@"timesBumped"];
                 [bumpedObj setObject:@"live" forKey:@"status"];
                 [bumpedObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                     if (succeeded) {
                         NSLog(@"saved bumped obj");
                     }
                 }];
             }
             
             [self hideHUD];
             
             //show add size modal first
             AddSizeController *vc = [[AddSizeController alloc]init];
             vc.delegate = self;
             [self.navigationController presentViewController:vc animated:YES completion:nil];
         }
         else
         {
             [self.regButton setEnabled:YES];
             [self hideHUD];
             NSLog(@"reg error %@", error);
             
             [self showAlertWithTitle:@"Registration Error" andMsg:@"Make sure you're connected to the internet and try again!"];
         }
     }];
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if (self.emailMode) {
        if (textField == self.nameField) {
            [self.lastNameField becomeFirstResponder];
        }
        else if (textField == self.lastNameField) {
            [self.emailField becomeFirstResponder];
        }
        else if (textField == self.emailField) {
            [self.usernameField becomeFirstResponder];
        }
        else if (textField == self.usernameField) {
            [self.passwordField becomeFirstResponder];
        }
        else{
            [textField resignFirstResponder];
        }

    }
    else{
        [textField resignFirstResponder];
    }

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
    NSString *URLString = @"http://www.sobump.com/terms";
    self.webViewController = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
    self.webViewController.title = @"Terms & Conditions";
    self.webViewController.showUrlWhileLoading = YES;
    self.webViewController.showPageTitles = NO;
    self.webViewController.doneButtonTitle = @"";
    self.webViewController.delegate = self;
    //hide toolbar banner
//    self.webViewController.infoMode = NO;
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
    self.somethingChanged = YES;
    
    if (!self.picker) {
        self.picker = [[UIImagePickerController alloc] init];
        self.picker.delegate = self;
        self.picker.allowsEditing = NO;
        self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    [self presentViewController:self.picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(nonnull NSDictionary<NSString *,id> *)info{

    self.warningLabel.text = @"";
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    self.pressedCam = YES;
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    
//    UIImage *imageToSave = [chosenImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(750.0, 750.0) interpolationQuality:kCGInterpolationHigh];
    
    [self showHUD];
    
    UIImage *imageToSave = [chosenImage scaleImageToSize:CGSizeMake(400, 400)]; //was 750
    [self.profilePicture setImage:imageToSave];

    NSData* data = UIImageJPEGRepresentation(imageToSave, 0.7f);
    if (data == nil) {
        
        NSLog(@"error with image data");
        self.imageSaved = NO;
        self.profilePicture.image = nil;
        [self hideHUD];
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
                [self hideHUD];
                
                self.imageSaved = YES;
                self.imageFile = filePicture;
                
                self.user[PF_USER_PICTURE] = filePicture;
            }
            else{
                [self hideHUD];

                NSLog(@"ERROR SAVING IMAGE FILE");

                if (self.imageFile) {
                    //there's been a previous image so remove this from user object
                    [self.user removeObjectForKey:PF_USER_PICTURE];
                }
                self.imageFile = nil;
                self.imageSaved = NO;
                
                self.profilePicture.image = nil;
                
                NSLog(@"error saving file %@", error);
                [self showAlertWithTitle:@"Connection Error" andMsg:@"Woops, something went wrong. Please check your interner connection and try again!"];
            }
        }];
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
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if (self.banMode == YES) {
            self.banMode = NO;
            [self.navigationController popViewControllerAnimated:YES];
        }
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
//     Tut1ViewController *vc = [[Tut1ViewController alloc]init];
//     vc.clickMode = YES;
    ExplainView *vc = [[ExplainView alloc]init];
    vc.introMode = YES;
    vc.emailIntro = self.emailMode;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)cancelPressed:(id)sender {
    if (self.somethingChanged == YES) {
        //ask if sure
        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Cancel signup?" message:@"Are you sure you want to cancel? Your changes won't be saved!" preferredStyle:UIAlertControllerStyleAlert];
        
        [alertView addAction:[UIAlertAction actionWithTitle:@"Stay" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
        
        [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:alertView animated:YES completion:nil];
    }
    else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}
-(void)checkEmailExists{
    PFQuery *checkEmailQuery = [PFUser query];
    [checkEmailQuery whereKey:@"email" equalTo:[self.emailField.text lowercaseString]];
    [checkEmailQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            self.checkedEmail = YES;

            if (objects.count == 0) {
//                NSLog(@"email is free");
            }
            else{
                //show alert that an account with that email already exists
                //may have logged in with Facebook previously, would they like to log in with facebook?
                //may be logging in with facebook but signed up with email previously
                
                NSLog(@"someone else using it");
                if (self.emailMode) {
                    [self previousEmailAlert];
                }
                else{
                    //prompt user to connect accounts once logged in
                    [self previousEmailAlertFacebook];
                }
            }
        }
        else{
            NSLog(@"error checking email %@", error);
            [self showAlertWithTitle:@"Error: 451" andMsg:@"Make sure you're connected to the internet!"];
        }
    }];
}

-(void)previousEmailAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Email Already in Use" message:@"Someone is already using that email on Bump! You may have previously logged in via Facebook - try logging in via Facebook now?" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Try different email" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        self.emailField.text = @"";
        [self.emailField becomeFirstResponder];
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Log in with Facebook" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self callLoginWithFacebook];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)previousEmailAlertFacebook{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Email Already in Use" message:@"Someone is already using that email on Bump! You may have previously signed up to Bump with a password - Log in with your password and link your accounts!" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Try different email" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        self.emailField.text = @"";
        [self.emailField becomeFirstResponder];
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Log in with password" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self callLoginWithUsername];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)callLoginWithFacebook{
    [self.delegate RegVCFacebookPressed];
}

-(void)callLoginWithUsername{
    [self.navigationController popViewControllerAnimated:YES];
    [self.delegate RegVCLoginPressed];
}

-(void)sendConfirmationEmail{
    
    NSDictionary *params = @{@"toEmail": [self.user objectForKey:@"email"]};
    [PFCloud callFunctionInBackground:@"sendConfirmEmail" withParameters:params block:^(NSDictionary *response, NSError *error) {
        if (!error) {
            
            [Answers logCustomEventWithName:@"Sent Reg Confirmation Email"
                           customAttributes:@{}];
            
            //increment confirmation email number count (max. = 3)
            [self.user incrementKey:@"emailsCount"];
            
            //next safe date to send email
            NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
            dayComponent.minute = 5;
            NSCalendar *theCalendar = [NSCalendar currentCalendar];
            NSDate *safeDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
            [self.user setObject:safeDate forKey:@"nextEmailSafeDate"];
            [self.user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    NSLog(@"saved email send date");
                    
                    //schedule local push reminder for 3 days time (8pm) to verify their email
                    [self scheduleVerifyReminder];
                }
                else{
                    NSLog(@"error saving email send date %@", error);
                }
            }];
        }
        else{
            NSLog(@"email error %@", error);
            
            [Answers logCustomEventWithName:@"Error sending Reg Confirmation Email"
                           customAttributes:@{}];
        }
    }];
}

- (void)addDoneButton {
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
    [keyboardToolbar sizeToFit];
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                      target:self action:@selector(hideTextfieldNow)];
    
    [doneBarButton setTintColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1]];
    keyboardToolbar.barTintColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];
    
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    
    self.nameField.inputAccessoryView = keyboardToolbar;
    self.lastNameField.inputAccessoryView = keyboardToolbar;
    self.emailField.inputAccessoryView = keyboardToolbar;
    self.usernameField.inputAccessoryView = keyboardToolbar;
    self.passwordField.inputAccessoryView = keyboardToolbar;

}

-(void)hideTextfieldNow{
    [Answers logCustomEventWithName:@"Reg Cancel Textfield Pressed"
                   customAttributes:@{}];
    
    [self.nameField resignFirstResponder];
    [self.lastNameField resignFirstResponder];
    [self.emailField resignFirstResponder];
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];

}
- (IBAction)helpPressed:(id)sender {
    [Answers logCustomEventWithName:@"Reg Help Pressed"
                   customAttributes:@{}];
    
    //show email composer in the app
    if ([MFMailComposeViewController canSendMail]) {
        self.pressedCam = YES; //to stop text fields triggering upon return
        
        MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
        [composeViewController setMailComposeDelegate:self];
        [composeViewController setToRecipients:@[@"hello@sobump.com"]];
        [composeViewController setSubject:@"Bump Registration Help"];
        [composeViewController setMessageBody:@"Having an issue signing up? Please send us a screenshot of any error you see and fully explain the issue so we can help you asap!\n\n############################" isHTML:NO];
        [self presentViewController:composeViewController animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    //Add an alert in case of failure
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)scheduleVerifyReminder{
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 3;
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *dateToFire = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
    
    // Create new date
    NSDateComponents *components1 = [theCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                   fromDate:dateToFire];
    
    NSDateComponents *components3 = [[NSDateComponents alloc] init];
    
    [components3 setYear:components1.year];
    [components3 setMonth:components1.month];
    [components3 setDay:components1.day];
    
    [components3 setHour:20];
    
    // Generate a new NSDate from components3.
    NSDate * combinedDate = [theCalendar dateFromComponents:components3];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc]init];
    [localNotification setAlertBody:@"Verify your BUMP email address now! Remember to check your Junk Folder 📬"];
    [localNotification setFireDate: combinedDate];
    [localNotification setTimeZone: [NSTimeZone defaultTimeZone]];
    [localNotification setRepeatInterval: 0];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
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
