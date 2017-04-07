//
//  UserProfileController.m
//  wtbtest
//
//  Created by Jack Ryder on 26/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "UserProfileController.h"
#import "OfferCell.h"
#import "ListingController.h"
#import <SVPullToRefresh/SVPullToRefresh.h>
#import "CreateForSaleListing.h"
#import "NavigationController.h"
#import "ProfileItemCell.h"
#import "ReviewsVC.h"
#import "ForSaleListing.h"
#import <Crashlytics/Crashlytics.h>
#import "MessageViewController.h"
#import "SquareCashStyleBehaviorDefiner.h"
#import "UIImage+Resize.h"

@interface UserProfileController ()

@end

@implementation UserProfileController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.createButton setHidden:YES];
    [self.actionLabel setHidden:YES];
    
    [self.bumpImageView setHidden:YES];
    [self.bumpLabel setHidden:YES];
    
    self.forSalePressed = NO;
    self.WTBPressed = NO;
    self.numberOfSegments = 0;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];

    // Register cell classes
    [self.collectionView registerClass:[ProfileItemCell class] forCellWithReuseIdentifier:@"Cell"];
    UINib *cellNib = [UINib nibWithNibName:@"ProfileItemCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    //calc screen width to avoid hard coding but bug with collection view so width always = 1000
    
    if ([ [ UIScreen mainScreen ] bounds ].size.width == 375) {
        //iPhone6/7
        [flowLayout setItemSize:CGSizeMake(124,124)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
        //iPhone 6 plus
        [flowLayout setItemSize:CGSizeMake(137, 137)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.width == 320){
        //iPhone 4/5
        [flowLayout setItemSize:CGSizeMake(106, 106)];
    }
    else{
        //fall back
        [flowLayout setItemSize:CGSizeMake(124,124)];
    }
    
    [flowLayout setMinimumInteritemSpacing:1.0];
    [flowLayout setMinimumLineSpacing:1.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.dataSource = self;
    self.collectionView.alwaysBounceVertical = YES;
    
    self.WTBArray = [[NSArray alloc]init];
    self.bumpedArray = [[NSMutableArray alloc]init];
    self.forSaleArray = [[NSMutableArray alloc]init];
    self.bumpedIds = [[NSMutableArray alloc]init];
    
//    NSLog(@"USER %@", self.user);
    
    if (self.tabMode == YES) {
        self.user = [PFUser currentUser];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newTBMessage) name:@"NewTBMessage" object:nil];
    }
    
    if (self.user) { //added in this check as saw a crash when querying a null user
        
        PFQuery *trustedQuery = [PFQuery queryWithClassName:@"trustedSellers"];
        [trustedQuery whereKey:@"user" equalTo:self.user];
        [trustedQuery countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
            if (number >= 1) {
                self.isSeller = YES;
                [self setupTrustedChecks];
            }
            
//            self.isSeller = YES; //CHECK

            //setup edit button here as userimageview didnt seem to have a frame if did it any earlier..
            [self setupEditButton];
            
            //segment control
            self.segmentedControl = [[HMSegmentedControl alloc] init];
            self.segmentedControl.frame = CGRectMake(0, self.myBar.frame.size.height-50,[UIApplication sharedApplication].keyWindow.frame.size.width, 50);
            self.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
            self.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
            self.segmentedControl.selectionIndicatorColor = [UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0];
            self.segmentedControl.titleTextAttributes = @{NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Medium" size:10]};
            self.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]};
            [self.segmentedControl addTarget:self action:@selector(segmentControlChanged) forControlEvents:UIControlEventValueChanged];
            
            BLKFlexibleHeightBarSubviewLayoutAttributes *initialSegAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] init];
            initialSegAttributes.frame = CGRectMake(0, self.myBar.frame.size.height-50,[UIApplication sharedApplication].keyWindow.frame.size.width, 50);
            [self.segmentedControl addLayoutAttributes:initialSegAttributes forProgress:0];
            
            BLKFlexibleHeightBarSubviewLayoutAttributes *finalSegAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialSegAttributes];
            finalSegAttributes.transform = CGAffineTransformMakeTranslation(0, -286);
            [self.segmentedControl addLayoutAttributes:finalSegAttributes forProgress:1.0];
            [self.myBar addSubview:self.segmentedControl];
            
            //setup correct dots button
            if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId] && self.isSeller == YES){
                //same person and a seller
                //show add button
                [self.dotsButton setImage:[UIImage imageNamed:@"plusIconRound"] forState:UIControlStateNormal];
                [self.dotsButton addTarget:self action:@selector(addForSalePressed) forControlEvents:UIControlEventTouchUpInside];
            }
            else{
                //show dots
                [self.dotsButton setImage:[UIImage imageNamed:@"dotsFilled"] forState:UIControlStateNormal];
                [self.dotsButton addTarget:self action:@selector(showAlertView) forControlEvents:UIControlEventTouchUpInside];
            }
            
            if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId] && self.isSeller == YES) {
                //trusted seller so load
                //all 3
                [self.segmentedControl setSectionTitles:@[@"W A N T E D", @"S E L L I N G", @"B U M P E D"]];
                self.numberOfSegments = 3;
                
                [self loadWTBListings];
                [self loadWTSListings];
                
                self.WTBSelected = YES;
                self.WTSSelected = NO;
                self.bumpsSelected = NO;
            }
            else if (self.isSeller == YES) {
                //trusted seller but not looking at own profile
                //WTS and WTB
                [self.segmentedControl setSectionTitles:@[@"W A N T E D", @"S E L L I N G", @"B U M P E D"]];
                self.numberOfSegments = 3;
                if (self.fromSearch == YES || self.saleMode == YES) {
                    [self.segmentedControl setSelectedSegmentIndex:1];
                    
                    self.WTSSelected = YES;
                    self.WTBSelected = NO;
                    self.bumpsSelected = NO;
                }
                else{
                    self.WTSSelected = NO;
                    self.WTBSelected = YES;
                    self.bumpsSelected = NO;
                }
                
                [self loadWTBListings];
                [self loadWTSListings];
            }
            else{
                //user is not a seller
                //just WTB
                [self.segmentedControl setSectionTitles:@[@"W A N T E D", @"B U M P E D"]];
                
                self.WTBSelected = YES;
                self.WTSSelected = NO;
                self.bumpsSelected = NO;
                
                self.numberOfSegments = 2;
                self.wantedMode = YES;
                [self loadWTBListings];
            }
        }];
    }
    
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"User Profile"
                                      }];
    [self setupHeaderBar];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setHidden:YES];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    //check if must show unread icon on cog icon 
    if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId] && self.tabMode == YES) {
        if ([self.navigationController tabBarItem].badgeValue != nil) {
//            NSLog(@"unseen TB msg");
            [self.backButton setImage:[UIImage imageNamed:@"unreadCog"] forState:UIControlStateNormal];
        }
        else{
            [self.backButton setImage:[UIImage imageNamed:@"profileCog"] forState:UIControlStateNormal];
        }
    }
    
    //refresh listings when user taps on profile tab
    if (self.tabMode == YES && self.user) {
        [self loadWTBListings];
        if (self.isSeller == YES) {
            [self loadWTSListings];
        }
    }
    
    //protect against (null) user crash
    if (self.user) {
        [self.user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                [self loadBumpedListings];
                
                PFFile *img = [self.user objectForKey:@"picture"];
                
                self.usernameLabel.text = self.user.username;
                self.middleUsernameLabel.text = self.user.username;
                
                if ([self.user objectForKey:@"profileLocation"]) {
                    
                    //setup correct font weights for main name/loc label
                    NSString *nameString = @"";
                    
                    if ([self.user objectForKey:@"firstName"] && [self.user objectForKey:@"lastName"]) {
                        nameString = [NSString stringWithFormat:@"%@ %@",[self.user objectForKey:@"firstName"],[self.user objectForKey:@"lastName"]];
                    }
                    else{
                        nameString = [self.user objectForKey:@"fullname"];
                    }
                    
                    NSString *locString = [self.user objectForKey:@"profileLocation"];
                    
                    if ([locString containsString:@"null"] || [locString containsString:@"(null)"]) {
                        //if been an error saving the loc then don't display the null
                        NSMutableAttributedString *attString =
                        [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%@",nameString]];
                        
                        
                        [attString addAttribute: NSFontAttributeName
                                          value: [UIFont fontWithName:@"PingFangSC-Medium" size:15]
                                          range: NSMakeRange(0,nameString.length)];
                        
                        self.nameAndLoc.attributedText = attString;
                        self.smallNameAndLoc.text =[NSString stringWithFormat:@"%@",nameString];
                    }
                    else{
                        NSMutableAttributedString *attString =
                        [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%@\n%@",nameString,locString]];
                        
                        
                        [attString addAttribute: NSFontAttributeName
                                          value: [UIFont fontWithName:@"PingFangSC-Medium" size:15]
                                          range: NSMakeRange(0,nameString.length)];
                        
                        
                        [attString addAttribute: NSFontAttributeName
                                          value:  [UIFont fontWithName:@"PingFangSC-Regular" size:15]
                                          range: NSMakeRange(nameString.length+1,locString.length)];
                        
                        self.nameAndLoc.attributedText = attString;
                        self.smallNameAndLoc.text =[NSString stringWithFormat:@"%@\n%@",nameString,locString];
                    }
                }
                else{
                    
                    //setup correct font weights for main name/loc label
                    NSString *nameString = @"";
                    
                    if ([self.user objectForKey:@"firstName"] && [self.user objectForKey:@"lastName"]) {
                        nameString = [NSString stringWithFormat:@"%@ %@",[self.user objectForKey:@"firstName"],[self.user objectForKey:@"lastName"]];
                    }
                    else{
                        nameString = [self.user objectForKey:@"fullname"];
                    }
                    
                    self.nameAndLoc.text = [NSString stringWithFormat:@"%@", nameString];
                    self.smallNameAndLoc.text = [NSString stringWithFormat:@"%@", nameString];
                }
                
                [self.userImageView setFile:img];
                [self.userImageView loadInBackground];
                
                [self.smallImageView setFile:img];
                [self.smallImageView loadInBackground];
            }
            else{
                NSLog(@"couldn't fetch user");
                [self showError];
            }
        }];
        
        PFQuery *dealsQuery = [PFQuery queryWithClassName:@"deals"];
        [dealsQuery whereKey:@"User" equalTo:self.user];
        [dealsQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                int starNumber = [[object objectForKey:@"currentRating"] intValue];
                int total = [[object objectForKey:@"dealsTotal"]intValue];
                
                //            NSLog(@"total %d and star number %d", total, starNumber);
                
                if (total > 0 || self.tabMode == YES) {
                    [self.myBar addSubview:self.starImageView];
                    [self.myBar addSubview:self.reviewsButton];
                    [self.myBar addSubview:self.usernameLabel];
                    self.noDeals = NO;
                    
                    [self.reviewsButton setTitle:[NSString stringWithFormat:@"%d Reviews",total] forState:UIControlStateNormal];
                    if (total == 0 && self.tabMode == YES) {
                        self.noDeals = YES;
                        [self.starImageView setImage:[UIImage imageNamed:@"emptyStars"]];
                        [self.reviewsButton setTitle:@"Earn reputation by chatting on Bump!" forState:UIControlStateNormal];
                    }
                    else if (starNumber == 0) {
                        [self.starImageView setImage:[UIImage imageNamed:@"0star"]];
                    }
                    else if (starNumber == 1){
                        [self.starImageView setImage:[UIImage imageNamed:@"1star"]];
                    }
                    else if (starNumber == 2){
                        [self.starImageView setImage:[UIImage imageNamed:@"2star"]];
                    }
                    else if (starNumber == 3){
                        [self.starImageView setImage:[UIImage imageNamed:@"3star"]];
                    }
                    else if (starNumber == 4){
                        [self.starImageView setImage:[UIImage imageNamed:@"4star"]];
                    }
                    else if (starNumber == 5){
                        [self.starImageView setImage:[UIImage imageNamed:@"5star"]];
                    }
                }
                else{
                    [self.myBar addSubview:self.middleUsernameLabel];
                }
                
                if (![self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
                    // looking at other user's profile
                    NSArray *friends = [[PFUser currentUser] objectForKey:@"friends"];
                    if ([friends containsObject:[self.user objectForKey:@"facebookId"]]) {
                        [self.FBButton setImage:[UIImage imageNamed:@"FbFriends"] forState:UIControlStateNormal];
                    }
                }
            }
            else{
                NSLog(@"error getting deals data!");
                [self.myBar addSubview:self.middleUsernameLabel];
            }
        }];
        
        self.currency = [[PFUser currentUser]objectForKey:@"currency"];
        if ([self.currency isEqualToString:@"GBP"]) {
            self.currencySymbol = @"£";
        }
        else if ([self.currency isEqualToString:@"EUR"]) {
            self.currencySymbol = @"€";
        }
        else if ([self.currency isEqualToString:@"USD"]) {
            self.currencySymbol = @"$";
        }
        
        if (self.forSalePressed == YES && self.numberOfSegments >= 2) {
            [self.segmentedControl setSelectedSegmentIndex:1];
            [self segmentControlChanged];
            [self loadWTSListings];
            
        }
        else if (self.WTBPressed == YES) {
            [self.segmentedControl setSelectedSegmentIndex:0];
            self.WTBPressed = NO;
            [self loadWTBListings];
        }
        else if (self.bumpedPressed == YES) {
            self.bumpedPressed = NO;
            [self loadBumpedListings];
        }
    }
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [imageView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    if (imageView == self.userImageView) {
        [imageView.layer setBorderWidth: 3.5];
    }
    else{
        [imageView.layer setBorderWidth: 1.5];
    }
}

