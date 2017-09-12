//
//  WelcomeViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 23/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "WelcomeViewController.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <Parse.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "ContainerViewController.h"
#import "NavigationController.h"
#import <Crashlytics/Crashlytics.h>
#import "AppDelegate.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.brandArray = [NSArray arrayWithObjects:@"supremeWelcome", @"palaceWelcome", @"pattaWelcome",@"offWhiteWelcome",@"goshaWelcome", @"adidasWelcome", @"stoneyWelcome", @"nikeWelcome",@"kithWelcome",@"ralphWelcome",@"yeezyWelcome",@"bapeWelcome",@"gucciWelcome",@"stussyWelcome",@"balenWelcome",@"cdgWelcome",@"veteWelcome",@"vloneWelcome",@"rafWelcome",@"asscWelcome",@"jordanWelcome",@"LVWelcome",@"placesWelcome",@"champWelcome", nil];
    
    //brand swipe view
    self.brandSwipeView.delegate = self;
    self.brandSwipeView.dataSource = self;
    self.brandSwipeView.clipsToBounds = YES;
    self.brandSwipeView.pagingEnabled = NO;
    self.brandSwipeView.truncateFinalPage = NO;
    [self.brandSwipeView setBackgroundColor:[UIColor clearColor]];
    self.brandSwipeView.alignment = SwipeViewAlignmentEdge;
    self.brandSwipeView.autoscroll = 0.6;
    self.brandSwipeView.wrapEnabled = YES;
    [self.brandSwipeView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)facebookTapped:(id)sender {
    [Answers logCustomEventWithName:@"Sign up Pressed"
                   customAttributes:@{
                                      @"type":@"Facebook"
                                      }];
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
    
    [PFFacebookUtils logInInBackgroundWithReadPermissions:@[@"public_profile", @"email", @"user_friends"] block:^(PFUser *user, NSError *error) {
        if (!user) {
            NSLog(@"error %@", error);
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
            //check if completed reg/tutorial via NSUserDefaults/user object
            [self hidHUD];
            
            NSLog(@"USER %@", [PFUser currentUser]);
            
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
            
            PFQuery *megaBanQuery = [PFQuery orQueryWithSubqueries:@[bannedInstallsQuery, bannedQuery]];
            [megaBanQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object){
                    //user is banned - log them out
                    NSLog(@"user is banned");
                    
                    [PFUser logOut];
                    
                    [Answers logCustomEventWithName:@"Logging Banned User Out"
                                   customAttributes:@{
                                                      @"from":@"Welcome"
                                                      }];
                    [self showAlertWithTitle:@"Account Restricted" andMsg:@"If you feel you're seeing this as a mistake then let us know hello@sobump.com"];

                }
                else{
                    //do final check against NSUserDefaults incase user was banned without device token coz didn't enable push
                    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"banned"] isEqualToString:@"YES"]) {
                        NSLog(@"user is banned");
                        
                        [PFUser logOut];
                        
                        [Answers logCustomEventWithName:@"Logging Banned User Out"
                                       customAttributes:@{
                                                          @"from":@"Welcome",
                                                          @"trigger":@"defaults"
                                                          }];
                        [self showAlertWithTitle:@"Account Restricted" andMsg:@"If you feel you're seeing this as a mistake then let us know hello@sobump.com"];
                        return;
                    }
                    
                    //not banned, now check if completed reg
                    NSLog(@"not banned");
                    
                    if ([[[PFUser currentUser]objectForKey:@"completedReg"]isEqualToString:@"YES"] ) { //CHECK
                        
                        //set user as tabUser
                        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                        appDelegate.profileView.user = user;
                        
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
                        
                        //take to app
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshHome" object:nil];
                        [self.delegate welcomeDismissed];
                        [self dismissViewControllerAnimated:YES completion:nil];
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
    }];
}

-(void)hidHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
}

- (IBAction)loginPressed:(id)sender {
    [Answers logCustomEventWithName:@"Log in Pressed"
                   customAttributes:@{}];
    
    loginEmailController *vc = [[loginEmailController alloc]init];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)signUpWithEmailPressed:(id)sender {
    [Answers logCustomEventWithName:@"Sign up Pressed"
                   customAttributes:@{
                                      @"type":@"Email"
                                      }];
    
    PFUser *newUser = [PFUser new];
    
    RegisterViewController *vc = [[RegisterViewController alloc]init];
    vc.user = newUser;
    vc.emailMode = YES;
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - swipe view delegates

-(UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view{
    
    UIImageView *imageView = nil;
    
    if (view == nil)
    {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80,90)];
        [view setAlpha:1.0];
        imageView = [[UIImageView alloc]initWithFrame:CGRectMake(5,5, 50, 50)];
        [view addSubview:imageView];
    }
    else
    {
        imageView = [[view subviews] lastObject];
    }
    
    //set brand image
    [imageView setImage:[UIImage imageNamed:self.brandArray[index]]];
    
    return view;
}

-(void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView{
    //do nothing
}
-(void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index{
    //do nothing
}

-(NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView{
    return self.brandArray.count;
}

#pragma mark - facebook login called delegates 

-(void)loginVCFacebookPressed{
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self facebookTapped:self];
}

-(void)RegVCFacebookPressed{
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self facebookTapped:self];
}

-(void)RegVCLoginPressed{
    [self loginPressed:self];
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}
@end
