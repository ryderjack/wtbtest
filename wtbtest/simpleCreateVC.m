//
//  simpleCreateVC.m
//  wtbtest
//
//  Created by Jack Ryder on 25/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "simpleCreateVC.h"
#import "UIImage+Resize.h"
#import "FBGroupShareViewController.h"
#import <Crashlytics/Crashlytics.h>
#import "AppDelegate.h"
#import "ForSaleListing.h"
#import "ForSaleCell.h"
#import "CreateViewController.h"
#import "CreateForSaleListing.h"
#import "mainApprovedSellerController.h"
#import "Mixpanel/Mixpanel.h"

@interface simpleCreateVC ()
@end

@implementation simpleCreateVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.listingAsLabel setHidden:YES];
    [self.orImageView setHidden:YES];
    [self.sellButton setHidden:YES];
    [self.tutorialImageView setHidden:YES];

    self.titleTextLabel.delegate = self;
    self.photostotal = 0;
    self.buyNowArray = [NSMutableArray array];
    self.buyNowIDs = [NSMutableArray array];
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.finishedListing = YES;
    self.tapNumber = 0;
    
    [self useCurrentLoc];
    
    self.profanityList = @[@"fucking",@"shitting", @"cunt", @"wanker", @"nigger", @"penis", @"cock", @"dick", @"bastard"];
    
    self.titleTextLabel.placeholder = @"What do you want to buy?";
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(toggleKeyboard)];
    tap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tap];
    
    self.catTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideCatTap)];
    self.catTap.numberOfTapsRequired = 1;
    
    //check if verified by facebook or email, if neither then show verify email flow
//    if ([[[PFUser currentUser] objectForKey:@"emailIsVerified"]boolValue] != YES && ![[PFUser currentUser]objectForKey:@"facebookId"] && self.introMode != YES) {
//        //user isn't verified
//        [self showVerifyAlert];
//    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController.navigationBar setHidden:YES];
    
    //sam and me only code for posting as someone else
    if ([[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"]|| [[PFUser currentUser].objectId isEqualToString:@"IIEf7cUvrO"] || [[PFUser currentUser].objectId isEqualToString:@"bXiWS96gp6"]) {
        
        if ([[NSUserDefaults standardUserDefaults]boolForKey:@"listMode"]==YES) {
            NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:@"listUser"];
            
            PFQuery *userQ = [PFUser query];
            [userQ whereKey:@"objectId" equalTo:userID];
            [userQ getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    [self.listingAsLabel setHidden:NO];
                    self.listingAsLabel.text = [NSString stringWithFormat:@"Listing as %@", [object objectForKey:@"username"]];
                    
                    self.listAsUser = (PFUser *)object;
                    self.listingAsMode = YES;
                }
                else{
                    NSLog(@"error getting user %@", error);
                }
            }];
        }
        else{
            self.listingAsMode = NO;
            [self.listingAsLabel setHidden:YES];
        }

    }
    
    if (self.introMode == YES) {
        [self.orImageView setHidden:YES];
        [self.sellButton setHidden:YES];
        [self.tutorialImageView setHidden:YES];
        
        self.skipButton.alpha = 0.0f;
        [self.skipButton setHidden:NO];
        
        //unhide after 10 seconds
        double delayInSeconds = 10.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:1.0
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.skipButton setAlpha:1.0];
                             }
                             completion:nil];
        });
    }
    else{
        [self.skipButton setHidden:YES];
    }
    
    self.imageSource = @"";
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Simple Create Wanted"
                                      }];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.introMode != YES && self.finishedListing == YES && self.savingListing != YES && self.completionShowing != YES) {
        [self.titleTextLabel becomeFirstResponder];
    }
    
    if (self.setupYes != YES) {
        [self setUpSuccess];
    }
    
    if (self.setupCategories != YES) {
        [self setupCatView];
    }
    
    if (self.introMode == YES && self.shownPushAlert != YES) {
        //show prompt for enabling push
        [self showPushAlert];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    if (self.hudShowing == YES) {
        [self hidHUD];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    NSString *stringCheck = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *wordsCheck = [stringCheck componentsSeparatedByString:@" "];

    if ([stringCheck isEqualToString:@""]) {
        [textField resignFirstResponder];
    }
    else if (([[textField.text lowercaseString] isEqualToString:@"supreme clothing"] || [[textField.text lowercaseString] isEqualToString:@"palace clothing"] || wordsCheck.count == 1) && self.alreadyPromptedSpecific == NO) {
        [self showSpecificPrompt];
    }
    else{
        [textField resignFirstResponder];
    }
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if(textField == self.titleTextLabel){
        if(range.length + range.location > textField.text.length)
        {
            return NO;
        }
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return newLength <= 50;
    }
    
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    NSArray *words = [textField.text componentsSeparatedByString:@" "];

    if (textField == self.titleTextLabel) {
        for (NSString *string in words) {
            if ([self.profanityList containsObject:string.lowercaseString]) {
                textField.text = @"";
                return;
            }
        }
    }
    
    NSString *stringCheck = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *wordsCheck = [stringCheck componentsSeparatedByString:@" "];

    if (self.toggleKeyboardHit == YES) {
        self.toggleKeyboardHit = NO;
    }
    else if ([stringCheck isEqualToString:@""]) {
        textField.text = @"";
    }
    else if ((wordsCheck.count == 1 || [[textField.text lowercaseString] isEqualToString:@"supreme clothing"] || [[textField.text lowercaseString] isEqualToString:@"palace clothing"]) && self.alreadyPromptedSpecific == YES) {
        self.finishedListing = NO;
        [self showCategories];
    }
    else if(![stringCheck isEqualToString:@""]){
        self.finishedListing = NO;
        [self showCategories];
    }
}

-(void)showSpecificPrompt{
    
    [Answers logCustomEventWithName:@"Showing 'Be Specific' Prompt in create"
                   customAttributes:@{}];
    
    //shake text view
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:0.06];
    [animation setRepeatCount:6];
    [animation setAutoreverses:YES];
    [animation setFromValue:[NSValue valueWithCGPoint:
                             CGPointMake([self.titleTextLabel center].x - 10.0f, [self.titleTextLabel center].y)]];
    [animation setToValue:[NSValue valueWithCGPoint:
                           CGPointMake([self.titleTextLabel center].x + 10.0f, [self.titleTextLabel center].y)]];
    [[self.titleTextLabel layer] addAnimation:animation forKey:@"position"];
    
    if (self.isSpecificViewShowing == YES) {
        return;
    }
    
    self.isSpecificViewShowing = YES;
    
    //setup drop down
    self.specificView = nil;
    self.specificView = [[UIView alloc]initWithFrame:CGRectMake(0, -70, [UIApplication sharedApplication].keyWindow.frame.size.width, 70)];
    [self.specificView setBackgroundColor:[UIColor colorWithRed:0.92 green:0.50 blue:1.00 alpha:1.0]];
    
    UILabel *specificLabel = [[UILabel alloc]initWithFrame:self.specificView.frame];
    [specificLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:15]];
    specificLabel.text = @"Pro tip: Be specific!";
    specificLabel.textColor = [UIColor whiteColor];
    specificLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.specificView addSubview:specificLabel];
    specificLabel.center = self.specificView.center;
    
    [self.view addSubview:self.specificView];
    
    //now animate down
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            [self.specificView setFrame:CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.frame.size.width, 70)];
                            specificLabel.center = self.specificView.center;
                        }
                     completion:^(BOOL finished) {
//                         self.alreadyPromptedSpecific = YES; //clamping down on shit WTBs
                         
                         //schedule auto dismiss
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                             [self dismissSpecificPrompt];
                         });
                     }];
    
}

-(void)dismissSpecificPrompt{
    //animate up
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            [self.specificView setFrame:CGRectMake(0, -500, [UIApplication sharedApplication].keyWindow.frame.size.width, 70)];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         self.isSpecificViewShowing = NO;

                         [self.specificView removeFromSuperview];
                         self.specificView = nil;
                     }];
}

