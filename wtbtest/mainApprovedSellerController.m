//
//  mainApprovedSellerController.m
//  wtbtest
//
//  Created by Jack Ryder on 01/06/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "mainApprovedSellerController.h"
#import <Crashlytics/Crashlytics.h>

@interface mainApprovedSellerController ()

@end

@implementation mainApprovedSellerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.topStatusLabel setHidden:YES];
    [self.bottomStatusLabel setHidden:YES];
    
    self.mainCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
    [self.longButton setTitle:@"S U B M I T" forState:UIControlStateNormal];
    [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
    [self.longButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
    [self.longButton addTarget:self action:@selector(submitPressed) forControlEvents:UIControlEventTouchUpInside];
    self.longButton.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Approved Seller Form"
                                      }];
    
    [self getSellerApp];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self checkPushStatus];
    
    if (self.barButtonPressed == YES) {
        self.barButtonPressed = NO;
    }
    
    [self checkStatus];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return self.mainCell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 669;
}
- (IBAction)legitButtonPressed:(id)sender {
    
    legitCheckController *vc = [[legitCheckController alloc]init];
    vc.delegate = self;
    
    vc.sellerApp = self.sellerApplication;
    
    self.barButtonPressed = YES;
    
    if (!self.sellerApplication) {
        [self showAlertWithTitle:@"Woops" andMsg:@"Make sure you're connected to the internet!"];
        return;
    }
    
    [self presentViewController:vc animated:YES completion:nil];

}
- (IBAction)howListButtonPressed:(id)sender {
    
    sellerTutController *vc = [[sellerTutController alloc]init];
    vc.delegate = self;
    vc.sellerApp = self.sellerApplication;
    
    self.barButtonPressed = YES;
    
    if (self.listButton.selected == YES) {
        vc.alreadySeen = YES;
    }
    
    if (!self.sellerApplication) {
        [self showAlertWithTitle:@"Woops" andMsg:@"Make sure you're connected to the internet!"];
        return;
    }
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)pushPressed:(id)sender {
    if (!self.pushDone) {
        if (self.pushButton.selected == NO) {
            
            //prompt for push permissions
            [self showPushPrompt];
        }
    }
}
- (IBAction)dismissPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)submitPressed{
    
    [self.longButton setEnabled:NO];
    [self showHUD];
    
    if (self.newReqMode == YES) {
        
        self.sellerApplication[@"submitted"] = @"NO";
        self.sellerApplication[@"denied"] = @"NO";
        
        self.sellerApplication[@"howToList"] = @"NO";
        self.sellerApplication[@"legitCheck"] = @"NO";
        
        [self.sellerApplication incrementKey:@"reviewCount"];

        [self.sellerApplication saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                
                self.submitted = NO;
                self.legitCheckDone = NO;
                self.howListDone = NO;
                
                [Answers logCustomEventWithName:@"New Request Pressed"
                               customAttributes:@{}];
                
                [self.topStatusLabel setHidden:YES];
                [self.bottomStatusLabel setHidden:YES];
                
                [self.listButton setHidden:NO];
                [self.legitButton setHidden:NO];
                [self.pushButton setHidden:NO];
                [self.mainLabel setHidden:NO];
                
                [self.longButton setTitle:@"S U B M I T" forState:UIControlStateNormal];
                [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
                self.newReqMode = NO;
                
                [self hideBarButton];
                [self.longButton setEnabled:YES];
                
                
                [self hidHUD];
            }
            else{
                [self hidHUD];
                [self.longButton setEnabled:YES];
                [self showAlertWithTitle:@"Saving Error" andMsg:@"Make sure you're connected to the internet"];
            }
        }];
        
        
    }
    else{
        
        if ([[self.sellerApplication objectForKey:@"reviewCount"]intValue] > 3) {
            [self showAlertWithTitle:@"Request Limit" andMsg:@"You've hit your request limit! Send Team Bump a message from Settings to resolve this"];
            return;
        }
        
        self.sellerApplication[@"submitted"] = @"YES";
        self.sellerApplication[@"reviewed"] = @"NO";
        self.sellerApplication[@"submissionDate"] = [NSDate date];
        
        [self.sellerApplication saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                [self hidHUD];
                [self hideBarButton];
                
                [Answers logCustomEventWithName:@"Seller Application Form Submitted"
                               customAttributes:@{}];
                
                
                // show waiting msg
                [self.topStatusLabel setHidden:NO];
                [self.bottomStatusLabel setHidden:NO];
                
                self.topStatusLabel.text = @"Seller Request Submitted";
                self.bottomStatusLabel.text = @"We’ll send you a notification when it’s been reviewed 🤞";
                
                [self.listButton setHidden:YES];
                [self.legitButton setHidden:YES];
                [self.pushButton setHidden:YES];
                [self.mainLabel setHidden:YES];
                
            }
            else{
                [self hidHUD];
                [self.longButton setEnabled:YES];
                [self showAlertWithTitle:@"Submission Error" andMsg:@"Make sure you're connected to the internet"];
            }
        }];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self hidHUD];
    [self hideBarButton];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    if (self.barButtonPressed != YES) {
        //fail safe to avoid bar button wrongly showing
        self.longButton = nil;
    }
}

