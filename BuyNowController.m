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
#import "DetailImageController.h"

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
    self.results = [NSMutableArray array];
    self.seenEbayItems = [NSMutableArray array];
    self.searchWords = [NSArray array];
    
    self.pullFinished = YES;
    self.infinFinished = NO;
    self.showRelated = YES;  //if YES show related, if NO don't show CHANGE
    self.ebayEnabled = YES;
    self.viewedItem = NO;
    self.fromInfinEbay = NO;
    [self.anotherPromptButton setHidden:YES];
    
    self.pullSkipped = 0; //CHANGE
    
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
            NSString *shouldShowEbay = [object objectForKey:@"ebayEnabled"];
            if ([shouldShowEbay isEqualToString:@"NO"]) {
                self.ebayEnabled = NO;
            }
        }
        else{
            NSLog(@"error getting latest version %@", error);
        }
    }];
    
    self.tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideItem)];
    self.tap.numberOfTapsRequired = 1;
    
    [self setUpItemView];
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    //put refresh code here so it remembers correct UICollectionView insets - doesn't work in VDL
    [self.tableView addPullToRefreshWithActionHandler:^{
        if (self.pullFinished == YES) {
            [self recommendFromServer];
        }
    }];
    
    self.spinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
    [self.tableView.pullToRefreshView setCustomView:self.spinner forState:SVPullToRefreshStateAll];
    [self.spinner startAnimating];
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        if (self.infinFinished == YES) {
            [self infiniteFromServer];
        }
    }];
}

-(void)getEbayProducts:(NSArray *)objectsToCheck{
    if (self.ebayEnabled == NO) {
        return;
    }
    [self.seenEbayItems removeAllObjects];
    __block int indexNo = 0;
    __block int checker = 0;

//    NSLog(@"objects to check count %lu", (unsigned long)objectsToCheck.count);
    
    for (NSDictionary *wtbDict in objectsToCheck) {
        indexNo++;
        if (self.showRelated == YES && indexNo==1 && self.fromInfinEbay == NO) {
            //related items, move on
            continue;
        }
        else{
            PFObject *WTB = [wtbDict valueForKey:@"WTB"];
            
            NSDictionary *params = @{@"itemTitle": [WTB objectForKey:@"title"], @"price": @1000, @"limit": @5}; //price is ignored atm in cloud code
            
            [PFCloud callFunctionInBackground:@"eBayFetch" withParameters:params block:^(NSDictionary *response, NSError *error) {
                if (!error) {
//                    NSLog(@"ebay response %@", response);
                    checker++;
                    
                    for (NSDictionary *itemDict in response) {
                        //check if item has been surfaced before in this session
                        if ([self.seenEbayItems containsObject:[itemDict valueForKey:@"itemURL"]]) {
                        }
                        else{
                            //insert eBay item to first postiion in match array
                            NSMutableArray *matches = [wtbDict valueForKey:@"matches"];
                            [matches insertObject:itemDict atIndex:0];
                            [wtbDict setValue:matches forKey:@"matches"];
                            [self.seenEbayItems addObject:[itemDict valueForKey:@"itemURL"]];
                            break;
                        }
                    }
                    
                    //objects to check will always be +1 more than checker as it includes the related row in the CV (if showrelated==YES of course!)
                    if (objectsToCheck.count == checker+1 && self.showRelated == YES && self.fromInfinEbay == NO) {
                        [self.tableView reloadData];

                    }
                    else if (objectsToCheck.count == checker && self.showRelated == NO && self.fromInfinEbay == NO){
                        [self.tableView reloadData];

                    }
                    else if (objectsToCheck.count == checker && self.fromInfinEbay == YES){
                        [self.tableView reloadData];

                    }
                    else{
                        //must have more WTBs to search eBay for
                    }
                }
                else{
                    NSLog(@"ebay error %@", error);
                    [self.tableView reloadData];

                }
            }];
        }
    }
}

