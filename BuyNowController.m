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
#import <Crashlytics/Crashlytics.h>
#import "ChatWithBump.h"

@interface BuyNowController ()

@end

@implementation BuyNowController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"B U Y  N O W";
    
    self.tableView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"RecommendCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
     UIBarButtonItem *sellingButton = [[UIBarButtonItem alloc] initWithTitle:@"Sell" style:UIBarButtonItemStylePlain target:self action:@selector(showSellingAlert)];
    [self.navigationItem setLeftBarButtonItem:sellingButton];

    
    self.contentOffsetDictionary = [NSMutableDictionary dictionary];
    
    self.wtbArray = [NSMutableArray array];
    self.viewsArray = [NSMutableArray array];
    self.products = [NSMutableArray array];
    
    self.pullFinished = YES;
    self.infinFinished = NO;
    self.showRelated = YES;  //if YES show related, if NO don't show
    self.viewedItem = NO;
    [self.anotherPromptButton setHidden:YES];
    
    // Option 1
    // Load user's latest 5 WTBs
    // for each WTB search for the WTS posts which have the most keywords in common (if none then don't show)
    // save pointers to those WTSs on the WTB object as Recommendation key
    // so it's a case of displaying the objects for this key in cell for item
    
    PFQuery *versionQuery = [PFQuery queryWithClassName:@"versions"];
    [versionQuery orderByDescending:@"createdAt"];
    [versionQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            NSString *shouldShowRelated = [object objectForKey:@"relatedShow"];
            if ([shouldShowRelated isEqualToString:@"NO"]) {
                self.showRelated = NO;
            }
        }
        else{
            NSLog(@"error getting latest version %@", error);
        }
    }];
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

-(void)recommendFromServer{
    if (self.pullFinished == NO) {
        return;
    }
    [self.anotherPromptButton setHidden:YES];
    self.pullFinished = NO;
    self.viewedItem = NO;
    NSLog(@"PULL LOADING");
    
    [self.topLabel setHidden:YES];
    [self.bottomLabel setHidden:YES];
    [self.tableView.infiniteScrollingView stopAnimating];
    
    self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
    [self.pullQuery whereKey:@"postUser" equalTo:[PFUser currentUser]];
    [self.pullQuery whereKey:@"status" equalTo:@"live"];
    self.pullQuery.limit = 1;
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
                    self.topLabel.text = @"No listings";
                    [self.view addSubview:self.topLabel];
                    
                    self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+90, 250, 200)];
                    self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                    [self.bottomLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:17]];
                    self.bottomLabel.numberOfLines = 0;
                    self.bottomLabel.textColor = [UIColor lightGrayColor];
                    self.bottomLabel.text = @"Create listings by hitting the + button so we can suggest relevant products to buy right now from sellers on Bump";
                    [self.view addSubview:self.bottomLabel];
                }
                else{
                    self.topLabel.text = @"No listings";
                    self.bottomLabel.text = @"Create listings by hitting the + button so we can suggest relevant products to buy right now from sellers on Bump";
                    
                    [self.topLabel setHidden:NO];
                    [self.bottomLabel setHidden:NO];
                }
                [self.tableView.pullToRefreshView stopAnimating];
                self.pullFinished = YES;
                [self.anotherPromptButton setHidden:NO];
                [self.anotherPromptButton setTitle:@"C R E A T E  A  L I S T I N G" forState:UIControlStateNormal];
                return;
            }
            [self.anotherPromptButton setHidden:YES];
            
            NSLog(@"got WTBs: %lu", objects.count);
            
            for (PFObject *WTB in objects) {
                
                //call server
                NSDictionary *params = @{@"wantedKeywords": [WTB objectForKey:@"keywords"]};
                
                [PFCloud callFunctionInBackground:@"productSearch" withParameters:params block:^(NSDictionary *response, NSError *error) {
                    if (!error) {
                        NSLog(@"search response %@", response);
                    }
                    else{
                        NSLog(@"ebay error %@", error);
                    }
                }];
                
            }
        }
    }];
}

