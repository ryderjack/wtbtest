//
//  UserProfileController.m
//  wtbtest
//
//  Created by Jack Ryder on 26/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "UserProfileController.h"
#import "CreateForSaleListing.h"
#import "NavigationController.h"
#import "ProfileItemCell.h"
#import "ReviewsVC.h"
#import <Crashlytics/Crashlytics.h>
#import "MessageViewController.h"
#import "SquareCashStyleBehaviorDefiner.h"
#import "UIImage+Resize.h"
#import "mainApprovedSellerController.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "ChatWithBump.h"
#import "SettingsController.h"
#import "UIImageView+Letters.h"
#import "AppDelegate.h"
#import "segmentedTableView.h"
#import <Intercom/Intercom.h>
#import "whoBumpedTableView.h"
#import "Mixpanel/Mixpanel.h"
#import "Branch.h"

@interface UserProfileController ()

@end

@implementation UserProfileController

typedef void(^myCompletion)(BOOL);

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.createButton setHidden:YES];
    [self.actionLabel setHidden:YES];
    
    [self.filterButton setHidden:YES];
    
    //filter setup
    self.filtersArray = [NSMutableArray array];
    self.filterSizesArray = [NSMutableArray array];
    self.filterBrandsArray = [NSMutableArray array];
    self.filterColoursArray = [NSMutableArray array];
    self.filterContinentsArray = [NSMutableArray array];
    
    self.lastSelected = [[NSIndexPath alloc]init];
    
    self.actionLabel.adjustsFontSizeToFitWidth = YES;
    self.actionLabel.minimumScaleFactor=0.5;
    
    [self.bumpImageView setHidden:YES];
    [self.bumpLabel setHidden:YES];
    
    self.forSalePressed = NO;
    self.WTBPressed = NO;
    self.numberOfSegments = 0;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    self.refreshControl = [[UIRefreshControl alloc]init];
    self.refreshControl.backgroundColor = [UIColor clearColor];
    self.refreshControl.tintColor = [UIColor lightGrayColor];
    [self.refreshControl addTarget:self action:@selector(refreshUser) forControlEvents:UIControlEventAllEvents];
    
    //implement pull to refresh
    if (@available(iOS 10.0, *)) {
        self.collectionView.refreshControl = self.refreshControl;
        
    }
    else{
        [self.collectionView addSubview:self.refreshControl];
    }

    // Register cell classes
    [self.collectionView registerClass:[ProfileItemCell class] forCellWithReuseIdentifier:@"Cell"];
    UINib *cellNib = [UINib nibWithNibName:@"ProfileItemCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    //calc screen width to avoid hard coding but bug with collection view so width always = 1000
    
    if ([ [ UIScreen mainScreen ] bounds ].size.width == 375) {
        //iPhone6/7
        [flowLayout setItemSize:CGSizeMake(124,124)];
        self.cellHeight = 124;
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
        //iPhone 6 plus
        [flowLayout setItemSize:CGSizeMake(137, 137)];
        self.cellHeight = 137;
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.width == 320){
        //iPhone 4/5
        self.smallScreen = YES;
        [flowLayout setItemSize:CGSizeMake(106, 106)];
        self.cellHeight = 106;
    }
    else{
        //fall back
        [flowLayout setItemSize:CGSizeMake(124,124)];
        self.cellHeight = 124;
    }
    
    [flowLayout setMinimumInteritemSpacing:1.0];
    [flowLayout setMinimumLineSpacing:1.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.dataSource = self;
    self.collectionView.alwaysBounceVertical = YES;
    
    self.WTBArray = [[NSMutableArray alloc]init];
    self.bumpedArray = [[NSMutableArray alloc]init];
    self.forSaleArray = [[NSMutableArray alloc]init];
    self.bumpedIds = [[NSMutableArray alloc]init];
    self.filterCategory = @"";
    
//    NSLog(@"USER %@", self.user);
    
    if (self.tabMode == YES) {
        self.user = [PFUser currentUser];
        
        //used for Team Bump & Support messages
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newTBMessage) name:@"NewTBMessage" object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshVeri) name:@"refreshVeri" object:nil];
        
        //for first TB message that's sent went user registers
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newTBMessageReg) name:@"NewTBMessageReg" object:nil];
        
        //for showing unseen order updates
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOrderBadge:) name:@"UnseenOrders" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeOrderBadge) name:@"clearOrders" object:nil];
        
        //if user posts a listing we want to auto refresh their profile feed
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadWTSListings) name:@"justPostedSaleListing" object:nil];
    }
    
    if (self.user) { //added in this check as saw a crash when querying a null user
    
        self.isSeller = YES;
    }
    
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"User Profile"
                                      }];
    
    //dismiss add pic view gesture
    self.tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideAddPicView)];
    self.tap.numberOfTapsRequired = 1;
    
    //prompt for pic (ok in load coz its tabMode)
    if (self.tabMode && ![self.user objectForKey:@"picture"] && ![[self.user objectForKey:@"addPicPromptSeen"] isEqualToString:@"YES"]) {
        [self showAddPicView];
    }
    
    //this is to explain to older users why the review system has changed
    if (self.tabMode && ![self.user objectForKey:@"reviewExplainer"]) {
        [self.user setObject:@"YES" forKey:@"reviewExplainer"];
        [self.user saveInBackground];
        
        [self showAlertWithTitle:@"Reviews" andMsg:@"With our new PayPal Checkout update you can now only leave reviews for users that you've purchased from/sold to through BUMP.\n\nThis way you know and trust that the reviews on a user's profile relate to real transactions they've completed.\n\nAny previous reviews you have receieved will no longer appear on your profile, however, we will still display your previous star rating."];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
        
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"NewTBMessageReg"] == YES && self.tabMode == YES) {
        [self newTBMessageReg];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NewTBMessageReg"];
    }
    
    [self.navigationController.navigationBar setHidden:YES];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    //check current user's dic to see if they're following this person, we don't need to fetch user for this
    if (!self.tabMode) {
        NSDictionary *followingDic = [[PFUser currentUser]objectForKey:@"followingDic"];
        
        if ([followingDic valueForKey:self.user.objectId]) {
            //following
            NSLog(@"following!");
            
            self.following = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setFollowingButton];
            });
        }
        else{
            //not following
            NSLog(@"not following");
            
            self.following = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setFollowButton];
            });
        }
    }
    
    //check if must show unread icon on cog icon
    if (self.tabMode && self.setupHeader) {
        [self calcTabBadge];
    }
    
    //refresh user after they enter a bio
    if (self.enteredBio == YES) {
        self.enteredBio = NO;
        [self refreshUser];
    }
    
    if (self.tappedListing == YES) {
        self.tappedListing = NO;
        
        if (self.changedSoldStatusOfListing == YES){
            self.changedSoldStatusOfListing = NO;
            
            if (self.segmentedControl.selectedSegmentIndex == 1) {
                //don't remove anything from liked segment, just do instant updates on wanted and for sale
            }
            
            else if (self.lastSelected.row < [self.collectionView numberOfItemsInSection:0]) {
                [self.collectionView performBatchUpdates:^{
                    [self.collectionView reloadItemsAtIndexPaths:@[self.lastSelected]];
                } completion:nil];
            }
        }
        
        if (self.deletedListing){
            self.deletedListing = NO;
            
            if (self.segmentedControl.selectedSegmentIndex == 1) {
                //don't instant update bump tab when items deleted
            }
            
            //when one item left to delete we just reload
            else if (self.lastSelected.row == 0) {
//                if (self.segmentedControl.selectedSegmentIndex == 1) {
////                    [self loadWTBListings];
//                }
                if (self.segmentedControl.selectedSegmentIndex == 0) {
                    [self loadWTSListings];
                }
            }
            else if (self.lastSelected.row < [self.collectionView numberOfItemsInSection:0]) {
                //check if for sale selected or wanted
                if (self.segmentedControl.selectedSegmentIndex == 1 && self.lastSelected.row < self.WTBArray.count) {
                    //remove item from wanted
                    [self.WTBArray removeObjectAtIndex:self.lastSelected.row];
                }
                else if (self.segmentedControl.selectedSegmentIndex == 0 && self.lastSelected.row < self.forSaleArray.count) {
                    //remove item from for sale
                    [self.forSaleArray removeObjectAtIndex:self.lastSelected.row];
                }
                [self.collectionView deleteItemsAtIndexPaths:@[self.lastSelected]];
            }
        }
    }
    
    //protect against (null) user crash
    else if (self.user) {
        
        //if already retrieved a user and its not tab mode don't fetch again
        if (!self.fetchedUser) {
            [self loadUser];
        }
    }
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.contentMode = UIViewContentModeScaleAspectFill;

    //create circle mask
    CGFloat margin = 3.0;
    CGRect rect = CGRectInset(imageView.bounds, margin, margin);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(imageView.bounds.size.width/2, imageView.bounds.size.height/2) radius:rect.size.width/2 startAngle:0 endAngle:M_PI*2 clockwise:NO];
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = path.CGPath;
    imageView.layer.mask = mask;

    //add border
    CAShapeLayer*   borderShape = [CAShapeLayer layer];
    borderShape.frame = imageView.bounds;
    borderShape.path = mask.path;
    borderShape.strokeColor = [UIColor whiteColor].CGColor;
    borderShape.fillColor = nil;
    
    if (imageView == self.userImageView) {
        borderShape.lineWidth = 6;
    }
    else{
        borderShape.lineWidth = 1.5;
    }
    
    [imageView.layer addSublayer:borderShape];
}

-(void)loadWTBListings{
    
    if (!self.user) {
        return;
    }
    
    PFQuery *wtbQuery = [PFQuery queryWithClassName:@"wantobuys"];
    [wtbQuery whereKey:@"postUser" equalTo:self.user];
    [wtbQuery whereKey:@"status" containedIn:@[@"live",@"purchased"]];
    [wtbQuery orderByDescending:@"createdAt"];
    [wtbQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            [self.refreshControl endRefreshing];

            //put the sold listings at the end
            NSSortDescriptor *sortDescriptorStatus = [[NSSortDescriptor alloc]
                                                      initWithKey: @"status" ascending: YES];
            NSSortDescriptor *sortDescriptorUpdated = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
            NSArray *sortedArray = [objects sortedArrayUsingDescriptors: [NSArray arrayWithObjects:sortDescriptorStatus,sortDescriptorUpdated,nil]];
            
            [self.WTBArray removeAllObjects];
            [self.WTBArray addObjectsFromArray:sortedArray];

            if (objects.count == 0 && self.segmentedControl.selectedSegmentIndex == 1 && self.tabMode == YES) {
                
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
            else if (objects.count == 0 && self.segmentedControl.selectedSegmentIndex == 1 && self.tabMode != YES){
                [self.actionLabel setHidden:NO];
                self.actionLabel.text = @"nothing to show";
                
                [self.createButton setHidden:YES];
                [self.bumpImageView setHidden:YES];
                [self.bumpLabel setHidden:YES];
            }
            
            else if (objects.count != 0 && self.segmentedControl.selectedSegmentIndex == 1) {
                [self.createButton setHidden:YES];
                [self.actionLabel setHidden:YES];
                
                [self.bumpImageView setHidden:YES];
                [self.bumpLabel setHidden:YES];
            }
            
            if (self.segmentedControl.selectedSegmentIndex == 1) {
                [self.collectionView reloadData];
            }
        }
        else{
            [self.refreshControl endRefreshing];

            NSLog(@"error getting WTBs %@", error);
        }
    }];
}

-(void)loadBumpedListings{
    NSLog(@"load liked listings");
    
    __block NSArray *totalBumped = [self.user objectForKey:@"totalBumpArray"];
    __block NSMutableArray *totalBumpedObjects = [NSMutableArray array];
    NSArray *saleBumped = [self.user objectForKey:@"saleBumpArray"];
    
    PFQuery *bumpedSaleListings = [PFQuery queryWithClassName:@"forSaleItems"];
    [bumpedSaleListings whereKey:@"status" containedIn:@[@"live",@"sold"]];
    [bumpedSaleListings whereKey:@"objectId" containedIn:saleBumped];
    bumpedSaleListings.limit = 2000;
    [bumpedSaleListings findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            [totalBumpedObjects addObjectsFromArray:objects];
            
            //reset arrays
            [self.bumpedArray removeAllObjects];
            [self.bumpedIds removeAllObjects];
            
            //display correct label
            if (self.tabMode == YES && self.segmentedControl.selectedSegmentIndex == 1 && totalBumpedObjects.count == 0) {
                //bump selected on own profile & nothing to show
                [self.createButton setHidden:YES];
                [self.actionLabel setHidden:NO];
                self.actionLabel.text = @"Like listings to save them for later";
                
                [self.bumpLabel setHidden:YES];
                [self.bumpImageView setHidden:YES];
                
            }
            else if(self.segmentedControl.selectedSegmentIndex == 1 && totalBumpedObjects.count == 0 && self.tabMode != YES){
                [self.actionLabel setHidden:NO];
                self.actionLabel.text = @"nothing to show";
                
                [self.createButton setHidden:YES];
                [self.bumpImageView setHidden:YES];
                [self.bumpLabel setHidden:YES];
            }
            else if (totalBumpedObjects.count != 0 && self.segmentedControl.selectedSegmentIndex == 1) {
                [self.createButton setHidden:YES];
                [self.actionLabel setHidden:YES];
                
                [self.bumpImageView setHidden:YES];
                [self.bumpLabel setHidden:YES];
            }
            
            if (totalBumpedObjects.count == 0) {
                if (self.bumpsSelected == YES) {
                    [self.collectionView performBatchUpdates:^{
                        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
                    } completion:nil];
                }
                return;
            }
            
            NSMutableArray *placeholderBumps = [NSMutableArray array];
            
            //check for duplicates
            for (PFObject *listing in totalBumpedObjects) {
                if (![self.bumpedIds containsObject:listing.objectId]) {
                    [placeholderBumps addObject:listing];
                    [self.bumpedIds addObject:listing.objectId];
                }
            }
            
            //order array based on personal total bump array (includes WTB & WTS bumps)
            for (NSString *objectID in totalBumped) {
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
            
            if (self.segmentedControl.selectedSegmentIndex == 1) {
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
            [self.refreshControl endRefreshing];
            NSLog(@"error getting WTS bumped objects %@", error);
        }
    }];

//    NSArray *wantedBumped = [self.user objectForKey:@"wantedBumpArray"];
//
//    PFQuery *bumpedListings = [PFQuery queryWithClassName:@"wantobuys"];
//    [bumpedListings whereKey:@"status" containedIn:@[@"live",@"purchased"]];
//    [bumpedListings whereKey:@"objectId" containedIn:wantedBumped];
//    bumpedListings.limit = 1000;
//
//    [bumpedListings findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//        if (objects) {
//            [self.refreshControl endRefreshing];
//
//            [totalBumpedObjects addObjectsFromArray:objects];
//
//            //now retrieve WTS Bumps
//            NSArray *saleBumped = [self.user objectForKey:@"saleBumpArray"];
//
//            PFQuery *bumpedSaleListings = [PFQuery queryWithClassName:@"forSaleItems"];
//            [bumpedSaleListings whereKey:@"status" containedIn:@[@"live",@"sold"]];
//            [bumpedSaleListings whereKey:@"objectId" containedIn:saleBumped];
//            bumpedSaleListings.limit = 1000;
//            [bumpedSaleListings findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//                if (objects) {
//                    [totalBumpedObjects addObjectsFromArray:objects];
//
//                    //reset arrays
//                    [self.bumpedArray removeAllObjects];
//                    [self.bumpedIds removeAllObjects];
//
//                    //display correct label
//                    if (self.tabMode == YES && self.segmentedControl.selectedSegmentIndex == 2 && totalBumpedObjects.count == 0) {
//                        //bump selected on own profile & nothing to show
//                        [self.createButton setHidden:YES];
//                        [self.actionLabel setHidden:NO];
//                        self.actionLabel.text = @"Like listings to save them for later";
//
//                        [self.bumpLabel setHidden:YES];
//                        [self.bumpImageView setHidden:YES];
//
//                    }
//                    else if(self.segmentedControl.selectedSegmentIndex == 2 && totalBumpedObjects.count == 0 && self.tabMode != YES){
//                        [self.actionLabel setHidden:NO];
//                        self.actionLabel.text = @"nothing to show";
//
//                        [self.createButton setHidden:YES];
//                        [self.bumpImageView setHidden:YES];
//                        [self.bumpLabel setHidden:YES];
//                    }
//                    else if (totalBumpedObjects.count != 0 && self.segmentedControl.selectedSegmentIndex == 2) {
//                        [self.createButton setHidden:YES];
//                        [self.actionLabel setHidden:YES];
//
//                        [self.bumpImageView setHidden:YES];
//                        [self.bumpLabel setHidden:YES];
//                    }
//
//                    if (totalBumpedObjects.count == 0) {
//                        if (self.bumpsSelected == YES) {
//                            [self.collectionView performBatchUpdates:^{
//                                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
//                            } completion:nil];
//                        }
//                        return;
//                    }
//
//                    NSMutableArray *placeholderBumps = [NSMutableArray array];
//
//                    //check for duplicates
//                    for (PFObject *listing in totalBumpedObjects) {
//                        if (![self.bumpedIds containsObject:listing.objectId]) {
//                            [placeholderBumps addObject:listing];
//                            [self.bumpedIds addObject:listing.objectId];
//                        }
//                    }
//
//                    //order array based on personal total bump array (includes WTB & WTS bumps)
//                    for (NSString *objectID in totalBumped) {
//                        for (PFObject *listing in placeholderBumps) {
//                            if ([listing.objectId isEqualToString:objectID]) {
//                                [self.bumpedArray addObject:listing];
//                                break;
//                            }
//                        }
//                    }
//
//                    //reverse order
//                    NSArray* reversedArray = [[self.bumpedArray reverseObjectEnumerator] allObjects];
//                    [self.bumpedArray removeAllObjects];
//                    [self.bumpedArray addObjectsFromArray:reversedArray];
//
//                    if (self.segmentedControl.selectedSegmentIndex == 2) {
//                        [self.collectionView performBatchUpdates:^{
//                            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
//                        } completion:nil];
//                    }
//                    else if (self.bumpsSelected == NO && self.WTBSelected == NO && self.WTSSelected == NO){
//                        //fail safe reload
//                        [self.collectionView reloadData];
//                    }
//
//                }
//                else{
//                    [self.refreshControl endRefreshing];
//                    NSLog(@"error getting WTS bumped objects %@", error);
//                }
//            }];
//
//
//        }
//        else{
//            [self.refreshControl endRefreshing];
//            NSLog(@"error getting wanted bumped %@", error);
//        }
//    }];
}

-(void)loadWTSListings{
    NSLog(@"load wts");
    
    if (!self.user || self.loadingSales == YES ) {
        return;
    }
    
    self.loadingSales = YES;
    
    self.saleQuery = nil;
    self.saleQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [self.saleQuery whereKey:@"sellerUser" equalTo:self.user];
    [self.saleQuery whereKey:@"status" containedIn:@[@"live",@"sold"]];
    
    if (self.filtersArray.count > 0) {
        [self setupPullQuery];
        
        //brand filter
        if (self.filterBrandsArray.count > 0) {
            [self.saleQuery whereKey:@"keywords" containedIn:self.filterBrandsArray];
        }
    }
    else{
        [self.saleQuery orderByDescending:@"createdAt"];
    }
    
    self.saleQuery.limit = 1000;
    
    [self.saleQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            [self.refreshControl endRefreshing];
            
            //put the sold listings at the end
            NSSortDescriptor *sortDescriptorStatus = [[NSSortDescriptor alloc]
                                                initWithKey: @"status" ascending: YES];
            NSSortDescriptor *sortDescriptorUpdated = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
            NSArray *sortedArray = [objects sortedArrayUsingDescriptors: [NSArray arrayWithObjects:sortDescriptorStatus,sortDescriptorUpdated,nil]];
            
            [self.forSaleArray removeAllObjects];
            [self.forSaleArray addObjectsFromArray:sortedArray];
            
            if (objects.count == 0 && self.WTSSelected == YES && self.tabMode == YES) {
                [self.createButton setHidden:NO];
                
                self.actionLabel.text = @"List an item for sale";
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
            
            //show filter button
            if (objects.count > 29 && self.WTSSelected == YES && self.tabMode != YES && self.filtersArray.count == 0 && self.segmentedControl.selectedSegmentIndex == 0){
                [self showFilter];
            }
            else if (self.filtersArray.count > 0 && self.segmentedControl.selectedSegmentIndex == 0 && self.WTSSelected == YES){
                [self showFilter];
            }
            
            if (self.forSalePressed == YES) {
                self.forSalePressed = NO;
            }
            
            self.infinEmpty = NO;
            self.loadingSales = NO;
            self.finishedSaleInfin = YES;
            self.saleSkipped = (int)objects.count;

            if (self.WTSSelected == YES) {
                [self.collectionView performBatchUpdates:^{
                    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
                } completion:nil];
            }
        }
        else{
            self.loadingSales = NO;
            [self.refreshControl endRefreshing];
            NSLog(@"error getting infin WTSs %@", error);
        }
    }];
}

