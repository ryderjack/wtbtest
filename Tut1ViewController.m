//
//  Tut1ViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 24/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "Tut1ViewController.h"
#import "NavigationController.h"
#import <QuartzCore/QuartzCore.h>
#import <Crashlytics/Crashlytics.h>

@interface Tut1ViewController ()

@end

@implementation Tut1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIView setAnimationsEnabled:YES];
    
    if (self.clickMode != YES) {
        [self.createButton setHidden:YES];
    }
    else{
        [self.createButton setHidden:NO];
        [self.createButton setAlpha:0.0];
        [self.createButton setTitle:@"N E X T" forState:UIControlStateNormal];
    }
    [self.dimissButton setHidden:YES];
    
    //to restart animations upon coming into foreground
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartAnimations) name:@"refreshHome" object:nil];
    
    [self.topLeftImageView setHidden:YES];
    [self.topRightImageView setHidden:YES];
    [self.bottomLeftImageView setHidden:YES];
    [self.bottomRightImageView setHidden:YES];
    
    [self.itemTopLeftImageView setHidden:YES];
    [self.itemTopRightImageView setHidden:YES];
    [self.itemBottomLeftImageView setHidden:YES];
    [self.itemBottomRightImageView setHidden:YES];
    
    self.bumpCount = 0;
    
    if (self.explainMode != YES) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(bump1Pressed)];
        tap.numberOfTapsRequired = 1;
        
        UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(bump2Pressed)];
        tap1.numberOfTapsRequired = 1;
        
        UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(bump3Pressed)];
        tap2.numberOfTapsRequired = 1;
        
        UITapGestureRecognizer *tap3 = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(bump4Pressed)];
        tap3.numberOfTapsRequired = 1;
        
        [self.topLeftImageView addGestureRecognizer:tap];
        [self.topRightImageView addGestureRecognizer:tap1];
        [self.bottomLeftImageView addGestureRecognizer:tap2];
        [self.bottomRightImageView addGestureRecognizer:tap3];
        
        self.pushText = [NSString stringWithFormat:@"%@ just liked your listing 👊", [PFUser currentUser].username];
        self.listings = [NSMutableArray array];
        PFQuery *latestQuery = [PFQuery queryWithClassName:@"wantobuys"];
        [latestQuery whereKey:@"status" equalTo:@"live"];
        [latestQuery orderByDescending:@"createdAt"];
        latestQuery.limit = 4;
        [latestQuery includeKey:@"postUser"];
        [latestQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                [self.listings addObjectsFromArray:objects];
                if (objects.count == 4) {
                    self.firstListing = objects[0];
                    self.secondListing = objects[1];
                    self.thirdListing = objects[2];
                    self.fourthListing = objects[3];
                    
                    [self.itemTopLeftImageView setFile:[self.firstListing objectForKey:@"image1"]];
                    [self.itemTopLeftImageView loadInBackground];
                    
                    [self.itemTopRightImageView setFile:[self.secondListing objectForKey:@"image1"]];
                    [self.itemTopRightImageView loadInBackground];
                    
                    [self.itemBottomLeftImageView setFile:[self.thirdListing objectForKey:@"image1"]];
                    [self.itemBottomLeftImageView loadInBackground];
                    
                    [self.itemBottomRightImageView setFile:[self.fourthListing objectForKey:@"image1"]];
                    [self.itemBottomRightImageView loadInBackground];
                    
                }
                else if (objects.count == 3){
                    self.firstListing = objects[0];
                    self.secondListing = objects[1];
                    self.thirdListing = objects[2];
                    
                    [self.itemTopLeftImageView setFile:[self.firstListing objectForKey:@"image1"]];
                    [self.itemTopLeftImageView loadInBackground];
                    
                    [self.itemTopRightImageView setFile:[self.secondListing objectForKey:@"image1"]];
                    [self.itemTopRightImageView loadInBackground];
                    
                    [self.itemBottomLeftImageView setFile:[self.thirdListing objectForKey:@"image1"]];
                    [self.itemBottomLeftImageView loadInBackground];
                }
                else if (objects.count == 2){
                    self.firstListing = objects[0];
                    self.secondListing = objects[1];
                    
                    [self.itemBottomLeftImageView setFile:[self.firstListing objectForKey:@"image1"]];
                    [self.itemBottomLeftImageView loadInBackground];
                    
                    [self.itemBottomRightImageView setFile:[self.secondListing objectForKey:@"image1"]];
                    [self.itemBottomRightImageView loadInBackground];
                }
                else if (objects.count == 1){
                    self.firstListing = objects[0];
                    
                    [self.itemBottomLeftImageView setFile:[self.firstListing objectForKey:@"image1"]];
                    [self.itemBottomLeftImageView loadInBackground];
                }
                else{
                    NSLog(@"got none");
                }
            }
            else{
                NSLog(@"error getting listings %@", error);
                
                // have a backup plan if get no listings?
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.cursorImageView.transform = CGAffineTransformIdentity;
    [self.cursorImageView setAlpha:0.0f];
    [self.screenImageView setAlpha:0.0f];
    [self.sendOfferImageView setAlpha:0.0f];
    
    if (self.index == 0) {
        [self.topLeftImageView setHidden:YES];
        [self.topRightImageView setHidden:YES];
        [self.bottomLeftImageView setHidden:YES];
        [self.bottomRightImageView setHidden:YES];
        
        [self.heroImageView setHidden:NO];
        self.heroImageView.image = [UIImage imageNamed:@"iPhoneIntro1"];
        self.titleLabel.text = @"Bump";
        self.descriptionLabel.text = @"List items you want & find buyers that want your stuff";
        if (self.clickMode != YES) {
            [self.createButton setHidden:YES];
        }else{
            [UIView animateWithDuration:1.0
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.createButton setAlpha:1.0];
                             }
                             completion:nil];
        }
    }
