//
//  MessagesTutorial.m
//  wtbtest
//
//  Created by Jack Ryder on 26/10/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "MessagesTutorial.h"
#import <Parse/Parse.h>
#import "CreateViewController.h"

@interface MessagesTutorial ()

@end

@implementation MessagesTutorial

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.fromMessageVC == YES) {
        [self.crossButton setHidden:NO];
    }
    else{
        [self.crossButton setHidden:YES];
    }
    // Do any additional setup after loading the view from its nib.
    self.progressNumber = 0;
    if (self.sellerMode == YES) {
        self.titleLabel.text = @"Introducing\nSeller Profiles";
        self.explainLabel.text = @"We’re working with a small group of sellers to recommend relevant items based on your WTBs";
        self.heroImageView.image = [UIImage imageNamed:@"sellerProfile"];
    }
    else if (self.introMode == YES){
        self.titleLabel.text = @"How does it work";
        self.explainLabel.text = @"Create listings for items you want to buy. Got something to sell? Find someone that wants to buy it and send them a message!";
        self.heroImageView.image = [UIImage imageNamed:@"yeezy"];
    }
    else{
        self.titleLabel.text = @"How to sell on Bump";
        self.explainLabel.text = @"On Bump, sellers send buyers an offer to buy their stuff. Tap the tag icon to send an offer, pictures & more!";
        self.heroImageView.image = [UIImage imageNamed:@"tagExplain"];
    }
    [self.progressButton setHidden:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
- (IBAction)progressButtonTapped:(id)sender {
    self.progressNumber++;
    if (self.progressNumber == 1) {
        //goto page 2
        [self setupPageTwo];
    }
    else if (self.progressNumber == 2) {
        //goto final page
        if (self.introMode == YES){
            PFUser *current = [PFUser currentUser];
            [current setObject:@"YES" forKey:@"completedIntroTutorial"];
            [current saveInBackground];
            
            CreateViewController *vc = [[CreateViewController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            [self setupPageThree];
        }
    }
    else if (self.progressNumber == 3) {
        //dismiss
        if (self.sellerMode == YES) {
            [self dismissViewControllerAnimated:YES completion:^{
                PFUser *current = [PFUser currentUser];
                [current setObject:@"YES" forKey:@"completedBuyNow"];
                [current saveInBackground];
            }];
        }
        else{
            [self setupPageFour];
        }
    }
    else if (self.progressNumber == 4) {
        //goto final page
        [self setupPageFive];
    }
    else if (self.progressNumber == 5) {
        //dismiss
        [self dismissViewControllerAnimated:YES completion:^{
            PFUser *current = [PFUser currentUser];
            [current setObject:@"YES" forKey:@"completedMsgIntro2"];
            [current saveInBackground];
        }];
    }
}

-(void)setupPageTwo{
    [self.progressButton setHidden:YES];
    [self performSelector:@selector(unhideProgress) withObject:nil afterDelay:1.0];
    
    if (self.sellerMode == YES) {
        self.titleLabel.text = @"Suggested Items";
        self.explainLabel.text = @"Tap on the cart to view suggested items based on what you want to buy on Bump";
        self.heroImageView.image = [UIImage imageNamed:@"cartTab"];
    }
    else if (self.introMode == YES){
        [self.progressButton setTitle:@"Create a WTB" forState:UIControlStateNormal];
        self.titleLabel.text = @"Suggested Items";
        self.explainLabel.text = @"Bump uses your wanted items to show you relevant products that can be purchased within the app";
        self.heroImageView.image = [UIImage imageNamed:@"buyNowTut"];
    }
    else{
        self.titleLabel.text = @"Send an offer";
        self.explainLabel.text = @"Fill out the name of what you're selling, condition, price & whether you want to meetup then hit send!";
        self.heroImageView.image = [UIImage imageNamed:@"newOffer"];

//        NSArray *offerImages = @[@"offer_1.png",@"offer_2.png",@"offer_3.png",@"offer_4.png",@"offer_5.png", @"offer_6.png", @"offer_7.png", @"offer_8.png", @"offer_9.png"];
//        NSMutableArray *images = [[NSMutableArray alloc] init];
//        for (int i = 0; i < offerImages.count; i++) {
//            [images addObject:[UIImage imageNamed:[offerImages objectAtIndex:i]]];
//        }
//        
//        // Normal Animation
//        self.heroImageView.animationImages = images;
//        self.heroImageView.animationDuration = 1.0;
//        [self.heroImageView startAnimating];
    }
}

-(void)setupPageThree{
    [self.heroImageView stopAnimating];
    
    if (self.sellerMode == YES) {
        [self.progressButton setHidden:YES];
        [self.progressButton setTitle:@"Done" forState:UIControlStateNormal];
        [self performSelector:@selector(unhideProgress) withObject:nil afterDelay:1.0];
        self.titleLabel.text = @"Buy it now";
        self.explainLabel.text = @"Recommended items are displayed under a WTB. Tap one to view details, message the seller and purchase it on Bump";
        self.heroImageView.image = [UIImage imageNamed:@"buyNowTut"];
    }
    else{
        [self.progressButton setHidden:NO];
        [self.progressButton setTitle:@"Next" forState:UIControlStateNormal];
        self.titleLabel.text = @"Buy on Bump";
        self.explainLabel.text = @"After you've sent your offer, buyers can tap on the offer message, to be taken to the checkout";
        self.heroImageView.image = [UIImage imageNamed:@"buy_1"];
        
//        NSArray *buyImages = @[@"buy_1.png",@"buy_2.png",@"buy_3.png",@"buy_4.png",@"buy_5.png"];
//        NSMutableArray *images = [[NSMutableArray alloc] init];
//        for (int i = 0; i < buyImages.count; i++) {
//            [images addObject:[UIImage imageNamed:[buyImages objectAtIndex:i]]];
//        }
//        
//        // Normal Animation
//        self.heroImageView.animationImages = images;
//        self.heroImageView.animationDuration = 5.0;
//        [self.heroImageView startAnimating];
    }
}

-(void)setupPageFour{
    self.titleLabel.text = @"Buy on Bump";
    self.explainLabel.text = @"Buyers enter their address, check the total then hit Pay with PayPal";
    
    NSArray *buyImages = @[@"buy_2.png",@"buy_3.png",@"buy_4.png"];
    NSMutableArray *images = [[NSMutableArray alloc] init];
    for (int i = 0; i < buyImages.count; i++) {
        [images addObject:[UIImage imageNamed:[buyImages objectAtIndex:i]]];
    }
    
    // Normal Animation
    self.heroImageView.animationImages = images;
    self.heroImageView.animationDuration = 3.0;
    [self.heroImageView startAnimating];

}

-(void)setupPageFive{
    [self.heroImageView stopAnimating];
    [self.progressButton setTitle:@"Done" forState:UIControlStateNormal];
    self.titleLabel.text = @"Buy on Bump";
    self.explainLabel.text = @"Log in to PayPal and pay the seller's email address in the top banner then hit 'Paid'!";
    self.heroImageView.image = [UIImage imageNamed:@"buy_5"];
}

-(void)unhideProgress{
    self.progressButton.alpha = 0.0;
    [self.progressButton setHidden:NO];
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.progressButton setAlpha:1.0];
                         
                     }
                     completion:nil];
}
- (IBAction)cancelPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setHidden:YES];
}

@end
