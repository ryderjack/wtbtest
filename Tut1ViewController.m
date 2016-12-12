//
//  Tut1ViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 24/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "Tut1ViewController.h"
#import "CreateViewController.h"
#import "NavigationController.h"

@interface Tut1ViewController ()

@end

@implementation Tut1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.createButton setHidden:YES];
    [self.dimissButton setHidden:YES];
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
        self.heroImageView.image = [UIImage imageNamed:@"iPhoneIntro1"];
        self.titleLabel.text = @"Bump";
        self.descriptionLabel.text = @"List items that you want and sellers get in touch";
        [self.createButton setHidden:YES];
    }
    else if (self.index == 1){
        self.heroImageView.image = [UIImage imageNamed:@"iPhoneIntro2.1"];
        self.titleLabel.text = @"Selling";
        self.descriptionLabel.text = @"Tap a listing. Message the buyer. Hit the tag. Send them an offer. Sold.";
        [self.createButton setHidden:YES];
        
        if (self.messageExplain == YES) {
            [self.dimissButton setAlpha:0.0];
            [self.dimissButton setHidden:NO];
            [UIView animateWithDuration:1.0
                                  delay:1.0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.dimissButton setAlpha:1.0];
                             }
                             completion:nil];
        }
        [self setupSelling];
    }
    else if (self.index == 2){
        self.heroImageView.image = [UIImage imageNamed:@"iPhone3"];
        self.titleLabel.text = @"Buying";
        self.descriptionLabel.text = @"Bump also recommends items that can be purchased straight away";
        
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
        else{
            [self.createButton setAlpha:0.0];
            [self.createButton setHidden:NO];
            
            [UIView animateWithDuration:1.0
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.createButton setAlpha:1.0];
                             }
                             completion:nil];
        }
    }
}

-(void)dismissCreateController:(CreateViewController *)controller{
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
}

-(void)setupSelling{
    [UIView animateKeyframesWithDuration:5.5 delay:0.6 options:UIViewKeyframeAnimationOptionCalculationModeLinear | UIViewKeyframeAnimationOptionRepeat animations:^{
        [self.cursorImageView setAlpha:0.0f];
        [self.screenImageView setAlpha:0.0f];
        [self.sendOfferImageView setAlpha:0.0f];
        
        //1.1 cursor appears
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.025 animations:^{
            self.cursorImageView.alpha = 1.0f;
        }];
        
        //1.2 cursor moves up
        [UIView addKeyframeWithRelativeStartTime:0.02 relativeDuration:0.1 animations:^{
            self.cursorImageView.transform = CGAffineTransformMakeTranslation(0,-60);
        }];
        
        //1.3 show message VC
        [UIView addKeyframeWithRelativeStartTime:0.15 relativeDuration:0.1 animations:^{
            [self.screenImageView setAlpha:1.0f];
        }];
        
        //1.4 cursor moves down to tag
        [UIView addKeyframeWithRelativeStartTime:0.4 relativeDuration:0.3 animations:^{
            self.cursorImageView.transform = CGAffineTransformMakeTranslation(-110, 18);
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
        PFUser *current = [PFUser currentUser];
        [current setObject:@"YES" forKey:@"completedIntroTutorial"];
        [current saveInBackground];
        
        CreateViewController *vc = [[CreateViewController alloc]init];
        vc.introMode = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}
@end