//    else if (self.index == 1){
//        [self.heroImageView setHidden:NO];
//        self.heroImageView.image = [UIImage imageNamed:@"iPhoneIntro2.1"];
//        self.titleLabel.text = @"Selling";
//        self.descriptionLabel.text = @"1. Tap a listing\n2. Message the buyer\n3. Hit the tag & send them an offer";
//        [self.createButton setHidden:YES];
//        
//        if (self.messageExplain == YES) {
//            [self.dimissButton setAlpha:0.0];
//            [self.dimissButton setHidden:NO];
//            [UIView animateWithDuration:1.0
//                                  delay:1.0
//                                options:UIViewAnimationOptionCurveEaseIn
//                             animations:^{
//                                 [self.dimissButton setAlpha:1.0];
//                             }
//                             completion:nil];
//        }
//        [self setupSelling];
//    }
    else if (self.index == 1){
        [self.topLeftImageView setHidden:YES];
        [self.topRightImageView setHidden:YES];
        [self.bottomLeftImageView setHidden:YES];
        [self.bottomRightImageView setHidden:YES];
        
        [self.heroImageView setHidden:NO];
        self.heroImageView.image = [UIImage imageNamed:@"iPhone3"];
        self.titleLabel.text = @"Discover";
        self.descriptionLabel.text = @"Bump also recommends items that can be purchased straight away";
    }
    else if (self.index == 2){
        [self.topLeftImageView setHidden:YES];
        [self.topRightImageView setHidden:YES];
        [self.bottomLeftImageView setHidden:YES];
        [self.bottomRightImageView setHidden:YES];
        
        [self.heroImageView setHidden:NO];
        self.heroImageView.image = [UIImage imageNamed:@"iPhoneIntro1Bar"];
        self.titleLabel.text = @"Bumping";
        self.descriptionLabel.text = @"Bump listings to help them get noticed just by tapping the up arrow";
        if (![(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"]) {
            [self setupBumping];
        }
        
        if (self.explainMode == YES) {
            [self.dimissButton setAlpha:0.0];
            [self.dimissButton setHidden:NO];
            
            [UIView animateWithDuration:1.0
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.dimissButton setAlpha:1.0];
                             }
                             completion:nil];
        }
    }
    else if (self.index == 3){
        if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
            //iPhone 5
            [self.topLeftImageView setHidden:YES];
            [self.topRightImageView setHidden:YES];
            
            [self.itemTopLeftImageView setHidden:YES];
            [self.itemTopRightImageView setHidden:YES];
        }
        else{
            [self.topLeftImageView setHidden:NO];
            [self.topRightImageView setHidden:NO];
            
            [self.itemTopLeftImageView setHidden:NO];
            [self.itemTopRightImageView setHidden:NO];
        }
        
        [self.bottomLeftImageView setHidden:NO];
        [self.bottomRightImageView setHidden:NO];

        [self.itemBottomLeftImageView setHidden:NO];
        [self.itemBottomRightImageView setHidden:NO];
        
        [self.heroImageView setHidden:YES];
        self.titleLabel.text = @"Get Bumping";
        self.descriptionLabel.text = @"Tap the up arrow on the above listings to Bump them!";
        
        [self.createButton setAlpha:0.0];
        [self.createButton setHidden:NO];
        
        //animate in after a delay if they haven't bumped a listing
        double delayInSeconds = 5.0; // number of seconds to wait
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:1.0
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.createButton setAlpha:1.0];
                             }
                             completion:nil];
        });
    }
}