-(void)loadWTBListings{
    
    if (!self.user) {
        return;
    }
    
    PFQuery *wtbQuery = [PFQuery queryWithClassName:@"wantobuys"];
    [wtbQuery whereKey:@"postUser" equalTo:self.user];
    [wtbQuery whereKey:@"status" notEqualTo:@"deleted"];
    [wtbQuery orderByDescending:@"lastUpdated"];
    [wtbQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            //put the sold listings at the end
            NSSortDescriptor *sortDescriptorStatus = [[NSSortDescriptor alloc]
                                                      initWithKey: @"status" ascending: YES];
            NSSortDescriptor *sortDescriptorUpdated = [[NSSortDescriptor alloc] initWithKey:@"lastUpdated" ascending:NO];
            NSArray *sortedArray = [objects sortedArrayUsingDescriptors: [NSArray arrayWithObjects:sortDescriptorStatus,sortDescriptorUpdated,nil]];
            
            self.WTBArray = sortedArray;

            if (objects.count == 0 && self.WTBSelected == YES && self.tabMode == YES) {
                
                if ([(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"])
                {
                    //it's an iPad so hide create button coz can't be seen
                    [self.createButton setHidden:YES];
                    [self.actionLabel setHidden:YES];
                }
                else{
                    [self.createButton setHidden:NO];
                    [self.actionLabel setHidden:NO];
                }
                [self.bumpImageView setHidden:YES];
                [self.bumpLabel setHidden:YES];
            }
            else if (objects.count == 0 && self.WTBSelected == YES && self.tabMode != YES){
                [self.actionLabel setHidden:NO];
                self.actionLabel.text = @"nothing to show";
                
                [self.createButton setHidden:YES];
                [self.bumpImageView setHidden:YES];
                [self.bumpLabel setHidden:YES];
            }
            
            else if (objects.count != 0 && self.WTBSelected == YES) {
                [self.createButton setHidden:YES];
                [self.actionLabel setHidden:YES];
                
                [self.bumpImageView setHidden:YES];
                [self.bumpLabel setHidden:YES];
            }
            
            if (self.WTBSelected == YES) {
                [self.collectionView reloadData];
            }
        }
        else{
            NSLog(@"error getting WTBs %@", error);
        }
    }];
}

-(void)loadBumpedListings{
    NSArray *bumped = [self.user objectForKey:@"bumpArray"];

    PFQuery *bumpedListings = [PFQuery queryWithClassName:@"wantobuys"];
    [bumpedListings whereKey:@"status" notEqualTo:@"deleted"];
    [bumpedListings whereKey:@"objectId" containedIn:bumped];
    [bumpedListings findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            //reset arrays
            [self.bumpedArray removeAllObjects];
            [self.bumpedIds removeAllObjects];
            
            NSLog(@"BUMPS: %ld", objects.count);
            
            //display correct label
            if (self.tabMode == YES && self.bumpsSelected == YES && objects.count == 0) {
                //bump selected on own profile & nothing to show
                [self.createButton setHidden:YES];
                [self.actionLabel setHidden:YES];
                
                if ([ [ UIScreen mainScreen ] bounds ].size.height > 568) {
                    [self.bumpImageView setHidden:NO];
                }
                else{
                    //don't show on iPhone SE as screen isn't big enough
                    [self.bumpImageView setHidden:YES];
                }
                [self.bumpLabel setHidden:NO];
            }
            else if(self.bumpsSelected == YES && objects.count == 0 && self.tabMode != YES){
                [self.actionLabel setHidden:NO];
                self.actionLabel.text = @"nothing to show";
                
                [self.createButton setHidden:YES];
                [self.bumpImageView setHidden:YES];
                [self.bumpLabel setHidden:YES];
            }
            else if (objects.count != 0 && self.bumpsSelected == YES) {
                [self.createButton setHidden:YES];
                [self.actionLabel setHidden:YES];
                
                [self.bumpImageView setHidden:YES];
                [self.bumpLabel setHidden:YES];
            }
            
            if (objects.count == 0) {
                if (self.bumpsSelected == YES) {
                    [self.collectionView performBatchUpdates:^{
                        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
                    } completion:nil];
                }
                return;
            }

            NSMutableArray *placeholderBumps = [NSMutableArray array];

            //check for duplicates
            for (PFObject *WTB in objects) {
                if (![self.bumpedIds containsObject:WTB.objectId]) {
                    [placeholderBumps addObject:WTB];
                    [self.bumpedIds addObject:WTB.objectId];
                }
            }
            
            //order array based on personal bump array
            for (NSString *objectID in bumped) {
                for (PFObject *listing in placeholderBumps) {
                    if ([listing.objectId isEqualToString:objectID]) {
                        [self.bumpedArray addObject:listing];
                        break;
                    }
                }
            }
            
            //reverse order
            NSArray* reversedArray = [[self.bumpedArray reverseObjectEnumerator] allObjects];
            [self.bumpedArray removeAllObjects];
            [self.bumpedArray addObjectsFromArray:reversedArray];
            
            if (self.bumpsSelected == YES) {
                [self.collectionView performBatchUpdates:^{
                    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
                } completion:nil];
            }
            else if (self.bumpsSelected == NO && self.WTBSelected == NO && self.WTSSelected == NO){
                //fail safe reload
                [self.collectionView reloadData];
            }

        }
        else{
            NSLog(@"error getting bumped objects %@", error);
        }
    }];
}