-(void)showGoogle{
    NSString *searchString = [self.titleTextLabel.text stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSString *URLString = [NSString stringWithFormat:@"https://www.google.co.uk/search?tbm=isch&q=%@&tbs=iar:s#imgrc=_",searchString];
    
    self.JRWebView = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
    self.JRWebView.title = @"A D D  I M A G E";
    self.JRWebView.showUrlWhileLoading = NO;
    self.JRWebView.showPageTitles = NO;
    self.JRWebView.delegate = self;
    self.JRWebView.createMode = YES;
    
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.JRWebView];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)paidPressed{
    //do nothing
}

-(void)cameraPressed{
    //launch image picker
    [Answers logCustomEventWithName:@"camera tapped"
                   customAttributes:@{
                                      @"where":@"create"
                                      }];
    [self alertSheet];
}

-(void)cancelWebPressed{
    [Answers logCustomEventWithName:@"Aborted listing"
                   customAttributes:@{
                                      @"where":@"create"
                                      }];
    self.finishedListing = YES;
    self.titleTextLabel.text = @"";
    [self.JRWebView dismissViewControllerAnimated:YES completion:nil];
}

-(void)screeshotPressed:(UIImage *)screenshot withTaps:(int)taps{
    [Answers logCustomEventWithName:@"Add image from Google"
                   customAttributes:@{
                                      @"where":@"create"
                                      }];
    
    self.savingListing = YES;
    self.tapNumber = taps;
    
//    if (taps == 1 || taps == 2) {
//        //aleady been auto cropped
//        [self.JRWebView dismissViewControllerAnimated:YES completion:nil];
//        [self finalImage:screenshot];
//    }
//    else{
        [self displayCropperWithImage:screenshot];
//    }
}

-(void)alertSheet{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Take a picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Take a picture tapped"
                       customAttributes:@{
                                          @"where":@"create"
                                          }];
        [self dismissViewControllerAnimated:YES completion:^{
//            CameraController *vc = [[CameraController alloc]init];
//            vc.delegate = self;
//            vc.offerMode = NO;
//            self.shouldSave = YES;
//            self.savingListing = YES;
//            [self presentViewController:vc animated:YES completion:nil];
            
            CamVC *vc = [[CamVC alloc]init];
            vc.delegate = self;
            [self presentViewController:vc animated:YES completion:nil];
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Choose from library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Choose pictures tapped"
                       customAttributes:@{
                                          @"where":@"create"
                                          }];
//        [self dismissViewControllerAnimated:YES completion:^{
            if (!self.picker) {
                self.picker = [[UIImagePickerController alloc] init];
                self.picker.delegate = self;
                self.picker.allowsEditing = NO;
                self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            }
            [self.JRWebView presentViewController:self.picker animated:YES completion:nil];
//        }];
    }]];
    

    
    [self.JRWebView presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark - various image picker delegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(nonnull NSDictionary<NSString *,id> *)info{
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    //display crop picker
    self.savingListing = YES;
    [picker dismissViewControllerAnimated:YES completion:^{
        [self displayCropperWithImage:chosenImage];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    self.savingListing = NO;
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)displayCropperWithImage:(UIImage *)image{
    BASSquareCropperViewController *squareCropperViewController = [[BASSquareCropperViewController alloc] initWithImage:image minimumCroppedImageSideLength:375.0f];
    squareCropperViewController.squareCropperDelegate = self;
    squareCropperViewController.backgroundColor = [UIColor whiteColor];
    squareCropperViewController.borderColor = [UIColor whiteColor];
    squareCropperViewController.doneFont = [UIFont fontWithName:@"PingFangSC-Medium" size:15.0f];
    squareCropperViewController.cancelFont = [UIFont fontWithName:@"PingFangSC-Regular" size:15.0f];
    squareCropperViewController.excludedBackgroundColor = [UIColor blackColor];
//    squareCropperViewController.tapNumber = self.tapNumber;
//    NSLog(@"TAP NUMBER %d", self.tapNumber);
    squareCropperViewController.doneText = @"Confirm";
    
    [self.JRWebView presentViewController:squareCropperViewController animated:YES completion:nil];
}

- (void)squareCropperDidCropImage:(UIImage *)croppedImage inCropper:(BASSquareCropperViewController *)cropper{
    [self.JRWebView dismissViewControllerAnimated:NO completion:^{
        [self.JRWebView dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self finalImage:croppedImage];
}

- (void)squareCropperDidCancelCropInCropper:(BASSquareCropperViewController *)cropper{
    self.savingListing = NO;
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

-(void)dismissPressed:(BOOL)yesorno{
    //camera dismissed
    self.savingListing = NO;
    self.titleTextLabel.text = @"";
    [self.titleTextLabel becomeFirstResponder];
}

-(void)tagString:(NSString *)tag{
    //do nothing
}
-(void)finalImage:(UIImage *)image{
    //save image if just been taken
    
    UIImage *newImage = [image scaleImageToSize:CGSizeMake(750, 750)];

    if (self.shouldSave == YES) {
        UIImageWriteToSavedPhotosAlbum(newImage, nil, nil, nil);
        self.shouldSave = NO;
    }
    self.firstImage = newImage;
    self.photostotal ++;
    
    [self saveListing];
}

#pragma mark - success view methods

-(void)setUpSuccess{
    self.successView = nil;
    self.bgView = nil;
    
    self.completionShowing = YES;
    self.setupYes = YES;
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SuccessView" owner:self options:nil];
    self.successView = (CreateSuccessView *)[nib objectAtIndex:0];
    self.successView.delegate = self;
    self.successView.alpha = 0.0;
    [self.successView setCollectionViewDataSourceDelegate:self indexPath:nil];
    [self.navigationController.view addSubview:self.successView];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -480, 300, 480)];
    }
    else{
        [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-170, -480, 340, 480)]; //iPhone 6/7 specific
    }
    
    self.successView.layer.cornerRadius = 10;
    self.successView.layer.masksToBounds = YES;
    
    self.bgView = [[UIView alloc]initWithFrame:self.view.frame];
    self.bgView.backgroundColor = [UIColor blackColor];
    self.bgView.alpha = 0.0;
    [self.navigationController.view insertSubview:self.bgView belowSubview:self.successView];
    
    //show NEW label
//    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"newBoostCount"]){
//        NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:@"newBoostCount"];
//        if (count >= 5) {
//            [self.successView.unseendNewLabel setHidden:YES];
//        }
//        else{
//            [self.successView.unseendNewLabel setHidden:NO];
//            count++;
//            [[NSUserDefaults standardUserDefaults] setInteger:count forKey:@"newBoostCount"];
//        }
//    }
//    else{
//        //first time with new boost button
//        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"newBoostCount"];
//    }
}

-(void)showSuccess{
    self.completionShowing = YES;
    self.bgView.alpha = 0.8;
    [self.successView setAlpha:1.0];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.successView setFrame:CGRectMake(0, 0, 300, 480)];
                            }
                            else{
                                [self.successView setFrame:CGRectMake(0, 0, 340, 480)];
                            }
                            self.successView.center = self.view.center;
                        }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)hideSuccess{
    self.createdListing = NO;
    self.finishedListing = YES;
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-150,1000, 300, 480)];
                            }
                            else{
                                [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-170,1000, 340, 480)]; //iPhone 6/7 specific
                            }
                            [self.bgView setAlpha:0.0];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         self.completionShowing = NO;
                         [self.successView setAlpha:0.0];
                         
                         if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                             //iphone5
                             [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -480, 300, 480)];
                         }
                         else{
                             [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-170, -480, 340, 480)]; //iPhone 6/7 specific
                         }
                     }];
}

