//
//  PurchaseTab.m
//  wtbtest
//
//  Created by Jack Ryder on 20/02/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "PurchaseTab.h"
#import "ProfileItemCell.h"
#import "ForSaleListing.h"
#import "NavigationController.h"
#import <SVPullToRefresh/SVPullToRefresh.h>
#import "PurchaseTabHeader.h"
#import "droppingTodayView.h"
#import "droppingCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <Crashlytics/Crashlytics.h>
#import "FeaturedItems.h"
#import "ChatWithBump.h"
#import "CreateForSaleListing.h"
#import "XMLReader.h"

@interface PurchaseTab ()

@end

@implementation PurchaseTab 

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"B U Y  N O W";
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    UIBarButtonItem *sellingButton = [[UIBarButtonItem alloc] initWithTitle:@"Sell" style:UIBarButtonItemStylePlain target:self action:@selector(sellPressed)];
    
    //collection view setup
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
    flowLayout.headerReferenceSize = CGSizeMake([UIApplication sharedApplication].keyWindow.frame.size.width, 125);
    flowLayout.sectionHeadersPinToVisibleBounds = NO;
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.dataSource = self;
    self.collectionView.alwaysBounceVertical = YES;
    
    //setup header
    [self.collectionView registerClass:[PurchaseTabHeader class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                   withReuseIdentifier:@"Header"];
    
    self.products = [NSMutableArray array];
    self.addedIDs = [NSMutableArray array];
    self.WTBMatches = [NSMutableArray array];
    self.featured = [NSMutableArray array];
    self.infinMatches = [NSMutableArray array];
    self.scheduledArray = [NSMutableArray array];
    self.listingIndexesArray = [NSMutableArray array];
    self.addedIndexes = [NSMutableArray array];
    self.affiliatesSeen = [NSMutableArray array];
    
    self.pullFinished = YES;
    self.featuredFinished = YES;
    self.infinFinished = YES;
    
    self.showAffiliates = YES; //CHANGE
    self.retrieveLimit = 28;
    //28 for YES and 30 for NO ^
    
    [self.anotherPromptButton setHidden:YES];

    [self getAffiliateData];
    [self loadWTBsAndMatches];

    //day of the week formatter
    self.dayOfWeekFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *inputTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [self.dayOfWeekFormatter setTimeZone:inputTimeZone];
    [self.dayOfWeekFormatter setDateFormat:@"EEE"];
    
    self.yeezySeenArray = [NSMutableArray array];
    self.supSeenArray = [NSMutableArray array];
    self.palaceSeenArray = [NSMutableArray array];
    
    self.selectedShop = @"sup";

    if ([[PFUser currentUser]objectForKey:@"yeezySeenArray"]) {
        self.yeezySeenArray = [[PFUser currentUser]objectForKey:@"yeezySeenArray"];
    }
    if ([[PFUser currentUser]objectForKey:@"supSeenArray"]) {
        self.supSeenArray = [[PFUser currentUser]objectForKey:@"supSeenArray"];
    }
    if ([[PFUser currentUser]objectForKey:@"palaceSeenArray"]) {
        self.palaceSeenArray = [[PFUser currentUser]objectForKey:@"palaceSeenArray"];
    }
    
    self.spinnerHUD = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    PFQuery *trustedQuery = [PFQuery queryWithClassName:@"trustedSellers"];
    [trustedQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    [trustedQuery countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
        if (number >= 1) {
            self.isSeller = YES;
        }
        else{
            self.isSeller = NO;
            [self.navigationItem setLeftBarButtonItem:sellingButton];
        }
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    //put refresh code here so it remembers correct UICollectionView insets - doesn't work in VDL
    [self.collectionView addPullToRefreshWithActionHandler:^{
        if (self.pullFinished == YES) {
            [self loadWTBsAndMatches];
        }
    }];
    
    self.spinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
    [self.collectionView.pullToRefreshView setCustomView:self.spinner forState:SVPullToRefreshStateAll];
    [self.spinner startAnimating];
    
    [self.collectionView addInfiniteScrollingWithActionHandler:^{
        if (self.infinFinished == YES) {
            //infinity query
            [self loadMoreWTBsAndMatches];
        }
    }];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, [UIColor blackColor], NSForegroundColorAttributeName,  nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Buy Now"
                                      }];
    
    [self updateDates];
    [self scheduleTimer];

    if (self.tappedItem == YES) {
        self.tappedItem = NO;
    }
    else{
//        [self loadShopDrop];
    }
    
//    //check if should show affiliate items
//    PFQuery *versionQuery = [PFQuery queryWithClassName:@"versions"];
//    [versionQuery orderByDescending:@"createdAt"];
//    [versionQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
//        if (object) {
//            if ([[object objectForKey:@"showAfilliates"]isEqualToString:@"NO"]) {
//                self.showAffiliates = NO;
//                self.retrieveLimit = 30;
//            }
//            else{
//                self.showAffiliates = YES;
//                self.retrieveLimit = 26;
//            }
//        }
//        else{
//            NSLog(@"error getting latest version %@", error);
//            self.showAffiliates = NO;
//            self.retrieveLimit = 30;
//        }
//    }];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //user has pressed view more from intro WTB, set this to NO so search Intro is triggered next time they're in explore
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"viewMorePressed"] == YES) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"viewMorePressed"];
    }
    
    //seen scheduling reminder?
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"dropIntro"]!=YES) {
        //show
        self.dropIntro = YES;
        [self pauseTimer];
        [self showCustomAlert];
    }
    
}

#pragma mark <UICollectionViewDataSource>

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    NSLog(@"will begin dragging");
    [self pauseTimer];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