-(void)loadWTSListings{
    
    if (!self.user) {
        return;
    }
    
    PFQuery *wtbQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [wtbQuery whereKey:@"sellerUser" equalTo:self.user];
    [wtbQuery whereKey:@"status" notEqualTo:@"deleted"];
    [wtbQuery orderByDescending:@"lastUpdated"];
    [wtbQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            
            //put the sold listings at the end
            NSSortDescriptor *sortDescriptorStatus = [[NSSortDescriptor alloc]
                                                initWithKey: @"status" ascending: YES];
            NSSortDescriptor *sortDescriptorUpdated = [[NSSortDescriptor alloc] initWithKey:@"lastUpdated" ascending:NO];
            NSArray *sortedArray = [objects sortedArrayUsingDescriptors: [NSArray arrayWithObjects:sortDescriptorStatus,sortDescriptorUpdated,nil]];

            self.forSaleArray = sortedArray;
            
            if (objects.count == 0 && self.WTSSelected == YES && self.tabMode == YES) {
                [self.createButton setHidden:NO];
                [self.actionLabel setHidden:NO];
                
                [self.bumpImageView setHidden:YES];
                [self.bumpLabel setHidden:YES];
            }
            else if (objects.count == 0 && self.WTSSelected == YES && self.tabMode != YES){
                [self.actionLabel setHidden:NO];
                self.actionLabel.text = @"nothing to show";
                
                [self.createButton setHidden:YES];
                [self.bumpImageView setHidden:YES];
                [self.bumpLabel setHidden:YES];
            }
            else if (objects.count != 0 && self.WTSSelected == YES) {
                [self.createButton setHidden:YES];
                [self.actionLabel setHidden:YES];
                
                [self.bumpImageView setHidden:YES];
                [self.bumpLabel setHidden:YES];
            }
            
            if (self.forSalePressed == YES) {
                self.forSalePressed = NO;
            }

            if (self.WTSSelected == YES) {
                NSLog(@"SHOULD RELOAD");
                [self.collectionView performBatchUpdates:^{
                    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
                } completion:nil];
            }
        }
        else{
            NSLog(@"error getting WTSs %@", error);
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.WTSSelected == YES) {
        return self.forSaleArray.count;
    }
    else if (self.WTBSelected == YES){
        return self.WTBArray.count;
    }
    else if (self.bumpsSelected == YES){
        return self.bumpedArray.count;
    }
    else{
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    ProfileItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    [cell.purchasedImageView setHidden:YES];
    cell.itemImageView.image = nil;
    cell.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    PFObject *listingObject;
    
    if (self.WTSSelected == YES) {
        NSLog(@"WTS selected");
        listingObject = [self.forSaleArray objectAtIndex:indexPath.row];
    }
    else if (self.WTBSelected == YES){
        NSLog(@"WTB selected");
        listingObject = [self.WTBArray objectAtIndex:indexPath.row];
    }
    else if (self.bumpsSelected == YES){
        NSLog(@"Bump selected");
        listingObject = [self.bumpedArray objectAtIndex:indexPath.row];
    }
    else{
        listingObject = [self.WTBArray objectAtIndex:indexPath.row];
    }
    
    
    [cell.itemImageView setFile:[listingObject objectForKey:@"image1"]];
    [cell.itemImageView loadInBackground];

    //don't show purchased on bumped listings section
    if ([[listingObject objectForKey:@"status"]isEqualToString:@"purchased"] && self.segmentedControl.selectedSegmentIndex != 1 && self.segmentedControl.selectedSegmentIndex != 2) {
        cell.itemImageView.alpha = 0.5;
        [cell.purchasedImageView setImage:[UIImage imageNamed:@"purchasedIcon"]];
        [cell.purchasedImageView setHidden:NO];
    }
    else if ([[listingObject objectForKey:@"status"]isEqualToString:@"sold"]) {
        cell.itemImageView.alpha = 0.5;
        [cell.purchasedImageView setImage:[UIImage imageNamed:@"soldIcon"]];
        [cell.purchasedImageView setHidden:NO];
    }
    else{
        cell.itemImageView.alpha = 1.0;
        [cell.purchasedImageView setHidden:YES];
    }
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{

    PFObject *selected;
    
    if (self.WTSSelected == YES) {
        NSLog(@"WTS selected");
        selected = [self.forSaleArray objectAtIndex:indexPath.row];
        self.forSalePressed = YES;
        ForSaleListing *vc = [[ForSaleListing alloc]init];
        vc.listingObject = selected;
        vc.fromBuyNow = YES;
        vc.pureWTS = YES; //always pure WTS from a profile
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (self.WTBSelected == YES){
        NSLog(@"WTB selected");
        selected = [self.WTBArray objectAtIndex:indexPath.row];
        self.WTBPressed = YES;
        ListingController *vc = [[ListingController alloc]init];
        vc.listingObject = selected;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (self.bumpsSelected == YES){
        NSLog(@"Bump selected");
        selected = [self.bumpedArray objectAtIndex:indexPath.row];
        self.bumpedPressed = YES;
        ListingController *vc = [[ListingController alloc]init];
        vc.listingObject = selected;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else{
        //fail safe
        selected = [self.WTBArray objectAtIndex:indexPath.row];
        self.WTBPressed = YES;
        ListingController *vc = [[ListingController alloc]init];
        vc.listingObject = selected;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(void)fbPressed{
    NSString *URLString = [NSString stringWithFormat:@"https://facebook.com/%@", [self.user objectForKey:@"facebookId"]];
    self.webView = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
    self.webView.title = @"F A C E B O O K";
    self.webView.showUrlWhileLoading = YES;
    self.webView.showPageTitles = NO;
    self.webView.doneButtonTitle = @"";
    self.webView.payMode = NO;
    self.webView.infoMode = NO;
    self.webView.delegate = self;
    
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.webView];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)cancelWebPressed{
    NSLog(@"cancel pressed");
    [self.webView dismissViewControllerAnimated:YES completion:nil];
}

-(void)screeshotPressed:(UIImage *)screenshot withTaps:(int)taps{
    
}

-(void)cameraPressed{
    
}

-(void)paidPressed{
    
}

-(void)reportUser{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Report" message:@"Bump takes inappropriate behaviour very seriously.\nIf you feel like this user has violated our terms let us know so we can make your experience on Bump as brilliant as possible. Call +447590554897 if you'd like to speak to one of the team immediately or message Team Bump from the Profile Tab within the app." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        PFObject *reportObject = [PFObject objectWithClassName:@"ReportedUsers"];
        reportObject[@"reportedUser"] = self.user;
        reportObject[@"reporter"] = [PFUser currentUser];
        [reportObject saveInBackground];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)SetupListing{
    CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
    vc.usernameToCheck = self.usernameToList;
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    self.forSalePressed = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)addForSalePressed{
    
    if ([[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"]) {
        //sam's upload stock code
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Post as User"
                                              message:@"Enter username"
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
         {
             textField.placeholder = @"username";
         }];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:@"DONE"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       UITextField *usernameField = alertController.textFields.firstObject;
                                       self.usernameToList = usernameField.text;
                                       [self SetupListing];
                                   }];
        
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:YES completion:nil];

    }
    else{
        CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        self.forSalePressed = YES;
        [self presentViewController:nav animated:YES completion:nil];
    }
}

-(void)ReviewsPressed{
    if (self.noDeals == YES) {
        return;
    }
    ReviewsVC *vc = [[ReviewsVC alloc]init];
    vc.user = self.user;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)segmentControlChanged{
    NSLog(@"CHANGED");
    [self.createButton setHidden:YES];
    [self.bumpImageView setHidden:YES];
    [self.bumpLabel setHidden:YES];
    [self.actionLabel setHidden:YES];
    
    //scroll to top before reloading
    if (self.WTBSelected == YES) {
        NSLog(@"wtb selected");
        
        if (self.WTBArray.count != 0) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionTop
                                                animated:NO];
        }
    }
    else if (self.WTSSelected == YES){
        NSLog(@"wts selected");
        
        if (self.forSaleArray.count != 0) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionTop
                                                animated:NO];
        }
    }
    else if (self.bumpsSelected == YES){
        NSLog(@"bump selected");
        
        if (self.bumpedArray.count != 0) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionTop
                                                animated:NO];
        }
    }
    
    if (self.tabMode == YES) {
        //looking at own profile for sure
        
        if (self.wantedMode == YES){
            //just wanted and bumped
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                //wanted
                self.WTBSelected = YES;
                self.WTSSelected = NO;
                self.bumpsSelected = NO;
                
                NSLog(@"selected wanted");
                if (self.WTBArray.count == 0) {
                    [self.createButton setHidden:NO];
                    [self.actionLabel setHidden:NO];
                    
                    [self.bumpImageView setHidden:YES];
                    [self.bumpLabel setHidden:YES];
                }
            }
            else{
                //bumped
                self.WTBSelected = NO;
                self.WTSSelected = NO;
                self.bumpsSelected = YES;
                
                NSLog(@"selected bumped");
                if (self.bumpedArray.count == 0) {
                    [self.createButton setHidden:YES];
                    [self.actionLabel setHidden:YES];
                    
                    if ([ [ UIScreen mainScreen ] bounds ].size.height > 568) {
                        //don't show on iPhone SE as screen isn't big enough
                        [self.bumpImageView setHidden:NO];
                    }
                    [self.bumpLabel setHidden:NO];
                }
            }
        }
        else{
            // all 3
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                //wanted
                self.WTBSelected = YES;
                self.WTSSelected = NO;
                self.bumpsSelected = NO;
                
                if (self.WTBArray.count == 0) {
                    [self.createButton setHidden:NO];
                    [self.actionLabel setHidden:NO];
                    
                    [self.bumpImageView setHidden:YES];
                    [self.bumpLabel setHidden:YES];
                }
                
            }
            else if (self.segmentedControl.selectedSegmentIndex == 1) {
                //selling
                NSLog(@"SELLING");
                self.WTBSelected = NO;
                self.WTSSelected = YES;
                self.bumpsSelected = NO;
                
                if (self.forSaleArray.count == 0) {
                    [self.createButton setHidden:NO];
                    [self.actionLabel setHidden:NO];
                    
                    [self.bumpImageView setHidden:YES];
                    [self.bumpLabel setHidden:YES];
                }
            }
            else{
                //bumped
                self.WTBSelected = NO;
                self.WTSSelected = NO;
                self.bumpsSelected = YES;
                
                NSLog(@"selected bumped");
                if (self.bumpedArray.count == 0) {
                    [self.createButton setHidden:YES];
                    [self.actionLabel setHidden:YES];
                    
                    if ([ [ UIScreen mainScreen ] bounds ].size.height > 568) {
                        //don't show on iPhone SE as screen isn't big enough
                        [self.bumpImageView setHidden:NO];
                    }
                    [self.bumpLabel setHidden:NO];
                }
            }
        }
    }
    else{
        if (self.wantedMode == YES){
            //just wanted and bumped
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                //wanted
                self.WTBSelected = YES;
                self.WTSSelected = NO;
                self.bumpsSelected = NO;
                
                if (self.WTBArray.count == 0) {
                    [self.actionLabel setHidden:NO];
                    self.actionLabel.text = @"nothing to show";
                    
                    [self.createButton setHidden:YES];
                    [self.bumpImageView setHidden:YES];
                    [self.bumpLabel setHidden:YES];
                }
            }
            else{
                //bumped
                self.WTBSelected = NO;
                self.WTSSelected = NO;
                self.bumpsSelected = YES;
                
                if (self.bumpedArray.count == 0) {
                    [self.actionLabel setHidden:NO];
                    self.actionLabel.text = @"nothing to show";
                    
                    [self.createButton setHidden:YES];
                    [self.bumpImageView setHidden:YES];
                    [self.bumpLabel setHidden:YES];
                }
            }
        }
        else{
            // all 3
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                //wanted
                self.WTBSelected = YES;
                self.WTSSelected = NO;
                self.bumpsSelected = NO;
                
                if (self.WTBArray.count == 0) {
                    [self.actionLabel setHidden:NO];
                    self.actionLabel.text = @"nothing to show";
                    
                    [self.createButton setHidden:YES];
                    [self.bumpImageView setHidden:YES];
                    [self.bumpLabel setHidden:YES];
                }
                
            }
            else if (self.segmentedControl.selectedSegmentIndex == 1) {
                //selling
                self.WTBSelected = NO;
                self.WTSSelected = YES;
                self.bumpsSelected = NO;
                
                if (self.forSaleArray.count == 0) {
                    [self.actionLabel setHidden:NO];
                    self.actionLabel.text = @"nothing to show";
                    
                    [self.createButton setHidden:YES];
                    [self.bumpImageView setHidden:YES];
                    [self.bumpLabel setHidden:YES];
                }
            }
            else{
                //bumped
                self.WTBSelected = NO;
                self.WTSSelected = NO;
                self.bumpsSelected = YES;
                
                NSLog(@"selected bumped");
                if (self.bumpedArray.count == 0) {
                    [self.actionLabel setHidden:NO];
                    self.actionLabel.text = @"nothing to show";
                    
                    [self.createButton setHidden:YES];
                    [self.bumpImageView setHidden:YES];
                    [self.bumpLabel setHidden:YES];
                }
            }
        }

    }

    [self.collectionView reloadData];
}

