//
//  UserProfileController.m
//  wtbtest
//
//  Created by Jack Ryder on 26/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "UserProfileController.h"
#import <SVPullToRefresh/SVPullToRefresh.h>
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

@interface UserProfileController ()

@end

@implementation UserProfileController

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
    
    //check if must show unread icon on cog icon
    if (self.tabMode && self.setupHeader) {
        [self calcTabBadge];
    }
//    if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId] && self.tabMode == YES) {
//        if (self.supportUnseen || self.messagesUnseen) { //CHANGE
//            [self.backButton setImage:[UIImage imageNamed:@"unreadCog"] forState:UIControlStateNormal];
//        }
//        else{
//            [self.backButton setImage:[UIImage imageNamed:@"profileCog"] forState:UIControlStateNormal];
//        }
//    }
    
    //refresh listings when user taps on profile tab
    if (self.tabMode == YES && self.user && self.segmentedControl.selectedSegmentIndex == 0) {
        [self loadWTSListings];
    }
    
    if (self.tappedListing == YES) {
        self.tappedListing = NO;
        
        if (self.changedSoldStatusOfListing == YES){
            self.changedSoldStatusOfListing = NO;
            
            if (self.segmentedControl.selectedSegmentIndex == 2) {
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
            
            if (self.segmentedControl.selectedSegmentIndex == 2) {
                //don't instant update bump tab when items deleted
            }
            
            //when one item left to delete we just reload
            else if (self.lastSelected.row == 0) {
                if (self.segmentedControl.selectedSegmentIndex == 1) {
                    [self loadWTBListings];
                }
                else if (self.segmentedControl.selectedSegmentIndex == 0) {
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
        [self.user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                
                if ([self.user objectForKey:@"bio"]) {
                    if (![[self.user objectForKey:@"bio"]isEqualToString:@""]) {
                        self.hasBio = YES;
                        
                        self.bioLabel.text = [self.user objectForKey:@"bio"];
                        self.bioLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
                    }
                    else{
                        //put this check in, incase user had a bio but then deleted it
                        self.hasBio = NO;
                        
                        self.bioLabel.text = @"Tap to add a bio";
                        self.bioLabel.textColor = [UIColor lightGrayColor];
                    }
                }
                else{
                    //fail safe
                    self.hasBio = NO;
                    
                    self.bioLabel.text = @"Tap to add a bio";
                    self.bioLabel.textColor = [UIColor lightGrayColor];
                }
                
                if (!self.setupHeader) {
                    self.setupHeader = YES;
                    [self addHeaderView];
                }
                
                //check if banned - if so show alert (not on tab mode though)
                if (self.tabMode != YES) {
                    PFQuery *bannedInstallsQuery = [PFQuery queryWithClassName:@"bannedUsers"];
                    [bannedInstallsQuery whereKey:@"user" equalTo:self.user];
                    [bannedInstallsQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                        if (object){
                            //this user is banned
                            self.banMode = YES;
                            [self showAlertWithTitle:@"User Restricted" andMsg:@"For your safety we've restrcited this user's account for violating our terms"];
                        }
                    }];
                }
                else{
                    //tab mode
                    if ([[self.user objectForKey:@"orderNumber"]intValue] > 0) {
                        self.showOrderButton = YES;
//                        [self.myBar addSubview:self.ordersButton];
                    }
                    
                    [self.myBar addSubview:self.ordersButton]; //CHANGE

                }
                
                
                [self loadBumpedListings];
                [self loadWTBListings];
                
                if (self.tabMode != YES && self.user && self.segmentedControl.selectedSegmentIndex != 0) {
                    [self loadWTSListings];
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
                
                self.usernameLabel.text = [NSString stringWithFormat:@"@%@", self.user.username];
                
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
                                          value: [UIFont fontWithName:@"PingFangSC-Medium" size:13]
                                          range: NSMakeRange(0,nameString.length)];
                        
                        [attString addAttribute: NSFontAttributeName
                                          value:  [UIFont fontWithName:@"PingFangSC-Regular" size:13]
                                          range: NSMakeRange(nameString.length+1,joinedString.length)];
                        
                        self.nameAndLoc.attributedText = attString;
                        self.smallNameAndLoc.text =[NSString stringWithFormat:@"%@",nameString];
                    }
                    else{
                        NSMutableAttributedString *attString =
                        [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%@\n%@",nameString,locString]];
                        
                        
                        [attString addAttribute: NSFontAttributeName
                                          value: [UIFont fontWithName:@"PingFangSC-Medium" size:13]
                                          range: NSMakeRange(0,nameString.length)];
                        
                        
                        [attString addAttribute: NSFontAttributeName
                                          value:  [UIFont fontWithName:@"PingFangSC-Regular" size:13]
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
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    dateFormatter.dateFormat = @"MMM yy";
                    NSString *dateJoined = [dateFormatter stringFromDate:self.user.createdAt];
                    NSString *joinedString = [NSString stringWithFormat:@"Joined %@",dateJoined];
                    
                    NSMutableAttributedString *attString =
                    [[NSMutableAttributedString alloc]
                     initWithString:[NSString stringWithFormat:@"%@\n%@",nameString,joinedString]];
                    
                    [attString addAttribute: NSFontAttributeName
                                      value: [UIFont fontWithName:@"PingFangSC-Medium" size:13]
                                      range: NSMakeRange(0,nameString.length)];
                    
                    [attString addAttribute: NSFontAttributeName
                                      value:  [UIFont fontWithName:@"PingFangSC-Regular" size:13]
                                      range: NSMakeRange(nameString.length+1,joinedString.length)];
                    
                    self.nameAndLoc.attributedText = attString;
                    self.smallNameAndLoc.text = [NSString stringWithFormat:@"%@", nameString];
                }
                
                //check how user is verified
                [self refreshVeri];
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
                    self.noDeals = NO;
                    
                    if (total == 1) {
                        [self.reviewsButton setTitle:[NSString stringWithFormat:@"%d Review",total] forState:UIControlStateNormal];
                    }
                    else{
                        [self.reviewsButton setTitle:[NSString stringWithFormat:@"%d Reviews",total] forState:UIControlStateNormal];
                    }
                    
                    if (total == 0 && self.tabMode == YES) {
                        self.noDeals = YES;
                        [self.starImageView setImage:[UIImage imageNamed:@"emptyStars"]];
                        [self.reviewsButton setHidden:YES];
                    }
                    if (starNumber == 1){
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
            }
        }];
        
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
            [self loadWTSListings];
            
        }
        else if (self.segmentedControl.selectedSegmentIndex == 1) {
            self.WTBPressed = NO;
            [self loadWTBListings];
        }
        else if (self.segmentedControl.selectedSegmentIndex == 2) {
            self.bumpedPressed = NO;
            [self loadBumpedListings];
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
    [mask setBorderColor: [[UIColor greenColor] CGColor]];
    
    if (imageView == self.userImageView) {
        borderShape.lineWidth = 6;
    }
    else{
        borderShape.lineWidth = 1.5;
    }

    
    [imageView.layer addSublayer:borderShape];
    
    
    
//    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
//    imageView.layer.masksToBounds = YES;
//    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
//    [imageView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
//    if (imageView == self.userImageView) {
//        [imageView.layer setBorderWidth: 3.5];
//    }
//    else{
//        [imageView.layer setBorderWidth: 1.5];
//    }
    
}

-(void)loadWTBListings{
    
    if (!self.user) {
        return;
    }
    
    PFQuery *wtbQuery = [PFQuery queryWithClassName:@"wantobuys"];
    [wtbQuery whereKey:@"postUser" equalTo:self.user];
    [wtbQuery whereKey:@"status" containedIn:@[@"live",@"purchased"]];
    [wtbQuery orderByDescending:@"lastUpdated"];
    [wtbQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            //put the sold listings at the end
            NSSortDescriptor *sortDescriptorStatus = [[NSSortDescriptor alloc]
                                                      initWithKey: @"status" ascending: YES];
            NSSortDescriptor *sortDescriptorUpdated = [[NSSortDescriptor alloc] initWithKey:@"lastUpdated" ascending:NO];
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
            NSLog(@"error getting WTBs %@", error);
        }
    }];
}

-(void)loadBumpedListings{
    NSLog(@"load bumped listings");
    
    __block NSArray *totalBumped = [self.user objectForKey:@"totalBumpArray"];
    __block NSMutableArray *totalBumpedObjects = [NSMutableArray array];

    NSArray *wantedBumped = [self.user objectForKey:@"wantedBumpArray"];

    PFQuery *bumpedListings = [PFQuery queryWithClassName:@"wantobuys"];
    [bumpedListings whereKey:@"status" containedIn:@[@"live",@"purchased"]];
    [bumpedListings whereKey:@"objectId" containedIn:wantedBumped];
    
    [bumpedListings findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            [totalBumpedObjects addObjectsFromArray:objects];
            
            //now retrieve WTS Bumps
            NSArray *saleBumped = [self.user objectForKey:@"saleBumpArray"];
            
            PFQuery *bumpedSaleListings = [PFQuery queryWithClassName:@"forSaleItems"];
            [bumpedSaleListings whereKey:@"status" containedIn:@[@"live",@"sold"]];
            [bumpedSaleListings whereKey:@"objectId" containedIn:saleBumped];
            
            [bumpedSaleListings findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (objects) {
                    [totalBumpedObjects addObjectsFromArray:objects];

                    //reset arrays
                    [self.bumpedArray removeAllObjects];
                    [self.bumpedIds removeAllObjects];
                    
                    //display correct label
                    if (self.tabMode == YES && self.segmentedControl.selectedSegmentIndex == 2 && totalBumpedObjects.count == 0) {
                        //bump selected on own profile & nothing to show
                        [self.createButton setHidden:YES];
                        [self.actionLabel setHidden:NO];
                        self.actionLabel.text = @"Like listings to save them for later";
                        
                        [self.bumpLabel setHidden:YES];
                        [self.bumpImageView setHidden:YES];
                        
                    }
                    else if(self.segmentedControl.selectedSegmentIndex == 2 && totalBumpedObjects.count == 0 && self.tabMode != YES){
                        [self.actionLabel setHidden:NO];
                        self.actionLabel.text = @"nothing to show";
                        
                        [self.createButton setHidden:YES];
                        [self.bumpImageView setHidden:YES];
                        [self.bumpLabel setHidden:YES];
                    }
                    else if (totalBumpedObjects.count != 0 && self.segmentedControl.selectedSegmentIndex == 2) {
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
                    
                    if (self.segmentedControl.selectedSegmentIndex == 2) {
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
                    NSLog(@"error getting WTS bumped objects %@", error);
                }
            }];
            
            
        }
        else{
            NSLog(@"error getting wanted bumped %@", error);
        }
    }];
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
        [self.saleQuery orderByDescending:@"lastUpdated"];
    }
    
    [self.saleQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {

            //put the sold listings at the end
            NSSortDescriptor *sortDescriptorStatus = [[NSSortDescriptor alloc]
                                                initWithKey: @"status" ascending: YES];
            NSSortDescriptor *sortDescriptorUpdated = [[NSSortDescriptor alloc] initWithKey:@"lastUpdated" ascending:NO];
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
            
            self.loadingSales = NO;

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
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        return self.forSaleArray.count;
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1){
        return self.WTBArray.count;
    }
    else if (self.segmentedControl.selectedSegmentIndex == 2){
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

    cell.itemImageView.image = nil;
    cell.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    PFObject *listingObject;
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
//        NSLog(@"WTS selected");
        listingObject = [self.forSaleArray objectAtIndex:indexPath.row];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1){
//        NSLog(@"WTB selected");
        listingObject = [self.WTBArray objectAtIndex:indexPath.row];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 2){
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
    if ([[listingObject objectForKey:@"status"]isEqualToString:@"purchased"] && self.segmentedControl.selectedSegmentIndex != 2) {
        cell.itemImageView.alpha = 0.5;
        [cell.purchasedImageView setImage:[UIImage imageNamed:@"purchasedIcon2"]];
        [cell.purchasedImageView setHidden:NO];
    }
    else if ([[listingObject objectForKey:@"status"]isEqualToString:@"sold"] && self.segmentedControl.selectedSegmentIndex != 2) {
        cell.itemImageView.alpha = 0.5;
        [cell.purchasedImageView setImage:[UIImage imageNamed:@"soldIcon2"]];
        [cell.purchasedImageView setHidden:NO];
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
        vc.seller = [selected objectForKey:@"sellerUser"];

        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1){
        [Answers logCustomEventWithName:@"Profile Item Selected"
                       customAttributes:@{
                                          @"type": @"WTB"
                                          }];
        
        NSLog(@"WTB selected");
        PFObject *listing = [self.WTBArray objectAtIndex:indexPath.row];
        self.WTBPressed = YES;
        ListingController *vc = [[ListingController alloc]init];
        vc.listingObject = listing;
        if (self.tabMode) {
            vc.delegate = self;
        }
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 2){
        
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
            vc.seller = [selected objectForKey:@"sellerUser"];

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
        [Answers logCustomEventWithName:@"Facebook Profile Pressed"
                       customAttributes:@{
                                          @"ownProfile": @"YES"
                                          }];
    }
    else{
        [Answers logCustomEventWithName:@"Facebook Profile Pressed"
                       customAttributes:@{
                                          @"ownProfile": @"NO"
                                          }];
    }
    
    NSString *URLString = [NSString stringWithFormat:@"https://facebook.com/%@", [self.user objectForKey:@"facebookId"]];
    self.webView = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
    self.webView.title = @"F A C E B O O K";
    self.webView.showUrlWhileLoading = YES;
    self.webView.showPageTitles = NO;
    self.webView.doneButtonTitle = @"";
    self.webView.payMode = NO;
//    self.webView.infoMode = NO;
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

-(void)selectedReportReason:(NSString *)reason{
    [Answers logCustomEventWithName:@"Reported User"
                   customAttributes:@{}];

    //send message from team bump saying we're looking into it
    [self sendReportMessageWithReason:reason];
    
    PFObject *reportObject = [PFObject objectWithClassName:@"ReportedUsers"];
    reportObject[@"reportedUser"] = self.user;
    reportObject[@"reporter"] = [PFUser currentUser];
    [reportObject saveInBackground];
}

-(void)sendReportMessageWithReason:(NSString *)reason{
    //save message first
    NSString *messageString = @"";
    
    if ([reason isEqualToString:@"Other"]) {
        if ([[PFUser currentUser]objectForKey:@"firstName"]) {
            messageString = [NSString stringWithFormat:@"Hey %@,\n\nThanks for helping keep the Bump community safe and reporting user @%@\n\nMind telling us why you reported the user?\n\nSophie\nTeam Bump",[[PFUser currentUser]objectForKey:@"firstName"],self.user.username];
        }
        else{
            messageString = [NSString stringWithFormat:@"Hey,\n\nThanks for helping keep the Bump community safe and reporting user @%@\n\nMind telling us why you reported the user?\n\nSophie\nTeam Bump",self.user.username];
        }
    }
    else{
        if ([[PFUser currentUser]objectForKey:@"firstName"]) {
            messageString = [NSString stringWithFormat:@"Hey %@,\n\nThanks for helping to keep the Bump community safe and reporting user @%@\n\nReason: %@\n\nWe'll get in touch if we have any more questions 👊\n\nSophie\nTeam Bump",[[PFUser currentUser]objectForKey:@"firstName"],self.user.username, reason];
        }
        else{
            messageString = [NSString stringWithFormat:@"Hey,\n\nThanks for helping to keep the Bump community safe and reporting user @%@\n\nReason: %@\n\nWe'll get in touch if we have any more questions 👊\n\nSophie\nTeam Bump",self.user.username, reason];
        }
    }
    
    //now save report message
    PFObject *messageObject1 = [PFObject objectWithClassName:@"teamBumpMsgs"];
    messageObject1[@"message"] = messageString;
    messageObject1[@"sender"] = [PFUser currentUser];
    messageObject1[@"senderId"] = @"BUMP";
    messageObject1[@"senderName"] = @"Team Bump";
    messageObject1[@"convoId"] = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
    messageObject1[@"status"] = @"sent";
    messageObject1[@"offer"] = @"NO";
    messageObject1[@"mediaMessage"] = @"NO";
    messageObject1[@"boostMessage"] = @"YES";
    [messageObject1 saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            
            //update profile tab bar badge
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [[appDelegate.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:@"1"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NewTBMessageReg"];
            
            //update convo
            PFQuery *convoQuery = [PFQuery queryWithClassName:@"teamConvos"];
            NSString *convoId = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
            [convoQuery whereKey:@"convoId" equalTo:convoId];
            [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    
                    //got the convo
                    [object incrementKey:@"totalMessages"];
                    [object setObject:messageObject1 forKey:@"lastSent"];
                    [object setObject:[NSDate date] forKey:@"lastSentDate"];
                    [object incrementKey:@"userUnseen"];
                    [object saveInBackground];
                    
                    [Answers logCustomEventWithName:@"Sent Report Message"
                                   customAttributes:@{
                                                      @"status":@"SENT",
                                                      @"type":@"User"
                                                      }];
                }
                else{
                    [Answers logCustomEventWithName:@"Sent Report Message"
                                   customAttributes:@{
                                                      @"status":@"Failed getting convo",
                                                      @"type":@"User"
                                                      }];
                }
            }];
        }
        else{
            NSLog(@"error saving report message %@", error);
            [Answers logCustomEventWithName:@"Sent Report Message"
                           customAttributes:@{
                                              @"status":@"Failed saving message",
                                              @"type":@"User"
                                              }];
        }
    }];
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
        if (self.segmentedControl.selectedSegmentIndex == 1) {
            //wanted
            self.WTBSelected = YES;
            self.WTSSelected = NO;
            self.bumpsSelected = NO;
            
            if (self.WTBArray.count == 0) {
                [self.createButton setHidden:NO];
                self.actionLabel.text = @"Let sellers know what you want";
                [self.actionLabel setHidden:NO];
                
                [self.bumpImageView setHidden:YES];
                [self.bumpLabel setHidden:YES];
            }
            
        }
        else if (self.segmentedControl.selectedSegmentIndex == 0) {
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
        if (self.segmentedControl.selectedSegmentIndex == 1) {
            [self hideFilter];

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
        else if (self.segmentedControl.selectedSegmentIndex == 0) {
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
        
        //Copy Link
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Copy Profile Link" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [Answers logCustomEventWithName:@"Copied Link"
                           customAttributes:@{
                                              @"link":@"profile"
                                              }];
            
            NSString *urlString = [NSString stringWithFormat:@"http://sobump.com/p?profile=%@",self.user.username];
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            [pb setString:urlString];
            
            //show HUD
            [self showHUDForCopy:YES];
            
            double delayInSeconds = 2.0; // number of seconds to wait
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self hideHUD];
                self.hud.labelText = @"";
            });
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Report User" message:@"Why would you like to report this user?" preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Selling fakes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self selectedReportReason:@"Selling fakes"];
            }]];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Offensive behaviour" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self selectedReportReason:@"Offensive behaviour"];
            }]];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Spamming" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self selectedReportReason:@"Spamming"];
            }]];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Other" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self selectedReportReason:@"Other"];
            }]];
            
            [self presentViewController:alertView animated:YES completion:nil];
            
        }]];
        
