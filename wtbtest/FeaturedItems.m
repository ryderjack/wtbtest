//
//  FeaturedItems.m
//  wtbtest
//
//  Created by Jack Ryder on 17/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "FeaturedItems.h"
#import "ForSaleListing.h"
#import "NavigationController.h"
#import "ProfileItemCell.h"
#import <SVPullToRefresh/SVPullToRefresh.h>


@interface FeaturedItems ()

@end

@implementation FeaturedItems

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.alwaysBounceVertical = YES;
    
    self.listings = [NSMutableArray array];
    
    self.pullFinished = YES;
    self.infinFinished = YES;
    self.skipped = 0;
    
    
    
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    //put refresh code here so it remembers correct UICollectionView insets - doesn't work in VDL
    [self.collectionView addPullToRefreshWithActionHandler:^{
        if (self.pullFinished == YES) {
            [self loadShop];
        }
    }];
    
    self.otherSpinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
    [self.collectionView.pullToRefreshView setCustomView:self.otherSpinner forState:SVPullToRefreshStateAll];
    [self.otherSpinner startAnimating];
    
    [self.collectionView addInfiniteScrollingWithActionHandler:^{
        if (self.infinFinished == YES) {
            [self loadInfinShop];
        }
    }];
}
-(NSMutableArray *)getRandomsLessThan:(int)M {  /////////////////////CHECK - ennsure number of for sale listings is bigger than 30
    NSMutableArray *listOfNumbers = [[NSMutableArray alloc] init];
    for (int i=0 ; i<M ; ++i) {
        [listOfNumbers addObject:[NSNumber numberWithInt:i]]; // ADD 1 TO GET NUMBERS BETWEEN 1 AND M RATHER THAN 0 and M-1
    }
    NSMutableArray *uniqueNumbers = [[NSMutableArray alloc] init];
    int r;
    while ([uniqueNumbers count] < 30) {
        r = arc4random() % [listOfNumbers count];
        if (![uniqueNumbers containsObject:[listOfNumbers objectAtIndex:r]]) {
            [uniqueNumbers addObject:[listOfNumbers objectAtIndex:r]];
        }
    }
    return uniqueNumbers;
}

-(void)loadListings{
    [self showHUD];
    //get random for sale items
    PFQuery *featuredQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [featuredQuery whereKey:@"status" equalTo:@"live"];
    [featuredQuery whereKey:@"feature" equalTo:@"YES"];
    [featuredQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            [self.listings removeAllObjects];
            [self.listings addObjectsFromArray:objects];

            PFQuery *forSaleQuery = [PFQuery queryWithClassName:@"forSaleItems"];
            [forSaleQuery whereKey:@"status" equalTo:@"live"];
            [forSaleQuery countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
                if (number) {
                    NSArray *indexesToGet = [self getRandomsLessThan:number];
                    PFQuery *forSaleQuery1 = [PFQuery queryWithClassName:@"forSaleItems"];
                    [forSaleQuery1 whereKey:@"status" equalTo:@"live"];
                    [forSaleQuery1 whereKey:@"index" containedIn:indexesToGet];
                    forSaleQuery1.limit = 30-self.listings.count;
                    [forSaleQuery1 findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                        if (objects) {
                            for (PFObject *listing in objects) {
                                if (![self.listings containsObject:listing]) {
                                    [self.listings addObject:listing];
                                }
                            }
                            [self hideHUD];
                            [self.collectionView reloadData];
                        }
                        else{
                            [self hideHUD];
                            NSLog(@"error getting extra for sale listings %@", error);
                        }
                    }];
                }
                else{
                    [self hideHUD];
                    NSLog(@"error counting %@", error);
                }
            }];
        }
        else{
            [self hideHUD];
            NSLog(@"error getting for sale listings %@", error);
        }
    }];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if ([self.mode isEqualToString:@"shop"]) {
        //load that type
        if ([self.shop isEqualToString:@"yeezy"]) {
            self.title = @"S H O P  Y E E Z Y";
        }
        else if ([self.shop isEqualToString:@"sup"]){
            self.title = @"S H O P  S U P R E M E";
        }
        else if ([self.shop isEqualToString:@"palace"]){
            self.title = @"S H O P  P A L A C E";
        }
        
        if (self.viewedItem == YES) {
            self.viewedItem = NO;
        }
        else{
            [self loadShop];
        }
        
    }
    else{
        //load featured poss?
    }
    
    [self.infiniteQuery cancel];
    [self.collectionView.pullToRefreshView stopAnimating];
    [self.collectionView.infiniteScrollingView stopAnimating];
    self.infinFinished = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.listings.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ProfileItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    [cell.purchasedImageView setHidden:YES];
    cell.itemImageView.image = nil;
    cell.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    cell.itemImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    PFObject *listingObject = [self.listings objectAtIndex:indexPath.item];
    
    [cell.itemImageView setFile:[listingObject objectForKey:@"image1"]];
    [cell.itemImageView loadInBackground];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    self.viewedItem = YES;
    
    PFObject *selected = [self.listings objectAtIndex:indexPath.item];
    ForSaleListing *vc = [[ForSaleListing alloc]init];
    vc.listingObject = selected;
    vc.source = @"shop";
    vc.pureWTS = YES;
    vc.fromBuyNow = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    if (!self.spinner) {
        self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    }
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