-(void)getRelatedProducts{
    if (self.showRelated == YES && self.results.count > 0) {
        
        if (self.products.count > 0) {
            //to avoid content offset being remembered & allow CV to scroll to start
            self.reloadingRelated = YES;
        }

        //use holding array to avoid crash for tapping on items which were from previous session
        NSMutableArray *holdingArray = [NSMutableArray array];
        
        PFQuery *productQuery = [PFQuery queryWithClassName:@"Products"];
        if ([[PFUser currentUser]objectForKey:@"wantedWords"]) {
            [productQuery whereKey:@"keywords" containedIn:[[PFUser currentUser]objectForKey:@"wantedWords"]];
        }
        
        //get related key words
        self.searchWords = [[PFUser currentUser]objectForKey:@"searches"];
        NSArray *wantedw = [NSArray array];
        
        if ([[PFUser currentUser]objectForKey:@"wantedWords"]) {
            wantedw = [[PFUser currentUser]objectForKey:@"wantedWords"];
            self.wantedWords = wantedw;
        }
        if (self.searchWords.count > 0 || wantedw.count > 0) {
            NSMutableArray *allSearchWords = [NSMutableArray array];
            //seaprate the searches into search words
            for (NSString *searchTerm in self.searchWords) {
                NSArray *searchTermWords = [[searchTerm lowercaseString] componentsSeparatedByString:@" "];
                //then add all search words to an array in lower case
                [allSearchWords addObjectsFromArray:searchTermWords];
            }
            if ([[PFUser currentUser]objectForKey:@"wantedWords"]) {
                [allSearchWords addObjectsFromArray:[[PFUser currentUser]objectForKey:@"wantedWords"]];
            }
            self.calcdKeywords = [[allSearchWords reverseObjectEnumerator] allObjects];
            
            [productQuery whereKey:@"keywords" containedIn:self.calcdKeywords]; //is the order of these words correct?
        }

        [productQuery whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
        productQuery.limit = 20;
        [productQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                int count = (int)objects.count;
                self.productSkipped = count;
                
                [holdingArray addObjectsFromArray:objects];
    
                [self.productIDs removeAllObjects];
    
                for (PFObject *product in objects) {
                    [self.productIDs addObject:product.objectId];
                }
                
                if (objects.count < 20) {
                    // add more
//                    NSLog(@"we need more products");
                    PFQuery *moreQuery = [PFQuery queryWithClassName:@"Products"];
                    moreQuery.limit = 20-objects.count;
                    if (self.ignoreRelatedShown != YES) {
                        [moreQuery whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
                    }
                    [moreQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                        if (objects) {
                            int count = (int)objects.count;
                            
                            if (count == 0 && self.ignoreRelatedShown != YES) {
                                //try it again ignoring what user has/hasn't seen
                                self.ignoreRelatedShown = YES;
                                [self getRelatedProducts];
                                return;
                            }
                            
                            self.moreProductSkipped = count;
                            
                            NSArray *more = [NSArray arrayWithArray:objects];
                            for (PFObject *product in more) {
                                if (![self.productIDs containsObject:product.objectId]) {
                                    [holdingArray addObject:product];
                                    [self.productIDs addObject:product.objectId];
                                }
                            }
                            [self.products removeAllObjects];
                            [self.products addObjectsFromArray:holdingArray];
//                            NSLog(@"products array %lu", self.products.count);
                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        }
                        else{
                            [self.products addObjectsFromArray:holdingArray];
                            //error getting more so just show the first lot loaded
                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        }
                    }];
                }
                else{
                    [self.products removeAllObjects];
                    [self.products addObjectsFromArray:holdingArray];
                    
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }
            }
            else{
                [self.products removeAllObjects];
                [self.productIDs removeAllObjects];
                NSLog(@"error getting related %@", error);
                [self.results removeObjectAtIndex:0];
                [self.tableView reloadData];
            }
        }];
    }
}

