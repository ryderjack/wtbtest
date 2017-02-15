//
//  ExploreVC.m
//  
//
//  Created by Jack Ryder on 29/02/2016.
//
//

#import "ExploreVC.h"
#import <SVPullToRefresh/SVPullToRefresh.h>
#import "NavigationController.h"
#import <Crashlytics/Crashlytics.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "AppConstant.h"
#import "UserProfileController.h"
#import "ContainerViewController.h"
#import "Tut1ViewController.h"

@interface ExploreVC ()

@end

@implementation ExploreVC

@synthesize locationManager = _locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.noresultsLabel setHidden:YES];
    [self.noResultsImageView setHidden:YES];
    [self.filterButton setHidden:YES];
    [self.filterBGView setHidden:YES];
    
    self.filterButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.filterButton.titleLabel.minimumScaleFactor=0.5;
    
    self.navigationItem.title = @"W A N T E D";
    
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"searchBarButton"] style:UIBarButtonItemStylePlain target:self action:@selector(searchPressed)];
    self.navigationItem.leftBarButtonItem = searchButton;
    
    UIBarButtonItem *filterBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"filterBarIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(filterPressed:)];
    self.navigationItem.rightBarButtonItem = filterBarButton;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    //collection view/cell setup
    [self.collectionView registerClass:[ExploreCell class] forCellWithReuseIdentifier:@"Cell"];
    
    UINib *cellNib = [UINib nibWithNibName:@"ExploreCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [flowLayout setItemSize:CGSizeMake(148, 215)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.height == 736){
        //iphone 6 plus
        [flowLayout setItemSize:CGSizeMake(196, 285)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.height == 480){
        //iphone 4
        [flowLayout setItemSize:CGSizeMake(124, 180)];
    }
    else{
        [flowLayout setItemSize:CGSizeMake(175, 254)]; //iPhone 6 specific
    }
    [flowLayout setMinimumInteritemSpacing:0];
    [flowLayout setMinimumLineSpacing:8.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    flowLayout.headerReferenceSize = CGSizeMake(self.collectionView.frame.size.width, 50);
//    flowLayout.sectionHeadersPinToVisibleBounds = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBump:) name:@"showBumpedVC" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showListing:) name:@"listingBumped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDrop:) name:@"showDropDown" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetHome) name:@"refreshHome" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertLatestListing:) name:@"justPostedListing" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBumpDrop:) name:@"showBumpedDropDown" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageSentDrop:) name:@"messageSentDropDown" object:nil];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    self.results = [[NSMutableArray alloc]init];
    self.resultIDs = [[NSMutableArray alloc]init];
    
    //setup header
    [self.collectionView registerClass:[UICollectionReusableView class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                   withReuseIdentifier:@"HeaderView"];
    
    //location stuff
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"askedForLocationPermission"] || [[[PFUser currentUser]objectForKey:@"completedReg"]isEqualToString:@"YES"]) {
        
        //for users that have already seen the location diaglog before this update - use the completedReg BOOL to check
        if ([[NSUserDefaults standardUserDefaults]boolForKey:@"askedForLocationPermission"]==NO) {
            [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"askedForLocationPermission"];
        }
        self.locationAllowed = [CLLocationManager locationServicesEnabled];
        [self startLocationManager];
    }
    
    //refresh setup
    self.pullFinished = YES;
    self.infinFinished = YES;
    self.lastInfinSkipped = 0;
    
    self.filtersON = NO; 
    self.ignoreShownTo = NO;
    
    [self.collectionView setScrollsToTop:YES];
    
    self.filtersArray = [NSMutableArray array];
    
    // set searchbar font
    NSDictionary *searchAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                      NSFontAttributeName, nil];
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setDefaultTextAttributes:searchAttributes];
    
    
    if (![FBSDKAccessToken currentAccessToken]) {
        NSLog(@"invalid token in VDL");
        //invalid access token
        [PFUser logOut];
        WelcomeViewController *vc = [[WelcomeViewController alloc]init];
        vc.delegate = self;
        self.welcomeShowing = YES;
        NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else{
        //get updated friends list
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:@"me/friends"
                                      parameters:@{@"fields": @"id, name"}
                                      HTTPMethod:@"GET"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
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
                
                [[PFUser currentUser]setObject:friendsHoldingArray forKey:@"friends"];
                [[PFUser currentUser] saveInBackground];
            }
            else{
                NSLog(@"error on friends %li", (long)error.code);
                if (error.code == 8) {
                    //invalid access token
                    [PFUser logOut];
                    WelcomeViewController *vc = [[WelcomeViewController alloc]init];
                    vc.delegate = self;
                    self.welcomeShowing = YES;
                    NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
                    [self presentViewController:navController animated:YES completion:nil];
                }
                else{
                    [self showError];
                }
            }
        }];
    }
    
    PFUser *currentUser = [PFUser currentUser];
    
    if (currentUser) {
        if (![[currentUser objectForKey:@"completedReg"] isEqualToString:@"YES"]) {
            [Answers logCustomEventWithName:@"Registration error"
                           customAttributes:@{
                                              @"error":@"hasn't completed reg",
                                              @"user":currentUser.username
                                              }];
            [PFUser logOut];
            WelcomeViewController *vc = [[WelcomeViewController alloc]init];
            vc.delegate = self;
            self.welcomeShowing = YES;
            NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:navController animated:NO completion:nil];
        }
        
        //removed these variables as they're cripplingly rigid..
        