-(void)loadMoreSaleListings{
    NSLog(@"load more items");
    
    if (!self.user || self.loadingSales == YES || self.forSaleArray.count < 42 || !self.finishedSaleInfin || self.infinEmpty) {
        return;
    }
    
    self.finishedSaleInfin = NO;
    
    self.saleInfinQuery = nil;
    self.saleInfinQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [self.saleInfinQuery whereKey:@"sellerUser" equalTo:self.user];
    [self.saleInfinQuery whereKey:@"status" containedIn:@[@"live",@"sold"]];
    
    if (self.filtersArray.count > 0) {
        [self setupInfinQuery];
        
        //brand filter
        if (self.filterBrandsArray.count > 0) {
            [self.saleInfinQuery whereKey:@"keywords" containedIn:self.filterBrandsArray];
        }
    }
    else{
        [self.saleInfinQuery orderByDescending:@"createdAt"];
    }
    
    self.saleInfinQuery.limit = 42;
    self.saleInfinQuery.skip = self.saleSkipped;
    [self.saleInfinQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            [self.refreshControl endRefreshing];
            
            //put the sold listings at the end
            NSSortDescriptor *sortDescriptorStatus = [[NSSortDescriptor alloc]
                                                      initWithKey: @"status" ascending: YES];
            NSSortDescriptor *sortDescriptorUpdated = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
            NSArray *sortedArray = [objects sortedArrayUsingDescriptors: [NSArray arrayWithObjects:sortDescriptorStatus,sortDescriptorUpdated,nil]];
            
            [self.forSaleArray addObjectsFromArray:sortedArray];
            
            int count = (int)objects.count;
            
            if (count == 0) {
                self.infinEmpty = YES;
            }
            
            self.saleSkipped += count;
            
            self.finishedSaleInfin = YES;
            
            if (self.WTSSelected == YES) {
                [self.collectionView reloadData];
            }
        }
        else{
            [self.refreshControl endRefreshing];
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
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        return self.forSaleArray.count;
    }
//    else if (self.segmentedControl.selectedSegmentIndex == 1){
//        return self.WTBArray.count;
//    }
    else if (self.segmentedControl.selectedSegmentIndex == 1){
        return self.bumpedArray.count;
    }
    else{
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    ProfileItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    [cell.purchasedImageView setHidden:YES];
    
    [cell.boostImageView setHidden:YES];
    [cell.boost2ImageView setHidden:YES];
    [cell.topRightImageView setHidden:YES];

    cell.itemImageView.image = nil;
    cell.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    PFObject *listingObject;
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
//        NSLog(@"WTS selected");
        listingObject = [self.forSaleArray objectAtIndex:indexPath.row];
    }
//    else if (self.segmentedControl.selectedSegmentIndex == 1){
////        NSLog(@"WTB selected");
//        listingObject = [self.WTBArray objectAtIndex:indexPath.row];
//    }
    else if (self.segmentedControl.selectedSegmentIndex == 1){
//        NSLog(@"Bump selected");
        listingObject = [self.bumpedArray objectAtIndex:indexPath.row];
    }
    
    if (![listingObject objectForKey:@"thumbnail"]) {
        [cell.itemImageView setFile:[listingObject objectForKey:@"image1"]];
    }
    else{
        [cell.itemImageView setFile:[listingObject objectForKey:@"thumbnail"]];
        
        //so first image in listing is loaded faster
        PFFile *image = [listingObject objectForKey:@"image1"];
        [image getDataInBackground];
    }
    [cell.itemImageView loadInBackground];
    
    //don't show purchased on bumped listings section
    if ([[listingObject objectForKey:@"status"]isEqualToString:@"purchased"] && self.segmentedControl.selectedSegmentIndex != 1) {
        cell.itemImageView.alpha = 0.5;
        [cell.purchasedImageView setImage:[UIImage imageNamed:@"purchasedIconS"]];
        [cell.purchasedImageView setHidden:NO];
    }
    else if ([[listingObject objectForKey:@"status"]isEqualToString:@"sold"] && self.segmentedControl.selectedSegmentIndex != 1) {
        
        if ([[listingObject objectForKey:@"payment"]isEqualToString:@"pending"]) {
            //listing is pending a successful payment so pretend to seller it hasn't been purchased yet
            cell.itemImageView.alpha = 1.0;
            [cell.purchasedImageView setHidden:YES];
        }
        else{
            cell.itemImageView.alpha = 0.5;
            [cell.purchasedImageView setImage:[UIImage imageNamed:@"soldIconShadow"]];
            [cell.purchasedImageView setHidden:NO];
        }
    }
    else{
        cell.itemImageView.alpha = 1.0;
        [cell.purchasedImageView setHidden:YES];
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{

    self.tappedListing = YES;
    
    if (self.tabMode) {
        self.lastSelected = indexPath;
    }
    
    PFObject *selected;
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        [Answers logCustomEventWithName:@"Profile Item Selected"
                       customAttributes:@{
                                          @"type": @"sale"
                                          }];
        
        NSLog(@"WTS selected");
        selected = [self.forSaleArray objectAtIndex:indexPath.row];
        self.forSalePressed = YES;
        ForSaleListing *vc = [[ForSaleListing alloc]init];
        vc.listingObject = selected;
        vc.fromBuyNow = YES;
        vc.pureWTS = YES; //always pure WTS from a profile
        if (self.tabMode) {
            vc.delegate = self;
        }
        vc.source = @"profile";

        [self.navigationController pushViewController:vc animated:YES];
    }
//    else if (self.segmentedControl.selectedSegmentIndex == 1){
//        [Answers logCustomEventWithName:@"Profile Item Selected"
//                       customAttributes:@{
//                                          @"type": @"WTB"
//                                          }];
//
//        NSLog(@"WTB selected");
//        PFObject *listing = [self.WTBArray objectAtIndex:indexPath.row];
//        self.WTBPressed = YES;
//        ListingController *vc = [[ListingController alloc]init];
//        vc.listingObject = listing;
//        if (self.tabMode) {
//            vc.delegate = self;
//        }
//        [self.navigationController pushViewController:vc animated:YES];
//    }
    else if (self.segmentedControl.selectedSegmentIndex == 1){
        
        NSLog(@"Bump selected");
        selected = [self.bumpedArray objectAtIndex:indexPath.row];
        self.bumpedPressed = YES;
        
        //check if WTS or WTB
        if ([selected objectForKey:@"sellerUser"]) {
            [Answers logCustomEventWithName:@"Profile Item Selected"
                           customAttributes:@{
                                              @"type": @"Liked",
                                              @"item":@"sale"
                                              }];
            
            //WTS
            ForSaleListing *vc = [[ForSaleListing alloc]init];
            vc.listingObject = selected;
            vc.fromBuyNow = YES;
            vc.pureWTS = YES; //always pure WTS from a profile
            if (self.tabMode) {
                vc.delegate = self;
            }

            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            [Answers logCustomEventWithName:@"Profile Item Selected"
                           customAttributes:@{
                                              @"type": @"Liked",
                                              @"item":@"WTB"
                                              }];
            //WTB
            ListingController *vc = [[ListingController alloc]init];
            vc.listingObject = selected;
            if (self.tabMode) {
                vc.delegate = self;
            }
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else{
        //fail safe
        
    }
}

-(void)fbPressed{
    if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
        [Answers logCustomEventWithName:@"Discover Pressed"
                       customAttributes:@{}];
        
        //goto discover
        whoBumpedTableView *vc = [[whoBumpedTableView alloc]init];
        vc.mode = @"discover";
        [self.navigationController pushViewController:vc animated:YES];
        
        //set image to read if needs be
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"seenDiscover"]){
            //mark as seen discover
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"seenDiscover"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.FBButton setImage:[UIImage imageNamed:@"discoverIcon"] forState:UIControlStateNormal];
            });
        }
    }
    else{
        [Answers logCustomEventWithName:@"Facebook Profile Pressed"
                       customAttributes:@{
                                          @"ownProfile": @"NO"
                                          }];
        
        NSString *URLString = [NSString stringWithFormat:@"https://facebook.com/%@", [self.user objectForKey:@"facebookId"]];
        SFSafariViewController *safariView = [[SFSafariViewController alloc]initWithURL:[NSURL URLWithString:URLString]];
        if (@available(iOS 11.0, *)) {
            safariView.dismissButtonStyle = UIBarButtonSystemItemCancel;
        }
        
        if (@available(iOS 10.0, *)) {
            safariView.preferredControlTintColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
        }
        
        [self.navigationController presentViewController:safariView animated:YES completion:nil];
    }
}

-(void)selectedReportReason:(NSString *)reason{
    self.hitReport = YES;
    
    NSArray *reportedArray = [self.user objectForKey:@"reportersArray"];
    
    if (![reportedArray containsObject:[PFUser currentUser].objectId]) {
        [Answers logCustomEventWithName:@"Reported User"
                       customAttributes:@{
                                          @"reason":reason,
                                          @"reporter":[PFUser currentUser].objectId,
                                          @"user":self.user.objectId,
                                          @"date":[NSDate date]
                                          }];
        
        NSString *mod = @"NO";
        BOOL recentConvoUser = NO;
        BOOL recentOrderUser = NO;
        
        if ([[[PFUser currentUser] objectForKey:@"mod"]isEqualToString:@"YES"] && ![[[PFUser currentUser] objectForKey:@"fod"]isEqualToString:@"YES"]) {
            mod = @"YES";
            
            [Answers logCustomEventWithName:[NSString stringWithFormat:@"Mod Reported Profile %@ %@", [PFUser currentUser].objectId,[PFUser currentUser].username]
                           customAttributes:@{
                                              @"reason":reason,
                                              @"reporter":[PFUser currentUser].objectId,
                                              @"user":self.user.objectId
                                              }];
        }
        else{
            //check if user is in recent orders or recent convos arrays
//            if ([[PFUser currentUser]objectForKey:@"recentOrderUsers"]) {
//
//                NSArray *recents = [[PFUser currentUser]objectForKey:@"recentOrderUsers"];
//                if ([recents containsObject:self.user.objectId]) {
//                    recentOrderUser = YES;
//                }
//            }
//            else if ([[PFUser currentUser]objectForKey:@"recentConvoUsers"]) {
//                NSArray *recents = [[PFUser currentUser]objectForKey:@"recentConvoUsers"];
//                if ([recents containsObject:self.user.objectId]) {
//                    recentConvoUser = YES;
//                }
//            }
        }
        
        //only pass the 1 which is positive
        if (recentOrderUser) {
            NSDictionary *params = @{@"userId": self.user.objectId, @"reporterId": [PFUser currentUser].objectId, @"reason": reason, @"mod":mod, @"modName":[PFUser currentUser].username, @"recentOrder": @"YES"};
            [PFCloud callFunctionInBackground:@"reportUserFunction" withParameters: params block:^(id  _Nullable object, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"error reporting user: %@", error);
                    
                    [Answers logCustomEventWithName:@"Error Reporting User"
                                   customAttributes:@{
                                                      @"error":error.description
                                                      }];
                }
            }];

        }
        else if (recentConvoUser){
            NSLog(@"recent convo user");
            
            NSDictionary *params = @{@"userId": self.user.objectId, @"reporterId": [PFUser currentUser].objectId, @"reason": reason, @"mod":mod, @"modName":[PFUser currentUser].username, @"recentConvo": @"YES"};
            [PFCloud callFunctionInBackground:@"reportUserFunction" withParameters: params block:^(id  _Nullable object, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"error reporting user: %@", error);
                    
                    [Answers logCustomEventWithName:@"Error Reporting User"
                                   customAttributes:@{
                                                      @"error":error.description
                                                      }];
                }
                else{
                    NSLog(@"success reporting");
                }
            }];
        }
        else{
            NSDictionary *params = @{@"userId": self.user.objectId, @"reporterId": [PFUser currentUser].objectId, @"reason": reason, @"mod":mod, @"modName":[PFUser currentUser].username};
            [PFCloud callFunctionInBackground:@"reportUserFunction" withParameters: params block:^(id  _Nullable object, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"error reporting user: %@", error);
                    
                    [Answers logCustomEventWithName:@"Error Reporting User"
                                   customAttributes:@{
                                                      @"error":error.description
                                                      }];
                }
            }];
        }

    }
    //we let mods report multiple times if needs be
    else if ([[[PFUser currentUser] objectForKey:@"mod"]isEqualToString:@"YES"] && ![[[PFUser currentUser] objectForKey:@"fod"]isEqualToString:@"YES"]) {
        
        [Answers logCustomEventWithName:[NSString stringWithFormat:@"Mod Reported Profile %@ %@", [PFUser currentUser].objectId,[PFUser currentUser].username]
                       customAttributes:@{
                                          @"reason":reason,
                                          @"reporter":[PFUser currentUser].objectId,
                                          @"user":self.user.objectId
                                          }];
        
        NSDictionary *params = @{@"userId": self.user.objectId, @"reporterId": [PFUser currentUser].objectId, @"reason": reason, @"mod":@"YES", @"modName":[PFUser currentUser].username};
        [PFCloud callFunctionInBackground:@"reportUserFunction" withParameters: params block:^(id  _Nullable object, NSError * _Nullable error) {
            if (error) {
                NSLog(@"error reporting user 1: %@", error);
                
                self.hitReport = NO;

                [Answers logCustomEventWithName:@"Error Reporting User"
                               customAttributes:@{
                                                  @"error":error.description
                                                  }];
            }
        }];
    }

}

-(void)sendReportMessageWithReason:(NSString *)reason{
    //save message first
    NSString *messageString = @"";
    
    if ([reason isEqualToString:@"Other"]) {
        if ([[PFUser currentUser]objectForKey:@"firstName"]) {
            messageString = [NSString stringWithFormat:@"Hey %@,\n\nThanks for helping keep the Bump community safe and reporting user @%@\n\nMind telling us why you reported the user?\n\nSophie\nBUMP Customer Service",[[PFUser currentUser]objectForKey:@"firstName"],self.user.username];
        }
        else{
            messageString = [NSString stringWithFormat:@"Hey,\n\nThanks for helping keep the Bump community safe and reporting user @%@\n\nMind telling us why you reported the user?\n\nSophie\nBUMP Customer Service",self.user.username];
        }
    }
    else{
        if ([[PFUser currentUser]objectForKey:@"firstName"]) {
            messageString = [NSString stringWithFormat:@"Hey %@,\n\nThanks for helping to keep the Bump community safe and reporting user @%@\n\nReason: %@\n\nWe'll get in touch if we have any more questions 👊\n\nSophie\nBUMP Customer Service",[[PFUser currentUser]objectForKey:@"firstName"],self.user.username, reason];
        }
        else{
            messageString = [NSString stringWithFormat:@"Hey,\n\nThanks for helping to keep the Bump community safe and reporting user @%@\n\nReason: %@\n\nWe'll get in touch if we have any more questions 👊\n\nSophie\nBUMP Customer Service",self.user.username, reason];
        }
    }
}