-(void)sharePressed{
    [Answers logCustomEventWithName:@"Success Share pressed"
                   customAttributes:@{
                                      @"pageName":@"create"
                                      }];
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share to Facebook Group" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        FBGroupShareViewController *vc = [[FBGroupShareViewController alloc]init];
        vc.objectId = self.listing.objectId;
        NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navigationController animated:YES completion:nil];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSMutableArray *items = [NSMutableArray new];
        [items addObject:[NSString stringWithFormat:@"Check out my wanted listing: %@\nPosted on Bump http://apple.co/2aY3rBk", [self.listing objectForKey:@"title"]]];
        UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
        [self presentViewController:activityController animated:YES completion:nil];
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)boostPressed{
    [Answers logCustomEventWithName:@"Boost pressed"
                   customAttributes:@{
                                      @"pageName":@"Success"
                                      }];
    
    boostController *vc = [[boostController alloc]init];
    vc.listing = self.listing;
    vc.delegate = self;
    if (self.introMode == YES) {
        vc.introMode = YES;
    }
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)successDonePressed{
    [Answers logCustomEventWithName:@"Success Done pressed"
                   customAttributes:@{
                                      @"pageName":@"create"
                                      }];
    [self hideSuccess];
    
    if (self.introMode == YES) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
    else{
        [self resetAll];
        [self cancelCrossPresse:self];
    }
}

-(void)createPressed{
    [Answers logCustomEventWithName:@"Success Create pressed"
                   customAttributes:@{
                                      @"pageName":@"create"
                                      }];
    [self resetAll];
    [self.titleTextLabel becomeFirstResponder];
    [self hideSuccess];
}

-(void)editPressed{
    [Answers logCustomEventWithName:@"Success Edit pressed"
                   customAttributes:@{
                                      @"pageName":@"create"
                                      }];
    //show edit VC
    CreateViewController *vc = [[CreateViewController alloc]init];
    vc.status = @"edit";
    vc.listing = self.listing;
    vc.addDetails = YES;
    if (self.introMode == YES) {
        vc.introMode = YES;
    }
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)addMorePressed{
    [Answers logCustomEventWithName:@"Success Add more pressed"
                   customAttributes:@{
                                      @"pageName":@"create"
                                      }];
    //show edit VC
    CreateViewController *vc = [[CreateViewController alloc]init];
    vc.status = @"edit";
    vc.listing = self.listing;
    vc.addDetails = YES;
    if (self.introMode == YES) {
        vc.introMode = YES;
    }
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    return self.buyNowArray.count;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == self.buyNowArray.count-1 && self.buyNowArray.count > 1) {
        
        [Answers logCustomEventWithName:@"Tapped 'view more' after creating listing"
                       customAttributes:@{}];
        
        if (self.introMode == YES) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"viewMorePressed"];
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                appDelegate.tabBarController.selectedIndex = 1;
            }];
        }
        else{
            self.tabBarController.selectedIndex = 1;
            [self successDonePressed];
        }
    }
    else{
        [Answers logCustomEventWithName:@"Tapped for sale listing after creating listing"
                       customAttributes:@{}];
        
        PFObject *WTS = [self.buyNowArray objectAtIndex:indexPath.item];
        ForSaleListing *vc = [[ForSaleListing alloc]init];
        vc.listingObject = WTS;
        vc.source = @"create";
        vc.pureWTS = NO;
        vc.fromCreate = YES;

        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ForSaleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.itemView.image = nil;
    
    if (indexPath.row == self.buyNowArray.count-1 && self.buyNowArray.count > 1) {
        [cell.itemView setImage:[UIImage imageNamed:@"viewMore"]];
    }
    else{
        PFObject *WTS = [self.buyNowArray objectAtIndex:indexPath.item];
        //        NSLog(@"WTS: %@ at index: %ld", WTS, (long)indexPath.row);
        //setup cell
        [cell.itemView setFile:[WTS objectForKey:@"thumbnail"]];
        [cell.itemView loadInBackground];
    }
    
    cell.itemView.layer.cornerRadius = 35;
    cell.itemView.layer.masksToBounds = YES;
    cell.itemView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    cell.itemView.contentMode = UIViewContentModeScaleAspectFill;
    
    return cell;
}

-(void)resetAll{
    self.somethingChanged = NO;
    self.titleTextLabel.text = @"";
    self.photostotal = 0;
    self.geopoint = nil;
    self.listing = nil;
    self.alreadyPromptedSpecific = NO;
}

-(void)useCurrentLoc{
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint * _Nullable geoPoint, NSError * _Nullable error) {
        if (!error) {
            double latitude = geoPoint.latitude;
            double longitude = geoPoint.longitude;
            
            CLLocation *loc = [[CLLocation alloc]initWithLatitude:latitude longitude:longitude];
            CLGeocoder *geocoder = [[CLGeocoder alloc]init];
            [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                if (placemarks) {
                    CLPlacemark *placemark = [placemarks lastObject];
                    self.locationString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.administrativeArea];
                    
                    if (geoPoint) {
                        self.geopoint = geoPoint;
                    }
                    else{
                        NSLog(@"error with location");
                    }
                }
                else{
                    NSLog(@"error %@", error);
                }
            }];
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
    self.hudShowing = YES;
    self.shouldShowHUD = YES;
}

-(void)hidHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
        self.hudShowing = NO;
        self.shouldShowHUD = NO;
    });
}