-(void)dismissSimpleCreateVC:(simpleCreateVC *)controller{
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
}

-(void)setupBumping{
    [UIView animateKeyframesWithDuration:3.0 delay:0.3 options:UIViewKeyframeAnimationOptionCalculationModeLinear | UIViewKeyframeAnimationOptionRepeat animations:^{
        [self.cursorImageView setAlpha:0.0f];
        self.cursorImageView.transform = CGAffineTransformMakeTranslation(-110, 90);
        self.screenImageView.image = [UIImage imageNamed:@"iPhoneIntroBumped"];
        [self.screenImageView setAlpha:0.0f];
        
        //1.1 cursor appears
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.025 animations:^{
            self.cursorImageView.alpha = 1.0f;
        }];
        
        //1.2 cursor moves up
        [UIView addKeyframeWithRelativeStartTime:0.02 relativeDuration:0.4 animations:^{
            self.cursorImageView.transform = CGAffineTransformMakeTranslation(-110,-115);
        }];
        
        //1.3 show bumped listing
        [UIView addKeyframeWithRelativeStartTime:0.4 relativeDuration:0.3 animations:^{
            [self.cursorImageView setAlpha:0.0f];
            [self.screenImageView setAlpha:1.0f];
        }];
        
    } completion:^(BOOL finished) {
        NSLog(@"Animation complete!");
        [self.cursorImageView setAlpha:0.0f];
        [self.screenImageView setAlpha:0.0f];
    }];
}