-(void)SetupListing{
    CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
    vc.usernameToCheck = self.usernameToList;
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    self.forSalePressed = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)addForSalePressed{
    
    if ([[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"] || [[PFUser currentUser].objectId isEqualToString:@"xD4xViQCUe"]) {
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
    if (self.noDeals == YES || self.isBumpOfficial) {
        return;
    }
    ReviewsVC *vc = [[ReviewsVC alloc]init];
    vc.user = self.user;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)segmentControlChanged{
    [self.createButton setHidden:YES];
    [self.bumpImageView setHidden:YES];
    [self.bumpLabel setHidden:YES];
    [self.actionLabel setHidden:YES];
    
    //scroll to top before reloading after checking if enough items in CV to avoid crash
    if ([self.collectionView numberOfItemsInSection:0] > 0) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:NO];
    }
    
    if (self.tabMode == YES) {
        //looking at own profile for sure
        [self hideFilter];

        // all 3
//        if (self.segmentedControl.selectedSegmentIndex == 1) {
//            //wanted
//            self.WTBSelected = YES;
//            self.WTSSelected = NO;
//            self.bumpsSelected = NO;
//
//            if (self.WTBArray.count == 0) {
//                [self.createButton setHidden:NO];
//                self.actionLabel.text = @"Let sellers know what you want";
//                [self.actionLabel setHidden:NO];
//
//                [self.bumpImageView setHidden:YES];
//                [self.bumpLabel setHidden:YES];
//            }
//
//        }
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            //selling
            self.WTBSelected = NO;
            self.WTSSelected = YES;
            self.bumpsSelected = NO;
            
            if (self.forSaleArray.count == 0) {
                if (self.firstLoad) {
                    //show prompt to list an item
                    [self.createButton setTitle:@"Create" forState:UIControlStateNormal];
                    [self.createButton setHidden:NO];
                    
                    self.actionLabel.text = @"List an item for sale";
                    [self.actionLabel setHidden:NO];
                    
                    [self.bumpImageView setHidden:YES];
                    [self.bumpLabel setHidden:YES];
                }
                else{
                    self.actionLabel.text = @"Loading";
                    [self.actionLabel setHidden:NO];
                    self.firstLoad = YES;
                }

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
                self.actionLabel.text = @"Like listings to save them for later";
                [self.actionLabel setHidden:NO];
                
                
//                if ([ [ UIScreen mainScreen ] bounds ].size.height > 568) {
//                    //don't show on iPhone SE as screen isn't big enough
//                    [self.bumpImageView setHidden:NO];
//                }
                [self.bumpImageView setHidden:YES];
                [self.bumpLabel setHidden:YES];
            }
        }
        
    }
    else{

        // all 3
//        if (self.segmentedControl.selectedSegmentIndex == 1) {
//            [self hideFilter];
//
//            //wanted
//            self.WTBSelected = YES;
//            self.WTSSelected = NO;
//            self.bumpsSelected = NO;
//
//            if (self.WTBArray.count == 0) {
//                [self.actionLabel setHidden:NO];
//                self.actionLabel.text = @"nothing to show";
//
//                [self.createButton setHidden:YES];
//                [self.bumpImageView setHidden:YES];
//                [self.bumpLabel setHidden:YES];
//            }
//
//        }
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            if (self.forSaleArray.count > 29 && self.filtersArray.count == 0) {
                [self showFilter];
            }
            else if (self.filtersArray.count > 0){
                [self showFilter];
            }

            //selling
            self.WTBSelected = NO;
            self.WTSSelected = YES;
            self.bumpsSelected = NO;
            
            if (self.forSaleArray.count == 0) {
                if (self.firstLoad) {
                    [self.actionLabel setHidden:NO];
                    self.actionLabel.text = @"nothing to show";
                    
                    [self.createButton setHidden:YES];
                    [self.bumpImageView setHidden:YES];
                    [self.bumpLabel setHidden:YES];
                }
                else{
                    self.actionLabel.text = @"Loading";
                    [self.actionLabel setHidden:NO];
                    self.firstLoad = YES;
                }
            }
        }
        else{
            [self hideFilter];

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
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self backPressed];
    }];
    
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)showAlertView{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    if (![self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
        
        if (!self.isBumpOfficial) {
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Message" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [self setupMessages];
            }]];
        }
        
        //Share on Whatsapp
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share on Whatsapp" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [Answers logCustomEventWithName:@"Shared on Whatsapp"
                           customAttributes:@{
                                              @"link":@"profile"
                                              }];
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            
            if (self.tabMode) {
                [mixpanel track:@"Tapped Share" properties:@{
                                                             @"channel":@"whatsapp",
                                                             @"content":@"own profile"
                                                             }];
            }
            else{
                [mixpanel track:@"Tapped Share" properties:@{
                                                             @"channel":@"whatsapp",
                                                             @"content":@"profile"
                                                             }];
            }
            
            NSString *routeString = [NSString stringWithFormat:@"profile/%@",self.user.objectId];
            BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:self.user.objectId];
            BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
            linkProperties.feature = @"sharingProfile";
            linkProperties.channel = @"whatsapp";
            [linkProperties addControlParam:@"$deeplink_path" withValue:routeString];
            [linkProperties addControlParam:@"referrer" withValue:[PFUser currentUser].objectId];
            
            [buo getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString* url, NSError* error) {
                if (!error) {
                    NSLog(@"whatsapp link %@", url);
                    
                    NSString * msg = [NSString stringWithFormat:@"@%@ is on BUMP %@", self.user.username,url];
                    
                    msg = [msg stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                    msg = [msg stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"?" withString:@"%3F"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"," withString:@"%2C"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
                    
                    NSString * urlWhats = [NSString stringWithFormat:@"whatsapp://send?text=%@",msg];
                    NSURL * whatsappURL = [NSURL URLWithString:urlWhats];
                    
                    if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
                        [[UIApplication sharedApplication] openURL: whatsappURL];
                    }
                }
                else{
                    NSLog(@"error w/ whatsapp link %@", error);
                    [Answers logCustomEventWithName:@"Whatsapp Link Error"
                                   customAttributes:@{
                                                      @"link":@"profile"
                                                      }];
                    
                    NSString *urlString = [NSString stringWithFormat:@"https://sobump.com/p?profile=%@",self.user.username];
                    NSString * msg = [NSString stringWithFormat:@"@%@ is on BUMP %@", self.user.username,urlString];
                    
                    msg = [msg stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                    msg = [msg stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"?" withString:@"%3F"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"," withString:@"%2C"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
                    
                    NSString * urlWhats = [NSString stringWithFormat:@"whatsapp://send?text=%@",msg];
                    NSURL * whatsappURL = [NSURL URLWithString:urlWhats];
                    
                    if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
                        [[UIApplication sharedApplication] openURL: whatsappURL];
                    }
                }
            }];
            
            
        }]];
        
        //Share on Messenger
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share on Messenger" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [Answers logCustomEventWithName:@"Shared on Messenger"
                           customAttributes:@{
                                              @"link":@"profile"
                                              }];
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            
            if (self.tabMode) {
                [mixpanel track:@"Tapped Share" properties:@{
                                                             @"channel":@"messenger",
                                                             @"content":@"own profile"
                                                             }];
            }
            else{
                [mixpanel track:@"Tapped Share" properties:@{
                                                             @"channel":@"messenger",
                                                             @"content":@"profile"
                                                             }];
            }
            
            NSString *routeString = [NSString stringWithFormat:@"profile/%@",self.user.objectId];
            BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:self.user.objectId];
            BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
            linkProperties.feature = @"sharingProfile";
            linkProperties.channel = @"messenger";
            [linkProperties addControlParam:@"$deeplink_path" withValue:routeString];
            [linkProperties addControlParam:@"referrer" withValue:[PFUser currentUser].objectId];
            
            [buo getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString* url, NSError* error) {
                if (!error) {
                    NSLog(@"messenger share link %@", url);
                    NSString *urlString = [NSString stringWithFormat:@"fb-messenger://share/?link=%@",url];
                    NSURL *messengerURL = [NSURL URLWithString:urlString];
                    if ([[UIApplication sharedApplication] canOpenURL: messengerURL]) {
                        [[UIApplication sharedApplication] openURL: messengerURL];
                    }
                    
                }
                else{
                    [Answers logCustomEventWithName:@"Messenger Link Error"
                                   customAttributes:@{
                                                      @"link":@"forsale listing",
                                                      @"error":error.description
                                                      }];
                    NSString *urlString = [NSString stringWithFormat:@"fb-messenger://share/?link=https://sobump.com/p?profile=%@",self.user.username];
                    NSURL *messengerURL = [NSURL URLWithString:urlString];
                    if ([[UIApplication sharedApplication] canOpenURL: messengerURL]) {
                        [[UIApplication sharedApplication] openURL: messengerURL];
                    }
                }
            }];
        }]];
        
        //Copy Link
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Copy Profile Link" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [Answers logCustomEventWithName:@"Copied Link"
                           customAttributes:@{
                                              @"link":@"profile"
                                              }];
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            
            if (self.tabMode) {
                [mixpanel track:@"Tapped Share" properties:@{
                                                             @"channel":@"link",
                                                             @"content":@"own profile"
                                                             }];
            }
            else{
                [mixpanel track:@"Tapped Share" properties:@{
                                                             @"channel":@"link",
                                                             @"content":@"profile"
                                                             }];
            }
            
            NSString *routeString = [NSString stringWithFormat:@"profile/%@",self.user.objectId];
            BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:self.user.objectId];
            BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
            linkProperties.feature = @"sharingProfile";
            linkProperties.channel = @"link";
            [linkProperties addControlParam:@"$deeplink_path" withValue:routeString];
            [linkProperties addControlParam:@"referrer" withValue:[PFUser currentUser].objectId];
            
            [buo getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString* url, NSError* error) {
                if (!error) {
                    NSLog(@"copied link %@", url);
                    [Answers logCustomEventWithName:@"Copied Link"
                                   customAttributes:@{
                                                      @"link":@"profile",
                                                      @"error":@NO
                                                      }];
                    
                    UIPasteboard *pb = [UIPasteboard generalPasteboard];
                    [pb setString:url];
                }
                else{
                    NSLog(@"error copying link %@", error);
                    [Answers logCustomEventWithName:@"Copied Link"
                                   customAttributes:@{
                                                      @"link":@"profile",
                                                      @"error":@YES
                                                      }];
                    
                    NSString *urlString = [NSString stringWithFormat:@"http://sobump.com/p?profile=%@",self.user.username];
                    UIPasteboard *pb = [UIPasteboard generalPasteboard];
                    [pb setString:urlString];
                }
            }];
            
            //show HUD
            [self showHUDWithLabel:@"Copied"];
            
            double delayInSeconds = 2.0; // number of seconds to wait
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self hideHUD];
            });
        }]];
        
        //General Share
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"More" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [Answers logCustomEventWithName:@"Shared Profile"
                           customAttributes:@{
                                              @"link":@"profile"
                                              }];
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            NSMutableArray *items = [NSMutableArray new];
            
            NSString *routeString = [NSString stringWithFormat:@"profile/%@",self.user.objectId];
            BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:self.user.objectId];
            BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
            linkProperties.feature = @"sharingProfile";
            linkProperties.channel = @"more";
            [linkProperties addControlParam:@"$deeplink_path" withValue:routeString];
            [linkProperties addControlParam:@"referrer" withValue:[PFUser currentUser].objectId];
            
            [buo getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString* url, NSError* error) {
                if (!error) {
                    NSLog(@"more link %@", url);
                    
                    [items addObject:[NSString stringWithFormat:@"@%@ is on BUMP  %@",self.user.username,url]];
                    UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
                    [self presentViewController:activityController animated:YES completion:nil];
                    
                    [activityController setCompletionWithItemsHandler:
                     ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                         
                         if (activityType) {
                             if (self.tabMode) {
                                 [mixpanel track:@"Tapped Share" properties:@{
                                                                              @"channel":activityType,
                                                                              @"content":@"own profile",
                                                                              @"more":@"YES"
                                                                              }];
                             }
                             else{
                                 [mixpanel track:@"Tapped Share" properties:@{
                                                                              @"channel":activityType,
                                                                              @"content":@"profile",
                                                                              @"more":@"YES"
                                                                              }];
                             }
                         }
                         else{
                             if (self.tabMode) {
                                 [mixpanel track:@"Tapped Share" properties:@{
                                                                              @"channel":@"more",
                                                                              @"content":@"own profile"
                                                                              }];
                             }
                             else{
                                 [mixpanel track:@"Tapped Share" properties:@{
                                                                              @"channel":@"more",
                                                                              @"content":@"profile"
                                                                              }];
                             }
                         }
                     }];
                }
                else{
                    NSLog(@"error w/ more link %@", error);
                    [Answers logCustomEventWithName:@"More Share Link Error"
                                   customAttributes:@{
                                                      @"link":@"profile",
                                                      @"error":error.description
                                                      }];
                    
                    [items addObject:[NSString stringWithFormat:@"@%@ is on BUMP  https://sobump.com/p?profile=%@",self.user.username,self.user.username]];
                    UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
                    [self presentViewController:activityController animated:YES completion:nil];
                    
                    [activityController setCompletionWithItemsHandler:
                     ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                         if (activityType) {
                             if (self.tabMode) {
                                 [mixpanel track:@"Tapped Share" properties:@{
                                                                              @"channel":activityType,
                                                                              @"content":@"own profile",
                                                                              @"more":@"YES"
                                                                              }];
                             }
                             else{
                                 [mixpanel track:@"Tapped Share" properties:@{
                                                                              @"channel":activityType,
                                                                              @"content":@"profile",
                                                                              @"more":@"YES"
                                                                              }];
                             }
                         }
                         else{
                             if (self.tabMode) {
                                 [mixpanel track:@"Tapped Share" properties:@{
                                                                              @"channel":@"more",
                                                                              @"content":@"own profile"
                                                                              }];
                             }
                             else{
                                 [mixpanel track:@"Tapped Share" properties:@{
                                                                              @"channel":@"more",
                                                                              @"content":@"profile"
                                                                              }];
                             }
                         }
                     }];
                }
            }];
        }]];
        
        //subscribe to post notifications
        PFInstallation *currentInstall = [PFInstallation currentInstallation];
        
        if ([currentInstall.channels containsObject:self.user.objectId]) {
            NSLog(@"already subscribed to this seller");
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Turn off Post Notifications" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [Answers logCustomEventWithName:@"Disabled Post Notifications"
                               customAttributes:@{}];
                
                [currentInstall removeObject:self.user.objectId forKey:@"channels"];
                [currentInstall saveInBackground];
                
                [Intercom logEventWithName:@"disabled_post_notification" metaData: @{}];
                
                [self showHUDWithLabel:@"Unsubscribed"];
                
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"Disabled Post Notifications" properties:@{}];
                
                //update this user's sub count
                NSDictionary *params = @{@"userId": self.user.objectId, @"increment":@"NO"};
                [PFCloud callFunctionInBackground:@"changeSubCount" withParameters: params block:^(id  _Nullable object, NSError * _Nullable error) {
                    if (error) {
                        NSLog(@"error decrementing subcount: %@", error);
                        
                        [Answers logCustomEventWithName:@"Error Decrementing Sub Count"
                                       customAttributes:@{
                                                          @"error":error.description
                                                          }];
                    }
                }];
                
                double delayInSeconds = 1.0; // number of seconds to wait
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self hideHUD];
                });
            }]];
            
        }
        else{
            NSLog(@"not subscribed yet");
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Turn on Post Notifications" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
                [Answers logCustomEventWithName:@"Enabled Post Notifications"
                               customAttributes:@{}];
                
                [currentInstall addUniqueObject:self.user.objectId forKey:@"channels"];
                [currentInstall saveInBackground];
                
                [Intercom logEventWithName:@"enabled_post_notification" metaData: @{}];
                
                [self showHUDWithLabel:@"Subscribed"];
                
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"Enabled Post Notifications" properties:@{}];
                
                //update this user's sub count
                NSDictionary *params = @{@"userId": self.user.objectId, @"increment":@"YES"};
                [PFCloud callFunctionInBackground:@"changeSubCount" withParameters: params block:^(id  _Nullable object, NSError * _Nullable error) {
                    if (error) {
                        NSLog(@"error incrementing subcount: %@", error);
                        
                        [Answers logCustomEventWithName:@"Error Incrementing Sub Count"
                                       customAttributes:@{
                                                          @"error":error.description
                                                          }];
                    }
                }];
                
                double delayInSeconds = 1.0; // number of seconds to wait
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self hideHUD];
                });
            }]];
        }
        
        if(self.isBumpOfficial){
           //dont let them report
        }
        else if ([[[PFUser currentUser] objectForKey:@"mod"]isEqualToString:@"YES"] && ![[[PFUser currentUser] objectForKey:@"fod"]isEqualToString:@"YES"] && !self.hitReport) {
            //user is a mod so prompt for a reason
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Ban" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
                
                UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Ban User" message:@"Why would you like to ban this user? (this reason will be sent to the user)" preferredStyle:UIAlertControllerStyleAlert];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                }]];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Bots/Software" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self selectedReportReason:@"Non digital items (e.g. Bots) are not permitted"];
                }]];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Fakes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self selectedReportReason:@"Selling a counterfeit/fake item"];
                }]];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Legit Checks" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self selectedReportReason:@"Legit Checks are not permitted"];
                }]];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Mystery Box" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self selectedReportReason:@"Mystery boxes are not permitted"];
                }]];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Not Streetwear" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self selectedReportReason:@"Selling a non-streetwear item"];
                }]];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Offensive" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self selectedReportReason:@"Offensive listing"];
                }]];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Raffle" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self selectedReportReason:@"Raffles are not permitted"];
                }]];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Spamming" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self selectedReportReason:@"Spamming"];
                }]];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Other" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self enterBanComment];
                }]];
                
                [self presentViewController:alertView animated:YES completion:nil];
            }]];

        }
        else{
            //not a mod
            
            //do a check to see if user has reported them before
            NSArray *reportedArray = [self.user objectForKey:@"reportedArray"]; //reportedArray is list of userIds that have reported this user
            
            if (![reportedArray containsObject:[PFUser currentUser].objectId] && !self.hitReport) {
                //user hasn't reported this person before so let them report the user!
                
                [actionSheet addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
                    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Report User" message:@"Why would you like to report this user?" preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    }]];
                    
                    [alertView addAction:[UIAlertAction actionWithTitle:@"Selling Bots/Software" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self selectedReportReason:@"Non digital items (e.g. Bots) are not permitted"];
                    }]];
                    
                    [alertView addAction:[UIAlertAction actionWithTitle:@"Selling Fakes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self selectedReportReason:@"Selling a counterfeit/fake item"];
                    }]];
                    
                    [alertView addAction:[UIAlertAction actionWithTitle:@"Selling Legit Checks" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self selectedReportReason:@"Legit Checks are not permitted"];
                    }]];
                    
                    [alertView addAction:[UIAlertAction actionWithTitle:@"Selling Mystery Boxes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self selectedReportReason:@"Mystery boxes are not permitted"];
                    }]];
                    
                    [alertView addAction:[UIAlertAction actionWithTitle:@"Selling Non-Streetwear" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self selectedReportReason:@"Selling a non-streetwear item"];
                    }]];
                    
                    [alertView addAction:[UIAlertAction actionWithTitle:@"Offensive Behaviour" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self selectedReportReason:@"Offensive listing"];
                    }]];
                    
                    [alertView addAction:[UIAlertAction actionWithTitle:@"Raffles" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self selectedReportReason:@"Raffles are not permitted"];
                    }]];
                    
                    [alertView addAction:[UIAlertAction actionWithTitle:@"Spamming" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self selectedReportReason:@"Spamming"];
                    }]];
                    
                    [alertView addAction:[UIAlertAction actionWithTitle:@"Other" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self selectedReportReason:@"Other"];
                    }]];
                    
                    [self presentViewController:alertView animated:YES completion:nil];
                    
                }]];
            }
        }
    }
    else{
        //Share on Whatsapp
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share on Whatsapp" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [Answers logCustomEventWithName:@"Shared on Whatsapp"
                           customAttributes:@{
                                              @"link":@"profile"
                                              }];
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Tapped Share" properties:@{
                                                         @"channel":@"whatsapp",
                                                         @"content":@"profile"
                                                         }];
            
            NSString *routeString = [NSString stringWithFormat:@"profile/%@",self.user.objectId];
            BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:self.user.objectId];
            BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
            linkProperties.feature = @"sharingProfile";
            linkProperties.channel = @"whatsapp";
            [linkProperties addControlParam:@"$deeplink_path" withValue:routeString];
            [linkProperties addControlParam:@"referrer" withValue:[PFUser currentUser].objectId];
            
            [buo getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString* url, NSError* error) {
                if (!error) {
                    NSLog(@"whatsapp link %@", url);
                    
                    NSString * msg = [NSString stringWithFormat:@"@%@ is on BUMP %@", self.user.username,url];
                    
                    msg = [msg stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                    msg = [msg stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"?" withString:@"%3F"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"," withString:@"%2C"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
                    
                    NSString * urlWhats = [NSString stringWithFormat:@"whatsapp://send?text=%@",msg];
                    NSURL * whatsappURL = [NSURL URLWithString:urlWhats];
                    
                    if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
                        [[UIApplication sharedApplication] openURL: whatsappURL];
                    }
                }
                else{
                    NSLog(@"error w/ whatsapp link %@", error);
                    [Answers logCustomEventWithName:@"Whatsapp Link Error"
                                   customAttributes:@{
                                                      @"link":@"profile"
                                                      }];
                    
                    NSString *urlString = [NSString stringWithFormat:@"https://sobump.com/p?profile=%@",self.user.username];
                    NSString * msg = [NSString stringWithFormat:@"@%@ is on BUMP %@", self.user.username,urlString];
                    
                    msg = [msg stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                    msg = [msg stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"?" withString:@"%3F"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"," withString:@"%2C"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
                    msg = [msg stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
                    
                    NSString * urlWhats = [NSString stringWithFormat:@"whatsapp://send?text=%@",msg];
                    NSURL * whatsappURL = [NSURL URLWithString:urlWhats];
                    
                    if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
                        [[UIApplication sharedApplication] openURL: whatsappURL];
                    }
                }
            }];
            

        }]];
        
        //Share on Messenger
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share on Messenger" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [Answers logCustomEventWithName:@"Shared on Messenger"
                           customAttributes:@{
                                              @"link":@"profile"
                                              }];
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Tapped Share" properties:@{
                                                         @"channel":@"messenger",
                                                         @"content":@"profile"
                                                         }];
            
            NSString *routeString = [NSString stringWithFormat:@"profile/%@",self.user.objectId];
            BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:self.user.objectId];
            BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
            linkProperties.feature = @"sharingProfile";
            linkProperties.channel = @"messenger";
            [linkProperties addControlParam:@"$deeplink_path" withValue:routeString];
            [linkProperties addControlParam:@"referrer" withValue:[PFUser currentUser].objectId];
            
            [buo getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString* url, NSError* error) {
                if (!error) {
                    NSLog(@"messenger share link %@", url);
                    NSString *urlString = [NSString stringWithFormat:@"fb-messenger://share/?link=%@",url];
                    NSURL *messengerURL = [NSURL URLWithString:urlString];
                    if ([[UIApplication sharedApplication] canOpenURL: messengerURL]) {
                        [[UIApplication sharedApplication] openURL: messengerURL];
                    }
                    
                }
                else{
                    [Answers logCustomEventWithName:@"Messenger Link Error"
                                   customAttributes:@{
                                                      @"link":@"forsale listing",
                                                      @"error":error.description
                                                      }];
                    NSString *urlString = [NSString stringWithFormat:@"fb-messenger://share/?link=https://sobump.com/p?profile=%@",self.user.username];
                    NSURL *messengerURL = [NSURL URLWithString:urlString];
                    if ([[UIApplication sharedApplication] canOpenURL: messengerURL]) {
                        [[UIApplication sharedApplication] openURL: messengerURL];
                    }
                }
            }];
        }]];
        
        //Copy Link
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Copy Profile Link" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [Answers logCustomEventWithName:@"Copied Link"
                           customAttributes:@{
                                              @"link":@"profile"
                                              }];
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Tapped Share" properties:@{
                                                         @"channel":@"link",
                                                         @"content":@"profile"
                                                         }];
            
            NSString *routeString = [NSString stringWithFormat:@"profile/%@",self.user.objectId];
            BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:self.user.objectId];
            BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
            linkProperties.feature = @"sharingProfile";
            linkProperties.channel = @"link";
            [linkProperties addControlParam:@"$deeplink_path" withValue:routeString];
            [linkProperties addControlParam:@"referrer" withValue:[PFUser currentUser].objectId];
            
            [buo getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString* url, NSError* error) {
                if (!error) {
                    NSLog(@"copied link %@", url);
                    [Answers logCustomEventWithName:@"Copied Link"
                                   customAttributes:@{
                                                      @"link":@"profile",
                                                      @"error":@NO
                                                      }];
                    
                    UIPasteboard *pb = [UIPasteboard generalPasteboard];
                    [pb setString:url];
                }
                else{
                    NSLog(@"error copying link %@", error);
                    [Answers logCustomEventWithName:@"Copied Link"
                                   customAttributes:@{
                                                      @"link":@"profile",
                                                      @"error":@YES
                                                      }];
                    
                    NSString *urlString = [NSString stringWithFormat:@"http://sobump.com/p?profile=%@",self.user.username];
                    UIPasteboard *pb = [UIPasteboard generalPasteboard];
                    [pb setString:urlString];
                }
            }];
            
            //show HUD
            [self showHUDWithLabel:@"Copied"];

            double delayInSeconds = 2.0; // number of seconds to wait
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self hideHUD];
            });
        }]];
        
        //General Share
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"More" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [Answers logCustomEventWithName:@"Shared Profile"
                           customAttributes:@{
                                              @"link":@"profile"
                                              }];
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Tapped Share" properties:@{
                                                         @"channel":@"more",
                                                         @"content":@"profile"
                                                         }];
            
            NSMutableArray *items = [NSMutableArray new];
            
            NSString *routeString = [NSString stringWithFormat:@"profile/%@",self.user.objectId];
            BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:self.user.objectId];
            BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
            linkProperties.feature = @"sharingProfile";
            linkProperties.channel = @"more";
            [linkProperties addControlParam:@"$deeplink_path" withValue:routeString];
            [linkProperties addControlParam:@"referrer" withValue:[PFUser currentUser].objectId];
            
            [buo getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString* url, NSError* error) {
                if (!error) {
                    NSLog(@"more link %@", url);
                    
                    [items addObject:[NSString stringWithFormat:@"@%@ is on BUMP  %@",self.user.username,url]];
                    UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
                    [self presentViewController:activityController animated:YES completion:nil];
                    
                    [activityController setCompletionWithItemsHandler:
                     ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                     }];
                    
                }
                else{
                    NSLog(@"error w/ more link %@", error);
                    [Answers logCustomEventWithName:@"More Share Link Error"
                                   customAttributes:@{
                                                      @"link":@"profile",
                                                      @"error":error.description
                                                      }];
                    
                    [items addObject:[NSString stringWithFormat:@"@%@ is on BUMP  https://sobump.com/p?profile=%@",self.user.username,self.user.username]];
                    UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
                    [self presentViewController:activityController animated:YES completion:nil];
                    
                    [activityController setCompletionWithItemsHandler:
                     ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                     }];
                }
            }];
        }]];
    }
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)enterBanComment{
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Reason"
                                          message:@"Why are you banning this user?\n\nYour reason will be sent to the user so please be polite and factual"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = @"e.g. Selling a Fake Supreme Bogo";
     }];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:@"Ban"
                               style:UIAlertActionStyleDestructive
                               handler:^(UIAlertAction *action)
                               {
                                   UITextField *reasonField = alertController.textFields.firstObject;
                                   
                                   BOOL acceptableString = YES;
                                   NSArray *profanityList = @[@"cunt", @"wanker", @"nigger", @"penis", @"cock", @"dick", @"fuck", @"fucking", @"shit", @"fucked"];
                                   
                                   for (NSString *badString in profanityList) {
                                       if ([reasonField.text.lowercaseString containsString:badString]) {
                                           acceptableString = NO;
                                           
                                           [Answers logCustomEventWithName:@"Mod Used bad language"
                                                          customAttributes:@{
                                                                             @"text":reasonField.text,
                                                                             @"mod":[PFUser currentUser].username,
                                                                             @"where":@"banning from profile"
                                                                             }];
                                       }
                                   }
                                   
                                   if (acceptableString == YES && reasonField.text.length > 5) {
                                       [self selectedReportReason:reasonField.text];
                                   }
                                   else{
                                       [self showAlertWithTitle:@"Enter Longer Reason" andMsg:nil];
                                   }
                               }];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                   }];
    
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)setupMessages{
    [self showHUDWithLabel:nil];

    //possible convoIDs
    NSString *possID = [NSString stringWithFormat:@"%@%@", [PFUser currentUser].objectId, self.user.objectId];
    NSString *otherId = [NSString stringWithFormat:@"%@%@",self.user.objectId,[PFUser currentUser].objectId];
    
    //split into sub queries to avoid the contains parameter which can't be indexed
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"convos"];
    [convoQuery whereKey:@"convoId" equalTo:possID];
    
    PFQuery *otherPossConvo = [PFQuery queryWithClassName:@"convos"];
    [otherPossConvo whereKey:@"convoId" equalTo:otherId];
    
    PFQuery *comboConvoQuery = [PFQuery orQueryWithSubqueries:@[convoQuery, otherPossConvo]];
    [comboConvoQuery whereKey:@"profileConvo" equalTo:@"YES"];
    [comboConvoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
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
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Created Convo" properties:@{
                                                          @"source":@"Profile"
                                                          }];
            
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
            
            ///extra fields for new inbox logic
            convoObject[@"buyerUsername"] = self.user.username;
            convoObject[@"buyerId"] = self.user.objectId;
            
            if ([self.user objectForKey:@"picture"]) {
                convoObject[@"buyerPicture"] = [self.user objectForKey:@"picture"];
            }
            
            convoObject[@"sellerUsername"] = [PFUser currentUser].username;
            convoObject[@"sellerId"] = [PFUser currentUser].objectId;
            
            if ([[PFUser currentUser] objectForKey:@"picture"]) {
                convoObject[@"sellerPicture"] = [[PFUser currentUser] objectForKey:@"picture"];
            }
            
            [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
//                    NSLog(@"saved new convo");
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

-(void)showHUDWithLabel:(NSString *)label{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    if (!label) {
        self.hud.customView = self.spinner;
        [self.spinner startAnimating];
    }
    else{
        self.hud.labelText = label;
    }
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.hud.labelText = @"";
        self.hud = nil;
    });
}

