//
//  ContainerViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 24/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ContainerViewController.h"
#import "Tut1ViewController.h"

@interface ContainerViewController ()

@end

@implementation ContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    [[self.pageController view] setFrame:[[self view] bounds]];
    
    Tut1ViewController *initialViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
    
    self.view.backgroundColor = initialViewController.view.backgroundColor;

    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];
    
    UIPageControl *pageControlAppearance = [UIPageControl appearanceWhenContainedInInstancesOfClasses:@[[UIPageViewController class]]];
    pageControlAppearance.pageIndicatorTintColor = [UIColor colorWithRed:0.05 green:0.54 blue:1.00 alpha:1.0];
    pageControlAppearance.currentPageIndicatorTintColor = [UIColor whiteColor];
    pageControlAppearance.backgroundColor = initialViewController.view.backgroundColor;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(Tut1ViewController *)viewController index];
    
    if (index == 0) {
        return nil;
    }
    
    index--;
    
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(Tut1ViewController *)viewController index];
    
    index++;
    
    if (self.explainMode == YES) {
        if (index == 3) {
            return nil;
        }
    }
    else{
        if (index == 4) {
            return nil;
        }
    }
    
    return [self viewControllerAtIndex:index];
    
}

- (Tut1ViewController *)viewControllerAtIndex:(NSUInteger)index {
    
    Tut1ViewController *childViewController = [[Tut1ViewController alloc] initWithNibName:@"Tut1ViewController" bundle:nil];
    childViewController.index = index;
    if (self.explainMode == YES) {
        childViewController.explainMode = YES;
    }
    return childViewController;
    
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    // The number of items reflected in the page indicator.
    if (self.explainMode == YES) {
        return 3;
    }
    else{
        return 4;
    }
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    // The selected item reflected in the page indicator.
    return 0;
}

@end
