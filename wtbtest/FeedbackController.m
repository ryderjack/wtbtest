//
//  FeedbackController.m
//  wtbtest
//
//  Created by Jack Ryder on 24/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "FeedbackController.h"
#import <Crashlytics/Crashlytics.h>
#import "NavigationController.h"
#import "AppDelegate.h"

@interface FeedbackController ()

@end

@implementation FeedbackController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.usersNameLabel.text = @"";
    self.explainLabel.text = @"";
    
    //set 5 stars as default
    self.starNumber = 5;
    
    [self.firstStar setSelected:YES];
    [self.secondStar setSelected:YES];
    [self.thirdStar setSelected:YES];
    [self.fourthStar setSelected:YES];
    [self.fifthStar setSelected:YES];
    
    self.navigationItem.title = @"R E V I E W";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.starCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    [self setImageBorder];
    self.commentField.delegate= self;
    
    self.user = [[PFUser alloc]init];
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.profanityList = @[@"fuck",@"fucking",@"cunt", @"wanker", @"nigger", @"penis", @"cock", @"shit", @"dick", @"bastard"];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cancelCross"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissFeedback)];
    [self.navigationItem setLeftBarButtonItem:cancelButton];

    UIBarButtonItem *reportButton = [[UIBarButtonItem alloc] initWithTitle:@"Report" style:UIBarButtonItemStylePlain target:self action:@selector(reportPressed)];
    [self.navigationItem setRightBarButtonItem:reportButton];
    
    self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
    [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
    [self.longButton setTitle:@"S U B M I T" forState:UIControlStateNormal];
    [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
    [self.longButton addTarget:self action:@selector(BarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.longButton.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
    
    [self showBarButton];
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Leave Review",
                                      }];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.user = [[PFUser alloc]init];
    self.user.objectId = self.IDUser;
    [self.user fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            
            NSString *nameString = @"";
            
            if ([self.user objectForKey:@"firstName"] && [self.user objectForKey:@"lastName"]) {
                self.usersNameLabel.text = [NSString stringWithFormat:@"%@ %@",[self.user objectForKey:@"firstName"],[self.user objectForKey:@"lastName"]];
            }
            else{
                self.usersNameLabel.text = [NSString stringWithFormat:@"%@",[self.user objectForKey:@"fullname"]];
            }
            
            if ([self.user objectForKey:@"firstName"]) {
                nameString = [self.user objectForKey:@"firstName"];
            }
            else{
                nameString = self.user.username;
            }
            self.explainLabel.text = [NSString stringWithFormat:@"Rate your experience with %@ - let us know how it went.",nameString];
            
            [self.userImageView setFile:[self.user objectForKey:@"picture"]];
            [self.userImageView loadInBackground];
            
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
    
    if (self.editMode) {
        
        [self.editFBObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                NSLog(@"FB OBJ: %@", object);
                
                //preset rating and comment
                self.convoObject = [object objectForKey:@"convo"];
                self.previousReview = [[object objectForKey:@"rating"]intValue];
                
                if ([object objectForKey:@"comment"]) {
                    self.commentField.text = [object objectForKey:@"comment"];
                }
                
                if (self.previousReview == 1) {
                    [self firstStarPressed:self];
                }
                else if (self.previousReview == 2) {
                    [self secondStarPressed:self];
                }
                else if (self.previousReview == 3) {
                    [self thirdStarPressed:self];
                }
                else if (self.previousReview == 4) {
                    [self fourthStarPressed:self];
                }
                else if (self.previousReview == 5) {
                    [self fifthStarPressed:self];
                }
                
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return 1;
    }

    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.starCell;
        }
    }

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 383;
        }
    }

    return 100;
}

- (void)reportPressed{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Report" message:@"Bump takes inappropriate behaviour very seriously.\nIf you feel like this user has violated our terms let us know so we can make your experience on Bump as brilliant as possible. Call +447590554897 if you'd like to speak to one of the team immediately or message Team Bump from Settings" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        PFObject *reportObject = [PFObject objectWithClassName:@"ReportedUsers"];
        reportObject[@"reportedUser"] = self.user;
        reportObject[@"reporter"] = [PFUser currentUser];
        [reportObject saveInBackground];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}