-(void)backPressed{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)setupHeaderBar:(myCompletion) block{
    int heightInt = 0;
    
    if (self.hasBio || self.tabMode) {
//        heightInt = 390;
        heightInt = 335;
    }
    else{
        //was 340
        heightInt = 285;
    }

    self.myBar = [[BLKFlexibleHeightBar alloc] initWithFrame:CGRectMake(0.0, 0.0, [UIApplication sharedApplication].keyWindow.frame.size.width,heightInt)]; //was 340
    self.myBar.backgroundColor = [UIColor whiteColor];
    self.myBar.behaviorDefiner = [SquareCashStyleBehaviorDefiner new];
    
    //snap to either top or bottom
    [self.myBar.behaviorDefiner addSnappingPositionProgress:0.0 forProgressRangeStart:0.0 end:0.5];
    [self.myBar.behaviorDefiner addSnappingPositionProgress:1.0 forProgressRangeStart:0.5 end:1.0];
    
    //create a splitter so collection view can respond to its own delegate methods AND flexibar can copy the CV's scroll view
    self.splitter = [[BLKDelegateSplitter alloc] initWithFirstDelegate:self secondDelegate:self.myBar.behaviorDefiner];
    
    self.collectionView.delegate = (id<UICollectionViewDelegate>)self.splitter;
    
    //int to adjust for larger iPhone X status bar 44pt now instead of 20pt). Second adjust is for the small version of the bar
    int adjust = 0;
    
    if (@available(iOS 11.0, *)) {
        
        if ([ [ UIScreen mainScreen ] bounds ].size.height == 812) {
            //iPhone X has a bigger status bar - was 20px now 44px so 24pt bigger
            adjust = 17; //was 120-
            self.myBar.minimumBarHeight = 120.0;
        }
        else{
            self.myBar.minimumBarHeight = 115.0;
        }
        self.collectionView.contentInset = UIEdgeInsetsMake(self.myBar.maximumBarHeight-[UIApplication sharedApplication].statusBarFrame.size.height, 0.0, 0.0, 0.0);
    }
    else{
        self.myBar.minimumBarHeight = 115.0;

        //seeing odd behaviour with collection view. Same sizes on iOS 10 & 11 but 11 has a larger top inset..
        self.collectionView.contentInset = UIEdgeInsetsMake(self.myBar.maximumBarHeight, 0.0, 0.0, 0.0);
    }
    
    //bg colour view
    self.bgView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.myBar.frame.size.width, 130)];
    self.bgView.backgroundColor = [UIColor colorWithRed:0.96 green:0.97 blue:0.99 alpha:1.0];
    [self.myBar addSubview:self.bgView];
    
    //profile image
    self.userImageView = [[PFImageView alloc]initWithFrame:CGRectMake(15, 100, 100, 100)];
    [self.userImageView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    [self setImageBorder:self.userImageView];
    [self.myBar addSubview:self.userImageView];
    
    //name & location
    if (self.smallScreen) {
        self.nameAndLoc = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160, 45)];
        self.nameAndLoc.font = [UIFont fontWithName:@"PingFangSC-Medium" size:12];
    }
    else{
        self.nameAndLoc = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 175, 45)];
        self.nameAndLoc.font = [UIFont fontWithName:@"PingFangSC-Medium" size:13];
    }
    
    self.nameAndLoc.numberOfLines = 2;
    self.nameAndLoc.textColor = [UIColor blackColor];
    self.nameAndLoc.textAlignment = NSTextAlignmentLeft;
    
    self.nameAndLoc.adjustsFontSizeToFitWidth = YES;
    self.nameAndLoc.minimumScaleFactor=0.5;
    
//    [self.nameAndLoc setBackgroundColor:[UIColor redColor]];
    
    //[self.nameAndLoc sizeToFit];
    [self.myBar addSubview:self.nameAndLoc];
    
    //top username
    self.usernameLabel = [[UILabel alloc] init];
    self.usernameLabel.numberOfLines = 1;
    self.usernameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
    self.usernameLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
    self.usernameLabel.textAlignment = NSTextAlignmentLeft;
    [self.myBar addSubview:self.usernameLabel];
    
    //verified with image view
    self.verifiedImageView = [[PFImageView alloc]initWithFrame:CGRectMake(0, 0, 50, 18)];
    [self.myBar addSubview:self.verifiedImageView];
    
    //add verification button
    if (self.tabMode) {
        self.moreVeriButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 18)];
        [self.moreVeriButton addTarget:self action:@selector(moreVeriPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.myBar addSubview:self.moreVeriButton];
    }
    
    //nav bar buttons
    
    //back button
    self.backButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 35, 35)];
    if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId] && self.tabMode == YES) {
        [self.backButton setImage:[UIImage imageNamed:@"profileCogNew"] forState:UIControlStateNormal];
        [self.backButton addTarget:self action:@selector(profileCogPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    else{
        [self.backButton setImage:[UIImage imageNamed:@"backArrowThinNew"] forState:UIControlStateNormal];
        [self.backButton addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];
        
    }
    [self.myBar addSubview:self.backButton];
    
    if (self.tabMode) {
//        self.ordersButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 35, 35)];
//        [self.ordersButton setImage:[UIImage imageNamed:@"ordersIcon2"] forState:UIControlStateNormal];
//        [self.ordersButton addTarget:self action:@selector(ordersButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//        [self.myBar addSubview:self.ordersButton];
        
        //change following buttong to the order button
        self.followButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 150, 28)];
        self.followButton.clipsToBounds = YES;
        
        [self setOrdersButton];
        
        self.followButton.showsTouchWhenHighlighted = NO;
        self.followButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:13];
        [self.followButton addTarget:self action:@selector(ordersButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.myBar addSubview:self.followButton];
    }
    else if(![self.user.objectId isEqualToString:[PFUser currentUser].objectId]){
        //don't show follow button on own profile
        self.followButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 150, 28)];
        self.followButton.clipsToBounds = YES;

        if (self.following) {
            [self setFollowingButton];
        }
        else{
            [self setFollowButton];
        }
        
        self.followButton.showsTouchWhenHighlighted = NO;
        self.followButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:13];
        [self.followButton addTarget:self action:@selector(followButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.myBar addSubview:self.followButton];
    }

    
    //facebook button
    self.FBButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 35, 35)];
    [self.FBButton setImage:[UIImage imageNamed:@"FBFillBlk1"] forState:UIControlStateNormal];
    [self.FBButton addTarget:self action:@selector(fbPressed) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.tabMode) {
        if ([[[PFUser currentUser] objectForKey:@"followingCount"]intValue] < 2000) {
            [self.myBar addSubview:self.FBButton]; //this turns into the discover button
        }
    }
    
    //dots button
    self.dotsButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.myBar addSubview:self.dotsButton];
    
    //stars image view
    self.starImageView = [[PFImageView alloc]initWithFrame:CGRectMake(0, 0, 93, 17)];
    [self.starImageView setImage:[UIImage imageNamed:@"emptyStars"]]; //placeholder
    [self.myBar addSubview:self.starImageView];
    
    //reviews button
    if (self.smallScreen) {
        self.reviewsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        self.reviewsButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:11];
    }
    else{
        self.reviewsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 30)];
        self.reviewsButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
    }
    
    self.reviewsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.reviewsButton addTarget:self action:@selector(ReviewsPressed) forControlEvents:UIControlEventTouchUpInside];
    self.reviewsButton.titleLabel.numberOfLines = 2;
//    [self.reviewsButton setBackgroundColor:[UIColor blueColor]];
    [self.myBar addSubview:self.reviewsButton];
    
    //followers button

    if (self.smallScreen) {
        self.followersButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        self.followersButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:11];
    }
    else{
        self.followersButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 30)];
        self.followersButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
    }
    
    self.followersButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.followersButton addTarget:self action:@selector(followersPressed) forControlEvents:UIControlEventTouchUpInside];
    self.followersButton.titleLabel.numberOfLines = 2;
//    [self.followersButton setBackgroundColor:[UIColor redColor]];
    [self.myBar addSubview:self.followersButton];
    
    //following
    if (self.smallScreen) {
        self.followingButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0,60, 30)]; //review/followers/following labels are separated by their width not dead spacing
        self.followingButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:11];
    }
    else{
        self.followingButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0,70, 30)];
        self.followingButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
    }
    
    self.followingButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.followingButton addTarget:self action:@selector(followingPressed) forControlEvents:UIControlEventTouchUpInside];
    self.followingButton.titleLabel.numberOfLines = 2;