//        if (self.userBlocked) {
//            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Unblock" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
//                [self unblockUser];
//            }]];
//        }
//        else{
//            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Block" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
//                [self blockUser];
//            }]];
//        }

    }
    else{
        //Copy Link
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Copy Profile Link" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [Answers logCustomEventWithName:@"Copied Link"
                           customAttributes:@{
                                              @"link":@"profile"
                                              }];
            
            NSString *urlString = [NSString stringWithFormat:@"http://sobump.com/p?profile=%@",self.user.username];
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            [pb setString:urlString];
            
            //show HUD
            [self showHUDForCopy:YES];
            
            double delayInSeconds = 2.0; // number of seconds to wait
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self hideHUD];
                self.hud.labelText = @"";
            });
        }]];
    }
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)setupMessages{
    [self showHUDForCopy:NO];
    
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

-(void)showHUDForCopy:(BOOL)copying{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    if (!copying) {
        self.hud.customView = self.spinner;
        [self.spinner startAnimating];
    }
    else{
        self.hud.labelText = @"Copied";
    }
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.hud = nil;
    });
}

-(void)backPressed{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)setupHeaderBar{
    int heightInt = 0;
    
    if (self.hasBio || self.tabMode) {
        heightInt = 390;
    }
    else{
        heightInt = 340;
    }

    self.myBar = [[BLKFlexibleHeightBar alloc] initWithFrame:CGRectMake(0.0, 0.0, [UIApplication sharedApplication].keyWindow.frame.size.width,heightInt)]; //was 340
    self.myBar.minimumBarHeight = 114.0;
    self.myBar.backgroundColor = [UIColor whiteColor];
    self.myBar.behaviorDefiner = [SquareCashStyleBehaviorDefiner new];
    
    //create a splitter so collection view can respond to its own delegate methods AND flexibar can copy the CV's scroll view
    self.splitter = [[BLKDelegateSplitter alloc] initWithFirstDelegate:self secondDelegate:self.myBar.behaviorDefiner];
    
    self.collectionView.delegate = (id<UICollectionViewDelegate>)self.splitter;
    
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInset = UIEdgeInsetsMake(self.myBar.maximumBarHeight-20, 0.0, 0.0, 0.0);
    }
    else{
        //seeing odd behaviour with collection view. Same sizes on iOS 10 & 11 but 11 has a larger top inset..
        self.collectionView.contentInset = UIEdgeInsetsMake(self.myBar.maximumBarHeight, 0.0, 0.0, 0.0);
    }
    
    // big mode setup
    
    //bg colour view
    if (self.hasBio || self.tabMode) {
        self.bgView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.myBar.frame.size.width, (self.myBar.frame.size.height/2-40))];//-25
    }
    else{
        self.bgView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.myBar.frame.size.width, (self.myBar.frame.size.height/2-15))];
    }
    
    self.bgView.backgroundColor = [UIColor colorWithRed:0.96 green:0.97 blue:0.99 alpha:1.0];
    [self.myBar addSubview:self.bgView];
    
    //profile image
    self.userImageView = [[PFImageView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
    [self.userImageView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    [self setImageBorder:self.userImageView];
    [self.myBar addSubview:self.userImageView];
    
    //name & location
    self.nameAndLoc = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
    self.nameAndLoc.numberOfLines = 2;
    self.nameAndLoc.font = [UIFont fontWithName:@"PingFangSC-Medium" size:13];
    self.nameAndLoc.textColor = [UIColor blackColor];
    self.nameAndLoc.textAlignment = NSTextAlignmentCenter;
    //[self.nameAndLoc sizeToFit];
    [self.myBar addSubview:self.nameAndLoc];
    
    //top username
    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
    self.usernameLabel.numberOfLines = 1;
    self.usernameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:13];
    self.usernameLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
    self.usernameLabel.textAlignment = NSTextAlignmentCenter;
    [self.myBar addSubview:self.usernameLabel];

    //verified label
    self.verifiedWithLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
    self.verifiedWithLabel.numberOfLines = 1;
    self.verifiedWithLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:13];
    self.verifiedWithLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
    self.verifiedWithLabel.textAlignment = NSTextAlignmentCenter;
    self.verifiedWithLabel.text = @"Verified with:";
    [self.myBar addSubview:self.verifiedWithLabel];
    
    //verified with image view
    self.verifiedImageView = [[PFImageView alloc]initWithFrame:CGRectMake(0, 0, 50, 18)];
    [self.myBar addSubview:self.verifiedImageView];
    
    //add verification button
    if (self.tabMode) {
        self.moreVeriButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 18)];
        [self.moreVeriButton addTarget:self action:@selector(moreVeriPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.myBar addSubview:self.moreVeriButton];
    }
    
    //divider img view
    self.dividerImgView = [[PFImageView alloc]initWithFrame:CGRectMake(0, 0, 1, 40)];
    self.dividerImgView.backgroundColor = [UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0];
    [self.myBar addSubview:self.dividerImgView];
    
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
    
    if (self.tabMode) {
        self.ordersButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
        [self.ordersButton setImage:[UIImage imageNamed:@"ordersIcon"] forState:UIControlStateNormal];
        [self.ordersButton addTarget:self action:@selector(ordersButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    
    //facebook button
    self.FBButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.FBButton setImage:[UIImage imageNamed:@"FBFillBlk"] forState:UIControlStateNormal];
    [self.FBButton addTarget:self action:@selector(fbPressed) forControlEvents:UIControlEventTouchUpInside];
    
    //dots button
    self.dotsButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.myBar addSubview:self.dotsButton];
    
    //stars image view
    self.starImageView = [[PFImageView alloc]initWithFrame:CGRectMake(0, 0, 100, 18)];
    //[self.myBar addSubview:self.starImageView];
    
    //reviews label
    self.reviewsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 300, 30)];
    self.reviewsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.reviewsButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
    [self.reviewsButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];
    [self.reviewsButton addTarget:self action:@selector(ReviewsPressed) forControlEvents:UIControlEventTouchUpInside];
    
    //[self.myBar addSubview:self.reviewsLabel];
    
    //////////
    //views for when bar collapses
    
    //small imageview
    self.smallImageView = [[PFImageView alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.smallImageView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    [self setImageBorder:self.smallImageView];
    [self.myBar addSubview:self.smallImageView];
    
    //small name / loc label
    self.smallNameAndLoc = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    self.smallNameAndLoc.numberOfLines = 2;
    self.smallNameAndLoc.font = [UIFont fontWithName:@"PingFangSC-Medium" size:10];
    self.smallNameAndLoc.textColor = [UIColor blackColor];
    self.smallNameAndLoc.textAlignment = NSTextAlignmentLeft;
    [self.myBar addSubview:self.smallNameAndLoc];
    
    [self.view addSubview:self.myBar];
    
    //setup subviews then add specific y values depending on if user has a bio
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialDividerView = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialDividerView.frame = self.dividerImgView.frame;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributes = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributes.size = self.userImageView.frame.size;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesUsernameLabel = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesUsernameLabel.size = self.usernameLabel.frame.size;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesVerifiedLabel = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesVerifiedLabel.size = self.verifiedWithLabel.frame.size;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesStarView = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesStarView.size = self.starImageView.frame.size;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesVerifiedImageView = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesVerifiedImageView.size = self.verifiedImageView.frame.size;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesVeriButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesVeriButton.size = self.moreVeriButton.frame.size;
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesReviews = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesReviews.size = self.reviewsButton.frame.size;
    
    if (self.hasBio || self.tabMode) {
        //setup bar subviews with additional space for bio
        
        //bio label
        self.bioLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 25)];
        self.bioLabel.numberOfLines = 1;
        self.bioLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
        self.bioLabel.textAlignment = NSTextAlignmentCenter;
        [self.myBar addSubview:self.bioLabel];
        
        //set bio upon start (also in fetch for if user updates)
        if ([self.user objectForKey:@"bio"]) {
            if (![[self.user objectForKey:@"bio"]isEqualToString:@""]) {
                self.bioLabel.text = [self.user objectForKey:@"bio"];
                self.bioLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
            }
            else{
                //put this check in, incase user had a bio but then deleted it
                self.bioLabel.text = @"Tap to add a bio";
                self.bioLabel.textColor = [UIColor lightGrayColor];
            }
        }
        else{
            //fail safe
            self.bioLabel.text = @"Tap to add a bio";
            self.bioLabel.textColor = [UIColor lightGrayColor];
        }
        
        self.addBioButton = [[UIButton alloc]initWithFrame:self.bioLabel.frame];
        [self.addBioButton addTarget:self action:@selector(addBioTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.myBar addSubview:self.addBioButton];
        
        //divider view
        initialDividerView.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)+65.0);//-25
        
        //image view
        initialLayoutAttributes.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)-40.0);//-25
        
        //top username label
        initialLayoutAttributesUsernameLabel.center = CGPointMake(CGRectGetMidX(self.myBar.bounds)+(CGRectGetMidX(self.myBar.bounds)/2), CGRectGetMidY(self.myBar.bounds)+35.0);//-25
        
        //verified with
        initialLayoutAttributesVerifiedLabel.center = CGPointMake(CGRectGetMidX(self.myBar.bounds)-(CGRectGetMidX(self.myBar.bounds)/2), CGRectGetMidY(self.myBar.bounds)+35.0);//-25
        
        //stars view
        initialLayoutAttributesStarView.center = CGPointMake(CGRectGetMidX(self.myBar.bounds),CGRectGetMidY(self.myBar.bounds)-(((CGRectGetMidY(self.myBar.bounds)/2)+12.5)));//-25 .... needed to half 25 since theres a division of the midpoint happening
        
        //verified with: img view
        initialLayoutAttributesVerifiedImageView.center = CGPointMake(CGRectGetMidX(self.myBar.bounds)-(CGRectGetMidX(self.myBar.bounds)/2), CGRectGetMidY(self.myBar.bounds)+65.0);//-25
        
        //verify button
        initialLayoutAttributesVeriButton.center = CGPointMake(CGRectGetMidX(self.myBar.bounds)-(CGRectGetMidX(self.myBar.bounds)/2), CGRectGetMidY(self.myBar.bounds)+65.0);//-25
        
        //reviews label
        initialLayoutAttributesReviews.center = CGPointMake(CGRectGetMidX(self.myBar.bounds)+(CGRectGetMidX(self.myBar.bounds)/2), CGRectGetMidY(self.myBar.bounds)+65.0);//-25
        
        //bio label
        BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesBioLabel = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
        initialLayoutAttributesBioLabel.size = self.bioLabel.frame.size;
        initialLayoutAttributesBioLabel.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)+115.0);//-25
        
        [self.bioLabel addLayoutAttributes:initialLayoutAttributesBioLabel forProgress:0.0];
        
        //bio label final
        BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesBio = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesBioLabel];
        finalLayoutAttributesBio.alpha = 0.0;
        [self.bioLabel addLayoutAttributes:finalLayoutAttributesBio forProgress:0.1];
        
        //bio button
        BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesBioButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
        initialLayoutAttributesBioButton.size = self.addBioButton.frame.size;
        initialLayoutAttributesBioButton.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)+115.0);//-25
        [self.addBioButton addLayoutAttributes:initialLayoutAttributesBioButton forProgress:0.0];
        
        //bio button final
        BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesBioButton = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesBioButton];
        finalLayoutAttributesBioButton.alpha = 0.0;
        [self.addBioButton addLayoutAttributes:finalLayoutAttributesBio forProgress:0.1];
    }
    else{
        //normal bar height without bio
        
        //divider view
        initialDividerView.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)+90.0);
        
        //image view
        initialLayoutAttributes.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)-15.0);
        
        //top username label
        initialLayoutAttributesUsernameLabel.center = CGPointMake(CGRectGetMidX(self.myBar.bounds)+(CGRectGetMidX(self.myBar.bounds)/2), CGRectGetMidY(self.myBar.bounds)+60.0);
        
        //verified with
        initialLayoutAttributesVerifiedLabel.center = CGPointMake(CGRectGetMidX(self.myBar.bounds)-(CGRectGetMidX(self.myBar.bounds)/2), CGRectGetMidY(self.myBar.bounds)+60.0);
        
        //stars view
        initialLayoutAttributesStarView.center = CGPointMake(CGRectGetMidX(self.myBar.bounds),CGRectGetMidY(self.myBar.bounds)-((CGRectGetMidY(self.myBar.bounds)/2)));
        
        //verified with: img view
        initialLayoutAttributesVerifiedImageView.center = CGPointMake(CGRectGetMidX(self.myBar.bounds)-(CGRectGetMidX(self.myBar.bounds)/2), CGRectGetMidY(self.myBar.bounds)+90.0);
        
        //verify button
        initialLayoutAttributesVeriButton.center = CGPointMake(CGRectGetMidX(self.myBar.bounds)-(CGRectGetMidX(self.myBar.bounds)/2), CGRectGetMidY(self.myBar.bounds)+90.0);
        
        //reviews label
        initialLayoutAttributesReviews.center = CGPointMake(CGRectGetMidX(self.myBar.bounds)+(CGRectGetMidX(self.myBar.bounds)/2), CGRectGetMidY(self.myBar.bounds)+90.0);
        
    }
    
    //bg view
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialBgView = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialBgView.frame = self.bgView.frame;
    [self.bgView addLayoutAttributes:initialBgView forProgress:0.0];
    
    
    //small image view
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesSmallImage = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesSmallImage.size = self.smallImageView.frame.size;
    initialLayoutAttributesSmallImage.frame = CGRectMake(100, 25, 30, 30);
    initialLayoutAttributesSmallImage.alpha = 0.0f;
    [self.smallImageView addLayoutAttributes:initialLayoutAttributesSmallImage forProgress:0.0];
    
    //small username /loc view
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesSmallName = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesSmallName.size = self.smallNameAndLoc.frame.size;
    initialLayoutAttributesSmallName.frame = CGRectMake(135, 25, 200, 30);
    initialLayoutAttributesSmallName.alpha = 0.0f;
    [self.smallNameAndLoc addLayoutAttributes:initialLayoutAttributesSmallName forProgress:0.0];
    
    //name & loc label
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesLabel = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesLabel.size = self.nameAndLoc.frame.size;
    initialLayoutAttributesLabel.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), 50);
    
    //back button
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesBackButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesBackButton.size = self.backButton.frame.size;
    initialLayoutAttributesBackButton.frame = CGRectMake(5, 25, 30, 30);
    
    //orders button
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialLayoutAttributesOrdersButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    initialLayoutAttributesOrdersButton.size = self.ordersButton.frame.size;
    initialLayoutAttributesOrdersButton.frame = CGRectMake(55, 25, 30, 30);
    
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

    [self.verifiedWithLabel addLayoutAttributes:initialLayoutAttributesVerifiedLabel forProgress:0.0];
    [self.verifiedImageView addLayoutAttributes:initialLayoutAttributesVerifiedImageView forProgress:0.0];
    [self.moreVeriButton addLayoutAttributes:initialLayoutAttributesVeriButton forProgress:0.0];

    [self.starImageView addLayoutAttributes:initialLayoutAttributesStarView forProgress:0.0];
    [self.reviewsButton addLayoutAttributes:initialLayoutAttributesReviews forProgress:0.0];
    [self.backButton addLayoutAttributes:initialLayoutAttributesBackButton forProgress:0.0];
    [self.FBButton addLayoutAttributes:initialLayoutAttributesfbButton forProgress:0.0];
    [self.dotsButton addLayoutAttributes:initialLayoutAttributesDotsButton forProgress:0.0];
    [self.dividerImgView addLayoutAttributes:initialDividerView forProgress:0.0];
    
    [self.ordersButton addLayoutAttributes:initialLayoutAttributesOrdersButton forProgress:0.0];


    
    // small mode
    
    //bg view
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalBgAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialBgView];
    finalBgAttributes.alpha = 0.0;
    [self.bgView addLayoutAttributes:finalBgAttributes forProgress:0.4];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalDividerAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialDividerView];
    finalDividerAttributes.alpha = 0.0;
    [self.dividerImgView addLayoutAttributes:finalDividerAttributes forProgress:0.4];
    
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
    
    // verified label final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesVerified = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesVerifiedLabel];
    finalLayoutAttributesVerified.alpha = 0.0;
    [self.verifiedWithLabel addLayoutAttributes:finalLayoutAttributesVerified forProgress:0.2];
    
    
    //verified img view final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesVerifiedImageView = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesVerifiedImageView];
    finalLayoutAttributesVerifiedImageView.alpha = 0.0;
    [self.verifiedImageView addLayoutAttributes:finalLayoutAttributesVerifiedImageView forProgress:0.1];
    
    //veri button
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesVeriButton = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesVeriButton];
    finalLayoutAttributesVeriButton.alpha = 0.0;
    [self.moreVeriButton addLayoutAttributes:finalLayoutAttributesVeriButton forProgress:0.2];
    
    // star view final
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalLayoutAttributesStar = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialLayoutAttributesStarView];
    finalLayoutAttributesStar.alpha = 0.0;
    [self.starImageView addLayoutAttributes:finalLayoutAttributesStar forProgress:0.8];
    
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
        
        //editImageView
        self.editImageView = [[PFImageView alloc]initWithFrame:CGRectMake(0,0, 30, 30)];
        [self.editImageView setImage:[UIImage imageNamed:@"editButton"]];
