//
//  loginEmailController.m
//  wtbtest
//
//  Created by Jack Ryder on 31/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "loginEmailController.h"
#import <Parse/Parse.h>
#import "resetPassController.h"
#import <Crashlytics/Crashlytics.h>
#import "AppDelegate.h"
#import <Intercom/Intercom.h>
#import "Mixpanel/Mixpanel.h"

@interface loginEmailController ()

@end

@implementation loginEmailController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.emailField.delegate = self;
    self.passwordField.delegate = self;
    
    self.warningLabel.adjustsFontSizeToFitWidth = YES;
    self.warningLabel.minimumScaleFactor=0.5;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self.emailField becomeFirstResponder];
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Login"
                                      }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)loginPressed:(id)sender {
    self.warningLabel.text = @"";
    [self showHUD];
    [self.logInButton setEnabled:NO];
    [self.facebookLoginButton setEnabled:NO];
    [self.resetButton setEnabled:NO];
    
    //remove @ if included
    NSString *username = [[[self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"@" withString:@""]lowercaseString];
    
    NSString *pass = [self.passwordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([username length] == 0 || [pass length] == 0) {
        self.warningLabel.text = @"Enter your username & password";
        [self hideHUD];
        [self.logInButton setEnabled:YES];
        [self.facebookLoginButton setEnabled:YES];
        [self.resetButton setEnabled:YES];
    }
    else{
        [PFUser logInWithUsernameInBackground:username password:pass block:^(PFUser * _Nullable user, NSError * _Nullable error) {
            if (user) {
                
                //check if user is banned
                PFQuery *bannedQuery = [PFQuery queryWithClassName:@"bannedUsers"];
                [bannedQuery whereKey:@"user" equalTo:[PFUser currentUser]];
                
                //also check if device is banned to prevent creating new accounts
                PFInstallation *installation = [PFInstallation currentInstallation];
                PFQuery *bannedInstallsQuery = [PFQuery queryWithClassName:@"bannedUsers"];
                if (installation.deviceToken) {
                    [bannedInstallsQuery whereKey:@"deviceToken" equalTo:installation.deviceToken];
                }
                else{
                    //to prevent simulator returning loads of results and fucking up banning logic
                    [bannedInstallsQuery whereKey:@"deviceToken" equalTo:@"thisISNothing"];
                }
                
                //check if this user has a merchantId and if its banned before
                PFQuery *merchantIdQuery = [PFQuery queryWithClassName:@"bannedUsers"];
                if ([[PFUser currentUser]objectForKey:@"paypalMerchantId"]) {
                    [merchantIdQuery whereKey:@"merchantId" equalTo:[[PFUser currentUser]objectForKey:@"paypalMerchantId"]];
                }
                else{
                    [merchantIdQuery whereKey:@"merchantId" equalTo:@"thisIsNothing"];
                }
                
                PFQuery *megaBanQuery = [PFQuery orQueryWithSubqueries:@[bannedQuery,bannedInstallsQuery,merchantIdQuery]];
                [megaBanQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                    if (object) {
                        //user is banned - log them out
                        
                        [Answers logCustomEventWithName:@"Banned user attempted login"
                                       customAttributes:@{}];
                        [self hideHUD];
                        
                        [self.logInButton setEnabled:YES];
                        [self.facebookLoginButton setEnabled:YES];
                        [self.resetButton setEnabled:YES];
                        
                        [self showAlertWithTitle:@"Account Restricted" andMsg:@"If you feel you're seeing this as a mistake then let us know hello@sobump.com"];

                    }
                    else{
                        //do final check against NSUserDefaults incase user was banned without device token coz didn't enable push
                        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"banned"] isEqualToString:@"YES"]) {
                            [Answers logCustomEventWithName:@"Banned user attempted login"
                                           customAttributes:@{
                                                              @"trigger":@"defaults"
                                                              }];
                            [self hideHUD];

                            [self.logInButton setEnabled:YES];
                            [self.facebookLoginButton setEnabled:YES];
                            [self.resetButton setEnabled:YES];

                            [self showAlertWithTitle:@"Account Restricted" andMsg:@"If you feel you're seeing this as a mistake then let us know hello@sobump.com"];
                            return;
                        }
                        
                        //everything okay
                        NSLog(@"success logging in");

                        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshHome" object:nil];
                        
                        //set user as tabUser
                        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                        appDelegate.profileView.user = user;
                        
                        if ([PFUser currentUser]) {
                            if (![[PFUser currentUser] objectForKey:@"newCertDone"]) {
                                [[PFUser currentUser] setObject:@"YES" forKey:@"newCertDone"];
                                [[PFUser currentUser] saveInBackground];
                            }
                        }
                        
                        
                        NSDictionary *params = @{@"userId": user.objectId};
                        [PFCloud callFunctionInBackground:@"verifyIntercomUserId" withParameters:params block:^(NSString *hash, NSError *error) {
                            if (!error) {
                                [Intercom setUserHash:hash];
                                [Intercom registerUserWithUserId:user.objectId];
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"registerIntercom" object:nil];
                            }
                            else{
                                [Answers logCustomEventWithName:@"Intercom Verify Error"
                                               customAttributes:@{
                                                                  @"where":@"login"
                                                                  }];
                            }
                        }];
                        
                        
                        [Answers logCustomEventWithName:@"Logged in"
                                       customAttributes:@{
                                                          @"via":@"email",
                                                          @"username": username
                                                          }];
                        
                        //update installation object w/ current user
                        PFInstallation *installation = [PFInstallation currentInstallation];
                        [installation setObject:[PFUser currentUser] forKey:@"user"];
                        [installation setObject:[PFUser currentUser].objectId forKey:@"userId"];
                        [installation saveInBackground];
                        
                        if (installation.deviceToken) {
                            //add device token to user obj so simple to track and ban
                            [[PFUser currentUser]setObject:installation.deviceToken forKey:@"deviceToken"];
                            [[PFUser currentUser] saveInBackground];
                        }
                        
                        Mixpanel *mixpanel = [Mixpanel sharedInstance];
                        [mixpanel identify:user.objectId];
                        
                        [self hideHUD];
                        [self dismissViewControllerAnimated:YES completion:nil];
                        
                    }
                }];
            }
            else{
                NSLog(@"error logging in %@", error);
                
                if (error.code == 101) {
                    [self showAlertWithTitle:@"Error Logging In" andMsg:@"Invalid Username or Password"];
                    self.passwordField.text = @"";
                }
                else{
                    [self showAlertWithTitle:@"Error Logging In" andMsg:error.description];
                }
                
                [self hideHUD];
                [self.logInButton setEnabled:YES];
                [self.facebookLoginButton setEnabled:YES];
                [self.resetButton setEnabled:YES];
                
                [Answers logCustomEventWithName:@"Log in error"
                               customAttributes:@{
                                                  @"via":@"email",
                                                  @"error":error.description
                                                  }];
            }
        }];
    }
}
- (IBAction)crossPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
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
- (IBAction)facebookLoginPressed:(id)sender {
    [self.delegate loginVCFacebookPressed];
}