//    [self.followingButton setBackgroundColor:[UIColor greenColor]];
    [self.myBar addSubview:self.followingButton];
    
    //////////
    //views for when bar collapses
    
    //small imageview
    self.smallImageView = [[PFImageView alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.smallImageView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    [self setImageBorder:self.smallImageView];
    [self.myBar addSubview:self.smallImageView];
    
    //small name / loc label
    self.smallNameAndLoc = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
    
    if (self.smallScreen) {
        [self.smallNameAndLoc setFrame:CGRectMake(0, 0, 90, 30)];
    }
    
    self.smallNameAndLoc.numberOfLines = 2;
    self.smallNameAndLoc.font = [UIFont fontWithName:@"PingFangSC-Medium" size:10];
    self.smallNameAndLoc.textColor = [UIColor blackColor];
    self.smallNameAndLoc.textAlignment = NSTextAlignmentLeft;
    [self.myBar addSubview:self.smallNameAndLoc];
    
    [self.view addSubview:self.myBar];
    
    //setup subviews then add specific y values depending on if user has a bio
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributes = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributes.size = self.userImageView.frame.size;
    
    //this causes user's username to be added to the label & the width calculated before locking in the frame for the header bar
    block(YES);
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesUsernameLabel = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesUsernameLabel.size = self.usernameLabel.frame.size;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesStarView = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesStarView.size = self.starImageView.frame.size;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesVerifiedImageView = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesVerifiedImageView.size = self.verifiedImageView.frame.size;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesVeriButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesVeriButton.size = self.moreVeriButton.frame.size;
    
    if (self.hasBio || self.tabMode) {
        //setup bar subviews with additional space for bio
        
        //bio label
        self.bioLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 30)];
        self.bioLabel.numberOfLines = 2;
        self.bioLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
        self.bioLabel.textAlignment = NSTextAlignmentLeft;
        self.bioLabel.textColor = [UIColor lightGrayColor];
        
//        [self.bioLabel setBackgroundColor:[UIColor greenColor]];

        [self.myBar addSubview:self.bioLabel];
        
        //set bio upon start (also in fetch for if user updates)
        if ([self.user objectForKey:@"bio"]) {
            if (![[self.user objectForKey:@"bio"]isEqualToString:@""]) {
                self.bioLabel.text = [self.user objectForKey:@"bio"];

            }
            else{
                //put this check in, incase user had a bio but then deleted it
                self.bioLabel.text = @"Tap to add a bio and let buyers know more about you";
            }
        }
        else{
            //fail safe
            self.bioLabel.text = @"Tap to add a bio and let buyers know more about you";
        }
        
        //onky add button for user's own page
        if (self.tabMode) {
            self.addBioButton = [[UIButton alloc]initWithFrame:self.bioLabel.frame];
            [self.addBioButton addTarget:self action:@selector(addBioTapped) forControlEvents:UIControlEventTouchUpInside];
            [self.myBar addSubview:self.addBioButton];
        }
        
        //bio label
        BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesBioLabel = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
        initialLayoutAttributesBioLabel.size = self.bioLabel.frame.size;
        initialLayoutAttributesBioLabel.frame = CGRectMake(15, 80 + self.userImageView.frame.size.height + 5 + self.nameAndLoc.frame.size.height, [UIApplication sharedApplication].keyWindow.frame.size.width - 30, 50);
        
        [self.bioLabel addLayoutAttributes:initialLayoutAttributesBioLabel forProgress:0.0];
        
        //bio label final
        BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesBio = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesBioLabel];
        finalLayoutAttributesBio.alpha = 0.0;
        [self.bioLabel addLayoutAttributes:finalLayoutAttributesBio forProgress:0.1];
        
        //bio button
        BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesBioButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
        initialLayoutAttributesBioButton.size = self.addBioButton.frame.size;
        initialLayoutAttributesBioButton.frame = CGRectMake(15,80 + self.userImageView.frame.size.height + 5 + self.nameAndLoc.frame.size.height, [UIApplication sharedApplication].keyWindow.frame.size.width - 20, 60);
        [self.addBioButton addLayoutAttributes:initialLayoutAttributesBioButton forProgress:0.0];
        
        //bio button final
        BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesBioButton = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesBioButton];
        finalLayoutAttributesBioButton.alpha = 0.0;
        [self.addBioButton addLayoutAttributes:finalLayoutAttributesBio forProgress:0.1];
    }
    else{
        //normal bar height without bio
    }
    
    //image view
    initialLayoutAttributes.frame = CGRectMake(10, 80, 100, 100);
    
    //top username label
    initialLayoutAttributesUsernameLabel.frame = CGRectMake(self.userImageView.frame.origin.x + self.userImageView.frame.size.width + 5, 130 - (17 + 15 +self.usernameLabel.frame.size.height),self.usernameLabel.frame.size.width,self.usernameLabel.frame.size.height);
    
    //verified image view
    initialLayoutAttributesVerifiedImageView.frame = CGRectMake(self.userImageView.frame.origin.x + self.userImageView.frame.size.width + 20 + self.starImageView.frame.size.width, 130 - (17 + 10 + 1), self.verifiedImageView.frame.size.width, self.verifiedImageView.frame.size.height);
    
    //verify button
    initialLayoutAttributesVeriButton.frame = CGRectMake(self.userImageView.frame.origin.x + self.userImageView.frame.size.width + 20 + self.starImageView.frame.size.width,130 - (17 + 10 + 1), self.verifiedImageView.frame.size.width, self.verifiedImageView.frame.size.height);
    
    //stars view
    initialLayoutAttributesStarView.frame = CGRectMake(self.userImageView.frame.origin.x + self.userImageView.frame.size.width + 5, 130 - (17 + 10), 93, 17);
    
    //reviews button
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesReviews = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesReviews.size = self.reviewsButton.frame.size;
    initialLayoutAttributesReviews.frame = CGRectMake(self.userImageView.frame.origin.x + self.userImageView.frame.size.width + 5, 140,self.reviewsButton.frame.size.width,self.reviewsButton.frame.size.height);
    
    //followers button
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesFollowers = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesFollowers.size = self.followersButton.frame.size;
    
    if (self.smallScreen) {
        initialLayoutAttributesFollowers.frame = CGRectMake(self.userImageView.frame.origin.x + self.userImageView.frame.size.width + 5 + self.reviewsButton.frame.size.width,140 ,self.followersButton.frame.size.width,self.followersButton.frame.size.height);
    }
    else{
        initialLayoutAttributesFollowers.frame = CGRectMake(self.userImageView.frame.origin.x + self.userImageView.frame.size.width + 85,140 ,self.followersButton.frame.size.width,self.followersButton.frame.size.height);
    }
    
    //following button
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesFollowing = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesFollowing.size = self.followingButton.frame.size;
    
    if (self.smallScreen) {
        initialLayoutAttributesFollowing.frame = CGRectMake(self.userImageView.frame.origin.x + self.userImageView.frame.size.width + 125,140,self.followersButton.frame.size.width,self.followersButton.frame.size.height);
    }
    else{
        initialLayoutAttributesFollowing.frame = CGRectMake(self.userImageView.frame.origin.x + self.userImageView.frame.size.width + 165,140,self.followersButton.frame.size.width,self.followersButton.frame.size.height);
    }
    
    //THE follow/unfollow button
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesFollowButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesFollowButton.size = self.followButton.frame.size;
    
    if (self.smallScreen) {
        initialLayoutAttributesFollowButton.frame = CGRectMake(self.userImageView.frame.origin.x + self.userImageView.frame.size.width + 5 + self.reviewsButton.frame.size.width,80 + self.userImageView.frame.size.height + 5 + 8.5 ,115,28);
    }
    else{//its 87 coz we're 5 short of the height of nameandloc label
        initialLayoutAttributesFollowButton.frame = CGRectMake(self.userImageView.frame.origin.x + self.userImageView.frame.size.width + 87.5, 80 + self.userImageView.frame.size.height + 5 + 8.5,150,28);
    }
    [self.followButton addLayoutAttributes:initialLayoutAttributesFollowButton forProgress:0.0];

    //bg view
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialBgView = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialBgView.frame = self.bgView.frame;
    [self.bgView addLayoutAttributes:initialBgView forProgress:0.0];
    
    //small image view
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesSmallImage = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesSmallImage.size = self.smallImageView.frame.size;
    initialLayoutAttributesSmallImage.frame = CGRectMake(100, 25 + adjust, 30, 30);
    initialLayoutAttributesSmallImage.alpha = 0.0f;
    [self.smallImageView addLayoutAttributes:initialLayoutAttributesSmallImage forProgress:0.0];
    
    //small username /loc view
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesSmallName = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesSmallName.size = self.smallNameAndLoc.frame.size;
    initialLayoutAttributesSmallName.frame = CGRectMake(135, 25 + adjust, self.smallNameAndLoc.frame.size.width, 30);
    initialLayoutAttributesSmallName.alpha = 0.0f;
    [self.smallNameAndLoc addLayoutAttributes:initialLayoutAttributesSmallName forProgress:0.0];
    
    //name & loc label
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesLabel = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesLabel.size = self.nameAndLoc.frame.size;
    initialLayoutAttributesLabel.frame = CGRectMake(15,80 + self.userImageView.frame.size.height + 5, self.nameAndLoc.frame.size.width, self.nameAndLoc.frame.size.height);
    
    //back button
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesBackButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesBackButton.size = self.backButton.frame.size;
    initialLayoutAttributesBackButton.frame = CGRectMake(5, 20 + adjust, 35, 35); //minus 5 off y due to new height
    
    //fb button
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesfbButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesfbButton.size = self.FBButton.frame.size;
    initialLayoutAttributesfbButton.frame = CGRectMake([UIApplication sharedApplication].keyWindow.frame.size.width-80, 20 + adjust, 35, 35);
    
    //dots button
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesDotsButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesDotsButton.size = self.dotsButton.frame.size;
    initialLayoutAttributesDotsButton.frame = CGRectMake([UIApplication sharedApplication].keyWindow.frame.size.width-40, 25 + adjust, 30, 30);
    
    //orders button
//    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesOrdersButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
//    initialLayoutAttributesOrdersButton.size = self.ordersButton.frame.size;
//    initialLayoutAttributesOrdersButton.frame = CGRectMake(50, 20 + adjust, 35, 35); //minus 5 off x value and y due to new frame
    
    // This is what we want the bar to look like at its maximum height (progress == 0.0)
    [self.userImageView addLayoutAttributes:initialLayoutAttributes forProgress:0.0];
    [self.nameAndLoc addLayoutAttributes:initialLayoutAttributesLabel forProgress:0.0];
    
    [self.usernameLabel addLayoutAttributes:initialLayoutAttributesUsernameLabel forProgress:0.0];

    [self.verifiedImageView addLayoutAttributes:initialLayoutAttributesVerifiedImageView forProgress:0.0];
    [self.moreVeriButton addLayoutAttributes:initialLayoutAttributesVeriButton forProgress:0.0];

    [self.starImageView addLayoutAttributes:initialLayoutAttributesStarView forProgress:0.0];
    
    [self.reviewsButton addLayoutAttributes:initialLayoutAttributesReviews forProgress:0.0];
    [self.followingButton addLayoutAttributes:initialLayoutAttributesFollowing forProgress:0.0];
    [self.followersButton addLayoutAttributes:initialLayoutAttributesFollowers forProgress:0.0];
    
    [self.backButton addLayoutAttributes:initialLayoutAttributesBackButton forProgress:0.0];
    [self.FBButton addLayoutAttributes:initialLayoutAttributesfbButton forProgress:0.0];
    [self.dotsButton addLayoutAttributes:initialLayoutAttributesDotsButton forProgress:0.0];
    
//    [self.ordersButton addLayoutAttributes:initialLayoutAttributesOrdersButton forProgress:0.0];
    
    // small mode
    
    //bg view
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalBgAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialBgView];
    finalBgAttributes.alpha = 0.0;
    [self.bgView addLayoutAttributes:finalBgAttributes forProgress:0.4];
    
    // image view final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributes];
    finalLayoutAttributes.alpha = 0.0;
    //CGAffineTransform translation = CGAffineTransformMakeTranslation(0.0, -30.0);
    //CGAffineTransform scale = CGAffineTransformMakeScale(0.2, 0.2);
    //finalLayoutAttributes.transform = CGAffineTransformConcat(scale, translation);
    // This is what we want the bar to look like at its minimum height (progress == 1.0)
    [self.userImageView addLayoutAttributes:finalLayoutAttributes forProgress:0.3];
    
    // top username final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesUsername = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesUsernameLabel];
    finalLayoutAttributesUsername.alpha = 0.0;
    [self.usernameLabel addLayoutAttributes:finalLayoutAttributesUsername forProgress:0.5];
    
    //verified img view final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesVerifiedImageView = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesVerifiedImageView];
    finalLayoutAttributesVerifiedImageView.alpha = 0.0;
    [self.verifiedImageView addLayoutAttributes:finalLayoutAttributesVerifiedImageView forProgress:0.4];
    
    //veri button
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesVeriButton = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesVeriButton];
    finalLayoutAttributesVeriButton.alpha = 0.0;
    [self.moreVeriButton addLayoutAttributes:finalLayoutAttributesVeriButton forProgress:0.4];
    
    // star view final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesStar = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesStarView];
    finalLayoutAttributesStar.alpha = 0.0;
    [self.starImageView addLayoutAttributes:finalLayoutAttributesStar forProgress:0.4];
    
    // reviews label final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesReviewLabel = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesReviews];
    finalLayoutAttributesReviewLabel.alpha = 0.0;
    [self.reviewsButton addLayoutAttributes:finalLayoutAttributesReviewLabel forProgress:0.3];
    
    // following label final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesFollowing = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesFollowing];
    finalLayoutAttributesFollowing.alpha = 0.0;
    [self.followingButton addLayoutAttributes:finalLayoutAttributesFollowing forProgress:0.3];
    
    // followers label final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesFollowers = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesFollowers];
    finalLayoutAttributesFollowers.alpha = 0.0;
    [self.followersButton addLayoutAttributes:finalLayoutAttributesFollowers forProgress:0.3];
    
    // name label final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesNameLabel = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesLabel];
    finalLayoutAttributesNameLabel.alpha = 0.0;
    [self.nameAndLoc addLayoutAttributes:finalLayoutAttributesNameLabel forProgress:0.1];
    
    //follow button
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesFollowButton = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesFollowButton];
    finalLayoutAttributesFollowButton.alpha = 0.0;
    [self.followButton addLayoutAttributes:finalLayoutAttributesFollowButton forProgress:0.3];
    
    // small username label final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesSmallLabel = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesSmallName];
    finalLayoutAttributesSmallLabel.alpha = 1.0;
    [self.smallNameAndLoc addLayoutAttributes:finalLayoutAttributesSmallLabel forProgress:0.6];
    
    // small image final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesSmallImage = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesSmallImage];
    finalLayoutAttributesSmallImage.alpha = 1.0;
    [self.smallImageView addLayoutAttributes:finalLayoutAttributesSmallImage forProgress:0.6];
    
    if (self.tabMode) {
        //profile image button
        self.imageButton = [[UIButton alloc]initWithFrame:CGRectMake(15, 100, 100, 100)];
        [self.imageButton addTarget:self action:@selector(profileImagePressed) forControlEvents:UIControlEventTouchUpInside];
        [self.myBar addSubview:self.imageButton];
        
        //image button initial
        BLKFlexibleHeightBarSubviewLayoutAttributes *initialImageButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
        initialImageButton.frame = CGRectMake(10, 80, 100, 100);
        initialImageButton.size = self.imageButton.frame.size;
        [self.imageButton addLayoutAttributes:initialImageButton forProgress:0.0];
        
        // image button final
        BLKFlexibleHeightBarSubviewLayoutAttributes *finalImageButtonAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialImageButton];
        finalImageButtonAttributes.alpha = 0.0;
        [self.imageButton addLayoutAttributes:finalImageButtonAttributes forProgress:0.3];
    }
    
    if (self.tabMode){
        //finish on this so we can update button images if any unread upon first tap on user's profile
        [self calcTabBadge];
    }
    
    NSLog(@"finished setup header");
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
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Change Profile Picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
    [self showHUDWithLabel:nil];
//    UIImage *imageToSave = [self.profileImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(750.0, 750.0) interpolationQuality:kCGInterpolationHigh];
    UIImage *imageToSave = [self.profileImage scaleImageToSize:CGSizeMake(400, 400)];

    NSData* data = UIImageJPEGRepresentation(imageToSave, 0.7f);
    if (data == nil) {
        NSLog(@"error with data");
        [self hideHUD];
        [picker dismissViewControllerAnimated:YES completion:nil];
        [self showAlertWithTitle:@"Image Error" andMsg:@"Woops, something went wrong. Please try again! If this keeps happening please message Support from Settings"];
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
//                        NSLog(@"saved!");
                        [self hideHUD];
                        
                        [self updateConvoImages];
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
                [Answers logCustomEventWithName:@"Error saving profile PFFile"
                               customAttributes:@{
                                                  @"where":@"Profile"
                                                  }];
            }
        }];
        [picker dismissViewControllerAnimated:YES completion:nil];
    }

}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)profileCogPressed{
    ProfileController *profile = [[ProfileController alloc]init];
    profile.modal = NO;
    profile.delegate = self;
    
    if (self.messagesUnseen > 0) {
        profile.unseenTBMsg = YES;
    }
    
    [self.navigationController pushViewController:profile animated:YES];
}

-(void)newTBMessage{
    [self calcTabBadge];
}

-(void)newTBMessageReg{
    self.messagesUnseen = 1;
    [self.backButton setImage:[UIImage imageNamed:@"profileCogUnreadNew"] forState:UIControlStateNormal];
}

-(void)TeamBumpInboxTapped{
    self.messagesUnseen = 0;
    
    [self calcTabBadge];
//    if (self.supportUnseen == 0) {
//        [self.backButton setImage:[UIImage imageNamed:@"profileCog"] forState:UIControlStateNormal];
//        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
//    }
}

-(void)supportTapped{
    self.supportUnseen = 0;

    [self calcTabBadge];
    
//    if (self.messagesUnseen == 0) {
//        [self.backButton setImage:[UIImage imageNamed:@"profileCog"] forState:UIControlStateNormal];
//        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
//    }
}

- (IBAction)createPressed:(id)sender {
    [self.tabBarController setSelectedIndex:2];
//    double delayInSeconds = 0.5;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        if (self.segmentedControl.selectedSegmentIndex == 0){
//            //selling
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"openSell" object:nil];
//        }
//        else if (self.segmentedControl.selectedSegmentIndex == 1){
//            //wanted
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"openWTB" object:nil];
//        }
//    });
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if (self.banMode) {
            self.banMode = NO;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    //this is received by home tab to make sure search bar doesn't disappear if user is on a profile
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ensureNavShowing" object:nil];
}

-(void)moreVeriPressed{
    if (self.needsFB != YES && self.needsEmail != YES) {
        return;
    }

    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    if (self.needsFB == YES) {
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Connect Facebook Account" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self linkFacebookToUser];
        }]];
    }
    
    if (self.needsEmail == YES){
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Verify Email Address" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self verifyEmail];
        }]];
    }
    
    [self presentViewController:actionSheet animated:YES completion:nil];

}

-(void)linkFacebookToUser{

    if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [PFFacebookUtils linkUserInBackground:[PFUser currentUser] withPublishPermissions:@[] block:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                NSLog(@"linked now!");
                [Answers logCustomEventWithName:@"Successfully Linked Facebook Account"
                               customAttributes:@{}];
                
                if ([PFUser currentUser]) {
                    [self retrieveFacebookData];
                }
            }
            else{
                NSLog(@"not linked! %@", error);
                
                if (error) {
                    [Answers logCustomEventWithName:@"Failed to Link Facebook Account"
                                   customAttributes:@{}];
                    
                    [self showAlertWithTitle:@"Linking Error" andMsg:@"You may have already signed up for BUMP with your Facebook account\n\nSend Support a message from Settings and we'll get it sorted!"];
                }
            }
        }];
    }
    else{
        [Answers logCustomEventWithName:@"Already Linked Facebook Account"
                       customAttributes:@{}];
        
        NSLog(@"is already linked!");
        if ([PFUser currentUser]) {
            [self retrieveFacebookData];
        }
    }
}

-(void)retrieveFacebookData{
    
    //change verified image
//    self.FBButton.alpha = 0.0;
//    [self.myBar addSubview:self.FBButton];
//
//    [UIView animateWithDuration:0.3
//                          delay:0
//                        options:UIViewAnimationOptionCurveEaseIn
//                     animations:^{
//                         self.FBButton.alpha = 1.0;
//                     }
//                     completion:nil];
    
    [UIView transitionWithView:self.verifiedImageView
                      duration:0.3f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.verifiedImageView.image = [UIImage imageNamed:@"bothVeri"];
                    } completion:nil];
    
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setValue:@"id,gender,picture" forKey:@"fields"];
    
    //get FacebookId
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:parameters]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                  id result, NSError *error) {
         if (error == nil)
         {
             NSDictionary *userData = (NSDictionary *)result;
             
             if ([userData objectForKey:@"gender"]) {
                 [[PFUser currentUser] setObject:[userData objectForKey:@"gender"] forKey:@"gender"];
             }
             
             if ([userData objectForKey:@"id"]) {
                 [[PFUser currentUser] setObject:[userData objectForKey:@"id"] forKey:@"facebookId"];
                 [[PFUser currentUser]saveInBackground];
                 
                 //create bumped object so can know when friends create listings
                 PFObject *bumpedObj = [PFObject objectWithClassName:@"Bumped"];
                 [bumpedObj setObject:[userData objectForKey:@"id"] forKey:@"facebookId"];
                 [bumpedObj setObject:self.user forKey:@"user"];
                 [bumpedObj setObject:@"live" forKey:@"status"];
                 [bumpedObj setObject:[NSDate date] forKey:@"safeDate"];
                 [bumpedObj setObject:@0 forKey:@"timesBumped"];
                 [bumpedObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                     if (succeeded) {
                         NSLog(@"saved bumped obj");
                     }
                 }];
             }
             
             //if user doesn't have a profile picture, set their fb one
             if (![[PFUser currentUser]objectForKey:@"picture"]) {
                 if ([userData objectForKey:@"picture"]) {
                     NSString *userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", userData[@"id"]];
                     NSURL *picUrl = [NSURL URLWithString:userImageURL];
                     NSData *picData = [NSData dataWithContentsOfURL:picUrl];
                     
                     //save image
                     if (picData == nil) {
                         
                         [Answers logCustomEventWithName:@"PFFile Nil Data"
                                        customAttributes:@{
                                                           @"pageName":@"Adding FB pic after linking in Profile"
                                                           }];
                     }
                     else{
                         PFFile *picFile = [PFFile fileWithData:picData];
                         [picFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                             if (succeeded) {
                                 [self.userImageView setFile:picFile];
                                 [self.userImageView loadInBackground];
                                 
                                 [PFUser currentUser] [@"picture"] = picFile;
                                 [[PFUser currentUser] saveInBackground];
                             }
                             else{
                                 NSLog(@"error saving new facebook pic");
                             }
                         }];
                     }
                 }
             }
         }
         else{
             NSLog(@"error connecting facebook %@", error);
         }
     }];
    
    //get friends
    FBSDKGraphRequest *friendRequest = [[FBSDKGraphRequest alloc]
                                        initWithGraphPath:@"me/friends/?limit=5000"
                                        parameters:@{@"fields": @"id, name"}
                                        HTTPMethod:@"GET"];
    [friendRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                                id result,
                                                NSError *error) {
        // Handle the result
        if (!error) {
            NSArray* friends = [result objectForKey:@"data"];
            NSLog(@"Found: %lu friends with bump installed", (unsigned long)friends.count);
            NSMutableArray *friendsHoldingArray = [NSMutableArray array];
            
            for (NSDictionary *friend in friends) {
                [friendsHoldingArray addObject:[friend objectForKey:@"id"]];
            }
            
            if (friendsHoldingArray.count > 0) {
                [[PFUser currentUser]setObject:friendsHoldingArray forKey:@"friends"];
                [[PFUser currentUser] saveInBackground];
            }
        }
        else{
            NSLog(@"error on friends %li", (long)error.code);
        }
    }];
}