-(void)getMoreRelated{
    if (self.showRelated == YES && self.results.count > 0) {
        
        //use holding array to avoid crash for tapping on items which were from previous session
        NSMutableArray *holdingArray = [NSMutableArray array];
        
        PFQuery *productQuery2 = [PFQuery queryWithClassName:@"Products"];
        if (self.calcdKeywords.count > 0) {
            [productQuery2 whereKey:@"keywords" containedIn:self.calcdKeywords];
        }
        [productQuery2 whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
        productQuery2.limit = 20;
        productQuery2.skip = self.productSkipped;
//        [productQuery2 whereKey:@"objectId" notContainedIn:self.productIDs];
        [productQuery2 findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                int count = (int)objects.count;
                self.productSkipped = self.productSkipped + count;
                
                for (PFObject *product in objects) {
                    if (![self.productIDs containsObject:product.objectId]) {
                        [holdingArray addObject:product];
                        [self.productIDs addObject:product.objectId];
                    }
                }
                
                if (objects.count < 20) {
                    // add more
                    NSLog(@"we need more 'view more' products");
                    PFQuery *moreQuery = [PFQuery queryWithClassName:@"Products"];
                    moreQuery.limit = 20-objects.count;
                    
                    if (self.ignoreRelatedShown != YES) {
                        [moreQuery whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
                    }
                    
                    moreQuery.skip = self.moreProductSkipped;
                    [moreQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                        if (objects) {
                            int count = (int)objects.count;
                            
                            if (count == 0 && self.ignoreRelatedShown != YES) {
                                //try it again ignoring what user has/hasn't seen
                                self.ignoreRelatedShown = YES;
                                [self getMoreRelated];
                                return;
                            }
                            
                            self.moreProductSkipped = self.moreProductSkipped + count;
                            
                            NSArray *more = [NSArray arrayWithArray:objects];
                            for (PFObject *product in more) {
                                if (![self.productIDs containsObject:product.objectId]) {
                                    [holdingArray addObject:product];
                                    [self.productIDs addObject:product.objectId];
                                }
                            }
                            [self.products addObjectsFromArray:holdingArray];
                            
                            NSLog(@"MORE products array %lu", self.products.count);
                            
                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        }
                        else{
                            [self.products addObjectsFromArray:holdingArray];
                            //error getting more so just show the first lot loaded
                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        }
                    }];
                }
                else{

                }
            }
            else{
                NSLog(@"error getting more related %@", error);
            }
        }];
    }
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
    self.pullQuery.limit = 10;
    self.pullQuery.skip = self.pullSkipped;
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
            self.skipped = count + self.pullSkipped;
            
            __block int productCount = 0;
            NSMutableArray *holdingArray = [NSMutableArray array];
            
            for (PFObject *WTB in objects) {
                
                NSArray *wantWords = [WTB objectForKey:@"keywords"];
                int wantNum = (int)wantWords.count;
                
                //call server & pass the number bcoz of array counting bug with cloud code
                NSDictionary *params = @{@"wantedKeywords":wantWords, @"wantNumber":[NSNumber numberWithInt:wantNum]};
                
                [PFCloud callFunctionInBackground:@"productSearch" withParameters:params block:^(NSDictionary *response, NSError *error) {
                    if (!error) {
                        productCount++;
                        
                        NSDictionary *wtbDict = response;
//                        NSLog(@"PRODUCT SEARCH RESP %@", wtbDict);
                        
                        //if matches array key is empty don't recommend anything
                        if ([[wtbDict valueForKey:@"matches"]count]==0){
                            //do nothing as have no matches from our sellers network
                        }
                        else{
                            [wtbDict setValue:WTB forKey:@"WTB"];
                            [holdingArray addObject:wtbDict];
                            NSLog(@"ADDING IN PULL results count in pull %lu", self.results.count);
                        }
                        
                        if (productCount == objects.count) {
                            NSLog(@"finished checking all products");
                            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                                                initWithKey: @"createdAt" ascending: NO];
                            NSArray *sortedArray = [holdingArray sortedArrayUsingDescriptors: [NSArray arrayWithObject:sortDescriptor]];
                            
                            [self.results removeAllObjects];
                            [self.results addObjectsFromArray:sortedArray];
                            
                            if (self.results.count > 0) {
                                NSLog(@"ADDING DIC");
                                self.pullSkipped = 0;
                                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"YES",@"related", nil];
                                [self.results insertObject:dict atIndex:0];
                            }
                            else if (self.results.count == 0){
                                int postNumber = (int)[[PFUser currentUser]objectForKey:@"postNumber"];
                                
                                if (self.pullSkipped <= postNumber) {
                                    NSLog(@"pull again!");
                                    self.pullSkipped = self.pullSkipped + 10; //this should match the limit number //CHANGE
                                    self.pullFinished = YES;
                                    [self recommendFromServer];
                                    return;
                                }
                                else{
                                    NSLog(@"skipped all listings now and still found nothing so show label");
                                }
                                
                                if (!self.topLabel && !self.bottomLabel) {
                                    self.topLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                                    self.topLabel.textAlignment = NSTextAlignmentCenter;
                                    [self.topLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:20]];
                                    self.topLabel.numberOfLines = 1;
                                    self.topLabel.textColor = [UIColor lightGrayColor];
                                    self.topLabel.text = @"No recommended items";
                                    [self.view addSubview:self.topLabel];
                                    
                                    self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+90, 250, 200)];
                                    self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                                    [self.bottomLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:17]];
                                    self.bottomLabel.numberOfLines = 0;
                                    self.bottomLabel.textColor = [UIColor lightGrayColor];
                                    self.bottomLabel.text = @"Don't worry! We're adding more stock everyday, in the meantime check out our Featured Items or create more listings";
                                    [self.view addSubview:self.bottomLabel];
                                }
                                else{
                                    self.topLabel.text = @"No recommended items";
                                    self.bottomLabel.text = @"Don't worry! We're adding more stock everyday, in the meantime check out our Featured Items or create more listings";
                                    
                                    [self.topLabel setHidden:NO];
                                    [self.bottomLabel setHidden:NO];
                                }
                                [self.tableView.pullToRefreshView stopAnimating];
                                self.pullFinished = YES;
                                [self.anotherPromptButton setHidden:NO];
                                [self.anotherPromptButton setTitle:@"C R E A T E  A N O T H E R  L I S T I N G" forState:UIControlStateNormal];
                                return;
                            }
                            
                            [self.tableView reloadData];
                            
                            [self.tableView.pullToRefreshView stopAnimating];
                            self.pullFinished = YES;
                            
                            [self getRelatedProducts];
                            self.fromInfinEbay = NO;
                            if (self.ebayEnabled != NO) {
                                [self getEbayProducts:self.results];
                            }
                        }
                    }
                    else{
                        NSLog(@"ebay error %@", error);
                    }
                }];
            }
        }
    }];
}