-(void)setupSelling{
    [UIView animateKeyframesWithDuration:5.5 delay:0.3 options:UIViewKeyframeAnimationOptionCalculationModeLinear | UIViewKeyframeAnimationOptionRepeat animations:^{
        [self.cursorImageView setAlpha:0.0f];
        [self.screenImageView setAlpha:0.0f];
        self.screenImageView.image = [UIImage imageNamed:@"iPhoneIntro2.2"];
        [self.sendOfferImageView setAlpha:0.0f];
        
        //1.1 cursor appears
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.025 animations:^{
            self.cursorImageView.alpha = 1.0f;
        }];
        
        //1.2 cursor moves down
        [UIView addKeyframeWithRelativeStartTime:0.02 relativeDuration:0.1 animations:^{
            self.cursorImageView.transform = CGAffineTransformMakeTranslation(0,90);
        }];
        
        //1.3 show message VC
        [UIView addKeyframeWithRelativeStartTime:0.15 relativeDuration:0.1 animations:^{
            [self.screenImageView setAlpha:1.0f];
        }];
        
        //1.4 cursor moves down to tag
        [UIView addKeyframeWithRelativeStartTime:0.4 relativeDuration:0.3 animations:^{
            self.cursorImageView.transform = CGAffineTransformMakeTranslation(-110, 90);
        }];
        
        //1.5 show message VC
        [UIView addKeyframeWithRelativeStartTime:0.7 relativeDuration:0.2 animations:^{
            [self.cursorImageView setAlpha:0.0f];
            [self.sendOfferImageView setAlpha:1.0];
        }];
        
    } completion:^(BOOL finished) {
        NSLog(@"Animation complete!");
        [self.cursorImageView setAlpha:0.0f];
        [self.screenImageView setAlpha:0.0f];
        [self.sendOfferImageView setAlpha:0.0f];
    }];
}
- (IBAction)createPressed:(id)sender {
    
    if (self.explainMode == YES) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if (self.messageExplain == YES){
        PFUser *current = [PFUser currentUser];
        [current setObject:@"YES" forKey:@"completedMsgIntro3"];
        [current saveInBackground];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else{
        if (self.index == 3) {
            PFUser *current = [PFUser currentUser];
            [current setObject:@"YES" forKey:@"completedIntroTutorial"];
            [current saveInBackground];
            
            [Answers logCustomEventWithName:@"Tutorial finished"
                           customAttributes:@{
                                              @"bumpCount":[NSNumber numberWithInt:self.bumpCount]
                                              }];
            
            simpleCreateVC *vc = [[simpleCreateVC alloc]init];
            vc.introMode = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            //setup next page
            self.index++;
            [self.createButton setAlpha:0.0];
            //stop all animations
            [self removeTutAnimations];
            [self progressTutorial];
        }
    }
}

-(void)bump1Pressed{
    [Answers logCustomEventWithName:@"Intro Bump Pressed"
                   customAttributes:@{
                                      @"Number":@"1"
                                      }];
    self.bumpCount++;
    [UIView animateWithDuration:0.6
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.topLeftImageView setImage:[UIImage imageNamed:@"tryBgBumped"]];
                         [self.createButton setAlpha:1.0];
                     }
                     completion:^(BOOL finished) {
                        
                         //in case user no longer exists
                         if (![[self.firstListing objectForKey:@"postUser"]objectId]) {
                             return;
                         }
                         
                        //send push
                         NSDictionary *params = @{@"userId": [[self.firstListing objectForKey:@"postUser"]objectId], @"message": self.pushText, @"sender": [PFUser currentUser].username, @"bumpValue": @"NO", @"listingID": self.firstListing.objectId};
                         
                         [PFCloud callFunctionInBackground:@"sendNewPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                             if (!error) {
                                 NSLog(@"push response %@", response);
                                 [Answers logCustomEventWithName:@"Push Sent"
                                                customAttributes:@{
                                                                   @"Type":@"Bump"
                                                                   }];
                             }
                             else{
                                 NSLog(@"push error %@", error);
                             }
                         }];
                         
                         PFObject *bumpObj = [PFObject objectWithClassName:@"BumpedListings"];
                         [bumpObj setObject:self.firstListing forKey:@"listing"];
                         [bumpObj setObject:@"live" forKey:@"status"];
                         [bumpObj setObject:[PFUser currentUser] forKey:@"bumpUser"];
                         [bumpObj saveInBackground];
                     }];
}
-(void)bump2Pressed{
    [Answers logCustomEventWithName:@"Intro Bump Pressed"
                   customAttributes:@{
                                      @"Number":@"2"
                                      }];
    self.bumpCount++;
    [UIView animateWithDuration:0.6
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.topRightImageView setImage:[UIImage imageNamed:@"tryBgBumped"]];
                         [self.createButton setAlpha:1.0];
                     }
                     completion:^(BOOL finished) {
                         [self.createButton setAlpha:1.0];
                         
                         //in case user no longer exists
                         if (![[self.secondListing objectForKey:@"postUser"]objectId]) {
                             return;
                         }
                         
                         //send push
                         NSDictionary *params = @{@"userId": [[self.secondListing objectForKey:@"postUser"]objectId], @"message": self.pushText, @"sender": [PFUser currentUser].username, @"bumpValue": @"NO", @"listingID": self.secondListing.objectId};
                         
                         [PFCloud callFunctionInBackground:@"sendNewPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                             if (!error) {
                                 NSLog(@"push response %@", response);
                                 [Answers logCustomEventWithName:@"Push Sent"
                                                customAttributes:@{
                                                                   @"Type":@"Bump"
                                                                   }];
                             }
                             else{
                                 NSLog(@"push error %@", error);
                             }
                         }];
                         
                         PFObject *bumpObj = [PFObject objectWithClassName:@"BumpedListings"];
                         [bumpObj setObject:self.secondListing forKey:@"listing"];
                         [bumpObj setObject:@"live" forKey:@"status"];
                         [bumpObj setObject:[PFUser currentUser] forKey:@"bumpUser"];
                         [bumpObj saveInBackground];
                     }];
}
-(void)bump3Pressed{
    [Answers logCustomEventWithName:@"Intro Bump Pressed"
                   customAttributes:@{
                                      @"Number":@"3"
                                      }];
    self.bumpCount++;
    [UIView animateWithDuration:0.6
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.bottomLeftImageView setImage:[UIImage imageNamed:@"tryBgBumped"]];
                         [self.createButton setAlpha:1.0];
                     }
                     completion:^(BOOL finished) {
                         
                         //in case user no longer exists
                         if (![[self.thirdListing objectForKey:@"postUser"]objectId]) {
                             return;
                         }
                         //send push
                         NSDictionary *params = @{@"userId": [[self.thirdListing objectForKey:@"postUser"]objectId], @"message": self.pushText, @"sender": [PFUser currentUser].username, @"bumpValue": @"NO", @"listingID": self.thirdListing.objectId};
                         
                         [PFCloud callFunctionInBackground:@"sendNewPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                             if (!error) {
                                 NSLog(@"push response %@", response);
                                 [Answers logCustomEventWithName:@"Push Sent"
                                                customAttributes:@{
                                                                   @"Type":@"Bump"
                                                                   }];
                             }
                             else{
                                 NSLog(@"push error %@", error);
                             }
                         }];
                         
                         PFObject *bumpObj = [PFObject objectWithClassName:@"BumpedListings"];
                         [bumpObj setObject:self.thirdListing forKey:@"listing"];
                         [bumpObj setObject:@"live" forKey:@"status"];
                         [bumpObj setObject:[PFUser currentUser] forKey:@"bumpUser"];
                         [bumpObj saveInBackground];
                     }];
}
-(void)bump4Pressed{
    [Answers logCustomEventWithName:@"Intro Bump Pressed"
                   customAttributes:@{
                                      @"Number":@"4"
                                      }];
    self.bumpCount++;
    [UIView animateWithDuration:0.6
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.bottomRightImageView setImage:[UIImage imageNamed:@"tryBgBumped"]];
                         [self.createButton setAlpha:1.0];
                     }
                     completion:^(BOOL finished) {
                         
                         //in case user no longer exists
                         if (![[self.fourthListing objectForKey:@"postUser"]objectId]) {
                             return;
                         }
                         
                         //send push
                         NSDictionary *params = @{@"userId": [[self.fourthListing objectForKey:@"postUser"]objectId], @"message": self.pushText, @"sender": [PFUser currentUser].username, @"bumpValue": @"NO", @"listingID": self.fourthListing.objectId};
                         
                         [PFCloud callFunctionInBackground:@"sendNewPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                             if (!error) {
                                 NSLog(@"push response %@", response);
                                 [Answers logCustomEventWithName:@"Push Sent"
                                                customAttributes:@{
                                                                   @"Type":@"Bump"
                                                                   }];
                             }
                             else{
                                 NSLog(@"push error %@", error);
                             }
                         }];
                         
                         PFObject *bumpObj = [PFObject objectWithClassName:@"BumpedListings"];
                         [bumpObj setObject:self.fourthListing forKey:@"listing"];
                         [bumpObj setObject:@"live" forKey:@"status"];
                         [bumpObj setObject:[PFUser currentUser] forKey:@"bumpUser"];
                         [bumpObj saveInBackground];
                     }];
}