- (IBAction)firstStarPressed:(id)sender {
    self.starNumber = 1;

    if (self.firstStar.selected == YES) {
        [self.secondStar setSelected:NO];
        [self.thirdStar setSelected:NO];
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
    else{
        [self.firstStar setSelected:YES];
    }
    [self.secondStar setSelected:NO];
    [self.thirdStar setSelected:NO];
    [self.fourthStar setSelected:NO];
    [self.fifthStar setSelected:NO];
}
- (IBAction)secondStarPressed:(id)sender {
    self.starNumber = 2;

    if (self.secondStar.selected == YES) {
        [self.thirdStar setSelected:NO];
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
    else{
        [self.secondStar setSelected:YES];
        
        [self.firstStar setSelected:YES];
        [self.thirdStar setSelected:NO];
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
}
- (IBAction)thirdStarPressed:(id)sender {
    self.starNumber = 3;

    if (self.thirdStar.selected == YES) {
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
    else{
        [self.thirdStar setSelected:YES];
        
        [self.firstStar setSelected:YES];
        [self.secondStar setSelected:YES];
        [self.fourthStar setSelected:NO];
        [self.fifthStar setSelected:NO];
    }
}
- (IBAction)fourthStarPressed:(id)sender {
    self.starNumber = 4;

    if (self.fourthStar.selected == YES) {
        [self.fifthStar setSelected:NO];
    }
    else{
        [self.fourthStar setSelected:YES];
        
        [self.firstStar setSelected:YES];
        [self.secondStar setSelected:YES];
        [self.thirdStar setSelected:YES];
        [self.fifthStar setSelected:NO];
    }
}
- (IBAction)fifthStarPressed:(id)sender {
    self.starNumber = 5;

    if (self.fifthStar.selected == YES) {
    }
    else{
        [self.fifthStar setSelected:YES];
        
        [self.firstStar setSelected:YES];
        [self.secondStar setSelected:YES];
        [self.thirdStar setSelected:YES];
        [self.fourthStar setSelected:YES];
    }
}
-(void)setImageBorder{
    self.userImageView.layer.cornerRadius = 35;
    self.userImageView.layer.masksToBounds = YES;
    self.userImageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.userImageView.contentMode = UIViewContentModeScaleAspectFill;
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.0f;
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.commentField) {
        NSArray *words = [textField.text componentsSeparatedByString:@" "];
        for (NSString *string in words) {
            if ([self.profanityList containsObject:string.lowercaseString]) {
                textField.text = @"";
                [self showAlertWithTitle:@"Language" andMsg:@"Bump does not condone any offensive language, if you've had a problem then tap 'Report' and we'll get in touch"];
                return;
            }
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (textField == self.commentField) {
        
        //limit comment length
        if(range.length + range.location > textField.text.length)
        {
            return NO;
        }
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return newLength <= 50;
    }
    return string;
}

-(void)dismissFeedback{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)hideBarButton{
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                         self.buttonShowing = NO;
                     }];
}

-(void)showBarButton{
    self.longButton.alpha = 0.0f;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.longButton.alpha = 1.0f;
                         [self.longButton setEnabled:YES];
                     }
                     completion:^(BOOL finished) {
                         self.buttonShowing = YES;
                     }];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self hideBarButton];
}

