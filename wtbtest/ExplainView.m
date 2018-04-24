//
//  ExplainView.m
//  wtbtest
//
//  Created by Jack Ryder on 11/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "ExplainView.h"
#import "CreateTab.h"
#import <Crashlytics/Crashlytics.h>
#import <Intercom/Intercom.h>

@interface ExplainView ()

@end

@implementation ExplainView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.higherNextButton setHidden:YES];
    self.navigationController.navigationBarHidden = YES;

    if (!self.introMode) {
        [self.nextButton setHidden:YES];
    }
    else{
        [self.cancelButton setHidden:YES];
    }
    
    self.mainCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (self.picAndTextMode){
        //provide an image, text and title then this VC just shows that! Easyyyy
        
        //setup passed on provided info
        self.imageView.image = self.heroImage;
        self.titleLabel.text = self.titleString;
        self.welcomeBackLabel.text = self.mainLabelText;
        
        //hide all exlpain stuff
        [self.firstLabel setHidden:YES];
        [self.firstImageView setHidden:YES];
        [self.secondLabel setHidden:YES];
        [self.secondImageView setHidden:YES];
        [self.thirdLabel setHidden:YES];
        [self.thirdImageView setHidden:YES];
        
        [self.cancelButton setHidden:YES];

        [self.higherNextButton setTitle:@"Dismiss" forState:UIControlStateNormal];
        [self.nextButton setHidden:YES];
        [self.higherNextButton setHidden:NO];

        //iPhone 7Plus users get the lower one
//        if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
//
//            //set button title
//
//            [self.nextButton setHidden:YES];
//            [self.higherNextButton setHidden:NO];
//        }
//        else{
//            [self.nextButton setHidden:YES];
//            [self.higherNextButton setHidden:NO];
//        }

    }
    else{
        [self.imageView setHidden:YES];
        [self.welcomeBackLabel setHidden:YES];
    }
    
    if (self.howWorks) {
        
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.titleLabel.minimumScaleFactor=0.5;
        
        //use top cross on iPhone SE, easier to hit than scrolling
        if([ [ UIScreen mainScreen ] bounds ].size.width != 320){
            //use dismiss button from below not top cross
            [self.cancelButton setHidden:YES];
            
            [self.nextButton setTitle:@"Dismiss" forState:UIControlStateNormal];
            [self.nextButton setHidden:NO];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return self.mainCell;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return 686;
    }
    return 0;
}
- (IBAction)nextPressed:(id)sender {
    if (self.introMode) {
        //email intro ends here since user can't create a listing without verified email
        
        [self completeSignUp];
        
//        if (self.emailIntro) {
//            [self emailSignUpDone];
//        }
//        else{
//            //allow a fb signup to create a listing if they want
//            CreateTab *vc = [[CreateTab alloc]init];
//            vc.introMode = YES;
//            [self.navigationController pushViewController:vc animated:YES];
//        }
    }
    else if(self.howWorks){
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if (self.changedMode) {
        [self setupNormalExplain];
        
        [[PFUser currentUser]setObject:@"YES" forKey:@"seenChangeVC"];
        [[PFUser currentUser]saveInBackground];
    }
    else{
        if (self.buyingIntro) {
            [[PFUser currentUser]setObject:@"YES" forKey:@"buyingIntro2"];
            [[PFUser currentUser]saveInBackground];
        }
        else if (self.sellingIntro) {
            [[PFUser currentUser]setObject:@"YES" forKey:@"sellingIntro2"];
            [[PFUser currentUser]saveInBackground];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
- (IBAction)cancelPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)setupNormalExplain{
    //scroll to top
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    //set title
    self.titleLabel.text = @"H O W  B U M P  W O R K S";
    
    [self.imageView setHidden:YES];
    [self.welcomeBackLabel setHidden:YES];
    
    //hide all exlpain stuff
    [self.firstLabel setAlpha:0.0];
    [self.firstImageView setAlpha:0.0];
    [self.secondLabel setAlpha:0.0];
    [self.secondImageView setAlpha:0.0];
    [self.thirdLabel setAlpha:0.0];
    [self.thirdImageView setAlpha:0.0];
    
    //unhide lower button
    [self.nextButton setTitle:@"Done" forState:UIControlStateNormal];
    [self.nextButton setAlpha:0.0];
    [self.nextButton setHidden:NO];

    
    [self.firstLabel setHidden:NO];
    [self.firstImageView setHidden:NO];
    [self.secondLabel setHidden:NO];
    [self.secondImageView setHidden:NO];
    [self.thirdLabel setHidden:NO];
    [self.thirdImageView setHidden:NO];
    
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.firstLabel setAlpha:1.0];
                         [self.firstImageView setAlpha:1.0];
                         [self.secondLabel setAlpha:1.0];
                         [self.secondImageView setAlpha:1.0];
                         [self.thirdLabel setAlpha:1.0];
                         [self.thirdImageView setAlpha:1.0];
                         
                         [self.nextButton setAlpha:1.0];
                         [self.higherNextButton setAlpha:0.0];
                         
                     }
                     completion:nil];
    
    self.changedMode = NO;
}