-(void)infiniteFromServer{
    if (self.pullFinished == NO || self.infinFinished == NO) {
        NSLog(@"don't run infin");
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
            [self.anotherPromptButton setHidden:NO];
            [self.anotherPromptButton setTitle:@"C R E A T E  A N O T H E R  L I S T I N G" forState:UIControlStateNormal];
            
            if (objects.count == 0) {
//                NSLog(@"got none");
                [self.tableView.infiniteScrollingView stopAnimating];
                self.infinFinished = YES;
                return;
            }
            
            int count = (int)[objects count];
            
//            NSLog(@"GOT %d more WTBs to display", count);
            
            self.skipped = self.skipped + count;
            __block int productCount = 0;
            
            NSMutableArray *holding = [NSMutableArray array];
            
            for (PFObject *WTB in objects) {
                
                NSArray *wantWords = [WTB objectForKey:@"keywords"];
                int wantNum = (int)wantWords.count;
                
                //call server
                NSDictionary *params = @{@"wantedKeywords":wantWords, @"wantNumber":[NSNumber numberWithInt:wantNum]};
                
                [PFCloud callFunctionInBackground:@"productSearch" withParameters:params block:^(NSDictionary *response, NSError *error) {
                    if (!error) {
                        productCount++;
                        
                        NSDictionary *wtbDict = response;
//                        NSLog(@"(INFIN) wtb: %@   matches: %@", [wtbDict valueForKey:@"WTB"], [wtbDict valueForKey:@"matches"]);
                        
                        //if matches array key is empty don't recommend anything
                        if ([[wtbDict valueForKey:@"matches"]count]==0){
                            //do nothing as have no matches from our sellers network
                            NSLog(@"no matches from seller network so don't add this dictionary to array");
                        }
                        else{
                            [wtbDict setValue:WTB forKey:@"WTB"];
                            [holding addObject:wtbDict];
                            NSLog(@"INFIN ADD");
                        }
                        
                        if (productCount == objects.count) {
                            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                                                initWithKey: @"createdAt" ascending: NO];
                            NSArray *sortedArray = [holding sortedArrayUsingDescriptors: [NSArray arrayWithObject:sortDescriptor]];
                            [self.results addObjectsFromArray:sortedArray];
                            
                            if (holding.count == 0 ) {
                                int postNumber = (int)[[PFUser currentUser]objectForKey:@"postNumber"];
                                
                                if (self.skipped <= postNumber) {
                                    NSLog(@"infinite again!");
                                    self.skipped = self.skipped + 10; //this should match the infinite limit number //CHECK
                                    self.infinFinished = YES;
                                    [self infiniteFromServer];
                                    return;
                                }
                                else{
                                    NSLog(@"skipped all listings now and still found nothing so show label");
                                }
                            }
                            
                            [self.tableView.infiniteScrollingView stopAnimating];
                            self.infinFinished = YES;
                            
                            [self.tableView reloadData];
                            
                            if (self.ebayEnabled != NO) {
                                self.fromInfinEbay = YES;
                                [self getEbayProducts:sortedArray];
                            }
                        }
                    }
                    else{
                        NSLog(@"ebay error %@", error);
                    }
                }];
            }
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
    
    cell.wtbTitle.text = @"";
    cell.timeLabel.text = @"";
    
    NSDictionary *wtbDict = [self.results objectAtIndex:indexPath.row];
    PFObject *WTB = [wtbDict valueForKey:@"WTB"];
    
    if ([wtbDict valueForKey:@"related"]) {
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
    return self.results.count;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(RecommendCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setCollectionViewDataSourceDelegate:self indexPath:indexPath];
    
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        //end of loading so reset BOOL
        self.reloadingRelated = NO;
    }
    
    if (self.reloadingRelated == YES && indexPath.row == 0) {
        [cell.collectionView setContentOffset:CGPointMake(0, 0)];
        return;
    }
    
    NSInteger index = cell.collectionView.indexPath.row;
    CGFloat horizontalOffset = [self.contentOffsetDictionary[[@(index) stringValue]] floatValue];
    [cell.collectionView setContentOffset:CGPointMake(horizontalOffset, 0)];
}