-(void)verifyEmail{
    //check if safe to allow user to send confirmation email
    if ([[PFUser currentUser]objectForKey:@"nextEmailSafeDate"]) {
        
        NSDate *safeDate = [[PFUser currentUser]objectForKey:@"nextEmailSafeDate"];
        
        if ([safeDate compare:[NSDate date]]==NSOrderedDescending) {
            //too early
            [Answers logCustomEventWithName:@"Requested Verification Email Again Too Soon"
                           customAttributes:@{}];
            
            NSLog(@"too early to send another email");
            [self showEarlyAlert];
        }
        else{
            //date is okay to request another
            NSLog(@"date is okay");

            //check what user email count is
            if ([[[PFUser currentUser]objectForKey:@"emailsCount"]intValue] < 3) {
                NSLog(@"okay to send another email");
                [self showVerifyEmailAlert];
            }
            else{
                NSLog(@"had too many sent!");
                [Answers logCustomEventWithName:@"Sent max verification emails"
                               customAttributes:@{}];
                
                [self showMaxAlert];
            }
        }
    }
    else{
        //cool to resend, never resent before
        NSLog(@"this is first send");
        [self showVerifyEmailAlert];
        
    }
}

-(void)showEarlyAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Verify Email" message:@"We've just sent you a confirmation email! Be sure to check your Junk Folder for an email from BUMP Customer Service\n\nIf you still can't find it, make sure your email is correct in settings then try again here in 5 mins so we can send another!\n\nPs the Gmail app doesn't like links! Try opening the email in the native iPhone Mail app" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Change email" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        [Answers logCustomEventWithName:@"Change Email Pressed from Early Email Alert"
                       customAttributes:@{}];
        
        SettingsController *vc = [[SettingsController alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showMaxAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Verify Email" message:@"We've already sent you 3 confirmation emails!\n\nCheck your information in Settings to ensure you've entered the correct email address. Also be sure to check your Junk Folder for an email from BUMP Customer Service. If you still can't find it, send Support an email hello@sobump.com\n\nPs the Gmail app doesn't like links! Try opening the email in the native iPhone Mail app" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showVerifyEmailAlert{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Verify Email" message:[NSString stringWithFormat:@"We'll send an email with a verification link to '%@'\n\nIf this is correct, hit send! Or you can change your email address in Settings\n\nRemember to check your Junk Folder!\n\nPs the Gmail app doesn't like links! Try opening the email in the native iPhone Mail app ",[[PFUser currentUser]objectForKey:@"email"]] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Send Confirmation Email" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        if ([[PFUser currentUser]objectForKey:@"email"]) {
            NSDictionary *params = @{@"toEmail": [[PFUser currentUser]objectForKey:@"email"]};
            [PFCloud callFunctionInBackground:@"sendConfirmEmail" withParameters:params block:^(NSDictionary *response, NSError *error) {
                if (!error) {
                    NSLog(@"email response %@", response);
                    
                    [self showAlertWithTitle:@"Email Sent" andMsg:@"Remember to check your Junk Folder!"];
                    
                    //increment confirmation email number count (max. = 3)
                    [[PFUser currentUser]incrementKey:@"emailsCount"];
                    
                    int count = [[[PFUser currentUser]objectForKey:@"emailsCount"]intValue];
                    
                    [Answers logCustomEventWithName:@"Sent Confirmation Email"
                                   customAttributes:@{
                                                      @"userCount":[NSNumber numberWithInt:count]
                                                      }];
                    
                    //next safe date to send email
                    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
                    dayComponent.minute = 5;
                    NSCalendar *theCalendar = [NSCalendar currentCalendar];
                    NSDate *safeDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
                    [[PFUser currentUser]setObject:safeDate forKey:@"nextEmailSafeDate"];
                    [[PFUser currentUser]saveInBackground];
                }
                else{
                    NSLog(@"email error %@", error);
                    
                    [Answers logCustomEventWithName:@"Error Sending Confirmation Email from Profile"
                                   customAttributes:@{}];
                    
                    [self showAlertWithTitle:@"Error 301" andMsg:@"There was a problem sending your confirmation email, make sure you're connected to the internet and try again!"];
                }
            }];
        }
        else{
            [self showAlertWithTitle:@"Add an email" andMsg:@"Make sure you've added an email address in Settings!"];
        }

    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)refreshVeri{
    //check how user is verified
    if ([self.user objectForKey:@"facebookId"] && [[self.user objectForKey:@"emailIsVerified"]boolValue] == YES) {
        [self.verifiedImageView setImage:[UIImage imageNamed:@"bothVeri"]];
        
        if (!self.tabMode) {
            [self.myBar addSubview:self.FBButton];
        }
        
        self.needsFB = NO;
        self.needsEmail = NO;
        
    }
    else if ([self.user objectForKey:@"facebookId"] && [[self.user objectForKey:@"emailIsVerified"]boolValue] != YES ) {

        if (!self.tabMode) {
            [self.myBar addSubview:self.FBButton];
        }
        
        if (self.tabMode) {
            
            self.needsEmail = YES;
            self.needsFB = NO;
            
            [self.verifiedImageView setImage:[UIImage imageNamed:@"veriAddEmail"]];
        }
        else{
            [self.verifiedImageView setImage:[UIImage imageNamed:@"fbVeri"]];
        }
    }
    else if ([[self.user objectForKey:@"emailIsVerified"]boolValue] == YES && ![self.user objectForKey:@"facebookId"]) {
        if (self.tabMode) {
            
            self.needsFB = YES;
            self.needsEmail = NO;
            
            [self.verifiedImageView setImage:[UIImage imageNamed:@"veriAddFB"]];
        }
        else{
            [self.verifiedImageView setImage:[UIImage imageNamed:@"emailVeri"]];
        }
    }
    else{
        //email not verified & fb acc not connected, awaiting confirmation email to be tapped!
        if (self.tabMode) {
            
            self.needsEmail = YES;
            self.needsFB = YES;
            
            [self.verifiedImageView setImage:[UIImage imageNamed:@"veriPendingEmail"]];
        }
        else{
            [self.verifiedImageView setImage:[UIImage imageNamed:@"emailPending"]];
        }
    }
}

#pragma mark - add picture drop down delegates

-(void)showAddPicView{
    [Answers logCustomEventWithName:@"Add Pic Drop Down Showing"
                   customAttributes:@{
                                      @"where": @"profile"
                                      }];
    
    if (self.alertShowing == YES) {
        return;
    }
    
    self.alertShowing = YES;
    self.dropDownBgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.dropDownBgView.alpha = 0.0;
    [self.dropDownBgView setBackgroundColor:[UIColor blackColor]];
    [[UIApplication sharedApplication].keyWindow addSubview:self.dropDownBgView];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.dropDownBgView.alpha = 0.6f;
                     }
                     completion:nil];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"engagementView" owner:self options:nil];
    self.addPicView = (engageTracker *)[nib objectAtIndex:0];
    self.addPicView.delegate = self;

    [self.addPicView setFrame:CGRectMake(([UIApplication sharedApplication].keyWindow.frame.size.width/2)-150, -300, 300, 290)];
    
    self.addPicView.layer.cornerRadius = 10;
    self.addPicView.layer.masksToBounds = YES;
    
    [self.addPicView.paypalImageView setHidden:YES];
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.addPicView];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
//                            [self.addPicView setFrame:CGRectMake(0, 0, 300, 290)];
                            self.addPicView.center = [UIApplication sharedApplication].keyWindow.center;
                        }
                     completion:^(BOOL finished) {
                         [self.dropDownBgView addGestureRecognizer:self.tap];
                     }];
}

-(void)hideAddPicView{
    [self.user setObject:@"YES" forKey:@"addPicPromptSeen"];
    [self.user saveInBackground];

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.dropDownBgView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         self.dropDownBgView = nil;
                         [self.dropDownBgView removeGestureRecognizer:self.tap];
                     }];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            [self.addPicView setFrame:CGRectMake((self.view.frame.size.width/2)-150, 1000, 300, 290)];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         self.alertShowing = NO;
                         [self.addPicView setAlpha:0.0];
                         self.addPicView = nil;
                     }];
}

-(void)addImagePressed{
    [self hideAddPicView];
    
    if (!self.picker) {
        self.picker = [[UIImagePickerController alloc] init];
        self.picker.delegate = self;
        self.picker.allowsEditing = NO;
        self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    [self presentViewController:self.picker animated:YES completion:nil];
}

#pragma mark - filter delegates (for big sellers only)

- (IBAction)filterPressed:(id)sender {
    [Answers logCustomEventWithName:@"Filters pressed"
                   customAttributes:@{
                                      @"page":@"User Profile"
                                      }];
    FilterVC *vc = [[FilterVC alloc]init];
    vc.delegate = self;
    vc.sellingSearch = NO;
    vc.profileSearch = YES;
    vc.currencySymbol = self.currencySymbol;
    if (self.filtersArray.count > 0) {
        vc.sendArray = [NSMutableArray arrayWithArray:self.filtersArray];
        
        vc.filterLower = self.filterLower;
        vc.filterUpper = self.filterUpper;
    }
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)filtersReturned:(NSMutableArray *)filters withSizesArray:(NSMutableArray *)sizes andBrandsArray:(NSMutableArray *)brands andColours:(NSMutableArray *)colours andCategories:(NSString *)category andPricLower:(float)lower andPriceUpper:(float)upper andContinents:(NSMutableArray *)continents{
    [self.forSaleArray removeAllObjects];
    [self.collectionView reloadData];
    
    self.filtersArray = filters;
    if (self.filtersArray.count > 0) {
        self.filterSizesArray = sizes;
        self.filterBrandsArray = brands;
        self.filterColoursArray = colours;
        self.filterCategory = category;
        self.filterUpper = upper;
        self.filterLower = lower;
        self.filterContinentsArray = continents;
        
        //change colour of filter number
        NSMutableAttributedString *filterString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"F I L T E R  %lu",self.filtersArray.count]];
        [self modifyString:filterString setColorForText:[NSString stringWithFormat:@"%lu",self.filtersArray.count] withColor:[UIColor colorWithRed:0.31 green:0.89 blue:0.76 alpha:1.0]];
        [self.filterButton setAttributedTitle:filterString forState:UIControlStateNormal];
        
    }
    else{
        //no filters
        NSMutableAttributedString *filterString = [[NSMutableAttributedString alloc] initWithString:@"F I L T E R"];
        [self.filterButton setAttributedTitle:filterString forState:UIControlStateNormal];
        
        [self.filterSizesArray removeAllObjects];
        [self.filterBrandsArray removeAllObjects];
        [self.filterColoursArray removeAllObjects];
        [self.filterContinentsArray removeAllObjects];
        
        self.filterCategory = @"";
    }
    
    //(reset skip)
    
    NSLog(@"filters array in user tab %@", self.filtersArray);
    
    if (self.forSaleArray.count != 0) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:NO];
    }
    [self loadWTSListings];
}

-(void)noChange{
    if (self.filtersArray.count > 0) {
        NSMutableAttributedString *filterString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"F I L T E R  %lu",self.filtersArray.count]];
        [self modifyString:filterString setColorForText:[NSString stringWithFormat:@"%lu",self.filtersArray.count] withColor:[UIColor colorWithRed:0.31 green:0.89 blue:0.76 alpha:1.0]];
        [self.filterButton setAttributedTitle:filterString forState:UIControlStateNormal];
    }
    else{
        //no filters
        NSMutableAttributedString *filterString = [[NSMutableAttributedString alloc] initWithString:@"F I L T E R"];
        [self.filterButton setAttributedTitle:filterString forState:UIControlStateNormal];
        
        [self.filterSizesArray removeAllObjects];
        [self.filterBrandsArray removeAllObjects];
        [self.filterColoursArray removeAllObjects];
        self.filterCategory = @"";
    }
}

-(void)setupPullQuery{
    if (self.filtersArray.count > 0) {
        
        //price
        if ([self.filtersArray containsObject:@"price"]) {
            [self.saleQuery whereKey:[NSString stringWithFormat:@"salePrice%@", self.currency] greaterThanOrEqualTo:@(self.filterLower)];
            [self.saleQuery whereKey:[NSString stringWithFormat:@"salePrice%@", self.currency] lessThanOrEqualTo:@(self.filterUpper)];
        }
        
        if ([self.filtersArray containsObject:@"hightolow"]) {
            [self.saleQuery orderByDescending:[NSString stringWithFormat:@"salePrice%@", self.currency]];
        }
        else if ([self.filtersArray containsObject:@"lowtohigh"]){
            [self.saleQuery orderByAscending:[NSString stringWithFormat:@"salePrice%@", self.currency]];
        }
        else{
            [self.saleQuery orderByDescending:@"createdAt"];
        }
        
        //instant buy
        if ([self.filtersArray containsObject:@"instantBuy"]){
            [self.saleQuery whereKey:@"instantBuy" equalTo:@"YES"];
        }

        //condition
        if ([self.filtersArray containsObject:@"new"]){
            [self.saleQuery whereKey:@"condition" containedIn:@[@"New", @"Any", @"BNWT", @"BNWOT"]];
        }
        else if ([self.filtersArray containsObject:@"used"]){
            [self.saleQuery whereKey:@"condition" containedIn:@[@"Used", @"Any"]];
        }
        else if ([self.filtersArray containsObject:@"deadstock"]){
            [self.saleQuery whereKey:@"condition" containedIn:@[@"Deadstock", @"Any"]];
        }
        
        //category filters
        if (![self.filterCategory isEqualToString:@""]) {
            [self.saleQuery whereKey:@"category" equalTo:self.filterCategory];
        }
        
        //gender
        if ([self.filtersArray containsObject:@"male"]){
            [self.saleQuery whereKey:@"sizeGender" equalTo:@"Mens"];
        }
        else if ([self.filtersArray containsObject:@"female"]){
            [self.saleQuery whereKey:@"sizeGender" equalTo:@"Womens"];
        }
        
        //all sizes filters
        if (self.filterSizesArray.count > 0) {
            [self.saleQuery whereKey:@"sizeArray" containedIn:self.filterSizesArray];
        }
        
        //colour filters
        if (self.filterColoursArray.count > 0) {
            [self.saleQuery whereKey:@"coloursArray" containedIn:self.filterColoursArray]; //was mainColour
        }
        
    }
    else{
        [self.saleQuery orderByDescending:@"createdAt"];
    }
}

-(void)setupInfinQuery{
    if (self.filtersArray.count > 0) {
        
        //price
        if ([self.filtersArray containsObject:@"price"]) {
            [self.saleInfinQuery whereKey:[NSString stringWithFormat:@"salePrice%@", self.currency] greaterThanOrEqualTo:@(self.filterLower)];
            [self.saleInfinQuery whereKey:[NSString stringWithFormat:@"salePrice%@", self.currency] lessThanOrEqualTo:@(self.filterUpper)];
        }
        
        if ([self.filtersArray containsObject:@"hightolow"]) {
            [self.saleInfinQuery orderByDescending:[NSString stringWithFormat:@"salePrice%@", self.currency]];
        }
        else if ([self.filtersArray containsObject:@"lowtohigh"]){
            [self.saleInfinQuery orderByAscending:[NSString stringWithFormat:@"salePrice%@", self.currency]];
        }
        else{
            [self.saleInfinQuery orderByDescending:@"createdAt"];
        }
        
        //instant buy
        if ([self.filtersArray containsObject:@"instantBuy"]){
            [self.saleInfinQuery whereKey:@"instantBuy" equalTo:@"YES"];
        }
        
        //condition
        if ([self.filtersArray containsObject:@"new"]){
            [self.saleInfinQuery whereKey:@"condition" containedIn:@[@"New", @"Any", @"BNWT", @"BNWOT"]];
        }
        else if ([self.filtersArray containsObject:@"used"]){
            [self.saleInfinQuery whereKey:@"condition" containedIn:@[@"Used", @"Any"]];
        }
        else if ([self.filtersArray containsObject:@"deadstock"]){
            [self.saleInfinQuery whereKey:@"condition" containedIn:@[@"Deadstock", @"Any"]];
        }
        
        //category filters
        if (![self.filterCategory isEqualToString:@""]) {
            [self.saleInfinQuery whereKey:@"category" equalTo:self.filterCategory];
        }
        
        //gender
        if ([self.filtersArray containsObject:@"male"]){
            [self.saleInfinQuery whereKey:@"sizeGender" equalTo:@"Mens"];
        }
        else if ([self.filtersArray containsObject:@"female"]){
            [self.saleInfinQuery whereKey:@"sizeGender" equalTo:@"Womens"];
        }
        
        //all sizes filters
        if (self.filterSizesArray.count > 0) {
            [self.saleInfinQuery whereKey:@"sizeArray" containedIn:self.filterSizesArray];
        }
        
        //colour filters
        if (self.filterColoursArray.count > 0) {
            [self.saleInfinQuery whereKey:@"coloursArray" containedIn:self.filterColoursArray];
        }
        
    }
    else{
        [self.saleInfinQuery orderByDescending:@"createdAt"];
    }
}

#pragma mark - colour part of label

-(NSMutableAttributedString *)modifyString: (NSMutableAttributedString *)mainString setColorForText:(NSString*) textToFind withColor:(UIColor*) color
{
    NSRange range = [mainString.mutableString rangeOfString:textToFind options:NSCaseInsensitiveSearch];
    
    if (range.location != NSNotFound) {
        [mainString addAttribute:NSForegroundColorAttributeName value:color range:range];
    }
    
    return mainString;
}

-(NSMutableAttributedString *)modifyNumberLabel: (NSMutableAttributedString *)mainString setFontForText:(NSString*) textToFind
{
    NSRange range = [mainString.mutableString rangeOfString:textToFind options:NSCaseInsensitiveSearch];
    
    if (range.location != NSNotFound) {
        
        if (self.smallScreen) {
            [mainString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFangSC-Semibold" size:13] range:range];
        }
        else{
            [mainString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFangSC-Semibold" size:14] range:range];
        }
        
        [mainString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] range:range];
    }
    
    return mainString;
}

-(void)hideFilter{
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.filterButton.alpha = 0.0;
                     }
                     completion:nil];
}

-(void)showFilter{
    self.filterButton.alpha = 0.0;
    [self.filterButton setHidden:NO];

    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.filterButton.alpha = 1.0;
                         
                     }
                     completion:nil];
}

#pragma mark - for sale listing delegates for reloading CV

-(void)changedSoldStatus{
    NSLog(@"changed sold status");
    self.changedSoldStatusOfListing = YES;
    self.deletedListing = NO;
}

-(void)deletedItem{
    self.changedSoldStatusOfListing = NO;
    self.deletedListing = YES;
}

-(void)dismissForSaleListing{
    //ignore
}

-(void)snapSeen{
    //ignore
}

-(void)boostedItem{
    [self loadWTSListings];
}


#pragma mark - wanted listing delegates for reloading CV

-(void)deletedWantedItem{
    self.changedSoldStatusOfListing = NO;
    self.deletedListing = YES;
}

-(void)changedPurchasedStatus{
    self.changedSoldStatusOfListing = YES;
    self.deletedListing = NO;
}

//no point reloading here because unless we refresh the collection view (which can't be done when on a different segment) the changes won't be made
-(void)likedItem{
//    [self loadBumpedListings];
}

-(void)likedWantedItem{
//    [self loadBumpedListings];
}

-(void)blockUser{
    //save a blocked object so other user can't message this user
    PFObject *blockedObject = [PFObject objectWithClassName:@"blockedUsers"];
    [blockedObject setObject:self.user forKey:@"blockedUser"];
    [blockedObject setObject:[PFUser currentUser] forKey:@"blocker"];
    [blockedObject setObject:@"live" forKey:@"status"];
    [blockedObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            [self showAlertWithTitle:@"User Blocked" andMsg:@"They can no longer message you on BUMP, if you'd like some support just message Support from Settings"];
        }
        else{
            [self showAlertWithTitle:@"Error Blocking User" andMsg:@"Send Support a message from Settings to get this sorted"];
        }
    }];
}