-(void)BarButtonPressed{
    [self.longButton setEnabled:NO];
    
    if (self.starNumber == 0) {
        [self showAlertWithTitle:@"Tap a star" andMsg:@"Let other users on Bump know how your experience went, just tap a star 💫"];
        [self.longButton setEnabled:YES];
    }
    else{
        [self showHUD];
        
        PFObject *feedbackObject;
        
        if (self.editMode) {
            feedbackObject = self.editFBObject;
        }
        else{
            feedbackObject = [PFObject objectWithClassName:@"feedback"];
        }
        
        [feedbackObject setObject:self.convoObject forKey:@"convo"];
        [feedbackObject setObject:[NSNumber numberWithInt:self.starNumber] forKey:@"rating"];
        [feedbackObject setObject:[PFUser currentUser] forKey:@"gaveFeedback"];
        
        if (self.purchased == YES) {
            [feedbackObject setObject:self.user forKey:@"sellerUser"];
            [feedbackObject setObject:[PFUser currentUser] forKey:@"buyerUser"];
        }
        else{
            [feedbackObject setObject:self.user forKey:@"buyerUser"];
            [feedbackObject setObject:[PFUser currentUser] forKey:@"sellerUser"];
        }
        
        if (![self.commentField.text isEqualToString:@""]) {
            [Answers logCustomEventWithName:@"Left a Review"
                           customAttributes:@{
                                              @"comment":@"YES"
                                              }];
            [feedbackObject setObject:self.commentField.text forKey:@"comment"];
        }
        else{
            [Answers logCustomEventWithName:@"Left a Review"
                           customAttributes:@{
                                              @"comment":@"NO"
                                              }];
        }
        
        [feedbackObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (!error) {

                //call delegate early to remove review banner in convo
                [self.delegate leftReview];

                //update user's deals data
                PFQuery *dealsQuery = [PFQuery queryWithClassName:@"deals"];
                [dealsQuery whereKey:@"User" equalTo:self.user];
                [dealsQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                    if (object) {
                        
                        if (self.editMode) {
                            //remove previous rating first & don't increment total
                            [object incrementKey:[NSString stringWithFormat:@"star%d", self.previousReview] byAmount:@-1];
                        }
                        else{                            
                            [object incrementKey:@"dealsTotal"]; //deals total is now the total number of reviews a user has
                        }
                        
                        
                        if (self.starNumber == 1) {
                            [object incrementKey:@"star1"];
                        }
                        else if (self.starNumber == 2){
                            [object incrementKey:@"star2"];
                        }
                        else if (self.starNumber == 3){
                            [object incrementKey:@"star3"];
                        }
                        else if (self.starNumber == 4){
                            [object incrementKey:@"star4"];
                        }
                        else if (self.starNumber == 5){
                            [object incrementKey:@"star5"];
                        }

                        int totalReviews = [[object objectForKey:@"dealsTotal"]intValue];
                        
                        // weight the different stars
                        int star1 = [[object objectForKey:@"star1"]intValue]*1;
                        int star2 = [[object objectForKey:@"star2"]intValue]*2;
                        int star3 = [[object objectForKey:@"star3"]intValue]*3;
                        int star4 = [[object objectForKey:@"star4"]intValue]*4;
                        int star5 = [[object objectForKey:@"star5"]intValue]*5;
                        
                        int total = (star1 + star2 + star3 + star4 + star5);
                        int rating = total / totalReviews;
                       
                        [object setObject:[NSNumber numberWithInt:rating] forKey:@"currentRating"];
                        [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                            if (succeeded) {
//                                NSLog(@"saved user's deal data %@", object);
                                
                                if (self.isBuyer == YES) {
                                    [self.convoObject setObject:@"YES" forKey:@"buyerHasReviewed"];
                                }
                                else{
                                    [self.convoObject setObject:@"YES" forKey:@"sellerHasReviewed"];
                                }
                                [self.convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                    if (succeeded) {
                                        
                                        NSLog(@"saved convo");
                                        
                                        [self hideHUD];
                                        
                                        if (self.starNumber >= 4 ) {
                                            
                                            PFUser *current = [PFUser currentUser];
                                            
                                            if ([current objectForKey:@"reviewDate"]) {
                                                //has reviewed before
                                                //check the version then time diff
                                                
                                                NSString *reviewedVersion = [current objectForKey:@"versionReviewed"];
                                                NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
                                                
                                                if ([reviewedVersion isEqualToString:currentVersion]) {
                                                    //already reviewed this version, check if been prompted to invite friends
                                                    [self invitePrompt];
                                                    [self dismissFeedback];
                                                }
                                                else{
                                                    //never reviewed this version, check if last review was later than 14 days ago
                                                    NSDate *lastReviewDate = [current objectForKey:@"reviewDate"];
                                                    
                                                    //check difference between 2 dates
                                                    NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:lastReviewDate];
                                                    double secondsInADay = 86400;
                                                    NSInteger daysBetweenDates = distanceBetweenDates / secondsInADay;
                                                    
                                                    if (daysBetweenDates >= 21) {
                                                        //prompt again if > 3 weeks later
                                                        [Answers logCustomEventWithName:@"Show Rate"
                                                                       customAttributes:@{
                                                                                          @"where": @"feedbackVC"
                                                                                          }];
                                                        [[NSNotificationCenter defaultCenter] postNotificationName:@"showRate" object:self.messageNav];
                                                        [self dismissFeedback];
                                                    }
                                                    else{
                                                        //rated too soon, check if seen invite
                                                        [self invitePrompt];
                                                        [self dismissFeedback];
                                                    }
                                                }
                                            }
                                            else{
                                                //never been asked to review so prompt
                                                [Answers logCustomEventWithName:@"Show Rate"
                                                               customAttributes:@{
                                                                                  @"where": @"feedbackVC"
                                                                                  }];
                                                [[NSNotificationCenter defaultCenter] postNotificationName:@"showRate" object:self.messageNav];
                                                [self dismissFeedback];
                                            }
                                        }
                                        else{
                                            //didn't give a 4+ star rating
                                            if (self.starNumber < 3) {
                                                [self sendPoorFeedbackMessage];
                                            }
                                            [self dismissFeedback];
                                        }
                                    }
                                    else{
                                        NSLog(@"error saving convo %@", error);
                                        [self hideHUD];
                                        [self.longButton setEnabled:YES];
                                        [self showAlertWithTitle:@"Error Saving" andMsg:@"Make sure you're connected to the internet code:4"];
                                    }
                                }];
                                
                                if (!self.editMode) {
                                    NSString *pushString = [NSString stringWithFormat:@"%@ just left you a review ✅", [PFUser currentUser].username];
                                    
                                    NSDictionary *params = @{@"userId": self.IDUser, @"message": pushString, @"sender": [PFUser currentUser].username};
                                    [PFCloud callFunctionInBackground:@"sendPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                                        if (!error) {
                                            NSLog(@"response sending feedback push %@", response);
                                        }
                                        else{
                                            NSLog(@"image push error %@", error);
                                        }
                                    }];
                                }

                            }
                            else{
                                NSLog(@"error saving deal data %@", error);
                                [self hideHUD];
                                [self.longButton setEnabled:YES];
                                [self showAlertWithTitle:@"Error Saving" andMsg:@"Make sure you're connected to the internet code:1"];
                            }
                        }];
                    }
                    else{
                        //no deals object
                        NSLog(@"error %@", error);
                        [self showAlertWithTitle:@"Error Saving" andMsg:@"Make sure you're connected to the internet code:2"];
                        [self.longButton setEnabled:YES];
                        [self hideHUD];
                    }
                }];
            }
            else{
                [self hideHUD];
                NSLog(@"error saving feedback obj %@", error);
                [self showAlertWithTitle:@"Error Saving" andMsg:@"Make sure you're connected to the internet code:3"]; //error on bump leaving feedback with guy - check cause
            }
        }];
    }
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)invitePrompt{
    [self triggerInvite];
}