-(void)saveListing{
    [self showHUD];
    
    NSString *itemTitle = [self.titleTextLabel.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    self.listing =[PFObject objectWithClassName:@"wantobuys"];
    
    [self.listing setObject:itemTitle forKey:@"title"];
    [self.listing setObject:[itemTitle lowercaseString]forKey:@"titleLower"];
    [self.listing setObject:self.categorySelected forKey:@"category"];
    
    //set default size on listing
    
    PFUser *current = [PFUser currentUser];
    
    //check if have default size info
    if ([current objectForKey:@"sizeCountry"]) {
        
        if ([self.categorySelected isEqualToString:@"Clothing"] && [current objectForKey:@"clothingSizeArray"]) {
            NSArray *clothingSizeArray = [current objectForKey:@"clothingSizeArray"];
            
            NSString *sizeLabel = [NSString stringWithFormat:@"%@/%@",clothingSizeArray[0],clothingSizeArray[1]];
            [self.listing setObject:sizeLabel forKey:@"sizeLabel"];
            
            [self.listing setObject:clothingSizeArray[0] forKey:@"firstSize"];
            [self.listing setObject:@"YES"forKey:[NSString stringWithFormat:@"size%@", clothingSizeArray[0]]];
            
            [self.listing setObject:clothingSizeArray[1] forKey:@"secondSize"];
            [self.listing setObject:@"YES"forKey:[NSString stringWithFormat:@"size%@", clothingSizeArray[1]]];
            
            [self.listing setObject:clothingSizeArray forKey:@"sizeArray"];
            
        }
        else if ([self.categorySelected isEqualToString:@"Footwear"] && [current objectForKey:@"UKShoeSizeArray"]){
            
            NSArray *ukSizeArray = [current objectForKey:@"USShoeSizeArray"];
            [self.listing setObject:ukSizeArray forKey:@"sizeArray"];

            
            //set size label
            NSString *sizeLabel = [NSString stringWithFormat:@"US %@/%@/%@",ukSizeArray[0],ukSizeArray[1],ukSizeArray[2]];
            [self.listing setObject:sizeLabel forKey:@"sizeLabel"];
            
            if ([[[PFUser currentUser]objectForKey:@"gender"]isEqualToString:@"male"]) {
                [self.listing setObject:@"Mens" forKey:@"sizeGender"];
            }
            else if ([[[PFUser currentUser]objectForKey:@"gender"]isEqualToString:@"female"]){
                [self.listing setObject:@"Womens" forKey:@"sizeGender"];
            }
            else{
                [self.listing setObject:@"Mens" forKey:@"sizeGender"];
            }

            //set YES to different sizes
            [self.listing setObject:ukSizeArray[0] forKey:@"firstSize"];
            NSString *newKey = [ukSizeArray[0] stringByReplacingOccurrencesOfString:@"." withString:@"dot"];
            [self.listing setObject:@"YES"forKey:[NSString stringWithFormat:@"size%@", newKey]];
            
            [self.listing setObject:ukSizeArray[1] forKey:@"secondSize"];
            NSString *new1Key = [ukSizeArray[1] stringByReplacingOccurrencesOfString:@"." withString:@"dot"];
            [self.listing setObject:@"YES"forKey:[NSString stringWithFormat:@"size%@", new1Key]];
        
            [self.listing setObject:ukSizeArray[2] forKey:@"thirdSize"];
            NSString *new2Key = [ukSizeArray[2] stringByReplacingOccurrencesOfString:@"." withString:@"dot"];
            [self.listing setObject:@"YES"forKey:[NSString stringWithFormat:@"size%@", new2Key]];
        
        }
    }
    //save each country sizes onto listing (only using UK for search atm)

    //save keywords (minus useless words)
    NSArray *wasteWords = [NSArray arrayWithObjects:@"x",@"to",@"with",@"and",@"the",@"wtb",@"or",@" ",@".",@"very",@"interested", @"in",@"wanted", @"", @"all",@"any", @"&",@"looking",@"size", @"buy", @"these", @"this", @"that", @"-",@"(", @")",@"/", nil];
    NSString *title = [itemTitle lowercaseString];
    NSArray *strings = [title componentsSeparatedByString:@" "];
    NSMutableArray *mutableStrings = [NSMutableArray arrayWithArray:strings];
    [mutableStrings removeObjectsInArray:wasteWords];
    
    NSMutableArray *finalKeywordArray = [NSMutableArray array];
    
    for (NSString *string in mutableStrings) {
        if (![string canBeConvertedToEncoding:NSASCIIStringEncoding]) {
//            NSLog(@"can't be converted %@", string);
        }
        else{
            //trim . or , etc. from string if not got a space inbetween
            NSString* cleanedString = [string stringByTrimmingCharactersInSet: [NSCharacterSet punctuationCharacterSet]];
            [finalKeywordArray addObject:cleanedString];
        }
    }
    [self.listing setObject:finalKeywordArray forKey:@"keywords"];
    
    finalKeywordArray = [self addAlternativeKeywordsFromArray:finalKeywordArray];
    [self.listing setObject:finalKeywordArray forKey:@"searchKeywords"];
    [self.listing setObject:@"live" forKey:@"status"];
    
    //set default condition wanted to any
    [self.listing setObject:@"Any" forKey:@"condition"];

    if (self.geopoint != nil) {
        [self.listing setObject:self.locationString forKey:@"location"];
        [self.listing setObject:self.geopoint forKey:@"geopoint"];
    }

    [self.listing setObject:[NSDate date] forKey:@"lastUpdated"];
    [self.listing setObject:@0 forKey:@"views"];
    [self.listing setObject:@0 forKey:@"bumpCount"];
    
    if (!self.currency) {
        self.currency = @"USD";
    }
    
    [self.listing setObject:self.currency forKey:@"currency"];
    
    if (self.listingAsMode != YES) {
        [self.listing setObject:[PFUser currentUser] forKey:@"postUser"];
    }
    else{
        [self.listing setObject:self.listAsUser forKey:@"postUser"];
    }
    
    NSData* data = UIImageJPEGRepresentation(self.firstImage, 0.7f);
    
    if (data == nil) {
        [Answers logCustomEventWithName:@"PFFile Nil Data"
                       customAttributes:@{
                                          @"pageName":@"simpleCreateVC"
                                          }];
        
        //prevent crash when creating a PFFile with nil data
        [self hidHUD];
        [self showAlertWithTitle:@"Image Error" andMsg:@"Woops, something went wrong! Please try again"];
        return;
    }
    
    PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data];
    [self.listing setObject:imageFile1 forKey:@"image1"];
    
    //save a smaller thumbnail image from first cell's image    
    UIImage *imageOne = [self.firstImage scaleImageToSize:CGSizeMake(200, 200)];
    NSData* dataOne = UIImageJPEGRepresentation(imageOne, 0.8f);
    PFFile *thumbFile = [PFFile fileWithName:@"thumb1.jpg" data:dataOne];
    [self.listing setObject:thumbFile forKey:@"thumbnail"];
    
    //set index on WTB
    if (self.listingAsMode != YES) {
        if ([[PFUser currentUser]objectForKey:@"postNumber"]) {
            int index = [[[PFUser currentUser]objectForKey:@"postNumber"]intValue]+1;
            [self.listing setObject:[NSNumber numberWithInt:index] forKey:@"index"];
        }
        else{
            [self.listing setObject:@0 forKey:@"index"];
        }
    }
    else{
        if ([self.listAsUser objectForKey:@"postNumber"]) {
            int index = [[self.listAsUser objectForKey:@"postNumber"]intValue]+1;
            [self.listing setObject:[NSNumber numberWithInt:index] forKey:@"index"];
        }
        else{
            [self.listing setObject:@0 forKey:@"index"];
        }
    }
    
    [self.listing saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            
            NSLog(@"listing saved! %@", self.listing.objectId);
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"WTB Created" properties:@{}];
            
            self.createdListing = YES;
            self.savingListing = NO;
            
            [self findRelevantItems];
            
            if (self.listingAsMode == YES) {
                [self hidHUD];
                [self showSuccess];
                return;
            }
            
            //analytics
            if (self.introMode == YES) {
                [Answers logCustomEventWithName:@"Listing Complete"
                               customAttributes:@{
                                                  @"mode":@"Intro",
                                                  @"imageSource":self.imageSource
                                                  }];
            }
            else{
                [Answers logCustomEventWithName:@"Listing Complete"
                               customAttributes:@{
                                                  @"mode":@"Normal",
                                                  @"imageSource":self.imageSource
                                                  }];
            }

            //add listing to home page via notif.
            [[NSNotificationCenter defaultCenter] postNotificationName:@"justPostedListing" object:self.listing];
            
            [[PFUser currentUser]incrementKey:@"postNumber"];
            [[PFUser currentUser] saveInBackground];
            
            //send FB friends a push asking them to Bump listing! just for WTS atm
//            NSString *pushText = [NSString stringWithFormat:@"Your Facebook friend %@ just posted a listing - Tap to Bump it 👊", [[PFUser currentUser] objectForKey:@"fullname"]];
//            
//            PFQuery *bumpedQuery = [PFQuery queryWithClassName:@"Bumped"];
//            [bumpedQuery whereKey:@"facebookId" containedIn:[[PFUser currentUser]objectForKey:@"friends"]];
//            [bumpedQuery whereKey:@"safeDate" lessThanOrEqualTo:[NSDate date]];
//            [bumpedQuery whereKeyExists:@"user"];
//            [bumpedQuery includeKey:@"user"];
//            bumpedQuery.limit = 10;
//            [bumpedQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//                if (objects) {
//                    NSLog(@"these objects can be pushed to %@", objects);
//                    if (objects.count > 0) {
//                        //create safe date which is 3 days from now
//                        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
//                        dayComponent.day = 3;
//                        NSCalendar *theCalendar = [NSCalendar currentCalendar];
//                        NSDate *safeDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
//                        
//                        for (PFObject *bumpObj in objects) {
//                            [bumpObj setObject:safeDate forKey:@"safeDate"];
//                            [bumpObj incrementKey:@"timesBumped"];
//                            [bumpObj saveInBackground];
//                            PFUser *friendUser = [bumpObj objectForKey:@"user"];
//                            
//                            NSDictionary *params = @{@"userId": friendUser.objectId, @"message": pushText, @"sender": [PFUser currentUser].username, @"bumpValue": @"YES", @"listingID": self.listing.objectId};
//                            
////                            [PFCloud callFunctionInBackground:@"sendNewPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
////                                if (!error) {
////                                    NSLog(@"push response %@", response);
////                                    [Answers logCustomEventWithName:@"Sent FB Friend a Bump Push"
////                                                   customAttributes:@{}];
////                                    [Answers logCustomEventWithName:@"Push Sent"
////                                                   customAttributes:@{
////                                                                      @"Type":@"FB Friend"
////                                                                      }];
////                                }
////                                else{
////                                    NSLog(@"push error %@", error);
////                                }
////                            }];
//                        }
//                    }
//                }
//                else{
//                    NSLog(@"error finding relevant bumped obj's %@", error);
//                }
//            }];
            
            //update wanted words from previous 10 listings
            PFQuery *myPosts = [PFQuery queryWithClassName:@"wantobuys"];
            [myPosts whereKey:@"postUser" equalTo:[PFUser currentUser]];
            [myPosts orderByDescending:@"lastUpdated"];
            myPosts.limit = 10;
            [myPosts findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (objects) {
                    NSMutableArray *wantedWords = [NSMutableArray array];
                    
                    for (PFObject *listing in objects) {
                        NSArray *keywords = [listing objectForKey:@"keywords"];
                        
                        for (NSString *word in keywords) {
                            if (![wantedWords containsObject:word]) {
                                [wantedWords addObject:word];
                            }
                        }
                    }
                    [[PFUser currentUser] setObject:wantedWords forKey:@"wantedWords"];
                    [[PFUser currentUser] saveInBackground];
                }
                else{
                    NSLog(@"nee posts pet");
                }
            }];
            
            [self hidHUD];
            [self dismissViewControllerAnimated:YES completion:^{
                [self.delegate showWantedSuccessForListing:self.listing];
            }];
            
