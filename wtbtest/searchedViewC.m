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
#import "detailSellingCell.h"

@interface searchedViewC ()

@end

@implementation searchedViewC

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.noWantedResultsLabel setHidden:YES];

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
    self.navigationItem.rightBarButtonItem = cancelButton;

//    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"<" style:UIBarButtonItemStylePlain target:self action:@selector(popViewControllerAnimated:)];
//    self.navigationItem.leftBarButtonItem = cancelButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollTop) name:@"scrollSearchTop" object:nil];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];

    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.delegate = self;
    [self.searchBar sizeToFit];
    self.searchBar.text = self.searchString;
//    self.searchBar.showsCancelButton = YES;
    
    if (@available(iOS 11.0, *)) {
        //nav bar height will be 56 (coz of bigger search bars)
        //move the whole collection view down because of the header
        
        UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 200, 44)];
        [self.searchBar setFrame:CGRectMake(0, 0, 200, 44)];
        [container addSubview:self.searchBar];
        self.navigationItem.titleView = container;
    }
    else{
        //nav bar height will be standard 44
        self.navigationItem.titleView = self.searchBar;
    }
    
//    //force cancel button to be enabled
//    UIButton *btnCancel = [self.searchBar valueForKey:@"_cancelButton"];
//    [btnCancel setEnabled:YES];
    
    //prompt to dismiss keyboard
    [self addDoneButton];
    
    //collection view/cell setup
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];

    if (self.sellingSearch) {
        //selling search ON
        
        [self.collectionView registerClass:[detailSellingCell class] forCellWithReuseIdentifier:@"Cell"];
        UINib *cellNib = [UINib nibWithNibName:@"detailSellingCell" bundle:nil];
        [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
        
        if ([ [ UIScreen mainScreen ] bounds ].size.width == 375) {
            //iPhone6/7
            [flowLayout setItemSize:CGSizeMake(175,222)];
        }
        else if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
            //iPhone 6 plus
            [flowLayout setItemSize:CGSizeMake(195, 247)];
        }
        else if([ [ UIScreen mainScreen ] bounds ].size.width == 320){
            //iPhone SE
            [flowLayout setItemSize:CGSizeMake(148, 188)];
        }
        else{
            //fall back
            [flowLayout setItemSize:CGSizeMake(175,222)];
        }
        
        [flowLayout setMinimumInteritemSpacing:8.0];
        
        if (self.sellingSearch) {
            flowLayout.footerReferenceSize = CGSizeMake([UIApplication sharedApplication].keyWindow.frame.size.width, 152);
            flowLayout.sectionFootersPinToVisibleBounds = NO;
            [self.collectionView registerNib:[UINib nibWithNibName:@"CreateWTBPromptFooter" bundle:nil]
                  forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                         withReuseIdentifier:@"Footer"];
        }

    }
    else{
        //wanted search
        [self.collectionView registerClass:[ExploreCell class] forCellWithReuseIdentifier:@"Cell"];
        
        UINib *cellNib = [UINib nibWithNibName:@"ExploreCell" bundle:nil];
        [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
        
//        [self.collectionView registerNib:[UINib nibWithNibName:@"searchBoostedHeader" bundle:nil]
//              forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
//                     withReuseIdentifier:@"search"];
        
        
        if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
            //iphone5
            [flowLayout setItemSize:CGSizeMake(148, 215)];
            self.headerSize = 280;
        }
        else if([ [ UIScreen mainScreen ] bounds ].size.height == 736){
            //iphone 6 plus
            [flowLayout setItemSize:CGSizeMake(196, 285)];
            self.headerSize = 350;
        }
        else if([ [ UIScreen mainScreen ] bounds ].size.height == 480){
            //iphone 4
            [flowLayout setItemSize:CGSizeMake(124, 180)];
        }
        else{
            [flowLayout setItemSize:CGSizeMake(175, 254)]; //iPhone 6 specific
            self.headerSize = 330;
        }
        
        [flowLayout setMinimumInteritemSpacing:0];
        
        //setup header
        [self.collectionView registerNib:[UINib nibWithNibName:@"simpleBannerHeader" bundle:nil]
              forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                     withReuseIdentifier:@"Header"];
        
        flowLayout.headerReferenceSize = CGSizeMake([UIApplication sharedApplication].keyWindow.frame.size.width, 40);
        flowLayout.sectionHeadersPinToVisibleBounds = NO;
    }

    [flowLayout setMinimumLineSpacing:8.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    self.results = [NSMutableArray array];
    
    [self.collectionView setScrollsToTop:YES];
    self.filtersArray = [NSMutableArray array];
    self.filterSizesArray = [NSMutableArray array];
    self.filterBrandsArray = [NSMutableArray array];
    self.filterColoursArray = [NSMutableArray array];
    self.filterContinentsArray = [NSMutableArray array];
    self.filterCategory = @"";

    self.uselessWords = [NSArray arrayWithObjects:@"x",@"to",@"with",@"and",@"the",@"wtb",@"or",@" ",@".",@"very",@"interested", @"in",@"wanted", @"",@",", nil];

    //refresh setup
    self.pullFinished = YES;
    self.infinFinished = YES;
    self.lastInfinSkipped = 0;
    self.viewedListing = NO;
}