//    NSLog(@"did end dragging");
    [self scheduleTimer];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if ([collectionView isKindOfClass:[AFCollectionView class]]) {
        
        if (self.carousel.currentItemIndex == 0) {
            //drops
            return self.scheduledArray.count;
        }
        else{
            //shop the drop
            if ([self.selectedShop isEqualToString:@"sup"]){
                return self.supArray.count;
            }
            else if ([self.selectedShop isEqualToString:@"yeezy"]){
                return self.yeezyArray.count;
            }
            else if ([self.selectedShop isEqualToString:@"palace"]){
                return self.palaceArray.count;
            }
            else{
                NSLog(@"fail safe in number of items");
                return 0;
            }
        }
    }
    else{
        return self.products.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([collectionView isKindOfClass:[AFCollectionView class]]) {
        //header's collection View
        droppingCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
        
        //border
        [self setImageBorder:cell.dropImageView];
        [self clearOuterColour:cell.outerView];
        
        cell.dropImageView.image = nil;
        
        if (self.carousel.currentItemIndex == 0) {
            
            //future releases
            [cell.dropLabel setHidden:NO];
            
            PFObject *releaseItem = [self.scheduledArray objectAtIndex:indexPath.row];
            
            //set image
            NSString *imageURL = [releaseItem valueForKey:@"imageURL"];
            [cell.dropImageView sd_setImageWithURL:[NSURL URLWithString:imageURL]];
            
            if ([[PFUser currentUser]objectForKey:@"remindersArray"]) {
                
                if ([[[PFUser currentUser]objectForKey:@"remindersArray"] containsObject:[releaseItem objectForKey:@"itemTitle"]]) {
                    //already scheduled
                    [self setAvailabilityImageViewBorder:cell.dropImageView];
                    [self setReminderViewBorder:cell.outerView];
                }
                else{
                    //no reminder for this item
                }
            }
            
            //set release date label
            if([self isDateToday:[releaseItem objectForKey:@"releaseDate"]]) {
                //drops today
                
                if( [[NSDate date]timeIntervalSinceDate:[releaseItem objectForKey:@"releaseDateWithTime"] ] > 0 ) {
                    
                    [self setAvailabilityImageViewBorder:cell.dropImageView];
                    
                    //check if sold out
                    if ([[releaseItem objectForKey:@"status"]isEqualToString:@"soldout"]) {
                        cell.dropLabel.text = @"S O L D  O U T";
                        [self setSoldOutViewBorder:cell.outerView];
                        [cell.dropLabel setTextColor:[UIColor lightGrayColor]];
                    }
                    else{
                        //if not sold out & already live change the colour to green
                        cell.dropLabel.text = @"L I V E";
                        [self setAvailableViewBorder:cell.outerView];
                        [cell.dropLabel setTextColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1]];
                    }
                }
                else{
                    //time hasn't happened yet so use time & black color
                    cell.dropLabel.text = [releaseItem objectForKey:@"releaseTimeString"];
                    [cell.dropLabel setTextColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1]];
                }
            }
            else{
                //check if drops tomorrow
                if ([self isDateTomorrow:[releaseItem objectForKey:@"releaseDate"]]) {
                    
                    NSString *tomorrowDay = [self.dayOfWeekFormatter stringFromDate:[releaseItem objectForKey:@"releaseDate"]];
                    cell.dropLabel.text = tomorrowDay;
                }
                else{
                    cell.dropLabel.text = [releaseItem objectForKey:@"releaseDateString"];
                }
                [cell.dropLabel setTextColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1]];
            }
        }
        else{
            
            //shop
            [cell.dropLabel setHidden:YES];
            PFObject *shopItem;
            
            if ([self.selectedShop isEqualToString:@"sup"]){
                shopItem = [self.supArray objectAtIndex:indexPath.row];
            }
            else if ([self.selectedShop isEqualToString:@"yeezy"]){
                shopItem = [self.yeezyArray objectAtIndex:indexPath.row];
            }
            else if ([self.selectedShop isEqualToString:@"palace"]){
                shopItem = [self.palaceArray objectAtIndex:indexPath.row];
            }
            else{
                NSLog(@"fail safe");
//                shopItem = [self.supArray objectAtIndex:indexPath.row];
                //this may have been causing an issue //CHECK
            }
            
            //img
            [cell.dropImageView setFile:[shopItem objectForKey:@"image1"]];
            [cell.dropImageView loadInBackground];
            
            //add to seen array
            if ([shopItem objectForKey:@"index"]) {
                if ([self.selectedShop isEqualToString:@"sup"]){
                    if (![self.supSeenArray containsObject:[shopItem objectForKey:@"index"]]) {
                        [self.supSeenArray addObject:[shopItem objectForKey:@"index"]];
                    }
                }
                else if ([self.selectedShop isEqualToString:@"yeezy"]){
                    if (![self.yeezySeenArray containsObject:[shopItem objectForKey:@"index"]]) {
                        [self.yeezySeenArray addObject:[shopItem objectForKey:@"index"]];
                    }
                }
                else if ([self.selectedShop isEqualToString:@"palace"]){
                    if (![self.palaceSeenArray containsObject:[shopItem objectForKey:@"index"]]) {
                        [self.palaceSeenArray addObject:[shopItem objectForKey:@"index"]];
                    }
                }
            }
        }
        return cell;
    }
    else{
        ProfileItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
        [cell.purchasedImageView setHidden:YES];
        cell.itemImageView.image = nil;
        [cell.itemImageView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
        
        NSDictionary *itemDict = [self.products objectAtIndex:indexPath.row];
        NSString *dictionaryType = [itemDict valueForKey:@"itemType"];
        
        if ([dictionaryType isEqualToString:@"normal"]) { //fetch before adding to dictionary?
            //normal for sale item from a match or featured
            PFObject *itemObject = [itemDict valueForKey:@"item"];
            
            if (![self.addedIDs containsObject:itemObject.objectId]) {
                [self.addedIDs addObject:itemObject.objectId];
            }
            
            [itemObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                
                if (object) {
                    cell.itemImageView.contentMode = UIViewContentModeScaleAspectFill;
                    [cell.itemImageView setFile:[itemObject objectForKey:@"image1"]];
                    [cell.itemImageView loadInBackground];
                }
            }];
        }
        else{

            cell.itemImageView.image = nil;
            [cell.itemImageView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
            
            //access image
            NSDictionary *itemD = [self.products objectAtIndex:indexPath.row];
            PFObject *itemObj = [itemD valueForKey:@"item"];
            
            if (![[[PFUser currentUser]objectForKey:@"affiliateSeen"]containsObject:[itemObj objectForKey:@"itemTitle"]]) {
                [[PFUser currentUser]addObject:[itemObj objectForKey:@"itemTitle"] forKey:@"affiliateSeen"];
                [[PFUser currentUser]saveEventually];
                self.remainingAffiliates--;
            }
            
            [cell.itemImageView sd_setImageWithURL:[NSURL URLWithString:[itemObj objectForKey:@"imageURL"]]];
            cell.itemImageView.contentMode = UIViewContentModeScaleAspectFill;
        }
        return cell;
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if ([collectionView isKindOfClass:[AFCollectionView class]]) {
        //header's collection View
        
        
        if (self.carousel.currentItemIndex == 0) {
            //drop reminders
            
            if (self.alertShowing == YES) {
                //checks if drop intro is showing - if so dismiss alert first
                [self donePressed];
            }
            
            PFObject *itemObject = [self.scheduledArray objectAtIndex:indexPath.row];
            
            if ([[itemObject objectForKey:@"status"]isEqualToString:@"TBC"]) {
                //check if release is TBC - if so don't show reminder/drop page
                self.showDropPageToo = NO;
                self.TBCMode = YES;
                [self pauseTimer];
                [self showAlertViewForItem:itemObject atIndexPath:indexPath];
                
            }
            else if([self isDateToday:[itemObject objectForKey:@"releaseDate"]]) {
                //drops today
                
                //check if releaseTimeDate is  in the next 10 mins
                NSDate *exactReleaseTime = [itemObject objectForKey:@"releaseDateWithTime"];
                NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:exactReleaseTime];
                double secondsInAMin = 60;
                NSInteger minsBetweenDates = distanceBetweenDates / secondsInAMin;
                
                //check if item drops in next 10 mins
                if (minsBetweenDates <= -10) {
                    //drop is > 10 mins away so show both options
                    self.showDropPageToo = YES;
                    [self pauseTimer];
                    [self showAlertViewForItem:itemObject atIndexPath:indexPath];
                }
                else{
                    //drop is in next 10 mins, just show product page
                    
                    NSString *releaseLink = [itemObject objectForKey:@"itemLink"];
                    
                    self.web = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:releaseLink]];
                    self.web.showUrlWhileLoading = YES;
                    self.web.showPageTitles = YES;
                    self.web.doneButtonTitle = @"";
                    self.web.paypalMode = NO;
                    self.web.infoMode = NO;
                    self.web.delegate = self;
                    
                    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.web];
                    [self presentViewController:navigationController animated:YES completion:nil];
                }
            }
            else{
                //not today so allow scheduling
                self.showDropPageToo = NO;
                [self pauseTimer];
                [self showAlertViewForItem:itemObject atIndexPath:indexPath];
            }
        }
        else{
            //shop
            [Answers logCustomEventWithName:@"Tapped Shop Item"
                           customAttributes:@{
                                              @"shop":self.selectedShop
                                              }];
            [self pauseTimer];
            self.tappedItem = YES;
            
            PFObject *itemObject;
            
            if ([self.selectedShop isEqualToString:@"sup"]){
                itemObject = [self.supArray objectAtIndex:indexPath.row];
            }
            else if ([self.selectedShop isEqualToString:@"yeezy"]){
                itemObject = [self.yeezyArray objectAtIndex:indexPath.row];
            }
            else if ([self.selectedShop isEqualToString:@"palace"]){
                itemObject = [self.palaceArray objectAtIndex:indexPath.row];
            }
            else{
                NSLog(@"fail safe in did select");
            }
            
            ForSaleListing *vc = [[ForSaleListing alloc]init];
            vc.listingObject = itemObject;
            vc.source = @"shop";
            vc.fromBuyNow = YES;
            vc.pureWTS = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else{
        self.tappedItem = YES;
        
        [Answers logCustomEventWithName:@"Tapped Buy Now Item"
                       customAttributes:@{}];

        NSDictionary *itemDict = [self.products objectAtIndex:indexPath.row];
        NSString *dictionaryType = [itemDict valueForKey:@"itemType"];
        
        if ([dictionaryType isEqualToString:@"normal"]) {
            //normal for sale item from a match or featured
            PFObject *itemObject = [itemDict valueForKey:@"item"];
            
            ForSaleListing *vc = [[ForSaleListing alloc]init];
            vc.listingObject = itemObject;
            vc.source = @"buy now";
            vc.fromBuyNow = YES;
            vc.pureWTS = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            NSDictionary *itemDict = [self.products objectAtIndex:indexPath.row];
            NSLog(@"ITEM DICT BEFORE FORSALE %@", itemDict);
            
            //affiliate item
            ForSaleListing *vc = [[ForSaleListing alloc]init];
            vc.listingObject = nil;
            vc.source = @"buy now";
            vc.fromBuyNow = YES;
            vc.pureWTS = YES;
            vc.affiliateMode = YES;
            vc.affiliateObject = [itemDict valueForKey:@"item"];

            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    self.headerView = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        self.headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
        
        //carousel setup
        if (!self.carousel) {
            self.carousel = [[iCarousel alloc]initWithFrame:CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.frame.size.width, self.headerView.frame.size.height)];
                        
            self.carousel.type = iCarouselTypeLinear;
            self.carousel.delegate = self;
            self.carousel.dataSource = self;
            self.carousel.pagingEnabled = YES;
            self.carousel.bounceDistance = 0.6;
            self.carousel.scrollEnabled = NO;
            self.carousel.clipsToBounds = YES;
            [self.carousel setBackgroundColor:[UIColor whiteColor]];
            [self.carousel reloadData];
            
            [self.headerView addSubview:self.carousel];
            
            [self scheduleTimer];
        }
    }
    return self.headerView;
}

