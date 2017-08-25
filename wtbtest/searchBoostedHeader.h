//
//  searchBoostedHeader.h
//  wtbtest
//
//  Created by Jack Ryder on 23/05/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SwipeView/SwipeView.h>
#import <Parse/Parse.h>
#import "ExploreCell.h"

@class searchBoostedHeader;

@protocol searchBoostDelegate <NSObject>
- (void)selectedBoostListing:(PFObject *)listing;
@end

@interface searchBoostedHeader : UICollectionReusableView <SwipeViewDelegate, SwipeViewDataSource, ExploreCellDelegate>

//basic setup
@property (weak, nonatomic) IBOutlet SwipeView *swipeView;
@property (nonatomic, strong) NSArray *boostedListings;
@property (nonatomic, strong) NSMutableArray *seenBoosts;

//listings
@property (nonatomic, strong) PFGeoPoint *currentLocation;

//delegate
@property (nonatomic, weak) id <searchBoostDelegate> delegate;

@end
