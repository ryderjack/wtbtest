//
//  ExploreVC.m
//  
//
//  Created by Jack Ryder on 29/02/2016.
//
//

#import "ExploreVC.h"
#import "ExploreCell.h"
#import <SVPullToRefresh/SVPullToRefresh.h>
#import "WelcomeViewController.h"
#import "NavigationController.h"
#import "Flurry.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "AppConstant.h"
#import "UserProfileController.h"
#import "ContainerViewController.h"

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
    
    self.searchString = @"";
    self.searchEnabled = NO;
    
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
        [flowLayout setItemSize:CGSizeMake((self.view.frame.size.width/2)-40, 300)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.height == 736){
        //iphone 6 plus
        [flowLayout setItemSize:CGSizeMake((self.view.frame.size.width/2), 300)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.height == 480){
        //iphone 4
        [flowLayout setItemSize:CGSizeMake((self.view.frame.size.width/2)-40, 300)];
    }
    else{
        [flowLayout setItemSize:CGSizeMake(175, 254)]; //iPhone 6 specific
    }
    [flowLayout setMinimumInteritemSpacing:0];
    [flowLayout setMinimumLineSpacing:8.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    self.results = [[NSMutableArray alloc]init];
    self.searchResults = [[NSMutableArray alloc]init];
    
    //location stuff
    [self startLocationManager];
    self.locationAllowed = [CLLocationManager locationServicesEnabled];
    
    //refresh setup
    self.pullFinished = YES;
    self.infinFinished = YES;
    self.lastInfinSkipped = 0;
    
    [self.collectionView setScrollsToTop:YES];
    
    self.filtersArray = [NSMutableArray array];
    self.filtersTapped = NO;
    
    // set searchbar font
    NSDictionary *searchAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                      NSFontAttributeName, nil];
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setDefaultTextAttributes:searchAttributes];
    
    if ([FBSDKAccessToken currentAccessToken] == nil) {
        //invalid access token
        [PFUser logOut];
        WelcomeViewController *vc = [[WelcomeViewController alloc]init];
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
                NSArray *currentList = [[PFUser currentUser] objectForKey:@"friends"];
                for (NSDictionary *friend in friends) {
                    if (![currentList containsObject:[friend objectForKey:@"id"]]) {
                        //add to friend's list
                        [[PFUser currentUser]addObject:[friend objectForKey:@"id"] forKey:@"friends"];
                        [[PFUser currentUser] saveInBackground];
                    }
                }
            }
            else{
                NSLog(@"error on friends %li", (long)error.code);
                if (error.code == 8) {
                    //invalid access token
                    [PFUser logOut];
                    WelcomeViewController *vc = [[WelcomeViewController alloc]init];
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
            [PFUser logOut];
        }
        
        //remove duplicate searches
        if (![[currentUser objectForKey:@"clearSearches"]isEqualToString:@"YES"]) {
            //clear duplicate searches
            NSMutableArray *searches = [NSMutableArray array];
            searches = [[PFUser currentUser]objectForKey:@"searches"];
            NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:searches];
            NSArray *arrayWithoutDuplicates = [orderedSet array];
            [[PFUser currentUser]setObject:arrayWithoutDuplicates forKey:@"searches"];
            [[PFUser currentUser] setObject:@"YES" forKey:@"clearSearches"];
            [[PFUser currentUser]saveInBackground];
        }
        
        if (![currentUser objectForKey:PF_USER_FULLNAME] || ![currentUser objectForKey:PF_USER_EMAIL] || ![currentUser objectForKey:@"currency"] || ![currentUser objectForKey:PF_USER_FACEBOOKID] || ![currentUser objectForKey: PF_USER_GENDER] || ![currentUser objectForKey:@"picture"] || currentUser.username.length > 10) {
            //been an error on sign up as user doesn't have all info saved
            currentUser[@"completedReg"] = @"NO";
            [PFUser logOut];
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
                UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"New update available" message:@"Harder, better, faster, stronger" preferredStyle:UIAlertControllerStyleAlert];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    
                }]];
                [alertView addAction:[UIAlertAction actionWithTitle:@"Update" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:
                                                                @"itms-apps://itunes.apple.com/app/id1096047233"]];
                }]];
                [self presentViewController:alertView animated:YES completion:nil];
            }
        }
        else{
            NSLog(@"error getting latest version %@", error);
        }
    }];
    
   // [PFUser logOut];
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
        self.infiniteQuery.skip = self.lastInfinSkipped;
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
    