#pragma mark - carousel delegates

-(CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value{
    if (option == iCarouselOptionWrap) {
        return YES;
    }
    return value;
}

-(void)carouselWillBeginDragging:(iCarousel *)carousel{
    [self pauseTimer];
    
    if (self.carousel.currentItemIndex == 0) {
        [self.scheduledView.collectionView.collectionViewLayout invalidateLayout];
        [self.scheduledView.collectionView reloadData];
    }
    else{
//        [self.shopView.collectionView.collectionViewLayout invalidateLayout];
//        [self.shopView.collectionView reloadData];
    }
}

-(void)carouselDidEndScrollingAnimation:(iCarousel *)carousel{
    [self scheduleTimer];
    
    if (self.carousel.currentItemIndex == 0) {
        [self.scheduledView.collectionView.collectionViewLayout invalidateLayout];
        [self.scheduledView.collectionView reloadData];
//        
//        if (self.supremeSeen == NO){
//            self.selectedShop = @"sup";
//            [self.shopView.shopButton setTitle:@"S H O P  S U P R E M E" forState:UIControlStateNormal];
//            self.supremeSeen = YES;
//        }
//        else if (self.yeezySeen == NO) {
//            self.selectedShop = @"yeezy";
//            [self.shopView.shopButton setTitle:@"S H O P  Y E E Z Y" forState:UIControlStateNormal];
//            self.yeezySeen = YES;
//        }
//        else if (self.palaceSeen == NO){
//            self.selectedShop = @"palace";
//            [self.shopView.shopButton setTitle:@"S H O P  P A L A C E" forState:UIControlStateNormal];
//            self.yeezySeen = NO;
//            self.supremeSeen = NO;
//        }
//        
//        [self.shopView.collectionView.collectionViewLayout invalidateLayout];
//        [self.shopView.collectionView reloadData];
    }
    else{
        //shifted setup to index 0 so is faster loading the shop
//        [self.shopView.collectionView.collectionViewLayout invalidateLayout];
//        [self.shopView.collectionView reloadData];
        
        //only change the shop if carousel is auto scrolling
//        if (self.autoScroll == YES) {
//            self.autoScroll = NO;
        
        
//        }
//        else{
//            //user has scrolled so dont change anything, may have seen something they like
//        }


    }
}

- (NSInteger)numberOfItemsInCarousel:(__unused iCarousel *)carousel
{
    return 1;
}

- (UIView *)carousel:(__unused iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    if (view == nil) {
        //load from nib
        view = [[[NSBundle mainBundle] loadNibNamed:@"DroppingToday" owner:self options:nil] lastObject];
        [view setFrame:CGRectMake(0, 0, self.carousel.frame.size.width, self.carousel.frame.size.height)];
        [((droppingTodayView *)view).shopButton addTarget:self action:@selector(shopPressed) forControlEvents:UIControlEventTouchUpInside];
        
        //setup collection view delegate
        [((droppingTodayView *)view) setCollectionViewDataSourceDelegate:self indexPath:nil];

    }
    
    if (index == 0) {
        ((droppingTodayView *)view).titleLabel.text = @"R E L E A S E S";
        ((droppingTodayView *)view).titleLabel.textColor = [UIColor blackColor];
        [((droppingTodayView *)view).shopButton setHidden:YES];
        self.scheduledView = ((droppingTodayView *)view);
        
        [view setBackgroundColor:[UIColor whiteColor]];
        [((droppingTodayView *)view).collectionView setBackgroundColor:[UIColor whiteColor]];
    }
    else if (index == 1){
        //shop the drop
        ((droppingTodayView *)view).titleLabel.text = @"";
        [((droppingTodayView *)view).shopButton setHidden:NO];
        ((droppingTodayView *)view).titleLabel.textColor = [UIColor blackColor];
        self.shopView = ((droppingTodayView *)view);
        
        [view setBackgroundColor:[UIColor whiteColor]];
        [((droppingTodayView *)view).collectionView setBackgroundColor:[UIColor whiteColor]];
        
    }
    

    return view;

}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index{
    //do nothing
}
-(NSMutableArray *)randomObjectsFromArray: (NSMutableArray *)sourceArray{
    NSMutableArray* pickedIndexes = [NSMutableArray new];
    
    int remaining = 10;
    
    if (sourceArray.count >= remaining) {
        while (remaining > 0) {
            int sourceCount = (int)sourceArray.count;
            id index = sourceArray[arc4random_uniform(sourceCount)];
            
            if (![pickedIndexes containsObject:index]) {
                [pickedIndexes addObject:index];
                remaining--;
            }
        }
    }
    return pickedIndexes;
}

-(void)loadWTBsAndMatches{
    if (self.pullFinished == NO) {
        return;
    }
    
    [self.anotherPromptButton setHidden:YES];
    self.pullFinished = NO;
    
    [self.collectionView.infiniteScrollingView stopAnimating];
    
    self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
    [self.pullQuery whereKey:@"postUser" equalTo:[PFUser currentUser]];
//    [self.pullQuery whereKey:@"status" equalTo:@"live"]; //does a WTB need to be live to inform products? also affects indexes searched
    
    if ([[PFUser currentUser]objectForKey:@"indexedListings"] &&[[PFUser currentUser]objectForKey:@"postNumber"] ) {
        
        int postNumber = [[[PFUser currentUser]objectForKey:@"postNumber"]intValue];
        
        //add indexes of all WTBs to an array so can track whats been loaded
        [self.listingIndexesArray removeAllObjects];
        [self.addedIndexes removeAllObjects];
        
        for (int i=0; i< postNumber; i++) {
            [self.listingIndexesArray addObject:[NSNumber numberWithInt:i]];
        }
        
        //shuffle indexes
        [self shuffle:self.listingIndexesArray];

        if (self.listingIndexesArray.count > 10) {
            //get 10 random indexes
            NSMutableArray *randomIndexes = [self randomObjectsFromArray:self.listingIndexesArray];
//            NSLog(@"indexes to get %@", randomIndexes);
            
            //keep track of what indexes have been fetched
            [self.addedIndexes addObjectsFromArray:randomIndexes];
            
            //remove from master index tracker array
            [self.listingIndexesArray removeObjectsInArray:randomIndexes];
            [self.pullQuery whereKey:@"index" containedIn:randomIndexes];
        }
        else{
            //have less than 10 WTBs so just shuffle the order
            [self.pullQuery whereKey:@"index" containedIn:self.listingIndexesArray];
            [self.addedIndexes addObjectsFromArray:self.listingIndexesArray];
            [self.listingIndexesArray removeAllObjects];
        }
    }
    
    self.pullQuery.limit = 10;
    [self.pullQuery cancel];
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (objects.count == 0 ) {
                [self.collectionView.pullToRefreshView stopAnimating];
                self.pullFinished = YES;
                self.infinFinished = YES;
                
                //fill with some for sale items
                [self loadFeatured];
                
                [self.anotherPromptButton setTitle:@"C R E A T E  A  L I S T I N G" forState:UIControlStateNormal];
                self.anotherPromptButton.alpha = 0.0f;
                [self.anotherPromptButton setHidden:NO];
                
                [UIView animateWithDuration:0.5
                                      delay:0.5
                                    options:UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                                     self.anotherPromptButton.alpha = 1.0f;
                                 }
                                 completion:nil];

                return;
            }

            [self.anotherPromptButton setHidden:YES];
            
            NSLog(@"got WTBs: %lu", objects.count);
            
            __block int productCount = 0;
            self.skipped = 0;
            [self.addedIDs removeAllObjects];
            
            NSMutableArray *holdingArray = [NSMutableArray array];
            
            for (PFObject *WTB in objects) {
                
                NSArray *wantWords = [WTB objectForKey:@"keywords"];
                int wantNum = (int)wantWords.count;
                
                //call server & pass the number bcoz of array counting bug with cloud code
                NSDictionary *params = @{@"wantedKeywords":wantWords, @"wantNumber":[NSNumber numberWithInt:wantNum]};
                
                [PFCloud callFunctionInBackground:@"productSearch" withParameters:params block:^(NSDictionary *response, NSError *error) {
                    if (!error) {
                        
                        NSDictionary *matchesDictionary = response;
                        
//                        NSLog(@"PRODUCT SEARCH RESP %@", matchesDictionary);
                        
                        if (holdingArray.count == self.retrieveLimit) { //was 30
                            return;
                        }
                        
                        //increment self.skipped when we actually use it's matches (i.e when the
                        productCount++;
                        self.skipped++;

                        //check if any for sale items returned
                        if ([[matchesDictionary valueForKey:@"matches"]count]==0){
                            //do nothing as have no matches from our sellers network
                        }
                        else{
                            //for each match item add to its own dictionary
                            NSArray *matches = [matchesDictionary valueForKey:@"matches"];
                            
                            for (PFObject *forSaleItem in matches) {
                                
                                if (![self.addedIDs containsObject:forSaleItem.objectId]) {
                                    
                                    //to prevent duplicates
                                    [self.addedIDs addObject:forSaleItem.objectId];
                                    
                                    //put each for sale item in a dictionary
                                    NSMutableDictionary *forSaleDictionary = [[NSMutableDictionary alloc]init];
                                    [forSaleDictionary setValue:forSaleItem forKey:@"item"];
                                    
                                    //set the 'itemType' to 'normal'
                                    [forSaleDictionary setValue:@"normal" forKey:@"itemType"];
                                    
                                    //add to holding array
                                    [holdingArray addObject:forSaleDictionary];
                                    
                                    if (holdingArray.count == self.retrieveLimit) {
                                        //once we have 30 break out
                                        NSLog(@"break");
                                        break;
                                    }
                                }
                            }
                        }
                        
                        //check if its the last WTB received & if so reload
                        if (productCount == objects.count || holdingArray.count == self.retrieveLimit) {
                            
                            NSLog(@"COUNT OF MATCHES %ld", holdingArray.count);
                            
                            [self.WTBMatches removeAllObjects];
                            [self.WTBMatches addObjectsFromArray:holdingArray];
                            
                            self.pullFinished = YES;
                            self.infinFinished = YES;
                            
                            self.infinFinalMode = NO;
                            
                            if (holdingArray.count < self.retrieveLimit) {
                                //need some buffer items from featured/normal for sale
                                [self loadFeatured];
                            }
                            else{
                                //only goto finalload if not calling loadFeatured
                                if (self.featuredFinished == YES) {
                                    [self finalLoad:nil];
                                }
                            }
                        }
                    }
                    else{
                        productCount++;
                        self.skipped++;
                        NSLog(@"error finding matches %@", error);
                    }
                }];
            }
        }
        else{
            [self.collectionView.pullToRefreshView stopAnimating];
            self.pullFinished = YES;
            NSLog(@"error in pull %@", error);
        }
    }];
}
- (IBAction)promptPressed:(id)sender {
    [Answers logCustomEventWithName:@"Create another listing"
                   customAttributes:@{
                                      @"From":@"Buy Now"
                                      }];
    self.tabBarController.selectedIndex = 2;
}