-(void)loadWTBs{
    if (self.pullFinished == NO) {
        return;
    }
    [self.anotherPromptButton setHidden:YES];
    self.pullFinished = NO;
    self.viewedItem = NO;
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
                    self.topLabel.text = @"No listings";
                    [self.view addSubview:self.topLabel];
                    
                    self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+90, 250, 200)];
                    self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                    [self.bottomLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:17]];
                    self.bottomLabel.numberOfLines = 0;
                    self.bottomLabel.textColor = [UIColor lightGrayColor];
                    self.bottomLabel.text = @"Create listings by hitting the + button so we can suggest relevant products to buy right now from sellers on Bump";
                    [self.view addSubview:self.bottomLabel];
                }
                else{
                    self.topLabel.text = @"No listings";
                    self.bottomLabel.text = @"Create listings by hitting the + button so we can suggest relevant products to buy right now from sellers on Bump";
                    
                    [self.topLabel setHidden:NO];
                    [self.bottomLabel setHidden:NO];
                }
                [self.tableView.pullToRefreshView stopAnimating];
                self.pullFinished = YES;
                [self.anotherPromptButton setHidden:NO];
                [self.anotherPromptButton setTitle:@"C R E A T E  A  L I S T I N G" forState:UIControlStateNormal];
                return;
            }
            [self.anotherPromptButton setHidden:YES];

            NSLog(@"got WTBs: %lu", objects.count);
            
            int count = (int)[objects count];
            self.skipped = count;
            
            __block int WTBCheck = 0;

            NSMutableArray *wtbHoldingArray = [NSMutableArray array];
            
            //get keywords for each WTB and find a WTS that has a good match
            for (PFObject *WTB in objects) {
                
                NSArray *WTBKeywords = [WTB objectForKey:@"keywords"];
                
                //clear array before adding new
                [WTB removeObjectForKey:@"buyNow"];
                
                PFQuery *WTSQuery = [PFQuery queryWithClassName:@"forSaleItems"];
                [WTSQuery whereKey:@"status" equalTo:@"live"];
                [WTSQuery whereKey:@"keywords" containedIn:WTBKeywords];
                [WTSQuery orderByDescending:@"createdAt"];
                [WTSQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (objects) {
                        WTBCheck++;

                        for (PFObject *forSale in objects) {
                            NSArray *WTSKeywords = [forSale objectForKey:@"keywords"];
                            NSMutableSet* set1 = [NSMutableSet setWithArray:WTBKeywords];
                            NSMutableSet* set2 = [NSMutableSet setWithArray:WTSKeywords];
                            [set1 intersectSet:set2]; //this will give you only the obejcts that are in both sets
                            
                            NSArray* result = [set1 allObjects];
                            
                            NSLog(@"result %@", result);
                            
                            //calc 80% of WTB keyword match
                            float sixty = WTBKeywords.count*0.8;
                            int roundedFloat = roundf(sixty);
                            
                            if (result.count >= roundedFloat && roundedFloat>0 ) { //&& result.count >2 CHANGE
                                [WTB addObject:forSale forKey:@"buyNow"];
                            }
                        }
                        
                        NSArray *matches = [WTB objectForKey:@"buyNow"];
                        
                        if (matches.count > 0) {
                            [wtbHoldingArray addObject:WTB];
                        }

                        if (count == WTBCheck) {
                            
                            //done last one, now reload
                            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                                                initWithKey: @"createdAt" ascending: NO];
                            NSArray *sortedArray = [wtbHoldingArray sortedArrayUsingDescriptors: [NSArray arrayWithObject:sortDescriptor]];
                            
                            [self.wtbArray removeAllObjects];
                            [self.wtbArray addObjectsFromArray:sortedArray];
                            
                            NSLog(@"got this many WTBs %lu", self.wtbArray.count);
                            
                            //labels
                            if (self.wtbArray.count == 0) {
                                [self.anotherPromptButton setHidden:NO];
                                [self.anotherPromptButton setTitle:@"C R E A T E  A N O T H E R  L I S T I N G" forState:UIControlStateNormal];

                                if (!self.topLabel && !self.bottomLabel) {
                                    self.topLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                                    self.topLabel.textAlignment = NSTextAlignmentCenter;
                                    [self.topLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:18]];
                                    self.topLabel.numberOfLines = 1;
                                    self.topLabel.textColor = [UIColor lightGrayColor];
                                    self.topLabel.text = @"No recommended items";
                                    [self.view addSubview:self.topLabel];
                                    
                                    self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+90, 250, 200)];
                                    self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                                    [self.bottomLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:15]];
                                    self.bottomLabel.numberOfLines = 0;
                                    self.bottomLabel.textColor = [UIColor lightGrayColor];
                                    self.bottomLabel.text = @"We're adding products daily so check back soon for recommended products based on your wanted items - Create another listing or check out the Featured items";
                                    [self.view addSubview:self.bottomLabel];
                                }
                                else{
                                    self.topLabel.text = @"No recommended items";
                                    self.bottomLabel.text = @"We're adding products daily so check back soon for recommended products based on your wanted items - Create another listing or check out the Featured items";

                                    [self.topLabel setHidden:NO];
                                    [self.bottomLabel setHidden:NO];
                                }
                            }
                            else{
                                [self.topLabel setHidden:YES];
                                [self.bottomLabel setHidden:YES];
                                
                                if (self.showRelated == YES) {
                                    //clear products first to avoid crash for tapping on items which were from previous session
                                    [self.products removeAllObjects];
                                    
                                    PFQuery *productQuery = [PFQuery queryWithClassName:@"Products"];
                                    if ([[PFUser currentUser]objectForKey:@"wantedWords"]) {
                                        [productQuery whereKey:@"keywords" containedIn:[[PFUser currentUser]objectForKey:@"wantedWords"]];
                                    }
                                    [productQuery whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
                                    productQuery.limit = 20;
                                    [productQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                                        if (objects) {
                                            //once got objects just reload the related cell
                                            NSLog(@"got products");
                                            [self.products addObjectsFromArray:objects];
                                            
                                            [self.productIDs removeAllObjects];
                                            for (PFObject *product in objects) {
                                                [self.productIDs addObject:product.objectId];
                                            }
                                            
                                            if (objects.count < 20) {
                                                // add more
                                                NSLog(@"we need more products");
                                                PFQuery *moreQuery = [PFQuery queryWithClassName:@"Products"];
                                                moreQuery.limit = 20-objects.count;
                                                [moreQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                                                    if (objects) {
                                                        NSArray *more = [NSArray arrayWithArray:objects];
                                                        for (PFObject *product in more) {
                                                            if (![self.productIDs containsObject:product.objectId]) {
                                                                [self.products addObject:product];
                                                                [self.productIDs addObject:product.objectId];
                                                            }
                                                        }
                                                        
                                                        NSLog(@"products array %lu", self.products.count);
                                                        
                                                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
                                                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                                    }
                                                    else{
                                                        //error getting more so just show the first lot loaded
                                                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
                                                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                                    }
                                                }];
                                            }
                                            else{
                                                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
                                                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                            }
                                        }
                                        else{
                                            NSLog(@"error getting related %@", error);
                                            //remove related cell since its empty
                                            [self.wtbArray removeObjectAtIndex:1];
                                            [self.tableView reloadData];
                                        }
                                    }];
                                    
                                    PFObject *relatedObject = [PFObject objectWithClassName:@"wantobuys"];
                                    [relatedObject setObject:@"related" forKey:@"field"];
                                    [self.wtbArray insertObject:relatedObject atIndex:1];
                                }
                            }
                            
                            NSRange range = NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView]);
                            NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:range];
                            [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
                            
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
            [self.anotherPromptButton setHidden:NO];
            [self.anotherPromptButton setTitle:@"C R E A T E  A N O T H E R  L I S T I N G" forState:UIControlStateNormal];

//            NSLog(@"infinite: got %u WTBs", objects.count);
            
            int count = (int)[objects count];
            self.skipped = self.skipped + count;
            __block int WTBCheck = 0;
            __block int infinMatches = 0;
            
            //get keywords for each WTB and find a WTS that has a good match
            for (PFObject *WTB in objects) {
                
                NSArray *WTBKeywords = [WTB objectForKey:@"keywords"];
                
                //clear array before adding new
                [WTB removeObjectForKey:@"buyNow"];
                
                PFQuery *WTSQuery = [PFQuery queryWithClassName:@"forSaleItems"];
                [WTSQuery whereKey:@"status" equalTo:@"live"];
                [WTSQuery whereKey:@"keywords" containedIn:WTBKeywords];
                [WTSQuery orderByDescending:@"createdAt"];
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
                            float sixty = WTBKeywords.count*0.8;
                            int roundedFloat = roundf(sixty);

                            if (result.count >= roundedFloat && roundedFloat>0 && result.count >2) {
                                //WTB has at least 2 matching keywords to this WTS and 70% keywords match
//                                NSLog(@"WTB: %@     WTS: %@", [WTB objectForKey:@"title"], [forSale objectForKey:@"description"]);
                                [WTB addObject:forSale forKey:@"buyNow"];
                                infinMatches++;
                            }
                        }
                        
                        if ([WTB objectForKey:@"buyNow"]) {
//                            NSLog(@"for sale item(s) added for this WTB %@", [WTB objectForKey:@"title"]);
                            [self.wtbArray addObject:WTB];
                            [WTB saveInBackground];
                        }
                        if (count == WTBCheck) {
                            //done last one, now reload
                            if (infinMatches == 0) {
                                NSLog(@"no matches found, run again to check if any other WTBs left to check");
                                [self infiniteloadWTBs];
                                return;
                            }
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
    
    if ([WTB objectForKey:@"field"]) {
        cell.wtbTitle.text = @"R E L A T E D";
        cell.timeLabel.text = @"";
        [cell.wtbTitle setTextColor:[UIColor blackColor]];
        [cell.wtbTitle setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
        return cell;
    }
    [cell.wtbTitle setTextColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0]];
    [cell.wtbTitle setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:14]];
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
    if (![self.wtbArray[collectionView.indexPath.row] objectForKey:@"field"]) {
        NSArray *collectionViewArray = [self.wtbArray[collectionView.indexPath.row] objectForKey:@"buyNow"];
        return collectionViewArray.count;
    }
    else{
        //return number of recommended items
        return self.products.count;
    }
}