-(void)triggerInvite{
    [Answers logCustomEventWithName:@"Asked to invite in messages"
                   customAttributes:@{}];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showInvite" object:nil];
}

-(void)sendPoorFeedbackMessage{
    //save message first
    NSString *messageString = @"";
    
    if ([[PFUser currentUser]objectForKey:@"firstName"]) {
        messageString = [NSString stringWithFormat:@"Hey %@,\n\nThanks for leaving a review on Bump and helping the community!\n\nWe noticed you left a poor review for user @%@, is there anything you'd like us to help with?\n\nThanks\nSophie @ Team Bump",[[PFUser currentUser]objectForKey:@"firstName"],self.user.username];
    }
    else{
        messageString = [NSString stringWithFormat:@"Hey\n\nThanks for leaving a review on Bump and helping the community!\n\nWe noticed you left a poor review for user @%@, is there anything you'd like us to help with?\n\nThanks\nSophie @ Team Bump",self.user.username];
    }
    
    //now save report message
    PFObject *messageObject1 = [PFObject objectWithClassName:@"teamBumpMsgs"];
    messageObject1[@"message"] = messageString;
    messageObject1[@"sender"] = [PFUser currentUser];
    messageObject1[@"senderId"] = @"BUMP";
    messageObject1[@"senderName"] = @"Team Bump";
    messageObject1[@"convoId"] = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
    messageObject1[@"status"] = @"sent";
    [messageObject1 saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            
            //update profile tab bar badge
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [[appDelegate.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:@"1"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NewTBMessageReg"];
            
            //update convo
            PFQuery *convoQuery = [PFQuery queryWithClassName:@"teamConvos"];
            NSString *convoId = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
            [convoQuery whereKey:@"convoId" equalTo:convoId];
            [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    
                    //got the convo
                    [object incrementKey:@"totalMessages"];
                    [object setObject:messageObject1 forKey:@"lastSent"];
                    [object setObject:[NSDate date] forKey:@"lastSentDate"];
                    [object incrementKey:@"userUnseen"];
                    [object saveInBackground];
                    
                    [Answers logCustomEventWithName:@"Sent Poor Feedback Message"
                                   customAttributes:@{
                                                      @"status":@"SENT"
                                                      }];
                }
                else{
                    [Answers logCustomEventWithName:@"Sent Poor Feedback Message"
                                   customAttributes:@{
                                                      @"status":@"Failed getting convo"
                                                      }];
                }
            }];
        }
        else{
            NSLog(@"error saving report message %@", error);
            [Answers logCustomEventWithName:@"Sent Poor Feedback Message"
                           customAttributes:@{
                                              @"status":@"Failed saving message"
                                              }];
        }
    }];
}
@end