-(void)unblockUser{
    PFQuery *blockQuery = [PFQuery queryWithClassName:@"blockedUsers"];
    [blockQuery whereKey:@"blockedUser" equalTo:self.user];
    [blockQuery whereKey:@"blocker" equalTo:[PFUser currentUser]];
    [blockQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            [object setObject:@"deleted" forKey:@"status"];
            [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    [self showAlertWithTitle:@"User Unblocked" andMsg:nil];
                }
                else{
                    [self showAlertWithTitle:@"Error Unblocking User" andMsg:@"Send Support a message from Settings to get this sorted"];
                }
            }];
        }
    }];
}

-(void)addHeaderView:(myCompletion) block{
    [self setupHeaderBar:^(BOOL finished) {
        if (finished) {
            //triggers username to be assigned to label & width calculated
            block(YES);
        }
    }];
    
    self.segmentedControl = [[HMSegmentedControl alloc] init];
    self.segmentedControl.frame = CGRectMake(0, self.myBar.frame.size.height-50,[UIApplication sharedApplication].keyWindow.frame.size.width, 50);
    self.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
    self.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
    self.segmentedControl.selectionIndicatorColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    
    self.segmentedControl.borderType = HMSegmentedControlBorderTypeBottom;
    self.segmentedControl.borderColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    self.segmentedControl.borderWidth = 0.5;
    
    self.segmentedControl.selectionIndicatorHeight = 2;
    self.segmentedControl.titleTextAttributes = @{NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Medium" size:10],NSForegroundColorAttributeName : [UIColor lightGrayColor]};
    self.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName :  [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]};
    [self.segmentedControl addTarget:self action:@selector(segmentControlChanged) forControlEvents:UIControlEventValueChanged];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialSegAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] init];
    initialSegAttributes.frame = CGRectMake(0, self.myBar.frame.size.height-50,[UIApplication sharedApplication].keyWindow.frame.size.width, 50);
    [self.segmentedControl addLayoutAttributes:initialSegAttributes forProgress:0];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalSegAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialSegAttributes];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 812) {
        //iPhone X has a bigger status bar - so we lower top buttons slightly, therefore minimum bar height is bit bigger
        if (self.hasBio || self.tabMode) {
            finalSegAttributes.transform = CGAffineTransformMakeTranslation(0, -215);
        }
        else{
            finalSegAttributes.transform = CGAffineTransformMakeTranslation(0, -165); //to get this number just minus small bar height (120) from new max bar height
        }
    }
    else{
        if (self.hasBio || self.tabMode) {
            finalSegAttributes.transform = CGAffineTransformMakeTranslation(0, -220);
        }
        else{
            finalSegAttributes.transform = CGAffineTransformMakeTranslation(0, -170); //to get this number just minus small bar height (115) from new max bar height
        }
    }

    [self.segmentedControl addLayoutAttributes:finalSegAttributes forProgress:1.0];
    [self.myBar addSubview:self.segmentedControl];
    
    //setup dots button
    [self.dotsButton setImage:[UIImage imageNamed:@"profileDots"] forState:UIControlStateNormal];
    [self.dotsButton addTarget:self action:@selector(showAlertView) forControlEvents:UIControlEventTouchUpInside];
    
    [self.segmentedControl setSectionTitles:@[@"S E L L I N G", @"L I K E S"]];
    self.numberOfSegments = 2;
    
    self.WTBSelected = NO;
    self.WTSSelected = YES;
    self.bumpsSelected = NO;
    
    if (!self.badgeView && self.hasBadge) {
        //badge image view
        self.badgeView = [[PFImageView alloc]initWithFrame:CGRectMake(0, 0, 15, 15)];
        
        if (self.modBadge) {
            [self.badgeView setImage:[UIImage imageNamed:@"modBadge"]];
        }
        else{
            [self.badgeView setImage:[UIImage imageNamed:@"veriBadge"]];
        }
        
        [self.myBar addSubview:self.badgeView];

        BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesBadgeView = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
        initialLayoutAttributesBadgeView.size = self.badgeView.frame.size;
        
        float usernameYVal = 130 - (17 + 15 + self.usernameLabel.frame.size.height);

        initialLayoutAttributesBadgeView.frame = CGRectMake(self.userImageView.frame.origin.x + self.userImageView.frame.size.width + 10 + self.usernameLabel.frame.size.width,(usernameYVal + (self.usernameLabel.frame.size.height/2))-7.5,self.badgeView.frame.size.width,self.badgeView.frame.size.height);
        [self.badgeView addLayoutAttributes:initialLayoutAttributesBadgeView forProgress:0.0];
        
        BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesBadgeView = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesBadgeView];
        finalLayoutAttributesBadgeView.alpha = 0.0;
        [self.badgeView addLayoutAttributes:finalLayoutAttributesBadgeView forProgress:0.5];
    }
}

-(void)addBioTapped{
    if (!self.hasBio) {
        [Answers logCustomEventWithName:@"Add bio pressed"
                       customAttributes:@{}];
        
        self.enteredBio = YES;
        SettingsController *vc = [[SettingsController alloc]init];
        vc.bioMode = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(void)updateConvoImages{
    //update user's top 20 recent convos to include the user's profile picture
    //query for convos where I'm the buyer then update buyerPicture & same for sellerPicture
    
    PFQuery *convoQ = [PFQuery queryWithClassName:@"convos"];
    [convoQ whereKey:@"totalMessages" greaterThan:@0];
//    [convoQ whereKeyExists:@"buyerUser"];
    [convoQ whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
    [convoQ orderByDescending:@"lastSentDate"];
    convoQ.limit = 20;
    [convoQ findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            for (PFObject *convo in objects) {
                convo[@"buyerPicture"] = [[PFUser currentUser] objectForKey:@"picture"];
                [convo saveInBackground];
            }
            
        }
        else{
            [Answers logCustomEventWithName:@"Error retrieving user's buyer convos to change pic"
                           customAttributes:@{
                                              @"where":@"Settings",
                                              }];
        }
    }];
    
    PFQuery *sellingConvoQ = [PFQuery queryWithClassName:@"convos"];
    [sellingConvoQ whereKey:@"totalMessages" greaterThan:@0];
    [sellingConvoQ whereKeyExists:@"sellerUser"];
    [sellingConvoQ whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
    [sellingConvoQ orderByDescending:@"lastSentDate"];
    sellingConvoQ.limit = 20;
    [sellingConvoQ findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            for (PFObject *convo in objects) {
                convo[@"sellerPicture"] = [[PFUser currentUser] objectForKey:@"picture"];
                [convo saveInBackground];
            }
            
        }
        else{
            [Answers logCustomEventWithName:@"Error retrieving user's seller convos to change pic"
                           customAttributes:@{
                                              @"where":@"Settings",
                                              }];
        }
    }];
}

-(void)ordersButtonPressed{
    segmentedTableView *vc = [[segmentedTableView alloc]init];
//    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)updateOrderBadge:(NSNotification*)note {
    [self calcTabBadge];
}

-(void)removeOrderBadge{
    [self.ordersButton setImage:[UIImage imageNamed:@"ordersNormalNew"] forState:UIControlStateNormal];
    [self.unseenOrdersView setHidden:YES];
}

-(void)calcTabBadge{
    
    //check if any support or team bump messages unseen
    int tabInt = 0;
    
    if (self.supportUnseen > 0 || self.messagesUnseen > 0) {
        tabInt++;
        [self.backButton setImage:[UIImage imageNamed:@"profileCogUnreadNew"] forState:UIControlStateNormal];
    }
    else{
        [self.backButton setImage:[UIImage imageNamed:@"profileCogNew"] forState:UIControlStateNormal];
    }
    
    //then get number of unseen orders
    if (self.ordersUnseen > 0) {
        tabInt+= self.ordersUnseen;
        [self.ordersButton setImage:[UIImage imageNamed:@"ordersUnreadNew"] forState:UIControlStateNormal];
        [self.unseenOrdersView setHidden:NO];
    }
    else{
        [self.ordersButton setImage:[UIImage imageNamed:@"ordersNormalNew"] forState:UIControlStateNormal];
        [self.unseenOrdersView setHidden:YES];
    }
    
    //add all together and set tab badge
    if (tabInt == 0) {
        [[self.tabBarController.tabBar.items objectAtIndex:4] setBadgeValue:nil];
    }
    else if(tabInt > 9){
        [[self.tabBarController.tabBar.items objectAtIndex:4] setBadgeValue:@"9+"];
    }
    else{
        [[self.tabBarController.tabBar.items objectAtIndex:4] setBadgeValue:[NSString stringWithFormat:@"%d",tabInt]];
    }
}

-(void)followersPressed{
    if (self.followersNumber > 0 && !self.isBumpOfficial) {
        whoBumpedTableView *vc = [[whoBumpedTableView alloc]init];
        vc.mode = @"followers";
        vc.user = self.user;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(void)followingPressed{
    if (self.followingNumber > 0) {
        whoBumpedTableView *vc = [[whoBumpedTableView alloc]init];
        vc.mode = @"following";
        vc.user = self.user;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(void)presentUnfollowSheet{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    actionSheet.title = [NSString stringWithFormat:@"Unfollow %@?", self.user.username];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Unfollow" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        self.following = NO;
        
        //tracking
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"unfollow_pressed" properties:@{
                                                       @"source":@"profile"
                                                       }];
        
        //update current user's followingDic locally
        if ([[PFUser currentUser]objectForKey:@"followingDic"]) {
            //remove from existing
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[[PFUser currentUser]objectForKey:@"followingDic"]];
            
            if ([dic valueForKey:self.user.objectId]) {
                [dic removeObjectForKey:self.user.objectId];
                [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
                [[PFUser currentUser]saveInBackground];
            }
        }
        
        //change follow button
        [self setFollowButton];
        
        //decrement followers badge
        if (self.followersNumber > 0) {
            self.followersNumber--;
            NSString *followersNumberString = [self shortenNumberToString:self.followersNumber];
            
            NSMutableAttributedString *followerString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\nFollowers",followersNumberString] attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]}];
            [self modifyNumberLabel:followerString setFontForText:followersNumberString];
            [self.followersButton setAttributedTitle:followerString forState:UIControlStateNormal];
        }
        
        NSDictionary *params = @{@"followedId": self.user.objectId, @"followingId": [PFUser currentUser].objectId};
        [PFCloud callFunctionInBackground:@"unfollowUser" withParameters: params block:^(id  _Nullable object, NSError * _Nullable error) {
            if (error) {
                NSLog(@"error unfollowing user: %@", error);
                
                [Answers logCustomEventWithName:@"Error Unfollowing User"
                               customAttributes:@{
                                                  @"error":error.description
                                                  }];
                
                //add user back into the local following array
                if ([[PFUser currentUser]objectForKey:@"followingDic"]) {
                    //add to existing
                    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[[PFUser currentUser]objectForKey:@"followingDic"]];
                    
                    //check if value already exists in dictionary before adding
                    if (![dic valueForKey:self.user.objectId]) {
                        dic[self.user.objectId] = self.user.objectId;
                        [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
                        [[PFUser currentUser]saveInBackground];
                    }
                }
                
                //reset button
                self.following = YES;
                [self setFollowButton];
                
                //show alert
                [self showAlertWithTitle:@"Follow Error" andMsg:@"Make sure you're connected to the internet. If you keep seeing this issue please send a screenshot to support from within the app"];
                
                //reset followers badge
                self.followersNumber++;
                NSString *followersNumberString = [self shortenNumberToString:self.followersNumber];
                
                NSMutableAttributedString *followerString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\nFollowers",followersNumberString] attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]}];
                [self modifyNumberLabel:followerString setFontForText:followersNumberString];
                [self.followersButton setAttributedTitle:followerString forState:UIControlStateNormal];
                
            }
            else{
                NSLog(@"success unfollowing user!");
                
                [Answers logCustomEventWithName:@"Unfollowed User"
                               customAttributes:@{
                                                  @"where":@"profile"
                                                  }];
            }
        }];
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)followButtonPressed{
    
    if (self.following) {
        //unfollow
        [self presentUnfollowSheet];
    }
    else{
        //follow
        NSLog(@"follow pressed");
        
        //tracking
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"follow_pressed" properties:@{
                                                       @"source":@"profile"
                                                       }];

        self.following = YES;
        
        //change follow button
        [self setFollowingButton];
        
        //increment followers badge
        self.followersNumber++;
        NSString *followersNumberString = [self shortenNumberToString:self.followersNumber];
        
        NSMutableAttributedString *followerString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\nFollowers",followersNumberString] attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]}];
        [self modifyNumberLabel:followerString setFontForText:followersNumberString];
        [self.followersButton setAttributedTitle:followerString forState:UIControlStateNormal];
        
        //if someone re-following over 3 times then we stop processing the follows
        if (self.followCounter > 3) {
            return;
        }
        
        self.followCounter++;

        //update current user's followingDic locally
        if ([[PFUser currentUser]objectForKey:@"followingDic"]) {
            //add to existing
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[[PFUser currentUser]objectForKey:@"followingDic"]];
            
            //check if value already exists in dictionary before adding
            if (![dic valueForKey:self.user.objectId]) {
                dic[self.user.objectId] = self.user.objectId;
                [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
                [[PFUser currentUser]saveInBackground];
            }
        }
        else{
            //create one
            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
            dic[self.user.objectId] = self.user.objectId;
            [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
            [[PFUser currentUser]saveInBackground];
        }
        
        NSDictionary *params = @{@"followedId": self.user.objectId, @"followingId": [PFUser currentUser].objectId};
        [PFCloud callFunctionInBackground:@"followUser" withParameters: params block:^(id  _Nullable object, NSError * _Nullable error) {
            if (error) {
                NSLog(@"error following user: %@", error);
                
                
                [Answers logCustomEventWithName:@"Error Following User"
                               customAttributes:@{
                                                  @"error":error.description
                                                  }];
                
                if ([[PFUser currentUser]objectForKey:@"followingDic"]) {
                    //remove from existing
                    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[[PFUser currentUser]objectForKey:@"followingDic"]];
                    
                    if ([dic valueForKey:self.user.objectId]) {
                        [dic removeObjectForKey:self.user.objectId];
                        [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
                        [[PFUser currentUser]saveInBackground];
                    }
                }
                
                //reset button
                self.following = NO;
                [self setFollowButton];
                
                //show alert
                [self showAlertWithTitle:@"Follow Error" andMsg:@"Make sure you're connected to the internet. If you keep seeing this issue please send a screenshot to support from within the app"];

                //reset followers badge
                self.followersNumber--;
                NSString *followersNumberString = [self shortenNumberToString:self.followersNumber];
                
                NSMutableAttributedString *followerString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\nFollowers",followersNumberString] attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]}];
                [self modifyNumberLabel:followerString setFontForText:followersNumberString];
                [self.followersButton setAttributedTitle:followerString forState:UIControlStateNormal];
            }
            else{
                NSLog(@"success following user!");
                
                [Answers logCustomEventWithName:@"Followed User"
                               customAttributes:@{
                                                  @"where":@"profile"
                                                  }];
            }
        }];
    }
    
}

//helpers to quickly change follow button
-(void)setFollowingButton{
    [self.followButton setBackgroundImage:nil forState:UIControlStateNormal];
    
    [self.followButton setTitle:@"Following" forState:UIControlStateNormal];
    self.followButton.layer.borderWidth = 1.1;
    self.followButton.layer.borderColor = [UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0].CGColor;
    self.followButton.layer.cornerRadius = 3;
    [self.followButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1] forState:UIControlStateNormal];
}

-(void)setOrdersButton{
    [self.followButton setBackgroundImage:nil forState:UIControlStateNormal];
    
    [self.followButton setTitle:@"Orders" forState:UIControlStateNormal];
    self.followButton.layer.borderWidth = 1.1;
    self.followButton.layer.borderColor = [UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0].CGColor;

    self.followButton.layer.cornerRadius = 3;
    [self.followButton setTitleColor: [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0] forState:UIControlStateNormal];
    
    //setup unread dot
    self.unseenOrdersView = [[UIView alloc]initWithFrame:CGRectMake(self.followButton.titleLabel.frame.origin.x + 25, self.followButton.titleLabel.frame.origin.y-7, 5,5)];
    [self.unseenOrdersView.layer setCornerRadius:2.5];
    self.unseenOrdersView.backgroundColor = [UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0];
    [self.unseenOrdersView setHidden:YES];
    [self.followButton addSubview:self.unseenOrdersView];
}

-(void)setFollowButton{
    self.followButton.layer.borderWidth = 0;
    [self.followButton setBackgroundImage:[UIImage imageNamed:@"followBg"] forState:UIControlStateNormal];
    [self.followButton setTitle:@"Follow" forState:UIControlStateNormal];
    
    if (self.fetchedUser && self.user && !self.tabMode) {
        if ([[self.user objectForKey:@"followingDic"]valueForKey:[PFUser currentUser].objectId] && [self.followButton.titleLabel.text isEqualToString:@"Follow"]) {
            [self.followButton setTitle:@"Follow back" forState:UIControlStateNormal];
        }
    }
    [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

-(NSString *)shortenNumberToString:(int)number{
    
    NSString *returnString = [NSString stringWithFormat:@"%d", number];
    
    //for over 10K
    if (number > 9999 && number <= 999999) {
        float numberFloat = (float)number/1000;
        
        //ensure we only show the decimal place when number after point is != 0
        numberFloat = numberFloat*10;
        numberFloat = floor(numberFloat);
        numberFloat = numberFloat/10;
        
        NSString *floatString = [NSString stringWithFormat:@"%.3f", numberFloat];
        NSArray *stringsArray = [floatString componentsSeparatedByString:@"."];
        
        if (stringsArray.count > 1) {
            if ([stringsArray[1] hasPrefix:@"0"]) {
                returnString = [NSString stringWithFormat:@"%.0fk", numberFloat];
            }
            else{
                returnString = [NSString stringWithFormat:@"%.1fk", numberFloat];
            }
        }
        else{
            returnString = [NSString stringWithFormat:@"%.1fk", numberFloat];
        }
        
    }
    //for over 1m
    else if (number > 999999) {
        float numberFloat = (float)number/1000000;
        //ensure we only show the decimal place when number after point is != 0
        numberFloat = numberFloat*10;
        numberFloat = floor(numberFloat);
        numberFloat = numberFloat/10;
        
        NSString *floatString = [NSString stringWithFormat:@"%.3f", numberFloat];
        NSArray *stringsArray = [floatString componentsSeparatedByString:@"."];
        
        if (stringsArray.count > 1) {
            if ([stringsArray[1] hasPrefix:@"0"]) {
                returnString = [NSString stringWithFormat:@"%.0fm", numberFloat];
            }
            else{
                returnString = [NSString stringWithFormat:@"%.1fm", numberFloat];
            }
        }
        else{
            returnString = [NSString stringWithFormat:@"%.1fm", numberFloat];
        }
    }
    
    return returnString;
}

-(void)loadUser{
    [self.user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            
//            NSLog(@"obj %@",self.user);
            
            self.fetchedUser = YES;
            
            //if its bump's official account disable messaging/reporting/tapping followers!
            if ([[self.user objectForKey:@"bumpOfficial"]isEqualToString:@"YES"]) {
                self.isBumpOfficial = YES;
            }
            
            //check if user needs a badge displayed
            if ([[self.user objectForKey:@"veriUser"] isEqualToString:@"YES"]) {
                self.hasBadge = YES;
                self.modBadge = NO;
            }
            else if([[self.user objectForKey:@"mod"] isEqualToString:@"YES"]){
                self.hasBadge = YES;
                self.modBadge = YES;
            }
            
            if ([self.user objectForKey:@"bio"]) {
                if (![[self.user objectForKey:@"bio"]isEqualToString:@""]) {
                    self.hasBio = YES;
                    
                    self.bioLabel.text = [self.user objectForKey:@"bio"];
                }
                else{
                    //put this check in, incase user had a bio but then deleted it
                    self.hasBio = NO;
                    
                    self.bioLabel.text = @"Tap to add a bio and let buyers know more about you";
                }
            }
            else{
                //fail safe
                self.hasBio = NO;
                
                self.bioLabel.text = @"Tap to add a bio and let buyers know more about you";
            }
            
            if (!self.setupHeader) {
                self.setupHeader = YES;
                __weak typeof(self) weakSelf = self;
                
                [self addHeaderView:^(BOOL finished) {
                    if (finished) {
                        if (![weakSelf.usernameLabel.text isEqualToString:weakSelf.user.username]) {
                            weakSelf.usernameLabel.text = [NSString stringWithFormat:@"@%@", weakSelf.user.username];
                            [weakSelf.usernameLabel sizeToFit];
                        }
                    }
                }];
            }
            
            //initial load
            [self loadWTSListings];
            [self loadBumpedListings];
//            [self loadWTBListings];
            
            //setup followers
            self.followingNumber = [[self.user objectForKey:@"followingCount"]intValue];
            
            BOOL showDummyFollowing = [[NSUserDefaults standardUserDefaults]boolForKey:@"showDummyFollowing"];
            
            if (showDummyFollowing) {
                NSLog(@"show dummy following");

                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showDummyFollowing"];
                int dummyCount = [[[NSUserDefaults standardUserDefaults]objectForKey:@"dummyFollowing"]intValue];
                
                if (self.followingNumber < dummyCount) {
                    NSLog(@"dummy: %d", dummyCount);
                    NSLog(@"following: %d", self.followingNumber);

                    self.followingNumber = dummyCount;
                }

            }
            NSString *followingNumberString = [self shortenNumberToString:self.followingNumber];
            
            NSMutableAttributedString *followingString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\nFollowing", followingNumberString] attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]}];
            [self modifyNumberLabel:followingString setFontForText:followingNumberString];
            [self.followingButton setAttributedTitle:followingString forState:UIControlStateNormal];
            
            //followers button
            self.followersNumber = [[self.user objectForKey:@"followerCount"]intValue];
            NSString *followersNumberString = [self shortenNumberToString:self.followersNumber];
            
            NSMutableAttributedString *followerString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\nFollowers",followersNumberString] attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]}];
            [self modifyNumberLabel:followerString setFontForText:followersNumberString];
            [self.followersButton setAttributedTitle:followerString forState:UIControlStateNormal];
            
            //setup reviews
            PFQuery *dealsQuery = [PFQuery queryWithClassName:@"deals"];
            [dealsQuery whereKey:@"User" equalTo:self.user];
            [dealsQuery orderByAscending:@"createdAt"];
            [dealsQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    int starNumber = [[object objectForKey:@"currentRating"] intValue];
                    int total = [[object objectForKey:@"dealsTotal"]intValue];
                    
                    NSLog(@"deals total: %d", total);
                    
                    if (total == 0) {
                        self.noDeals = YES;
                    }
                    else{
                        self.noDeals = NO;
                    }
                    
                    NSString *reviewsTitle = @"0\nReviews";
                    
                    if (total == 0) {
                        self.noDeals = YES;
                    }
                    else if (total == 1) {
                        reviewsTitle = [NSString stringWithFormat:@"%d\nReview",total];
                    }
                    else{
                        reviewsTitle = [NSString stringWithFormat:@"%d\nReviews",total];
                    }
                    
                    //modify reviews button colors
                    NSMutableAttributedString *reviewString = [[NSMutableAttributedString alloc] initWithString:reviewsTitle attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]}];
                    [self modifyNumberLabel:reviewString setFontForText:[NSString stringWithFormat:@"%d", total]];
                    [self.reviewsButton setAttributedTitle:reviewString forState:UIControlStateNormal];
                    
                    if (self.isBumpOfficial) {
                        [self.starImageView setImage:[UIImage imageNamed:@"5star"]];
                    }
                    else if (starNumber == 0) {
                        [self.starImageView setImage:[UIImage imageNamed:@"emptyStars"]];
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
                    NSLog(@"error getting deals data!");
                    
                    [self.starImageView setImage:[UIImage imageNamed:@"emptyStars"]];
                    NSString *reviewsTitle = @"0\nReviews";
                    
                    NSMutableAttributedString *reviewString = [[NSMutableAttributedString alloc] initWithString:reviewsTitle attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]}];
                    [self modifyNumberLabel:reviewString setFontForText:@"0"];
                    [self.reviewsButton setAttributedTitle:reviewString forState:UIControlStateNormal];
                }
            }];
            
            //check if banned - if so show alert (not on tab mode though)
            if (self.tabMode != YES) {
                PFQuery *bannedInstallsQuery = [PFQuery queryWithClassName:@"bannedUsers"];
                [bannedInstallsQuery whereKey:@"user" equalTo:self.user];
                [bannedInstallsQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                    if (object){
                        //this user is banned
                        self.banMode = YES;
                        [self showAlertWithTitle:@"User Restricted" andMsg:@"For your safety we've restricted this user's account for violating our terms"];
                    }
                }];
            }
            