-(NSMutableArray *)get: (int)thismany RandomsLessThan:(int)total {  /////////////////////CHECK - ennsure number of for sale listings is bigger than 30
    NSMutableArray *listOfNumbers = [[NSMutableArray alloc] init];
    for (int i=0 ; i<total ; ++i) {
        [listOfNumbers addObject:[NSNumber numberWithInt:i]]; // ADD 1 TO GET NUMBERS BETWEEN 1 AND M RATHER THAN 0 and M-1
    }
    NSMutableArray *uniqueNumbers = [[NSMutableArray alloc] init];
    int r;
    while ([uniqueNumbers count] < thismany) { //up it to 40 because an item at one of those indexes may have been seen before
        r = arc4random() % [listOfNumbers count];
        if (![uniqueNumbers containsObject:[listOfNumbers objectAtIndex:r]]) {
            [uniqueNumbers addObject:[listOfNumbers objectAtIndex:r]];
        }
    }
    return uniqueNumbers;
}

//fills the gaps basically with random for sale items
-(void)loadFeatured{
    
    if (self.featuredFinished == NO) {
        return;
    }
    
//    NSLog(@"addedIDS count: %ld", self.addedIDs.count);
    
    NSMutableArray *featuredHolding = [[NSMutableArray alloc]init];
    
    PFQuery *forSaleQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [forSaleQuery whereKey:@"status" equalTo:@"live"];
    [forSaleQuery whereKey:@"objectId" notContainedIn:self.addedIDs];
    [forSaleQuery countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
        if (number) {
            
//            NSLog(@"number is %d", number);
            
            NSArray *indexesToGet = [self get:40 RandomsLessThan:number];
            PFQuery *forSaleQuery1 = [PFQuery queryWithClassName:@"forSaleItems"];
            [forSaleQuery1 whereKey:@"status" equalTo:@"live"];
            [forSaleQuery1 whereKey:@"index" containedIn:indexesToGet];
            forSaleQuery1.limit = 40; //think this limit was sometinmes causing less than 30 random for sale items to appear
            [forSaleQuery1 whereKey:@"objectId" notContainedIn:self.addedIDs];
            [forSaleQuery1 findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (objects) {
                    
                    NSLog(@"featured count %lu", objects.count);
                    
                    NSMutableArray *holdingIDs = [NSMutableArray array];
                    [holdingIDs addObjectsFromArray:self.addedIDs];
                    
//                    NSLog(@"holding ID COUNT %ld", holdingIDs.count);
                    
                    for (PFObject *featuredItem2 in objects) {
                        if (![holdingIDs containsObject:featuredItem2.objectId]) {
                            //avoid duplicates
                            [featuredHolding addObject:featuredItem2];
                            [holdingIDs addObject:featuredItem2.objectId];
                        }
                    }
                    
//                    NSLog(@"unique featured count %lu", holdingIDs.count);
                    
                    NSMutableArray *finalHoldingArray = [NSMutableArray array];
                    
                    for (PFObject *forSaleItem in featuredHolding) {
                        
                        //put each for sale item in a dictionary
                        NSMutableDictionary *forSaleDictionary = [[NSMutableDictionary alloc]init];
                        [forSaleDictionary setValue:forSaleItem forKey:@"item"];
                        
                        //set the 'itemType' to 'normal'
                        [forSaleDictionary setValue:@"normal" forKey:@"itemType"];
                        
                        //add to holding array
                        [finalHoldingArray addObject:forSaleDictionary];
                        
                        if (finalHoldingArray.count == self.retrieveLimit) {
                            //exit when hit 30, thats the max we'll need
                            break;
                        }
                        
                    }
                    
                    [self.featured removeAllObjects];
                    [self.featured addObjectsFromArray:finalHoldingArray];
                    
                    self.featuredFinished = YES;
                    
                    //pass infin matches all the time but its only used for infinity loading
                    [self finalLoad:self.infinMatches];
                    
//                    if (self.pullFinished == YES) {
//                        [self finalLoad];
//                    }
                    
                }
                else{
                    NSLog(@"error getting for sale listings %@", error);
                    self.featuredFinished = YES;
                    [self.featured removeAllObjects];
                    [self finalLoad:self.infinMatches];

                }
            }];
            
        }
        else{
            NSLog(@"error counting %@", error);
            self.featuredFinished = YES;
            [self.featured removeAllObjects];
            [self finalLoad:self.infinMatches];
        }
    }];
}

