//
//  BuyNowController.m
//  wtbtest
//
//  Created by Jack Ryder on 06/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "BuyNowController.h"
#import "AFCollectionView.h"
#import "RecommendCell.h"
#import "ForSaleCell.h"
#import <SVPullToRefresh/SVPullToRefresh.h>
#import "ForSaleListing.h"
#import "NavigationController.h"
#import "MessagesTutorial.h"
#import "FeaturedItems.h"
#import "Flurry.h"

@interface BuyNowController ()

@end

@implementation BuyNowController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"B U Y  N O W";
    
    self.tableView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"RecommendCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    self.contentOffsetDictionary = [NSMutableDictionary dictionary];
    
    self.wtbArray = [NSMutableArray array];
    self.viewsArray = [NSMutableArray array];
    self.pullFinished = YES;
    self.infinFinished = YES;
    
    // Option 1
    // Load user's latest 5 WTBs
    // for each WTB search for the WTS posts which have the most keywords in common (if none then don't show)
    // save pointers to those WTSs on the WTB object as Recommendation key
    // so it's a case of displaying the objects for this key in cell for item
    
    [self loadWTBs];
    
    if (![[[PFUser currentUser]objectForKey:@"completedBuyNow"]isEqualToString:@"YES"]) {
        MessagesTutorial *vc = [[MessagesTutorial alloc]init];
        vc.sellerMode = YES;
        [self presentViewController:vc animated:YES completion:nil];
    }
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    //put refresh code here so it remembers correct UICollectionView insets - doesn't work in VDL
    [self.tableView addPullToRefreshWithActionHandler:^{
        if (self.pullFinished == YES) {
            [self loadWTBs];
        }
    }];
    
    self.spinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
    [self.tableView.pullToRefreshView setCustomView:self.spinner forState:SVPullToRefreshStateAll];
    [self.spinner startAnimating];
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        if (self.infinFinished == YES) {
            [self infiniteloadWTBs];
        }
    }];
}

-(void)loadWTBs{
    if (self.pullFinished == NO || self.infinFinished == NO) {
        return;
    }
    self.pullFinished = NO;
    NSLog(@"PULL LOADING");

    [self.topLabel setHidden:YES];
    [self.bottomLabel setHidden:YES];
    [self.tableView.infiniteScrollingView stopAnimating];

    self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
    [self.pullQuery whereKey:@"postUser" equalTo:[PFUser currentUser]];
    [self.pullQuery whereKey:@"status" equalTo:@"live"];
    self.pullQuery.limit = 10;
    [self.pullQuery orderByDescending:@"createdAt"];
    [self.pullQuery cancel];
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            if (objects.count == 0) {
                
                // whole page should become for sale stuff.. and header should say no WTBs
                
                if (!self.topLabel && !self.bottomLabel) {
                    self.topLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                    self.topLabel.textAlignment = NSTextAlignmentCenter;
                    [self.topLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:20]];
                    self.topLabel.numberOfLines = 1;
                    self.topLabel.textColor = [UIColor lightGrayColor];
                    self.topLabel.text = @"No WTBs";
                    [self.view addSubview:self.topLabel];
                    
                    self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+90, 250, 200)];
                    self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                    [self.bottomLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:17]];
                    self.bottomLabel.numberOfLines = 0;
                    self.bottomLabel.textColor = [UIColor lightGrayColor];
                    self.bottomLabel.text = @"Create WTBs by hitting the + icon so we can suggest relevant products to buy right now from sellers on Bump";
                    [self.view addSubview:self.bottomLabel];
                }
                else{
                    self.topLabel.text = @"No WTBs";
                    self.bottomLabel.text = @"Create WTBs by hitting the + icon so we can suggest relevant products to buy right now from sellers on Bump";
                    
                    [self.topLabel setHidden:NO];
                    [self.bottomLabel setHidden:NO];
                }
                [self.tableView.pullToRefreshView stopAnimating];
                self.pullFinished = YES;
                return;
            }
        
            NSLog(@"got WTBs: %lu", objects.count);
            
            int count = (int)[objects count];
            __block int WTBCheck = 0;
            self.skipped = count;
            NSMutableArray *wtbHoldingArray = [NSMutableArray array];
