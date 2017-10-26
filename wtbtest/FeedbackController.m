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
#import "ChatWithBump.h"

@interface FeedbackController ()

@end

@implementation FeedbackController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set 5 stars as default
    self.starNumber = 0;
    
    self.ratingLabel.text = @"Rate";
    
//    [self.firstStar setSelected:YES];
//    [self.secondStar setSelected:YES];
//    [self.thirdStar setSelected:YES];
//    [self.fourthStar setSelected:YES];
//    [self.fifthStar setSelected:YES];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    self.navigationItem.title = @"R E V I E W";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.starCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.commentCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.spaceCell.selectionStyle = UITableViewCellSelectionStyleNone;

    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    self.commentView.delegate= self;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.profanityList = @[@"fuck",@"fucking",@"cunt", @"wanker", @"nigger", @"penis", @"cock", @"shit", @"dick", @"bastard"];
    
    self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
    [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
    [self.longButton setTitle:@"S U B M I T" forState:UIControlStateNormal];
    [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
    [self.longButton addTarget:self action:@selector(BarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.longButton.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Leave Review",
                                      }];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section==0) {
        return 0.01f;
    }
    return 32.0f;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            self.fetchedUser = YES;
            [self.longButton setEnabled:YES];
        }
        else{
            [Answers logCustomEventWithName:@"Error fetching feedback user"
                           customAttributes:@{}];
            
            [self showAlertWithTitle:@"Connection Error" andMsg:@"Ensure you're connected to the internet then try again!"];
            [self dismissFeedback];
        }
    }];
    
    if (self.editMode) {
        
        [self.editFBObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                NSLog(@"FB OBJ: %@", object);
                
                //preset rating and comment
                self.previousReview = [[object objectForKey:@"rating"]intValue];
                
                if ([object objectForKey:@"comment"]) {
                    self.commentView.text = [object objectForKey:@"comment"];
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
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 2) {
        return 2;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        return self.starCell;
    }
    else if (indexPath.section == 1){
        return self.commentCell;
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return self.supportCell;
        }
        else if (indexPath.row == 1) {
            return self.spaceCell;
        }
    }

    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            [self setupSupport];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        return 153;
    }
    else if (indexPath.section == 1){
        return 196;
    }
    else if (indexPath.section == 2){
        return 60;
    }

    return 100;
}

