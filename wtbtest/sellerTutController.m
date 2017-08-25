//
//  sellerTutController.m
//  wtbtest
//
//  Created by Jack Ryder on 05/06/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "sellerTutController.h"

@interface sellerTutController ()

@end

@implementation sellerTutController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mainImageView.layer.cornerRadius = 10.0;
    self.mainImageView.layer.masksToBounds = YES;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    //long button setup
    self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
    [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
    [self.longButton setTitle:@"N E X T" forState:UIControlStateNormal];
    [self.longButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
    [self.longButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];
    [self.longButton addTarget:self action:@selector(nextPressed) forControlEvents:UIControlEventTouchUpInside];
    self.longButton.alpha = 0.0f;
    [self.view addSubview:self.longButton];
    [self showBarButton];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)dismissPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)nextPressed{

    if (self.pageIndex == 0) {
        [self.longButton setAlpha:0.0];
        self.mainLabel.text = @"Make sure your listings have good quality images as well as a detailed description";
        
        [UIView animateWithDuration:0.2
                              delay:1
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.longButton.alpha = 1.0f;
                         }
                         completion:^(BOOL finished) {
                         }];
    }
    else if (self.pageIndex == 1){
        [self.longButton setAlpha:0.0];
        [UIView animateWithDuration:0.2
                              delay:1
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.longButton.alpha = 1.0f;
                         }
                         completion:^(BOOL finished) {
                         }];
        
        self.mainLabel.text = @"Once you’ve been approved, tap the plus to get started!";
        
        [self.mainImageView setImage:[UIImage imageNamed:@"sellerTutPlus"]];
        
        [self.longButton setTitle:@"D O N E" forState:UIControlStateNormal];
        [self.longButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
    }
    else if (self.pageIndex == 2){
        [self.longButton setEnabled:NO];
        [self finishTutorial];
    }
    
    self.pageIndex++;
}

-(void)hideBarButton{
    self.buttonShowing = NO;
    
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)showBarButton{
    self.buttonShowing = YES;
    
    self.longButton.alpha = 0.0f;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.longButton.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self hideBarButton];
}

-(void)viewDidDisappear:(BOOL)animated{
    self.longButton = nil;
}

-(void)finishTutorial{
    if (self.alreadySeen == YES) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }

    [self showHUD];
    
    self.sellerApp[@"howToList"] = @"YES";
    [self.sellerApp saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            [self hideHUD];
            [self.delegate completedSellerTut];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else{
            [self hideHUD];
            [self.longButton setEnabled:YES];
            [self showAlertWithTitle:@"Saving Error" andMsg:@"Make sure you're connected to the internet!"];
        }
    }];
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
}
@end