-(void)progressTutorial{
//    if (self.index == 1){
//        [self.heroImageView setHidden:NO];
//        self.heroImageView.image = [UIImage imageNamed:@"iPhoneIntro2.1"];
//        [UIView animateWithDuration:3.5
//                              delay:0.0
//                            options:UIViewAnimationOptionCurveEaseIn
//                         animations:^{
//                             self.titleLabel.text = @"Selling";
//                             self.descriptionLabel.text = @"1. Tap a listing\n2. Message the buyer\n3. Hit the tag & send them an offer";
//                         }
//                         completion:nil];
//        [self setupSelling];
//        [self fadeInProgressButton];
//    }
    if (self.index == 1){
        [self.topLeftImageView setHidden:YES];
        [self.topRightImageView setHidden:YES];
        [self.bottomLeftImageView setHidden:YES];
        [self.bottomRightImageView setHidden:YES];
        
        [self.heroImageView setHidden:NO];
        self.heroImageView.image = [UIImage imageNamed:@"iPhone3"];
        
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.titleLabel.text = @"Discover";
                             self.descriptionLabel.text = @"Bump recommends items from our Seller Network & upcoming releases";
                         }
                         completion:nil];
        
        double delayInSeconds = 1.0; // number of seconds to wait
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.5
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.createButton setAlpha:1.0];
                             }
                             completion:nil];
        });
    }
    else if (self.index == 2){
        [self.topLeftImageView setHidden:YES];
        [self.topRightImageView setHidden:YES];
        [self.bottomLeftImageView setHidden:YES];
        [self.bottomRightImageView setHidden:YES];
        
        [self.heroImageView setHidden:NO];
        self.heroImageView.image = [UIImage imageNamed:@"iPhoneIntro1Bar"];
        self.titleLabel.text = @"Bumping";
        self.descriptionLabel.text = @"Bump listings to help get them noticed just by tapping the up arrow";
        
        //don't show on iPad as its cut off the screen
        if (![(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"]) {
            [self setupBumping];
        }
        
        [self fadeInProgressButton];
    }
    else if (self.index == 3){
        if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
            //iPhone 5
            [self.topLeftImageView setHidden:YES];
            [self.topRightImageView setHidden:YES];
            
            [self.itemTopLeftImageView setHidden:YES];
            [self.itemTopRightImageView setHidden:YES];
        }
        else{
            [self.topLeftImageView setHidden:NO];
            [self.topRightImageView setHidden:NO];
            
            [self.itemTopLeftImageView setHidden:NO];
            [self.itemTopRightImageView setHidden:NO];
        }
        
        [self.bottomLeftImageView setHidden:NO];
        [self.bottomRightImageView setHidden:NO];
        
        [self.itemBottomLeftImageView setHidden:NO];
        [self.itemBottomRightImageView setHidden:NO];
        
        [self.heroImageView setHidden:YES];
        self.titleLabel.text = @"Your turn!";
        self.descriptionLabel.text = @"Tap the up arrow on the above listings to give them a bump";
        [self.createButton setTitle:@"C R E A T E  A  L I S T I N G" forState:UIControlStateNormal];

        [self.createButton setAlpha:0.0];
        [self.createButton setHidden:NO];
        
        double delayInSeconds = 6.0; // number of seconds to wait
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:1.0
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.createButton setAlpha:1.0];
                             }
                             completion:nil];
        });
    }
}

-(void)fadeInProgressButton{
    //animate in after a delay if they haven't bumped a listing
    double delayInSeconds = 2.0; // number of seconds to wait
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.createButton setAlpha:1.0];
                         }
                         completion:nil];
    });
}

-(void)removeTutAnimations{
    [self.sendOfferImageView.layer removeAllAnimations];
    [self.cursorImageView.layer removeAllAnimations];
    [self.screenImageView.layer removeAllAnimations];
}

-(void)restartAnimations{
    [self removeTutAnimations];
    if (self.index == 1) {
        self.cursorImageView.transform = CGAffineTransformMakeTranslation(0,0);
        [self setupSelling];
    }
    else if (self.index == 3){
        self.cursorImageView.transform = CGAffineTransformMakeTranslation(-110, 90);
        [self setupBumping];
    }
}
@end
