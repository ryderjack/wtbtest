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

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
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
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"completedReg1"] == YES) {//////////////////update before release (remove the 1)
                //take to app
            }
            else{
                //haven't completed it take them there
                RegisterViewController *vc = [[RegisterViewController alloc]init];
                vc.user = user;
                [self.navigationController pushViewController:vc animated:YES];
            }
        }
    }];
}
- (IBAction)tutorialPressed:(id)sender {
    ContainerViewController *vc = [[ContainerViewController alloc]init];
    [self presentViewController:vc animated:YES
                     completion:nil];
}


@end
