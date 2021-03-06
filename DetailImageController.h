//
//  DetailImageController.h
//  wtbtest
//
//  Created by Jack Ryder on 04/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface DetailImageController : UIViewController


@property (weak, nonatomic) IBOutlet PFImageView *imageView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (assign, nonatomic) NSInteger index;

@property (nonatomic, strong) PFFile *firstImage;
@property (nonatomic, strong) PFFile *secondImage;
@property (nonatomic, strong) PFFile *thirdImage;
@property (nonatomic, strong) PFFile *fourthImage;
@property (nonatomic, strong) PFObject *listing;
@property (nonatomic) int numberOfPics;

@end