#pragma mark - custom header

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    self.bannerHeaderView = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        self.bannerHeaderView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
        
        [self.bannerHeaderView.simpleHeaderLabel setTextAlignment:NSTextAlignmentCenter];
        [self.bannerHeaderView.simpleHeaderLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:12]];

        if (self.sellingSearch) {
            [self.bannerHeaderView setBackgroundColor:[UIColor redColor]];
            self.bannerHeaderView.simpleHeaderLabel.text = @"For sale results";
        }
        else{
            [self.bannerHeaderView setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
            [self.bannerHeaderView.simpleHeaderLabel setTextColor:[UIColor whiteColor]];
            self.bannerHeaderView.simpleHeaderLabel.text = @"Wanted item results";
        }
        return self.bannerHeaderView;
    }
    else if (kind == UICollectionElementKindSectionFooter){
        self.promptFooterView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer" forIndexPath:indexPath];
        if (self.results.count > 0) {
            self.promptFooterView.footerLabel.text = @"Can't find what you're looking for?\n\nCreate a wanted listing on BUMP so sellers can find you and send you a message!";
        }
        else{
            self.promptFooterView.footerLabel.text = @"No results\n\nCreate a wanted listing on BUMP so sellers can find you and send you a message!";
        }
        
        [self.promptFooterView.footerButton addTarget:self action:@selector(createWantedListingPressed) forControlEvents:UIControlEventTouchUpInside];
        
        return self.promptFooterView;
        
    }
    //this can't be nil remember
    return self.bannerHeaderView;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section{
    if (self.sellingSearch) {
        if (self.showFooter) {
            self.initialHeaderSizeSetup = YES;
            return CGSizeMake(CGRectGetWidth(collectionView.bounds),152);
        }
        else{
            return CGSizeZero;
        }
    }
    return CGSizeZero;
}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
//{
////    if (self.showBoostHeader == YES|| self.initialHeaderSizeSetup != YES) {
////        self.initialHeaderSizeSetup = YES;
////        return CGSizeMake(CGRectGetWidth(collectionView.bounds), self.headerSize);
////    }
////    else{
////        return CGSizeZero;
////    }
//    
//
//}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    UITextField *txfSearchField = [self.searchBar valueForKey:@"searchField"];
    
    if (@available(iOS 11.0, *)) {
        [txfSearchField setAttributedText:[[NSAttributedString alloc] initWithString:self.searchString attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFangSC-Regular" size:14]}]];
    }
    if (self.viewedListing != YES) {
        [self queryParsePull];
//        [self getBoostedSearchListings];
    }
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    //put refresh code here so it remembers correct UICollectionView insets - doesn't work in VDL
//    [self.collectionView addPullToRefreshWithActionHandler:^{
//        if (self.pullFinished == YES) {
//            [self queryParsePull];
////            [self getBoostedSearchListings];
//        }
//    }];
    
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
    
    //reset the query to remove old constraints
    self.pullQuery = nil;
    
    if (self.sellingSearch) {
        self.pullQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    }
    else{
        self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
        [self.pullQuery orderByDescending:@"lastUpdated,bumpCount"];
    }
    
    self.pullFinished = NO;
    self.showFooter = NO;

    self.pullQuery.limit = 20;
    [self setupPullQuery];
    __block NSMutableArray *wordsToSearch = [NSMutableArray array];
    
    NSArray *searchWords = [[self.searchString lowercaseString] componentsSeparatedByString:@" "];
    [wordsToSearch addObjectsFromArray:searchWords];
    
    //remove useless words
    [wordsToSearch removeObjectsInArray:self.uselessWords];
    
    if (self.sellingSearch) {
        [self.pullQuery whereKey:@"keywords" containsAllObjectsInArray:wordsToSearch];
    }
    else{
        [self.pullQuery whereKey:@"searchKeywords" containsAllObjectsInArray:wordsToSearch];
    }
    
    //brand filter
    if (self.filterBrandsArray.count > 0) {
        [self.pullQuery whereKey:@"keywords" containedIn:self.filterBrandsArray];
    }
    
    [self.pullQuery whereKey:@"status" equalTo:@"live"];
    
    [self.pullQuery cancel];
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            int count = (int)[objects count];
            NSLog(@"search results %d", count);
            
            if (!self.sellingSearch && count == 0) {
                [self.noWantedResultsLabel setHidden:NO];
            }
            else{
                [self.noWantedResultsLabel setHidden:YES];
            }
            
            if (count < 20) {
                self.showFooter = YES;
            }
            else{
                self.showFooter = NO;
            }
            
            self.lastInfinSkipped = count;
            
            [self.results removeAllObjects];
            [self.results addObjectsFromArray:objects];
            
            [self.collectionView reloadData];

//            [self.collectionView setContentOffset:CGPointMake(0, 0)];
            
//            [self.collectionView.pullToRefreshView stopAnimating]; //CHECK this is causing CV to scroll past the top upon reload

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
    if (self.pullFinished == NO || self.infinFinished == NO) {
        return;
    }
    
    if (self.results.count < 20) {
        //no point loading
        [self.collectionView.infiniteScrollingView stopAnimating];
        return;
    }
    
    [self hideFilterButton];
    
    self.infinFinished = NO;
    self.showFooter = NO;

    NSLog(@"infinity in search");
    self.infiniteQuery = nil;
    
    if (self.sellingSearch) {
        self.infiniteQuery = [PFQuery queryWithClassName:@"forSaleItems"];
        [self.infiniteQuery orderByDescending:@"lastUpdated"];
    }
    else{
        self.infiniteQuery = [PFQuery queryWithClassName:@"wantobuys"];
        [self.infiniteQuery orderByDescending:@"lastUpdated,bumpCount"];
    }
    
    self.infiniteQuery.limit = 20;
    self.infiniteQuery.skip = self.lastInfinSkipped;

    [self.infiniteQuery whereKey:@"status" equalTo:@"live"]; //SET set all banned users' listings to a status of banned

    [self setupInfinQuery];
    __block NSMutableArray *wordsToSearch = [NSMutableArray array];
    
    NSArray *searchWords = [[self.searchString lowercaseString] componentsSeparatedByString:@" "];
    [wordsToSearch addObjectsFromArray:searchWords];
    
    //remove useless words
    [wordsToSearch removeObjectsInArray:self.uselessWords];
    
    if (self.sellingSearch) {
        [self.infiniteQuery whereKey:@"keywords" containsAllObjectsInArray:wordsToSearch];
    }
    else{
        [self.infiniteQuery whereKey:@"searchKeywords" containsAllObjectsInArray:wordsToSearch];
    }
    
    //brand filter
    if (self.filterBrandsArray.count > 0) {
        [self.infiniteQuery whereKey:@"keywords" containedIn:self.filterBrandsArray];
    }
    
    [self.infiniteQuery cancel];
    [self.infiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            NSLog(@"search infin count %d", count);
            
            if (count < 20) {
                self.showFooter = YES;
            }
            else{
                self.showFooter = NO;
            }
            
            self.lastInfinSkipped = self.lastInfinSkipped + count;
            [self.results addObjectsFromArray:objects];
            [self.collectionView reloadData];
            [self.collectionView.infiniteScrollingView stopAnimating];
            self.infinFinished = YES;
            
            [self showFilterButton];
        }
        else{
            NSLog(@"error %@", error);
            self.infinFinished = YES;
            [self showError];
            
            [self showFilterButton];
        }
    }];
}