-(void)finalLoad:(NSMutableArray *)array{
    NSLog(@"FINAL LOAD CALLED");
    if (self.finalLoading == YES) {
        return;
    }
    
    self.finalLoading = YES;
    
    if (self.infinFinalMode != YES) {
        
        NSLog(@"FINAL LOAD IN PULL MODE");
        
        if (self.WTBMatches.count == self.retrieveLimit) {
            //just have WTB matches as products surfaced
            [self.products removeAllObjects];
            [self.products addObjectsFromArray:self.WTBMatches];
            [self shuffle:self.products];
            
            if (self.showAffiliates == YES) {
                //add an affiliate product every 11 items so 2 per 30 items
                for (int i=1; i<self.products.count; i++) {
                    if (i % 11 == 0) {
                        NSLog(@"INSERTING AFF");
                        //divisible by 11 so add an affiliate item
                        [self.products insertObject:[self.affiliateProducts objectAtIndex:self.indexToAdd] atIndex:i-1];
                        NSLog(@"INSERTED AFF");
                        self.indexToAdd++;
                    }
                }
            }
        }
        
        else if (self.WTBMatches.count < self.retrieveLimit){
            //add this many featured -> 30-count (that haven't been seen before)
            int numberToAdd = self.retrieveLimit-(int)self.WTBMatches.count;
            
//            NSLog(@"number to add %d", numberToAdd);
            
            //create array from featured which is correct size
            NSArray *extraItems = [NSArray array];
            
            if (self.featured.count >= numberToAdd) {
//                NSLog(@"can top up exactly");
                
                extraItems = [self.featured subarrayWithRange: NSMakeRange(0,numberToAdd)];
                
                //add featured array to wtbmatches
                [self.WTBMatches addObjectsFromArray:extraItems];
                
            }
            else{
//                NSLog(@"use whole array");
                
                //just use wholefeatured array
                [self.WTBMatches addObjectsFromArray:self.featured];
            }
            
            if (self.showAffiliates == YES) {
                for (int i=1; i<self.WTBMatches.count; i++) {
                    if (i % 11 == 0) {
                        //divisible by 11 so add an affiliate item
                        [self.WTBMatches insertObject:[self.affiliateProducts objectAtIndex:self.indexToAdd] atIndex:i-1];
                        self.indexToAdd++;
                    }
                }
            }
            
            //add to self.products
            [self.products removeAllObjects];
            [self.products addObjectsFromArray:self.WTBMatches];
        }
    }
    else{
        
        NSLog(@"FINAL LOAD IN INFIN MODE w/ INFIN MATCHES COUNT %ld", self.infinMatches.count);

        if (self.infinMatches.count == self.retrieveLimit) {
            //just have WTB matches as products surfaced
            
            if (self.showAffiliates == YES) {
                for (int i=1; i<self.infinMatches.count; i++) {
                    if (i % 11 == 0) {
                        //divisible by 11 so add an affiliate item
                        [self.infinMatches insertObject:[self.affiliateProducts objectAtIndex:self.indexToAdd] atIndex:i-1];
                        self.indexToAdd++;
                    }
                }
            }
            
            [self.products addObjectsFromArray:self.infinMatches];
        }
        
        else if (self.infinMatches.count < self.retrieveLimit){
            //add this many featured -> 30-count (that haven't been seen before)
            int numberToAdd = self.retrieveLimit-(int)self.infinMatches.count;
            
            NSLog(@"INFIN number to add %d", numberToAdd);
            
            //create array from featured which is correct size
            NSArray *extraItems = [NSArray array];
            
            if (self.featured.count >= numberToAdd) {
                NSLog(@"INFIN can top up exactly");
                
                extraItems = [self.featured subarrayWithRange: NSMakeRange(0,numberToAdd)];
                
                //add featured array to wtbmatches
                [self.infinMatches addObjectsFromArray:extraItems];
                
            }
            else{
                NSLog(@"INFIN use whole array");
                
                //just use wholefeatured array
                [self.infinMatches addObjectsFromArray:self.featured];
            }
            
            if (self.showAffiliates == YES) {
                for (int i=1; i<self.infinMatches.count; i++) {
                    if (i % 11 == 0) {
                        //divisible by 11 so add an affiliate item
                        [self.infinMatches insertObject:[self.affiliateProducts objectAtIndex:self.indexToAdd] atIndex:i-1];
                        self.indexToAdd++;
                    }
                }
            }
            
            //add to self.products
            [self.products addObjectsFromArray:self.infinMatches];
        }
    }
    

    //stop spinner spinning
    [self.collectionView.infiniteScrollingView stopAnimating];
    [self.collectionView.pullToRefreshView stopAnimating];
    [self.collectionView reloadData];
    self.finalLoading = NO;
}

-(void)loadMoreWTBsAndMatches{
    if (self.infinFinished == NO || self.pullFinished == NO) {
        NSLog(@"returning from infin");
        return;
    }
    
    if (self.remainingAffiliates < 2 && self.showAffiliates == YES) {
        NSLog(@"TURNING OFF AFFILIATES COZ NOT ENOUGH TO SHOW");
        self.showAffiliates = NO;
        self.retrieveLimit = 30;
    }
    
    [self.anotherPromptButton setHidden:YES];
    self.infinFinished = NO;
    
    NSLog(@"INFIN LOADING");
    
    self.infiniteQuery = [PFQuery queryWithClassName:@"wantobuys"];
    
    
    if (self.listingIndexesArray.count > 0) {
        //we have some indexes to fetch
        
        NSLog(@"got some indexes to fetch in infin %@", self.listingIndexesArray);
        
        if (self.listingIndexesArray.count > 10) {
            //get 10 random indexes
            NSMutableArray *randomIndexes = [self randomObjectsFromArray:self.listingIndexesArray];
            NSLog(@"INFIN: indexes to get %@", randomIndexes);
            
            //keep track of indexes already fetched
            [self.addedIndexes addObjectsFromArray:randomIndexes];
            
            //remove from master index tracker array
            [self.listingIndexesArray removeObjectsInArray:randomIndexes];
            [self.infiniteQuery whereKey:@"index" containedIn:randomIndexes];
        }
        else{
            //have less than 10 WTBs so just shuffle the order
            [self.infiniteQuery whereKey:@"index" containedIn:self.listingIndexesArray];
            
            [self.addedIndexes addObjectsFromArray:self.listingIndexesArray];
            [self.listingIndexesArray removeAllObjects];
        }
    }
    else if([[PFUser currentUser]objectForKey:@"indexedListings"]){
        //ran out of listings so ensure we get zero returned
        [self.infiniteQuery whereKey:@"index" notContainedIn:self.addedIndexes];
    }
    
    [self.infiniteQuery whereKey:@"postUser" equalTo:[PFUser currentUser]];
//    [self.infiniteQuery whereKey:@"status" equalTo:@"live"]; //see pull comments
    self.infiniteQuery.limit = 10;
    self.infiniteQuery.skip = self.skipped;
    [self.infiniteQuery orderByDescending:@"lastUpdated"];
    [self.infiniteQuery cancel];
    [self.infiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (objects.count == 0 ) {
                
                NSLog(@"nothing from INFIN");
                
                self.infinFinished = YES;
                
                [self.infinMatches removeAllObjects];
                
                //fill with some for sale items
                self.infinFinalMode = YES;
                [self loadFeatured];
                
                [self.anotherPromptButton setTitle:@"C R E A T E  A  L I S T I N G" forState:UIControlStateNormal];
                self.anotherPromptButton.alpha = 0.0f;
                [self.anotherPromptButton setHidden:NO];

                [UIView animateWithDuration:0.5
                                      delay:0.5
                                    options:UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                                     self.anotherPromptButton.alpha = 1.0f;
                                 }
                                 completion:nil];
                
                return;
            }
            
            [self.anotherPromptButton setHidden:YES];
            
            NSLog(@"INFIN WTBs: %lu", objects.count);
            
            __block int productCount = 0;
            
            NSMutableArray *holdingArray = [NSMutableArray array];
            
            for (PFObject *WTB in objects) {
                
                NSArray *wantWords = [WTB objectForKey:@"keywords"];
                int wantNum = (int)wantWords.count;
                
                //call server & pass the number bcoz of array counting bug with cloud code
                NSDictionary *params = @{@"wantedKeywords":wantWords, @"wantNumber":[NSNumber numberWithInt:wantNum]};
                
                [PFCloud callFunctionInBackground:@"productSearch" withParameters:params block:^(NSDictionary *response, NSError *error) {
                    if (!error) {
                        
                        NSDictionary *matchesDictionary = response;
                        
//                        NSLog(@"PRODUCT SEARCH RESP %@", matchesDictionary);
                        
                        if (holdingArray.count == self.retrieveLimit) {
                            return;
                        }
                        
                        //increment self.skipped when we actually use it's matches (i.e when the
                        productCount++;
                        self.skipped++;
                        
                        //check if any for sale items returned
                        if ([[matchesDictionary valueForKey:@"matches"]count]==0){
                            //do nothing as have no matches from our sellers network
                        }
                        else{
                            //for each match item add to its own dictionary
                            NSArray *matches = [matchesDictionary valueForKey:@"matches"];
                            
                            for (PFObject *forSaleItem in matches) {
                                
                                if (![self.addedIDs containsObject:forSaleItem.objectId]) {
                                    
                                    //to prevent duplicates
                                    [self.addedIDs addObject:forSaleItem.objectId];
                                    
                                    //put each for sale item in a dictionary
                                    NSMutableDictionary *forSaleDictionary = [[NSMutableDictionary alloc]init];
                                    [forSaleDictionary setValue:forSaleItem forKey:@"item"];
                                    
                                    //set the 'itemType' to 'normal'
                                    [forSaleDictionary setValue:@"normal" forKey:@"itemType"];
                                    
                                    //add to holding array
                                    [holdingArray addObject:forSaleDictionary];
                                    
                                    if (holdingArray.count == self.retrieveLimit) {
                                        //once we have the limit, break out
                                        NSLog(@"break");
                                        break;
                                    }
                                }
                            }
                        }
                        
                        //check if its the last WTB received & if so reload
                        if (productCount == objects.count || holdingArray.count == self.retrieveLimit) {
                            
                            [self.infinMatches removeAllObjects];
                            [self.infinMatches addObjectsFromArray:holdingArray];
                            
                            NSLog(@"INFIN MATCHES %ld", holdingArray.count);
                            
                            self.infinFinished = YES;
                            self.infinFinalMode = YES;
                            
                            if (holdingArray.count < self.retrieveLimit) {
                                //need some buffer items from featured/normal for sale
                                [self loadFeatured];
                            }
                            else{
                                //only goto finalload if not calling loadFeatured
                                if (self.featuredFinished == YES) {
                                    [self finalLoad:self.infinMatches];
                                }
                            }
                        }
                    }
                    else{
                        productCount++;
                        self.skipped++;
                        NSLog(@"infin error finding matches %@", error);
                    }
                }];
            }
        }
        else{
            [self.collectionView.infiniteScrollingView stopAnimating];
            self.infinFinished = YES;
            NSLog(@"error in infin %@", error);
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

-(void)getScheduledReleases{
    
    if (self.thisMorning) {
        PFQuery *releases = [PFQuery queryWithClassName:@"Releases"];
        [releases whereKey:@"status" notEqualTo:@"deleted"];
        [releases whereKey:@"releaseDateWithTime" greaterThanOrEqualTo:self.thisMorning];
        [releases orderByAscending:@"releaseDateWithTime"];
        [releases findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                NSLog(@"FOUND %lu RELEASES", objects.count);
                
                [self.scheduledArray removeAllObjects];
                [self.scheduledArray addObjectsFromArray:objects];
                
                [self.scheduledView.collectionView.collectionViewLayout invalidateLayout];
                [self.scheduledView.collectionView reloadData];
                
            }
            else{
                NSLog(@"error getting releases %@", error);
            }
        }];
    }
    else{
        [Answers logCustomEventWithName:@"Caught thisMorning date error"
                       customAttributes:@{}];
    }

}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width/2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [imageView.layer setBorderWidth: 0.0];
}

