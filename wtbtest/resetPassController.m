//
//  resetPassController.m
//  wtbtest
//
//  Created by Jack Ryder on 01/08/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "resetPassController.h"
#import <Crashlytics/Crashlytics.h>

@interface resetPassController ()

@end

@implementation resetPassController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mainTextField.delegate = self;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    //for when user taps link in email to come back to app & reset password
    if (self.resetMode) {
        [self.mainTextField setSecureTextEntry:YES];
        
        [self.backButton setImage:[UIImage imageNamed:@"cancelCross"] forState:UIControlStateNormal];
        [self.resetButton setTitle:@"Reset" forState:UIControlStateNormal];
        self.mainTextField.placeholder = @"Enter new password";
        self.mainLabel.text = @"Enter your new password, passwords must contain at least 8 characters and no spaces";
        
        //check if userId passed is the same as the user who initiated the request
        NSString *startUser = [[NSUserDefaults standardUserDefaults] valueForKey:@"startUser"];
        
        if ([startUser isEqualToString:self.userId]) {
            //they're the same, good to change
            NSLog(@"they're the same");
        }
        else{
            //userId's don't match, tapped link in someone else's email perhaps
            NSLog(@"reset id's don't match");
            self.dontMatchError = YES;
            [self showAlertWithTitle:@"Reset Error 1" andMsg:@"Make sure you're tapping the link in the latest BUMP Customer Service Password Reset email!"];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self.mainTextField becomeFirstResponder];
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Reset"
                                      }];
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    [self resetPressed:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)resetPressed:(id)sender {
    [self.resetButton setEnabled:NO];
    [self.backButton setEnabled:NO];
    self.warningLabel.text = @"";
    
    [self showHUD];
    
    if (self.resetMode) {
        NSString *newPassword = [self.mainTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([newPassword length] < 8){
            [self showAlertWithTitle:@"Enter a password" andMsg:@"Passwords must contain at least 8 characters"];
            [self hideHUD];
            [self.resetButton setEnabled:YES];
            [self.backButton setEnabled:YES];
        }
        else{
            //we're good to reset the password
            //need to use a cloud code function with the master key
            NSDictionary *params = @{@"userId":self.userId, @"newPassword":newPassword};
            [PFCloud callFunctionInBackground:@"changePassword" withParameters:params block:^(NSDictionary *response, NSError *error) {
                if (!error) {
                    
                    //reset user in defaults so cant keep pressing that link to reset pass
                    [[NSUserDefaults standardUserDefaults]setValue:@"" forKey:@"startUser"];

                    [Answers logCustomEventWithName:@"Changed Password Success"
                                   customAttributes:@{}];
                    
                    NSLog(@"change password response %@", response);

                    [self showPassChangedAlert];
                    
                }
                else{
                    [self hideHUD];

                    NSLog(@"save password error %@", error);
                    
                    [Answers logCustomEventWithName:@"Changed Password Failed"
                                   customAttributes:@{}];
                    
                    [self showAlertWithTitle:@"Error Changing Password" andMsg: [NSString stringWithFormat:@"Please try again! If the problem persists email hello@sobump.com\n%@",error.description]];

                }
            }];
        }
    }
    else{
        //normal reset
        NSString *email = [[self.mainTextField.text lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([email length] == 0){
            [self showAlertWithTitle:@"Enter your email" andMsg:@"We'll email you with instructions on how to reset your password"];
            
            [self hideHUD];
            [self.resetButton setEnabled:YES];
            [self.backButton setEnabled:YES];
        }
        else{
            
            //check user exists first
            PFQuery *checkUsernameQuery = [PFUser query];
            [checkUsernameQuery whereKey:@"email" equalTo:email];
            [checkUsernameQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    self.retrievedUser = (PFUser *)object;
                    
                    //this user has option to sign in with facebook
                    if ([object objectForKey:@"facebookId"] && [object objectForKey:@"password"]) {
                        //user has linked facebook so can log in with facebook or continue with reset
                        [self hideHUD];
                        [self showFacebookAlert];
                    }
                    //for users without a password, there's nothing to reset man!
                    else if ([object objectForKey:@"facebookId"] && ![object objectForKey:@"password"]){
                        [self hideHUD];
                        [self showOnlyFacebookAlert];
                    }
                    else{
                        [self continueReset];
                    }
                }
                else{
                    //wrong email
                    self.warningLabel.text = @"That email does not match our records";
                    [self.mainTextField becomeFirstResponder];
                    
                    [self hideHUD];
                    [self.resetButton setEnabled:YES];
                    [self.backButton setEnabled:YES];
                    NSLog(@"error checking email %@", error);
                }
            }];
        }
    }
}

-(void)continueReset{
    
    NSString *email = [self.mainTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    //user exists with that email
    //now check if sent confirmation email off here recently
    NSString *safeDateString = @"";
    safeDateString = [[NSUserDefaults standardUserDefaults] valueForKey:@"safeResetDate"];
    
    __block int resetCount = [[[NSUserDefaults standardUserDefaults] valueForKey:@"resetCount"]intValue];
    
    if (resetCount > 300) {
        [self showAlertWithTitle:@"Reset Requests Exceeded" andMsg:@"You've requested a password reset 3 times! Send us an email at hello@sobump.com to reset your password"];
        [self hideHUD];
        [self.resetButton setEnabled:YES];
        [self.backButton setEnabled:YES];
        return;
    }
    
    if (![safeDateString isEqualToString:@""]) {
        //got a previous date to check
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSDate *safeDate = [dateFormatter dateFromString:safeDateString];
        
        if ([safeDate compare:[NSDate date]]==NSOrderedDescending) {
            //safe date is later than now, still need to wait
            [self showEmailAlert];
            
            [self hideHUD];
            [self.resetButton setEnabled:YES];
            [self.backButton setEnabled:YES];
            
            [Answers logCustomEventWithName:@"Requested Password Reset too early"
                           customAttributes:@{}];
        }
        else{
            //good to email again
            
            NSDictionary *params = @{@"toEmail": email, @"userId":self.retrievedUser.objectId};
            [PFCloud callFunctionInBackground:@"sendResetPassword" withParameters:params block:^(NSDictionary *response, NSError *error) {
                if (!error) {
                    [Answers logCustomEventWithName:@"Sent Password Reset Email"
                                   customAttributes:@{}];
                    
                    //keep record of who requested pass change to make sure we change correct user's pass
                    [[NSUserDefaults standardUserDefaults]setValue:self.retrievedUser.objectId forKey:@"startUser"];
                    
                    NSLog(@"reset email response %@", response);
                    
                    //increment reset email number count (max. = 3)
                    int count = resetCount++;
                    [[NSUserDefaults standardUserDefaults]setValue:[NSNumber numberWithInt:count] forKey:@"resetCount"];
                    
                    //next safe date to send reset email
                    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
                    dayComponent.hour = 3;
                    NSCalendar *theCalendar = [NSCalendar currentCalendar];
                    NSDate *safeDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
                    NSString *safeString = [dateFormatter stringFromDate:safeDate];
                    [[NSUserDefaults standardUserDefaults]setValue:safeString forKey:@"safeResetDate"];

                    self.dontMatchError = YES;
                    [self showAlertWithTitle:@"Reset Email Sent 📩" andMsg:@"Tap the link the email to reset your password\n\nDon't forget to check your Junk Mail folder!"];
                    [self.resetButton setTitle:@"Sent" forState:UIControlStateNormal];

                    [self hideHUD];
                    [self.resetButton setEnabled:NO];
                    [self.backButton setEnabled:YES];
                    
                }
                else{
                    NSLog(@"email error %@", error);
                    
                    [Answers logCustomEventWithName:@"Error Sending Reset Email"
                                   customAttributes:@{}];
                    
                    [self showAlertWithTitle:@"Error 301" andMsg:@"There was a problem sending your reset email, make sure you're connected to the internet and try again!\n\nIf the problem persists email hello@sobump.com"];
                    
                    [self hideHUD];
                    [self.resetButton setEnabled:YES];
                    [self.backButton setEnabled:YES];
                }
            }];
        }
        
    }
    else{
        //hasn't reset before on here so send & update send date
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        NSDictionary *params = @{@"toEmail": email, @"userId":self.retrievedUser.objectId};
        [PFCloud callFunctionInBackground:@"sendResetPassword" withParameters:params block:^(NSDictionary *response, NSError *error) {
            if (!error) {
                [Answers logCustomEventWithName:@"Sent Password Reset Email"
                               customAttributes:@{}];
                
                //keep record of who requested pass change to make sure we change correct user's pass
                [[NSUserDefaults standardUserDefaults]setValue:self.retrievedUser.objectId forKey:@"startUser"];
                
                NSLog(@"reset email response %@", response);
                
                //increment reset email number count (max. = 3)
                int count = resetCount++;
                [[NSUserDefaults standardUserDefaults]setValue:[NSNumber numberWithInt:count] forKey:@"resetCount"];
                
                //next safe date to send reset email
                NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
                dayComponent.minute = 5;
                NSCalendar *theCalendar = [NSCalendar currentCalendar];
                NSDate *safeDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
                NSString *safeString = [dateFormatter stringFromDate:safeDate];
                [[NSUserDefaults standardUserDefaults]setValue:safeString forKey:@"safeResetDate"];
                
                self.dontMatchError = YES;
                [self showAlertWithTitle:@"Reset Email Sent 📩" andMsg:@"Tap the link the email to reset your password\n\nDon't forget to check your Junk Mail folder"];
                
                [self.resetButton setTitle:@"Sent" forState:UIControlStateNormal];
                
                [self hideHUD];
                [self.resetButton setEnabled:NO];
                [self.backButton setEnabled:YES];
                
            }
            else{
                NSLog(@"email error %@", error);
                
                [Answers logCustomEventWithName:@"Error Sending Reset Email"
                               customAttributes:@{}];
                
                [self showAlertWithTitle:@"Error 302" andMsg:@"There was a problem sending your reset email, make sure you're connected to the internet and try again!\n\nIf the problem persists email hello@sobump.com"];
                
                [self hideHUD];
                [self.resetButton setEnabled:YES];
                [self.backButton setEnabled:YES];
            }
        }];
    }
}

- (IBAction)backPresse:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    return YES;
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
        if (self.dontMatchError) {
            self.dontMatchError = NO;
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showOnlyFacebookAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Facebook Login" message:@"Don't worry, you never signed up to Bump with a password - you signed up with Facebook. To log in just tap 'Continue with Facebook' on the next screen" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }]];

    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showFacebookAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Facebook Account Detected" message:@"We noticed you've connected to Bump via Facebook, instead of resetting your password you can Log in with Facebook now!" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Reset Password" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self showHUD];
        [self continueReset];
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Log in with Facebook" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showPassChangedAlert{
    [self hideHUD];

    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Password Changed!" message:@"✅" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }]];
    
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showEmailAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Reset Email Sent" message:@"You've already requested a password reset! Be sure to check your Junk Folder for an email from BUMP Customer Service (hello@sobump.com) You can request another password reset email in 5 mins" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}
@end
