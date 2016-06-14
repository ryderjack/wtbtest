//
//  Tut1ViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 24/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "Tut1ViewController.h"

@interface Tut1ViewController ()

@end

@implementation Tut1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.startButton setHidden:YES];
    
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    self.mainLabel.minimumScaleFactor=0.5;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.pageControl setCurrentPage:self.index];
    
    if (self.index == 0) {
        self.mainTitle.text = @"Selling";
        self.mainLabel.text = @"Listings show how much the buyer is willing to pay and the condition of the item they wantobuy";
        self.imageView.image = [UIImage imageNamed:@"pic1"];
        
    }
    else if (self.index == 1){
        self.mainTitle.text = @"Selling";
        self.mainLabel.text = @"Hit the filter button to refine your search results when looking for items people want";
        self.imageView.image = [UIImage imageNamed:@"pic2"];
        
    }
    else if (self.index == 2){
        self.mainTitle.text = @"Buying";
        self.mainLabel.text = @"Tell sellers exactly what you want";
        self.imageView.image = [UIImage imageNamed:@"pic3"];
        
    }
    else if (self.index == 3){
        self.mainTitle.text = @"Buying";
        self.mainLabel.text = @"All Payments are made securely using PayPal";
        self.imageView.image = [UIImage imageNamed:@"paypal"];
        [self.startButton setHidden:NO];
    }
}
- (IBAction)startPressed:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