//    if (self.pullFinished == YES) {
//        if (self.listingTapped == NO) {
//            [self queryParsePull];
//        }
//    }
    
    if (self.searchEnabled == YES) {
        [self.searchController.searchBar setHidden:NO];
    }
    
    [self.infiniteQuery cancel];
    [self.collectionView.infiniteScrollingView stopAnimating];
    self.infinFinished = YES;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (self.listingTapped == NO) {
        self.searchShowing = NO;
    }
    
    self.filtersTapped = NO;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self.collectionView.infiniteScrollingView stopAnimating];
    
    if (self.userPressed == YES) {
        self.userPressed = NO;
        NSLog(@"just searched for a user, do nothing");
        [self.searchController.searchBar becomeFirstResponder];
    }
    else if (self.searchEnabled == YES && self.filtersTapped == NO && self.listingTapped == NO) {
        NSLog(@"about to call search pressed");
        self.searchShowing = NO;
        [self searchPressed];
    }
    else if (self.searchEnabled == YES && self.filtersTapped == NO && self.listingTapped == YES) {
        //if not active then show (could have changed tabs from looking at the listing)
        NSLog(@"checking if should show as been on a listing and could have switched tabs");
        [self ShouldShowSearch];
    }
    
    self.listingTapped = NO;
    self.filtersTapped = NO;
    
    [Flurry logEvent:@"Explore_Tapped"];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ExploreCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    PFObject *listing;
    
    cell.imageView.image = nil;
    
    if (self.searchEnabled == YES) {
        listing = [self.searchResults objectAtIndex:indexPath.row];
    }
    else{
        listing = [self.results objectAtIndex:indexPath.row];
    }
    
    //set placeholder spinner view
    MBProgressHUD __block *hud = [MBProgressHUD showHUDAddedTo:cell.imageView animated:YES];
    hud.square = YES;
    hud.mode = MBProgressHUDModeCustomView;
    hud.color = [UIColor whiteColor];
    DGActivityIndicatorView __block *spinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
    hud.customView = spinner;
    [spinner startAnimating];
    
    [cell.imageView setFile:[listing objectForKey:@"image1"]];
    [cell.imageView loadInBackground:^(UIImage * _Nullable image, NSError * _Nullable error) {
        
    } progressBlock:^(int percentDone) {
        if (percentDone == 100) {
            //remove spinner
            [spinner stopAnimating];
            [MBProgressHUD hideHUDForView:cell.imageView animated:NO];
            spinner = nil;
            hud = nil;
        }
    }];
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@", [listing objectForKey:@"title"]];
    
    NSString *condition = [listing objectForKey:@"condition"];
    
    int price = [[listing objectForKey:[NSString stringWithFormat:@"listingPrice%@", self.currency]]intValue];

    //since EUR has been recently added, do a check if the listing has a EUR price. If not, calc and save
    if ([self.currency isEqualToString:@"EUR"] && price == 0) {
        int pounds = [[listing objectForKey:@"listingPriceGBP"]intValue];
        int EUR = pounds*1.16;
        listing[@"listingPriceEUR"] = @(EUR);
        price = EUR;
        [listing saveInBackground];
    }
    cell.priceLabel.text = [NSString stringWithFormat:@"%@%d", self.currencySymbol,price];
    
    if ([condition isEqualToString:@"BNWT"]) {
        [cell.conditionView setImage:[UIImage imageNamed:@"BNWTImg"]];
    }
    else if([condition isEqualToString:@"BNWOT"]){
        [cell.conditionView setImage:[UIImage imageNamed:@"BNWOTImg"]];
    }
    else if([condition isEqualToString:@"Any"]){
        [cell.conditionView setImage:[UIImage imageNamed:@"AnyImg"]];
    }
    else if([condition isEqualToString:@"Used"]){
        [cell.conditionView setImage:[UIImage imageNamed:@"UsedImg"]];
    }
    NSString *sizeNoUK = [[listing objectForKey:@"sizeLabel"] stringByReplacingOccurrencesOfString:@"UK" withString:@""];
    sizeNoUK = [sizeNoUK stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if ([sizeNoUK isEqualToString:@"One size"]) {
        cell.sizeLabel.text = [NSString stringWithFormat:@"%@", sizeNoUK];
    }
    else if ([sizeNoUK isEqualToString:@"S"]){
        cell.sizeLabel.text = @"Small";
    }
    else if ([sizeNoUK isEqualToString:@"M"]){
        cell.sizeLabel.text = @"Medium";
    }
    else if ([sizeNoUK isEqualToString:@"L"]){
        cell.sizeLabel.text = @"Large";
    }
    else if ([[listing objectForKey:@"category"]isEqualToString:@"Clothing"]){
        cell.sizeLabel.text = [NSString stringWithFormat:@"%@", sizeNoUK];
    }
    else{
        cell.sizeLabel.text = [NSString stringWithFormat:@"%@", [listing objectForKey:@"sizeLabel"]];
    }
    
    PFGeoPoint *location = [listing objectForKey:@"geopoint"];
    if (self.currentLocation && location) {
        int distance = [location distanceInKilometersTo:self.currentLocation];
        cell.distanceLabel.text = [NSString stringWithFormat:@"%dkm", distance];
    }
    else{
        NSLog(@"no location data %@ %@", self.currentLocation, location);
        cell.distanceLabel.text = @"";
    }

    cell.backgroundColor = [UIColor whiteColor];
    
    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (self.searchEnabled == YES) {
       return self.searchResults.count;
    }
    else{
       return self.results.count;
    }
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(void)queryParseInfinite{
    if (self.pullFinished == NO) {
        return;
    }
    self.infinFinished = NO;
    self.infiniteQuery.limit = 12;
    [self.infiniteQuery whereKey:@"status" equalTo:@"live"];
    [self setupInfinQuery];
    __block NSMutableArray *wordsToSearch = [NSMutableArray array];
    
    if (self.searchEnabled == YES) {
        NSArray *searchWords = [self.searchString componentsSeparatedByString:@" "];
        [wordsToSearch addObjectsFromArray:searchWords];
        
        //remove useless words
        [wordsToSearch removeObjectsInArray:self.uselessWords];
        [self.infiniteQuery whereKey:@"keywords" containsAllObjectsInArray:wordsToSearch];
    }
    [self.infiniteQuery cancel];
    [self.infiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            self.lastInfinSkipped = self.lastInfinSkipped + count;
            
            if (self.searchEnabled == YES) {
                [self.searchResults addObjectsFromArray:objects];
            }
            else{
                //save in normal results array
                [self.results addObjectsFromArray:objects];
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
    self.pullFinished = NO;
    self.pullQuery.limit = 12;
    [self setupPullQuery];
    __block NSMutableArray *wordsToSearch = [NSMutableArray array];
    
    if (self.searchEnabled == YES) {
        NSLog(@"search enabled!! in pull query");
        NSArray *searchWords = [self.searchString componentsSeparatedByString:@" "];
        [wordsToSearch addObjectsFromArray:searchWords];
        
        //remove useless words
        [wordsToSearch removeObjectsInArray:self.uselessWords];
        [self.pullQuery whereKey:@"keywords" containsAllObjectsInArray:wordsToSearch];
    }
    
    [self.pullQuery whereKey:@"status" equalTo:@"live"];
    [self.pullQuery cancel];
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            self.lastInfinSkipped = count;
            
            if (count == 0) {
                [self.noresultsLabel setHidden:NO];
                [self.noResultsImageView setHidden:YES];
            }
            else{
                [self.noresultsLabel setHidden:YES];
                [self.noResultsImageView setHidden:YES];
            }
            
            if (self.searchEnabled == YES) {
                [self.searchResults removeAllObjects];
                [self.searchResults addObjectsFromArray:objects];
            }
            else{
                //save in normal results array
                [self.results removeAllObjects];
                [self.results addObjectsFromArray:objects];
            }
            
            [self.collectionView reloadData];
            [self.collectionView.pullToRefreshView stopAnimating];
            self.pullFinished = YES;

            if (self.shiftDown == YES) {
                self.shiftDown = NO;
                NSLog(@"shift down");
                [self.collectionView setContentOffset:CGPointMake(0, -800) animated:NO];
            }
            else if (self.shiftDown == NO && self.searchEnabled == YES){
                NSLog(@"set it to 108");
                [self.collectionView setContentOffset:CGPointMake(0,-108) animated:NO];
            }
            else if (self.filterMove == YES && self.searchEnabled == YES) {
                self.filterMove = NO;
                NSLog(@"filter down");
                [self.collectionView setContentOffset:CGPointMake(0,-108) animated:NO];
            }
//            else if(self.searchEnabled == NO){
//                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
//                                            atScrollPosition:UICollectionViewScrollPositionTop
//                                                    animated:YES];
 
//            }
        }
        else{
            NSLog(@"error on pull %@", error);
            self.pullFinished = YES;
            if (error.code == 209) {
                //invalid access token
                [PFUser logOut];
                WelcomeViewController *vc = [[WelcomeViewController alloc]init];
                NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
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
                //got location
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
        }
        else{
            NSLog(@"no geopoint %@", error);
        }
    }];
}
- (IBAction)filterPressed:(id)sender {
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
    NSLog(@"return");
    self.filtersTapped = YES;

    self.filtersArray = filters;
    if (self.filtersArray.count > 0) {
//        [self.filterButton setImage:[UIImage imageNamed:@"filterOn"] forState:UIControlStateNormal];
//        [self.filterButton.titleLabel setTextColor:[UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1]];
        NSLog(@"got some filters brah %lu", self.filtersArray.count);
        self.filterButton.titleLabel.text = [NSString stringWithFormat:@"F I L T E R S  %lu",self.filtersArray.count];
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1];
        [self.filterButton setHidden:NO];
        [self.filterBGView setHidden:NO];
    }
    else if (self.searchEnabled == YES){
        [self.filterButton setHidden:NO];
        [self.filterBGView setHidden:NO];
        if (self.filtersArray.count > 0) {
            self.filterButton.titleLabel.text = [NSString stringWithFormat:@"F I L T E R S  %lu",self.filtersArray.count];
        }
    }
    else{
//        [self.filterButton setImage:[UIImage imageNamed:@"filterButton"] forState:UIControlStateNormal];
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
        [self.filterButton setHidden:YES];
        [self.filterBGView setHidden:YES];
    }
    self.lastInfinSkipped = 0;
    NSLog(@"filters array in explore %@", self.filtersArray);
    //reset queries to remove constraints
    self.infiniteQuery = [PFQuery queryWithClassName:@"wantobuys"];
    self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
    self.filterMove = YES;
    
    //if array is empty from a 'no results' search then don't scroll to top to avoid crashing as there's 0 index paths to scroll to!
    if (self.searchResults.count != 0 && self.results.count != 0) {
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
    else{
        [self.infiniteQuery orderByDescending:@"createdAt"];
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
    else{
        [self.pullQuery orderByDescending:@"createdAt"];
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    PFObject *selected;
    
    if (self.searchEnabled == YES) {
        selected = [self.searchResults objectAtIndex:indexPath.item];
    }
    else{
        selected = [self.results objectAtIndex:indexPath.item];
    }
    
    ListingController *vc = [[ListingController alloc]init];
    vc.listingObject = selected;

    if (self.searchEnabled == YES) {
        [self.searchController.searchBar setHidden:YES];
    }
    self.listingTapped = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)searchPressed{

    self.pullFinished = YES;
    // Create the search results view controller and use it for the UISearchController.
    if (!self.resultsController) {
        self.resultsController = [[searchResultsController alloc]init];
        self.resultsController.delegate = self;
    }
    
    // Create the search controller and make it perform the results updating.
    if (!self.searchController) {
        //create new search controller
        
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.resultsController];
        self.searchController.delegate = self;

        self.searchController.searchResultsUpdater = self.resultsController;
        self.searchController.hidesNavigationBarDuringPresentation = NO;
        self.searchController.dimsBackgroundDuringPresentation = NO;
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeWords;
        self.searchController.searchBar.placeholder = @"Search for stuff you're selling";
        self.searchController.searchBar.barTintColor = [UIColor blackColor];
        self.searchController.searchBar.tintColor = [UIColor whiteColor];
        self.searchController.searchBar.delegate = self;
        self.searchController.searchBar.scopeButtonTitles = @[@"Wanted items", @"People"];
        
        //change cursor colour
        for ( UIView *v in [self.searchController.searchBar.subviews.firstObject subviews] ){
            if ( YES == [v isKindOfClass:[UITextField class]] ){
                [((UITextField*)v) setTintColor:[UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1]];
                break;
            }
        }
        [self.searchController.searchBar setTranslucent:YES];
    }
    else{
        self.searchController.searchBar.selectedScopeButtonIndex = 0;
    }
    
    self.searchController.searchBar.placeholder = @"Search for stuff you're selling";
    
    // reset filters
    [self.filtersArray removeAllObjects];
    self.filterButton.titleLabel.text = @"F I L T E R S";
//    [self.filterButton setImage:[UIImage imageNamed:@"filterButton"] forState:UIControlStateNormal];

    if (self.searchController.isActive == NO) {
        // Present the view controller.
        [self presentViewController:self.searchController animated:YES completion:^{
            [self.filterButton setHidden:NO];
            [self.filterBGView setHidden:NO];
            [self.collectionView setContentOffset:CGPointMake(0,0) animated:NO];
        }];
        self.resultsShowing = YES;
        self.searchShowing = YES;
    }
    
    self.searchEnabled = YES;
    [self.filterButton setHidden:NO];
    [self.filterBGView setHidden:NO];
}

-(void)ShouldShowSearch{
    if (self.searchController.isActive == NO) {
        [self presentViewController:self.searchController animated:YES completion:^{
            [self.searchController.searchBar resignFirstResponder];
            [self.searchController.searchResultsController.view setHidden:YES];
        }];
        self.searchShowing = YES;
    }
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    //update list
    [self.searchController.searchResultsController.view setHidden:NO];
}

-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    [self.collectionView reloadData];
    return YES;
}
-(void)willdiss:(BOOL)response{
    if (response == YES) {
        [self.searchController dismissViewControllerAnimated:NO completion:nil];
    }
}

-(void)userTapped:(PFUser *)user{
    
    UserProfileController *vc = [[UserProfileController alloc]init];
    vc.user = user;
    vc.fromSearch = YES;
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    self.userPressed = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    if (self.searchEnabled == YES) {
        self.searchString = searchBar.text;
        NSString *stringCheck = [self.searchString stringByReplacingOccurrencesOfString:@" " withString:@""];

        if (self.searchController.searchBar.selectedScopeButtonIndex == 0){
            //clear search array
            [self.searchResults removeAllObjects];
            [self.collectionView reloadData];
            
            [self.noresultsLabel setHidden:YES];
            [self.noResultsImageView setHidden:YES];
            
            NSMutableArray *history = [[NSMutableArray alloc]init];
            
            //save the search term and if there's 10 or more items in the search array delete the oldest and add the latest term
            if (![stringCheck isEqualToString:@""]) {
                
                // if haven't searched before create empty array to avoid crashing
                if ([[PFUser currentUser] objectForKey:@"searches"]) {
                    history = [[PFUser currentUser] objectForKey:@"searches"];
                    
                    if (history.count >= 15) {
                        [history removeObjectAtIndex:0];
                    }
                    
                    if (![[history lastObject] isEqualToString:self.searchString]) {
                        [history addObject:self.searchString];
                    }
                }
                else{
 //                   history = [NSMutableArray arrayWithArray:@[]];
                    NSLog(@"no history as new user so add first object");
                    [history addObject:self.searchString];
                }
                
                [[PFUser currentUser] setObject:history forKey:@"searches"];
                [[PFUser currentUser] saveInBackground];
            }
            
            //update results controller UI since only updated via query every time search button pressed
            NSMutableArray *searchesList = [NSMutableArray arrayWithArray:self.resultsController.itemResults];
            
            //        if (![searchesList containsObject:self.searchString]) {
            //            [searchesList insertObject:self.searchString atIndex:0];
            //        }
            
            if (searchesList.count > 0) {
                if (![searchesList[0] isEqualToString:self.searchString] && ![stringCheck isEqualToString:@""]) {
                    [searchesList insertObject:self.searchString atIndex:0];
                }
            }
            else if (![stringCheck isEqualToString:@""]){
                [searchesList insertObject:self.searchString atIndex:0];
            }
            
            self.resultsController.itemResults = searchesList;
            [self.resultsController.tableView reloadData];
            self.searchString = [searchBar.text lowercaseString];
            
            //query
            [self.searchController.searchResultsController.view setHidden:YES];
            self.shiftDown = YES;
            self.resultsShowing = NO;
            [self queryParsePull];
        }
        else{
            //user entered
            NSLog(@"entered username");
        }
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    NSLog(@"search this string %@", self.searchController.searchBar.text);
    if (self.searchController.searchBar.selectedScopeButtonIndex == 1){
        
        PFQuery *userQueryForRand = [PFUser query];
        [userQueryForRand whereKey:@"username" containsString:[self.searchController.searchBar.text lowercaseString]];
        [userQueryForRand whereKey:@"completedReg" equalTo:@"YES"];
        [userQueryForRand findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                NSLog(@"users found %lu", objects.count);
                if (objects.count == 0) {
                    NSLog(@"oioi");
                    if (!self.noUserLabel) {
                        self.noUserLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                        self.noUserLabel.textAlignment = NSTextAlignmentCenter;
                        self.noUserLabel.text = @"No users found";
                        [self.noUserLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:20]];
                        self.noUserLabel.numberOfLines = 1;
                        self.noUserLabel.textColor = [UIColor lightGrayColor];
                    }
                    [[UIApplication sharedApplication].keyWindow addSubview:self.noUserLabel];
                }
                else{
                    if (self.noUserLabel) {
                        [self.noUserLabel removeFromSuperview];
                    }
                }
                self.resultsController.userResults = objects;
                self.resultsController.userSearch = YES;
                [self.resultsController.tableView reloadData];
            }
            else{
                NSLog(@"error getting users %@", error);
            }
        }];
    }
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    NSLog(@"cancel clicked");
    [self.filterButton setHidden:YES];
    [self.filterBGView setHidden:YES];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];

    if (self.noUserLabel) {
        [self.noUserLabel removeFromSuperview];
    }

    self.resultsController.cancelClicked = YES;
    
    self.searchEnabled = NO;
    self.searchShowing = NO;
    self.resultsShowing = NO;
    
    [self.searchResults removeAllObjects];
    [self.collectionView setContentOffset:CGPointMake(0, -108) animated:NO];
    [self.collectionView reloadData];
    
    if (self.results.count == 0) {
        [self.noresultsLabel setHidden:NO];
        [self.noResultsImageView setHidden:YES];
    }
    else{
        [self.noresultsLabel setHidden:YES];
        [self.noResultsImageView setHidden:YES];
    }
    
    // reset filters
    [self.filtersArray removeAllObjects];
    self.filterButton.titleLabel.text = @"F I L T E R S";
