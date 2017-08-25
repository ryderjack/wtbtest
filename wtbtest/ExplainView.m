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
    
    if (self.changedMode) {
        //setup change gif and label
        
        NSArray *imageNames = @[@"djk-1.jpg",@"djk-2.jpg",@"djk-3.jpg",@"djk-4.jpg",@"djk-5.jpg",@"djk-6.jpg",@"djk-7.jpg",@"djk-8.jpg",@"djk-9.jpg",@"djk-10.jpg",@"djk-11.jpg",@"djk-12.jpg",@"djk-13.jpg",@"djk-14.jpg",@"djk-15.jpg",@"djk-16.jpg",@"djk-17.jpg",@"djk-18.jpg",@"djk-19.jpg",@"djk-20.jpg",@"djk-21.jpg",@"djk-22.jpg",@"djk-23.jpg",@"djk-24.jpg",@"djk-25.jpg",@"djk-26.jpg",@"djk-27.jpg",@"djk-28.jpg",@"djk-29.jpg",@"djk-30.jpg",];
        
        NSMutableArray *images = [[NSMutableArray alloc] init];
        for (int i = 0; i < imageNames.count; i++) {
            [images addObject:[UIImage imageNamed:[imageNames objectAtIndex:i]]];
        }
        
        // Normal Animation
        self.imageView.animationImages = images;
        self.imageView.animationDuration = 6.0;
        [self.imageView startAnimating];
        
        //set title
        self.titleLabel.text = @"B U M P ' S  C H A N G E D !";
        
        //hide all exlpain stuff
        [self.firstLabel setHidden:YES];
        [self.firstImageView setHidden:YES];
        [self.secondLabel setHidden:YES];
        [self.secondImageView setHidden:YES];
        [self.thirdLabel setHidden:YES];
        [self.thirdImageView setHidden:YES];
        
        //hide cancel and show button
        [self.cancelButton setHidden:YES];
        [self.nextButton setHidden:YES];
        [self.higherNextButton setHidden:NO];
    }
    else if (self.buyingIntro){
        //message buying intro
        
        [Answers logCustomEventWithName:@"Seen buying intro"
                       customAttributes:@{}];
        
        // Normal Animation
        self.imageView.image = [UIImage imageNamed:@"chatImageLarge"];
        
        //set title
        self.titleLabel.text = @"B U Y I N G  O N  B U M P";
        
        self.welcomeBackLabel.text = @"When you’re ready to purchase something just ask the Seller to send their PayPal email address on Bump\n\nYou can tap that message to be taken to PayPal and pay\n\nRemember to pay PayPal Goods & Services - if you’ve got any questions just send Team Bump a message from Settings!";
        
        //hide all exlpain stuff
        [self.firstLabel setHidden:YES];
        [self.firstImageView setHidden:YES];
        [self.secondLabel setHidden:YES];
        [self.secondImageView setHidden:YES];
        [self.thirdLabel setHidden:YES];
        [self.thirdImageView setHidden:YES];
        
        //hide cancel and show button
        [self.cancelButton setHidden:YES];
        [self.nextButton setHidden:YES];
        [self.higherNextButton setHidden:NO];
        
        //set button title
        [self.higherNextButton setTitle:@"Done" forState:UIControlStateNormal];
        
    }
    else if (self.sellingIntro){
        //message selling intro
        
        [Answers logCustomEventWithName:@"Seen selling intro"
                       customAttributes:@{}];
        
        // Normal Animation
        self.imageView.image = [UIImage imageNamed:@"sendPayPalIcon3"];
        
        //set title
        self.titleLabel.text = @"S E L L I N G  O N  B U M P";
        
        self.welcomeBackLabel.text = @"When you’re ready to sell something on Bump tap the ‘Send PayPal email’ button\n\nThis makes it easy for the buyer to pay you through PayPal without leaving the app\n\nBump never handles any payment information, your transaction is only handled by PayPal, we just make everything easier!";
        
        //hide all exlpain stuff
        [self.firstLabel setHidden:YES];
        [self.firstImageView setHidden:YES];
        [self.secondLabel setHidden:YES];
        [self.secondImageView setHidden:YES];
        [self.thirdLabel setHidden:YES];
        [self.thirdImageView setHidden:YES];
        
        //hide cancel and show button
        [self.cancelButton setHidden:YES];
        [self.nextButton setHidden:YES];
        [self.higherNextButton setHidden:NO];
        
        //set button title
        [self.higherNextButton setTitle:@"Done" forState:UIControlStateNormal];
        
    }
    else if (self.picAndTextMode){
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
        
        //decide which cancel button to show
        
        //iPhone 7Plus users get the lower one
        if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
            
            //set button title
            [self.higherNextButton setTitle:@"Done" forState:UIControlStateNormal];
            
            [self.cancelButton setHidden:YES];
            [self.nextButton setHidden:YES];
            [self.higherNextButton setHidden:NO];
        }
        else{
            [self.cancelButton setHidden:NO];
            [self.nextButton setHidden:YES];
            [self.higherNextButton setHidden:YES];
        }

    }
    else{
        [self.imageView setHidden:YES];
        [self.welcomeBackLabel setHidden:YES];
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
        if (self.emailIntro) {
            [self emailSignUpDone];
        }
        else{
            //allow a fb signup to create a listing if they want
            CreateTab *vc = [[CreateTab alloc]init];
            vc.introMode = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
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

-(void)emailSignUpDone{
    
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
    [localNotification setAlertBody:@"What are you selling? List your first item for sale on Bump now! 🤑"]; //make sure this matches the app delegate local notifications handler method
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
    self.customAlert.messageLabel.text = @"Tap to be notified when buyers send you a message on Bump 💬";
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
    [Answers logCustomEventWithName:@"Accepted Push Permissions"
                   customAttributes:@{
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
    
    [self donePressed];
}



@end
