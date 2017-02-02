//
//  TOJRWebView.m
//  wtbtest
//
//  Created by Jack Ryder on 26/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "TOJRWebView.h"
#import <Crashlytics/Crashlytics.h>
#import "AddImagesTutorial.h"
#import <Parse/Parse.h>

@interface TOJRWebView ()

@end

@implementation TOJRWebView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
    self.applicationLeftBarButtonItems = @[cancelButton];
    
    if (self.createMode == YES || self.editMode == YES) {
        self.tapCount = 0;
        UITapGestureRecognizer *targetGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        targetGesture.numberOfTapsRequired = 1;
        targetGesture.delegate = self;
        [self.webView addGestureRecognizer:targetGesture];
    }
    
    if ([[[PFUser currentUser]objectForKey:@"oneTapWarning"]isEqualToString:@"YES"]) {
        self.seenOneTapWarning = YES;
    }
    else{
        self.seenOneTapWarning = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.createMode == YES) {
        if (![[[PFUser currentUser]objectForKey:@"addImageTutorial"]isEqualToString:@"YES"]) {
            AddImagesTutorial *vc = [[AddImagesTutorial alloc]init];
            vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
            [self presentViewController:vc animated:YES completion:nil];
        }
    }
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
    if (self.createMode == YES || self.editMode == YES || self.depopMode == YES) {
        //hide webview whilst it loads
        self.placeholderView = [[UIImageView alloc]initWithFrame:self.webView.frame];
        self.placeholderView.backgroundColor = [UIColor whiteColor];
        [self.webView addSubview:self.placeholderView];
    }
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    if (self.createMode == YES || self.editMode == YES || self.depopMode == YES) {
        //scroll down
        [self.webView.scrollView setContentOffset:CGPointMake(0,180) animated:NO];
        [self.placeholderView removeFromSuperview];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if (self.createMode == YES || self.editMode == YES || self.depopMode == YES) {
        if (self.editMode == YES || self.depopMode == YES){
            self.doneButton = nil;
        }
        else if (self.createMode == YES){
            self.doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Camera" style:UIBarButtonItemStylePlain target:self action:@selector(CameraPressed)];
        }
        
        self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
        [self.longButton setTitle:@"S C R E E N S H O T" forState:UIControlStateNormal];
        [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
        [self.longButton addTarget:self action:@selector(screenshotHit) forControlEvents:UIControlEventTouchUpInside];
        self.longButton.alpha = 0.0f;
        [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
        
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.longButton.alpha = 1.0f;
                         }
                         completion:^(BOOL finished) {
                             NSLog(@"showing");
                             self.buttonShowing = YES;
                         }];
    }
    else if (self.balanceMode == YES){
        
    }
    else if (self.payMode == YES){
        self.doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Paid" style:UIBarButtonItemStylePlain target:self action:@selector(paidPressed)];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                         self.buttonShowing = NO;
                         [self.longButton removeFromSuperview];
                         self.longButton = nil;
                     }];
}



-(void)screenshotHit{
    if (self.tapCount == 0 && self.createMode == YES) {
        NSLog(@"zero");
        return;
    }
    
    if (self.tapCount == 1 && self.seenOneTapWarning == NO && (self.createMode == YES || self.editMode == YES)) {
        //show custom alert telling user to tap on image again
        [self showOneTapAlert];
    }
    /*
    else if (self.tapCount == 1){
        UIImage *screenshot1 = [self screenshotOne];
        [self.delegate screeshotPressed:screenshot1 withTaps:self.tapCount];
    }
    else if (self.tapCount == 2){
        UIImage *screenshot2 = [self screenshotTwo];
        [self.delegate screeshotPressed:screenshot2 withTaps:self.tapCount]; //CHANGE should probs avoid the auto cropping for now as chance could go wrong
    }
     */
    else{
        UIImage *screenshot = [self screenshot];
        [self.delegate screeshotPressed:screenshot withTaps:self.tapCount];
    }
}

-(void)CameraPressed{
    [self.delegate cameraPressed];
}

-(void)paidPressed{
    [self.delegate paidPressed];
}
     
-(UIImage *)screenshot
{
    CGRect rect;
    rect=CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef context=UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:context];
    
    UIImage *image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

//when tapped twice
-(UIImage *)screenshotTwo{
    
    UIGraphicsBeginImageContext(self.view.bounds.size);
    
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    CGRect rect = CGRectMake(0,200,self.view.frame.size.width, 375);
    CGImageRef imageRef = CGImageCreateWithImageInRect([viewImage CGImage], rect);
    
    UIImage *img = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    
    return img;
}

//when tapped once
-(UIImage *)screenshotOne{
    
    UIGraphicsBeginImageContext(self.view.bounds.size);
    
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    CGRect rect = CGRectMake(0,111,self.view.frame.size.width, 375);
    CGImageRef imageRef = CGImageCreateWithImageInRect([viewImage CGImage], rect);
    
    UIImage *img = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    
    return img;
}

-(void)cancelPressed{
    [self.delegate cancelWebPressed];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    //if you would like to manipulate the otherGestureRecognizer here is an example of how to cancel and disable it
    if([otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]){
        
        UITapGestureRecognizer *tapRecognizer = (UITapGestureRecognizer*)otherGestureRecognizer;
        if(tapRecognizer.numberOfTapsRequired == 2 && tapRecognizer.numberOfTouchesRequired == 1){
            
            //this disalbes and cancels all other singleTouchDoubleTap recognizers
            // default is YES. disabled gesture recognizers will not receive touches. when changed to NO the gesture recognizer will be cancelled if it's currently recognizing a gesture
            otherGestureRecognizer.enabled = NO;
        }
    }
    return YES;
}
-(void)handleTap:(id)sender{
    self.tapCount++;
}

//show one tap warning
-(void)showOneTapAlert{
    if (self.alertShowing == YES) {
        return;
    }
    
    [Answers logCustomEventWithName:@"One tap warning shown"
                   customAttributes:@{}];
    
    self.alertShowing = YES;
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
    self.customAlert.titleLabel.text = @"Tap image one more time!";
    self.customAlert.messageLabel.text = @"To get the best version of your chosen image tap it one more time 👆 then hit Screenshot!";
    self.customAlert.numberOfButtons = 1;
    
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
                     completion:^(BOOL finished) {
                         self.seenOneTapWarning = YES;
                         [[PFUser currentUser]setObject:@"YES" forKey:@"oneTapWarning"];
                         [[PFUser currentUser]saveInBackground];
                     }];
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
                         self.alertShowing = NO;
                         [self.customAlert setAlpha:0.0];
                         self.customAlert = nil;
                     }];
}

-(void)firstPressed{
    //do nothing
}
-(void)secondPressed{
    //do nothing
}


@end
