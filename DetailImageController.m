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
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(dismissVC)];
    [self.view addGestureRecognizer:swipe];
    
    [self.pageControl setNumberOfPages:self.numberOfPics];
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    
    // Setting the swipe direction.
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    
    // Adding the swipe gesture on image view
    [self.view addGestureRecognizer:swipeLeft];
    [self.view addGestureRecognizer:swipeRight];
    
    if (self.listingPic == YES) {
        // don't show tagged label
        [self.tagLabel setHidden:YES];
    }
    else{
        // show it oh show it!
        [self.tagLabel setHidden:NO];
        self.tagLabel.text = self.tagText;
    }
    
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 6.0;
    self.scrollView.contentSize = self.imageView.frame.size;
    self.scrollView.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (self.messagesPicMode == YES) {
        [self.imageView setImage:self.messagePicture];
    }
    else{
        if (self.offerMode == YES) {
            [self.imageView setFile:[self.listing objectForKey:@"image"]];

        }
        else{
            [self.imageView setFile:[self.listing objectForKey:@"image1"]];
        }
    }
    
    [self.pageControl setCurrentPage:self.index];
    [self.imageView loadInBackground];
}

-(void)dismissVC{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe {
    if (self.numberOfPics > 1) {
       self.imageView.image = nil;
    }
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
        }
    }
    if (self.numberOfPics > 1) {
        //set placeholder spinner view
        MBProgressHUD __block *hud = [MBProgressHUD showHUDAddedTo:self.imageView animated:YES];
        hud.square = YES;
        hud.mode = MBProgressHUDModeCustomView;
        hud.color = [UIColor blackColor];
        DGActivityIndicatorView __block *spinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor whiteColor] size:20.0f];
        hud.customView = spinner;
        [spinner startAnimating];
        
        [self.imageView loadInBackground:^(UIImage * _Nullable image, NSError * _Nullable error) {
        } progressBlock:^(int percentDone) {
            if (percentDone == 100) {
                //remove spinner
                [spinner stopAnimating];
                [MBProgressHUD hideHUDForView:self.imageView animated:NO];
                spinner = nil;
                hud = nil;
            }
        }];
    }
}
@end