-(void)dismissVC{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)showError{
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Error Fetching User"
                                  message:@"Make sure you're connected to the internet!"
                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)showAlertView{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    if (![self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Message" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self setupMessages];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
            [self reportUser];
        }]];
    }
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)setupMessages{
    [self showHUD];
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"convos"];
    
    //possible convoIDs
    NSString *possID = [NSString stringWithFormat:@"%@%@", [PFUser currentUser].objectId, self.user.objectId];
    NSString *otherId = [NSString stringWithFormat:@"%@%@",self.user.objectId,[PFUser currentUser].objectId];
    
    NSArray *idArray = [NSArray arrayWithObjects:possID,otherId, nil];
    
    [convoQuery whereKey:@"convoId" containedIn:idArray];
    [convoQuery includeKey:@"buyerUser"];
    [convoQuery includeKey:@"sellerUser"];
    
    [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //convo exists, goto that one but pretype a message like "I'm interested in your Supreme bogo" etc.
            MessageViewController *vc = [[MessageViewController alloc]init];
            vc.convoId = [object objectForKey:@"convoId"];
            vc.convoObject = object;
            vc.otherUser = self.user;
            
            if ([[[object objectForKey:@"sellerUser"]objectId] isEqualToString:self.user.objectId]) {
                vc.userIsBuyer = YES;
            }
            else{
                vc.userIsBuyer = NO;
            }
            vc.otherUserName = self.user.username;
            vc.pureWTS = YES;
            vc.profileConvo = YES;

            [self hideHUD];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            //create a new convo and goto it
            PFObject *convoObject = [PFObject objectWithClassName:@"convos"];
            convoObject[@"sellerUser"] = [PFUser currentUser];
            convoObject[@"buyerUser"] = self.user;
            convoObject[@"convoId"] = [NSString stringWithFormat:@"%@%@", [PFUser currentUser].objectId, self.user.objectId];
            convoObject[@"profileConvo"] = @"YES";
            convoObject[@"totalMessages"] = @0;
            convoObject[@"buyerUnseen"] = @0;
            convoObject[@"sellerUnseen"] = @0;
            convoObject[@"source"] = @"profile";
            
            [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    NSLog(@"saved new convo");
                    //saved
                    MessageViewController *vc = [[MessageViewController alloc]init];
                    vc.convoId = [convoObject objectForKey:@"convoId"];
                    vc.convoObject = convoObject;
                    vc.otherUser = self.user;
                    vc.otherUserName = self.user.username;
                    vc.userIsBuyer = NO;
                    vc.pureWTS = YES;
                    vc.profileConvo = YES;

                    [self hideHUD];
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else{
                    NSLog(@"error saving convo in profile");
                }
            }];
        }
    }];
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
}