//        else if (![currentUser objectForKey:PF_USER_FULLNAME] || ![currentUser objectForKey:PF_USER_EMAIL] || ![currentUser objectForKey:@"currency"] || ![currentUser objectForKey:PF_USER_FACEBOOKID] || ![currentUser objectForKey: PF_USER_GENDER] || ![currentUser objectForKey:@"picture"]) {
//            //been an error on sign up as user doesn't have all info saved
//            
//            [Answers logCustomEventWithName:@"Registration error"
//                           customAttributes:@{
//                                              @"error":@"lack of info",
//                                              @"user":currentUser.username
//                                              }];
//            
//            currentUser[@"completedReg"] = @"NO";
//            [currentUser saveInBackground];
//            [PFUser logOut];
//            WelcomeViewController *vc = [[WelcomeViewController alloc]init];
//            NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
//            [self presentViewController:navController animated:NO completion:nil];
//        }
        else{
            //user has signed up fine
            
            //check if have lowercase fullname
            if (![currentUser objectForKey:@"fullnameLower"]) {
                //for search purposes so can search by name!
                currentUser[@"fullnameLower"] = [[[PFUser currentUser]objectForKey:@"fullname"]lowercaseString];
                [currentUser saveInBackground];
            }
            
            //check if bumps have been migrated to new system introduced in Build: 1156
            if (![[PFUser currentUser]objectForKey:@"bumpArray"]) {
                PFQuery *bumps = [PFQuery queryWithClassName:@"wantobuys"];
                [bumps whereKey:@"bumpArray" containsString:currentUser.objectId];
                [bumps findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (objects) {
                        if (objects.count == 0) {
                            currentUser[@"bumpArray"] = @[];
                        }
                        else{
                            NSMutableArray *placeholderBumps = [NSMutableArray array];
                            
                            //check for duplicates
                            for (PFObject *WTB in objects) {
                                if (![placeholderBumps containsObject:WTB.objectId]) {
                                    [placeholderBumps addObject:WTB.objectId];
                                }
                            }
                            currentUser[@"bumpArray"] = placeholderBumps;
                        }
                        [currentUser saveInBackground];
                    }
                    else{
                        NSLog(@"error finding previous bumps so reset %@", error);
                        currentUser[@"bumpArray"] = @[];
                        [currentUser saveInBackground];
                    }
                }];
            }
            
            //check if they have wanted words
            if (![currentUser objectForKey:@"wantedWords"]) {
                PFQuery *myPosts = [PFQuery queryWithClassName:@"wantobuys"];
                [myPosts whereKey:@"postUser" equalTo:currentUser];
                [myPosts orderByDescending:@"createdAt"];
                myPosts.limit = 10;
                [myPosts findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (objects) {
                        NSMutableArray *wantedWords = [NSMutableArray array];
                        
                        for (PFObject *listing in objects) {
                            NSArray *keywords = [listing objectForKey:@"searchKeywords"];
                            
                            for (NSString *word in keywords) {
                                if (![wantedWords containsObject:word]) {
                                    [wantedWords addObject:word];
                                }
                            }
                        }
                        NSLog(@"wanted words: %@", wantedWords);
                        [currentUser setObject:wantedWords forKey:@"wantedWords"];
                        [currentUser saveInBackground];
                    }
                    else{
                        NSLog(@"nee posts pet");
                    }
                }];
            }
            
            // finally check if they've been banned - put it last because otherwise if logout user from a previous user check this will still run and throw error 'can't do a comparison query for type (null)
            
            PFQuery *bannedQuery = [PFQuery queryWithClassName:@"bannedUsers"];
            [bannedQuery whereKey:@"user" equalTo:[PFUser currentUser]];
            [bannedQuery countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
                if (number > 1) {
                    //user is banned - log them out
                    [PFUser logOut];
                    WelcomeViewController *vc = [[WelcomeViewController alloc]init];
                    vc.delegate = self;
                    self.welcomeShowing = YES;
                    NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
                    [self presentViewController:navController animated:NO completion:nil];
                }
            }];
        }
    }
    self.uselessWords = [NSArray arrayWithObjects:@"x",@"to",@"with",@"and",@"the",@"wtb",@"or",@" ",@".",@"very",@"interested", @"in",@"wanted", @"", nil];

    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    PFQuery *versionQuery = [PFQuery queryWithClassName:@"versions"];
    [versionQuery orderByDescending:@"createdAt"];
    [versionQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            NSString *latest = [object objectForKey:@"number"];
            if (![appVersion isEqualToString:latest]) {
                UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"New update available" message:nil preferredStyle:UIAlertControllerStyleAlert];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                }]];
                [alertView addAction:[UIAlertAction actionWithTitle:@"Update" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:
                                                                @"itms-apps://itunes.apple.com/app/id1096047233"]];
                }]];
//                [self presentViewController:alertView animated:YES completion:nil]; //CHANGE
            }
        }
        else{
            NSLog(@"error getting latest version %@", error);
        }
    }];
    
//    [PFUser logOut]; //CHECK
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    //put refresh code here so it remembers correct UICollectionView insets - doesn't work in VDL
    [self.collectionView addPullToRefreshWithActionHandler:^{
        if (self.pullFinished == YES) {
            [self queryParsePull];
        }
    }];
    
     self.spinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
    [self.collectionView.pullToRefreshView setCustomView:self.spinner forState:SVPullToRefreshStateAll];
    [self.spinner startAnimating];
    
    [self.collectionView addInfiniteScrollingWithActionHandler:^{
        if (self.infinFinished == YES) {
            [self queryParseInfinite];
        }
    }];
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(8, 8, 8, 8); // top, left, bottom, right
}

-(void)viewWillAppear:(BOOL)animated{
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, [UIColor blackColor], NSForegroundColorAttributeName,  nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if (![PFUser currentUser]) {
        WelcomeViewController *vc = [[WelcomeViewController alloc]init];
        vc.delegate = self;
        self.welcomeShowing = YES;
        NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navController animated:NO completion:nil];
    }
    else{
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
    }
    
    if (!self.infiniteQuery) {
        self.infiniteQuery = [PFQuery queryWithClassName:@"wantobuys"];
    }
    if (!self.pullQuery && [PFUser currentUser]) {
        self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
        [self queryParsePull];
    }
    
    [self.infiniteQuery cancel];
    [self.collectionView.infiniteScrollingView stopAnimating];
    self.infinFinished = YES;
    
    if (self.listingTapped == YES) {
        
        //since listing tapped was always YES before then it is constantly reloading self.lastselected on every VWA even when lasttapped doesn't exist
        //must be happening when searching or filtering as they run out of items in the CV
        //so it tries to reload an item which isn't there
        
        self.listingTapped = NO; //set to NO so this ^ won't be happening (shouldn't)...
        if ([self.collectionView numberOfItemsInSection:0] >= self.lastSelected.row) {
            [self.collectionView reloadItemsAtIndexPaths:@[self.lastSelected]];
            //self.lastSelected = nil; was causing crash
        }
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

    [self.collectionView.infiniteScrollingView stopAnimating];
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Explore"
                                      }];
    
    if (self.filtersArray.count > 0) {
//        NSLog(@"got some filters brah %lu", self.filtersArray.count);
        [self.filterButton setTitle:[NSString stringWithFormat:@"F I L T E R S  %lu",self.filtersArray.count] forState:UIControlStateNormal];
    }
    if ([PFUser currentUser]) {
        
        if (![[[PFUser currentUser] objectForKey:@"searchIntro"] isEqualToString:@"YES"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"viewMorePressed"] != YES && [[[PFUser currentUser] objectForKey:@"completedReg"] isEqualToString:@"YES"]) {
            
            //trigger location for first sign in
            [self parseLocation];
            [self setUpIntroAlert];
        }
        
        //if user redownloaded - ask for push/location permissions again
        else if ([[NSUserDefaults standardUserDefaults]boolForKey:@"askedForPushPermission"] == NO && [[[PFUser currentUser] objectForKey:@"completedReg"]isEqualToString:@"YES"] && [[NSUserDefaults standardUserDefaults]boolForKey:@"declinedPushPermissions"] != YES && self.welcomeShowing != YES) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if (self.welcomeShowing == YES) {
                    NSLog(@"DONT SHOW, WELCOME SHOWING"); ////not sure if this works, needs more testing w/ logging in/out
                }
            });
            [self parseLocation];
            [self showPushReminder];
        }
    }
}

#pragma mark - custom segment control header

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        [headerView setBackgroundColor: [UIColor whiteColor]];
        