//        [self.myBar addSubview:self.editImageView];
        
        //image view button initial
        BLKFlexibleHeightBarSubviewLayoutAttributes *initialImageButton = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
        
        //edit button initial attributes
        BLKFlexibleHeightBarSubviewLayoutAttributes *editAttributes = [BLKFlexibleHeightBarSubviewLayoutAttributes new];

        if (self.hasBio || self.tabMode) {
            initialImageButton.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)-40.0);//-25
            editAttributes.center = CGPointMake(CGRectGetMidX(self.myBar.bounds)+40, CGRectGetMidY(self.myBar.bounds)-5.0);//-25

        }
        else{
            initialImageButton.center = CGPointMake(CGRectGetMidX(self.myBar.bounds), CGRectGetMidY(self.myBar.bounds)-15.0);
            editAttributes.center = CGPointMake(CGRectGetMidX(self.myBar.bounds)+40, CGRectGetMidY(self.myBar.bounds)+20.0);
        }
        
        initialImageButton.size = self.userImageView.frame.size;
        [self.imageButton addLayoutAttributes:initialImageButton forProgress:0.0];
        
        editAttributes.size = self.editImageView.frame.size;
        [self.editImageView addLayoutAttributes:editAttributes forProgress:0.0];
        
        // image button final
        BLKFlexibleHeightBarSubviewLayoutAttributes *finalImageButtonAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialImageButton];
        finalImageButtonAttributes.alpha = 0.0;
        [self.imageButton addLayoutAttributes:finalImageButtonAttributes forProgress:0.4];

        //final attributes
        BLKFlexibleHeightBarSubviewLayoutAttributes *finalEditAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:editAttributes];
        finalEditAttributes.alpha = 0.0;
        [self.editImageView addLayoutAttributes:finalEditAttributes forProgress:0.4];
    }
    
    //finish on this so we can update button images if any unread upon first tap on user's profile
    [self calcTabBadge];
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
    [self showHUDForCopy:NO];