-(void)backPressed{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)setupHeaderBar{
    self.myBar = [[BLKFlexibleHeightBar alloc] initWithFrame:CGRectMake(0.0, 0.0, [UIApplication sharedApplication].keyWindow.frame.size.width, 400.0)];
    self.myBar.minimumBarHeight = 114.0;
    
    self.myBar.backgroundColor = [UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0];
    self.myBar.behaviorDefiner = [SquareCashStyleBehaviorDefiner new];
    
    //create a splitter so collection view can respond to its own delegate methods AND flexibar can copy the CV's scroll view
    self.splitter = [[BLKDelegateSplitter alloc] initWithFirstDelegate:self secondDelegate:self.myBar.behaviorDefiner];
    
    self.collectionView.delegate = (id<UICollectionViewDelegate>)self.splitter;
    self.collectionView.contentInset = UIEdgeInsetsMake(self.myBar.maximumBarHeight, 0.0, 0.0, 0.0);
    
    // big mode setup
    
    //profile image
    self.userImageView = [[PFImageView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
    [self.userImageView setBackgroundColor:[UIColor lightGrayColor]];
    [self setImageBorder:self.userImageView];
    [self.myBar addSubview:self.userImageView];
    
    //name & location
    self.nameAndLoc = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
    self.nameAndLoc.numberOfLines = 2;
    self.nameAndLoc.textColor = [UIColor whiteColor];
    self.nameAndLoc.textAlignment = NSTextAlignmentCenter;
    //[self.nameAndLoc sizeToFit];
    [self.myBar addSubview:self.nameAndLoc];
    
    //top username
    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
    self.usernameLabel.numberOfLines = 1;
    self.usernameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:15];
    self.usernameLabel.textColor = [UIColor whiteColor];
    self.usernameLabel.textAlignment = NSTextAlignmentCenter;
    //[self.myBar addSubview:self.usernameLabel];
    
    //middle username
    self.middleUsernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
    self.middleUsernameLabel.numberOfLines = 1;
    self.middleUsernameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:15];
    self.middleUsernameLabel.textColor = [UIColor whiteColor];
    self.middleUsernameLabel.textAlignment = NSTextAlignmentCenter;
   // [self.myBar addSubview:self.middleUsernameLabel];
    
    //nav bar buttons
    
    //back button
    self.backButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId] && self.tabMode == YES) {
        [self.backButton setImage:[UIImage imageNamed:@"profileCog"] forState:UIControlStateNormal];
        [self.backButton addTarget:self action:@selector(profileCogPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    else{
        [self.backButton setImage:[UIImage imageNamed:@"backArrowThin"] forState:UIControlStateNormal];
        [self.backButton addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];

    }
    [self.myBar addSubview:self.backButton];
    
    //facebook button
    self.FBButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.FBButton setImage:[UIImage imageNamed:@"facebookProfileFilled"] forState:UIControlStateNormal];
    [self.FBButton addTarget:self action:@selector(fbPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.myBar addSubview:self.FBButton];
    
    //dots button
    self.dotsButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.myBar addSubview:self.dotsButton];
    
    //stars image view
    self.starImageView = [[PFImageView alloc]initWithFrame:CGRectMake(0, 0, 140, 25)];
    //[self.myBar addSubview:self.starImageView];

    //reviews label
    self.reviewsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 300, 30)];
    self.reviewsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.reviewsButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:10];
    [self.reviewsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.reviewsButton addTarget:self action:@selector(ReviewsPressed) forControlEvents:UIControlEventTouchUpInside];
    //[self.myBar addSubview:self.reviewsLabel];
    
    //////////
    //views for when bar collapses
    
    //small imageview
    self.smallImageView = [[PFImageView alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.smallImageView setBackgroundColor:[UIColor lightGrayColor]];
    [self setImageBorder:self.smallImageView];
    [self.myBar addSubview:self.smallImageView];
    
    //small name / loc label
    self.smallNameAndLoc = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    self.smallNameAndLoc.numberOfLines = 2;
    self.smallNameAndLoc.font = [UIFont fontWithName:@"PingFangSC-Medium" size:10];
    self.smallNameAndLoc.textColor = [UIColor whiteColor];
    self.smallNameAndLoc.textAlignment = NSTextAlignmentLeft;
    [self.myBar addSubview:self.smallNameAndLoc];
    
    [self.view addSubview:self.myBar];
    
    //small image view
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesSmallImage = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesSmallImage.size = self.smallImageView.frame.size;
    initialLayoutAttributesSmallImage.frame = CGRectMake(55, 25, 30, 30);
    initialLayoutAttributesSmallImage.alpha = 0.0f;
    [self.smallImageView addLayoutAttributes:initialLayoutAttributesSmallImage forProgress:0.0];
    
    //small username /loc view
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesSmallName = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesSmallName.size = self.smallNameAndLoc.frame.size;
    initialLayoutAttributesSmallName.frame = CGRectMake(90, 25, 200, 30);
    initialLayoutAttributesSmallName.alpha = 0.0f;
    [self.smallNameAndLoc addLayoutAttributes:initialLayoutAttributesSmallName forProgress:0.0];
    
    //image view
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributes = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributes.size = self.userImageView.frame.size;
    initialLayoutAttributes.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)-15.0);
    
    //name & loc label
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesLabel = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesLabel.size = self.nameAndLoc.frame.size;
    initialLayoutAttributesLabel.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)-120.0);
    
    //top username label
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesUsernameLabel = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesUsernameLabel.size = self.usernameLabel.frame.size;
    initialLayoutAttributesUsernameLabel.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)+60.0);

    
    //middle username label
    BLKFlexibleHeightBarSubviewLayoutAttributes *middleInitial = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    middleInitial.size = self.middleUsernameLabel.frame.size;
    middleInitial.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)+85.0);
    
    //stars view
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesStarView = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesStarView.size = self.starImageView.frame.size;
    initialLayoutAttributesStarView.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)+95.0);
    
    //reviews label
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesReviews = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesReviews.size = self.reviewsButton.frame.size;
    initialLayoutAttributesReviews.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)+120.0);
    
    //back button
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesBackButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesBackButton.size = self.backButton.frame.size;
    initialLayoutAttributesBackButton.frame = CGRectMake(5, 25, 30, 30);
    
    //fb button
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesfbButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesfbButton.size = self.FBButton.frame.size;
    initialLayoutAttributesfbButton.frame = CGRectMake([UIApplication sharedApplication].keyWindow.frame.size.width-85, 25, 30, 30);
    
    //dots button
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesDotsButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesDotsButton.size = self.dotsButton.frame.size;
    initialLayoutAttributesDotsButton.frame = CGRectMake([UIApplication sharedApplication].keyWindow.frame.size.width-40, 25, 30, 30);
    
    // This is what we want the bar to look like at its maximum height (progress == 0.0)
    [self.userImageView addLayoutAttributes:initialLayoutAttributes forProgress:0.0];
    [self.nameAndLoc addLayoutAttributes:initialLayoutAttributesLabel forProgress:0.0];
    [self.usernameLabel addLayoutAttributes:initialLayoutAttributesUsernameLabel forProgress:0.0];
    
    [self.middleUsernameLabel addLayoutAttributes:middleInitial forProgress:0.0];
    [self.starImageView addLayoutAttributes:initialLayoutAttributesStarView forProgress:0.0];
    [self.reviewsButton addLayoutAttributes:initialLayoutAttributesReviews forProgress:0.0];
    [self.backButton addLayoutAttributes:initialLayoutAttributesBackButton forProgress:0.0];
    [self.FBButton addLayoutAttributes:initialLayoutAttributesfbButton forProgress:0.0];
    [self.dotsButton addLayoutAttributes:initialLayoutAttributesDotsButton forProgress:0.0];
    
    // small mode
    
    // image view final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributes];
    finalLayoutAttributes.alpha = 0.0;
    //CGAffineTransform translation = CGAffineTransformMakeTranslation(0.0, -30.0);
    //CGAffineTransform scale = CGAffineTransformMakeScale(0.2, 0.2);
    //finalLayoutAttributes.transform = CGAffineTransformConcat(scale, translation);
    // This is what we want the bar to look like at its minimum height (progress == 1.0)
    [self.userImageView addLayoutAttributes:finalLayoutAttributes forProgress:0.4];
    
    // top username final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesUsername = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesUsernameLabel];
    finalLayoutAttributesUsername.alpha = 0.0;
    [self.usernameLabel addLayoutAttributes:finalLayoutAttributesUsername forProgress:0.2];
    
    // middle username final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutMiddleUsername = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:middleInitial];
    finalLayoutMiddleUsername.alpha = 0.0;
    [self.middleUsernameLabel addLayoutAttributes:finalLayoutMiddleUsername forProgress:0.2];
    
    // star view final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesStar = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesStarView];
    finalLayoutAttributesStar.alpha = 0.0;
    [self.starImageView addLayoutAttributes:finalLayoutAttributesStar forProgress:0.1];
    
    // reviews label final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesReviewLabel = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesReviews];
    finalLayoutAttributesReviewLabel.alpha = 0.0;
    [self.reviewsButton addLayoutAttributes:finalLayoutAttributesReviewLabel forProgress:0.1];
    
    // name label final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesNameLabel = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesLabel];
    finalLayoutAttributesNameLabel.alpha = 0.0;
    [self.nameAndLoc addLayoutAttributes:finalLayoutAttributesNameLabel forProgress:0.9];
    
    // small username label final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesSmallLabel = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesSmallName];
    finalLayoutAttributesSmallLabel.alpha = 1.0;
    [self.smallNameAndLoc addLayoutAttributes:finalLayoutAttributesSmallLabel forProgress:0.9];
    
    // small image final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesSmallImage = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesSmallImage];
    finalLayoutAttributesSmallImage.alpha = 1.0;
    [self.smallImageView addLayoutAttributes:finalLayoutAttributesSmallImage forProgress:0.9];
    
    if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
        //profile image button
        self.imageButton = [[UIButton alloc]initWithFrame:self.userImageView.frame];
        [self.imageButton addTarget:self action:@selector(profileImagePressed) forControlEvents:UIControlEventTouchUpInside];
        [self.myBar addSubview:self.imageButton];
        
        //image view button
        BLKFlexibleHeightBarSubviewLayoutAttributes *initialImageButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
        initialImageButton.size = self.userImageView.frame.size;
        initialImageButton.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)-15.0);
        [self.imageButton addLayoutAttributes:initialImageButton forProgress:0.0];
        
        // image button final
        BLKFlexibleHeightBarSubviewLayoutAttributes *finalImageButtonAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialImageButton];
        finalImageButtonAttributes.alpha = 0.0;
        [self.imageButton addLayoutAttributes:finalImageButtonAttributes forProgress:0.4];
    }
}