- (void)reportPressed{

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
    
    self.commentLabel.text = @"Explain your issue";
    self.ratingLabel.text = @"Terrible";
    
    //check if entered a comment already & if so, show bar button
    if (self.enteredComment) {
        [self showBarButton];
    }
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
    
    self.commentLabel.text = @"Explain your issue";
    self.ratingLabel.text = @"Bad";
    
    //check if entered a comment already & if so, show bar button
    if (self.enteredComment) {
        [self showBarButton];
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
    
    self.commentLabel.text = @"Leave a comment";
    self.ratingLabel.text = @"OK";
    
    //check if entered a comment already & if so, show bar button
    if (self.enteredComment) {
        [self showBarButton];
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
    
    self.commentLabel.text = @"Say thanks";
    self.ratingLabel.text = @"Good";
    
    //check if entered a comment already & if so, show bar button
    if (self.enteredComment) {
        [self showBarButton];
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
    
    self.commentLabel.text = @"Say thanks";
    self.ratingLabel.text = @"Excellent";
    
    //check if entered a comment already & if so, show bar button
    if (self.enteredComment) {
        [self showBarButton];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}



-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.01f;
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

#pragma mark - text view delegates

-(void)textViewDidBeginEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@"e.g. Fast shipping? Item as described? Good communication?"]) {
        textView.text = @"";
        textView.textColor = [UIColor colorWithRed:74/255.0f green:74/255.0f blue:74/255.0f alpha:1.0f];
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView{
    self.enteredComment = NO;

    if ([textView.text isEqualToString:@""]) {
        [self hideBarButton];
        textView.text = @"e.g. Fast shipping? Item as described? Good communication?";
        textView.textColor = [UIColor lightGrayColor];
    }
    else{
        //they've wrote something so do the check for profanity
        NSArray *words = [textView.text componentsSeparatedByString:@" "];
        for (NSString *string in words) {
            if ([self.profanityList containsObject:string.lowercaseString]) {
                [self hideBarButton];
                textView.text = @"e.g. Fast shipping? Item as described? Good communication?";
                textView.textColor = [UIColor lightGrayColor];
                return;
            }
        }
        
        //check if tapped a star too & show submit if so
        if (textView.text.length > 5) {
            self.enteredComment = YES;
            
            if(self.starNumber > 0){
                [self showBarButton];
            }
        }
        else{
            [self hideBarButton];
            [self showAlertWithTitle:@"Comment" andMsg:@"Let other users on BUMP know how your experience went with a longer & detailed comment"];
        }
    }
}

//return key removes keyboard in text view
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

-(void)dismissFeedback{
    [self.navigationController popViewControllerAnimated:YES];
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
    
    //to do's
    // 1. save feedback object
    // 2. save this onto the order object as buyer/sellerReview
    
    // -- dismiss VC --
    
    // 3. send push notifying user who got feedback
    // 4. update user's deals data - can do this in background when leave this VC (involves a query to find it too)
    
    [self.longButton setEnabled:NO];
    
    NSString *commentCheck = [self.commentView.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (self.starNumber == 0) {
        [self showAlertWithTitle:@"Tap a star" andMsg:@"Let other users on BUMP know how your experience went, just tap a star 💫"];
        [self.longButton setEnabled:YES];
    }
    else if ([self.commentView.text isEqualToString:@"e.g. Fast shipping? Item as described? Good communication?"] || [commentCheck isEqualToString:@""]) {
        [self showAlertWithTitle:@"Comment" andMsg:@"Let other users on BUMP know how your experience went with a comment"];
        [self.longButton setEnabled:YES];
    }
    else if (self.commentView.text.length < 5) {
        [self showAlertWithTitle:@"Comment" andMsg:@"Let other users on BUMP know how your experience went with a longer & detailed comment"];
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
        
        [feedbackObject setObject:[NSNumber numberWithInt:self.starNumber] forKey:@"rating"];
        [feedbackObject setObject:[PFUser currentUser] forKey:@"gaveFeedback"];
        [feedbackObject setObject:self.commentView.text forKey:@"comment"];
        [feedbackObject setObject:@"live" forKey:@"status"];
        [feedbackObject setObject:self.user forKey:@"gotFeedback"];
        [feedbackObject setObject:@"YES" forKey:@"order"];
        [feedbackObject setObject:@"YES" forKey:@"order"];
        [feedbackObject setObject:[self.orderObject objectForKey:@"itemImage"] forKey:@"thumbnail"];
        
        //set gave feedback user's basic info so reviews can be queried faster
        if ([[PFUser currentUser]objectForKey:@"picture"]) {
            [feedbackObject setObject:[[PFUser currentUser]objectForKey:@"picture"] forKey:@"gavePicture"];
        }
        [feedbackObject setObject:[PFUser currentUser].username forKey:@"gaveUsername"];

        if (self.purchased == YES) {
            [feedbackObject setObject:self.user.objectId forKey:@"sellerId"];
            [feedbackObject setObject:[PFUser currentUser].objectId forKey:@"buyerId"];
        }
        else{
            [feedbackObject setObject:self.user.objectId forKey:@"buyerId"];
            [feedbackObject setObject:[PFUser currentUser].objectId forKey:@"sellerId"];
        }
        
        [Answers logCustomEventWithName:@"Review Pressed"
                       customAttributes:@{
                                          @"buyer":[NSNumber numberWithBool:self.purchased]
                                          }];
        
        [feedbackObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (!error) {
                
                NSLog(@"saved fb object");
                
                [Answers logCustomEventWithName:@"Saved Feedback"
                               customAttributes:@{
                                                  @"success":@"YES"
                                                  }];
                
                //save review to order object
                if (self.purchased) {
                    [self.orderObject setObject:feedbackObject forKey:@"sellerReview"];
                    [self.orderObject setObject:@"YES" forKey:@"buyerLeftFeedback"];
                    [self.orderObject setObject:@(self.starNumber) forKey:@"sellerStars"];
                }
                else{
                    [self.orderObject setObject:feedbackObject forKey:@"buyerReview"]; //this is the review of the buyer NOT the review the buyer left
                    [self.orderObject setObject:@"YES" forKey:@"sellerLeftFeedback"];
                    [self.orderObject setObject:@(self.starNumber) forKey:@"buyerStars"];
                }
                [self.orderObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        [Answers logCustomEventWithName:@"Saved Feedback on Order"
                                       customAttributes:@{
                                                          @"success":@"YES"
                                                          }];
                        [self.delegate leftReview];
                        
                        NSLog(@"saved feedback on order");
                        //pop VC will rest saves in BG
                        [self hideHUD];
                        [self dismissFeedback];
                    }
                    else{
                        [Answers logCustomEventWithName:@"Saved Feedback on Order"
                                       customAttributes:@{
                                                          @"success":@"NO",
                                                          @"error" : error.description,
                                                          @"feedbackId" : feedbackObject.objectId
                                                          }];
                        
                        //pop VC will rest saves in BG
                        [self hideHUD];
                        [self dismissFeedback];
                    }
                }];
                
                //decide whether to ask this user to review BUMP
                [self sendReview]; //CHANGE
                
                //send push to other user
                if (!self.editMode && !self.sentPush) {
                    self.sentPush = YES;
                    NSString *pushString = [NSString stringWithFormat:@"%@ just left you a review ✅", [PFUser currentUser].username];
                    
                    NSDictionary *params = @{@"userId": self.user.objectId, @"message": pushString, @"sender": [PFUser currentUser].username, @"bumpValue": @"NO", @"listingID": self.orderObject.objectId};
                    [PFCloud callFunctionInBackground:@"sendNewPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                        if (!error) {
                            NSLog(@"response sending review push %@", response);
                            
                            [Answers logCustomEventWithName:@"Sent Review Push"
                                           customAttributes:@{
                                                              @"success":@"YES"
                                                              }];
                        }
                        else{
                            NSLog(@"review push error %@", error);
                            
                            [Answers logCustomEventWithName:@"Sent Review Push"
                                           customAttributes:@{
                                                              @"success":@"NO",
                                                              @"error" : error.description
                                                              }];
                        }
                    }];
                }

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
                                [Answers logCustomEventWithName:@"Saved Deals data"
                                               customAttributes:@{
                                                                  @"success":@"YES"
                                                                  }];
                            }
                            else{
                                [Answers logCustomEventWithName:@"Saved Deals data"
                                               customAttributes:@{
                                                                  @"success":@"NO",
                                                                  @"error" : error.description
                                                                  }];
                            }
                        }];
                    }
                    else{
                        //no deals object
                        [Answers logCustomEventWithName:@"Saved Deals data"
                                       customAttributes:@{
                                                          @"success":@"NO",
                                                          @"error" : error.description
                                                          }];
                    }
                }];
            }
            else{
                //error saving feedback object
                [Answers logCustomEventWithName:@"Saved Feedback"
                               customAttributes:@{
                                                  @"success":@"NO",
                                                  @"error" : error.description
                                                  }];
            }
        }];
    }
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
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
        messageString = [NSString stringWithFormat:@"Hey %@,\n\nThanks for leaving a review on BUMP and helping the community!\n\nWe noticed you left a poor review for user @%@, is there anything you'd like us to help with?\n\nThanks\nSophie @ Team BUMP",[[PFUser currentUser]objectForKey:@"firstName"],self.user.username];
    }
    else{
        messageString = [NSString stringWithFormat:@"Hey\n\nThanks for leaving a review on BUMP and helping the community!\n\nWe noticed you left a poor review for user @%@, is there anything you'd like us to help with?\n\nThanks\nSophie @ Team BUMP",self.user.username];
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

-(void)sendReview{
    if (self.starNumber >= 4 ) {
        
        PFUser *current = [PFUser currentUser];
        
        if ([current objectForKey:@"reviewDate"]) {
            //has reviewed before
            //check the version then time diff
            
            NSString *reviewedVersion = [current objectForKey:@"versionReviewed"];
            NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
            
            if ([reviewedVersion isEqualToString:currentVersion]) {
                //already reviewed this version, check if been prompted to invite friends
//                [self invitePrompt];
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
                }
                else{
                    //rated too soon, check if seen invite
//                    [self invitePrompt];
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
        }
    }
    else{
        //didn't give a 4+ star rating
        if (self.starNumber < 3) {
            [self sendPoorFeedbackMessage];
        }
    }
}

-(void)setupSupport{
    if (self.tappedSupport) {
        NSLog(@"returning from help");
        return;
    }
    self.tappedSupport = YES;
    
    [self showHUD];
    
    //get the support ticket or create a new one if needed
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"supportConvos"];
    NSString *convoId = [NSString stringWithFormat:@"TICKET%@%@", [PFUser currentUser].objectId, self.orderObject.objectId];
    [convoQuery whereKey:@"ticketId" equalTo:convoId];
    [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            self.tappedSupport = NO;
            [self hideHUD];
            
            //convo exists, go there
            ChatWithBump *vc = [[ChatWithBump alloc]init];
            vc.convoId = [NSString stringWithFormat:@"TICKET%@%@", [PFUser currentUser].objectId, self.orderObject.objectId];
            vc.convoObject = object;
            vc.otherUser = [PFUser currentUser];
            vc.supportMode = YES;
            vc.isBuyer = self.purchased;
            //            [self.navigationController tabBarItem].badgeValue = nil;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            //create a new one
            PFObject *convoObject = [PFObject objectWithClassName:@"supportConvos"];
            convoObject[@"user"] = [PFUser currentUser];
            convoObject[@"userId"] = [PFUser currentUser].objectId;
            convoObject[@"ticketId"] = [NSString stringWithFormat:@"TICKET%@%@", [PFUser currentUser].objectId, self.orderObject.objectId];
            convoObject[@"totalMessages"] = @0;
            convoObject[@"status"] = @"open";
            convoObject[@"orderObject"] = self.orderObject;
            convoObject[@"orderDate"] = self.orderObject.createdAt;
            convoObject[@"listing"] = [self.orderObject objectForKey:@"listing"];

            if (self.purchased) {
                convoObject[@"purchase"] = @"YES";
                convoObject[@"buyerId"] = [PFUser currentUser].objectId;
                convoObject[@"sellerId"] = self.user.objectId;
            }
            else{
                convoObject[@"purchase"] = @"NO";
                convoObject[@"buyerId"] = self.user.objectId;
                convoObject[@"sellerId"] = [PFUser currentUser].objectId;
            }
            
            convoObject[@"itemTitle"] = [self.orderObject objectForKey:@"itemTitle"];
            convoObject[@"itemImage"] = [self.orderObject objectForKey:@"itemImage"];
            
            [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    //saved, goto VC
                    self.tappedSupport = NO;
                    [self hideHUD];
                    
                    ChatWithBump *vc = [[ChatWithBump alloc]init];
                    vc.convoId = [NSString stringWithFormat:@"TICKET%@%@", [PFUser currentUser].objectId, self.orderObject.objectId];
                    vc.convoObject = convoObject;
                    vc.otherUser = [PFUser currentUser];
                    vc.supportMode = YES;
                    vc.isBuyer = self.purchased;
                    
                    //                    [self.navigationController tabBarItem].badgeValue = nil;
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else{
                    self.tappedSupport = NO;
                    [self hideHUD];
                    
                    [self showAlertWithTitle:@"Connection Error" andMsg:@"Make sure you're connected to the internet and try again!"];
                    NSLog(@"error saving support ticket");
                }
            }];
        }
    }];
}
@end