-(NSInteger)collectionView:(AFCollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    NSDictionary *wtbDict = [self.results objectAtIndex:collectionView.indexPath.row];

    if ([wtbDict valueForKey:@"related"]) {
        //return number of recommended items
        return self.products.count;
    }
    else{
        NSArray *collectionViewArray = [wtbDict valueForKey:@"matches"];
//        NSLog(@"count of CV Array %lu for this WTB: %@", collectionViewArray.count, [wtbDict valueForKey:@"WTB"]);
        return collectionViewArray.count;
    }
}

-(UICollectionViewCell *)collectionView:(AFCollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ForSaleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.itemView.image = nil;
    NSDictionary *wtbDict = [self.results objectAtIndex:collectionView.indexPath.row];
    
    if ([wtbDict valueForKey:@"related"] && self.showRelated == YES) {
//        NSLog(@"should show a product in this collection view!");
        if (indexPath.row == self.products.count-1 && self.products.count > 1) {
            [cell.itemView setImage:[UIImage imageNamed:@"viewMore"]];
        }
        else{
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
    }
    else{
//        NSArray *collectionViewArray = [self.wtbArray[collectionView.indexPath.row] objectForKey:@"buyNow"];
        
        NSArray *collectionViewArray = [wtbDict valueForKey:@"matches"];
        
//        NSLog(@"collection view array %@", collectionViewArray);
        
        if ([collectionViewArray[indexPath.item]isKindOfClass:[NSDictionary class]]) {
//            NSLog(@"its an ebay item");
            NSDictionary *ebayItem = collectionViewArray[indexPath.item];
            NSURL *imageFileUrl = [[NSURL alloc] initWithString:[ebayItem valueForKey:@"itemImageURL"]];
            NSData *imageData = [NSData dataWithContentsOfURL:imageFileUrl];
            cell.itemView.image = [UIImage imageWithData:imageData];
        }
        else{
            PFObject *WTS = collectionViewArray[indexPath.item];
            [WTS fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    PFObject *WTB = [wtbDict valueForKey:@"WTB"];
                    
                    //setup cell
                    [cell.itemView setFile:[WTS objectForKey:@"thumbnail"]];
                    [cell.itemView loadInBackground];
                    [WTS setObject:WTB forKey:@"WTB"];
                }
                else{
                    NSLog(@"error fetching %@", error);
                }
            }];
            
            if ([self.viewsArray containsObject:WTS.objectId]) {
            }
            else{
                [self.viewsArray addObject:WTS.objectId];
            }
        }
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
    
    if (collectionView.indexPath.row == 0 && self.showRelated == YES) {
        if (indexPath.row == self.products.count-1 && self.products.count > 1) {
            //view more pressed
            [Answers logCustomEventWithName:@"View more tapped in Buy Now Related"
                           customAttributes:@{}];
            
            //load more related products
            [self getMoreRelated];
        }
        else{
            //related tapped
            PFObject *product = self.products[indexPath.item];
            self.listingToView = product;
            if (self.itemView.alpha == 0.0f) {
                NSLog(@"about to show END item");
                self.itemShowing = YES;
                [self clearItemView];
                [self itemViewListingSetup];
                [self showItemView];
            }
            else{
                NSLog(@"already showing end item!");
            }

            [Answers logCustomEventWithName:@"Tapped item for sale"
                           customAttributes:@{
                                              @"itemType":@"related"
                                              }];
        }
    }
    else{
        //normal
        NSDictionary *wtbDict = [self.results objectAtIndex:collectionView.indexPath.row];
        NSArray *collectionViewArray = [wtbDict valueForKey:@"matches"];
        
        if ([collectionViewArray[indexPath.item]isKindOfClass:[NSDictionary class]]) {
            NSLog(@"tapped an ebay item!");
            self.ebayToView = collectionViewArray[indexPath.item];
            if (self.itemShowing != YES || self.itemView.alpha == 0.0f) {
                self.itemShowing = YES;
                [self clearItemView];
                [self ebayListingSetup];
                [self showItemView];
            }
            
            [Answers logCustomEventWithName:@"Tapped item for sale"
                           customAttributes:@{
                                              @"itemType":@"eBay"
                                              }];
        }
        else{
            PFObject *WTS = collectionViewArray[indexPath.item];
            
            [Answers logCustomEventWithName:@"Tapped item for sale"
                           customAttributes:@{
                                              @"itemType":@"sellersNetwork"
                                              }];
            self.viewedItem = YES;
            ForSaleListing *vc = [[ForSaleListing alloc]init];
            vc.listingObject = WTS;
            vc.WTBObject = [WTS objectForKey:@"WTB"];
            vc.source = @"recommended";
            vc.pureWTS = NO;
            NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
            [self presentViewController:nav animated:YES completion:nil];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
        
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Buy Now"
                                      }];
    
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
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Featured"
                                      }];
    
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
    [Answers logCustomEventWithName:@"Create another listing"
                   customAttributes:@{
                                      @"From":@"Buy Now"
                                      }];
    self.tabBarController.selectedIndex = 2;
}