-(void)setupTrustedChecks{
    UIImageView *checkView = [[UIImageView alloc]initWithFrame:CGRectMake(0,0, 30, 30)];
    [checkView setImage:[UIImage imageNamed:@"trusted30"]];
    [self.myBar addSubview:checkView];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *checkAttributes = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    checkAttributes.size = checkView.frame.size;
    checkAttributes.frame = CGRectMake(self.userImageView.frame.origin.x, self.userImageView.frame.origin.y+70, 30, 30);
    [checkView addLayoutAttributes:checkAttributes forProgress:0.0];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalCheckAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:checkAttributes];
    finalCheckAttributes.alpha = 0.0;
    [checkView addLayoutAttributes:finalCheckAttributes forProgress:0.4];
    
    //setup smaller checkview
    UIImageView *checkImageViewSmall = [[UIImageView alloc]initWithFrame:CGRectMake(0,0, 15, 15)];
    [checkImageViewSmall setImage:[UIImage imageNamed:@"trusted30"]];
    [self.myBar addSubview:checkImageViewSmall];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *checkSmallAttributes = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    checkSmallAttributes.size = checkImageViewSmall.frame.size;
    checkSmallAttributes.frame = CGRectMake(self.smallImageView.frame.origin.x, self.smallImageView.frame.origin.y+15, 15, 15);
    checkSmallAttributes.alpha = 0.0;
    [checkImageViewSmall addLayoutAttributes:checkSmallAttributes forProgress:0.0];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalSmallCheckAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:checkSmallAttributes];
    finalSmallCheckAttributes.alpha = 1.0;
    [checkImageViewSmall addLayoutAttributes:finalSmallCheckAttributes forProgress:0.9];
}