-(void)completeSignUp{
    
    //schedule local push reminder to create first listing
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
    
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
    [localNotification setAlertBody:@"What are you selling? List your first item for sale on BUMP now 🏷"]; //make sure this matches the app delegate local notifications handler method
    [localNotification setFireDate: combinedDate];
    [localNotification setTimeZone: [NSTimeZone defaultTimeZone]];
    [localNotification setRepeatInterval: 0];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    //show push alert then dismiss
    [self showPushAlert];
}

#pragma mark - push prompt
-(void)showPushAlert{
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
    self.customAlert = (customAlertViewClass *)[nib objectAtIndex:0];
    self.customAlert.delegate = self;
    self.customAlert.titleLabel.text = @"Enable Push";
    self.customAlert.messageLabel.text = @"Tap to be notified when buyers send you a message on BUMP";
    self.customAlert.numberOfButtons = 2;
    [self.customAlert.secondButton setTitle:@"E N A B L E" forState:UIControlStateNormal];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, -157, 250, 157)];
    }
    else{
        [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, -188, 300, 188)]; //iPhone 6/7 specific
    }
    
    self.customAlert.layer.cornerRadius = 10;
    self.customAlert.layer.masksToBounds = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.customAlert];
    
    [UIView animateWithDuration:1.0
                          delay:0.2
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.customAlert setFrame:CGRectMake(0, 0, 250, 157)];
                            }
                            else{
                                [self.customAlert setFrame:CGRectMake(0, 0, 300, 188)]; //iPhone 6/7 specific
                            }
                            self.customAlert.center = self.view.center;
                            
                        }
                     completion:nil];
}

-(void)donePressed{
    
    //register user's info with Intercom so they get the welcome msg at the correct time
    //update Intercom with user info
    NSDictionary *params = @{@"userId": [PFUser currentUser].objectId};
    [PFCloud callFunctionInBackground:@"verifyIntercomUserId" withParameters:params block:^(NSString *hash, NSError *error) {
        if (!error) {
            [Intercom setUserHash:hash];
            [Intercom registerUserWithUserId:[PFUser currentUser].objectId];
            
            //setup intercom listener
            [[NSNotificationCenter defaultCenter] postNotificationName:@"registerIntercom" object:nil];
            
            //add standard info to user object
            ICMUserAttributes *userAttributes = [ICMUserAttributes new];
            userAttributes.email = [PFUser currentUser][@"email"];
            userAttributes.signedUpAt = [NSDate date];
            userAttributes.name = [PFUser currentUser][@"fullname"];
            
            NSString *affiliate = @"none";
            
            if ([PFUser currentUser][@"affiliate"]) {
                affiliate = [PFUser currentUser][@"affiliate"];
            }
            
            if (self.emailIntro) {
                //finish adding custom intercom attributes for email mode
                userAttributes.customAttributes = @{@"email_sign_up" : @YES,
                                                    @"currency": self.currency,
                                                    @"Username":[PFUser currentUser].username,
                                                    @"affiliate":affiliate
                                                    };
                
            }
            else if([PFUser currentUser][@"facebookId"]){
                //and same for facebook mode
                userAttributes.customAttributes = @{@"email_sign_up" : @NO,
                                                    @"currency": self.currency,
                                                    @"Username":[PFUser currentUser].username,
                                                    @"facebookId": [PFUser currentUser][@"facebookId"],
                                                    @"affiliate":affiliate
                                                    };
            }
            
            [Intercom updateUser:userAttributes];
            
            //use this property so we can know who ended reg early and send them a welcome message the next time they open the app
            [[PFUser currentUser]setObject:@"YES" forKey:@"sentWelcomeMessage"];
            [[PFUser currentUser]saveInBackground];
            
        }
        else{
            NSLog(@"reg intercom veri error");
            [Answers logCustomEventWithName:@"Intercom Verify Error"
                           customAttributes:@{
                                              @"where":@"registration"
                                              }];
        }
    }];
    
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
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, 1000, 250, 157)];
                            }
                            else{
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, 1000, 300, 188)]; //iPhone 6/7 specific
                            }
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         [self.customAlert setAlpha:0.0];
                         [self.customAlert removeFromSuperview];
                         self.customAlert = nil;
                         
                         //dismiss whole VC
                         [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshHome" object:nil];
                         [self dismissViewControllerAnimated:YES completion:nil];
                     }];
}

-(void)firstPressed{
    [Answers logCustomEventWithName:@"Denied Push Permissions"
                   customAttributes:@{
                                      @"username":[PFUser currentUser].username
                                      }];
    [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"declinedPushPermissions"];
    [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"declinedDate"];
    
    [self donePressed];
}

-(void)secondPressed{
    //present push dialog
    if ([PFUser currentUser]) {
        [Answers logCustomEventWithName:@"Accepted Push Permissions"
                       customAttributes:@{
                                          @"username":[PFUser currentUser].username
                                          }];
    }

    [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"askedForPushPermission"];
    [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"declinedPushPermissions"];
    
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    [self donePressed];
}



@end
