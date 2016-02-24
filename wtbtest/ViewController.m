//
//  ViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 19/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ViewController.h"
#import <Parse.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "WelcomeViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Test";
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //present welcome view
    WelcomeViewController *vc = [[WelcomeViewController alloc]init];
    [self presentViewController:vc animated:NO completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)loginButtonClicked
{
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login
     logInWithReadPermissions: @[@"public_profile", @"email"]
     fromViewController:self
     handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
         if (error) {
             NSLog(@"Process error");
         } else if (result.isCancelled) {
             NSLog(@"Cancelled");
         } else {
             NSLog(@"Logged in");
             //do a check for first time
             //if first time save user info to a user, could just do a check if theyve logged in before with NSUserDefaults
             
             if ([[NSUserDefaults standardUserDefaults] objectForKey:@"returning"] == NO) {
                 
                 [self requestFacebook];
                 
//                 [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"returning"];
                 
             }
            
             
             
             //otherwise just dismiss the VC and enter the app
             
             
             
             
         }
     }];
}

//get the user info for the current user (if not already logged in)
-(void)requestFacebook{
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                   parameters:nil];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error)
     {
         if (error == nil)
         {
             NSDictionary *userData = (NSDictionary *)result;
             NSLog(@"user data %@", userData);
         }
     }];
}

@end
