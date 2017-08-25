//
//  DetailImageController.m
//  wtbtest
//
//  Created by Jack Ryder on 04/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "DetailImageController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface DetailImageController ()

@end

@implementation DetailImageController

- (void)viewDidLoad {
    [super viewDidLoad];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(crossPressed:)];
    tap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tap];
    
    if (self.numberOfPics > 20) {
        [self.pageControl setHidden:YES];
    }
    else if (self.numberOfPics > 1){
        [self.pageControl setNumberOfPages:self.numberOfPics];
    }
    else{
        [self.pageControl setNumberOfPages:0];
    }
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(crossPressed:)];
    [swipe setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.view addGestureRecognizer:swipe];
    
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
    self.scrollView.contentSize = self.carousel.frame.size;
    self.scrollView.delegate = self;
    
    //zoom setup
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapFrom:)];
    [doubleTap setNumberOfTapsRequired:2];
    [self.scrollView addGestureRecognizer:doubleTap];
    
    //carousel setup
    self.carousel.type = iCarouselTypeLinear;
    self.carousel.delegate = self;
    self.carousel.dataSource = self;
    self.carousel.pagingEnabled = YES;
    self.carousel.bounceDistance = 0.3;
    
    if (self.chosenIndex) {
        [self.carousel scrollToItemAtIndex:self.chosenIndex animated:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.carousel;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.pageControl setCurrentPage:self.index];
}

-(void)dismissVC{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe {

    if (self.numberOfPics > self.pageControl.currentPage) {
        //set placeholder spinner view
        MBProgressHUD __block *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.square = YES;
        hud.mode = MBProgressHUDModeCustomView;
        hud.color = [UIColor whiteColor];
        DGActivityIndicatorView __block *spinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
        hud.customView = spinner;
        [spinner startAnimating];
    }
}

- (NSInteger)numberOfItemsInCarousel:(__unused iCarousel *)carousel
{
    if (self.convoMode == YES) {
        return self.convoImagesArray.count;
    }
    else{
        return self.numberOfPics;
    }
}

- (UIView *)carousel:(__unused iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        view = [[PFImageView alloc] initWithFrame:CGRectMake(0, 0, self.carousel.frame.size.width,self.carousel.frame.size.height)];
        view.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    ((PFImageView *)view).image = nil;
    
    if (self.convoMode == YES) {
        PFObject *imageMessage = [self.convoImagesArray objectAtIndex:index];
        PFFile *file = [imageMessage objectForKey:@"Image"];
        [((PFImageView *)view) setFile:file];
    }
    else if (self.messagesPicMode == YES) {
        [((PFImageView *)view)setImage:self.messagePicture];
    }
    else if (self.affiliate == YES){
        [((PFImageView *)view)sd_setImageWithURL:[NSURL URLWithString:[self.listing objectForKey:@"imageURL"]]];
    }
    else{
        if (self.offerMode == YES) {
            [((PFImageView *)view) setFile:[self.listing objectForKey:@"image"]]; //needed?
        }
        else{
            if (index == 0) {
                [((PFImageView *)view)setFile:[self.listing objectForKey:@"image1"]];
            }
            else if (index == 1){
                [((PFImageView *)view)setFile:[self.listing objectForKey:@"image2"]];
            }
            else if (index == 2){
                [((PFImageView *)view)setFile:[self.listing objectForKey:@"image3"]];
            }
            else if (index == 3){
                [((PFImageView *)view)setFile:[self.listing objectForKey:@"image4"]];
            }
            else if (index == 4){
                [((PFImageView *)view)setFile:[self.listing objectForKey:@"image5"]];
            }
            else if (index == 5){
                [((PFImageView *)view)setFile:[self.listing objectForKey:@"image6"]];
            }
        }
    }

    [((PFImageView *)view) loadInBackground];
    
    return view;
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel{
    self.pageControl.currentPage = self.carousel.currentItemIndex;
}

- (NSInteger)numberOfPlaceholdersInCarousel:(__unused iCarousel *)carousel
{
    //note: placeholder views are only displayed on some carousels if wrapping is disabled
    return 0;
}

- (UIView *)carousel:(__unused iCarousel *)carousel placeholderViewAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    if (view == nil)
    {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.carousel.frame.size.width,self.carousel.frame.size.height)];
        view.contentMode = UIViewContentModeCenter;
        view.backgroundColor = [UIColor whiteColor];
    }
    return view;
}
- (IBAction)crossPressed:(id)sender {
    [self.delegate dismissedDetailImageView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value{
    if (option == iCarouselOptionWrap) {
        return NO;
    }
    return 2;
}

#pragma mark - zoom methods

- (void)handleDoubleTapFrom:(UITapGestureRecognizer *)recognizer {
    
    float newScale = [self.scrollView zoomScale] * 4.0;
    
    if (self.scrollView.zoomScale > 1.0)
    {
        [self.scrollView setZoomScale:1.0 animated:YES];
    }
    else
    {
        CGRect zoomRect = [self zoomRectForScale:newScale
                                      withCenter:[recognizer locationInView:recognizer.view]];
        [self.scrollView zoomToRect:zoomRect animated:YES];
    }
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    zoomRect.size.height = [self.scrollView frame].size.height / scale;
    zoomRect.size.width  = [self.scrollView frame].size.width  / scale;
    
    center = [self.scrollView convertPoint:center fromView:self.view];
    
    zoomRect.origin.x    = center.x - ((zoomRect.size.width / 2.0));
    zoomRect.origin.y    = center.y - ((zoomRect.size.height / 2.0));
    
    return zoomRect;
}

@end
