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

@interface BuyNowController ()

@end

@implementation BuyNowController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Buy it now";
    
    NSArray *colours = [NSArray arrayWithObjects:[UIColor redColor],[UIColor greenColor],[UIColor blueColor],[UIColor redColor],[UIColor greenColor],[UIColor blueColor],[UIColor redColor],[UIColor greenColor],[UIColor blueColor],[UIColor redColor],[UIColor greenColor],[UIColor blueColor], nil];
    
    self.colorArray = [NSArray arrayWithObjects:colours,colours,colours, nil];
    
    self.tableView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"RecommendCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    self.contentOffsetDictionary = [NSMutableDictionary dictionary];
    
    self.wtbArray = [NSMutableArray array];
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
    [self.topLabel setHidden:YES];
    [self.bottomLabel setHidden:YES];
    
    self.pullFinished = NO;
    self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
    [self.pullQuery whereKey:@"postUser" equalTo:[PFUser currentUser]];
    [self.pullQuery whereKey:@"status" equalTo:@"live"];
    self.pullQuery.limit = 10;
    [self.pullQuery orderByDescending:@"createdAt"];
    [self.pullQuery cancel];
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            if (objects.count == 0) {
                if (!self.topLabel && !self.bottomLabel) {
                    self.topLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                    self.topLabel.textAlignment = NSTextAlignmentCenter;
                    [self.topLabel setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:20]];
                    self.topLabel.numberOfLines = 1;
                    self.topLabel.textColor = [UIColor lightGrayColor];
                    self.topLabel.text = @"No WTBs!";
                    [self.view addSubview:self.topLabel];
                    
                    self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+90, 250, 200)];
                    self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                    [self.bottomLabel setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:17]];
                    self.bottomLabel.numberOfLines = 0;
                    self.bottomLabel.textColor = [UIColor lightGrayColor];
                    self.bottomLabel.text = @"Create WTBs by hitting the + icon so we can suggest relevant products to buy right now from sellers on Bump";
                    [self.view addSubview:self.bottomLabel];
                }
                else{
                    self.topLabel.text = @"No WTBs!";
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
            [self.wtbArray removeAllObjects];
            
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
                            
                            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                                                initWithKey: @"createdAt" ascending: NO];
                            
                            NSArray *sortedArray = [self.wtbArray sortedArrayUsingDescriptors: [NSArray arrayWithObject:sortDescriptor]];
                            
                            [self.wtbArray removeAllObjects];
                            [self.wtbArray addObjectsFromArray:sortedArray];
                            
                            if (self.wtbArray.count == 0) {
                                if (!self.topLabel && !self.bottomLabel) {
                                    self.topLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                                    self.topLabel.textAlignment = NSTextAlignmentCenter;
                                    [self.topLabel setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:20]];
                                    self.topLabel.numberOfLines = 1;
                                    self.topLabel.textColor = [UIColor lightGrayColor];
                                    self.topLabel.text = @"No recommended items";
                                    [self.view addSubview:self.topLabel];
                                    
                                    self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+50, 250, 200)];
                                    self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                                    [self.bottomLabel setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:17]];
                                    self.bottomLabel.numberOfLines = 0;
                                    self.bottomLabel.textColor = [UIColor lightGrayColor];
                                    self.bottomLabel.text = @"We're adding items everyday so check back soon";
                                    [self.view addSubview:self.bottomLabel];
                                }
                                else{
                                    self.topLabel.text = @"No recommended items";
                                    self.bottomLabel.text = @"We're adding items everyday so check back soon";

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
    if (self.pullFinished == NO) {
        return;
    }
    [self.topLabel setHidden:YES];
    [self.bottomLabel setHidden:YES];
    
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
            NSLog(@"infinite: got %lu WTBs", objects.count);
            
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
                            float sixty = WTBKeywords.count*0.7;
                            NSLog(@" float %f", sixty);
                            int roundedFloat = roundf(sixty);
                            NSLog(@"rounded float %d", roundedFloat);
                            NSLog(@"results count %lu", (unsigned long)result.count);
                            
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
    
    NSLog(@"array of wtbs %@", self.wtbArray);
    
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
    
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
//    NSArray *collectionViewArray = self.colorArray[collectionView.indexPath.row];
    NSArray *collectionViewArray = [self.wtbArray[collectionView.indexPath.row] objectForKey:@"buyNow"];
    
    return collectionViewArray.count;
}

-(UICollectionViewCell *)collectionView:(AFCollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
//    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];

    ForSaleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];

    NSArray *collectionViewArray = [self.wtbArray[collectionView.indexPath.row] objectForKey:@"buyNow"];
//    cell.backgroundColor = collectionViewArray[indexPath.item];
//    NSLog(@"in this collection view %@", collectionViewArray[indexPath.item]);
    
    PFObject *WTS = collectionViewArray[indexPath.item];
    PFObject *WTB = [self.wtbArray objectAtIndex:self.currentIndexPath.row];
    
    cell.saleImageView.image = nil;
    
    //set placeholder spinner view
    MBProgressHUD __block *hud = [MBProgressHUD showHUDAddedTo:cell.saleImageView animated:YES];
    hud.square = YES;
    hud.mode = MBProgressHUDModeCustomView;
    hud.color = [UIColor whiteColor];
    DGActivityIndicatorView __block *spinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
    hud.customView = spinner;
    [spinner startAnimating];
    
    //setup cell
    [cell.saleImageView setFile:[WTS objectForKey:@"image1"]];
    [cell.saleImageView loadInBackground:^(UIImage * _Nullable image, NSError * _Nullable error) {
        
    } progressBlock:^(int percentDone) {
        if (percentDone == 100) {
            //remove spinner
            [spinner stopAnimating];
            [MBProgressHUD hideHUDForView:cell.saleImageView animated:NO];
            spinner = nil;
            hud = nil;
        }
    }];
    
    [WTS setObject:WTB forKey:@"WTB"];
    
    cell.saleImageView.layer.cornerRadius = 35;
    cell.saleImageView.layer.masksToBounds = YES;
    cell.saleImageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    cell.saleImageView.contentMode = UIViewContentModeScaleAspectFill;

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
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

@end