//        UIView *bgView = [[UIView alloc]initWithFrame:headerView.frame];
//        bgView.backgroundColor = [UIColor whiteColor];
//        bgView.alpha = 0.9;
//        
//        [headerView addSubview:bgView];
        
        self.segmentedControl = [[HMSegmentedControl alloc] init];
        self.segmentedControl.frame = headerView.frame;
        self.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
        self.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        self.segmentedControl.selectionIndicatorColor = [UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0];
        self.segmentedControl.titleTextAttributes = @{NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Medium" size:10]};
        self.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]};
        [self.segmentedControl addTarget:self action:@selector(segmentControlChanged) forControlEvents:UIControlEventValueChanged];
        self.segmentedControl.backgroundColor = [UIColor whiteColor];
        //self.segmentedControl = aSegmentedControl;
        [self.segmentedControl setSectionTitles:@[@"S U G G E S T E D", @"L A T E S T"]];
        [headerView addSubview:self.segmentedControl];

        if (self.latestMode == YES) {
            [self.segmentedControl setSelectedSegmentIndex:1];
        }
        
        reusableview = headerView;
        return reusableview;

    }
    else{
        return reusableview;
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    self.cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    self.cell.delegate = self;
    
    self.cell.layer.cornerRadius = 4;
    self.cell.layer.masksToBounds = YES;
    
    PFObject *listing = [self.results objectAtIndex:indexPath.row];
    
    //set the item as seen
    NSArray *shownTo = [listing objectForKey:@"shownTo"];
    if (![shownTo containsObject:[[PFUser currentUser]objectId]] && self.filtersON == NO) {
        [listing addObject:[[PFUser currentUser]objectId] forKey:@"shownTo"];
        [listing saveInBackground];
    }
    
    [[PFUser currentUser]addObject:listing.objectId forKey:@"seenListings"];
    [[PFUser currentUser]saveEventually];
    
    self.cell.imageView.image = nil;
    
    NSArray *bumpArray = [listing objectForKey:@"bumpArray"];
    if ([bumpArray containsObject:[PFUser currentUser].objectId]) {
        //already bumped
        [self.cell.bumpButton setSelected:YES];
        
        //set bg colour
        [self.cell.transView setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
        self.cell.transView.alpha = 0.9;
    }
    else{
        //haven't bumped
        [self.cell.bumpButton setSelected:NO];
        
        //set bg colour
        [self.cell.transView setBackgroundColor:[UIColor blackColor]];
        self.cell.transView.alpha = 0.5;
    }
    
    if (bumpArray.count > 0) {
        int count = (int)[bumpArray count];
        [self.cell.bumpButton setTitle:[NSString stringWithFormat:@"%@",[self abbreviateNumber:count]] forState:UIControlStateNormal];
    }
    else{
        [self.cell.bumpButton setTitle:@" " forState:UIControlStateNormal];
    }
    
    [self.cell.imageView setFile:[listing objectForKey:@"image1"]];
    [self.cell.imageView loadInBackground];
    
    self.cell.titleLabel.text = [NSString stringWithFormat:@"%@", [listing objectForKey:@"title"]];
    
//    if ([listing objectForKey:[NSString stringWithFormat:@"listingPrice%@", self.currency]]) {
//        int price = [[listing objectForKey:[NSString stringWithFormat:@"listingPrice%@", self.currency]]intValue];
//        self.cell.priceLabel.text = [NSString stringWithFormat:@"%@%d", self.currencySymbol,price];
//    }
//    else{
        self.cell.priceLabel.text = @"";
//    }

    if ([listing objectForKey:@"sizeLabel"]) {
        NSString *sizeNoUK = [[listing objectForKey:@"sizeLabel"] stringByReplacingOccurrencesOfString:@"UK" withString:@""];
        sizeNoUK = [sizeNoUK stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if ([sizeNoUK isEqualToString:@"One size"]) {
            self.cell.sizeLabel.text = [NSString stringWithFormat:@"%@", sizeNoUK];
        }
        else if ([sizeNoUK isEqualToString:@"S"]){
            self.cell.sizeLabel.text = @"Small";
        }
        else if ([sizeNoUK isEqualToString:@"M"]){
            self.cell.sizeLabel.text = @"Medium";
        }
        else if ([sizeNoUK isEqualToString:@"L"]){
            self.cell.sizeLabel.text = @"Large";
        }
        else if ([[listing objectForKey:@"category"]isEqualToString:@"Clothing"]){
            self.cell.sizeLabel.text = [NSString stringWithFormat:@"%@", sizeNoUK];
        }
        else{
            self.cell.sizeLabel.text = [NSString stringWithFormat:@"%@", [listing objectForKey:@"sizeLabel"]];
        }
    }
    else{
        self.cell.sizeLabel.text = @"";
    }
    
    PFGeoPoint *location = [listing objectForKey:@"geopoint"];
    if (self.currentLocation && location) {
        int distance = [location distanceInKilometersTo:self.currentLocation];
        if (![listing objectForKey:@"sizeLabel"]) {
            self.cell.sizeLabel.text = [NSString stringWithFormat:@"%dkm", distance];
            self.cell.distanceLabel.text = @"";
        }
        else{
            self.cell.distanceLabel.text = [NSString stringWithFormat:@"%dkm", distance];
        }
    }
    else{
        NSLog(@"no location data %@ %@", self.currentLocation, location);
        self.cell.distanceLabel.text = @"";
    }

    self.cell.backgroundColor = [UIColor whiteColor];
    
    return self.cell;
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

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.results.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(void)queryParseInfinite{
    if (self.pullFinished == NO) {
        return;
    }
    NSLog(@"infinity last skipped %d", self.lastInfinSkipped);
    self.infiniteQuery = nil;
    self.infiniteQuery = [PFQuery queryWithClassName:@"wantobuys"];

    self.infinFinished = NO;
    self.infiniteQuery.limit = 12;
    self.infiniteQuery.skip = self.lastInfinSkipped;
    [self.infiniteQuery whereKey:@"status" equalTo:@"live"];

    if (self.latestMode == YES) {
        [self.infiniteQuery orderByDescending:@"lastUpdated,bumpCount"];
        if (self.ignoreShownToLatest == NO) {
            [self.infiniteQuery whereKey:@"objectId" notContainedIn:[[PFUser currentUser]objectForKey:@"seenListings"]];
//            [self.infiniteQuery whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
        }
    }
    else{
        //suggested mode
        if (self.cleverMode == YES) {
            [self.infiniteQuery whereKey:@"searchKeywords" containedIn:self.calcdKeywords];
            [self.infiniteQuery orderByDescending:@"bumpCount,views"];
            if (self.ignoreShownTo != YES) {
                [self.infiniteQuery whereKey:@"objectId" notContainedIn:[[PFUser currentUser]objectForKey:@"seenListings"]];
//                [self.infiniteQuery whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
            }
        }
        else{
            //clever mode off
            [self.infiniteQuery orderByDescending:@"lastUpdated,bumpCount"];
        }
    }

    [self setupInfinQuery];
    [self.infiniteQuery cancel];
    [self.infiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            NSLog(@"infin count %d", count);
            
            if (count == 0 && self.ignoreShownTo != YES && self.latestMode == NO) {
                self.ignoreShownTo = YES;
                
                [[PFUser currentUser]setObject:@[] forKey:@"seenListings"];
                [[PFUser currentUser]saveEventually];
                
                self.lastInfinSkipped = 0;
                [self queryParseInfinite];
                return;
            }
            else if(count == 0 && self.ignoreShownToLatest != YES && self.latestMode == YES){
                self.ignoreShownToLatest = YES;
                self.lastInfinSkipped = 0;
                [self queryParseInfinite];
                return;
            }
            
            self.lastInfinSkipped = self.lastInfinSkipped + count;
            
            if (self.filtersON == YES) {
                [self.results addObjectsFromArray:objects];
            }
            else{
                if (self.latestMode == YES) {
                    if (count == 12) {
                        
                        //all is good so add to results array
                        for (PFObject *listing in objects) {
                            if (![self.resultIDs containsObject:listing.objectId]) {
                                [self.results addObject:listing];
                                [self.resultIDs addObject:listing.objectId];
                            }
                        }
                    }
                    
                    //running out of new stuff so start to ignore what I've seen
                    if(count < 12 && self.ignoreShownToLatest != YES){
                        self.ignoreShownToLatest = YES;
                        for (PFObject *listing in objects) {
                            if (![self.resultIDs containsObject:listing.objectId]) {
                                [self.results addObject:listing];
                                [self.resultIDs addObject:listing.objectId];
                            }
                        }
                    }
                }
                else{
                    //save in normal results array
                    if (count == 12 && self.cleverMode == YES) { //12 is limit
                        NSLog(@"clever mode is good!");
                        
                        //keep going with clever mode!
                        for (PFObject *listing in objects) {
                            if (![self.resultIDs containsObject:listing.objectId]) {
                                [self.results addObject:listing];
                                [self.resultIDs addObject:listing.objectId];
                            }
                        }
                    }
                    else if(count < 12 && self.cleverMode == YES){
                        NSLog(@"time to switch off & reset whats been seen for next time");
                        [[PFUser currentUser]setObject:@[] forKey:@"seenListings"];
                        [[PFUser currentUser]saveEventually];
                        
                        //add objects to array but switch off clever mode and reset the skip
                        for (PFObject *listing in objects) {
                            if (![self.resultIDs containsObject:listing.objectId]) {
                                [self.results addObject:listing];
                                [self.resultIDs addObject:listing.objectId];
                            }
                        }
                        self.cleverMode = NO;
                        self.lastInfinSkipped = 0;
                    }
                    else if (self.cleverMode == NO){
                        
                        //add but check hasn't been added already
                        NSLog(@"clever mode off");
                        
                        for (PFObject *listing in objects) {
                            if (![self.resultIDs containsObject:listing.objectId]) {
                                [self.results addObject:listing];
                                [self.resultIDs addObject:listing.objectId];
                            }
                        }
                    }
                    else{
                        NSLog(@"doesn't fit!!");
                    }
                }
            }
            
            [self.collectionView reloadData];
            [self.collectionView.infiniteScrollingView stopAnimating];
            self.infinFinished = YES;
        }
        else{
            NSLog(@"error %@", error);
            self.infinFinished = YES;
            [self showError];
        }
    }];
}
-(void)queryParsePull{
    NSLog(@"pulling!");
    //reset the query to remove the home screen constraints
    self.pullQuery = nil;
    self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
    self.pullFinished = NO;
    self.pullQuery.limit = 12;
    
    if (self.latestMode == YES) {
        
        [self.pullQuery orderByDescending:@"lastUpdated,bumpCount"];
        if (self.ignoreShownToLatest == NO ) {
//            [self.pullQuery whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
            [self.pullQuery whereKey:@"objectId" notContainedIn:[[PFUser currentUser]objectForKey:@"seenListings"]];
        }
    }
    else{
        
        //intelligent Home
        //use previous searches/wants to inform what listings people see
        self.searchWords = [[PFUser currentUser]objectForKey:@"searches"];
        NSArray *wantedw = [NSArray array];
        if ([[PFUser currentUser]objectForKey:@"wantedWords"]) {
            wantedw = [[PFUser currentUser]objectForKey:@"wantedWords"];
            self.wantedWords = wantedw;
        }
        
        //check if got any words to inform search
        if (self.searchWords.count > 0 || wantedw.count > 0) {
            NSMutableArray *allSearchWords = [NSMutableArray array];
            //seaprate the searches into search words
            for (NSString *searchTerm in self.searchWords) {
                NSArray *searchTermWords = [[searchTerm lowercaseString] componentsSeparatedByString:@" "];
                //then add all search words to an array in lower case
                [allSearchWords addObjectsFromArray:searchTermWords];
            }
            if ([[PFUser currentUser]objectForKey:@"wantedWords"]) {
                [allSearchWords addObjectsFromArray:[[PFUser currentUser]objectForKey:@"wantedWords"]];
            }
            self.calcdKeywords = [[allSearchWords reverseObjectEnumerator] allObjects];
            
            //add basic search terms in case only posted WTB/searched for 1 thing, which limits results
            NSMutableArray *baseArray = [NSMutableArray arrayWithArray:self.calcdKeywords];
            [baseArray addObject:@"supreme"];
            self.calcdKeywords = baseArray;
            
            [self.pullQuery whereKey:@"searchKeywords" containedIn:self.calcdKeywords];
            if (self.ignoreShownTo == NO) {
                [self.pullQuery whereKey:@"objectId" notContainedIn:[[PFUser currentUser]objectForKey:@"seenListings"]];
            }
            [self.pullQuery orderByDescending:@"bumpCount,views"];
        }
        else{
            //has no previous searches so show most recent
            self.calcdKeywords = @[@"supreme", @"yeezy", @"palace", @"stone", @"patta", @"adidas"];
            [self.pullQuery whereKey:@"searchKeywords" containedIn:self.calcdKeywords];
            [self.pullQuery orderByDescending:@"lastUpdated,bumpCount"];
            if (self.ignoreShownTo == NO) {
                [self.pullQuery whereKey:@"objectId" notContainedIn:[[PFUser currentUser]objectForKey:@"seenListings"]];
//                [self.pullQuery whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
            }
        }
        
    }

    [self setupPullQuery];
    [self.pullQuery whereKey:@"status" equalTo:@"live"];
    [self.pullQuery cancel];
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            NSLog(@"PULL OBJECTS COUNT: %d", count);
            self.lastInfinSkipped = count;
            
            if (count == 0 && self.ignoreShownTo == YES && self.latestMode == NO){
                // no more suggested results!!! so reset what user has seen so they start again
                [self.noresultsLabel setHidden:YES];
                [self.noResultsImageView setHidden:YES];
                
                [[PFUser currentUser]setObject:@[] forKey:@"seenListings"];
                [[PFUser currentUser]saveEventually];
                
                if (self.triedAlready != YES) {
                    self.triedAlready = YES;
                    [self queryParsePull];
                }

            }
            else if (count < 12 && self.ignoreShownTo == NO && self.latestMode == NO) {
                //seen all results so reset what they have seen
                [self.noresultsLabel setHidden:YES];
                [self.noResultsImageView setHidden:YES];
                
                NSLog(@"MY ARRAY: %@",[[PFUser currentUser] objectForKey:@"seenListings"]);
                
                NSLog(@"START TO IGNORE WHAT IVE ALREADY SEEN");
                self.ignoreShownTo = YES;
                
                
                //reset seen list for next time
                [[PFUser currentUser]setObject:@[] forKey:@"seenListings"];
                [[PFUser currentUser]saveInBackground];

                [self queryParsePull];
                return;

            }
            else if (count == 0 && self.ignoreShownToLatest == YES && self.latestMode == YES){
                // no more latest results!!!
                [self.noresultsLabel setHidden:NO];
                [self.noResultsImageView setHidden:YES];
            }
            else if (count < 12 && self.ignoreShownToLatest == NO && self.latestMode == YES){
                //seen all results so start to ignore what already seen > better to reset what seen?
                [self.noresultsLabel setHidden:YES];
                [self.noResultsImageView setHidden:YES];
                
                self.ignoreShownToLatest = YES;
                [self queryParsePull];
                return;
            }

            else{
                //fail safe
                [self.noresultsLabel setHidden:YES];
                [self.noResultsImageView setHidden:YES];
            }
            
            NSLog(@"continuing in pull!");
            self.ignoreShownTo = NO;
            self.triedAlready = NO;
            
            if (self.latestMode != YES){
                if (count == 12) {
                    self.cleverMode = YES;
                }
                else{
                    self.cleverMode = NO;
                    self.lastInfinSkipped = 0;
                }
            }

            //save in normal results array
            [self.results removeAllObjects];
            [self.results addObjectsFromArray:objects];
            
            //animate the data change
            [self.collectionView performBatchUpdates:^{
                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            } completion:nil];
            
            [self.collectionView.pullToRefreshView stopAnimating];
            self.pullFinished = YES;
            
            [self.resultIDs removeAllObjects];
            for (PFObject *listing in objects) {
                [self.resultIDs addObject:listing.objectId];
            }
        }
        else{
            NSLog(@"error on pull %@", error);
            self.pullFinished = YES;
            if (error.code == 209) {
                //invalid access token
                [PFUser logOut];
                WelcomeViewController *vc = [[WelcomeViewController alloc]init];
                vc.delegate = self;
                NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
                self.welcomeShowing = YES;
                [self presentViewController:navController animated:YES completion:nil];
            }
            else{
                [self showError];
            }
        }
    }];
}
- (void) startLocationManager {
    
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _locationManager.distanceFilter = 5;
        _locationManager.delegate = self;
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        [_locationManager startUpdatingLocation];
        [self parseLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusDenied:
            NSLog(@"kCLAuthorizationStatusDenied");
        {
            UIAlertController * alert=   [UIAlertController
                                          alertControllerWithTitle:@"Location services disabled"
                                          message:@"Enable location services in settings to view WTBs nearby!"
                                          preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            _locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
            [_locationManager startUpdatingLocation];
            
            CLLocation *currentLocation = _locationManager.location;
            if (currentLocation) {
                //get location
                [self parseLocation];
            }
        }
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        {
            _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            _locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
            [_locationManager startUpdatingLocation];
            
            CLLocation *currentLocation = _locationManager.location;
            if (currentLocation) {
                //got location
                [self parseLocation];
            }
        }
            break;
        case kCLAuthorizationStatusNotDetermined:
            NSLog(@"kCLAuthorizationStatusNotDetermined");
            break;
        case kCLAuthorizationStatusRestricted:
            NSLog(@"kCLAuthorizationStatusRestricted");
            break;
    }
}

-(void)parseLocation{
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint * _Nullable geoPoint, NSError * _Nullable error) {
        if (geoPoint) {
            self.currentLocation = geoPoint;
            double latitude = geoPoint.latitude;
            double longitude = geoPoint.longitude;
            
            CLLocation *loc = [[CLLocation alloc]initWithLatitude:latitude longitude:longitude];
            CLGeocoder *geocoder = [[CLGeocoder alloc]init];
            [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                if (placemarks) {
                    CLPlacemark *placemark = [placemarks lastObject];
                    NSString *titleString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.ISOcountryCode];
                    
                    if (![titleString containsString:@"(null)"]) { //protect against saving when user hasn't granted location permission
                        [[PFUser currentUser]setObject:titleString forKey:@"profileLocation"];
                        [[PFUser currentUser]saveInBackground];
                    }
                    
                }
                else{
                    NSLog(@"error %@", error);
                }
            }];

        }
        else{
            NSLog(@"no geopoint %@", error);
        }
    }];
}
- (IBAction)filterPressed:(id)sender {
    [Answers logCustomEventWithName:@"Filters pressed"
                   customAttributes:@{
                                      @"page":@"Explore"
                                      }];
    
    FilterVC *vc = [[FilterVC alloc]init];
    vc.delegate = self;
    if (self.filtersArray.count > 0) {
        vc.sendArray = [NSMutableArray arrayWithArray:self.filtersArray];
    }
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)noChange{
    if (self.filtersArray > 0) {
        self.filterButton.titleLabel.text = [NSString stringWithFormat:@"F I L T E R S  %lu",self.filtersArray.count];
    }
}

