//
//  CustomCopyActivity.m
//  wtbtest
//
//  Created by Jack Ryder on 06/04/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import "CustomCopyActivity.h"

@implementation CustomCopyActivity

- (NSString *)activityType
{
    return @"bump.copy.link";
}

- (NSString *)activityTitle
{
    return @"Copy Link";
}

- (UIImage *)activityImage
{
    // Note: These images need to have a transparent background and I recommend these sizes:
    // iPadShare@2x should be 126 px, iPadShare should be 53 px, iPhoneShare@2x should be 100
    // px, and iPhoneShare should be 50 px. I found these sizes to work for what I was making.
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        return [UIImage imageNamed:@"iPadShare.png"];
    }
    else
    {
        return [UIImage imageNamed:@"iPhoneShare.png"];
    }
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    NSLog(@"%s", __FUNCTION__);
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    NSLog(@"%s",__FUNCTION__);
}

- (UIViewController *)activityViewController
{
    NSLog(@"%s",__FUNCTION__);
    return nil;
}

- (void)performActivity
{
    // This is where you can do anything you want, and is the whole reason for creating a custom
    [self.delegate copiedLinkPressed];
    
    // UIActivity
    [self activityDidFinish:YES];
}

@end