//            [self.wtbArray removeAllObjects];
            
            //get keywords for each WTB and find a WTS that has a good match
            for (PFObject *WTB in objects) {
                
                NSArray *WTBKeywords = [WTB objectForKey:@"keywords"];
                
                //clear array before adding new
                [WTB removeObjectForKey:@"buyNow"];
                
                PFQuery *WTSQuery = [PFQuery queryWithClassName:@"forSaleItems"];
                [WTSQuery whereKey:@"status" equalTo:@"live"];
                [WTSQuery whereKey:@"keywords" containedIn:WTBKeywords];
                [WTSQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (objects) {
                        WTBCheck++;

                        for (PFObject *forSale in objects) {
                            NSArray *WTSKeywords = [forSale objectForKey:@"keywords"];
                            NSMutableSet* set1 = [NSMutableSet setWithArray:WTBKeywords];
                            NSMutableSet* set2 = [NSMutableSet setWithArray:WTSKeywords];
                            [set1 intersectSet:set2]; //this will give you only the obejcts that are in both sets
                            
                            NSArray* result = [set1 allObjects];
                            
                            //calc 70% of WTB keyword counts
                            float sixty = WTBKeywords.count*0.7;
                            int roundedFloat = roundf(sixty);
                            
                            if (result.count >= roundedFloat && roundedFloat>0 && result.count >2) {
                                //WTB has at least 2 matching keywords to this WTS and 70% keywords match
                                NSLog(@"WTB: %@     WTS: %@", [WTB objectForKey:@"title"], [forSale objectForKey:@"description"]);
                                [WTB addObject:forSale forKey:@"buyNow"];
                            }
                        }
                        
                        NSArray *matches = [WTB objectForKey:@"buyNow"];
                        
                        if (matches.count > 0) {
//                            [self.wtbArray addObject:WTB];
                            [wtbHoldingArray addObject:WTB];
                        }

                        if (count == WTBCheck) {
                            //done last one, now reload
                            NSLog(@"time to reload");
                            
                            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                                                initWithKey: @"createdAt" ascending: NO];
                            
                            NSArray *sortedArray = [wtbHoldingArray sortedArrayUsingDescriptors: [NSArray arrayWithObject:sortDescriptor]];
                            
                            [self.wtbArray removeAllObjects];
                            [self.wtbArray addObjectsFromArray:sortedArray];
                            
                            //labels
                            if (self.wtbArray.count == 0) {
                                if (!self.topLabel && !self.bottomLabel) {
                                    self.topLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                                    self.topLabel.textAlignment = NSTextAlignmentCenter;
                                    [self.topLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:18]];
                                    self.topLabel.numberOfLines = 1;
                                    self.topLabel.textColor = [UIColor lightGrayColor];
                                    self.topLabel.text = @"No recommended items";
                                    [self.view addSubview:self.topLabel];
                                    
                                    self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+60, 250, 200)];
                                    self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                                    [self.bottomLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:15]];
                                    self.bottomLabel.numberOfLines = 0;
                                    self.bottomLabel.textColor = [UIColor lightGrayColor];
                                    self.bottomLabel.text = @"Check back soon for recommended products based on your WTBs - In the meantime tap above to browse featured items for sale";
                                    [self.view addSubview:self.bottomLabel];
                                }
                                else{
                                    self.topLabel.text = @"No recommended items";
                                    self.bottomLabel.text = @"Check back soon for recommended products based on your WTBs - In the meantime tap above to browse featured items for sale";

                                    [self.topLabel setHidden:NO];
                                    [self.bottomLabel setHidden:NO];
                                }
                            }
                            else{
                                [self.topLabel setHidden:YES];
                                [self.bottomLabel setHidden:YES];
                            }
                            
                            [self.tableView reloadData];
                            [self.tableView.pullToRefreshView stopAnimating];
                            self.pullFinished = YES;
                        }
                    }
                    else{
                        NSLog(@"error getting relevant WTBs");
                    }
                }];
            }
        }
        else{
            NSLog(@"error getting WTBs %@", error);
        }
    }];
}

