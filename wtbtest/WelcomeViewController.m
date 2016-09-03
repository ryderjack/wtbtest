//
//  WelcomeViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 23/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "WelcomeViewController.h"
#import "RegisterViewController.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <Parse.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "ContainerViewController.h"
#import "NavigationController.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    [self.tutorialTestButton setHidden:YES];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        [[[UIDevice currentDevice] model] hasPrefix:@"iPad"]) {
        // This app is an iPhone app running on an iPad
        [self.descriptionLabel setHidden:YES];
    }
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)facebookTapped:(id)sender {
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
    
    [PFFacebookUtils logInInBackgroundWithReadPermissions:@[@"public_profile", @"email", @"user_friends"] block:^(PFUser *user, NSError *error) {
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
            [self hidHUD];
            
        } else if (user.isNew) {
            NSLog(@"New user signed up and logged in through Facebook!");
            //take to reg VC & save data
            RegisterViewController *vc = [[RegisterViewController alloc]init];
            vc.user = user;
            
            [self hidHUD];
            
            [self.navigationController pushViewController:vc animated:YES];
            
        } else {
            NSLog(@"User logged in through Facebook!");
            //check if completed reg/tutorial via NSUserDefaults
            
            [self hidHUD];
            
            //always take to reg for now to avoid missing data entry
            
//            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"completedReg"] == YES) {//////////////////update before release (remove the 1)
//                //take to app
//                NSLog(@"dismiss popup");
//                [self dismissViewControllerAnimated:YES completion:nil];
//            }
//            else{
                //haven't completed it take them there
                NSLog(@"to reg screen");
                RegisterViewController *vc = [[RegisterViewController alloc]init];
                vc.user = user;
                [self.navigationController pushViewController:vc animated:YES];
//            }
        }
    }];
}
- (IBAction)tutorialPressed:(id)sender {
    ContainerViewController *vc = [[ContainerViewController alloc]init];
    [self presentViewController:vc animated:YES
                     completion:nil];
}

-(void)hidHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
}

@end