-(void)viewWillDisappear:(BOOL)animated{
    [self hideHUD];
}

-(void)loadShop{
    if (self.pullFinished == NO) {
        return;
    }
    
    self.pullFinished = NO;
    
    self.pullQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [self.pullQuery whereKey:@"status" equalTo:@"live"];
    if ([self.shop isEqualToString:@"yeezy"]) {
        [self.pullQuery whereKey:@"keywords" containedIn:@[@"yeezy", @"350", @"750", @"yeezys", @"pirates", @"moonrock", @"V2", @"kanye", @"merch", @"pablo", @"west", @"dons", @"oreo"]];
    }
    else if ([self.shop isEqualToString:@"sup"]){
        [self.pullQuery whereKey:@"keywords" containedIn:@[@"supreme", @"sup", @"bogo", @"box logo", @"preme"]];
    }
    else if ([self.shop isEqualToString:@"palace"]){
        [self.pullQuery whereKey:@"keywords" containedIn:@[@"palace", @"palidas", @"triferg", @"tri-ferg", @"tri", @"ferg"]];
    }
    self.pullQuery.limit = 30;
    [self.pullQuery orderByDescending:@"lastUpdated"];
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            if (objects.count == 0) {
                [self.collectionView.pullToRefreshView stopAnimating];
                self.pullFinished = YES;
                return;
            }
            self.skipped = (int)objects.count;

            [self.listings removeAllObjects];
            [self.listings addObjectsFromArray:objects];
            
            [self shuffle:self.listings];
            
            [self.collectionView reloadData];
            
            self.pullFinished = YES;
            [self.collectionView.pullToRefreshView stopAnimating];
        }
    }];
}

-(void)loadInfinShop{
    if (self.infinFinished == NO || self.pullFinished == NO) {
        return;
    }
    
    self.infinFinished = NO;
    
    self.infiniteQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [self.infiniteQuery whereKey:@"status" equalTo:@"live"];
    if ([self.shop isEqualToString:@"yeezy"]) {
        [self.infiniteQuery whereKey:@"keywords" containedIn:@[@"yeezy", @"350", @"750", @"yeezys", @"pirates", @"moonrock", @"V2", @"kanye", @"merch", @"pablo", @"west", @"dons", @"oreo"]];
    }
    else if ([self.shop isEqualToString:@"sup"]){
        [self.infiniteQuery whereKey:@"keywords" containedIn:@[@"supreme", @"sup", @"bogo", @"box logo", @"preme"]];
    }
    else if ([self.shop isEqualToString:@"palace"]){
        [self.infiniteQuery whereKey:@"keywords" containedIn:@[@"palace", @"palidas", @"triferg", @"tri-ferg", @"tri", @"ferg"]];
    }
    self.infiniteQuery.limit = 30;
    self.infiniteQuery.skip = self.skipped;
    [self.infiniteQuery orderByDescending:@"lastUpdated"];
    [self.infiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            if (objects.count == 0) {
                [self.collectionView.infiniteScrollingView stopAnimating];
                self.infinFinished = YES;
                return;
            }
            
            self.skipped = self.skipped + (int)objects.count;
            
            self.infinFinished = YES;
            [self.collectionView.infiniteScrollingView stopAnimating];
            
            NSMutableArray *holding = [NSMutableArray arrayWithArray:objects];
            [self shuffle:holding];
           
            [self.listings addObjectsFromArray:holding];
            [self.collectionView reloadData];
        }
    }];
}

- (void)shuffle:(NSMutableArray *)array
{
    NSUInteger count = [array count];
    if (count <= 1) return;
    for (NSUInteger i = 0; i < count - 1; ++i) {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t )remainingCount);
        [array exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
}

@end
