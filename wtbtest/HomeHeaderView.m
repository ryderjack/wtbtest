//
//  HomeHeaderView.m
//  wtbtest
//
//  Created by Jack Ryder on 03/04/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "HomeHeaderView.h"
#import <Crashlytics/Crashlytics.h>

@implementation HomeHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    //carousel setup
    self.carousel.type = iCarouselTypeLinear;
    self.carousel.delegate = self;
    self.carousel.dataSource = self;
    self.carousel.pagingEnabled = YES;
    self.carousel.bounceDistance = 0.3;
    
    [self scheduleTimer];
}


#pragma mark - carousel delegates

- (NSInteger)numberOfItemsInCarousel:(__unused iCarousel *)carousel
{
    return self.itemsArray.count;
}

- (UIView *)carousel:(__unused iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        view = [[PFImageView alloc] initWithFrame:CGRectMake(0, 0, self.carousel.frame.size.width,self.carousel.frame.size.height)];
        view.contentMode = UIViewContentModeScaleAspectFill;
        view.clipsToBounds = YES; //<- essential for aspect fill, stops image spilling over
    }
    
    //reset image
    ((PFImageView *)view).image = nil;

    PFObject *homeItem = [self.itemsArray objectAtIndex:index];
    [((PFImageView *)view)setFile:[homeItem objectForKey:@"imageFile"]];
    [((PFImageView *)view) loadInBackground];
    
    return view;
}

-(CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value{
    if (option == iCarouselOptionWrap) {
        return YES;
    }
    return value;
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index{
    
    PFObject *selectedItem = [self.itemsArray objectAtIndex:index];
    NSString *type = [selectedItem objectForKey:@"type"];
    
    if ([type isEqualToString:@"snapchat"]) {
        //take to snapchat
        [Answers logCustomEventWithName:@"Header Tapped"
                       customAttributes:@{
                                          @"type":@"Snapchat"
                                          }];
        NSURL *whatsappURL = [NSURL URLWithString:@"snapchat://add/teambump"];
        if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
            [[UIApplication sharedApplication] openURL: whatsappURL];
        }
    }
    else if ([type isEqualToString:@"search"]) {
        [self.delegate searchHeaderSelected];
    }
    else if ([type isEqualToString:@"nothing"]) {
        NSString *name = [selectedItem objectForKey:@"name"];
        
        [Answers logCustomEventWithName:@"Header Tapped"
                       customAttributes:@{
                                          @"type":@"nothing",
                                          @"name":name
                                          }];
        //do nothing
    }
    else if ([type isEqualToString:@"tab"]) {
        NSArray *infoArray = [selectedItem objectForKey:@"info"];
        int tabNumber = [infoArray[0] intValue];
        [self.delegate tabHeaderItemSelected:tabNumber];
        
    }
    else if ([type isEqualToString:@"web"]) {
        NSArray *infoArray = [selectedItem objectForKey:@"info"];
        NSString *site = infoArray[0];
        [self.delegate webHeaderItemSelected:site];
    }
//    else if ([type isEqualToString:@"blog"]) {
//
//       //TBC
//    }
}

-(void)pauseTimer{
    if (self.pausedInProgress == YES) {
        return;
    }
    self.pausedInProgress = YES;

    [self.scrollTimer invalidate];
    self.scrollTimer = nil;


    self.pausedInProgress = NO;
}

-(void)scheduleTimer{

    [self.scrollTimer invalidate];
     self.scrollTimer = nil;

    self.scrollTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                        target:self
                                                      selector:@selector(scrollPlease)
                                                      userInfo:nil
                                                       repeats:YES];
}

-(void)scrollPlease{
    [self.carousel scrollToItemAtIndex:self.carousel.currentItemIndex+1 animated:YES];
}


-(void)carouselWillBeginDragging:(iCarousel *)carousel{
    [self pauseTimer];
}

-(void)carouselDidEndScrollingAnimation:(iCarousel *)carousel{
    [self scheduleTimer];
}
@end