-(void)infiniteloadWTBs{
    if (self.pullFinished == NO || self.infinFinished == NO) {
        return;
    }
    NSLog(@"INFINITE LOADING");
    self.infinFinished = NO;
    self.infiniteQuery = [PFQuery queryWithClassName:@"wantobuys"];
    [self.infiniteQuery whereKey:@"postUser" equalTo:[PFUser currentUser]];
    [self.infiniteQuery whereKey:@"status" equalTo:@"live"];
    self.infiniteQuery.limit = 10;
    [self.infiniteQuery orderByDescending:@"createdAt"];
    self.infiniteQuery.skip = self.skipped;
    [self.infiniteQuery cancel];
    [self.infiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            if (objects.count == 0) {
                NSLog(@"got none");
                [self.tableView.infiniteScrollingView stopAnimating];
                self.infinFinished = YES;
                return;
            }
//            NSLog(@"infinite: got %u WTBs", objects.count);
            
            int count = (int)[objects count];
            self.skipped = self.skipped + count;
            __block int WTBCheck = 0;
            
            //get keywords for each WTB and find a WTS that has a good match
            for (PFObject *WTB in objects) {
                
                NSArray *WTBKeywords = [WTB objectForKey:@"keywords"];
                
                //clear array before adding new
                [WTB removeObjectForKey:@"buyNow"];
                
                PFQuery *WTSQuery = [PFQuery queryWithClassName:@"forSaleItems"];
                [WTSQuery whereKey:@"status" equalTo:@"live"];
                [WTSQuery whereKey:@"keywords" containedIn:WTBKeywords];
                [WTSQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (objects) {
                        WTBCheck++;

                        for (PFObject *forSale in objects) {
                            NSArray *WTSKeywords = [forSale objectForKey:@"keywords"];
                            NSMutableSet* set1 = [NSMutableSet setWithArray:WTBKeywords];
                            NSMutableSet* set2 = [NSMutableSet setWithArray:WTSKeywords];
                            [set1 intersectSet:set2]; //this will give you only the obejcts that are in both sets
                            
                            NSArray* result = [set1 allObjects];
                            
                            //calc 70% of WTB keyword counts
                            float sixty = WTBKeywords.count*0.9;
//                            NSLog(@" float %f", sixty);
                            int roundedFloat = roundf(sixty);
//                            NSLog(@"rounded float %d", roundedFloat);
//                            NSLog(@"results count %lu", (unsigned long)result.count);
                            
                            if (result.count >= roundedFloat && roundedFloat>0 && result.count >2) {
                                //WTB has at least 2 matching keywords to this WTS and 70% keywords match
                                NSLog(@"WTB: %@     WTS: %@", [WTB objectForKey:@"title"], [forSale objectForKey:@"description"]);
                                [WTB addObject:forSale forKey:@"buyNow"];
                            }
                        }
                        
                        if ([WTB objectForKey:@"buyNow"]) {
                            NSLog(@"for sale item(s) added for this WTB %@", [WTB objectForKey:@"title"]);
                            [self.wtbArray addObject:WTB];
                            [WTB saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                if (succeeded) {
                                    NSLog(@"saved WTB!");
                                }
                                else{
                                    NSLog(@"error saving WTB %@", error);
                                }
                            }];
                        }
                        if (count == WTBCheck) {
                            //done last one, now reload
                            NSLog(@"time to reload");
                            [self.tableView reloadData];
                            [self.tableView.infiniteScrollingView stopAnimating];
                            self.infinFinished = YES;
                        }
                    }
                    else{
                        NSLog(@"error getting relevant WTBs");
                    }
                }];
            }
        }
        else{
            NSLog(@"error getting WTBs %@", error);
        }
    }];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 143;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RecommendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    if (!cell){
        cell = [[RecommendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    PFObject *WTB = [self.wtbArray objectAtIndex:indexPath.row];

    self.currentIndexPath = indexPath;
    
    cell.wtbTitle.text = [WTB objectForKey:@"title"];
    
    //time posted
    NSDate *createdDate = WTB.createdAt;
    NSDate *now = [NSDate date];
    NSTimeInterval distanceBetweenDates = [now timeIntervalSinceDate:createdDate];
    double secondsInAnHour = 3600;
    float minsBetweenDates = (distanceBetweenDates / secondsInAnHour)*60;
    if (minsBetweenDates > 0 && minsBetweenDates < 1) {
        //seconds
        cell.timeLabel.text = [NSString stringWithFormat:@"%.fs ago", (minsBetweenDates*60)];
    }
    else if (minsBetweenDates == 1){
        //1 min
        cell.timeLabel.text = @"1m ago";
    }
    else if (minsBetweenDates > 1 && minsBetweenDates <60){
        //mins
        cell.timeLabel.text = [NSString stringWithFormat:@"%.fm ago", minsBetweenDates];
    }
    else if (minsBetweenDates == 60){
        //1 hour
        cell.timeLabel.text = @"1h ago";
    }
    else if (minsBetweenDates > 60 && minsBetweenDates <1440){
        //hours
        cell.timeLabel.text = [NSString stringWithFormat:@"%.fh ago", (minsBetweenDates/60)];
    }
    else if (minsBetweenDates > 1440 && minsBetweenDates < 2880){
        //1 day
        cell.timeLabel.text = [NSString stringWithFormat:@"%.fd ago", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 2880 && minsBetweenDates < 10080){
        //days
        cell.timeLabel.text = [NSString stringWithFormat:@"%.fd ago", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 10080){
        //weeks
        cell.timeLabel.text = [NSString stringWithFormat:@"%.fw ago", (minsBetweenDates/10080)];
    }
    else{
        //fail safe :D
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setDateFormat:@"MMM YY"];
        
        NSDate *formattedDate = [NSDate date];
        cell.timeLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:formattedDate]];
        dateFormatter = nil;
    }
    
    NSLog(@"at end of table view cell");
    
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"memory warning!!!!!!");
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView
numberOfRowsInSection:(NSInteger)section
{
    return self.wtbArray.count;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(RecommendCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setCollectionViewDataSourceDelegate:self indexPath:indexPath];
    
    NSInteger index = cell.collectionView.indexPath.row;
    CGFloat horizontalOffset = [self.contentOffsetDictionary[[@(index) stringValue]] floatValue];
    [cell.collectionView setContentOffset:CGPointMake(horizontalOffset, 0)];
    
}

-(NSInteger)collectionView:(AFCollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    NSArray *collectionViewArray = [self.wtbArray[collectionView.indexPath.row] objectForKey:@"buyNow"];
    
    return collectionViewArray.count;
}

-(UICollectionViewCell *)collectionView:(AFCollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ForSaleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    NSArray *collectionViewArray = [self.wtbArray[collectionView.indexPath.row] objectForKey:@"buyNow"];
    
    PFObject *WTS = collectionViewArray[indexPath.item];
    if ([self.viewsArray containsObject:WTS.objectId]) {
    }
    else{
        [self.viewsArray addObject:WTS.objectId];
    }
    
    PFObject *WTB = [self.wtbArray objectAtIndex:self.currentIndexPath.row];
    cell.itemView.image = nil;
    
    //setup cell
    [cell.itemView setFile:[WTS objectForKey:@"thumbnail"]];
    [cell.itemView loadInBackground];
    [WTS setObject:WTB forKey:@"WTB"];
    
    cell.itemView.layer.cornerRadius = 35;
    cell.itemView.layer.masksToBounds = YES;
    cell.itemView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    cell.itemView.contentMode = UIViewContentModeScaleAspectFill;

    return cell;
}

-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(RecommendCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat horizontalOffset = cell.collectionView.contentOffset.x;
    NSInteger index = cell.collectionView.indexPath.row;
    self.contentOffsetDictionary[[@(index) stringValue]] = @(horizontalOffset);
}

#pragma mark - UIScrollViewDelegate Methods

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (![scrollView isKindOfClass:[UICollectionView class]]) return;
    
    CGFloat horizontalOffset = scrollView.contentOffset.x;
    
    AFCollectionView *collectionView = (AFCollectionView *)scrollView;
    NSInteger index = collectionView.indexPath.row;
    self.contentOffsetDictionary[[@(index) stringValue]] = @(horizontalOffset);
}

