//
//  ContainerViewController.h
//  wtbtest
//
//  Created by Jack Ryder on 24/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContainerViewController : UIViewController <UIPageViewControllerDataSource>

@property (strong, nonatomic) UIPageViewController *pageController;

@end