-(void)profileImagePressed{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Choose picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (!self.picker) {
            self.picker = [[UIImagePickerController alloc] init];
            self.picker.delegate = self;
            self.picker.allowsEditing = NO;
            self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        [self presentViewController:self.picker animated:YES completion:nil];
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    self.profileImage = info[UIImagePickerControllerOriginalImage];
    [self showHUD];
//    UIImage *imageToSave = [self.profileImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(750.0, 750.0) interpolationQuality:kCGInterpolationHigh];
    UIImage *imageToSave = [self.profileImage scaleImageToSize:CGSizeMake(750, 750)];

    NSData* data = UIImageJPEGRepresentation(imageToSave, 0.7f);
    if (data == nil) {
        NSLog(@"error with data");
        [self hideHUD];
        [picker dismissViewControllerAnimated:YES completion:nil];
        [self showAlertWithTitle:@"Image Error" andMsg:@"Woops, something went wrong. Please try again! If this keeps happening please message Team Bump from your profile"];
        [Answers logCustomEventWithName:@"PFFile Nil Data"
                       customAttributes:@{
                                          @"pageName":@"Profile"
                                          }];
    }
    else{
        PFFile *filePicture = [PFFile fileWithName:@"picture.jpg" data:data];
        [filePicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                [self.userImageView setFile:filePicture];
                [self.userImageView loadInBackground];
                
                [PFUser currentUser][@"picture"] = filePicture;
                [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        NSLog(@"saved!");
                        [self hideHUD];
                    }
                    else{
                        NSLog(@"error saving %@", error);
                        [self hideHUD];
                    }
                }];
            }
            else{
                NSLog(@"error saving file %@", error);
                [self hideHUD];
            }
        }];
        [picker dismissViewControllerAnimated:YES completion:nil];
    }

}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)setupEditButton{
    if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
        
        //setup the actual edit button
        self.editImageView = [[PFImageView alloc]initWithFrame:CGRectMake(0,0, 30, 30)];
        [self.editImageView setImage:[UIImage imageNamed:@"editButton"]];
        [self.myBar addSubview:self.editImageView];
        
        BLKFlexibleHeightBarSubviewLayoutAttributes *editAttributes = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
        editAttributes.size = self.editImageView.frame.size;
        editAttributes.frame = CGRectMake(self.userImageView.frame.origin.x+70,self.userImageView.frame.origin.y+70, 30, 30);
        [self.editImageView addLayoutAttributes:editAttributes forProgress:0.0];
        
        BLKFlexibleHeightBarSubviewLayoutAttributes *finalEditAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:editAttributes];
        finalEditAttributes.alpha = 0.0;
        [self.editImageView addLayoutAttributes:finalEditAttributes forProgress:0.4];
    }
}