-(void)filtersReturned:(NSMutableArray *)filters{
    [self.results removeAllObjects];
    [self.collectionView reloadData];
    self.filtersArray = filters;
    if (self.filtersArray.count > 0) {
        self.filtersON = YES;
        NSLog(@"got some filters brah %lu", self.filtersArray.count);
        self.filterButton.titleLabel.text = [NSString stringWithFormat:@"F I L T E R S  %lu",self.filtersArray.count];
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1];
        [self.filterButton setHidden:NO];
        [self.filterBGView setHidden:NO];
    }
    else{
        self.filtersON = NO;
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
        [self.filterButton setHidden:YES];
        [self.filterBGView setHidden:YES];
    }
    self.lastInfinSkipped = 0;

    NSLog(@"filters array in explore %@", self.filtersArray);
    
    //if array is empty from a 'no results' search then don't scroll to top to avoid crashing as there's 0 index paths to scroll to!
    if (self.results.count != 0) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:NO];
    }

    [self queryParsePull];
}

-(void)setupInfinQuery{
    if (self.filtersArray.count > 0) {
        if ([self.filtersArray containsObject:@"hightolow"]) {
            [self.infiniteQuery orderByDescending:[NSString stringWithFormat:@"listingPrice%@", self.currency]];
        }
        else if ([self.filtersArray containsObject:@"lowtohigh"]){
            [self.infiniteQuery orderByAscending:[NSString stringWithFormat:@"listingPrice%@", self.currency]];
        }
        
        if ([self.filtersArray containsObject:@"aroundMe"] && self.currentLocation) {
            [self.infiniteQuery whereKey:@"geopoint" nearGeoPoint:self.currentLocation];
        }
        
        if ([self.filtersArray containsObject:@"BNWT"]){
            [self.infiniteQuery whereKey:@"condition" containedIn:@[@"BNWT", @"Any"]];
        }
        else if ([self.filtersArray containsObject:@"used"]){
            [self.infiniteQuery whereKey:@"condition" containedIn:@[@"Used", @"Any"]];
        }
        else if ([self.filtersArray containsObject:@"BNWOT"]){
            [self.infiniteQuery whereKey:@"condition" containedIn:@[@"BNWOT", @"Any"]];
        }
        
        if ([self.filtersArray containsObject:@"clothing"]){
            [self.infiniteQuery whereKey:@"category" equalTo:@"Clothing"];
        }
        else if ([self.filtersArray containsObject:@"footwear"]){
            [self.infiniteQuery whereKey:@"category" equalTo:@"Footwear"];
        }
        else if ([self.filtersArray containsObject:@"accessory"]){
            [self.infiniteQuery whereKey:@"category" equalTo:@"Accessories"];
        }
        
        if ([self.filtersArray containsObject:@"male"]){
            [self.infiniteQuery whereKey:@"sizeGender" equalTo:@"Mens"];
        }
        else if ([self.filtersArray containsObject:@"female"]){
            [self.infiniteQuery whereKey:@"sizeGender" equalTo:@"Womens"];
        }
        
        //footwear sizes
        if ([self.filtersArray containsObject:@"3"]){
            [self.infiniteQuery whereKey:@"size3" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"3.5"]){
            [self.infiniteQuery whereKey:@"size3dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"4"]){
            [self.infiniteQuery whereKey:@"size4" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"4.5"]){
            [self.infiniteQuery whereKey:@"size4dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"5"]){
            [self.infiniteQuery whereKey:@"size5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"5.5"]){
            [self.infiniteQuery whereKey:@"size5dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"6"]){
            [self.infiniteQuery whereKey:@"size6" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"6.5"]){
            [self.infiniteQuery whereKey:@"size6dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"7"]){
            [self.infiniteQuery whereKey:@"size7" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"7.5"]){
            [self.infiniteQuery whereKey:@"size7dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"8"]){
            [self.infiniteQuery whereKey:@"size8" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"8.5"]){
            [self.infiniteQuery whereKey:@"size8dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"9"]){
            [self.infiniteQuery whereKey:@"size9" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"9.5"]){
            [self.infiniteQuery whereKey:@"size9dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"10"]){
            [self.infiniteQuery whereKey:@"size10" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"10.5"]){
            [self.infiniteQuery whereKey:@"size10dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"11"]){
            [self.infiniteQuery whereKey:@"size11" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"11.5"]){
            [self.infiniteQuery whereKey:@"size11dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"12"]){
            [self.infiniteQuery whereKey:@"size12" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"12.5"]){
            [self.infiniteQuery whereKey:@"size12dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"13"]){
            [self.infiniteQuery whereKey:@"size13" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"13.5"]){
            [self.infiniteQuery whereKey:@"size13dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"14"]){
            [self.infiniteQuery whereKey:@"size14" equalTo:@"YES"];
        }
        
        //clothing sizes
        if ([self.filtersArray containsObject:@"XXS"]){
            [self.infiniteQuery whereKey:@"XXS" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"XS"]){
            [self.infiniteQuery whereKey:@"XS" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"S"]){
            [self.infiniteQuery whereKey:@"S" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"M"]){
            [self.infiniteQuery whereKey:@"M" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"L"]){
            [self.infiniteQuery whereKey:@"L" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"XL"]){
            [self.infiniteQuery whereKey:@"XL" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"XXL"]){
            [self.infiniteQuery whereKey:@"XXL" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"OS"]){
            [self.infiniteQuery whereKey:@"OS" equalTo:@"YES"];
        }
    }
}
-(void)setupPullQuery{
    if (self.filtersArray.count > 0) {
        if ([self.filtersArray containsObject:@"hightolow"]) {
            [self.pullQuery orderByDescending:[NSString stringWithFormat:@"listingPrice%@", self.currency]];
        }
        else if ([self.filtersArray containsObject:@"lowtohigh"]){
            [self.pullQuery orderByAscending:[NSString stringWithFormat:@"listingPrice%@", self.currency]];
        }
        
        if ([self.filtersArray containsObject:@"aroundMe"] && self.currentLocation) {
            [self.pullQuery whereKey:@"geopoint" nearGeoPoint:self.currentLocation];
        }
        
        if ([self.filtersArray containsObject:@"BNWT"]){
            [self.pullQuery whereKey:@"condition" containedIn:@[@"BNWT", @"Any"]];
        }
        else if ([self.filtersArray containsObject:@"used"]){
            [self.pullQuery whereKey:@"condition" containedIn:@[@"Used", @"Any"]];
        }
        else if ([self.filtersArray containsObject:@"BNWOT"]){
            [self.pullQuery whereKey:@"condition" containedIn:@[@"BNWOT", @"Any"]];
        }
        
        if ([self.filtersArray containsObject:@"clothing"]){
            [self.pullQuery whereKey:@"category" equalTo:@"Clothing"];
        }
        else if ([self.filtersArray containsObject:@"footwear"]){
            [self.pullQuery whereKey:@"category" equalTo:@"Footwear"];
        }
        else if ([self.filtersArray containsObject:@"accessory"]){
            [self.pullQuery whereKey:@"category" equalTo:@"Accessories"];
        }
        
        if ([self.filtersArray containsObject:@"male"]){
            [self.pullQuery whereKey:@"sizeGender" equalTo:@"Mens"];
        }
        else if ([self.filtersArray containsObject:@"female"]){
            [self.pullQuery whereKey:@"sizeGender" equalTo:@"Womens"];
        }
        
        //footwear sizes
        if ([self.filtersArray containsObject:@"3"]){
            [self.pullQuery whereKey:@"size3" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"3.5"]){
            [self.pullQuery whereKey:@"size3dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"4"]){
            [self.pullQuery whereKey:@"size4" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"4.5"]){
            [self.pullQuery whereKey:@"size4dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"5"]){
            [self.pullQuery whereKey:@"size5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"5.5"]){
            [self.pullQuery whereKey:@"size5dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"6"]){
            [self.pullQuery whereKey:@"size6" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"6.5"]){
            [self.pullQuery whereKey:@"size6dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"7"]){
            [self.pullQuery whereKey:@"size7" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"7.5"]){
            [self.pullQuery whereKey:@"size7dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"8"]){
            [self.pullQuery whereKey:@"size8" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"8.5"]){
            [self.pullQuery whereKey:@"size8dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"9"]){
            [self.pullQuery whereKey:@"size9" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"9.5"]){
            [self.pullQuery whereKey:@"size9dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"10"]){
            [self.pullQuery whereKey:@"size10" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"10.5"]){
            [self.pullQuery whereKey:@"size10dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"11"]){
            [self.pullQuery whereKey:@"size11" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"11.5"]){
            [self.pullQuery whereKey:@"size11dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"12"]){
            [self.pullQuery whereKey:@"size12" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"12.5"]){
            [self.pullQuery whereKey:@"size12dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"13"]){
            [self.pullQuery whereKey:@"size13" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"13.5"]){
            [self.pullQuery whereKey:@"size13dot5" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"14"]){
            [self.pullQuery whereKey:@"size14" equalTo:@"YES"];
        }
       
        //clothing sizes
        if ([self.filtersArray containsObject:@"XXS"]){
            [self.pullQuery whereKey:@"sizeXXS" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"XS"]){
            [self.pullQuery whereKey:@"sizeXS" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"S"]){
            [self.pullQuery whereKey:@"sizeS" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"M"]){
            [self.pullQuery whereKey:@"sizeM" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"L"]){
            [self.pullQuery whereKey:@"sizeL" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"XL"]){
            [self.pullQuery whereKey:@"sizeXL" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"XXL"]){
            [self.pullQuery whereKey:@"sizeXXL" equalTo:@"YES"];
        }
        else if ([self.filtersArray containsObject:@"OS"]){
            [self.pullQuery whereKey:@"sizeOS" equalTo:@"YES"];
        }
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (!self.lastSelected) {
        self.lastSelected = [[NSIndexPath alloc]init];
    }
    self.lastSelected = indexPath;
    PFObject *selected = [self.results objectAtIndex:indexPath.item];
    
    ListingController *vc = [[ListingController alloc]init];
    vc.listingObject = selected;
    self.listingTapped = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)searchPressed{
    TheMainSearchView *vc = [[TheMainSearchView alloc]init];
    vc.currency = self.currency;
    vc.delegate = self;
    vc.currencySymbol = self.currencySymbol;
    vc.geoPoint = self.currentLocation;
    vc.tabBarHeight = [NSNumber numberWithFloat:self.tabBarController.tabBar.frame.size.height];
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    self.definesPresentationContext = YES;
    nav.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)showError{
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Error"
                                  message:@"Make sure you're connected to the internet!"
                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)cellTapped:(id)sender{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:(ExploreCell*)sender];
    
    PFObject *listingObject = [self.results objectAtIndex:indexPath.item];
    
    [Answers logCustomEventWithName:@"Bumped a listing"
                   customAttributes:@{
                                      @"where":@"Home"
                                      }];
    
    ExploreCell *cell = sender;
    NSMutableArray *bumpArray = [NSMutableArray arrayWithArray:[listingObject objectForKey:@"bumpArray"]];
    NSMutableArray *personalBumpArray = [NSMutableArray arrayWithArray:[[PFUser currentUser] objectForKey:@"bumpArray"]];

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
        NSString *pushText = [NSString stringWithFormat:@"%@ just bumped your listing 👊", [PFUser currentUser].username];
        
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
                                              @"where":@"Home"
                                              }];
        }
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

- (void)handleBump:(NSNotification*)note {
    NSString *listingID = [note object];
    
    [Answers logCustomEventWithName:@"Opened BumpVC after receiving FB Friend Push"
                   customAttributes:@{}];
    
    BumpVC *vc = [[BumpVC alloc]init];
    vc.listingID = listingID;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showListing:(NSNotification*)note {
    NSString *listingID = [note object];
    
    [Answers logCustomEventWithName:@"Opened listing after receiving Bump Push"
                   customAttributes:@{}];
    
    PFObject *listing = [PFObject objectWithoutDataWithClassName:@"wantobuys" objectId:listingID];
    ListingController *vc = [[ListingController alloc]init];
    vc.listingObject = listing;
    NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
    [nav pushViewController:vc animated:YES];
}
- (void)handleDrop:(NSNotification*)note {
    NSString *listingID = [note object];
    
    [Answers logCustomEventWithName:@"Received in app push"
                   customAttributes:@{
                                      @"type":@"FB Friend just posted"
                                      }];

    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"notView" owner:self options:nil];
    self.dropDown = (notificatView *)[nib objectAtIndex:0];
    self.dropDown.delegate = self;
    self.dropDown.listingID = listingID;
    
    UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDrop)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [self.dropDown addGestureRecognizer:swipeGesture];
    [self.dropDown setFrame:CGRectMake(0, -119, self.view.frame.size.width, 119)];
    
    PFQuery *listingQ = [PFQuery queryWithClassName:@"wantobuys"];
    [listingQ whereKey:@"objectId" equalTo:listingID];
    [listingQ includeKey:@"postUser"];
    [listingQ getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            PFObject *listing = object;
            self.dropDown.listing = listing;
            [self.dropDown.imageView setFile:[object objectForKey:@"image1"]];
            [self.dropDown.imageView loadInBackground:^(UIImage * _Nullable image, NSError * _Nullable error) {
                if (image) {
                    PFUser *postUser = [listing objectForKey:@"postUser"];
                    self.dropDown.mainLabel.text = [NSString stringWithFormat:@"Your Facebook friend %@ just posted a listing - Tap to Bump it 👊", [postUser objectForKey:@"fullname"]];
                    self.justABump = NO;
                    self.justAMessage = NO;
                    //animate down
                    [[UIApplication sharedApplication].keyWindow addSubview:self.dropDown];
                    
                    [UIView animateWithDuration:1.0
                                          delay:0.0
                         usingSpringWithDamping:0.5
                          initialSpringVelocity:0.5
                                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                                            //Animations
                                            [self.dropDown setFrame:CGRectMake(0, 0, self.view.frame.size.width, 119)];
                                        }
                                     completion:^(BOOL finished) {
                                         //schedule auto dismiss
                                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                             [self dismissDrop];
                                         });
                                     }];
                }
            }];
        }
        else{
            NSLog(@"error finding listing");
        }
    }];
}

-(void)dismissDrop{
    //animate up
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            [self.dropDown setFrame:CGRectMake(0, -119, self.view.frame.size.width, 119)];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         [self.dropDown removeFromSuperview];
                     }];
    
}

-(void)handleBumpDrop:(NSNotification*)note {
    NSArray *info = [note object];
    
    //prevent crashes with wrongly formatted pushes
    if (info.count <2) {
        return;
    }
    
    NSString *listingID = info[0];
    NSString *message = info[1];
    
    [Answers logCustomEventWithName:@"Received in app push"
                   customAttributes:@{
                                      @"type":@"Received a Bump"
                                      }];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"notView" owner:self options:nil];
    self.dropDown = (notificatView *)[nib objectAtIndex:0];
    self.dropDown.delegate = self;
    self.dropDown.listingID = listingID;
    
    UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDrop)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [self.dropDown addGestureRecognizer:swipeGesture];
    [self.dropDown setFrame:CGRectMake(0, -119, self.view.frame.size.width, 119)];
    
    PFQuery *listingQ = [PFQuery queryWithClassName:@"wantobuys"];
    [listingQ whereKey:@"objectId" equalTo:listingID];
    [listingQ getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            PFObject *listing = object;
            self.dropDown.listing = listing;
            [self.dropDown.imageView setFile:[object objectForKey:@"image1"]];
            [self.dropDown.imageView loadInBackground:^(UIImage * _Nullable image, NSError * _Nullable error) {
                if (image) {
                    self.dropDown.mainLabel.text = message;
                    self.justABump = YES;
                    self.justAMessage = NO;
                    //animate down
                    [[UIApplication sharedApplication].keyWindow addSubview:self.dropDown];
                    
                    [UIView animateWithDuration:1.0
                                          delay:0.0
                         usingSpringWithDamping:0.5
                          initialSpringVelocity:0.5
                                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                                            //Animations
                                            [self.dropDown setFrame:CGRectMake(0, 0, self.view.frame.size.width, 119)];
                                        }
                                     completion:^(BOOL finished) {
                                         //schedule auto dismiss
                                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                             [self dismissDrop];
                                         });
                                     }];
                }
            }];
        }
        else{
            NSLog(@"error finding listing");
        }
    }];
}

-(void)bumpTappedForListing:(NSString *)listing{

    [Answers logCustomEventWithName:@"Tapped in app Push"
                   customAttributes:@{
                                      @"type":@"Bump"
                                      }];
    
    //animate up
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            [self.dropDown setFrame:CGRectMake(0, -119, self.view.frame.size.width, 119)];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         [self.dropDown removeFromSuperview];
                     }];
    
    if (self.justAMessage == YES){
        
    }
    else if (self.justABump == NO) {
        BumpVC *vc = [[BumpVC alloc]init];
        vc.listingID = listing;
        [self presentViewController:vc animated:YES completion:nil];
    }
    else{
        //goto that listing
        NSLog(@"goto listing");
        PFObject *listingObj = [PFObject objectWithoutDataWithClassName:@"wantobuys" objectId:listing];
        ListingController *vc = [[ListingController alloc]init];
        vc.listingObject = listingObj;
        NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
        [nav pushViewController:vc animated:YES];
    }
}

-(void)cancellingMainSearch{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

-(void)setUpIntroAlert{
    self.searchBgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.searchBgView.alpha = 0.0;
    
    UIImageView *imgView = [[UIImageView alloc]initWithFrame:self.searchBgView.frame];
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone 5
        [imgView setImage:[UIImage imageNamed:@"searchIntro1"]];
    }
    else{
        //iPhone 6 specific
        [imgView setImage:[UIImage imageNamed:@"searchIntro"]];
    }
    [self.searchBgView addSubview:imgView];
    [[UIApplication sharedApplication].keyWindow addSubview:self.searchBgView];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.searchBgView.alpha = 0.6f;
                     }
                     completion:nil];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"customAlertView" owner:self options:nil];
    self.customAlert = (customAlertViewClass *)[nib objectAtIndex:0];
    self.customAlert.delegate = self;
    self.customAlert.titleLabel.text = @"Selling Something?";
    self.customAlert.messageLabel.text = @"Hit the Search button to find wanted listings that match what you’re selling";
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, -157, 250, 157)];
    }
    else{
        [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, -188, 300, 188)]; //iPhone 6/7 specific
    }
    
    self.customAlert.layer.cornerRadius = 10;
    self.customAlert.layer.masksToBounds = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.customAlert];
    
    [UIView animateWithDuration:1.5
                          delay:1.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, 100, 250, 157)];
                            }
                            else{
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, 100, 300, 188)]; //iPhone 6/7 specific
                            }
                        }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)showPushReminder{
    NSLog(@"SHOW PUSH REMINDER");
    self.shownPushAlert = YES;
    self.searchBgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.searchBgView.alpha = 0.0;
    [self.searchBgView setBackgroundColor:[UIColor blackColor]];
    [[UIApplication sharedApplication].keyWindow addSubview:self.searchBgView];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.searchBgView.alpha = 0.6f;
                     }
                     completion:nil];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"customAlertView" owner:self options:nil];
    self.pushAlert = (customAlertViewClass *)[nib objectAtIndex:0];
    self.pushAlert.delegate = self;
    self.pushAlert.titleLabel.text = @"Enable Push";
    self.pushAlert.messageLabel.text = @"Tap to be notified when sellers/potential buyers send you a message on Bump";
    self.pushAlert.numberOfButtons = 2;
    [self.pushAlert.secondButton setTitle:@"E N A B L E" forState:UIControlStateNormal];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, -157, 250, 157)];
    }
    else{
        [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, -188, 300, 188)]; //iPhone 6/7 specific
    }
    
    self.pushAlert.layer.cornerRadius = 10;
    self.pushAlert.layer.masksToBounds = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.pushAlert];
    
    [UIView animateWithDuration:1.5
                          delay:0.2
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.pushAlert setFrame:CGRectMake(0, 0, 250, 157)];
                            }
                            else{
                                [self.pushAlert setFrame:CGRectMake(0, 0, 300, 188)]; //iPhone 6/7 specific
                            }
                            self.pushAlert.center = self.view.center;
                            
                        }
                     completion:nil];
}

