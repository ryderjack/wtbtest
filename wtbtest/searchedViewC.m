//
//  searchedViewC.m
//  wtbtest
//
//  Created by Jack Ryder on 21/12/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "searchedViewC.h"
#import <SVPullToRefresh/SVPullToRefresh.h>
#import "NavigationController.h"
#import <Crashlytics/Crashlytics.h>

@interface searchedViewC ()

@end

@implementation searchedViewC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.noresultsLabel setHidden:YES];
    
    self.filterButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.filterButton.titleLabel.minimumScaleFactor=0.5;

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.delegate = self;
    self.navigationItem.titleView = self.searchBar;
    [self.searchBar sizeToFit];
    self.searchBar.text = self.searchString;
    
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
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    self.results = [[NSMutableArray alloc]init];
    
    [self.collectionView setScrollsToTop:YES];
    self.filtersArray = [NSMutableArray array];
    
    self.uselessWords = [NSArray arrayWithObjects:@"x",@"to",@"with",@"and",@"the",@"wtb",@"or",@" ",@".",@"very",@"interested", @"in",@"wanted", @"", nil];

    //refresh setup
    self.pullFinished = YES;
    self.infinFinished = YES;
    self.lastInfinSkipped = 0;
    self.viewedListing = NO;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.viewedListing != YES) {
        [self queryParsePull];
    }
    NSLog(@"FRAME IN SEARCHED %@", self.tabBarHeight);
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)queryParsePull{
    NSLog(@"pulling in search!");
    
    //reset the query to remove the home screen constraints
    self.pullQuery = nil;
    self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
    
    self.pullFinished = NO;
    self.pullQuery.limit = 12;
    [self setupPullQuery];
    __block NSMutableArray *wordsToSearch = [NSMutableArray array];
    
    NSArray *searchWords = [[self.searchString lowercaseString] componentsSeparatedByString:@" "];
    [wordsToSearch addObjectsFromArray:searchWords];
    
    //remove useless words
    [wordsToSearch removeObjectsInArray:self.uselessWords];
    [self.pullQuery whereKey:@"searchKeywords" containsAllObjectsInArray:wordsToSearch];
    [self.pullQuery whereKey:@"status" equalTo:@"live"];
    [self.pullQuery cancel];
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            NSLog(@"count of objects %d", count);
            self.lastInfinSkipped = count;
            
            if (count == 0) {
                [self.noresultsLabel setHidden:NO];
            }
            else{
                [self.noresultsLabel setHidden:YES];
            }
            
            [self.results removeAllObjects];
            [self.results addObjectsFromArray:objects];
            
            [self.collectionView reloadData];
            [self.collectionView.pullToRefreshView stopAnimating];
            self.pullFinished = YES;
        }
        else{
            NSLog(@"error on pull %@", error);
            self.pullFinished = YES;
            [self showError];
        }
    }];
}

-(void)queryParseInfinite{
    if (self.pullFinished == NO) {
        return;
    }
    NSLog(@"infinity in search");
    self.infiniteQuery = nil;
    self.infiniteQuery = [PFQuery queryWithClassName:@"wantobuys"];
    self.infinFinished = NO;
    self.infiniteQuery.limit = 12;
    self.infiniteQuery.skip = self.lastInfinSkipped;
    [self.infiniteQuery whereKey:@"status" equalTo:@"live"];
    [self setupInfinQuery];
    __block NSMutableArray *wordsToSearch = [NSMutableArray array];
    
    NSArray *searchWords = [[self.searchString lowercaseString] componentsSeparatedByString:@" "];
    [wordsToSearch addObjectsFromArray:searchWords];
    
    //remove useless words
    [wordsToSearch removeObjectsInArray:self.uselessWords];
    [self.infiniteQuery whereKey:@"searchKeywords" containsAllObjectsInArray:wordsToSearch];
    [self.infiniteQuery cancel];
    [self.infiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            NSLog(@"infin count %d", count);
            self.lastInfinSkipped = self.lastInfinSkipped + count;
            [self.results addObjectsFromArray:objects];
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

-(void)cancelPressed{
    [self.searchBar resignFirstResponder];
    [self.delegate cancellingOtherSearch];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(8, 8, 8, 8); // top, left, bottom, right
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    
    self.cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    self.cell.delegate = self;
    
    PFObject *listing = [self.results objectAtIndex:indexPath.row];
    
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


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.results.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    self.viewedListing = YES;
    if (!self.lastSelected) {
        self.lastSelected = [[NSIndexPath alloc]init];
    }
    self.lastSelected = indexPath;
    PFObject *selected;

    selected = [self.results objectAtIndex:indexPath.item];
    
    ListingController *vc = [[ListingController alloc]init];
    vc.listingObject = selected;
    vc.fromSearch = YES;
    vc.tabBarHeight = self.tabBarHeight;
    [self.navigationController pushViewController:vc animated:YES];
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
    ExploreCell *cell = sender;
    
    [Answers logCustomEventWithName:@"Bumped a listing"
                   customAttributes:@{
                                      @"where":@"Search"
                                      }];
    
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
                                              @"where":@"Search"
                                              }];
        }
    }
    
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
    else{
        [self.pullQuery orderByDescending:@"createdAt"];
    }
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
    else{
        [self.infiniteQuery orderByDescending:@"createdAt"];
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self.searchBar resignFirstResponder];
    self.searchString = searchBar.text;
    NSString *stringCheck = [self.searchString stringByReplacingOccurrencesOfString:@" " withString:@""];
    [self.delegate enteredSearchTerm:self.searchString];

    if (![stringCheck isEqualToString:@""]) {
        [self.results removeAllObjects];
        [self.collectionView reloadData];
        self.searchString = self.searchBar.text;
        [self queryParsePull];
    }
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    [self.searchBar resignFirstResponder];
    self.searchString = searchBar.text;
    NSString *stringCheck = [self.searchString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (![stringCheck isEqualToString:@""]) {
        [self.delegate enteredSearchTerm:self.searchString];
    }
}

- (IBAction)filterPressed:(id)sender {
    [Answers logCustomEventWithName:@"Filters pressed"
                   customAttributes:@{
                                      @"page":@"Search"
                                      }];
    FilterVC *vc = [[FilterVC alloc]init];
    vc.delegate = self;
    if (self.filtersArray.count > 0) {
        vc.sendArray = [NSMutableArray arrayWithArray:self.filtersArray];
    }
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)filtersReturned:(NSMutableArray *)filters{
    [self.results removeAllObjects];
    [self.collectionView reloadData];
    
    self.filtersArray = filters;
    if (self.filtersArray.count > 0) {
        NSLog(@"got some filters brah %lu", self.filtersArray.count);
        self.filterButton.titleLabel.text = [NSString stringWithFormat:@"F I L T E R S  %lu",self.filtersArray.count];
    }
    else{
        //no filters
        self.filterButton.titleLabel.text = [NSString stringWithFormat:@"F I L T E R S  OFF"];
    }
    self.lastInfinSkipped = 0;
    
    NSLog(@"filters array in explore %@", self.filtersArray);
    
    if (self.results.count != 0) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:NO];
    }
    [self queryParsePull];
}

-(void)noChange{
    if (self.filtersArray > 0) {
        self.filterButton.titleLabel.text = [NSString stringWithFormat:@"F I L T E R S  %lu",self.filtersArray.count];
    }
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
@end
