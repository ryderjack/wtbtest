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

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)facebookTapped:(id)sender {
    
    [PFFacebookUtils logInInBackgroundWithReadPermissions:@[@"public_profile", @"email"] block:^(PFUser *user, NSError *error) {
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
        } else if (user.isNew) {
            NSLog(@"New user signed up and logged in through Facebook!");
            //take to reg VC & save data
            RegisterViewController *vc = [[RegisterViewController alloc]init];
            vc.user = user;
            [self presentViewController:vc animated:YES
                             completion:nil];
            
        } else {
            NSLog(@"User logged in through Facebook!");
            //check if completed reg/tutorial via NSUserDefaults
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"completedReg"] == YES) {
                //take to app
            }
            else{
                //haven't completed it take them there
                RegisterViewController *vc = [[RegisterViewController alloc]init];
                vc.user = user;
                [self presentViewController:vc animated:YES
                                 completion:nil];
            }
        }
    }];
}


@end