//    [self.filterButton setImage:[UIImage imageNamed:@"filterButton"] forState:UIControlStateNormal];
    
    // reset the skip count and the pull query
    int count = (int)[self.results count];
    self.lastInfinSkipped = count;
    
    self.pullQuery = nil;
    self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
    
    self.infiniteQuery = nil;
    self.infiniteQuery = [PFQuery queryWithClassName:@"wantobuys"];
    
    [self queryParsePull];
}

-(void)favouriteTapped:(NSString *)favourite{
    if (self.searchEnabled == YES) {
        NSLog(@"fave tapped");
        self.searchController.searchBar.text = favourite;
        [self.searchController.searchBar resignFirstResponder];
        self.searchString = [favourite lowercaseString];
        [self.pullQuery cancel];
        [self queryParsePull];
    }
}

-(void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope{
    NSLog(@"changed");
    if (self.noUserLabel) {
        [self.noUserLabel removeFromSuperview];
    }
    self.searchController.searchBar.text = @"";
    if (selectedScope == 1) {
        //users selected
        [self.searchController.searchBar becomeFirstResponder];
        
        self.searchController.searchBar.placeholder = @"Search for users";
        [self.searchController.searchResultsController.view setHidden:NO];
        NSLog(@"users selected");
        self.resultsController.userSearch = YES;
        self.resultsController.userResults = @[];
    }
    else{
        NSLog(@"WTBs selected");
        self.searchController.searchBar.placeholder = @"Search for stuff you're selling";
        //WTBs selected
        self.resultsController.userSearch = NO;
    }
    
    [self.resultsController.tableView reloadData];
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
@end
