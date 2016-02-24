//
//  Tut1ViewController.h
//  wtbtest
//
//  Created by Jack Ryder on 24/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Tut1ViewController : UIViewController

@property (assign, nonatomic) NSInteger index;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UILabel *mainTitle;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;

@end