-(void)profileCogPressed{
    ProfileController *profile = [[ProfileController alloc]init];
    profile.modal = YES;
    profile.delegate = self;
    
    if (self.messagesUnseen > 0) {
        profile.unseenTBMsg = YES;
    }
    if (self.showSnap == YES) {
        profile.showSnapDot = YES;
        self.showSnap = NO;
    }
    
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:profile];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)newTBMessage{
    [self.backButton setImage:[UIImage imageNamed:@"unreadCog"] forState:UIControlStateNormal];
}

-(void)TeamBumpInboxTapped{
    [self.backButton setImage:[UIImage imageNamed:@"profileCog"] forState:UIControlStateNormal];
    [[self.tabBarController.tabBar.items objectAtIndex:4] setBadgeValue:nil];
}

-(void)snapSeen{
    UITabBarItem *itemToBadge = self.tabBarController.tabBar.items[4];
    int currentTabValue = [itemToBadge.badgeValue intValue];
    
    if (currentTabValue > 1) {
        //minus one, still have some TB messages unseen
        int newTabValue = currentTabValue + 1;
        itemToBadge.badgeValue = [NSString stringWithFormat:@"%d", newTabValue];
    }
    else{
        //reset to nil
        [[self.tabBarController.tabBar.items objectAtIndex:4] setBadgeValue:nil];
    }
}
- (IBAction)createPressed:(id)sender {
    if (self.segmentedControl.selectedSegmentIndex == 0){
        self.tabBarController.selectedIndex = 2;
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1){
        CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
        vc.usernameToCheck = self.usernameToList;
        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        self.forSalePressed = YES;
        [self presentViewController:nav animated:YES completion:nil];
    }
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}


@end