-(void)setAvailableViewBorder:(UIView *)view{
    view.layer.cornerRadius = view.frame.size.width/2;
    view.layer.masksToBounds = YES;
    view.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    view.contentMode = UIViewContentModeScaleAspectFit;
    [view.layer setBorderColor: [[UIColor colorWithRed:0.31 green:0.89 blue:0.76 alpha:1.0] CGColor]];
    [view.layer setBorderWidth: 1.0];
}

-(void)setReminderViewBorder:(UIView *)view{
    view.layer.cornerRadius = view.frame.size.width/2;
    view.layer.masksToBounds = YES;
    view.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    view.contentMode = UIViewContentModeScaleAspectFit;
    [view.layer setBorderColor: [[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0] CGColor]];
    [view.layer setBorderWidth: 1.0];
}

-(void)setSoldOutViewBorder:(UIView *)view{
    view.layer.cornerRadius = view.frame.size.width/2;
    view.layer.masksToBounds = YES;
    view.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    view.contentMode = UIViewContentModeScaleAspectFit;
    [view.layer setBorderColor: [[UIColor colorWithRed:1.00 green:0.41 blue:0.49 alpha:1.0] CGColor]];
    [view.layer setBorderWidth: 1.0];
}

-(void)setAvailabilityImageViewBorder:(UIImageView *)imageView{
    [imageView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    [imageView.layer setBorderWidth: 1.5];
}

-(void)clearOuterColour:(UIView *)view{
    [view.layer setBorderWidth: 0.0];
}



- (BOOL) isDateToday: (NSDate *) aDate
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    
    components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:aDate];
    
    NSDate *otherDate = [cal dateFromComponents:components];
    
    if([today isEqualToDate:otherDate]) {
        return YES;
    }
    else{
        return NO;
    }
}

- (BOOL) isDateTomorrow: (NSDate *) aDate
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
    NSDate *tomor = [cal dateByAddingComponents:dayComponent toDate:today options:0];
    
    components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:aDate];
    
    NSDate *otherDate = [cal dateFromComponents:components];
    
    if([tomor isEqualToDate:otherDate]) {
        return YES;
    }
    else{
        return NO;
    }
}

-(void)loadShopDrop{
    
    [self loadSup];
    [self loadPalace];
    [self loadYeezy];
}

-(void)loadSup{
    //supreme shop
    PFQuery *supQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [supQuery whereKey:@"status" equalTo:@"live"];
    [supQuery whereKey:@"index" notContainedIn:self.supSeenArray];
    supQuery.limit = 5;
    NSLog(@"load sup");
    [supQuery orderByDescending:@"lastUpdated"];
    [supQuery whereKey:@"keywords" containedIn:@[@"supreme", @"sup", @"bogo", @"box logo", @"preme"]];
    [supQuery whereKey:@"keywords" notContainedIn:@[@"yeezy", @"palace"]];
    [supQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            if (objects.count == 0 && self.supSeenArray.count > 0) {
                [self.supSeenArray removeAllObjects];
                [self loadSup];
                return;
            }
            else if (objects.count == 0 && self.supSeenArray.count == 0){
                return;
            }
            self.supArray = objects;
            
            //this reload okay?
            [self.shopView.collectionView.collectionViewLayout invalidateLayout];
            [self.shopView.collectionView reloadData];
        }
    }];
}

-(void)loadYeezy{
    //yeezy shop
    PFQuery *yeezyQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [yeezyQuery whereKey:@"status" equalTo:@"live"];
    [yeezyQuery whereKey:@"index" notContainedIn:self.yeezySeenArray];
    yeezyQuery.limit = 5;
    NSLog(@"load yeezy");

    [yeezyQuery orderByDescending:@"lastUpdated"];
    [yeezyQuery whereKey:@"keywords" containedIn:@[@"yeezy", @"350", @"750", @"yeezys", @"pirates", @"moonrock", @"V2", @"kanye"]];
    [yeezyQuery whereKey:@"keywords" notContainedIn:@[@"supreme", @"palace"]];
    [yeezyQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            if (objects.count == 0 && self.yeezySeenArray.count > 0) {
                [self.yeezySeenArray removeAllObjects];
                [self loadYeezy];
                return;
            }
            else if (objects.count == 0 && self.yeezySeenArray.count == 0){
                return;
            }
            
            self.yeezyArray = objects;
        }
    }];
}

-(void)loadPalace{
    //palace shop
    PFQuery *palaceQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [palaceQuery whereKey:@"status" equalTo:@"live"];
    [palaceQuery whereKey:@"index" notContainedIn:self.palaceSeenArray];
    palaceQuery.limit = 5;
    NSLog(@"load palace");

    [palaceQuery orderByDescending:@"lastUpdated"];
    [palaceQuery whereKey:@"keywords" containedIn:@[@"palace", @"palidas", @"triferg"]];
    [palaceQuery whereKey:@"keywords" notContainedIn:@[@"supreme", @"yeezy"]];
    [palaceQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            if (objects.count == 0 && self.palaceSeenArray.count > 0) {
                [self.palaceSeenArray removeAllObjects];
                [self loadPalace];
                return;
            }
            else if (objects.count == 0 && self.palaceSeenArray.count == 0){
                return;
            }
            
            self.palaceArray = objects;
        }
    }];
}

