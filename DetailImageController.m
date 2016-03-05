//
//  DetailImageController.m
//  wtbtest
//
//  Created by Jack Ryder on 04/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "DetailImageController.h"

@interface DetailImageController ()

@end

@implementation DetailImageController

- (void)viewDidLoad {
    [super viewDidLoad];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissVC)];
    tap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tap];
    [self.pageControl setNumberOfPages:self.numberOfPics];
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    
    // Setting the swipe direction.
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    
    // Adding the swipe gesture on image view
    [self.view addGestureRecognizer:swipeLeft];
    [self.view addGestureRecognizer:swipeRight];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.imageView setFile:[self.listing objectForKey:@"image1"]];
    
    [self.pageControl setCurrentPage:self.index];
    [self.imageView loadInBackground];
}

-(void)dismissVC{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe {
    
    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        NSLog(@"Left Swipe");
        if (self.pageControl.currentPage != 4) {
            if (self.pageControl.currentPage == 0) {
                 [self.imageView setFile:[self.listing objectForKey:@"image2"]];
                [self.pageControl setCurrentPage:1];
            }
            else if (self.pageControl.currentPage == 1){
                 [self.imageView setFile:[self.listing objectForKey:@"image3"]];
                [self.pageControl setCurrentPage:2];
            }
            else if (self.pageControl.currentPage == 2){
                 [self.imageView setFile:[self.listing objectForKey:@"image4"]];
                [self.pageControl setCurrentPage:3];
            }
            [self.imageView loadInBackground];
        }
    }
    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        NSLog(@"Right Swipe");
        if (self.pageControl.currentPage != 0) {
            if (self.pageControl.currentPage == 1) {
                [self.imageView setFile:[self.listing objectForKey:@"image1"]];
                [self.pageControl setCurrentPage:0];
            }
            else if (self.pageControl.currentPage == 2){
                 [self.imageView setFile:[self.listing objectForKey:@"image2"]];
                [self.pageControl setCurrentPage:1];
            }
            else if (self.pageControl.currentPage == 3){
                 [self.imageView setFile:[self.listing objectForKey:@"image3"]];
                [self.pageControl setCurrentPage:2];
            }
            [self.imageView loadInBackground];
        }
    }
}
@end
