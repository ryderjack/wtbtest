//
//  HomeHeaderView.h
//  wtbtest
//
//  Created by Jack Ryder on 03/04/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMSegmentedControl.h"
#import <iCarousel/iCarousel.h>
#import <ParseUI/ParseUI.h>
#import <Parse/Parse.h>

@class HomeHeaderView;

@protocol HeaderDelegate <NSObject>
- (void)tabHeaderItemSelected:(int)tabNumber;
- (void)webHeaderItemSelected:(NSString *)site;
- (void)searchHeaderSelected;
- (void)ccHeaderSelectedWithLink:(NSString *)link andText: (NSString *)text;

@end

@interface HomeHeaderView : UICollectionReusableView <iCarouselDataSource,iCarouselDelegate>

@property (weak, nonatomic) IBOutlet HMSegmentedControl *headerSegmentControl;
@property (weak, nonatomic) IBOutlet iCarousel *carousel;
@property (nonatomic, strong) NSArray *itemsArray;

//delegate
@property (nonatomic, weak) id <HeaderDelegate> delegate;

//timer
@property (nonatomic, strong) NSTimer *scrollTimer;
@property (nonatomic) BOOL pausedInProgress;


@end