-(void)showSellingAlert{
    if (self.alertShowing == YES) {
        return;
    }
    
    [Answers logCustomEventWithName:@"Sell prompt pressed in buyNow"
                   customAttributes:@{}];
    
    self.alertShowing = YES;
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

-(void)setUpItemView{
    self.itemView = nil;
    self.viewerBg = nil;
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"viewItemView" owner:self options:nil];
    self.itemView = (viewItemClass *)[nib objectAtIndex:0];
    self.itemView.delegate = self;
    self.itemView.alpha = 0.0;
    [[UIApplication sharedApplication].keyWindow addSubview:self.itemView]; //seems to be a bug when using self.view.frame so use application window instead
//    [self.navigationController.view addSubview:self.itemView];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.itemView setFrame:CGRectMake(([UIApplication sharedApplication].keyWindow.frame.size.width/2)-135, -235, 270, 235)];
    }
    else{
        [self.itemView setFrame:CGRectMake(([UIApplication sharedApplication].keyWindow.frame.size.width/2)-148, -234, 295, 234)]; //iPhone 6/7 specific
    }
    
    self.itemView.layer.cornerRadius = 10;
    self.itemView.layer.masksToBounds = YES;
    
    self.viewerBg = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.viewerBg.backgroundColor = [UIColor blackColor];
    self.viewerBg.alpha = 0.0;
    
    [[UIApplication sharedApplication].keyWindow insertSubview:self.viewerBg belowSubview:self.itemView];
    