-(void)collectionView:(AFCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    
    NSArray *collectionViewArray = [self.wtbArray[collectionView.indexPath.row] objectForKey:@"buyNow"];
    PFObject *WTS = collectionViewArray[indexPath.item];
    
    ForSaleListing *vc = [[ForSaleListing alloc]init];
    vc.listingObject = WTS;
    vc.WTBObject = [WTS objectForKey:@"WTB"];
    vc.source = @"recommended";
    vc.pureWTS = NO;
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [Flurry logEvent:@"BuyNow_Tapped"];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 70)];
        [view setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.9]];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((tableView.frame.size.width/2)-105, 26, 250, 18)];
        [label setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:12]];
        label.text = @"Tap to browse featured items for sale";
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0];
        [view addSubview:label];
//        label.center = view.center;
        
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake((label.frame.origin.x-15), 26, 15, 15)];
        [imageView setImage:[UIImage imageNamed:@"cartBlue"]];
        [view addSubview:imageView];
        
        UIButton *button = [[UIButton alloc]initWithFrame:view.frame];
        [button addTarget:self action:@selector(pushFeatured) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:button];
        return view;
    }
    else{
        return nil;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 70;
    }
    else{
        return 0;
    }
}

-(void)pushFeatured{
    [Flurry logEvent:@"Featured_Tapped"];
    FeaturedItems *vc = [[FeaturedItems alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)viewDidDisappear:(BOOL)animated{
    PFObject *viewObj = [PFObject objectWithClassName:@"views"];
    [viewObj setObject:self.viewsArray forKey:@"IDs"];
    [viewObj saveEventually:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            NSLog(@"saved!");
            [self.viewsArray removeAllObjects];
        }
        else{
            NSLog(@"error saving views %@", error);
        }
    }];
}

@end