//            [self showSuccess];
            
            //show boost VC automatically just once
//            if (![[NSUserDefaults standardUserDefaults] valueForKey:@"autoShowBoost"]){
//                [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"autoShowBoost"];
//                
//                //first time so auto show boost VC
//                boostController *vc = [[boostController alloc]init];
//                vc.listing = self.listing;
//                vc.delegate = self;
//                if (self.introMode == YES) {
//                    vc.introMode = YES;
//                }
//                [self presentViewController:vc animated:YES completion:nil];
//            }
        }
        else{
            //error saving listing
            NSLog(@"error saving listing so hiding");
            [self hidHUD];
            NSLog(@"error saving %@", error);
            
            if (self.introMode == YES) {
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                [self.delegate dismissSimpleCreateVC:self];
            }
        }
    }];
}

-(void)findRelevantItems{
    [self.buyNowArray removeAllObjects];
    [self.buyNowIDs removeAllObjects];
    
    NSArray *WTBKeywords = [self.listing objectForKey:@"keywords"];
    
    PFQuery *salesQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [salesQuery whereKey:@"status" equalTo:@"live"];
    [salesQuery whereKey:@"keywords" containedIn:WTBKeywords];
    //    [salesQuery orderByDescending:@"createdAt"];
    salesQuery.limit = 10;
    [salesQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            [self.buyNowArray addObjectsFromArray:objects];
            
            for (PFObject *forSale in objects) {
                [self.buyNowIDs addObject:forSale.objectId];
            }
            
//            NSLog(@"count first time %lu", objects.count);
            
            if (objects.count < 10) {
                PFQuery *salesQuery2 = [PFQuery queryWithClassName:@"forSaleItems"];
                [salesQuery2 whereKey:@"status" equalTo:@"live"];
                [salesQuery2 orderByDescending:@"lastUpdated"];
                [salesQuery whereKey:@"objectId" notContainedIn:self.buyNowIDs];
                salesQuery2.limit = 10-self.buyNowArray.count;
                [salesQuery2 findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (objects) {
//                        NSLog(@"objects second time %lu", objects.count);
                        for (PFObject *forSale in objects) {
                            if (![self.buyNowIDs containsObject:forSale.objectId]) {
                                [self.buyNowArray addObject:forSale];
                                [self.buyNowIDs addObject:forSale.objectId];
                            }
                        }
//                        NSLog(@"count second time %lu", self.buyNowArray.count);
                        [self.successView.collectionView reloadData];
                    }
                    else{
                        NSLog(@"error in second query %@", error);
                    }
                }];
            }
            else{
                [self.successView.collectionView reloadData];
            }
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

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
    self.customAlert.messageLabel.text = @"Tap to be notified when sellers & potential buyers send you a message on BUMP";
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
    
    [UIView animateWithDuration:1.5
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
    [self.titleTextLabel becomeFirstResponder];
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

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)toggleKeyboard{
    if (self.finishedListing == YES) {
        if ([self.titleTextLabel isFirstResponder]) {
            self.toggleKeyboardHit = YES;
            [self.titleTextLabel resignFirstResponder];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else{
            [self.titleTextLabel becomeFirstResponder];
        }
    }
}
- (IBAction)skipButtonPressed:(id)sender {
    [Answers logCustomEventWithName:@"Skipped intro create"
                   customAttributes:@{}];
    
    //schedule local push reminder
    //local notifications set up
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
    
    //setup so user is taken to Buy Now
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"viewMorePressed"];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.tabBarController.selectedIndex = 1;
    }];
    
//    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sellPressed:(id)sender {
    
    if (self.isSeller != YES) {
        [Answers logCustomEventWithName:@"Apply to sell pressed"
                       customAttributes:@{
                                          @"where": @"create"
                                          }];
        
        //take to seller application
        mainApprovedSellerController *vc = [[mainApprovedSellerController alloc]init];
        [self presentViewController:vc animated:YES completion:nil];
    }
    else{
        [Answers logCustomEventWithName:@"Sell Pressed in Create"
                       customAttributes:@{}];
        
        self.titleTextLabel.text = @"";
        CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

#pragma mark - categories drop down

-(void)setupCatView{
    self.catView = nil;
    self.setupCategories = YES;
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CategoryView" owner:self options:nil];
    self.catView = (CategoryDropDown *)[nib objectAtIndex:0];
    self.catView.delegate = self;
    self.catView.alpha = 0.0;
    [self.navigationController.view addSubview:self.catView];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.catView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -192, 300, 174)];
    }
    else{
        [self.catView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -192, 300, 174)]; //iPhone 6/7 specific
    }
    
    self.catView.layer.cornerRadius = 10;
    self.catView.layer.masksToBounds = YES;
}
-(void)showCategories{
    self.bgView.alpha = 0.8;
    [self.catView setAlpha:1.0];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.catView setFrame:CGRectMake(0, 0, 300, 174)];
                            }
                            else{
                                [self.catView setFrame:CGRectMake(0, 0, 300, 174)];
                            }
                            self.catView.center = self.view.center;
                        }
                     completion:^(BOOL finished) {
                         [self.bgView addGestureRecognizer:self.catTap];
                     }];
}

-(void)hideCatTap{
    [self hideCategories];
    [self.titleTextLabel becomeFirstResponder];
}

-(void)hideCategories{

    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.catView setFrame:CGRectMake((self.view.frame.size.width/2)-150,1000, 300, 174)];
                            }
                            else{
                                [self.catView setFrame:CGRectMake((self.view.frame.size.width/2)-150,1000, 300, 174)]; //iPhone 6/7 specific
                            }
                            [self.bgView setAlpha:0.0];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         self.finishedListing = YES;
                         [self.catView setAlpha:0.0];
                         [self.bgView removeGestureRecognizer:self.catTap];
                         
                         if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                             //iphone5
                             [self.catView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -174, 300, 174)];
                         }
                         else{
                             [self.catView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -174, 300, 174)]; //iPhone 6/7 specific
                         }
                     }];
}

-(void)clothingPressed{
    self.categorySelected = @"Clothing";
    [self hideCategories];
    [self showGoogle];
}

-(void)footPressed{
    self.categorySelected = @"Footwear";
    [self hideCategories];
    [self showGoogle];
}

-(void)otherPressed{
    self.categorySelected = @"Accessories";
    [self hideCategories];
    [self showGoogle];
}