-(void)donePressed{
    if (self.shownPushAlert == YES) {
        //push re-reminder
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.searchBgView.alpha = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             self.searchBgView = nil;
                         }];
        
        [UIView animateWithDuration:1.0
                              delay:0.0
             usingSpringWithDamping:0.1
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseIn animations:^{
                                //Animations
                                if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                    //iphone5
                                    [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, 1000, 250, 157)];
                                }
                                else{
                                    [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, 1000, 300, 188)]; //iPhone 6/7 specific
                                }
                            }
                         completion:^(BOOL finished) {
                             //Completion Block
                             [self.pushAlert setAlpha:0.0];
                             [self.pushAlert removeFromSuperview];
                             self.pushAlert = nil;
                         }];
    }
    else{
        //search intro
        [[PFUser currentUser]setObject:@"YES" forKey:@"searchIntro"];
        [[PFUser currentUser] saveInBackground];
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.searchBgView.alpha = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             self.searchBgView = nil;
                         }];
        
        [UIView animateWithDuration:1.0
                              delay:0.0
             usingSpringWithDamping:0.1
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseIn animations:^{
                                //Animations
                                if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                    //iphone5
                                    [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, 1000, 250, 157)];
                                }
                                else{
                                    [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, 1000, 300, 188)]; //iPhone 6/7 specific
                                }
                            }
                         completion:^(BOOL finished) {
                             //Completion Block
                             [self.customAlert setAlpha:0.0];
                             self.customAlert = nil;
                         }];
    }
}
//custom alert delegates
-(void)firstPressed{
    //push reminder
    [Answers logCustomEventWithName:@"Denied Push Permissions"
                   customAttributes:@{
                                      @"mode":@"redownloaded"
                                      }];
    [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"declinedPushPermissions"];
    [self donePressed];
}
-(void)secondPressed{
    //push reminder
    [Answers logCustomEventWithName:@"Accepted Push Permissions"
                   customAttributes:@{
                                      @"mode":@"redownloaded"
                                      }];
    [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"askedForPushPermission"];
    [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"declinedPushPermissions"];

    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    [self donePressed];
}