-(void)shopPressed{
    
    self.tappedItem = YES;
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Shop Now",
                                      @"shop":self.selectedShop
                                      }];
    
    FeaturedItems *vc = [[FeaturedItems alloc]init];
    vc.mode = @"shop";
    vc.shop = self.selectedShop;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)doubleTapScroll{
    if (self.products.count != 0 && self.tappedItem == NO) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:YES];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self pauseTimer];
    
    [[PFUser currentUser] setObject:self.yeezySeenArray forKey:@"yeezySeenArray"];
    [[PFUser currentUser] setObject:self.supSeenArray forKey:@"supSeenArray"];
    [[PFUser currentUser] setObject:self.palaceSeenArray forKey:@"palaceSeenArray"];
    [[PFUser currentUser] saveInBackground];
}

-(void)scrollPlease{
    self.autoScroll = YES;
    [self.carousel scrollToItemAtIndex:self.carousel.currentItemIndex+1 animated:YES];
}

-(void)pauseTimer{
//    if (self.pausedInProgress == YES) {
//        return;
//    }
//    self.pausedInProgress = YES;
//    
//    [self.scrollTimer invalidate];
//    self.scrollTimer = nil;
//    
//    
//    self.pausedInProgress = NO;
}

-(void)scheduleTimer{
//    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"dropIntro"]!=YES) {
//        return;
//    }
//    [self.scrollTimer invalidate];
//     self.scrollTimer = nil;
//     
//    self.scrollTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
//                                                        target:self
//                                                      selector:@selector(scrollPlease)
//                                                      userInfo:nil
//                                                       repeats:YES];
}

-(void)showAlertViewForItem: (PFObject *) scheduledItem atIndexPath:(NSIndexPath *)indexPath {
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    if (self.TBCMode == YES) {
        self.TBCMode = NO;
        //don't show anything else, just the title and maybe price
        if ([scheduledItem objectForKey:@"priceString"] && [scheduledItem objectForKey:@"releaseTimeString"]) {
            actionSheet.title = [NSString stringWithFormat:@"%@ %@\n%@ %@",[scheduledItem objectForKey:@"itemTitle"],[scheduledItem objectForKey:@"priceString"],[scheduledItem objectForKey:@"releaseDateString"],[scheduledItem objectForKey:@"releaseTimeString"]];
        }
        else if ([scheduledItem objectForKey:@"priceString"]){
            actionSheet.title = [NSString stringWithFormat:@"%@ %@\n%@",[scheduledItem objectForKey:@"itemTitle"],[scheduledItem objectForKey:@"priceString"],[scheduledItem objectForKey:@"releaseDateString"]];
        }
        else{
            actionSheet.title = [NSString stringWithFormat:@"%@\n%@",[scheduledItem objectForKey:@"itemTitle"], [scheduledItem objectForKey:@"releaseDateString"]];
        }
    }
    else{
        if ([scheduledItem objectForKey:@"priceString"]) {
            actionSheet.title = [NSString stringWithFormat:@"%@ %@\n%@ %@",[scheduledItem objectForKey:@"itemTitle"],[scheduledItem objectForKey:@"priceString"],[scheduledItem objectForKey:@"releaseDateString"],[scheduledItem objectForKey:@"releaseTimeString"]];
        }
        else{
            actionSheet.title = [NSString stringWithFormat:@"%@\n%@ %@",[scheduledItem objectForKey:@"itemTitle"],[scheduledItem objectForKey:@"releaseDateString"],[scheduledItem objectForKey:@"releaseTimeString"]];
        }
        
        if (self.showDropPageToo == YES && [scheduledItem objectForKey:@"itemLink"]) {
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Visit Drop Page" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
                [Answers logCustomEventWithName:@"Visit Drop Page Tapped"
                               customAttributes:@{}];
                
                NSString *releaseLink = [scheduledItem objectForKey:@"itemLink"];
                
                self.web = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:releaseLink]];
                self.web.showUrlWhileLoading = YES;
                self.web.showPageTitles = YES;
                self.web.doneButtonTitle = @"";
                self.web.paypalMode = NO;
                self.web.infoMode = NO;
                self.web.delegate = self;
                
                NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.web];
                [self presentViewController:navigationController animated:YES completion:nil];
            }]];
        }
        
        NSMutableArray *remindersArray = [NSMutableArray array];
        
        if ([[PFUser currentUser]objectForKey:@"remindersArray"]) {
            [remindersArray addObjectsFromArray:[[PFUser currentUser]objectForKey:@"remindersArray"]];
        }
        
        if ([remindersArray containsObject:[scheduledItem objectForKey:@"itemTitle"]]) {
            //cancel notification
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel Reminder" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self showHUD];
                self.hud.labelText = @"Cancelled";
                
                [Answers logCustomEventWithName:@"Cancel Reminder"
                               customAttributes:@{}];
                
                //update user array
                NSMutableArray *discardedItems = [NSMutableArray array];
                
                for (NSString *itemTitle in remindersArray) {
                    
                    if ([itemTitle isEqualToString:[scheduledItem objectForKey:@"itemTitle"]]){
                        [discardedItems addObject:itemTitle];
                        NSLog(@"found an item to delete");
                    }
                    
                }
                [remindersArray removeObjectsInArray:discardedItems];
                
                [[PFUser currentUser]setObject:remindersArray forKey:@"remindersArray"];
                [[PFUser currentUser] saveInBackground];
                
                //remove border by reloading cell
                [self.scheduledView.collectionView reloadData];

                //cancel local notification
                NSArray *notificationArray = [[UIApplication sharedApplication] scheduledLocalNotifications];
                
                for(UILocalNotification *notification in notificationArray){
                    
                    if ([notification.alertBody containsString:[scheduledItem objectForKey:@"itemTitle"]]) {
                        
                        // delete this notification
                        NSLog(@"delete this notification");
                        [[UIApplication sharedApplication] cancelLocalNotification:notification];
                    }
                }
                
                double delayInSeconds = 1.5; // number of seconds to wait
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self hideHUD];
                });
                
                [self scheduleTimer];
                
            }]];
        }
        else{
            //schedule notification
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Remind me when this drops" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
                [Answers logCustomEventWithName:@"Remind me pressed"
                               customAttributes:@{
                                                  @"sneaker":[scheduledItem objectForKey:@"itemTitle"]
                                                  }];
                
                [self showHUD];
                self.hud.labelText = @"Scheduled";
                
                //schedule local notification
                
                NSString *reminderString = @"";
                NSCalendar *theCalendar = [NSCalendar currentCalendar];
                NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
                
                UILocalNotification *localNotification = [[UILocalNotification alloc]init];
                
                //set alert string
                NSString *releaseTime = [scheduledItem objectForKey:@"releaseTimeString"];
                
                //check if got a link - if so add 'Swipe to cop' to alert
                if ([scheduledItem objectForKey:@"itemLink"]) {
                    NSLog(@"got a link!");
                    reminderString = [NSString stringWithFormat:@"Reminder: the '%@' drops at %@ - Swipe to cop!", [scheduledItem objectForKey:@"itemTitle"],releaseTime];
                    
                    //attach the link to the notification for web view when opened
                    NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:[scheduledItem objectForKey:@"itemLink"], @"link", nil];
                    localNotification.userInfo = userDict;
                }
                else{
                    NSLog(@"no link so standard string");
                    reminderString = [NSString stringWithFormat:@"Reminder: the '%@' drops at %@!", [scheduledItem objectForKey:@"itemTitle"],releaseTime];
                }
                
                //set alert 10 mins before
                NSDate *dropDate = [scheduledItem objectForKey:@"releaseDateWithTime"];
                dayComponent.minute = -10;
                NSDate *dateToFire = [theCalendar dateByAddingComponents:dayComponent toDate:dropDate options:0];
                [localNotification setFireDate: dateToFire];
                [localNotification setAlertBody:reminderString];
                [localNotification setTimeZone: [NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
                [localNotification setRepeatInterval: 0];
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                
                [remindersArray addObject:[scheduledItem objectForKey:@"itemTitle"]];
                
                [[PFUser currentUser]setObject:remindersArray forKey:@"remindersArray"];
                [[PFUser currentUser] saveInBackground];
                
                //add border by reloading cell
                [self.scheduledView.collectionView reloadData];
                
                double delayInSeconds = 1.0; // number of seconds to wait
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self hideHUD];
                });
                
                if ([[NSUserDefaults standardUserDefaults]boolForKey:@"reminderIntroSeen"] == YES) {
                    //only schedule if alert not showing
                    [self scheduleTimer];
                }
            }]];
        }
    }
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self scheduleTimer];
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.labelText = @"";
    self.hud.mode = MBProgressHUDModeCustomView;
    [self.spinner startAnimating];
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
}

