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
#import "ExplainViewController.h"
#import "WelcomeViewController.h"
#import "NavigationController.h"
#import "Flurry.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>


@interface ExploreVC ()

@end

@implementation ExploreVC

@synthesize locationManager = _locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.noresultsLabel setHidden:YES];
    [self.noResultsImageView setHidden:YES];
    
    self.searchString = @"";
    self.searchEnabled = NO;
    
    self.navigationItem.title = @"Bump";
    
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"searchBarIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(searchPressed)];
    self.navigationItem.leftBarButtonItem = searchButton;
    
    //collection view/cell setup
    [self.collectionView registerClass:[ExploreCell class] forCellWithReuseIdentifier:@"Cell"];
    
    UINib *cellNib = [UINib nibWithNibName:@"ExploreCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [flowLayout setItemSize:CGSizeMake((self.collectionView.frame.size.width/2)-40, 300)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.height == 736){
        //iphone 6 plus
        [flowLayout setItemSize:CGSizeMake((self.collectionView.frame.size.width/2), 300)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.height == 480){
        //iphone 4
        [flowLayout setItemSize:CGSizeMake((self.collectionView.frame.size.width/2)-40, 300)];
    }
    else{
        [flowLayout setItemSize:CGSizeMake(175, 300)]; //iPhone 6 specific
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
    
    self.filtersArray = [NSMutableArray array];
    self.filtersTapped = NO;
    
    // set searchbar font
    NSDictionary *searchAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:13],
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
//                        NSLog(@"I have a friend named %@ with id %@", [friend objectForKey:@"name"], [friend objectForKey:@"id"]);
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
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-HeavyItalic" size:17],
                                    NSFontAttributeName, [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0], NSForegroundColorAttributeName,  nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if (![PFUser currentUser]) {
        WelcomeViewController *vc = [[WelcomeViewController alloc]init];
        NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else{
        self.currency = [[PFUser currentUser]objectForKey:@"currency"];
        if ([self.currency isEqualToString:@"GBP"]) {
            self.currencySymbol = @"£";
        }
        else{
            self.currencySymbol = @"$";
        }
    }
    
    if (!self.infiniteQuery) {
        self.infiniteQuery = [PFQuery queryWithClassName:@"wantobuys"];
    }
    if (!self.pullQuery) {
        self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
    }
    
    if (self.pullFinished == YES) {
        if (self.listingTapped == NO) {
            [self queryParsePull];
        }
    }
    
    if (self.searchEnabled == YES) {
        [self.searchController.searchBar setHidden:NO];
    }
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
    
    if (self.searchEnabled == YES && self.filtersTapped == NO && self.listingTapped == NO) {
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
    
    //upon first open show 'How it works' VC modally
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showHowWorks"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showHowWorks"];
        ExplainViewController *vc = [[ExplainViewController alloc]init];
        [self presentViewController:vc animated:YES completion:nil];
    }
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
    
    if ([[listing objectForKey:@"sizeLabel"] isEqualToString:@"One size"]) {
        cell.sizeLabel.text = [NSString stringWithFormat:@"%@", [listing objectForKey:@"sizeLabel"]];
    }else{
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
    
    if (self.searchEnabled == YES) {
        [self.infiniteQuery whereKey:@"titleLower" containsString:self.searchString];
    }
    [self.infiniteQuery cancel];
    [self.infiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            self.lastInfinSkipped = self.lastInfinSkipped + count;
            
            if (self.searchEnabled == YES) {
                //save in searchResults array
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
    NSLog(@"query here");
    self.pullFinished = NO;
    self.pullQuery.limit = 12;
    [self setupPullQuery];
    if (self.searchEnabled == YES) {
        [self.pullQuery whereKey:@"titleLower" containsString:self.searchString];
    }
    
    [self.pullQuery whereKey:@"status" equalTo:@"live"];
    [self.pullQuery cancel];
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            if (count == 0) {
                [self.noresultsLabel setHidden:NO];
                [self.noResultsImageView setHidden:YES];
            }
            else{
                [self.noresultsLabel setHidden:YES];
                [self.noResultsImageView setHidden:YES];
            }
            self.lastInfinSkipped = count;
            
            if (self.searchEnabled == YES) {
                //save in searchResults array
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
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)filtersReturned:(NSMutableArray *)filters{
    self.filtersTapped = YES;
    
    self.filtersArray = filters;
    if (self.filtersArray.count > 0) {
        [self.filterButton setImage:[UIImage imageNamed:@"filterOn"] forState:UIControlStateNormal];
    }
    else{
        [self.filterButton setImage:[UIImage imageNamed:@"filterButton"] forState:UIControlStateNormal];
    }
    self.lastInfinSkipped = 0;
    NSLog(@"filters array in explore %@", self.filtersArray);
    //rest queries to remove constraints
    self.infiniteQuery = [PFQuery queryWithClassName:@"wantobuys"];
    self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
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
    // Create the search results view controller and use it for the UISearchController.
    self.resultsController = [[searchResultsController alloc]init];
    self.resultsController.delegate = self;
    
    // Create the search controller and make it perform the results updating.
    if (!self.searchController) {
        NSLog(@"must create a new search controller");
        
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.resultsController];
        self.searchController.delegate = self;
        
        self.searchController.searchResultsUpdater = self.resultsController;
        self.searchController.hidesNavigationBarDuringPresentation = NO;
        self.searchController.dimsBackgroundDuringPresentation = NO;
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeWords;
        self.searchController.searchBar.delegate = self;
        self.searchController.searchBar.placeholder = @"Search for stuff you're selling";
        self.searchController.searchBar.barTintColor = [UIColor blackColor];
        self.searchController.searchBar.tintColor = [UIColor whiteColor];
        
        //change cursor colour
        for ( UIView *v in [self.searchController.searchBar.subviews.firstObject subviews] ){
            if ( YES == [v isKindOfClass:[UITextField class]] ){
                [((UITextField*)v) setTintColor:[UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1]];
                break;
            }
        }
        
        [self.searchController.searchBar setTranslucent:YES];
        
        // reset filters
        [self.filtersArray removeAllObjects];
        [self.filterButton setImage:[UIImage imageNamed:@"filterButton"] forState:UIControlStateNormal];
    }
    else{
        NSLog(@"already got a search controller");
    }
    
    NSLog(self.listingTapped ? @"yep listing tapped in pressed": @"nope listing tapped");
    
    if (self.searchController.isActive == NO) {
        // Present the view controller.
        [self presentViewController:self.searchController animated:YES completion:nil];
        self.resultsShowing = YES;
        self.searchShowing = YES;
    }
    
    self.searchEnabled = YES;
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
-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    if (self.searchEnabled == YES) {
        
        self.searchString = searchBar.text;

        //clear search array
        [self.searchResults removeAllObjects];
        [self.noresultsLabel setHidden:YES];
        [self.noResultsImageView setHidden:YES];
        
        NSMutableArray *history = [[NSMutableArray alloc]init];
        
        //save the search term and if there's 10 or more items in the search array delete the oldest and add the latest term
        if (![self.searchString isEqualToString:@""]) {
            
            // if haven't searched before create empty array to avoid crashing
            
            if ([[PFUser currentUser] objectForKey:@"searches"]) {
                history = [[PFUser currentUser] objectForKey:@"searches"];
            }
            else{
                history = [NSMutableArray arrayWithArray:@[]];
            }
            
            if (history.count >= 15) {
                [history removeObjectAtIndex:0];
            }
            [history addObject:self.searchString];
            
            [[PFUser currentUser] setObject:history forKey:@"searches"];
            [[PFUser currentUser] saveEventually];
        }
        
        //update results controller UI since only updated via query every time search button pressed
        
        NSMutableArray *searchesList = [NSMutableArray arrayWithArray:self.resultsController.allResults];
        [searchesList insertObject:self.searchString atIndex:0];
        self.resultsController.allResults = searchesList;
        [self.resultsController.tableView reloadData];
        
        self.searchString = [searchBar.text lowercaseString];
        
        //query
        [self.searchController.searchResultsController.view setHidden:YES];
        self.resultsShowing = NO;
        [self queryParsePull];
    }
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    self.searchEnabled = NO;
    self.searchShowing = NO;
    self.resultsShowing = NO;
    
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
    [self.filterButton setImage:[UIImage imageNamed:@"filterButton"] forState:UIControlStateNormal];
    
    // reset the skip count and the pull query
    int count = (int)[self.results count];
    self.lastInfinSkipped = count;
    
    self.pullQuery = nil;
    self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
    
    [self queryParsePull];
}

-(void)favouriteTapped:(NSString *)favourite{
    if (self.searchEnabled == YES) {
        self.searchController.searchBar.text = favourite;
        [self.searchController.searchBar resignFirstResponder];
        self.searchString = [favourite lowercaseString];
        [self.pullQuery cancel];
        [self queryParsePull];
    }
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