//    UIImage *imageToSave = [self.profileImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(750.0, 750.0) interpolationQuality:kCGInterpolationHigh];
    UIImage *imageToSave = [self.profileImage scaleImageToSize:CGSizeMake(400, 400)];

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
    profile.modal = YES;
    profile.delegate = self;
    
    if (self.messagesUnseen > 0) {
        profile.unseenTBMsg = YES;
    }
    
    if (self.supportUnseen > 0) {
        profile.unseenSupport = YES;
    }
    
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:profile];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)newTBMessage{
    [self calcTabBadge];
}

-(void)newTBMessageReg{
    self.messagesUnseen = 1;
    [self.backButton setImage:[UIImage imageNamed:@"unreadCog"] forState:UIControlStateNormal];
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
    [self.tabBarController setSelectedIndex:1];
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.segmentedControl.selectedSegmentIndex == 0){
            //selling
            [[NSNotificationCenter defaultCenter] postNotificationName:@"openSell" object:nil];
        }
        else if (self.segmentedControl.selectedSegmentIndex == 1){
            //wanted
            [[NSNotificationCenter defaultCenter] postNotificationName:@"openWTB" object:nil];
        }
    });
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
                    
                    [self showAlertWithTitle:@"Linking Error" andMsg:@"You may have already signed up for Bump with your Facebook account\n\nSend Team Bump a message from Settings and we'll get it sorted!"];
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
                 [bumpedObj setObject:[self.user objectForKey:@"facebookId"] forKey:@"facebookId"];
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
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Verify Email 📩" message:@"We've just sent you a confirmation email! Be sure to check your Junk Folder for an email from Team Bump\n\nIf you still can't find it, make sure your email is correct in settings then try again here in 5 mins so we can send another!\n\nPs the Gmail app doesn't like links! Try opening the email in the native iPhone Mail app" preferredStyle:UIAlertControllerStyleAlert];
    
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
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Verify Email 📩" message:@"We've already sent you 3 confirmation emails!\n\nBe sure to check your Junk Folder for an email from Team Bump. If you still can't find it, send Team Bump a message\n\nPs the Gmail app doesn't like links! Try opening the email in the native iPhone Mail app" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Message Team Bump" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Message Team Bump Pressed from Max Email Alert"
                       customAttributes:@{}];
        
        //goto Team Bump messages
        PFQuery *convoQuery = [PFQuery queryWithClassName:@"teamConvos"];
        NSString *convoId = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
        [convoQuery whereKey:@"convoId" equalTo:convoId];
        [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                //convo exists, go there
                ChatWithBump *vc = [[ChatWithBump alloc]init];
                vc.convoId = [object objectForKey:@"convoId"];
                vc.convoObject = object;
                vc.otherUser = [PFUser currentUser];
                
                //unhide nav bar
                [self.navigationController pushViewController:vc animated:YES];
            }
            else{
                //create a new one
                PFObject *convoObject = [PFObject objectWithClassName:@"teamConvos"];
                convoObject[@"otherUser"] = [PFUser currentUser];
                convoObject[@"convoId"] = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
                convoObject[@"totalMessages"] = @0;
                [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        //saved, goto VC
                        ChatWithBump *vc = [[ChatWithBump alloc]init];
                        vc.convoId = [convoObject objectForKey:@"convoId"];
                        vc.convoObject = convoObject;
                        vc.otherUser = [PFUser currentUser];
                        
                        //unhide nav bar
                        [self.navigationController pushViewController:vc animated:YES];
                    }
                    else{
                        NSLog(@"error saving convo");
                    }
                }];
            }
        }];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showVerifyEmailAlert{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Verify Email 📩" message:[NSString stringWithFormat:@"We'll send an email with a verification link to '%@'\n\nIf this is correct, hit send! Or you can change your email address in Settings\n\nRemember to check your Junk Folder!\n\nPs the Gmail app doesn't like links! Try opening the email in the native iPhone Mail app ",[[PFUser currentUser]objectForKey:@"email"]] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Send Confirmation Email" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        if ([[PFUser currentUser]objectForKey:@"email"]) {
            NSDictionary *params = @{@"toEmail": [[PFUser currentUser]objectForKey:@"email"]};
            [PFCloud callFunctionInBackground:@"sendConfirmEmail" withParameters:params block:^(NSDictionary *response, NSError *error) {
                if (!error) {
                    NSLog(@"email response %@", response);
                    
                    [self showAlertWithTitle:@"Email Sent! 📬" andMsg:@"Remember to check your Junk Folder!"];
                    
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
//        [self.myBar addSubview:self.FBButton];
        
        self.needsFB = NO;
        self.needsEmail = NO;
        
    }
    else if ([self.user objectForKey:@"facebookId"] && [[self.user objectForKey:@"emailIsVerified"]boolValue] != YES ) {
//        [self.myBar addSubview:self.FBButton];
        
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
            [self.saleQuery orderByDescending:@"lastUpdated"];
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
        [self.saleQuery orderByDescending:@"lastUpdated"];
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
            [self showAlertWithTitle:@"User Blocked" andMsg:@"They can no longer message you on Bump, if you'd like some support just message Team Bump from Settings"];
        }
        else{
            [self showAlertWithTitle:@"Error Blocking User" andMsg:@"Send Team Bump a message from Settings to get this sorted"];
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
                    [self showAlertWithTitle:@"Error Unblocking User" andMsg:@"Send Team Bump a message from Settings to get this sorted"];
                }
            }];
        }
    }];
}