#pragma mark - boost controller delegate
-(void)dismissedWithPurchase:(NSString *)purchase{
    
    //fetchupdated listing so it has correct boost info
    //then pass to explore
    
    [self.listing fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"latestListingBoosted" object:object];
        }
    }];
}
- (IBAction)cancelCrossPresse:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(NSMutableArray *)addAlternativeKeywordsFromArray:(NSMutableArray *)finalKeywordArray{
    //t shirt variations
    if ([finalKeywordArray containsObject:@"tee"]) {
        [finalKeywordArray addObject:@"shirt"];
        [finalKeywordArray addObject:@"t"];
        [finalKeywordArray addObject:@"t-shirt"];
        [finalKeywordArray addObject:@"tshirt"];
        [finalKeywordArray addObject:@"top"];
        [finalKeywordArray addObject:@"tees"];
    }
    else if ([finalKeywordArray containsObject:@"tshirt"]) {
        [finalKeywordArray addObject:@"shirt"];
        [finalKeywordArray addObject:@"t"];
        [finalKeywordArray addObject:@"t-shirt"];
        [finalKeywordArray addObject:@"tee"];
        [finalKeywordArray addObject:@"top"];
        [finalKeywordArray addObject:@"tees"];
    }
    else if ([finalKeywordArray containsObject:@"t-shirt"]) {
        [finalKeywordArray addObject:@"shirt"];
        [finalKeywordArray addObject:@"t"];
        [finalKeywordArray addObject:@"tshirt"];
        [finalKeywordArray addObject:@"tee"];
        [finalKeywordArray addObject:@"top"];
        [finalKeywordArray addObject:@"tees"];
    }
    else if ([finalKeywordArray containsObject:@"t"] && [finalKeywordArray containsObject:@"shirt"]) {
        [finalKeywordArray addObject:@"t-shirt"];
        [finalKeywordArray addObject:@"tshirt"];
        [finalKeywordArray addObject:@"tee"];
        [finalKeywordArray addObject:@"top"];
        [finalKeywordArray addObject:@"tees"];
    }
    
    //bogo variations
    if ([finalKeywordArray containsObject:@"bogo"]) {
        [finalKeywordArray addObject:@"box"];
        [finalKeywordArray addObject:@"logo"];
        [finalKeywordArray addObject:@"boxlogo"];
        [finalKeywordArray addObject:@"bogos"];
    }
    else if ([finalKeywordArray containsObject:@"box logo"]) {
        [finalKeywordArray addObject:@"bogo"];
        [finalKeywordArray addObject:@"boxlogo"];
        [finalKeywordArray addObject:@"bogos"];
    }
    
    //triferg variations
    if ([finalKeywordArray containsObject:@"triferg"]) {
        [finalKeywordArray addObject:@"tri-ferg"];
        [finalKeywordArray addObject:@"tri"];
        [finalKeywordArray addObject:@"ferg"];
    }
    else if ([finalKeywordArray containsObject:@"tri-ferg"]) {
        [finalKeywordArray addObject:@"triferg"];
        [finalKeywordArray addObject:@"tri"];
        [finalKeywordArray addObject:@"ferg"];
    }
    else if ([finalKeywordArray containsObject:@"tri"] && [finalKeywordArray containsObject:@"ferg"]) {
        [finalKeywordArray addObject:@"triferg"];
        [finalKeywordArray addObject:@"tri-ferg"];
    }
    
    //numbers
    if ([finalKeywordArray containsObject:@"1"] || [finalKeywordArray containsObject:@"one"]) {
        [finalKeywordArray addObject:@"1"];
        [finalKeywordArray addObject:@"one"];
    }
    if ([finalKeywordArray containsObject:@"2"] || [finalKeywordArray containsObject:@"two"]) {
        [finalKeywordArray addObject:@"2"];
        [finalKeywordArray addObject:@"two"];
    }
    if ([finalKeywordArray containsObject:@"3"] || [finalKeywordArray containsObject:@"three"]) {
        [finalKeywordArray addObject:@"3"];
        [finalKeywordArray addObject:@"three"];
    }
    if ([finalKeywordArray containsObject:@"4"] || [finalKeywordArray containsObject:@"four"]) {
        [finalKeywordArray addObject:@"4"];
        [finalKeywordArray addObject:@"four"];
    }
    if ([finalKeywordArray containsObject:@"5"] || [finalKeywordArray containsObject:@"five"]) {
        [finalKeywordArray addObject:@"five"];
        [finalKeywordArray addObject:@"5"];
    }
    if ([finalKeywordArray containsObject:@"6"] || [finalKeywordArray containsObject:@"six"]) {
        [finalKeywordArray addObject:@"6"];
        [finalKeywordArray addObject:@"six"];
    }
    if ([finalKeywordArray containsObject:@"7"] || [finalKeywordArray containsObject:@"seven"]) {
        [finalKeywordArray addObject:@"seven"];
        [finalKeywordArray addObject:@"7"];
    }
    if ([finalKeywordArray containsObject:@"8"] || [finalKeywordArray containsObject:@"eight"]) {
        [finalKeywordArray addObject:@"8"];
        [finalKeywordArray addObject:@"eight"];
    }
    if ([finalKeywordArray containsObject:@"9"] || [finalKeywordArray containsObject:@"nine"]) {
        [finalKeywordArray addObject:@"9"];
        [finalKeywordArray addObject:@"nine"];
    }
    if ([finalKeywordArray containsObject:@"10"] || [finalKeywordArray containsObject:@"ten"]) {
        [finalKeywordArray addObject:@"10"];
        [finalKeywordArray addObject:@"ten"];
    }
    
    //pullover/anorak
    if ([finalKeywordArray containsObject:@"pullover"]) {
        [finalKeywordArray addObject:@"anorak"];
        [finalKeywordArray addObject:@"pull"];
        [finalKeywordArray addObject:@"over"];
        [finalKeywordArray addObject:@"anarak"];
    }
    else if ([finalKeywordArray containsObject:@"anorak"]) {
        [finalKeywordArray addObject:@"pullover"];
        [finalKeywordArray addObject:@"pull"];
        [finalKeywordArray addObject:@"over"];
        [finalKeywordArray addObject:@"anarak"];
    }
    else if ([finalKeywordArray containsObject:@"anarak"]) {
        [finalKeywordArray addObject:@"pullover"];
        [finalKeywordArray addObject:@"pull"];
        [finalKeywordArray addObject:@"over"];
        [finalKeywordArray addObject:@"anorak"];
    }
    //quarter zip
    if ([finalKeywordArray containsObject:@"quarter"] && [finalKeywordArray containsObject:@"zip"] ) {
        [finalKeywordArray addObject:@"1/4"];
        [finalKeywordArray addObject:@"zip"];
        [finalKeywordArray addObject:@"quarterzip"];
    }
    else if ([finalKeywordArray containsObject:@"1/4"] && [finalKeywordArray containsObject:@"zip"] ) {
        [finalKeywordArray addObject:@"1/4"];
        [finalKeywordArray addObject:@"zip"];
        [finalKeywordArray addObject:@"quarterzip"];
    }
    else if ([finalKeywordArray containsObject:@"quarterzip"]) {
        [finalKeywordArray addObject:@"1/4"];
        [finalKeywordArray addObject:@"zip"];
        [finalKeywordArray addObject:@"quarter"];
    }
    
    //half zip
    if ([finalKeywordArray containsObject:@"half"] && [finalKeywordArray containsObject:@"zip"] ) {
        [finalKeywordArray addObject:@"1/2"];
        [finalKeywordArray addObject:@"quarterzip"];
        [finalKeywordArray addObject:@"quarter"];
    }
    else if ([finalKeywordArray containsObject:@"1/2"] && [finalKeywordArray containsObject:@"zip"] ) {
        [finalKeywordArray addObject:@"halfzip"];
        [finalKeywordArray addObject:@"half"];
    }
    else if ([finalKeywordArray containsObject:@"halfzip"]) {
        [finalKeywordArray addObject:@"1/2"];
        [finalKeywordArray addObject:@"zip"];
        [finalKeywordArray addObject:@"half"];
    }
    
    //overshirt
    if ([finalKeywordArray containsObject:@"over"] && [finalKeywordArray containsObject:@"shirt"] ) {
        [finalKeywordArray addObject:@"overshirt"];
    }
    else if ([finalKeywordArray containsObject:@"overshirt"]) {
        [finalKeywordArray addObject:@"over"];
        [finalKeywordArray addObject:@"shirt"];
    }
    
    //hoodie/jumper/hood jumper
    if ([finalKeywordArray containsObject:@"hooded"] && [finalKeywordArray containsObject:@"jumper"] ) {
        [finalKeywordArray addObject:@"hoodie"];
        [finalKeywordArray addObject:@"hoody"];
    }
    else if ([finalKeywordArray containsObject:@"hoodie"]) {
        [finalKeywordArray addObject:@"hooded"];
        [finalKeywordArray addObject:@"hoody"];
        [finalKeywordArray addObject:@"jumper"];
    }
    else if ([finalKeywordArray containsObject:@"hoody"]) {
        [finalKeywordArray addObject:@"hoodie"];
        [finalKeywordArray addObject:@"hoody"];
        [finalKeywordArray addObject:@"jumper"];
        [finalKeywordArray addObject:@"hooded"];
    }
    
    //ultraboost
    if ([finalKeywordArray containsObject:@"ultra"] && [finalKeywordArray containsObject:@"boost"] ) {
        [finalKeywordArray addObject:@"ultraboost"];
        [finalKeywordArray addObject:@"UB"];
    }
    else if ([finalKeywordArray containsObject:@"ultraboost"]) {
        [finalKeywordArray addObject:@"ultra"];
        [finalKeywordArray addObject:@"boost"];
        [finalKeywordArray addObject:@"UB"];
    }
    //primeknit
    if ([finalKeywordArray containsObject:@"prime"] && [finalKeywordArray containsObject:@"knit"] ) {
        [finalKeywordArray addObject:@"primeknit"];
        [finalKeywordArray addObject:@"pk"];
    }
    else if ([finalKeywordArray containsObject:@"primeknit"]) {
        [finalKeywordArray addObject:@"prime"];
        [finalKeywordArray addObject:@"knit"];
        [finalKeywordArray addObject:@"pk"];
    }
    
    //parker
    if ([finalKeywordArray containsObject:@"parker"]) {
        [finalKeywordArray addObject:@"parka"];
    }
    else if ([finalKeywordArray containsObject:@"parka"]) {
        [finalKeywordArray addObject:@"parker"];
    }
    
    //cap/hat
    if ([finalKeywordArray containsObject:@"cap"]) {
        [finalKeywordArray addObject:@"hat"];
    }
    else if ([finalKeywordArray containsObject:@"hat"]) {
        [finalKeywordArray addObject:@"cap"];
    }
    
    //assc
    if ([finalKeywordArray containsObject:@"assc"]) {
        [finalKeywordArray addObject:@"antisocialsocialclub"];
        [finalKeywordArray addObject:@"anti"];
        [finalKeywordArray addObject:@"social"];
        [finalKeywordArray addObject:@"club"];
    }
    else if ([finalKeywordArray containsObject:@"anti"] && [finalKeywordArray containsObject:@"social"] && [finalKeywordArray containsObject:@"club"]) {
        [finalKeywordArray addObject:@"assc"];
        [finalKeywordArray addObject:@"antisocialsocialclub"];
    }
    
    //gosha
    if ([finalKeywordArray containsObject:@"gosha"]) {
        [finalKeywordArray addObject:@"rubchinskiy"];
        [finalKeywordArray addObject:@"gosharubchinskiy"];
        [finalKeywordArray addObject:@"rubchinsky"];
        [finalKeywordArray addObject:@"ruchinskiy"];
    }
    else if ([finalKeywordArray containsObject:@"rubchinskiy"]) {
        [finalKeywordArray addObject:@"gosha"];
        [finalKeywordArray addObject:@"gosharubchinskiy"];
        [finalKeywordArray addObject:@"rubchinsky"];
        [finalKeywordArray addObject:@"ruchinskiy"];
    }
    
    //raf simons
    if ([finalKeywordArray containsObject:@"simons"]) {
        [finalKeywordArray addObject:@"raf"];
        [finalKeywordArray addObject:@"raph"];
        [finalKeywordArray addObject:@"rafsimons"];
        [finalKeywordArray addObject:@"raphsimons"];
        [finalKeywordArray addObject:@"simmons"];
    }
    else if ([finalKeywordArray containsObject:@"simmons"]) {
        [finalKeywordArray addObject:@"raf"];
        [finalKeywordArray addObject:@"raph"];
        [finalKeywordArray addObject:@"rafsimons"];
        [finalKeywordArray addObject:@"raphsimons"];
        [finalKeywordArray addObject:@"simons"];
    }
    
    //yeezy
    if ([finalKeywordArray containsObject:@"yeezy"]) {
        [finalKeywordArray addObject:@"yeezys"];
        [finalKeywordArray addObject:@"kanye"];
        [finalKeywordArray addObject:@"yeezus"];
    }
    else if ([finalKeywordArray containsObject:@"yeezys"]) {
        [finalKeywordArray addObject:@"yeezy"];
        [finalKeywordArray addObject:@"kanye"];
        [finalKeywordArray addObject:@"yeezus"];
    }
    else if ([finalKeywordArray containsObject:@"kanye"]) {
        [finalKeywordArray addObject:@"yeezy"];
        [finalKeywordArray addObject:@"yeezys"];
        [finalKeywordArray addObject:@"yeezus"];
    }
    
    //palidas
    if ([finalKeywordArray containsObject:@"palace"] && [finalKeywordArray containsObject:@"adidas"]) {
        [finalKeywordArray addObject:@"palidas"];
    }
    
    //crew
    if ([finalKeywordArray containsObject:@"crew"]) {
        [finalKeywordArray addObject:@"crewneck"];
        [finalKeywordArray addObject:@"sweatshirt"];
        [finalKeywordArray addObject:@"sweat"];
        [finalKeywordArray addObject:@"jumper"];
        [finalKeywordArray addObject:@"sweater"];
        [finalKeywordArray addObject:@"top"];
    }
    else if ([finalKeywordArray containsObject:@"crewneck"]) {
        [finalKeywordArray addObject:@"crew"];
        [finalKeywordArray addObject:@"sweatshirt"];
        [finalKeywordArray addObject:@"sweat"];
        [finalKeywordArray addObject:@"jumper"];
        [finalKeywordArray addObject:@"sweater"];
        [finalKeywordArray addObject:@"top"];
    }
    
    //bred/black&red
    if ([finalKeywordArray containsObject:@"bred"]) {
        [finalKeywordArray addObject:@"black"];
        [finalKeywordArray addObject:@"red"];
    }
    else if ([finalKeywordArray containsObject:@"black"] && [finalKeywordArray containsObject:@"red"]) {
        [finalKeywordArray addObject:@"bred"];
    }
    
    //stone island
    if ([finalKeywordArray containsObject:@"stoney"]) {
        [finalKeywordArray addObject:@"stone"];
        [finalKeywordArray addObject:@"island"];
    }
    else if ([finalKeywordArray containsObject:@"stone"] && [finalKeywordArray containsObject:@"island"]) {
        [finalKeywordArray addObject:@"stoney"];
    }
    
    //bape
    if ([finalKeywordArray containsObject:@"bape"]) {
        [finalKeywordArray addObject:@"bathing"];
        [finalKeywordArray addObject:@"ape"];
    }
    else if ([finalKeywordArray containsObject:@"bathing"] && [finalKeywordArray containsObject:@"ape"]) {
        [finalKeywordArray addObject:@"bape"];
    }
    
    //off white
    if ([finalKeywordArray containsObject:@"offwhite"]) {
        [finalKeywordArray addObject:@"off"];
        [finalKeywordArray addObject:@"white"];
        [finalKeywordArray addObject:@"off-white"];
        [finalKeywordArray addObject:@"ofwhite"];
    }
    else if ([finalKeywordArray containsObject:@"off-white"]) {
        [finalKeywordArray addObject:@"off"];
        [finalKeywordArray addObject:@"white"];
        [finalKeywordArray addObject:@"offwhite"];
        [finalKeywordArray addObject:@"ofwhite"];
    }
    else if ([finalKeywordArray containsObject:@"of"] && [finalKeywordArray containsObject:@"white"]) {
        [finalKeywordArray addObject:@"off"];
        [finalKeywordArray addObject:@"white"];
        [finalKeywordArray addObject:@"off-white"];
        [finalKeywordArray addObject:@"offwhite"];
        [finalKeywordArray addObject:@"ofwhite"];
    }
    
    //pants
    if ([finalKeywordArray containsObject:@"joggers"]) {
        [finalKeywordArray addObject:@"sweatpants"];
        [finalKeywordArray addObject:@"trackpants"];
        [finalKeywordArray addObject:@"tracksuit"];
        [finalKeywordArray addObject:@"bottoms"];
        [finalKeywordArray addObject:@"tracksuits"];
    }
    else if ([finalKeywordArray containsObject:@"sweatpants"]) {
        [finalKeywordArray addObject:@"trackpants"];
        [finalKeywordArray addObject:@"tracksuit"];
        [finalKeywordArray addObject:@"bottoms"];
        [finalKeywordArray addObject:@"tracksuits"];
        [finalKeywordArray addObject:@"joggers"];
    }
    else if ([finalKeywordArray containsObject:@"trackpants"]) {
        [finalKeywordArray addObject:@"joggers"];
        [finalKeywordArray addObject:@"tracksuit"];
        [finalKeywordArray addObject:@"bottoms"];
        [finalKeywordArray addObject:@"tracksuits"];
        [finalKeywordArray addObject:@"sweatpants"];
    }
    else if ([finalKeywordArray containsObject:@"tracksuit"] && [finalKeywordArray containsObject:@"bottoms"]) {
        [finalKeywordArray addObject:@"joggers"];
        [finalKeywordArray addObject:@"tracksuits"];
        [finalKeywordArray addObject:@"sweatpants"];
        [finalKeywordArray addObject:@"trackpants"];
    }
    
    //longsleeve
    if ([finalKeywordArray containsObject:@"longsleeve"]) {
        [finalKeywordArray addObject:@"long-sleeve"];
        [finalKeywordArray addObject:@"long"];
        [finalKeywordArray addObject:@"sleeve"];
        [finalKeywordArray addObject:@"l/s"];
        [finalKeywordArray addObject:@"ls"];
    }
    else if ([finalKeywordArray containsObject:@"long-sleeve"]) {
        [finalKeywordArray addObject:@"longsleeve"];
        [finalKeywordArray addObject:@"long"];
        [finalKeywordArray addObject:@"sleeve"];
        [finalKeywordArray addObject:@"l/s"];
        [finalKeywordArray addObject:@"ls"];
    }
    else if ([finalKeywordArray containsObject:@"ls"]) {
        [finalKeywordArray addObject:@"longsleeve"];
        [finalKeywordArray addObject:@"long"];
        [finalKeywordArray addObject:@"sleeve"];
        [finalKeywordArray addObject:@"l/s"];
        [finalKeywordArray addObject:@"long-sleeve"];
    }
    else if ([finalKeywordArray containsObject:@"l/s"]) {
        [finalKeywordArray addObject:@"longsleeve"];
        [finalKeywordArray addObject:@"long"];
        [finalKeywordArray addObject:@"sleeve"];
        [finalKeywordArray addObject:@"ls"];
        [finalKeywordArray addObject:@"long-sleeve"];
    }
    
    //shortsleeve
    if ([finalKeywordArray containsObject:@"shortsleeve"]) {
        [finalKeywordArray addObject:@"short-sleeve"];
        [finalKeywordArray addObject:@"short"];
        [finalKeywordArray addObject:@"sleeve"];
    }
    else if ([finalKeywordArray containsObject:@"short-sleeve"]) {
        [finalKeywordArray addObject:@"shortsleeve"];
        [finalKeywordArray addObject:@"short"];
        [finalKeywordArray addObject:@"sleeve"];
    }
    
    //shortsleeve
    if ([finalKeywordArray containsObject:@"jacket"]) {
        [finalKeywordArray addObject:@"coat"];
    }
    else if ([finalKeywordArray containsObject:@"coat"]) {
        [finalKeywordArray addObject:@"jacket"];
    }
    
    //puffa
    if ([finalKeywordArray containsObject:@"puffa"]) {
        [finalKeywordArray addObject:@"puffer"];
    }
    else if ([finalKeywordArray containsObject:@"puffer"]) {
        [finalKeywordArray addObject:@"puffa"];
    }
    
    //supreme
    if ([finalKeywordArray containsObject:@"supreme"]) {
        [finalKeywordArray addObject:@"preme"];
    }
    else if ([finalKeywordArray containsObject:@"preme"]) {
        [finalKeywordArray addObject:@"supreme"];
    }
    
    //camo
    if ([finalKeywordArray containsObject:@"camo"]) {
        [finalKeywordArray addObject:@"camouflage"];
        [finalKeywordArray addObject:@"camaflage"];
        [finalKeywordArray addObject:@"camauflage"];
    }
    else if ([finalKeywordArray containsObject:@"camouflage"]) {
        [finalKeywordArray addObject:@"camo"];
        [finalKeywordArray addObject:@"camaflage"];
        [finalKeywordArray addObject:@"camauflage"];
    }
    else if ([finalKeywordArray containsObject:@"camaflage"]) {
        [finalKeywordArray addObject:@"camo"];
        [finalKeywordArray addObject:@"camouflage"];
        [finalKeywordArray addObject:@"camauflage"];
    }
    else if ([finalKeywordArray containsObject:@"camauflage"]) {
        [finalKeywordArray addObject:@"camo"];
        [finalKeywordArray addObject:@"camouflage"];
        [finalKeywordArray addObject:@"camaflage"];
    }
    
    //LV
    if ([finalKeywordArray containsObject:@"louisvuitton"]) {
        [finalKeywordArray addObject:@"louis"];
        [finalKeywordArray addObject:@"vuitton"];
        [finalKeywordArray addObject:@"lv"];
    }
    else if ([finalKeywordArray containsObject:@"louis"] && [finalKeywordArray containsObject:@"vuitton"]) {
        [finalKeywordArray addObject:@"lv"];
        [finalKeywordArray addObject:@"louisvuitton"];
    }
    
    //TNF
    if ([finalKeywordArray containsObject:@"tnf"]) {
        [finalKeywordArray addObject:@"northface"];
        [finalKeywordArray addObject:@"north"];
        [finalKeywordArray addObject:@"face"];
    }
    else if ([finalKeywordArray containsObject:@"north"] && [finalKeywordArray containsObject:@"face"]) {
        [finalKeywordArray addObject:@"tnf"];
        [finalKeywordArray addObject:@"northface"];
    }
    
    
    //remove duplications
    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:finalKeywordArray];
    NSArray *arrayWithoutDuplicates = [orderedSet array];
    
    [finalKeywordArray removeAllObjects];
    [finalKeywordArray addObjectsFromArray:arrayWithoutDuplicates];
    
    return finalKeywordArray;
}

-(void)showVerifyAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Verify Email 📩" message:@"To keep Bump safe we authenticate users via Facebook or Email.\n\nTo create your listing either tap the link in the verification email we sent you or connect your Facebook account\n\nDon't forget to check your Junk Folder" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        //dismiss VC
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

@end