-(void)hideBarButton{
    self.buttonShowing = NO;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)showBarButton{
    self.buttonShowing = YES;
    self.longButton.alpha = 0.0f;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.longButton.alpha = 1.0f;
                         [self.longButton setEnabled:YES];
                     }
                     completion:^(BOOL finished) {
                     }];
}


-(void)getSellerApp{
    [self showHUD];
    PFQuery *applicationQuery = [PFQuery queryWithClassName:@"SellerApps"];
    [applicationQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    [applicationQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            [self hidHUD];

            self.sellerApplication = object;
            
            //check if been submitted first
            if ([[self.sellerApplication objectForKey:@"submitted"]isEqualToString:@"YES"]) {
                self.submitted = YES;
                
                if ([[self.sellerApplication objectForKey:@"reviewed"]isEqualToString:@"NO"]){
                    //show waiting screen
                    [self.topStatusLabel setHidden:NO];
                    [self.bottomStatusLabel setHidden:NO];
                    
                    self.topStatusLabel.text = @"Seller Request Submitted";
                    self.bottomStatusLabel.text = @"We’ll send you a notification when it’s been reviewed 🤞";
                    
                    [self.listButton setHidden:YES];
                    [self.legitButton setHidden:YES];
                    [self.pushButton setHidden:YES];
                    [self.mainLabel setHidden:YES];
                    
                    [self.longButton setAlpha:0.0];
                    
                }
                else if ([[self.sellerApplication objectForKey:@"denied"]isEqualToString:@"YES"]){
                    //show denied screen
                    [self.topStatusLabel setHidden:NO];
                    [self.bottomStatusLabel setHidden:NO];
                    
                    self.topStatusLabel.text = @"Woops!";
                    self.bottomStatusLabel.text = @"Unfortunately we couldn't approve you now - We get 1000s of requests and can’t approve them all 😩";
                    
                    [self.listButton setHidden:YES];
                    [self.legitButton setHidden:YES];
                    [self.pushButton setHidden:YES];
                    [self.mainLabel setHidden:YES];
                    
                    [self.longButton setTitle:@"N E W  R E Q U E S T" forState:UIControlStateNormal];
                    [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:12]];
                    self.newReqMode = YES;
                    [self showBarButton];

                }
                else if ([[self.sellerApplication objectForKey:@"approved"]isEqualToString:@"YES"]){
                    //show approved screen
                    [self.topStatusLabel setHidden:NO];
                    [self.bottomStatusLabel setHidden:NO];
                    
                    self.topStatusLabel.text = @"🙌 Approved 🙌";
                    self.bottomStatusLabel.text = @"Congrats, you’re now an approved seller! Tap the + to list items for sale";
                    
                    [self.listButton setHidden:YES];
                    [self.legitButton setHidden:YES];
                    [self.pushButton setHidden:YES];
                    [self.mainLabel setHidden:YES];
                    
                    [self.longButton setAlpha:0.0];
                }
            }
            else{
                //hasn't been submitted
                //check what's already been completed
                if ([[self.sellerApplication objectForKey:@"legitCheck"]isEqualToString:@"YES"]) {
                    [self.legitButton setSelected:YES];
                    self.legitCheckDone = YES;
                }
                
                if ([[self.sellerApplication objectForKey:@"howToList"]isEqualToString:@"YES"]) {
                    [self.listButton setSelected:YES];
                    self.howListDone = YES;
                }
                
                //decide whether to show the bar button
                [self checkStatus];
            }
            
        }
        else{
            //no application obj so create one
            
            PFObject *sellerApp = [PFObject objectWithClassName:@"SellerApps"];
            [sellerApp setObject:[PFUser currentUser] forKey:@"user"];
            sellerApp[@"submitted"] = @"NO";
            sellerApp[@"howToList"] = @"NO";
            sellerApp[@"legitCheck"] = @"NO";
            [sellerApp saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    self.sellerApplication = sellerApp;
                    NSLog(@"saved seller app");
                    [self hidHUD];
                }
                else{
                    NSLog(@"error saving seller app");
                    [self showAlertWithTitle:@"Saving Error" andMsg:@"Make sure you're connected to the internet!"];
                    [self hidHUD];
                }
            }];

        }
    }];
    
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