//    [self.navigationController.view insertSubview:self.viewerBg belowSubview:self.itemView];
    
    NSLog(@"view's frame %@ and %f", NSStringFromCGRect(self.itemView.frame),self.itemView.frame.size.height);
}

-(void)showItemView{
    self.viewedItem = YES;
    [self.navigationItem setRightBarButtonItems:nil animated:YES];
    self.viewerBg.alpha = 0.6;
    [self.itemView setAlpha:1.0];
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.itemView setFrame:CGRectMake(0, 0, 270, 235)];
                            }
                            else{
                                [self.itemView setFrame:CGRectMake(0, 0, 295, 234)];
                            }
                            self.itemView.center = self.view.center;
                        }
                     completion:^(BOOL finished) {
                         self.itemShowing = YES;
                         [self.viewerBg addGestureRecognizer:self.tap];
                     }];
}

-(void)visitPressed{
    [self hideItem];
    NSString *URLString = @"";
    
    if (self.ebayTapped == YES) {
        //goto eBay
        URLString = [self.ebayToView valueForKey:@"itemURL"];
        [Answers logCustomEventWithName:@"Visit Store Pressed"
                       customAttributes:@{
                                          @"retailer":@"eBay"
                                          }];
    }
    else{
        //goto END.
        URLString = [self.listingToView objectForKey:@"link"];
        [Answers logCustomEventWithName:@"Visit Store Pressed"
                       customAttributes:@{
                                          @"retailer":@"END"
                                          }];
    }
    self.web = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
    self.web.showUrlWhileLoading = YES;
    self.web.showPageTitles = YES;
    self.web.doneButtonTitle = @"";
    self.web.paypalMode = NO;
    self.web.infoMode = NO;
    self.web.delegate = self;
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.web];
    [self presentViewController:navigationController animated:YES completion:nil];
}

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

-(void)hideItem{
    [UIView animateWithDuration:0.7
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.itemView setFrame:CGRectMake((self.view.frame.size.width/2)-135,1000, 270, 235)];
                            }
                            else{
                                [self.itemView setFrame:CGRectMake((self.view.frame.size.width/2)-148,1000, 295, 234)]; //iPhone 6/7 specific
                            }
                            [self.viewerBg setAlpha:0.0];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         self.itemShowing = NO;
                         [self.itemView setAlpha:0.0];
                         [self.viewerBg setAlpha:0.0];
                         [self.viewerBg removeGestureRecognizer:self.tap];
                         
                         if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                             //iphone5
                             [self.itemView setFrame:CGRectMake((self.view.frame.size.width/2)-135, -235, 270, 235)];
                         }
                         else{
                             [self.itemView setFrame:CGRectMake((self.view.frame.size.width/2)-148, -234, 295, 234)]; //iPhone 6/7 specific
                         }
                     }];
}

-(void)ebayListingSetup{
    self.ebayTapped = YES;
    [self.itemView.visitButton setTitle:@"V I S I T  E B A Y" forState:UIControlStateNormal];
    NSURL *imageFileUrl = [[NSURL alloc] initWithString:[self.ebayToView valueForKey:@"itemImageURL"]];
    NSData *imageData = [NSData dataWithContentsOfURL:imageFileUrl];
    self.itemView.itemImageView.image = [UIImage imageWithData:imageData];
    
    NSString *currency = [self.ebayToView valueForKey:@"itemCurrency"];
    NSString *symbol = @"";
    if ([currency isEqualToString:@"GBP"]) {
        symbol = @"£";
    }
    else if ([currency isEqualToString:@"USD"]){
        symbol = @"$";
    }
    else if([currency isEqualToString:@"EUR"]){
        symbol = @"€";
    }
    else{
        symbol = currency;
    }
    self.itemView.priceLabel.text = [NSString stringWithFormat:@"%@%@",symbol,[self.ebayToView valueForKey:@"itemPrice"]];
    self.itemView.locationLabel.text = @"-";
    self.itemView.sizeLabel.text = @"-";
    self.itemView.timeLabel.text = @"-";
    self.itemView.descriptionLabel.text = [[self.ebayToView valueForKey:@"itemTitle"] capitalizedString];
}

