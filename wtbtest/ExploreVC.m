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
    
    self.navigationItem.title = @"wantobuy";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"question"] style:UIBarButtonItemStylePlain target:self action:@selector(showExtraInfo)];
    
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"searchBarIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(searchPressed)];
    
    self.navigationItem.rightBarButtonItem = infoButton;
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
    
    // set searchbar font
    NSDictionary *searchAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:13],
                                      NSFontAttributeName, nil];
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setDefaultTextAttributes:searchAttributes];
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
    if (!self.infiniteQuery) {
        self.infiniteQuery = [PFQuery queryWithClassName:@"wantobuys"];
    }
    if (!self.pullQuery) {
        self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
    }
    
    if (self.pullFinished == YES) {
        [self queryParsePull];
    }
    
    if (self.searchEnabled == YES) {
        [self.searchController.searchBar setHidden:NO];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (![PFUser currentUser]) {
        WelcomeViewController *vc = [[WelcomeViewController alloc]init];
        NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navController animated:YES completion:nil];
    }
    
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasFBUpdate111"])
//    {
//        // Has feedback update
//    }
//    else
//    {
//        [PFUser logOut];
//        
//        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasFBUpdate"];
//        
//        WelcomeViewController *vc = [[WelcomeViewController alloc]init];
//        NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
//        [self presentViewController:navController animated:YES completion:nil];
//        
//    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ExploreCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    PFObject *listing;
    
    if (self.searchEnabled == YES) {
        listing = [self.searchResults objectAtIndex:indexPath.row];
    }
    else{
        listing = [self.results objectAtIndex:indexPath.row];
    }
    
    [cell.imageView setFile:[listing objectForKey:@"image1"]];
    [cell.imageView loadInBackground];
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@", [listing objectForKey:@"title"]];
    
    NSString *condition = [listing objectForKey:@"condition"];
    int price = [[listing objectForKey:@"listingPrice"] intValue];
    cell.priceLabel.text = [NSString stringWithFormat:@"%@ £%d", condition,price];
    
    if ([[listing objectForKey:@"size"] isEqualToString:@"One size"]) {
        cell.sizeLabel.text = [NSString stringWithFormat:@"%@", [listing objectForKey:@"size"]];
    }else{
        cell.sizeLabel.text = [NSString stringWithFormat:@"UK %@", [listing objectForKey:@"size"]];
    }
    
    PFGeoPoint *location = [listing objectForKey:@"geopoint"];
    if (self.currentLocation && location) {
        int distance = [location distanceInKilometersTo:self.currentLocation];
        cell.distanceLabel.text = [NSString stringWithFormat:@"%dkm", distance];
    }
    else{
        NSLog(@"nothing! %@ %@", self.currentLocation, location);
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
    self.infinFinished = NO;
    self.infiniteQuery.limit = 8;
    [self.infiniteQuery whereKey:@"status" notEqualTo:@"purchased"];
    [self setupInfinQuery];
    
    if (self.searchEnabled == YES) {
        [self.infiniteQuery whereKey:@"title" matchesRegex:self.searchString];
    }
    
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
        }
    }];
}
-(void)queryParsePull{
    self.pullFinished = NO;
    self.pullQuery.limit = 8;
    [self setupPullQuery];
    
    if (self.searchEnabled == YES) {
        [self.pullQuery whereKey:@"title" matchesRegex:self.searchString];
    }
    
    [self.pullQuery whereKey:@"status" notEqualTo:@"purchased"];
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            if (count == 0) {
                [self.noresultsLabel setHidden:NO];
                [self.noResultsImageView setHidden:NO];
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
                
//                NSSortDescriptor *sortDescriptor;
//                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"listingPrice"
//                                                             ascending:NO];
//                NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
//                NSArray *sortedArray = [objects sortedArrayUsingDescriptors:sortDescriptors];
                
                [self.results addObjectsFromArray:objects];
            }
            
            [self.collectionView reloadData];
            [self.collectionView.pullToRefreshView stopAnimating];
            self.pullFinished = YES;
        }
        else{
            NSLog(@"error %@", error);
            self.pullFinished = YES;
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
                                          message:@"Enable location services in settings to view wantobuy listings nearby!"
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
            [self.infiniteQuery orderByDescending:@"listingPrice"];
        }
        else if ([self.filtersArray containsObject:@"lowtohigh"]){
            [self.infiniteQuery orderByAscending:@"listingPrice"];
        }
        
        if ([self.filtersArray containsObject:@"new"]){
            [self.infiniteQuery whereKey:@"condition" containsString:@"New"];
        }
        else if ([self.filtersArray containsObject:@"used"]){
            [self.infiniteQuery whereKey:@"condition" equalTo:@"Used"];
        }
        
        if ([self.filtersArray containsObject:@"clothing"]){
            [self.infiniteQuery whereKey:@"category" equalTo:@"Clothing"];
        }
        else if ([self.filtersArray containsObject:@"footwear"]){
            [self.infiniteQuery whereKey:@"category" equalTo:@"Footwear"];
            
            if ([self.filtersArray containsObject:@"male"]){
                [self.infiniteQuery whereKey:@"sizeGender" equalTo:@"Mens"];
            }
            else if ([self.filtersArray containsObject:@"female"]){
                [self.infiniteQuery whereKey:@"sizeGender" equalTo:@"Womens"];
            }
        }
        
        //footwear sizes
        if ([self.filtersArray containsObject:@"3"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"3"];
        }
        else if ([self.filtersArray containsObject:@"3.5"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"3.5"];
        }
        else if ([self.filtersArray containsObject:@"4"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"4"];
        }
        else if ([self.filtersArray containsObject:@"4.5"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"4.5"];
        }
        else if ([self.filtersArray containsObject:@"5"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"5"];
        }
        else if ([self.filtersArray containsObject:@"5.5"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"5.5"];
        }
        else if ([self.filtersArray containsObject:@"6"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"6"];
        }
        else if ([self.filtersArray containsObject:@"6.5"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"6.5"];
        }
        else if ([self.filtersArray containsObject:@"7"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"7"];
        }
        else if ([self.filtersArray containsObject:@"7.5"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"7.5"];
        }
        else if ([self.filtersArray containsObject:@"8"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"8"];
        }
        else if ([self.filtersArray containsObject:@"8.5"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"8.5"];
        }
        else if ([self.filtersArray containsObject:@"9"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"9"];
        }
        else if ([self.filtersArray containsObject:@"9.5"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"9.5"];
        }
        else if ([self.filtersArray containsObject:@"10"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"10"];
        }
        else if ([self.filtersArray containsObject:@"10.5"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"10.5"];
        }
        else if ([self.filtersArray containsObject:@"11"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"11"];
        }
        else if ([self.filtersArray containsObject:@"11.5"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"11.5"];
        }
        else if ([self.filtersArray containsObject:@"12"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"12"];
        }
        else if ([self.filtersArray containsObject:@"12.5"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"12.5"];
        }
        else if ([self.filtersArray containsObject:@"13"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"13"];
        }
        else if ([self.filtersArray containsObject:@"13.5"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"13.5"];
        }
        else if ([self.filtersArray containsObject:@"14"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"14"];
        }
        
        if ([self.filtersArray containsObject:@"XXS"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"XXS"];
        }
        else if ([self.filtersArray containsObject:@"XS"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"XS"];
        }
        else if ([self.filtersArray containsObject:@"S"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"S"];
        }
        else if ([self.filtersArray containsObject:@"M"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"M"];
        }
        else if ([self.filtersArray containsObject:@"L"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"L"];
        }
        else if ([self.filtersArray containsObject:@"XL"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"XL"];
        }
        else if ([self.filtersArray containsObject:@"XXL"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"XXL"];
        }
        else if ([self.filtersArray containsObject:@"OS"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"OS"];
        }
    }
    else{
        [self.infiniteQuery orderByDescending:@"createdAt"];
    }
}
-(void)setupPullQuery{
    if (self.filtersArray.count > 0) {
        if ([self.filtersArray containsObject:@"hightolow"]) {
            [self.pullQuery orderByDescending:@"listingPrice"];
        }
        else if ([self.filtersArray containsObject:@"lowtohigh"]){
            [self.pullQuery orderByAscending:@"listingPrice"];
        }
        
        if ([self.filtersArray containsObject:@"new"]){
            [self.pullQuery whereKey:@"condition" containsString:@"New"];
        }
        else if ([self.filtersArray containsObject:@"used"]){
            [self.pullQuery whereKey:@"condition" equalTo:@"Used"];
        }
        
        if ([self.filtersArray containsObject:@"clothing"]){
            [self.pullQuery whereKey:@"category" equalTo:@"Clothing"];
        }
        else if ([self.filtersArray containsObject:@"footwear"]){
            [self.pullQuery whereKey:@"category" equalTo:@"Footwear"];
            
            if ([self.filtersArray containsObject:@"male"]){
                [self.pullQuery whereKey:@"sizeGender" equalTo:@"Mens"];
            }
            else if ([self.filtersArray containsObject:@"female"]){
                [self.pullQuery whereKey:@"sizeGender" equalTo:@"Womens"];
            }
        }
        
        //footwear sizes
        if ([self.filtersArray containsObject:@"3"]){
            [self.pullQuery whereKey:@"size" equalTo:@"3"];
        }
        else if ([self.filtersArray containsObject:@"3.5"]){
            [self.pullQuery whereKey:@"size" equalTo:@"3.5"];
        }
        else if ([self.filtersArray containsObject:@"4"]){
            [self.pullQuery whereKey:@"size" equalTo:@"4"];
        }
        else if ([self.filtersArray containsObject:@"4.5"]){
            [self.pullQuery whereKey:@"size" equalTo:@"4.5"];
        }
        else if ([self.filtersArray containsObject:@"5"]){
            [self.pullQuery whereKey:@"size" equalTo:@"5"];
        }
        else if ([self.filtersArray containsObject:@"5.5"]){
            [self.pullQuery whereKey:@"size" equalTo:@"5.5"];
        }
        else if ([self.filtersArray containsObject:@"6"]){
            [self.pullQuery whereKey:@"size" equalTo:@"6"];
        }
        else if ([self.filtersArray containsObject:@"6.5"]){
            [self.pullQuery whereKey:@"size" equalTo:@"6.5"];
        }
        else if ([self.filtersArray containsObject:@"7"]){
            [self.pullQuery whereKey:@"size" equalTo:@"7"];
        }
        else if ([self.filtersArray containsObject:@"7.5"]){
            [self.pullQuery whereKey:@"size" equalTo:@"7.5"];
        }
        else if ([self.filtersArray containsObject:@"8"]){
            [self.pullQuery whereKey:@"size" equalTo:@"8"];
        }
        else if ([self.filtersArray containsObject:@"8.5"]){
            [self.pullQuery whereKey:@"size" equalTo:@"8.5"];
        }
        else if ([self.filtersArray containsObject:@"9"]){
            [self.pullQuery whereKey:@"size" equalTo:@"9"];
        }
        else if ([self.filtersArray containsObject:@"9.5"]){
            [self.pullQuery whereKey:@"size" equalTo:@"9.5"];
        }
        else if ([self.filtersArray containsObject:@"10"]){
            [self.pullQuery whereKey:@"size" equalTo:@"10"];
        }
        else if ([self.filtersArray containsObject:@"10.5"]){
            [self.pullQuery whereKey:@"size" equalTo:@"10.5"];
        }
        else if ([self.filtersArray containsObject:@"11"]){
            [self.pullQuery whereKey:@"size" equalTo:@"11"];
        }
        else if ([self.filtersArray containsObject:@"11.5"]){
            [self.pullQuery whereKey:@"size" equalTo:@"11.5"];
        }
        else if ([self.filtersArray containsObject:@"12"]){
            [self.pullQuery whereKey:@"size" equalTo:@"12"];
        }
        else if ([self.filtersArray containsObject:@"12.5"]){
            [self.pullQuery whereKey:@"size" equalTo:@"12.5"];
        }
        else if ([self.filtersArray containsObject:@"13"]){
            [self.pullQuery whereKey:@"size" equalTo:@"13"];
        }
        else if ([self.filtersArray containsObject:@"13.5"]){
            [self.pullQuery whereKey:@"size" equalTo:@"13.5"];
        }
        else if ([self.filtersArray containsObject:@"14"]){
            [self.pullQuery whereKey:@"size" equalTo:@"14"];
        }
       
        //clothing sizes
        if ([self.filtersArray containsObject:@"XXS"]){
            [self.pullQuery whereKey:@"size" equalTo:@"XXS"];
        }
        else if ([self.filtersArray containsObject:@"XS"]){
            [self.pullQuery whereKey:@"size" equalTo:@"XS"];
        }
        else if ([self.filtersArray containsObject:@"S"]){
            [self.pullQuery whereKey:@"size" equalTo:@"S"];
        }
        else if ([self.filtersArray containsObject:@"M"]){
            [self.pullQuery whereKey:@"size" equalTo:@"M"];
        }
        else if ([self.filtersArray containsObject:@"L"]){
            [self.pullQuery whereKey:@"size" equalTo:@"L"];
        }
        else if ([self.filtersArray containsObject:@"XL"]){
            [self.pullQuery whereKey:@"size" equalTo:@"XL"];
        }
        else if ([self.filtersArray containsObject:@"XXL"]){
            [self.pullQuery whereKey:@"size" equalTo:@"XXL"];
        }
        else if ([self.filtersArray containsObject:@"OS"]){
            [self.pullQuery whereKey:@"size" equalTo:@"OS"];
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
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)showExtraInfo{
    ExplainViewController *vc = [[ExplainViewController alloc]init];
    vc.setting = @"process";
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)searchPressed{
    // Create the search results view controller and use it for the UISearchController.
    self.resultsController = [[searchResultsController alloc]init];
    self.resultsController.delegate = self;
    
    // Create the search controller and make it perform the results updating.
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.resultsController];
    self.searchController.delegate = self;
    
    self.searchController.searchResultsUpdater = self.resultsController;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.placeholder = @"Search for stuff you're selling";

    self.searchController.searchBar.barTintColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
    self.searchController.searchBar.tintColor = [UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1];
    
    [self.searchController.searchBar setTranslucent:YES];
    self.searchEnabled = YES;
    
    // reset filters
    [self.filtersArray removeAllObjects];
    [self.filterButton setImage:[UIImage imageNamed:@"filterButton"] forState:UIControlStateNormal];
        
    // Present the view controller.
    [self presentViewController:self.searchController animated:YES completion:nil];
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
        
        //query
        [self.searchController.searchResultsController.view setHidden:YES];
        [self queryParsePull];
    }
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    self.searchEnabled = NO;
    
    if (self.results.count == 0) {
        [self.noresultsLabel setHidden:NO];
        [self.noResultsImageView setHidden:NO];
    }
    else{
        [self.noresultsLabel setHidden:YES];
        [self.noResultsImageView setHidden:YES];
    }
    
    // cancel existing search queries
    [self.pullQuery cancel];
    [self.infiniteQuery cancel];
    
    // reset filters
    [self.filtersArray removeAllObjects];
    [self.filterButton setImage:[UIImage imageNamed:@"filterButton"] forState:UIControlStateNormal];
    
    // reset the skip count and the pull query
    int count = (int)[self.results count];
    self.lastInfinSkipped = count;
    
    self.pullQuery = nil;
    self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
    
    [self.collectionView reloadData];
}

-(void)favouriteTapped:(NSString *)favourite{
    if (self.searchEnabled == YES) {
        self.searchController.searchBar.text = favourite;
        [self.searchController.searchBar resignFirstResponder];
        self.searchString = favourite;
        [self.pullQuery cancel];
        [self queryParsePull];
    }
}
@end