-(void)checkUsernameExists:(NSString *)username{
    
    PFQuery *checkUsernameQuery = [PFUser query];
    [checkUsernameQuery whereKey:@"username" equalTo:[username lowercaseString]];
    [checkUsernameQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (objects.count == 0) {
                //wrong username
                self.warningLabel.text = @"That username does not exist";
                
                [Answers logCustomEventWithName:@"Username does not exist in login"
                               customAttributes:@{}];
                
                [self.emailField becomeFirstResponder];
            }
            else{
                //user exists with that username
                self.warningLabel.text = @"";
            }
        }
        else{
            NSLog(@"error checking username %@", error);
        }
    }];
}

#pragma mark - text field delegates

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.emailField) {
        NSString *username = [[self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"@" withString:@""];

        if (![username isEqualToString:@""]) {
            [self checkUsernameExists:username];
        }
    }
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
    NSInteger nextTag = textField.tag + 1;
    // Try to find next responder
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        // Found next responder, so set it.
        [nextResponder becomeFirstResponder];
    } else {
        // Not found, so remove keyboard.
        [textField resignFirstResponder];
        [self loginPressed:self];
    }
    return YES;
}
- (IBAction)resetPressed:(id)sender {
    [Answers logCustomEventWithName:@"Reset on Login Pressed"
                   customAttributes:@{}];
//    
//    //show email composer in the app
//    if ([MFMailComposeViewController canSendMail]) {
//        MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
//        [composeViewController setMailComposeDelegate:self];
//        [composeViewController setToRecipients:@[@"hello@sobump.com"]];
//        [composeViewController setSubject:@"Bump Password Reset"];
//        [composeViewController setMessageBody:@"Hi,\n\nTo reset your Bump password just tell us a few things first\n\nName:ENTER\n\nUsername:ENTER\n\nOld password:ENTER\n\nNew password:ENTER\n\nWe'll send you an email when that's been changed!\n\n🙌" isHTML:NO];
//        [self presentViewController:composeViewController animated:YES completion:nil];
//    }
    resetPassController *vc = [[resetPassController alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    //Add an alert in case of failure
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