-(void)addHeaderView{
    [self setupHeaderBar];
    
    self.segmentedControl = [[HMSegmentedControl alloc] init];
    self.segmentedControl.frame = CGRectMake(0, self.myBar.frame.size.height-50,[UIApplication sharedApplication].keyWindow.frame.size.width, 50);
    self.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
    self.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
    self.segmentedControl.selectionIndicatorColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    self.segmentedControl.selectionIndicatorHeight = 2;
    self.segmentedControl.titleTextAttributes = @{NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Medium" size:10],NSForegroundColorAttributeName : [UIColor lightGrayColor]};
    self.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName :  [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]};
    [self.segmentedControl addTarget:self action:@selector(segmentControlChanged) forControlEvents:UIControlEventValueChanged];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *initialSegAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] init];
    initialSegAttributes.frame = CGRectMake(0, self.myBar.frame.size.height-50,[UIApplication sharedApplication].keyWindow.frame.size.width, 50);
    [self.segmentedControl addLayoutAttributes:initialSegAttributes forProgress:0];
    
    BLKFlexibleHeightBarSubviewLayoutAttributes *finalSegAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:initialSegAttributes];
    
    if (self.hasBio || self.tabMode) {
        finalSegAttributes.transform = CGAffineTransformMakeTranslation(0, -276);
    }
    else{
        finalSegAttributes.transform = CGAffineTransformMakeTranslation(0, -226);
    }
    [self.segmentedControl addLayoutAttributes:finalSegAttributes forProgress:1.0];
    [self.myBar addSubview:self.segmentedControl];
    
    //setup dots button
    [self.dotsButton setImage:[UIImage imageNamed:@"dotsFilled"] forState:UIControlStateNormal];
    [self.dotsButton addTarget:self action:@selector(showAlertView) forControlEvents:UIControlEventTouchUpInside];
    
    [self.segmentedControl setSectionTitles:@[@"S E L L I N G", @"W A N T E D", @"L I K E S"]];
    self.numberOfSegments = 3;
    
    self.WTBSelected = NO;
    self.WTSSelected = YES;
    self.bumpsSelected = NO;
}