-(void)resetHome{
    //only reset if they're looking at home tab
    if (self.tabBarController.selectedIndex == 0) {
        if (self.results.count != 0) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionTop
                                                animated:NO];
        }
        
        self.ignoreShownTo = NO;
        [self queryParsePull];
    }
}

-(void)insertLatestListing:(NSNotification*)note {
    PFObject *listing = [note object];
//    NSLog(@"insert %@", listing);
    if (self.results.count > 0) {
        [self.results insertObject:listing atIndex:0];
        [self.resultIDs addObject:listing.objectId];
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        } completion:nil];
    }
}

-(void)doubleTapScroll{
    if (self.results.count != 0) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:YES];
    }
}

#pragma mark message drop

-(void)messageSentDrop:(NSNotification*)note {
    PFUser *friend = [note object];
    
    [Answers logCustomEventWithName:@"Showing Message Sent Drop"
                   customAttributes:@{}];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"notView" owner:self options:nil];
    self.dropDown = (notificatView *)[nib objectAtIndex:0];
    self.dropDown.delegate = self;
    self.dropDown.sentMode = YES;
    [self setImageBorder:self.dropDown.imageView];
    
    [friend fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            [self.dropDown.imageView setFile:[friend objectForKey:@"picture"]];
            [self.dropDown.imageView loadInBackground:^(UIImage * _Nullable image, NSError * _Nullable error) {
                if (image) {
                    self.dropDown.mainLabel.text = [NSString stringWithFormat:@"Message sent to %@", friend.username];
                    
                    //setup what happens when user taps notification
                    self.justAMessage = YES;
                    
                    //animate down
                    [[UIApplication sharedApplication].keyWindow addSubview:self.dropDown];
                    
                    [UIView animateWithDuration:1.0
                                          delay:0.0
                         usingSpringWithDamping:0.5
                          initialSpringVelocity:0.5
                                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                                            //Animations
                                            [self.dropDown setFrame:CGRectMake(0, 0, self.view.frame.size.width, 119)];
                                        }
                                     completion:^(BOOL finished) {
                                         //schedule auto dismiss
                                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                             [self dismissDrop];
                                         });
                                     }];
                }
            }];
        }
        else{
            NSLog(@"error fetching user %@", error);
        }
    }];
    
    UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDrop)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [self.dropDown addGestureRecognizer:swipeGesture];
    [self.dropDown setFrame:CGRectMake(0, -119, self.view.frame.size.width, 119)];
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = 30;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)segmentControlChanged{
    if (self.latestMode == YES) {
        //load suggested
        [self.segmentedControl setSelectedSegmentIndex:0];
        self.latestMode = NO;
    }
    else{
        //load latest
        [self.segmentedControl setSelectedSegmentIndex:1];
        self.latestMode = YES;
    }
    [self queryParsePull];
}

-(void)welcomeDismissed{
    self.welcomeShowing = NO;
}


@end
