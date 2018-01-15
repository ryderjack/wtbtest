//
//  BumpingIntroVC.m
//  wtbtest
//
//  Created by Jack Ryder on 21/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "BumpingIntroVC.h"

@interface BumpingIntroVC ()

@end

@implementation BumpingIntroVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIView setAnimationsEnabled:YES];
    self.selectedMainImageView.alpha = 0.0;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //animate in dismiss button after read text
    [self.dismissButton setAlpha:0.0];
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             
                             [self.dismissButton setAlpha:1.0];
                         }
                         completion:^(BOOL finished) {
                         }];
    });
    
    
    //restart animations when come back from bg
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartAnimations) name:@"refreshHome" object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.cursorImageView.transform = CGAffineTransformIdentity;
    [self.cursorImageView setAlpha:0.0f];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //needs to be here, didn't work in VDL
    [self setupBumping];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissPressed:(id)sender {
    [self.delegate dismissedBumpingIntro];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)removeAnimations{
    [self.cursorImageView.layer removeAllAnimations];
}

-(void)restartAnimations{
    [self removeAnimations];
    self.cursorImageView.transform = CGAffineTransformMakeTranslation(0,0);
    [self setupBumping];
}

-(void)setupBumping{
//    [UIView animateKeyframesWithDuration:2.0 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear | UIViewKeyframeAnimationOptionRepeat animations:^{
//        [self.cursorImageView setAlpha:0.0f];
//        self.selectedMainImageView.alpha = 0.0;
//        self.mainImageView.alpha = 1.0;
//        self.cursorImageView.transform = CGAffineTransformMakeTranslation(0, 0);
//
//        //1.1 cursor appears
//        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.025 animations:^{
//            self.cursorImageView.alpha = 1.0f;
//        }];
//
//        //1.2 cursor moves up
//        [UIView addKeyframeWithRelativeStartTime:0.02 relativeDuration:0.4 animations:^{
//            self.cursorImageView.transform = CGAffineTransformMakeTranslation(0,-170);
//        }];
//
//        //1.3 show bumped listing
//        [UIView addKeyframeWithRelativeStartTime:0.4 relativeDuration:0.2 animations:^{
//            [self.cursorImageView setAlpha:0.0f];
//            self.mainImageView.alpha = 0.0;
//            self.selectedMainImageView.alpha = 1.0;
//        }];
//
//    } completion:^(BOOL finished) {
//        [self.cursorImageView setAlpha:0.0f];
//        self.selectedMainImageView.alpha = 0.0;
//    }];
    
    [UIView animateWithDuration:0.3
                          delay:0.2
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                        self.mainImageView.alpha = 0.0;
                        self.selectedMainImageView.alpha = 1.0;
                     }
                     completion:nil];
    
}
@end
