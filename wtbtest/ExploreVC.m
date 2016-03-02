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

@interface ExploreVC ()

@end

@implementation ExploreVC

@synthesize locationManager = _locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Explore";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    //collection view/cell setup
    [self.collectionView registerClass:[ExploreCell class] forCellWithReuseIdentifier:@"Cell"];
    
    UINib *cellNib = [UINib nibWithNibName:@"ExploreCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(175, 300)]; //iPhone 6 specific
//    [flowLayout setItemSize:CGSizeMake((self.collectionView.frame.size.width/2)-40, 300)]; //good for iPhone 5
    [flowLayout setMinimumInteritemSpacing:0];
    [flowLayout setMinimumLineSpacing:8.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1];
    
    self.results = [[NSMutableArray alloc]init];
    
    //location stuff
    [self startLocationManager];
    self.locationAllowed = [CLLocationManager locationServicesEnabled];
    
    //refresh setup
    self.pullFinished = YES;
    self.infinFinished = YES;
    self.lastInfinSkipped = 0;
    self.collectionView.pullToRefreshView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    
    self.filtersArray = [NSMutableArray array];
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
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ExploreCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    PFObject *listing = [self.results objectAtIndex:indexPath.row];
    cell.titleLabel.text = [NSString stringWithFormat:@"%@", [listing objectForKey:@"title"]];
    cell.priceLabel.text = [NSString stringWithFormat:@"%@ £%@", [listing objectForKey:@"condition"],[listing objectForKey:@"price"]];
    
    PFGeoPoint *location = [listing objectForKey:@"geopoint"];
    if (self.currentLocation && location) {
        int distance = [location distanceInKilometersTo:self.currentLocation];
        cell.distanceLabel.text = [NSString stringWithFormat:@"%dkm", distance];
    }
    else{
        cell.distanceLabel.text = @"";
    }
    
    [cell.imageView setFile:[listing objectForKey:@"image1"]];
    [cell.imageView loadInBackground];
    
    cell.backgroundColor = [UIColor whiteColor];
    
    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.results.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(void)queryParseInfinite{
    self.infinFinished = NO;
    self.infiniteQuery.limit = 4;
    [self setupInfinQuery];
    
    [self.infiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            self.lastInfinSkipped = self.lastInfinSkipped + count;
            [self.results addObjectsFromArray:objects];
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
    self.pullQuery.limit = 4;
    [self setupPullQuery];
    
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            self.lastInfinSkipped = count;
            [self.results removeAllObjects];
            [self.results addObjectsFromArray:objects];
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
            [self.infiniteQuery orderByDescending:@"price"];
        }
        else if ([self.filtersArray containsObject:@"lowtohigh"]){
            [self.infiniteQuery orderByAscending:@"price"];
        }
        
        if ([self.filtersArray containsObject:@"new"]){
            [self.infiniteQuery whereKey:@"condition" equalTo:@"New"];
        }
        else if ([self.filtersArray containsObject:@"used"]){
            [self.infiniteQuery whereKey:@"condition" equalTo:@"Used"];
        }
        
        if ([self.filtersArray containsObject:@"clothing"]){
            [self.infiniteQuery whereKey:@"category" equalTo:@"Clothing"];
        }
        else if ([self.filtersArray containsObject:@"footwear"]){
            [self.infiniteQuery whereKey:@"category" equalTo:@"Footwear"];
        }
        
        if ([self.filtersArray containsObject:@"male"]){
            [self.infiniteQuery whereKey:@"sizegender" equalTo:@"male"];
        }
        else if ([self.filtersArray containsObject:@"female"]){
            [self.infiniteQuery whereKey:@"sizegender" equalTo:@"female"];
        }
        
        //footwear sizes
        if ([self.filtersArray containsObject:@"2"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"2"];
        }
        else if ([self.filtersArray containsObject:@"3"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"3"];
        }
        else if ([self.filtersArray containsObject:@"4"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"4"];
        }
        else if ([self.filtersArray containsObject:@"5"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"5"];
        }
        else if ([self.filtersArray containsObject:@"6"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"6"];
        }
        else if ([self.filtersArray containsObject:@"7"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"7"];
        }
        else if ([self.filtersArray containsObject:@"8"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"8"];
        }
        else if ([self.filtersArray containsObject:@"9"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"9"];
        }
        else if ([self.filtersArray containsObject:@"10"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"10"];
        }
        else if ([self.filtersArray containsObject:@"11"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"11"];
        }
        else if ([self.filtersArray containsObject:@"12"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"12"];
        }
        else if ([self.filtersArray containsObject:@"13"]){
            [self.infiniteQuery whereKey:@"size" equalTo:@"13"];
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
}
-(void)setupPullQuery{
    if (self.filtersArray.count > 0) {
        if ([self.filtersArray containsObject:@"hightolow"]) {
            [self.pullQuery orderByDescending:@"price"];
        }
        else if ([self.filtersArray containsObject:@"lowtohigh"]){
            [self.pullQuery orderByAscending:@"price"];
        }
        
        if ([self.filtersArray containsObject:@"new"]){
            [self.pullQuery whereKey:@"condition" equalTo:@"New"];
        }
        else if ([self.filtersArray containsObject:@"used"]){
            [self.pullQuery whereKey:@"condition" equalTo:@"Used"];
        }
        
        if ([self.filtersArray containsObject:@"clothing"]){
            [self.pullQuery whereKey:@"category" equalTo:@"Clothing"];
        }
        else if ([self.filtersArray containsObject:@"footwear"]){
            [self.pullQuery whereKey:@"category" equalTo:@"Footwear"];
        }
        
        if ([self.filtersArray containsObject:@"male"]){
            [self.pullQuery whereKey:@"sizegender" equalTo:@"male"];
        }
        else if ([self.filtersArray containsObject:@"female"]){
            [self.pullQuery whereKey:@"sizegender" equalTo:@"female"];
        }
        
        //footwear sizes
        if ([self.filtersArray containsObject:@"2"]){
            [self.pullQuery whereKey:@"size" equalTo:@"2"];
        }
        else if ([self.filtersArray containsObject:@"3"]){
            [self.pullQuery whereKey:@"size" equalTo:@"3"];
        }
        else if ([self.filtersArray containsObject:@"4"]){
            [self.pullQuery whereKey:@"size" equalTo:@"4"];
        }
        else if ([self.filtersArray containsObject:@"5"]){
            [self.pullQuery whereKey:@"size" equalTo:@"5"];
        }
        else if ([self.filtersArray containsObject:@"6"]){
            [self.pullQuery whereKey:@"size" equalTo:@"6"];
        }
        else if ([self.filtersArray containsObject:@"7"]){
            [self.pullQuery whereKey:@"size" equalTo:@"7"];
        }
        else if ([self.filtersArray containsObject:@"8"]){
            [self.pullQuery whereKey:@"size" equalTo:@"8"];
        }
        else if ([self.filtersArray containsObject:@"9"]){
            [self.pullQuery whereKey:@"size" equalTo:@"9"];
        }
        else if ([self.filtersArray containsObject:@"10"]){
            [self.pullQuery whereKey:@"size" equalTo:@"10"];
        }
        else if ([self.filtersArray containsObject:@"11"]){
            [self.pullQuery whereKey:@"size" equalTo:@"11"];
        }
        else if ([self.filtersArray containsObject:@"12"]){
            [self.pullQuery whereKey:@"size" equalTo:@"12"];
        }
        else if ([self.filtersArray containsObject:@"13"]){
            [self.pullQuery whereKey:@"size" equalTo:@"13"];
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
}
@end