-(void)addBioTapped{
    if (!self.hasBio) {
        [Answers logCustomEventWithName:@"Add bio pressed"
                       customAttributes:@{}];
        
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
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)updateOrderBadge:(NSNotification*)note {
    [self calcTabBadge];
}

-(void)calcTabBadge{
    NSLog(@"calc tab badge");
    
    //check if any support or team bump messages unseen
    int tabInt = 0;
    
    if (self.supportUnseen > 0 || self.messagesUnseen > 0) {
        tabInt++;
        [self.backButton setImage:[UIImage imageNamed:@"unreadCog"] forState:UIControlStateNormal];
    }
    else{
        [self.backButton setImage:[UIImage imageNamed:@"profileCog"] forState:UIControlStateNormal];
    }
    
    //then get number of unseen orders
    if (self.ordersUnseen > 0) {
        tabInt+= self.ordersUnseen;
        [self.ordersButton setImage:[UIImage imageNamed:@"ordersIconUnread"] forState:UIControlStateNormal];
    }
    else{
        [self.ordersButton setImage:[UIImage imageNamed:@"ordersIcon"] forState:UIControlStateNormal];
    }
    
    //add all together and set tab badge
    if (tabInt == 0) {
        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
    }
    else{
        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:[NSString stringWithFormat:@"%d",tabInt]];
    }
}
@end