#pragma HUD

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
}

-(void)hidHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
}

-(void)checkStatus{
    //show bar button if ready to submit!
    if (self.pushDone && self.howListDone && self.legitCheckDone && self.buttonShowing != YES && self.submitted != YES) {
        [self showBarButton];
    }
}

#pragma completion delegates

-(void)completedLegitVC{
    self.legitCheckDone = YES;
    self.legitButton.selected = YES;
    
    [self checkStatus];
}

-(void)completedSellerTut{
    self.howListDone = YES;
    self.listButton.selected = YES;
    
    [self checkStatus];
}

#pragma push prompt methods

-(void)showPushPrompt{
    self.shownPushAlert = YES;
    self.searchBgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.searchBgView.alpha = 0.0;
    [self.searchBgView setBackgroundColor:[UIColor blackColor]];
    [[UIApplication sharedApplication].keyWindow addSubview:self.searchBgView];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.searchBgView.alpha = 0.6f;
                     }
                     completion:nil];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"customAlertView" owner:self options:nil];
    self.pushAlert = (customAlertViewClass *)[nib objectAtIndex:0];
    self.pushAlert.delegate = self;
    self.pushAlert.titleLabel.text = @"Enable Push";

    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"declinedPushPermissions"]) {
        //show normal prompt
        self.pushAlert.messageLabel.text = @"Get notified when buyers message you on Bump";
        [self.pushAlert.secondButton setTitle:@"E N A B L E" forState:UIControlStateNormal];
        self.settingsMode = NO;
    }
    else{
        //show prompt to goto settings and turn push back on
        self.pushAlert.messageLabel.text = @"Get notified when buyers message you - Goto Settings now to enable Push";
        [self.pushAlert.secondButton setTitle:@"S E T T I N G S" forState:UIControlStateNormal];
        self.settingsMode = YES;
    }

    self.pushAlert.numberOfButtons = 2;
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, -157, 250, 157)];
    }
    else{
        [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, -188, 300, 188)]; //iPhone 6/7 specific
    }
    
    self.pushAlert.layer.cornerRadius = 10;
    self.pushAlert.layer.masksToBounds = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.pushAlert];
    
    [UIView animateWithDuration:0.5
                          delay:0.2
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.pushAlert setFrame:CGRectMake(0, 0, 250, 157)];
                            }
                            else{
                                [self.pushAlert setFrame:CGRectMake(0, 0, 300, 188)]; //iPhone 6/7 specific
                            }
                            self.pushAlert.center = self.view.center;
                            
                        }
                     completion:nil];
}

-(void)donePressed{
    //check push status
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self checkPushStatus];
    });
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.searchBgView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         self.searchBgView = nil;
                     }];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, 1000, 250, 157)];
                            }
                            else{
                                [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, 1000, 300, 188)]; //iPhone 6/7 specific
                            }
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         [self.pushAlert setAlpha:0.0];
                         [self.pushAlert removeFromSuperview];
                         self.pushAlert = nil;
                     }];
}

#pragma custom alert delegates

-(void)firstPressed{
    //cancelled
    [self donePressed];
}
-(void)secondPressed{
    
    if (self.settingsMode == YES) {
        //take user to settings
        NSString *settings = UIApplicationOpenSettingsURLString;
        NSURL *settingsURL = [NSURL URLWithString:settings];
        [[UIApplication sharedApplication]openURL:settingsURL];
    }
    else{
        //push reminder
        [Answers logCustomEventWithName:@"Accepted Push Permissions"
                       customAttributes:@{
                                          @"mode":@"seller application",
                                          @"username":[PFUser currentUser].username
                                          }];
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"askedForPushPermission"];
        [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"declinedPushPermissions"];
        
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    [self donePressed];
}

-(void)checkPushStatus{
    if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
        self.pushButton.selected = YES;
        self.pushDone = YES;
    }
    else{
        self.pushButton.selected = NO;
        self.pushDone = NO;
    }
}

@end
