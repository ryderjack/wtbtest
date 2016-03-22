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
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeKeyboard)];
    tapGesture.numberOfTapsRequired = 1;
    [self.tableView addGestureRecognizer:tapGesture];
    self.warningLabel.text = @"";
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self requestFacebook:self.user];
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
        NSString *userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?height=80", userData[@"id"]];
        NSURL *picUrl = [NSURL URLWithString:userImageURL];
        NSData *pic = [NSData dataWithContentsOfURL:picUrl];
        [self.profileImageView setImage:[UIImage imageWithData:pic]];
        [self setImageBorder];
        
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
        return 5;
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
        else if(indexPath.row == 1){
            return 44;
        }
        else if(indexPath.row == 2){
            return 44;
        }
        else if(indexPath.row == 3){
            return 44;
        }
        else if(indexPath.row == 4){
            return 197;
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)setImageBorder{
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2;
    self.profileImageView.layer.masksToBounds = YES;
    
    self.profileImageView.layer.borderWidth = 1.0f;
    self.profileImageView.layer.borderColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1].CGColor;
    
    self.profileImageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
}

- (IBAction)regPressed:(id)sender {
    
    //check values entered
    
    NSString *name = [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *email = [self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *username = [self.usernameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([name length] == 0 || [email length] == 0 || [username length] == 0)  {
        
        self.warningLabel.text = @"Enter your name, email and a username";
    }
    else{
        if ([self NSStringIsValidEmail:self.emailField.text] == NO) {
            self.warningLabel.text = @"Enter a valid email";
            self.emailField.textColor = [UIColor colorWithRed:1 green:0.294 blue:0.38 alpha:1];
        }
        else{
            
            //check username entered is unique
            PFQuery *usernameQuery = [PFQuery queryWithClassName:@"_User"];
            [usernameQuery whereKey:@"username" equalTo:self.usernameField.text];
            [usernameQuery countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
                if (!error) {
                    if (number == 0) {
                        NSLog(@"username is available!");
                        
                        self.user[PF_USER_FULLNAME] = self.nameField.text;
                        self.user[PF_USER_EMAIL] = self.emailField.text;
                        self.user[PF_USER_USERNAME] = self.usernameField.text;
                
                        
                        //also need to save image
                        
                        [self.user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                         {
                             if (error == nil)
                             {
                                 NSLog(@"saved new user! %@", [PFUser currentUser]);
//                                 [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"completedReg"];
                                 
                                 //progress to tutorial
                                 ContainerViewController *vc = [[ContainerViewController alloc]init];
                                 [self.navigationController pushViewController:vc animated:YES];
                             }
                             else
                             {
                                 NSLog(@"error %@", error);
                             }
                         }];
                    }
                    else{
                        NSLog(@"username taken");
                        self.warningLabel.text = @"Username taken";
                        self.usernameField.textColor = [UIColor colorWithRed:1 green:0.294 blue:0.38 alpha:1];
                    }
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

@end