-(void)itemViewListingSetup{
    self.ebayTapped = NO;
    [self.itemView.visitButton setTitle:@"V I S I T  E N D." forState:UIControlStateNormal];
    [self.listingToView fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (!error) {
            //setup image
            [self.itemView.itemImageView setFile:[self.listingToView objectForKey:@"image1"]];
            [self.itemView.itemImageView loadInBackground];
            
            self.itemView.priceLabel.text = [self.listingToView objectForKey:@"price"];
            self.itemView.locationLabel.text = @"Ships to UK";
            self.itemView.sizeLabel.text = @"Multiple";
            self.itemView.descriptionLabel.text = [NSString stringWithFormat:@"%@ - fulfilled by END.", [self.listingToView objectForKey:@"title"]];
            
            [self calcPostedDate];
            
            [self.listingToView incrementKey:@"views"];
            [self.listingToView saveInBackground];
            
        }
        else{
            NSLog(@"error fetching listing %@", error);
        }
    }];
}
-(void) calcPostedDate{
    NSDate *createdDate = self.listingToView.createdAt;
    NSDate *now = [NSDate date];
    NSTimeInterval distanceBetweenDates = [now timeIntervalSinceDate:createdDate];
    double secondsInAnHour = 3600;
    float minsBetweenDates = (distanceBetweenDates / secondsInAnHour)*60;
    if (minsBetweenDates > 0 && minsBetweenDates < 1) {
        //seconds
        self.itemView.timeLabel.text = [NSString stringWithFormat:@"%.fs ago", (minsBetweenDates*60)];
    }
    else if (minsBetweenDates == 1){
        //1 min
        self.itemView.timeLabel.text = @"1m ago";
    }
    else if (minsBetweenDates > 1 && minsBetweenDates <60){
        //mins
        self.itemView.timeLabel.text = [NSString stringWithFormat:@"%.fm ago", minsBetweenDates];
    }
    else if (minsBetweenDates == 60){
        //1 hour
        self.itemView.timeLabel.text = @"1h ago";
    }
    else if (minsBetweenDates > 60 && minsBetweenDates <1440){
        //hours
        self.itemView.timeLabel.text = [NSString stringWithFormat:@"%.fh ago", (minsBetweenDates/60)];
    }
    else if (minsBetweenDates > 1440 && minsBetweenDates < 2880){
        //1 day
        self.itemView.timeLabel.text = [NSString stringWithFormat:@"%.fd ago", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 2880 && minsBetweenDates < 10080){
        //days
        self.itemView.timeLabel.text = [NSString stringWithFormat:@"%.fd ago", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 10080){
        //weeks
        self.itemView.timeLabel.text = [NSString stringWithFormat:@"%.fw ago", (minsBetweenDates/10080)];
    }
    else{
        //fail safe :D
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setDateFormat:@"MMM YY"];
        
        NSDate *formattedDate = [NSDate date];
        self.itemView.timeLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:formattedDate]];
        dateFormatter = nil;
    }
}

-(void)imagePressed{
    if (self.ebayTapped != YES) {
        //END. so show image
        [self presentDetailImage];
    }
    else{
        //eBay so can't show bigger image
    }
}

-(void)presentDetailImage{
    DetailImageController *vc = [[DetailImageController alloc]init];
    vc.listingPic = YES;
    vc.numberOfPics = 1;
    vc.listing = self.listingToView;
    [self hideItem];
    [self presentViewController:vc animated:YES completion:nil];
}
-(void)clearItemView{
    self.itemView.itemImageView.image = nil;
    self.itemView.priceLabel.text = @"";
    self.itemView.locationLabel.text = @"";
    self.itemView.sizeLabel.text = @"";
    self.itemView.timeLabel.text = @"";
    self.itemView.descriptionLabel.text = @"";
}
@end