-(void)updateDates{
    
    if (self.updatingDates == YES) {
        return;
    }
    
    self.updatingDates = YES;
    
    //get correct dates for querying releases
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"dd/MM/YYYY"];
    NSString *dateString=[dateFormatter stringFromDate:[NSDate date]];
    
    //does user have 12 hour clock - impacts on formatter used
    NSString *formatStringForHours = [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]];
    NSRange containsA = [formatStringForHours rangeOfString:@"a"];
    BOOL is12HourClock = containsA.location != NSNotFound;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSString *dawn;

    if (is12HourClock == YES) {
        [formatter setDateFormat:@"dd/MM/yyyy hh:mm aa"];
        dawn = [NSString stringWithFormat:@"%@ 12:00 am", dateString];
    }
    else{
        [formatter setDateFormat:@"dd/MM/yyyy HH:mm"];
        dawn = [NSString stringWithFormat:@"%@ 00:00", dateString];
    }
    
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [formatter setTimeZone:gmt];
    
    self.thisMorning = [formatter dateFromString:dawn];
    
    [self getScheduledReleases];
    
    self.updatingDates = NO;
}

#pragma mark - web view delegates
-(void)paidPressed{
    //do nothing
}

-(void)cancelWebPressed{
    [self.web dismissViewControllerAnimated:YES completion:nil];
}

-(void)cameraPressed{
    //do nothing
}

-(void)screeshotPressed:(UIImage *)screenshot withTaps:(int)taps{
    //do nothing
}

#pragma mark - custom alert delegates

-(void)sellPressed{
    if (self.isSeller == YES) {
        //let seller list an item
        [self addForSalePressed];
    }
    else{
        [self showCustomAlert];
    }
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
        [self pauseTimer];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

-(void)SetupListing{
    [Answers logCustomEventWithName:@"Sell prompt pressed in buyNow"
                   customAttributes:@{
                                      @"seller":@"YES"
                                      }];
    
    CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
    vc.usernameToCheck = self.usernameToList;
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)showCustomAlert{
    if (self.alertShowing == YES) {
        return;
    }
    
    self.alertShowing = YES;
   
    if (self.dropIntro != YES) {
        self.searchBgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];

    }
    else{
        //show bg over collection view only so user can see releases
        self.searchBgView = [[UIView alloc]initWithFrame:CGRectMake(0,(self.navigationController.navigationBar.frame.size.height + self.headerView.frame.size.height+[UIApplication sharedApplication].statusBarFrame.size.height), [UIApplication sharedApplication].keyWindow.frame.size.width, [UIApplication sharedApplication].keyWindow.frame.size.height-(self.navigationController.navigationBar.frame.size.height+self.headerView.frame.size.height+[UIApplication sharedApplication].statusBarFrame.size.height))];
    }
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
    self.customAlert = (customAlertViewClass *)[nib objectAtIndex:0];
    self.customAlert.delegate = self;
    
    if (self.dropIntro == YES){
        [Answers logCustomEventWithName:@"Drop Intro showing"
                       customAttributes:@{}];
        
        self.customAlert.titleLabel.text = @"Drop Reminders";
        self.customAlert.messageLabel.text = @"Tap on a sneaker to view drop info & schedule a reminder to secure your pair";
        self.customAlert.numberOfButtons = 1;
    }
    else{
        [Answers logCustomEventWithName:@"Sell prompt pressed in buyNow"
                       customAttributes:@{
                                          @"seller":@"NO"
                                          }];
        
        self.customAlert.titleLabel.text = @"Sell on Bump";
        self.customAlert.messageLabel.text = @"Currently, only approved sellers can list items for sale. If you're an active seller send us a message to get selling on Bump";
        self.customAlert.numberOfButtons = 2;
    }
    
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
                          delay:0.2
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.customAlert setFrame:CGRectMake(0, 0, 250, 157)];
                            }
                            else{
                                [self.customAlert setFrame:CGRectMake(0, 0, 300, 188)]; //iPhone 6/7 specific
                            }
                            self.customAlert.center = self.view.center;
                            
                        }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)donePressed{
    
    if (self.dropIntro == YES){
        self.dropIntro = NO;
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"dropIntro"];
        [self scheduleTimer];
    }
    
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
                         self.alertShowing = NO;
                         [self.customAlert setAlpha:0.0];
                         self.customAlert = nil;
                     }];
}

-(void)firstPressed{
    [self donePressed];
}
-(void)secondPressed{
    [Answers logCustomEventWithName:@"Message Team Bump pressed from buyNow Sell prompt"
                   customAttributes:@{}];
    
    [self donePressed];
    //goto Team Bump messages
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"teamConvos"];
    NSString *convoId = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
    [convoQuery whereKey:@"convoId" equalTo:convoId];
    [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //convo exists, go there
            self.tappedItem = YES;
            ChatWithBump *vc = [[ChatWithBump alloc]init];
            vc.convoId = [object objectForKey:@"convoId"];
            vc.convoObject = object;
            vc.otherUser = [PFUser currentUser];
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
                    self.tappedItem = YES;
                    ChatWithBump *vc = [[ChatWithBump alloc]init];
                    vc.convoId = [convoObject objectForKey:@"convoId"];
                    vc.convoObject = convoObject;
                    vc.otherUser = [PFUser currentUser];
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else{
                    NSLog(@"error saving convo");
                }
            }];
        }
    }];
}

-(void)getAffiliateData{
    NSLog(@"get affiliate data");
    
    self.affiliateProducts = [NSMutableArray array];
    [self.affiliateProducts removeAllObjects];
    self.remainingAffiliates = 0;
    self.indexToAdd = 0;

    NSArray *seenAffiliates;
    
    if ([[PFUser currentUser]objectForKey:@"affiliateSeen"]) {
         seenAffiliates = [[PFUser currentUser]objectForKey:@"affiliateSeen"];
    }
    else{
        seenAffiliates = @[];
    }
    
    PFQuery *affQuery = [PFQuery queryWithClassName:@"Affiliates"];
    affQuery.limit = 500;
    [affQuery whereKey:@"itemTitle" notContainedIn:seenAffiliates];
    
    if (self.cleverMode == YES) {
        NSArray *calcdKeywords = [NSArray array];
        
        //use previous searches/wants to inform what affiliates people see
        NSArray *searchWords = [[PFUser currentUser]objectForKey:@"searches"];
        NSArray *wantedw = [NSArray array];
        if ([[PFUser currentUser]objectForKey:@"wantedWords"]) {
            wantedw = [[PFUser currentUser]objectForKey:@"wantedWords"];
        }
        
        //check if got any words to inform search
        if (searchWords.count > 0 || wantedw.count > 0) {
            NSMutableArray *allSearchWords = [NSMutableArray array];
            //seaprate the searches into search words
            for (NSString *searchTerm in searchWords) {
                NSArray *searchTermWords = [[searchTerm lowercaseString] componentsSeparatedByString:@" "];
                
                //then add all search words to an array in lower case
                [allSearchWords addObjectsFromArray:searchTermWords];
            }
            if (wantedw.count >0) {
                [allSearchWords addObjectsFromArray:wantedw];
            }
            calcdKeywords = [[allSearchWords reverseObjectEnumerator] allObjects];
        }
        
        [affQuery whereKey:@"keywords" containedIn:calcdKeywords];
    }
    
    [affQuery orderByDescending:@"createdAt"];
    [affQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (self.cleverMode == YES && objects.count == 0) {
                self.cleverMode = NO;
                [self getAffiliateData];
                return;
            }
            else if (self.cleverMode == NO && objects.count == 0){
                self.showAffiliates = NO;
                self.retrieveLimit = 30;
                [self.collectionView reloadData];
                return;
            }
        
            for (PFObject *affItem in objects) {
                self.remainingAffiliates++;
                
                //put each for sale item in a dictionary
                NSMutableDictionary *affDic = [[NSMutableDictionary alloc]init];
                [affDic setValue:affItem forKey:@"item"];
                
                //set the 'itemType' to 'normal'
                [affDic setValue:@"affiliate" forKey:@"itemType"];
                
                //add to holding array
                [self.affiliateProducts addObject:affDic];
            }
            
            
            NSLog(@"added all to affiliates with count %lu", self.affiliateProducts.count);
        
        }
        else{
            NSLog(@"error fetching affiliate objects %@", error);
            self.showAffiliates = NO;
            self.retrieveLimit = 30;
            [self.collectionView reloadData];
        }
    }];

}
@end
