//
//  searchBoostedHeader.m
//  wtbtest
//
//  Created by Jack Ryder on 23/05/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "searchBoostedHeader.h"
#import <ParseUI/ParseUI.h>
#import <Crashlytics/Crashlytics.h>

@implementation searchBoostedHeader

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.boostedListings = [NSArray array];
    self.seenBoosts = [NSMutableArray array];
    
    //setup swipe views
    self.swipeView.delegate = self;
    self.swipeView.dataSource = self;
    self.swipeView.clipsToBounds = YES;
    self.swipeView.pagingEnabled = YES;
    self.swipeView.truncateFinalPage = YES;
    [self.swipeView setBackgroundColor:[UIColor colorWithRed:0.31 green:0.89 blue:0.76 alpha:1.0]];
    [self setBackgroundColor:[UIColor colorWithRed:0.31 green:0.89 blue:0.76 alpha:1.0]];

    self.swipeView.alignment = SwipeViewAlignmentEdge;
}

#pragma mark - swipe view delegates

-(UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view{
    
    UIView *innerView;
    
    if (view == nil)
    {
        
        //create an inner view so can control padding between cells
        
        NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:@"ExploreCell"
                                                          owner:self
                                                        options:nil];
        innerView = (UIView*)[nibViews objectAtIndex:0];
        
        if ([(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"]){
            //iPad (needs to be first as iPad can run in iPhone mode so screen size is same as an iPhones)
            view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 160,210)];
            [innerView setFrame:CGRectMake(0, 0, 140, 210)];
        }
        else if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
            //iphone5
            view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 175,215)];
            [innerView setFrame:CGRectMake(0, 0, 148, 215)];
        }
        else if([ [ UIScreen mainScreen ] bounds ].size.height == 736){
            //iphone 7 plus
            view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 220,285)];
            [innerView setFrame:CGRectMake(0, 0, 196, 285)];

        }
        else if([ [ UIScreen mainScreen ] bounds ].size.height == 480){
            //iphone 4
            view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140,185)];
            [innerView setFrame:CGRectMake(0, 0, 124, 180)];
        }
        else{
            //iPhone 6 specific
            view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 190,254)];
            [innerView setFrame:CGRectMake(0, 0, 175, 254)];
        }
        
        view.backgroundColor = [UIColor clearColor];
        innerView.backgroundColor = [UIColor whiteColor];
        
        //set corner radius
        innerView.layer.cornerRadius = 4;
        innerView.layer.masksToBounds = YES;
        
        [view addSubview:innerView];
        innerView.center = view.center;
        
    }
    else{
        innerView = [[view subviews] lastObject];

    }
    
    ((ExploreCell *)innerView).imageView.image = nil;
    
    //set index so can get this cell for bumping
    ((ExploreCell *)innerView).indexInt = (int)index;
    
    PFObject *listing = [self.boostedListings objectAtIndex:index];
    
    //set the item as seen (only once)
    
    if (![self.seenBoosts containsObject:listing.objectId]) {
        [self.seenBoosts addObject:listing.objectId];
        [listing incrementKey:@"boostViews"];
        [listing saveEventually];
    }
    
    NSArray *bumpArray = [listing objectForKey:@"bumpArray"];
    if ([bumpArray containsObject:[PFUser currentUser].objectId]) {
        //already bumped
        [((ExploreCell *)innerView).bumpButton setSelected:YES];
        
        //set bg colour
        [((ExploreCell *)innerView).transView setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
        ((ExploreCell *)innerView).transView.alpha = 0.9;
    }
    else{
        //haven't bumped
        [((ExploreCell *)innerView).bumpButton setSelected:NO];
        
        //set bg colour
        [((ExploreCell *)innerView).transView setBackgroundColor:[UIColor blackColor]];
        ((ExploreCell *)innerView).transView.alpha = 0.5;
    }
    
    if (bumpArray.count > 0) {
        int count = (int)[bumpArray count];
        [((ExploreCell *)innerView).bumpButton setTitle:[NSString stringWithFormat:@"%@",[self abbreviateNumber:count]] forState:UIControlStateNormal];
    }
    else{
        [((ExploreCell *)innerView).bumpButton setTitle:@" " forState:UIControlStateNormal];
    }
    
    [((ExploreCell *)innerView).imageView setFile:[listing objectForKey:@"image1"]];
    [((ExploreCell *)innerView).imageView loadInBackground];
    
    ((ExploreCell *)innerView).titleLabel.text = [NSString stringWithFormat:@"%@", [listing objectForKey:@"title"]];
    ((ExploreCell *)innerView).priceLabel.text = @"";
    
    if ([listing objectForKey:@"sizeLabel"]) {
        NSString *sizeNoUK = [[listing objectForKey:@"sizeLabel"] stringByReplacingOccurrencesOfString:@"UK" withString:@""];
        sizeNoUK = [sizeNoUK stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if ([sizeNoUK isEqualToString:@"One size"]) {
            ((ExploreCell *)innerView).sizeLabel.text = [NSString stringWithFormat:@"%@", sizeNoUK];
        }
        else if ([sizeNoUK isEqualToString:@"S"]){
            ((ExploreCell *)innerView).sizeLabel.text = @"Small";
        }
        else if ([sizeNoUK isEqualToString:@"M"]){
            ((ExploreCell *)innerView).sizeLabel.text = @"Medium";
        }
        else if ([sizeNoUK isEqualToString:@"L"]){
            ((ExploreCell *)innerView).sizeLabel.text = @"Large";
        }
        else if ([[listing objectForKey:@"category"]isEqualToString:@"Clothing"]){
            ((ExploreCell *)innerView).sizeLabel.text = [NSString stringWithFormat:@"%@", sizeNoUK];
        }
        else{
            ((ExploreCell *)innerView).sizeLabel.text = [NSString stringWithFormat:@"%@", [listing objectForKey:@"sizeLabel"]];
        }
    }
    else{
        ((ExploreCell *)innerView).sizeLabel.text = @"";
    }
    
    PFGeoPoint *location = [listing objectForKey:@"geopoint"];
    if (self.currentLocation && location) {
        int distance = [location distanceInKilometersTo:self.currentLocation];
        if (![listing objectForKey:@"sizeLabel"]) {
            ((ExploreCell *)innerView).sizeLabel.text = [NSString stringWithFormat:@"%dkm", distance];
            ((ExploreCell *)innerView).distanceLabel.text = @"";
        }
        else{
            ((ExploreCell *)innerView).distanceLabel.text = [NSString stringWithFormat:@"%dkm", distance];
        }
    }
    else{
        NSLog(@"no location data %@ %@", self.currentLocation, location);
        ((ExploreCell *)innerView).distanceLabel.text = @"";
    }
    
    //set boost icon
    [((ExploreCell *)innerView).distanceLabel setHidden:YES];
    [((ExploreCell *)innerView).boostImageView setImage:[UIImage imageNamed:@"greenBoost"]];
    
    //delegates
    ((ExploreCell *)innerView).delegate = self;
    
    return view;
}

-(void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index{
    PFObject *listingObject = [self.boostedListings objectAtIndex:index];
    [self.delegate selectedBoostListing:listingObject];
}


-(NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView{
    return self.boostedListings.count;
}

-(NSString *)abbreviateNumber:(int)num {
    
    NSString *abbrevNum;
    float number = (float)num;
    
    //Prevent numbers smaller than 1000 to return NULL
    if (num >= 1000) {
        NSArray *abbrev = @[@"K", @"M", @"B"];
        
        for (int i = (int)abbrev.count - 1; i >= 0; i--) {
            
            // Convert array index to "1000", "1000000", etc
            int size = pow(10,(i+1)*3);
            
            if(size <= number) {
                // Removed the round and dec to make sure small numbers are included like: 1.1K instead of 1K
                number = number/size;
                NSString *numberString = [self floatToString:number];
                
                // Add the letter for the abbreviation
                abbrevNum = [NSString stringWithFormat:@"%@%@", numberString, [abbrev objectAtIndex:i]];
            }
            
        }
    } else {
        
        // Numbers like: 999 returns 999 instead of NULL
        abbrevNum = [NSString stringWithFormat:@"%d", (int)number];
    }
    
    return abbrevNum;
}

- (NSString *) floatToString:(float) val {
    NSString *ret = [NSString stringWithFormat:@"%.1f", val];
    unichar c = [ret characterAtIndex:[ret length] - 1];
    
    while (c == 48) { // 0
        ret = [ret substringToIndex:[ret length] - 1];
        c = [ret characterAtIndex:[ret length] - 1];
        
        //After finding the "." we know that everything left is the decimal number, so get a substring excluding the "."
        if(c == 46) { // .
            ret = [ret substringToIndex:[ret length] - 1];
        }
    }
    
    return ret;
}

#pragma mark - explore cell delegates

-(void)cellTapped:(id)sender{
    
    ExploreCell *cell = sender;
    PFObject *listingObject = [self.boostedListings objectAtIndex:cell.indexInt];
    
    [Answers logCustomEventWithName:@"Bumped a listing"
                   customAttributes:@{
                                      @"where":@"search boost"
                                      }];
    
    NSMutableArray *bumpArray = [NSMutableArray array];
    if ([listingObject objectForKey:@"bumpArray"]) {
        [bumpArray addObjectsFromArray:[listingObject objectForKey:@"bumpArray"]];
    }
    
    NSMutableArray *personalBumpArray = [NSMutableArray array];
    if ([[PFUser currentUser] objectForKey:@"bumpArray"]) {
        [personalBumpArray addObjectsFromArray:[[PFUser currentUser] objectForKey:@"bumpArray"]];
    }
    
    if ([bumpArray containsObject:[PFUser currentUser].objectId]) {
        NSLog(@"already bumped it m8");
        [cell.bumpButton setSelected:NO];
        [cell.transView setBackgroundColor:[UIColor blackColor]];
        cell.transView.alpha = 0.5;
        [bumpArray removeObject:[PFUser currentUser].objectId];
        [listingObject setObject:bumpArray forKey:@"bumpArray"];
        [listingObject incrementKey:@"bumpCount" byAmount:@-1];
        
        if ([personalBumpArray containsObject:listingObject.objectId]) {
            [personalBumpArray removeObject:listingObject.objectId];
        }
        
        //update bump object
        PFQuery *bumpQ = [PFQuery queryWithClassName:@"BumpedListings"];
        [bumpQ whereKey:@"bumpUser" equalTo:[PFUser currentUser]];
        [bumpQ whereKey:@"listing" equalTo:listingObject];
        [bumpQ findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                for (PFObject *bump in objects) {
                    [bump setObject:@"deleted" forKey:@"status"];
                    [bump saveInBackground];
                }
            }
        }];
    }
    else{
        NSLog(@"bumped");
        [cell.bumpButton setSelected:YES];
        [cell.transView setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
        cell.transView.alpha = 0.9;
        [bumpArray addObject:[PFUser currentUser].objectId];
        [listingObject addObject:[PFUser currentUser].objectId forKey:@"bumpArray"];
        [listingObject incrementKey:@"bumpCount"];
        
        if (![personalBumpArray containsObject:listingObject.objectId]) {
            [personalBumpArray addObject:listingObject.objectId];
        }
        
        //send push
        NSString *pushText = [NSString stringWithFormat:@"%@ just liked your listing", [PFUser currentUser].username];
        
        if (![[[listingObject objectForKey:@"postUser"]objectId] isEqualToString:[[PFUser currentUser]objectId]]) {
            NSDictionary *params = @{@"userId": [[listingObject objectForKey:@"postUser"]objectId], @"message": pushText, @"sender": [PFUser currentUser].username, @"bumpValue": @"NO", @"listingID": listingObject.objectId};
            
            [PFCloud callFunctionInBackground:@"sendNewPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                if (!error) {
                    NSLog(@"push response %@", response);
                    [Answers logCustomEventWithName:@"Push Sent"
                                   customAttributes:@{
                                                      @"Type":@"Bump"
                                                      }];
                }
                else{
                    NSLog(@"push error %@", error);
                }
            }];
        }
        else{
            [Answers logCustomEventWithName:@"Bumped own listing"
                           customAttributes:@{
                                              @"where":@"search boost"
                                              }];
        }
        
        PFObject *bumpObj = [PFObject objectWithClassName:@"BumpedListings"];
        [bumpObj setObject:listingObject forKey:@"listing"];
        [bumpObj setObject:[PFUser currentUser] forKey:@"bumpUser"];
        [bumpObj setObject:@"live" forKey:@"status"];
        [bumpObj saveInBackground];
    }
    
    //save listing
    [listingObject saveInBackground];
    [[PFUser currentUser]setObject:personalBumpArray forKey:@"bumpArray"];
    [[PFUser currentUser]saveInBackground];
    
    if (bumpArray.count > 0) {
        int count = (int)[bumpArray count];
        [cell.bumpButton setTitle:[NSString stringWithFormat:@"%@",[self abbreviateNumber:count]] forState:UIControlStateNormal];
    }
    else{
        [cell.bumpButton setTitle:@" " forState:UIControlStateNormal];
    }

}

@end