-(void)cancelPressed{
    [self.searchBar resignFirstResponder];
    [self.delegate cancellingOtherSearch];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self cancelPressed];
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
//    if (@available(iOS 11.0, *)) {
//        //nav bar height will be 56 (coz of bigger search bars)
//        return UIEdgeInsetsMake(20, 8, 8, 8); // top, left, bottom, right
//    }
//    else{
//        //nav bar height will be standard 44
//    }

    return UIEdgeInsetsMake(8, 8, 8, 8); // top, left, bottom, right

}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.sellingSearch) {
        //for sale items search
        detailSellingCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
        cell.itemImageView.image = nil;
        [cell.itemImageView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
        
        PFObject *forSaleItem = [self.results objectAtIndex:indexPath.row];
        
        //set image
        [cell.itemImageView setFile:[forSaleItem objectForKey:@"thumbnail"]];
        [cell.itemImageView loadInBackground];
        
        //set title
        if ([forSaleItem objectForKey:@"itemTitle"]) {
            cell.itemTitleLabel.text = [forSaleItem objectForKey:@"itemTitle"];
        }
        else{
            cell.itemTitleLabel.text = [forSaleItem objectForKey:@"description"];
        }
        
        //set price label if exists
        float price = [[forSaleItem objectForKey:[NSString stringWithFormat:@"salePrice%@", self.currency]]floatValue];
        
        if (price != 0.00 && price > 0.99) {
            cell.itemPriceLabel.text = [NSString stringWithFormat:@"%@%.0f",self.currencySymbol ,price];
        }
        else{
            cell.itemPriceLabel.text = @"";
        }
        
        NSString *condition = @"";
        
        //check if has condition
        if ([forSaleItem objectForKey:@"condition"]) {
            NSString *conditionString = [forSaleItem objectForKey:@"condition"];
            if ([conditionString isEqualToString:@"BNWT"] || [conditionString isEqualToString:@"BNWOT"] || [conditionString isEqualToString:@"Deadstock"]) {
                condition = @"New";
            }
            else if([conditionString isEqualToString:@"Other"]){
                condition = @"Used";
            }
            else{
                condition = conditionString;
            }
        }
        
        //check if has size
        NSString *size = @"";
        
        if (![[forSaleItem objectForKey:@"category"]isEqualToString:@"Accessories"]) {
            NSString *sizeLabel = [forSaleItem objectForKey:@"sizeLabel"];
            
            if ([sizeLabel isEqualToString:@"Multiple"]) {
                size = sizeLabel;
            }
            else if ([sizeLabel isEqualToString:@"UK XXL"]){
                size = @"XXLarge";
            }
            else if ([sizeLabel isEqualToString:@"UK XL"]){
                size = @"XLarge";
            }
            else if ([sizeLabel isEqualToString:@"UK L"]){
                size = @"Large";
            }
            else if ([sizeLabel isEqualToString:@"UK M"]){
                size = @"Medium";
            }
            else if ([sizeLabel isEqualToString:@"UK S"]){
                size = @"Small";
            }
            else if ([sizeLabel isEqualToString:@"UK XS"]){
                size = @"XSmall";
            }
            else if ([sizeLabel isEqualToString:@"UK XXS"]){
                size = @"XXSmall";
            }
            else if ([sizeLabel isEqualToString:@"XXL"]){
                size = @"XXLarge";
            }
            else if ([sizeLabel isEqualToString:@"XL"]){
                size = @"XLarge";
            }
            else if ([sizeLabel isEqualToString:@"L"]){
                size = @"Large";
            }
            else if ([sizeLabel isEqualToString:@"M"]){
                size = @"Medium";
            }
            else if ([sizeLabel isEqualToString:@"S"]){
                size = @"Small";
            }
            else if ([sizeLabel isEqualToString:@"XS"]){
                size = @"XSmall";
            }
            else if ([sizeLabel isEqualToString:@"XXS"]){
                size = @"XXSmall";
            }
            else if ([sizeLabel isEqualToString:@"XXL"]){
                size = @"XXLarge";
            }
            else if ([sizeLabel isEqualToString:@"XL"]){
                size = @"XLarge";
            }
            else if ([sizeLabel isEqualToString:@"L"]){
                size = @"Large";
            }
            else if ([sizeLabel isEqualToString:@"M"]){
                size = @"Medium";
            }
            else if ([sizeLabel isEqualToString:@"S"]){
                size = @"Small";
            }
            else if ([sizeLabel isEqualToString:@"XS"]){
                size = @"XSmall";
            }
            else if ([sizeLabel isEqualToString:@"XXS"]){
                size = @"XXSmall";
            }
            else{
                size = sizeLabel;
            }
        }
        
        //set info label
        if (![condition isEqualToString:@""] && ![size isEqualToString:@""]) {
            cell.itemInfoLabel.text = [NSString stringWithFormat:@"%@ | %@", condition, size];
        }
        else if([condition isEqualToString:@""] && ![size isEqualToString:@""]){
            cell.itemInfoLabel.text = size;
        }
        else if(![condition isEqualToString:@""] && [size isEqualToString:@""]){
            cell.itemInfoLabel.text = condition;
        }
        else{
            cell.itemInfoLabel.text = @"";
        }
        return cell;
    }
    else{
        //wanted items search
        self.cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
        self.cell.delegate = self;
        
        self.cell.layer.cornerRadius = 4;
        self.cell.layer.masksToBounds = YES;
        
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
        
        if ([listing objectForKey:@"thumbnail"]) {
            [self.cell.imageView setFile:[listing objectForKey:@"thumbnail"]];
        }
        else{
            [self.cell.imageView setFile:[listing objectForKey:@"image1"]];
        }
        
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
//        
//        BOOL highlightBoost = NO;
//        BOOL searchBoost = NO;
//        BOOL featureBoost = NO;
//        
//        //check what boosts are enabled then display the correct summary boost icon
//        if ([listing objectForKey:@"highlighted"]) {
//            
//            NSDate *expiryDate = [listing objectForKey:@"highlightExpiry"];
//            
//            if ([[listing objectForKey:@"highlighted"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedDescending) {
//                
//                highlightBoost = YES;
//                
//            }
//            else if ([[listing objectForKey:@"highlighted"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedAscending) {
//                [listing removeObjectForKey:@"highlighted"];
//                [listing saveInBackground];
//            }
//            
//        }
//        
//        if ([listing objectForKey:@"searchBoost"]) {
//            
//            NSDate *expiryDate = [listing objectForKey:@"searchBoostExpiry"];
//            
//            if ([[listing objectForKey:@"searchBoost"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedDescending) {
//                
//                searchBoost = YES;
//                
//            }
//            else if ([[listing objectForKey:@"searchBoost"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedAscending) {
//                [listing removeObjectForKey:@"searchBoost"];
//                [listing saveInBackground];
//            }
//        }
//        
//        if ([listing objectForKey:@"featuredBoost"]) {
//            
//            NSDate *expiryDate = [listing objectForKey:@"featuredBoostExpiry"];
//            
//            if ([[listing objectForKey:@"featuredBoost"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedDescending) {
//                
//                featureBoost = YES;
//                
//                [[PFUser currentUser]addObject:listing.objectId forKey:@"seenFeatured"];
//                [[PFUser currentUser]saveEventually];
//            }
//            else if ([[listing objectForKey:@"featuredBoost"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedAscending) {
//                [listing removeObjectForKey:@"featuredBoost"];
//                [listing saveInBackground];
//            }
//        }
//        
//        // check which boost to display
//        if (highlightBoost == YES && featureBoost != YES) {
//            [self.cell.boostImageView setImage:[UIImage imageNamed:@"blueBoost"]];
//            [self.cell.boostImageView setHidden:NO];
//            
//            [self.cell.layer setBorderColor: [[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0] CGColor]];
//            [self.cell.layer setBorderWidth: 2.0];
//            
//            [self.cell.distanceLabel setHidden:YES];
//        }
//        else if (featureBoost == YES) {
//            [self.cell.boostImageView setImage:[UIImage imageNamed:@"purpleBoost"]];
//            [self.cell.boostImageView setHidden:NO];
//            
//            [self.cell.layer setBorderWidth: 0.0];
//            [self.cell.distanceLabel setHidden:YES];
//        }
//        else{
//            [self.cell.layer setBorderWidth: 0.0];
//            [self.cell.distanceLabel setHidden:NO];
//            [self.cell.boostImageView setHidden:YES];
//        }
        
        self.cell.backgroundColor = [UIColor whiteColor];
        
        return self.cell;
    }
}


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.results.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    self.viewedListing = YES;
    
    if (self.sellingSearch) {
        //for sale item search
        
        [Answers logCustomEventWithName:@"Tapped search item"
                       customAttributes:@{
                                          @"type":@"for sale"
                                          }];
        
        PFObject *itemObject = [self.results objectAtIndex:indexPath.row];
        
        ForSaleListing *vc = [[ForSaleListing alloc]init];
        vc.listingObject = itemObject;
        vc.source = @"search";
        vc.fromBuyNow = YES;
        vc.pureWTS = YES;

        //switch off hiding nav bar
        self.navigationController.navigationBarHidden = NO;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else{
        [Answers logCustomEventWithName:@"Tapped search item"
                       customAttributes:@{
                                          @"type":@"wanted"
                                          }];
        
        //wanted item search
        if (!self.lastSelected) {
            self.lastSelected = [[NSIndexPath alloc]init];
        }
        self.lastSelected = indexPath;
        PFObject *listing;
        
        listing = [self.results objectAtIndex:indexPath.item];
        
        ListingController *vc = [[ListingController alloc]init];
        vc.listingObject = listing;
        vc.fromSearch = YES;
        vc.tabBarHeight = self.tabBarHeight;
        [self.navigationController pushViewController:vc animated:YES];
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

-(void)setupPullQuery{
    if (self.filtersArray.count > 0) {
        
        //setup location
        if (self.filterContinentsArray.count > 0) {
            if ([self.filterContinentsArray containsObject:@"Around me"]) {
                
                if (self.currentLocation) {
                    [self.pullQuery whereKey:@"geopoint" nearGeoPoint:self.currentLocation withinKilometers:100];
                }
                else{
                    //prompt to turn location on?
                    [Answers logCustomEventWithName:@"Around me searched without location"
                                   customAttributes:@{}];
                }
            }
            else{
                //got a continent to filter
                [self.pullQuery whereKey:@"continent" containedIn:self.filterContinentsArray];
            }
        }
        else{
            //don't do anything as it's global
        }
        
        //price
        if ([self.filtersArray containsObject:@"price"]) {
            [self.pullQuery whereKey:[NSString stringWithFormat:@"salePrice%@", self.currency] greaterThanOrEqualTo:@(self.filterLower)];
            [self.pullQuery whereKey:[NSString stringWithFormat:@"salePrice%@", self.currency] lessThanOrEqualTo:@(self.filterUpper)];
        }
        
        if ([self.filtersArray containsObject:@"hightolow"]) {
            [self.pullQuery whereKey:[NSString stringWithFormat:@"salePrice%@", self.currency] greaterThan:@(0.00)];
            [self.pullQuery orderByDescending:[NSString stringWithFormat:@"salePrice%@", self.currency]];
        }
        else if ([self.filtersArray containsObject:@"lowtohigh"]){
            [self.pullQuery whereKey:[NSString stringWithFormat:@"salePrice%@", self.currency] greaterThan:@(0.00)];
            [self.pullQuery orderByAscending:[NSString stringWithFormat:@"salePrice%@", self.currency]];
        }
        else{
            [self.pullQuery orderByDescending:@"lastUpdated"];
        }
        
        //condition
        if ([self.filtersArray containsObject:@"new"]){
            [self.pullQuery whereKey:@"condition" containedIn:@[@"New", @"Any", @"BNWT", @"BNWOT",@"Deadstock"]];  //updated as we removed Deastock as an option
        }
        else if ([self.filtersArray containsObject:@"used"]){
            [self.pullQuery whereKey:@"condition" containedIn:@[@"Used", @"Any"]];
        }
        else if ([self.filtersArray containsObject:@"deadstock"]){
            [self.pullQuery whereKey:@"condition" containedIn:@[@"Deadstock", @"Any"]];
        }
        
        //category filters
        if (![self.filterCategory isEqualToString:@""]) {
            [self.pullQuery whereKey:@"category" equalTo:self.filterCategory];
        }
        
        //gender
        if ([self.filtersArray containsObject:@"male"]){
            [self.pullQuery whereKey:@"sizeGender" equalTo:@"Mens"];
        }
        else if ([self.filtersArray containsObject:@"female"]){
            [self.pullQuery whereKey:@"sizeGender" equalTo:@"Womens"];
        }
        
        //all sizes filters
        if (self.filterSizesArray.count > 0) {
            [self.pullQuery whereKey:@"sizeArray" containedIn:self.filterSizesArray];
        }
        
        //colour filters
        if (self.filterColoursArray.count > 0) {
            [self.pullQuery whereKey:@"coloursArray" containedIn:self.filterColoursArray]; //was mainColour
        }

    }
    else{
        [self.pullQuery orderByDescending:@"lastUpdated"];
    }
}

-(void)callSizeQuery{
    self.sizeQuery = nil;
    self.sizeQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [self.sizeQuery whereKey:@"sizeArray" containedIn:self.filterSizesArray];
}

-(void)setupInfinQuery{
    if (self.filtersArray.count > 0) {
        
        //setup location
        if (self.filterContinentsArray.count > 0) {
            if ([self.filterContinentsArray containsObject:@"Around me"]) {
                
                if (self.currentLocation) {
                    [self.infiniteQuery whereKey:@"geopoint" nearGeoPoint:self.currentLocation withinKilometers:100];
                }
                else{
                    //prompt to turn location on?
                    [Answers logCustomEventWithName:@"Around me searched without location"
                                   customAttributes:@{}];
                }
            }
            else{
                //got a continent to filter
                [self.infiniteQuery whereKey:@"continent" containedIn:self.filterContinentsArray];
            }
            
        }
        else{
            //don't do anything as it's global
        }
        
        //price
        if ([self.filtersArray containsObject:@"price"]) {
            [self.infiniteQuery whereKey:[NSString stringWithFormat:@"salePrice%@", self.currency] greaterThanOrEqualTo:@(self.filterLower)];
            [self.infiniteQuery whereKey:[NSString stringWithFormat:@"salePrice%@", self.currency] lessThanOrEqualTo:@(self.filterUpper)];
        }
        
        if ([self.filtersArray containsObject:@"hightolow"]) {
            [self.infiniteQuery whereKey:[NSString stringWithFormat:@"salePrice%@", self.currency] greaterThan:@(0.00)];
            [self.infiniteQuery orderByDescending:[NSString stringWithFormat:@"salePrice%@", self.currency]];
        }
        else if ([self.filtersArray containsObject:@"lowtohigh"]){
            [self.infiniteQuery whereKey:[NSString stringWithFormat:@"salePrice%@", self.currency] greaterThan:@(0.00)];
            [self.infiniteQuery orderByAscending:[NSString stringWithFormat:@"salePrice%@", self.currency]];
        }
        
        //location
        if ([self.filtersArray containsObject:@"aroundMe"] && self.currentLocation) {
            [self.infiniteQuery whereKey:@"geopoint" nearGeoPoint:self.currentLocation withinKilometers:400];
        }
        
        //condition
        if ([self.filtersArray containsObject:@"new"]){
            [self.infiniteQuery whereKey:@"condition" containedIn:@[@"New", @"Any", @"BNWT", @"BNWOT", @"Deadstock"]];
        }
        else if ([self.filtersArray containsObject:@"used"]){
            [self.infiniteQuery whereKey:@"condition" containedIn:@[@"Used", @"Any"]];
        }
        else if ([self.filtersArray containsObject:@"deadstock"]){
            [self.infiniteQuery whereKey:@"condition" containedIn:@[@"Deadstock", @"Any"]];
        }
        
        //category filters
        if (![self.filterCategory isEqualToString:@""]) {
            [self.infiniteQuery whereKey:@"category" equalTo:self.filterCategory];
        }
        
        //gender
        if ([self.filtersArray containsObject:@"male"]){
            [self.infiniteQuery whereKey:@"sizeGender" equalTo:@"Mens"];
        }
        else if ([self.filtersArray containsObject:@"female"]){
            [self.infiniteQuery whereKey:@"sizeGender" equalTo:@"Womens"];
        }
        
        //all sizes filters
        if (self.filterSizesArray.count > 0) {
            [self.infiniteQuery whereKey:@"sizeArray" containedIn:self.filterSizesArray];
        }
        
        //colour filters
        if (self.filterColoursArray.count > 0) {
            [self.infiniteQuery whereKey:@"coloursArray" containedIn:self.filterColoursArray];
        }
        
    }
    else{
        [self.infiniteQuery orderByDescending:@"lastUpdated"];
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    if (self.sellingSearch) {
        [Answers logCustomEventWithName:@"Search"
                       customAttributes:@{
                                          @"type":@"For Sale search"
                                          }];
    }
    else{
        [Answers logCustomEventWithName:@"Search"
                       customAttributes:@{
                                          @"type":@"Wanted search"
                                          }];
    }
    
    [self.searchBar resignFirstResponder];
    self.searchString = searchBar.text;
    NSString *stringCheck = [self.searchString stringByReplacingOccurrencesOfString:@" " withString:@""];
    [self.delegate enteredSearchTerm:self.searchString inSellingSearch:self.sellingSearch];
    
//    //force cancel button to be enabled
//    UIButton *btnCancel = [self.searchBar valueForKey:@"_cancelButton"];
//    [btnCancel setEnabled:YES];

    if (![stringCheck isEqualToString:@""]) {
        [self.results removeAllObjects];
        [self.collectionView reloadData];
        self.searchString = self.searchBar.text;
        [self queryParsePull];
//        [self getBoostedSearchListings];
    }
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    [self.searchBar resignFirstResponder];
    
    NSString *stringCheck = [searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (![stringCheck isEqualToString:@""]) {
        self.searchString = searchBar.text;
        [self.delegate enteredSearchTerm:self.searchString inSellingSearch:self.sellingSearch];
    }
    
//    //force cancel button to be enabled
//    UIButton *btnCancel = [self.searchBar valueForKey:@"_cancelButton"];
//    [btnCancel setEnabled:YES];
}

- (IBAction)filterPressed:(id)sender {
    [Answers logCustomEventWithName:@"Filters pressed"
                   customAttributes:@{
                                      @"page":@"Search"
                                      }];
    FilterVC *vc = [[FilterVC alloc]init];
    vc.delegate = self;
    vc.currencySymbol = self.currencySymbol;
    vc.sellingSearch = self.sellingSearch;
    if (self.filtersArray.count > 0) {
        
        vc.sendArray = [NSMutableArray arrayWithArray:self.filtersArray];
        
        vc.filterLower = self.filterLower;
        vc.filterUpper = self.filterUpper;
    }
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)filtersReturned:(NSMutableArray *)filters withSizesArray:(NSMutableArray *)sizes andBrandsArray:(NSMutableArray *)brands andColours:(NSMutableArray *)colours andCategories:(NSString *)category andPricLower:(float)lower andPriceUpper:(float)upper andContinents:(NSMutableArray *)continents{
    [self.results removeAllObjects];
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
        
        //update filter button title and colour
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
    self.lastInfinSkipped = 0;
    
    if (self.results.count != 0) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:NO];
    }
    [self queryParsePull];
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
        [self.filterContinentsArray removeAllObjects];

        self.filterCategory = @"";
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

#pragma mark - search boost header methods / delegates

-(void)getBoostedSearchListings{
    //reset the query to remove the home screen constraints
    PFQuery *boostQuery = [PFQuery queryWithClassName:@"wantobuys"];
    boostQuery.limit = 20;
    __block NSMutableArray *wordsToSearch = [NSMutableArray array];
    
    NSArray *searchWords = [[self.searchString lowercaseString] componentsSeparatedByString:@" "];
    [wordsToSearch addObjectsFromArray:searchWords];
    
    //remove useless words
    [wordsToSearch removeObjectsInArray:self.uselessWords];
    [boostQuery whereKey:@"searchKeywords" containsAllObjectsInArray:wordsToSearch];
    [boostQuery whereKey:@"status" equalTo:@"live"];
    [boostQuery whereKey:@"searchBoost" equalTo:@"YES"];
//    [boostQuery whereKey:@"searchBoostExpiry" greaterThanOrEqualTo:[NSDate date]];
    [boostQuery orderByAscending:@"boostViews,searchBoostExpiry"];
    [boostQuery cancel];
    [boostQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
//            NSLog(@"count of objects %@", objects);
            
//            self.headerView.boostedListings = objects;
//            [self.headerView.seenBoosts removeAllObjects];
//            [self.headerView.swipeView reloadData];

            
            if (objects.count > 0) {
                self.showBoostHeader = YES;
                
                [Answers logCustomEventWithName:@"search boost items returned"
                               customAttributes:@{
                                                  @"count":[NSString stringWithFormat:@"%lu",objects.count]
                                                  }];
            }
            else{
                self.showBoostHeader = NO;
            }
            [self.collectionView reloadData];
        }
        else{
            NSLog(@"error on boosted %@", error);
            [self showError];
        }
    }];
    
}

-(void)selectedBoostListing:(PFObject *)listing{
    
}

- (void)createWantedListingPressed{
    [self cancelPressed];
    //send notification to createTab to open WTB creater
    [self.presentingViewController.tabBarController setSelectedIndex:1];
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"openWTB" object:nil];
    });
}

-(void)hideFilterButton{
    [self.filterButton setHidden:YES];
}

-(void)showFilterButton{
    [self.filterButton setHidden:NO];
}

- (void)addDoneButton {
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
    [keyboardToolbar sizeToFit];
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(dismissKeyboard)];
    
    [doneBarButton setTintColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1]];
    keyboardToolbar.barTintColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];
    
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    
    self.searchBar.inputAccessoryView = keyboardToolbar;
}

-(void)dismissKeyboard{
    [self.searchBar resignFirstResponder];
    
//    //force cancel button to be enabled
//    UIButton *btnCancel = [self.searchBar valueForKey:@"_cancelButton"];
//    [btnCancel setEnabled:YES];
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

-(void)scrollTop{
    if (self.results.count != 0) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
    }
}
@end
