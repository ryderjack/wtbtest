//
//  supportAnswerVC.m
//  wtbtest
//
//  Created by Jack Ryder on 10/03/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import "supportAnswerVC.h"
#import "Mixpanel/Mixpanel.h"
#import <Intercom/Intercom.h>

@interface supportAnswerVC ()

@end

@implementation supportAnswerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mainCell.selectionStyle = UITableViewCellSelectionStyleNone;

    //get the parent topic from supportObject passed here
    NSString *parentTopic = @"";
    
    if (self.showShippingAnswer) {
        self.titleLabel.text = @"I have not received my item";
        parentTopic = @"not received";
        
        PFQuery *answerQuery = [PFQuery queryWithClassName:@"AnswerObject"];
        [answerQuery whereKey:@"status" equalTo:@"live"];
        [answerQuery whereKey:@"parentTopic" equalTo:@"not received"];
        [answerQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                self.answerObject = object;
                self.textView.text = [object objectForKey:@"answerText"];
                
                //setup text and button
                if ([[object objectForKey:@"showButton"]isEqualToString:@"YES"]) {
                    [self setupButton];
                }
                
            }
            else{
                [self showAlertWithTitle:@"Error Retrieving Answer" andMsg:@"Ensure you're connected to the internet and then try again.\n\nIf the problem persists please email hello@sobump.com"];
            }
        }];
    }
    else{
        parentTopic = [self.supportObject objectForKey:@"topic"];
        self.titleLabel.text = [self.supportObject objectForKey:@"title"];
        
        PFQuery *answerQuery = [PFQuery queryWithClassName:@"AnswerObject"];
        [answerQuery whereKey:@"status" equalTo:@"live"];
        [answerQuery whereKey:@"parentTopic" equalTo:parentTopic];
        [answerQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                self.answerObject = object;
                self.textView.text = [object objectForKey:@"answerText"];
                
                //setup text and button
                if ([[object objectForKey:@"showButton"]isEqualToString:@"YES"]) {
                    [self setupButton];
                }
                
            }
            else{
                [self showAlertWithTitle:@"Error Retrieving Answer" andMsg:@"Ensure you're connected to the internet and then try again.\n\nIf the problem persists please email hello@sobump.com"];
            }
        }];
    }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Support Answer" properties:@{
                                                          @"topic":parentTopic
                                                          }];
    [Intercom logEventWithName:@"viewed_support_answer" metaData:@{
                                                                   @"topic":parentTopic
                                                                   }];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.mainCell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 679;
}

-(void)barButtonPressed{
    if (self.messageMode) {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Tapped Support Chat" properties:@{}];
        
        [Intercom presentMessenger];
    }
    else{
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Tapped Support Help" properties:@{}];
        
        //need more help pressed
        [self showMessagePrompt];
    }
}

-(void)showHUD{
    
    if (!self.spinner) {
        self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    }
    
    [self.spinner startAnimating];
    
    if (!self.hud) {
        self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        self.hud.square = YES;
        self.hud.mode = MBProgressHUDModeCustomView;
        self.hud.customView = self.spinner;
    }
    
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.hud.labelText = @"";
        self.hud = nil;
    });
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self hideBarButton];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    self.longButton = nil;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.longShowing != YES && self.longButton) {
        [self showBarButton];
    }
}

-(void)hideBarButton{
    self.longShowing = NO;

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
    self.longShowing = YES;

    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.longButton.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)setupButton{
    if (!self.longButton) {
        
        if ([ [ UIScreen mainScreen ] bounds ].size.height == 812) {
            //iPhone X
            self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-90, [UIApplication sharedApplication].keyWindow.frame.size.width, 90)];
        }
        else{
            self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
        }
        
        if ([[self.answerObject objectForKey:@"buttonType"]isEqualToString:@"message"]) {
            self.messageMode = YES;
            [self.longButton setTitle:@"Chat now" forState:UIControlStateNormal];
            [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
            [self.longButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
        else{
            [self.longButton setTitle:@"Still need help?" forState:UIControlStateNormal];
            [self.longButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
            [self.longButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }

        [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:15]];
        [self.longButton addTarget:self action:@selector(barButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        self.longButton.alpha = 0.0f;
        [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
    }
    
    if (self.longShowing != YES) {
        [self showBarButton];
    }
}

-(void)showMessagePrompt{
    [self hideBarButton];
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Have you opened a PayPal dispute?" message:@"This is a neccessary step before proceeding.\n\nPlease follow the instructions above to successfully create a PayPal dispute" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Yes I have" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Tapped Support Chat" properties:@{
                                                            @"source":@"dispute prompt"
                                                            }];

        [Intercom presentMessenger];
        [self showBarButton];
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self showBarButton];
    }]];
    
    [self presentViewController:alertView animated:YES completion:nil];
}


@end