-(UICollectionViewCell *)collectionView:(AFCollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ForSaleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.itemView.image = nil;

    if (collectionView.indexPath.row == 1 && self.showRelated == YES) {
        PFObject *product = self.products[indexPath.item];
        
        PFFile *imgFile = [product objectForKey:@"thumbnail"];
        [cell.itemView setFile:imgFile];
        [cell.itemView loadInBackground];
        
        NSArray *shownTo = [product objectForKey:@"shownTo"];
        if (![shownTo containsObject:[[PFUser currentUser]objectId]]) {
            [product addObject:[[PFUser currentUser]objectId] forKey:@"shownTo"];
            [product saveInBackground];
        }
    }
    else{
        NSArray *collectionViewArray = [self.wtbArray[collectionView.indexPath.row] objectForKey:@"buyNow"];
        
        NSLog(@"collection view array %@", collectionViewArray);
        
        PFObject *WTS = collectionViewArray[indexPath.item];
        if ([self.viewsArray containsObject:WTS.objectId]) {
        }
        else{
            [self.viewsArray addObject:WTS.objectId];
        }
        
        PFObject *WTB = [self.wtbArray objectAtIndex:self.currentIndexPath.row];

        //setup cell
        [cell.itemView setFile:[WTS objectForKey:@"thumbnail"]];
        [cell.itemView loadInBackground];
        [WTS setObject:WTB forKey:@"WTB"];
    }
    
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
    
    
    self.viewedItem = YES;
    ForSaleListing *vc = [[ForSaleListing alloc]init];
    
    if (collectionView.indexPath.row == 1 && self.showRelated == YES) {
        //related tapped
        PFObject *product = self.products[indexPath.item];
        
        vc.listingObject = product;
        vc.source = @"related";
        vc.pureWTS = NO;
        vc.relatedProduct = YES;
        
        [Answers logContentViewWithName:@"For Sale Item Selected"
                            contentType:@"Related"
                              contentId:product.objectId
                       customAttributes:@{}];
    }
    else{
        //normal
        NSArray *collectionViewArray = [self.wtbArray[collectionView.indexPath.row] objectForKey:@"buyNow"];
        PFObject *WTS = collectionViewArray[indexPath.item];
        
        [Answers logContentViewWithName:@"For Sale Item Selected"
                            contentType:@"Recommended"
                              contentId:WTS.objectId
                       customAttributes:@{}];
        
        vc.listingObject = WTS;
        vc.WTBObject = [WTS objectForKey:@"WTB"];
        vc.source = @"recommended";
        vc.pureWTS = NO;
    }
    
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [Answers logContentViewWithName:@"Buy Now Tapped"
                        contentType:@""
                          contentId:@""
                   customAttributes:@{}];
    
    [self.infiniteQuery cancel];
    [self.tableView.infiniteScrollingView stopAnimating];
    self.infinFinished = YES;
    
    if (self.viewedItem == YES) {
        self.viewedItem = NO;
    }
    else{
        [self recommendFromServer];
    }

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"viewMorePressed"] == YES) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"viewMorePressed"];
    }
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
    [Answers logContentViewWithName:@"Featured Tapped"
                        contentType:@""
                          contentId:@""
                   customAttributes:@{}];
    
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

- (IBAction)anotherPromptPressed:(id)sender {
    self.tabBarController.selectedIndex = 2;
}

-(void)showSellingAlert{
    self.searchBgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
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
    self.customAlert.titleLabel.text = @"Are you a big seller?";
    self.customAlert.messageLabel.text = @"If you've got your own BigCartel with a reasonable amount of stock send us a message to get selling on Bump";
    self.customAlert.numberOfButtons = 2;
    
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
                         [self.customAlert setAlpha:0.0];
                         self.customAlert = nil;
                     }];
}

-(void)firstPressed{
    [self donePressed];
}
-(void)secondPressed{
    [self donePressed];
    //goto Team Bump messages
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"teamConvos"];
    NSString *convoId = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
    [convoQuery whereKey:@"convoId" equalTo:convoId];
    [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //convo exists, go there
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
@end
