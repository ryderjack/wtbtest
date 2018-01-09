//
//  TOJRWebView.m
//  wtbtest
//
//  Created by Jack Ryder on 26/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "TOJRWebView.h"
#import <Crashlytics/Crashlytics.h>
#import <Parse/Parse.h>

@interface TOJRWebView ()

@end

@implementation TOJRWebView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cancelCross"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
    self.applicationLeftBarButtonItems = @[cancelButton];
    self.view.backgroundColor = [UIColor whiteColor];
    
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
    
    if (self.payMode != YES) {
        //web view seemed to be pushed down y slightly so ensure its at the top of the view
        [self.webView setFrame:CGRectMake(self.webView.frame.origin.x, self.view.frame.origin.y, self.webView.frame.size.width, self.webView.frame.size.height)];
    }
    else{
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            if (@available(iOS 11.0, *)) {
                [self.webView setFrame:CGRectMake(self.webView.frame.origin.x, self.view.frame.origin.y+(self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height + 44), self.webView.frame.size.width, self.webView.frame.size.height)];
            }
        });
    }
    
    if (self.dropMode == YES) {
        self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    }
    
    if (self.infoMode) {
        UIView *emailView = [[UIView alloc]initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height, self.view.frame.size.width, 44)];
        UIButton *emailButton = [[UIButton alloc]initWithFrame:CGRectMake(0,0, emailView.frame.size.width, emailView.frame.size.height)];
        emailButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        emailButton.titleLabel.minimumScaleFactor=0.5;
        [emailButton setTitle:[NSString stringWithFormat:@"Seller's email copied, paste when ready!"] forState:UIControlStateNormal];
        emailButton.backgroundColor = [UIColor colorWithRed:0.42 green:0.42 blue:0.84 alpha:1.0];
        [emailButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        emailButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:15];
        [emailView addSubview:emailButton];
        [emailButton setCenter:CGPointMake(emailView.frame.size.width / 2, emailView.frame.size.height / 2)];
        [self.view addSubview:emailView];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
        
    if (self.createMode == YES) {
        if ([[[PFUser currentUser]objectForKey:@"addImageTutorial"]isEqualToString:@"NO"]) {
            
            //add blur view
            self.blurView = [[FXBlurView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
            [self.blurView setTintColor:[UIColor whiteColor]];
            self.navigationController.navigationBar.layer.zPosition = -1;
            [self.view addSubview:self.blurView];
            
            [self hideBarButton];
            
            AddImagesTutorial *vc = [[AddImagesTutorial alloc]init];
            vc.delegate = self;
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
    else if(self.dropMode == YES || self.storeMode == YES || self.payMode == YES){
        [self showHUD];
    }
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    if (self.createMode == YES || self.editMode == YES || self.depopMode == YES) {
        //scroll down
        NSLog(@"OFFSET");
        [self.webView.scrollView setContentOffset:CGPointMake(0,140) animated:NO];
        [self.placeholderView removeFromSuperview];
    }
    else if(self.dropMode == YES || self.storeMode == YES || self.payMode){
        [self hideHUD];
    }
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    if(self.dropMode == YES || self.storeMode == YES || self.payMode == YES){
        [self hideHUD];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if (self.createMode == YES || self.editMode == YES || self.depopMode == YES) {
        if (self.editMode == YES || self.depopMode == YES){
            //            self.doneButton = nil;
        }
        
        int adjust = 60;
        //iPhone X has a bigger status bar - was 20px now 44px
        
        if ([ [ UIScreen mainScreen ] bounds ].size.height == 812) {
            //iPhone X
            adjust = 80;
        }
        
        self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-adjust, [UIApplication sharedApplication].keyWindow.frame.size.width, adjust)];
        [self.longButton setTitle:@"S C R E E N S H O T" forState:UIControlStateNormal];
        [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
        [self.longButton addTarget:self action:@selector(screenshotHit) forControlEvents:UIControlEventTouchUpInside];
        self.longButton.alpha = 0.0f;
        [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
        
        [self showBarButton];
    }
    else if (self.balanceMode == YES){
        
    }
    else if (self.payMode == YES){
        //        self.doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Paid" style:UIBarButtonItemStylePlain target:self action:@selector(paidPressed)];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    if (self.showingSpinner == YES) {
        self.showingSpinner = NO;
        [self hideHUD];
    }

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
        [self.delegate screeshotPressed:screenshot2 withTaps:self.tapCount]; //should probs avoid the auto cropping for now as chance could go wrong
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
    if (self.payMode == YES) {
        [self leavePrompt];
    }
    else{
        [self.delegate cancelWebPressed];
    }
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

-(void)showHUD{
    //only show HUD on initial web page load
    if (self.showingSpinner == YES) {
        return;
    }
    self.showingSpinner = YES;
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (!self.spinner) {
        self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    }
    self.hud.square = YES;
    
    if (self.dropMode == YES) {
        self.hud.labelText = @"🙏";
    }
    
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)leavePrompt{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Sure?" message:@"Are you sure you want to leave this page?" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Yes, leave" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.delegate cancelWebPressed];
    }]];
    
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)dismissedAddImage{
    //reset nav bar
    self.navigationController.navigationBar.layer.zPosition = 0;
    
    //hide blur view
    [UIView animateWithDuration:0.1 delay:0.0 options:0 animations:^{
        self.blurView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.blurView setHidden:YES];
    }];
    
    //reshow bar button
    [self showBarButton];
}

-(void)showBarButton{
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

-(void)hideBarButton{
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                         self.buttonShowing = NO;
                     }];
}
@end