//            if (self.tabMode != YES && self.user && self.segmentedControl.selectedSegmentIndex != 0) {
//            }
            
            if(![self.user objectForKey:@"picture"]){
                
                NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:30],
                                                NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
                
                [self.userImageView setImageWithString:self.user.username color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes];
                
                NSDictionary *textAttributes1 = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:10],
                                                 NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
                
                [self.smallImageView setImageWithString:self.user.username color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes1];
            }
            else{
                PFFile *img = [self.user objectForKey:@"picture"];
                
                [self.userImageView setFile:img];
                [self.userImageView loadInBackground];
                
                [self.smallImageView setFile:img];
                [self.smallImageView loadInBackground];
            }
            
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
                    //display 'Joined June 2017' underneath instead to keep label alignment / height
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    dateFormatter.dateFormat = @"MMM yy";
                    NSString *dateJoined = [dateFormatter stringFromDate:self.user.createdAt];
                    NSString *joinedString = [NSString stringWithFormat:@"Joined %@",dateJoined];
                    
                    NSMutableAttributedString *attString =
                    [[NSMutableAttributedString alloc]
                     initWithString:[NSString stringWithFormat:@"%@\n%@",nameString,joinedString]];
                    
                    
                    [attString addAttribute: NSFontAttributeName
                                      value: [UIFont fontWithName:@"PingFangSC-Medium" size:15]
                                      range: NSMakeRange(0,nameString.length)];
                    
                    if (self.smallScreen) {
                        [attString addAttribute: NSFontAttributeName
                                          value:  [UIFont fontWithName:@"PingFangSC-Regular" size:11]
                                          range: NSMakeRange(nameString.length+1,joinedString.length)];
                    }
                    else{
                        [attString addAttribute: NSFontAttributeName
                                          value:  [UIFont fontWithName:@"PingFangSC-Regular" size:12]
                                          range: NSMakeRange(nameString.length+1,joinedString.length)];
                    }
                    
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
                    
                    if (self.smallScreen) {
                        [attString addAttribute: NSFontAttributeName
                                          value:  [UIFont fontWithName:@"PingFangSC-Regular" size:11]
                                          range: NSMakeRange(nameString.length+1,locString.length)];
                    }
                    else{
                        [attString addAttribute: NSFontAttributeName
                                          value:  [UIFont fontWithName:@"PingFangSC-Regular" size:12]
                                          range: NSMakeRange(nameString.length+1,locString.length)];
                    }
                    
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
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                dateFormatter.dateFormat = @"MMM yy";
                NSString *dateJoined = [dateFormatter stringFromDate:self.user.createdAt];
                NSString *joinedString = [NSString stringWithFormat:@"Joined %@",dateJoined];
                
                NSMutableAttributedString *attString =
                [[NSMutableAttributedString alloc]
                 initWithString:[NSString stringWithFormat:@"%@\n%@",nameString,joinedString]];
                
                [attString addAttribute: NSFontAttributeName
                                  value: [UIFont fontWithName:@"PingFangSC-Medium" size:15]
                                  range: NSMakeRange(0,nameString.length)];
                
                [attString addAttribute: NSFontAttributeName
                                  value:  [UIFont fontWithName:@"PingFangSC-Regular" size:12]
                                  range: NSMakeRange(nameString.length+1,joinedString.length)];
                
                self.nameAndLoc.attributedText = attString;
                self.smallNameAndLoc.text = [NSString stringWithFormat:@"%@", nameString];
            }
            
            //check how user is verified
            [self refreshVeri];
            
            if (![self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
                // looking at other user's profile
                NSArray *friends = [[PFUser currentUser] objectForKey:@"friends"];
                if ([friends containsObject:[self.user objectForKey:@"facebookId"]]) {
                    [self.FBButton setImage:[UIImage imageNamed:@"FbFriends1"] forState:UIControlStateNormal];
                }
            }
            else{
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"seenDiscover"] == YES) {
                    [self.FBButton setImage:[UIImage imageNamed:@"discoverIcon"] forState:UIControlStateNormal];
                }
                else{
                    [self.FBButton setImage:[UIImage imageNamed:@"discoverIconUnread"] forState:UIControlStateNormal];
                }
            }
        }
        else{
            NSLog(@"couldn't fetch user");
            [self showError];
        }
    }];
    
    //setup currency and listings
    self.currency = [[PFUser currentUser]objectForKey:@"currency"];
    if ([self.currency isEqualToString:@"GBP"]) {
        self.currencySymbol = @"£";
    }
    else if ([self.currency isEqualToString:@"EUR"]) {
        self.currencySymbol = @"€";
    }
    else if ([self.currency isEqualToString:@"USD"] || [self.currency isEqualToString:@"AUD"]) {
        self.currencySymbol = @"$";
    }
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        [self segmentControlChanged];
//        [self loadWTSListings];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1) {
        self.bumpedPressed = NO;
    }
//    else if (self.segmentedControl.selectedSegmentIndex == 2) {
//        self.bumpedPressed = NO;
////        [self loadBumpedListings];
//    }
}

-(void)refreshUser{
    NSLog(@"REFRESH USER CALLED");
    
    if (self.refreshingUser || !self.user) {
        return;
    }
    
    self.refreshingUser = YES;
    
    [self.user fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            [self.refreshControl endRefreshing];
            
            self.fetchedUser = YES;
            
            //check if user needs a badge displayed
            if ([[self.user objectForKey:@"veriUser"] isEqualToString:@"YES"]) {
                self.hasBadge = YES;
                self.modBadge = NO;
            }
            else if([[self.user objectForKey:@"mod"] isEqualToString:@"YES"]){
                self.hasBadge = YES;
                self.modBadge = YES;
            }
            
            if ([self.user objectForKey:@"bio"]) {
                if (![[self.user objectForKey:@"bio"]isEqualToString:@""]) {
                    self.hasBio = YES;
                    
                    self.bioLabel.text = [self.user objectForKey:@"bio"];
                }
                else{
                    //put this check in, incase user had a bio but then deleted it
                    self.hasBio = NO;
                    
                    self.bioLabel.text = @"Tap to add a bio and let buyers know more about you";
                }
            }
            else{
                //fail safe
                self.hasBio = NO;
                
                self.bioLabel.text = @"Tap to add a bio and let buyers know more about you";
            }
            
            if (!self.setupHeader) {
                self.setupHeader = YES;
                __weak typeof(self) weakSelf = self;
                
                [self addHeaderView:^(BOOL finished) {
                    if (finished) {
                        if (![weakSelf.usernameLabel.text isEqualToString:weakSelf.user.username]) {
                            weakSelf.usernameLabel.text = [NSString stringWithFormat:@"@%@", weakSelf.user.username];
                            [weakSelf.usernameLabel sizeToFit];
                        }
                    }
                }];
            }
            
            //reload items
            [self loadWTSListings];
            [self loadBumpedListings];
//            [self loadWTBListings];
            
            //setup followers
            self.followingNumber = [[self.user objectForKey:@"followingCount"]intValue];
            NSString *followingNumberString = [self shortenNumberToString:self.followingNumber];
            
            NSMutableAttributedString *followingString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\nFollowing", followingNumberString] attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]}];
            [self modifyNumberLabel:followingString setFontForText:followingNumberString];
            [self.followingButton setAttributedTitle:followingString forState:UIControlStateNormal];
            
            //followers button
            self.followersNumber = [[self.user objectForKey:@"followerCount"]intValue];
            NSString *followersNumberString = [self shortenNumberToString:self.followersNumber];
            
            NSMutableAttributedString *followerString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\nFollowers",followersNumberString] attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]}];
            [self modifyNumberLabel:followerString setFontForText:followersNumberString];
            [self.followersButton setAttributedTitle:followerString forState:UIControlStateNormal];
            
            //setup reviews
            PFQuery *dealsQuery = [PFQuery queryWithClassName:@"deals"];
            [dealsQuery whereKey:@"User" equalTo:self.user];
            [dealsQuery orderByAscending:@"createdAt"];
            [dealsQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    int starNumber = [[object objectForKey:@"currentRating"] intValue];
                    int total = [[object objectForKey:@"dealsTotal"]intValue];
                    
//                    NSLog(@"deals total: %d", total);
                    
                    if (total == 0) {
                        self.noDeals = YES;
                    }
                    else{
                        self.noDeals = NO;
                    }
                    
                    NSString *reviewsTitle = @"0\nReviews";
                    
                    if (total == 0) {
                        self.noDeals = YES;
                    }
                    else if (total == 1) {
                        reviewsTitle = [NSString stringWithFormat:@"%d\nReview",total];
                    }
                    else{
                        reviewsTitle = [NSString stringWithFormat:@"%d\nReviews",total];
                    }
                    
                    //modify reviews button colors
                    NSMutableAttributedString *reviewString = [[NSMutableAttributedString alloc] initWithString:reviewsTitle attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]}];
                    [self modifyNumberLabel:reviewString setFontForText:[NSString stringWithFormat:@"%d", total]];
                    [self.reviewsButton setAttributedTitle:reviewString forState:UIControlStateNormal];
                    
                    if (starNumber == 0) {
                        [self.starImageView setImage:[UIImage imageNamed:@"emptyStars"]];
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
                    NSLog(@"error getting deals data!");
                    
                    [self.starImageView setImage:[UIImage imageNamed:@"emptyStars"]];
                    NSString *reviewsTitle = @"0\nReviews";
                    
                    NSMutableAttributedString *reviewString = [[NSMutableAttributedString alloc] initWithString:reviewsTitle attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]}];
                    [self modifyNumberLabel:reviewString setFontForText:@"0"];
                    [self.reviewsButton setAttributedTitle:reviewString forState:UIControlStateNormal];
                }
            }];
            
            //check if banned - if so show alert (not on tab mode though)
            if (self.tabMode != YES) {
                PFQuery *bannedInstallsQuery = [PFQuery queryWithClassName:@"bannedUsers"];
                [bannedInstallsQuery whereKey:@"user" equalTo:self.user];
                [bannedInstallsQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                    if (object){
                        //this user is banned
                        self.banMode = YES;
                        [self showAlertWithTitle:@"User Restricted" andMsg:@"For your safety we've restricted this user's account for violating our terms"];
                    }
                }];
            }
            
            if(![self.user objectForKey:@"picture"]){
                
                NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:30],
                                                NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
                
                [self.userImageView setImageWithString:self.user.username color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes];
                
                NSDictionary *textAttributes1 = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:10],
                                                 NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
                
                [self.smallImageView setImageWithString:self.user.username color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes1];
            }
            else{
                PFFile *img = [self.user objectForKey:@"picture"];
                
                [self.userImageView setFile:img];
                [self.userImageView loadInBackground];
                
                [self.smallImageView setFile:img];
                [self.smallImageView loadInBackground];
            }
            
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
                    //display 'Joined June 2017' underneath instead to keep label alignment / height
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    dateFormatter.dateFormat = @"MMM yy";
                    NSString *dateJoined = [dateFormatter stringFromDate:self.user.createdAt];
                    NSString *joinedString = [NSString stringWithFormat:@"Joined %@",dateJoined];
                    
                    NSMutableAttributedString *attString =
                    [[NSMutableAttributedString alloc]
                     initWithString:[NSString stringWithFormat:@"%@\n%@",nameString,joinedString]];
                    
                    
                    [attString addAttribute: NSFontAttributeName
                                      value: [UIFont fontWithName:@"PingFangSC-Medium" size:15]
                                      range: NSMakeRange(0,nameString.length)];
                    
                    if (self.smallScreen) {
                        [attString addAttribute: NSFontAttributeName
                                          value:  [UIFont fontWithName:@"PingFangSC-Regular" size:11]
                                          range: NSMakeRange(nameString.length+1,joinedString.length)];
                    }
                    else{
                        [attString addAttribute: NSFontAttributeName
                                          value:  [UIFont fontWithName:@"PingFangSC-Regular" size:12]
                                          range: NSMakeRange(nameString.length+1,joinedString.length)];
                    }
                    
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
                    
                    if (self.smallScreen) {
                        [attString addAttribute: NSFontAttributeName
                                          value:  [UIFont fontWithName:@"PingFangSC-Regular" size:11]
                                          range: NSMakeRange(nameString.length+1,locString.length)];
                    }
                    else{
                        [attString addAttribute: NSFontAttributeName
                                          value:  [UIFont fontWithName:@"PingFangSC-Regular" size:12]
                                          range: NSMakeRange(nameString.length+1,locString.length)];
                    }
                    
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
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                dateFormatter.dateFormat = @"MMM yy";
                NSString *dateJoined = [dateFormatter stringFromDate:self.user.createdAt];
                NSString *joinedString = [NSString stringWithFormat:@"Joined %@",dateJoined];
                
                NSMutableAttributedString *attString =
                [[NSMutableAttributedString alloc]
                 initWithString:[NSString stringWithFormat:@"%@\n%@",nameString,joinedString]];
                
                [attString addAttribute: NSFontAttributeName
                                  value: [UIFont fontWithName:@"PingFangSC-Medium" size:15]
                                  range: NSMakeRange(0,nameString.length)];
                
                [attString addAttribute: NSFontAttributeName
                                  value:  [UIFont fontWithName:@"PingFangSC-Regular" size:12]
                                  range: NSMakeRange(nameString.length+1,joinedString.length)];
                
                self.nameAndLoc.attributedText = attString;
                self.smallNameAndLoc.text = [NSString stringWithFormat:@"%@", nameString];
            }
            
            //check how user is verified
            [self refreshVeri];
            
            if (![self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
                // looking at other user's profile
                NSArray *friends = [[PFUser currentUser] objectForKey:@"friends"];
                if ([friends containsObject:[self.user objectForKey:@"facebookId"]]) {
                    [self.FBButton setImage:[UIImage imageNamed:@"FbFriends1"] forState:UIControlStateNormal];
                }
            }
            else{
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"seenDiscover"] == YES) {
                    [self.FBButton setImage:[UIImage imageNamed:@"discoverIcon"] forState:UIControlStateNormal];
                }
                else{
                    [self.FBButton setImage:[UIImage imageNamed:@"discoverIconUnread"] forState:UIControlStateNormal];
                }
            }
            
            self.refreshingUser = NO;
        }
        else{
            self.refreshingUser = NO;
            
            [self.refreshControl endRefreshing];
            NSLog(@"couldn't fetch user");
            [self showError];
        }
    }];
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        [self segmentControlChanged];
//        [self loadWTSListings];
    }
//    else if (self.segmentedControl.selectedSegmentIndex == 1) {
//        self.WTBPressed = NO;
////        [self loadWTBListings];
//    }
    else if (self.segmentedControl.selectedSegmentIndex == 1) {
        self.bumpedPressed = NO;
//        [self loadBumpedListings];
    }
    
}

#pragma mark - infinite scrolling

//-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
//
//    float bottom = scrollView.contentSize.height - scrollView.frame.size.height;
//    float buffer = self.cellHeight * 2;
//    float scrollPosition = scrollView.contentOffset.y;
//
//    // Reached the bottom of the list
//    if (scrollPosition > (bottom - buffer)) {
//        // Add more dates to the bottom
//
//        if (self.finishedSaleInfin == YES && self.segmentedControl.selectedSegmentIndex == 0) {
//            //infinity query
//            [self loadMoreSaleListings];
//        }
//    }
//}

@end
