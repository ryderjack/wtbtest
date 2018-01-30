//
//  ExploreVC.m
//  
//
//  Created by Jack Ryder on 29/02/2016.
//
//

#import "ExploreVC.h"
#import "NavigationController.h"
#import <Crashlytics/Crashlytics.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "AppConstant.h"
#import "UserProfileController.h"
#import "ContainerViewController.h"
#import "Tut1ViewController.h"
#import "ChatWithBump.h"
#import <StoreKit/StoreKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "AddSizeController.h"
#import "eventDetailController.h"
#import <StoreKit/StoreKit.h>
#import "mainApprovedSellerController.h"
#import "SmallWantedCell.h"

@interface ExploreVC ()

@end

@implementation ExploreVC

@synthesize locationManager = _locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.noForSaleItemLabel setHidden:YES];
    [self.noWantedListingLabel setHidden:YES];
    
    self.wantedCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    [self.tableView setContentInset:UIEdgeInsetsMake(-20, 0, 0, 0)];
    
    //set table view header
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"HomeHeaderView" owner:self options:nil];
    self.headerView = (HomeHeaderView *)[nib objectAtIndex:0];
    self.headerView.delegate = self;
    self.headerView.backgroundColor = [UIColor greenColor];
    self.tableView.tableHeaderView = self.headerView;

    //OBSERVERS
    //navigation
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBump:) name:@"showBumpedVC" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showListing:) name:@"listingBumped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showReleasePage:) name:@"showRelease" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSellerApp) name:@"showSellerApp" object:nil];

    //update data
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetHome) name:@"refreshHome" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertLatestListing:) name:@"justPostedListing" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLatestListing:) name:@"latestListingBoosted" object:nil];
    
    //drop down
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBumpDrop:) name:@"showBumpedDropDown" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageSentDrop:) name:@"messageSentDropDown" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showScreenShot:) name:@"screenshotDropDown" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDrop:) name:@"showDropDown" object:nil];
    
    //pop up triggers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setUpRateViewWithNav:) name:@"showRate" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showInviteView) name:@"showInvite" object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setUpEngagementViewWithNav:) name:@"showEngageQ" object:nil];

    //in-app purchase observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseComplete:) name:@"purchaseComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseFailedExplore:) name:@"purchaseFailed" object:nil];
    
//    [self.collectionView setCollectionViewLayout:flowLayout];
//    self.collectionView.delegate = self;
//    self.collectionView.alwaysBounceVertical = YES;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    //setup arrays
    self.wantedMatches = [[NSMutableArray alloc]init];
    self.sellingMatches = [[NSMutableArray alloc]init];
    self.homeItems = [NSArray array];
    
    //setup header
//    [self.collectionView registerClass:[UICollectionReusableView class]
//            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
//                   withReuseIdentifier:@"HeaderView"];
    
    //location stuff
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"askedForLocationPermission"] || [[[PFUser currentUser]objectForKey:@"completedReg"]isEqualToString:@"YES"]) {
        
        //for users that have already seen the location diaglog before this update - use the completedReg BOOL to check
        if ([[NSUserDefaults standardUserDefaults]boolForKey:@"askedForLocationPermission"]==NO) {
            [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"askedForLocationPermission"];
        }
        self.locationAllowed = [CLLocationManager locationServicesEnabled];
        [self startLocationManager];
    }
    
    //refresh setup of queries
    self.featuredMode = YES;
    self.pullFinished = YES;
    self.infinFinished = YES;
    self.lastInfinSkipped = 0;
    
    self.pullLimit = 12;
    self.infinLimit = 12;
    
    self.filtersON = NO; 
    self.ignoreShownTo = NO;
    
    [self.tableView setScrollsToTop:YES];
    
    self.filtersArray = [NSMutableArray array];
    
    //setup swipe views
    self.wantedSwipeView.delegate = self;
    self.wantedSwipeView.dataSource = self;
    self.wantedSwipeView.clipsToBounds = YES;
    self.wantedSwipeView.pagingEnabled = YES;
    self.wantedSwipeView.truncateFinalPage = YES;
    
    self.sellingSwipeView.delegate = self;
    self.sellingSwipeView.dataSource = self;
    self.sellingSwipeView.clipsToBounds = YES;
    self.sellingSwipeView.pagingEnabled = YES;
    self.sellingSwipeView.truncateFinalPage = YES;
    
    [self getWantedMatches];
    
    // set searchbar font
    NSDictionary *searchAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                      NSFontAttributeName, nil];
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setDefaultTextAttributes:searchAttributes];
    
    if (![FBSDKAccessToken currentAccessToken]) {
        NSLog(@"invalid token in VDL");
        //invalid access token
        [PFUser logOut];
        WelcomeViewController *vc = [[WelcomeViewController alloc]init];
        vc.delegate = self;
        self.welcomeShowing = YES;
        NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else{
        //get updated friends list
//        NSLog(@"get friends list");
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:@"me/friends/?limit=5000"
                                      parameters:@{@"fields": @"id, name"}
                                      HTTPMethod:@"GET"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
            // Handle the result
            if (!error) {
                NSArray* friends = [result objectForKey:@"data"];
                NSLog(@"Found: %lu friends with bump installed", (unsigned long)friends.count);
                NSMutableArray *friendsHoldingArray = [NSMutableArray array];
                
                for (NSDictionary *friend in friends) {
                    [friendsHoldingArray addObject:[friend objectForKey:@"id"]];
                }
                
                [[PFUser currentUser]setObject:friendsHoldingArray forKey:@"friends"];
                [[PFUser currentUser] saveInBackground];
            }
            else{
                NSLog(@"error on friends %li", (long)error.code);
                if (error.code == 8) {
                    //invalid access token
                    [PFUser logOut];
                    WelcomeViewController *vc = [[WelcomeViewController alloc]init];
                    vc.delegate = self;
                    self.welcomeShowing = YES;
                    NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
                    [self presentViewController:navController animated:YES completion:nil];
                }
                else{
                    [self showError];
                }
            }
        }];
    }
    
    PFUser *currentUser = [PFUser currentUser];

    if (currentUser) {
        NSLog(@"got a current user");
        if (![[currentUser objectForKey:@"completedReg"] isEqualToString:@"YES"]) {
            [Answers logCustomEventWithName:@"Registration error"
                           customAttributes:@{
                                              @"error":@"hasn't completed reg",
                                              @"user":currentUser.username
                                              }];
            [PFUser logOut];
            WelcomeViewController *vc = [[WelcomeViewController alloc]init];
            vc.delegate = self;
            self.welcomeShowing = YES;
            NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:navController animated:NO completion:nil];
        }
        
        //check if all essential info saved from reg - if not then let them do it again
        
        else if (![currentUser objectForKey:PF_USER_FULLNAME] || ![currentUser objectForKey:PF_USER_EMAIL] || ![currentUser objectForKey:@"currency"] || ![currentUser objectForKey:PF_USER_FACEBOOKID] || currentUser.username.length >20) { //CHECK
            //been an error on sign up as user doesn't have all info saved / error with username
            
            [Answers logCustomEventWithName:@"Registration error"
                           customAttributes:@{
                                              @"error":@"lack of info",
                                              @"user":currentUser.username
                                              }];
            
            currentUser[@"completedReg"] = @"NO";
            [currentUser saveInBackground];
            [PFUser logOut];
            WelcomeViewController *vc = [[WelcomeViewController alloc]init];
            self.welcomeShowing = YES;
            NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:navController animated:NO completion:nil];
        }
        else{
            //user has signed up fine, do final checks
//            NSLog(@"user has signed up fine, lets do final checks");
            
            //check if any of their reminder times have been updated
            if ([currentUser objectForKey:@"remindersArray"]) {
                NSArray *remindersArray = [currentUser objectForKey:@"remindersArray"];
                
                if (remindersArray.count > 0) {
                    
                    PFQuery *releaseQuery = [PFQuery queryWithClassName:@"Releases"];
                    [releaseQuery whereKey:@"itemTitle" containedIn:remindersArray];
                    [releaseQuery whereKey:@"status" equalTo:@"live"];
                    [releaseQuery whereKey:@"timeUpdated" equalTo:@"YES"];
                    [releaseQuery whereKey:@"timeUpdatedUsers" notEqualTo:currentUser.objectId];
                    [releaseQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                        if (objects) {
//                            NSLog(@"releases to reschedule: %@", objects);
                            
                            //for each update release 1) cancel local push  2) reschedule
                            
                            for (PFObject *release in objects) {
                                
                                [Answers logCustomEventWithName:@"Updating Release Time"
                                               customAttributes:@{}];
                                
                                //cancel old local push
                                NSArray *notificationArray = [[UIApplication sharedApplication] scheduledLocalNotifications];
                                
                                for(UILocalNotification *notification in notificationArray){
                                    if ([notification.alertBody containsString:[release objectForKey:@"itemTitle"]]) {
                                        // delete this notification
//                                        NSLog(@"delete this notification");
                                        [[UIApplication sharedApplication] cancelLocalNotification:notification];
                                    }
                                }
                                
                                //reschedule new local push
                                
                                NSCalendar *theCalendar = [NSCalendar currentCalendar];
                                NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
                                
                                UILocalNotification *localNotification = [[UILocalNotification alloc]init];
                                NSString *releaseTime = [release objectForKey:@"releaseTimeString"];
                            
//                                NSLog(@"NEW RELEASE TIME: %@", releaseTime);
                                
                                NSString *reminderString = [NSString stringWithFormat:@"Reminder: the '%@' drops at %@ - Swipe to cop!", [release objectForKey:@"itemTitle"],releaseTime];
                                
                                //attach the title to the notification so can be queried and link added to web view when swiped
                                NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:[release objectForKey:@"itemTitle"],@"itemTitle",nil];
                                localNotification.userInfo = userDict;
                                
                                //set alert 10 mins before
                                NSDate *dropDate = [release objectForKey:@"releaseDateWithTime"];
                                dayComponent.minute = -10;
                                NSDate *dateToFire = [theCalendar dateByAddingComponents:dayComponent toDate:dropDate options:0];
                                [localNotification setFireDate: dateToFire];
                                [localNotification setAlertBody:reminderString];
                                [localNotification setTimeZone: [NSTimeZone localTimeZone]];
                                [localNotification setRepeatInterval: 0];
                                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                                
                                //update each Release object's timeUpdatedUsers array with this user's objectID
                                [release addObject:currentUser.objectId forKey:@"timeUpdatedUsers"];
                                //save Release object
                                [release saveInBackground];
                            }
                        }
                        else{
                            NSLog(@"error getting updated releases %@", error);
                        }
                    }];
                }
            }
            
            //check if declined push permissions and if need to ask again
            if ([[NSUserDefaults standardUserDefaults]boolForKey:@"declinedPushPermissions"]== YES && [[currentUser objectForKey:@"completedReg"] isEqualToString:@"YES"]) {
                [self checkPushStatus];
            }
            
            // just always clear purchase queue when restart app to be safe
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"processingPurchase"];
            
            //check for purchases that failed to save so must try again
            NSArray *failedPurchases = [NSArray arrayWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:@"failedPurchases"]];
            
            if (failedPurchases.count > 0) {
                for (NSDictionary *dict in failedPurchases) {
                    NSLog(@"about to resave this failed purchase %@", dict);
                    [self saveFailedBoostWithDict:dict];
                }
            }

            //check if deals data has saved, otherwise create & save
            if (![currentUser objectForKey:@"dealsSaved"]) {
                PFQuery *dealsQuery = [PFQuery queryWithClassName:@"deals"];
                [dealsQuery whereKey:@"User" equalTo:currentUser];
                [dealsQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                    if (object) {
                        //already have deals info saved
                        currentUser[@"dealsSaved"] = @"YES";
                        [currentUser saveInBackground];
                    }
                    else{
                        //no deals info
                        PFObject *dealsData = [PFObject objectWithClassName:@"deals"];
                        [dealsData setObject:[PFUser currentUser] forKey:@"User"];
                        [dealsData setObject:@0 forKey:@"star1"];
                        [dealsData setObject:@0 forKey:@"star2"];
                        [dealsData setObject:@0 forKey:@"star3"];
                        [dealsData setObject:@0 forKey:@"star4"];
                        [dealsData setObject:@0 forKey:@"star5"];
                        
                        [dealsData setObject:@0 forKey:@"dealsTotal"];
                        [dealsData setObject:@0 forKey:@"currentRating"];
                        [dealsData saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                            if (succeeded) {
                                currentUser[@"dealsSaved"] = @"YES";
                                [currentUser saveInBackground];
                            }
                        }];
                    }
                }];
            }

            //check if have lowercase fullname
            if (![currentUser objectForKey:@"fullnameLower"]) {
                //for search purposes so can search by name!
                currentUser[@"fullnameLower"] = [[[PFUser currentUser]objectForKey:@"fullname"]lowercaseString];
                [currentUser saveInBackground];
            }
            
            //check if bumps have been migrated to new system introduced in Build: 1156
            if (![[PFUser currentUser]objectForKey:@"bumpArray"]) {
                PFQuery *bumps = [PFQuery queryWithClassName:@"wantobuys"];
                [bumps whereKey:@"bumpArray" containsString:currentUser.objectId];
                [bumps findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (objects) {
                        if (objects.count == 0) {
                            currentUser[@"bumpArray"] = @[];
                        }
                        else{
                            NSMutableArray *placeholderBumps = [NSMutableArray array];
                            
                            //check for duplicates
                            for (PFObject *WTB in objects) {
                                if (![placeholderBumps containsObject:WTB.objectId]) {
                                    [placeholderBumps addObject:WTB.objectId];
                                }
                            }
                            currentUser[@"bumpArray"] = placeholderBumps;
                        }
                        [currentUser saveInBackground];
                    }
                    else{
                        NSLog(@"error finding previous bumps so reset %@", error);
                        currentUser[@"bumpArray"] = @[];
                        [currentUser saveInBackground];
                    }
                }];
            }
            
            //check if they have wanted words
            if (![currentUser objectForKey:@"wantedWords"]) {
                PFQuery *myPosts = [PFQuery queryWithClassName:@"wantobuys"];
                [myPosts whereKey:@"postUser" equalTo:currentUser];
                [myPosts orderByDescending:@"lastUpdated"];
                myPosts.limit = 10;
                [myPosts findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (objects) {
                        NSMutableArray *wantedWords = [NSMutableArray array];
                        
                        for (PFObject *listing in objects) {
                            NSArray *keywords = [listing objectForKey:@"searchKeywords"];
                            
                            for (NSString *word in keywords) {
                                if (![wantedWords containsObject:word]) {
                                    [wantedWords addObject:word];
                                }
                            }
                        }
//                        NSLog(@"wanted words: %@", wantedWords);
                        [currentUser setObject:wantedWords forKey:@"wantedWords"];
                        [currentUser saveInBackground];
                    }
                    else{
                        NSLog(@"nee posts pet");
                    }
                }];
            }
            
            //check if their listings have been indexed for Buy Now 2.0
            if (![currentUser objectForKey:@"indexedListings"]) {
                
                PFQuery *usersListings = [PFQuery queryWithClassName:@"wantobuys"];
                [usersListings whereKey:@"postUser" equalTo:currentUser];
                [usersListings orderByDescending:@"createdAt"];
                usersListings.limit = 500;
                [usersListings findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (objects) {
                     
                        int indexCount = 0;
                        for (PFObject *listing in objects) {
                            [listing setObject:[NSNumber numberWithInt:indexCount] forKey:@"index"];
                            [listing saveInBackground];
                            indexCount++;
                        }
                        currentUser[@"indexedListings"] = @"YES";
                        [currentUser saveInBackground];
                    }
                    else{
                        NSLog(@"error fetching user's listings to index %@", error);
                    }
                }];
            }
            
            //check if have the boost message
            if (![currentUser objectForKey:@"freeFirstBoost"]) {
                [self sendFreeBoostMessage];
            }
            
            // finally check if they've been banned - put it last because otherwise if logout user from a previous user check this will still run and throw error 'can't do a comparison query for type (null)
            
            PFQuery *bannedQuery = [PFQuery queryWithClassName:@"bannedUsers"];
            [bannedQuery whereKey:@"user" equalTo:[PFUser currentUser]];
            [bannedQuery countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
                if (number >= 1) {
                    //user is banned - log them out
                    
                    [Answers logCustomEventWithName:@"Logging Banned User Out"
                                   customAttributes:@{
                                                      @"from":@"ExploreLoad"
                                                      }];
                    
                    [PFUser logOut];
                    WelcomeViewController *vc = [[WelcomeViewController alloc]init];
                    vc.delegate = self;
                    self.welcomeShowing = YES;
                    NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
                    [self presentViewController:navController animated:NO completion:nil];
                }
            }];
        }
    }
    self.uselessWords = [NSArray arrayWithObjects:@"x",@"to",@"with",@"and",@"the",@"wtb",@"or",@" ",@".",@"very",@"interested", @"in",@"wanted", @"", nil];

    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    PFQuery *versionQuery = [PFQuery queryWithClassName:@"versions"];
    [versionQuery orderByDescending:@"createdAt"];
    [versionQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            NSString *latest = [object objectForKey:@"number"];
            
            //add in a check if user was created in past 2 days
            //only show update prompt if created later than that
            //to protect against the update crossover period
            
            NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:currentUser.createdAt];
            double secondsInADay = 86400;
            NSInteger daysSinceSigningUp = distanceBetweenDates / secondsInADay;
            
            if (daysSinceSigningUp > 2) {
                //can prompt now
                if (![appVersion isEqualToString:latest]) {
                    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"New update available" message:nil preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                        [Answers logCustomEventWithName:@"Cancel Update pressed"
                                       customAttributes:@{
                                                          @"page":@"Explore",
                                                          @"userVersion":appVersion,
                                                          @"updateVersion":latest
                                                          }];
                    }]];
                    [alertView addAction:[UIAlertAction actionWithTitle:@"Update" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        [Answers logCustomEventWithName:@"Update pressed"
                                       customAttributes:@{
                                                          @"page":@"Explore"
                                                          }];
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:
                                                                    @"itms-apps://itunes.apple.com/app/id1096047233"]];
                    }]];
                    [self presentViewController:alertView animated:YES completion:nil]; //change
                }
            }
        }
        else{
            NSLog(@"error getting latest version %@", error);
        }
    }];
    
    
    //dismiss Invite gesture
    self.tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideInviteView)];
    self.tap.numberOfTapsRequired = 1;
    
    
//    [PFUser logOut]; //CHECK
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//-(void)didMoveToParentViewController:(UIViewController *)parent {
//    [super didMoveToParentViewController:parent];
//    //put refresh code here so it remembers correct UICollectionView insets - doesn't work in VDL
//    [self.tableView addPullToRefreshWithActionHandler:^{
//        if (self.pullFinished == YES) {
////            [self queryParsePullWithRecall:NO];
//        }
//    }];
//
//     self.spinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
//    [self.tableView.pullToRefreshView setCustomView:self.spinner forState:SVPullToRefreshStateAll];
//    [self.spinner startAnimating];
////
////    [self.tableView addInfiniteScrollingWithActionHandler:^{
////        if (self.infinFinished == YES) {
//////            [self queryParseInfinite];
////        }
////    }];
//}

//- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
//    return UIEdgeInsetsMake(8, 8, 8, 8); // top, left, bottom, right
//}

- (CGSize) collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(60.0f, 275.0f);// width is ignored
}



-(void)viewWillAppear:(BOOL)animated{
        
    [self.navigationController.navigationBar setHidden:YES];
    
    if (![PFUser currentUser]) {
        WelcomeViewController *vc = [[WelcomeViewController alloc]init];
        vc.delegate = self;
        self.welcomeShowing = YES;
        NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navController animated:NO completion:nil];
    }
    else{
        if (self.gotCarousel != YES) {
            [self getCarouselData];
        }

        self.currency = [[PFUser currentUser]objectForKey:@"currency"];
        if ([self.currency isEqualToString:@"GBP"]) {
            self.currencySymbol = @"£";
        }
        else if ([self.currency isEqualToString:@"EUR"]) {
            self.currencySymbol = @"€";
        }
        else if ([self.currency isEqualToString:@"USD"]) {
            self.currencySymbol = @"$";
        }
    }
    
    if (!self.infiniteQuery) {
        self.infiniteQuery = [PFQuery queryWithClassName:@"wantobuys"];
    }
    if (!self.pullQuery && [PFUser currentUser]) {
        self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
//        [self queryParsePullWithRecall:NO];
    }
    
    [self.infiniteQuery cancel];
//    [self.tableView.infiniteScrollingView stopAnimating];
    self.infinFinished = YES;
    
    if (self.listingTapped == YES) {
        
//        NSLog(@"LASTSELECTED ROW %ld     numberofitems: %ld  last selected section: %ld      lastselected: %@", (long)self.lastSelected.row,(long)[self.collectionView numberOfItemsInSection:0],(long)self.lastSelected.section,self.lastSelected);
        
        self.listingTapped = NO; //set to NO so this ^ won't be happening (shouldn't)...
//        
//        if ([self.collectionView numberOfItemsInSection:0] > self.lastSelected.row && self.lastSelected.section == 0 && self.lastSelected) { //was >= but remember the .row number starts at index 0 so if its equal it still accessing an item which isnt there
//            //saw another crash here
//            [self.collectionView reloadItemsAtIndexPaths:@[self.lastSelected]];
//        }
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.hidesBarsOnSwipe = NO;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
//    self.navigationController.hidesBarsOnSwipe = YES;
    
//    [self.collectionView.infiniteScrollingView stopAnimating];
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Explore"
                                      }];
    
    if (self.filtersArray.count > 0) {
        [self.filterButton setTitle:[NSString stringWithFormat:@"F I L T E R S  %lu",self.filtersArray.count] forState:UIControlStateNormal];
    }
    
    BOOL modalPresent = (self.presentedViewController);
    if ([PFUser currentUser] && modalPresent != YES) {
        
        //for showing pop ups
        if (![[[PFUser currentUser] objectForKey:@"searchIntro"] isEqualToString:@"YES"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"viewMorePressed"] != YES && [[[PFUser currentUser] objectForKey:@"completedReg"] isEqualToString:@"YES"]) {
            
            if (modalPresent != YES) {
                [self setUpIntroAlert];
            }
            //trigger location for first sign in
            [self parseLocation];
        }
        
        //if user redownloaded - ask for push/location permissions again
        else if ([[NSUserDefaults standardUserDefaults]boolForKey:@"askedForPushPermission"] == NO && [[[PFUser currentUser] objectForKey:@"completedReg"]isEqualToString:@"YES"] && [[NSUserDefaults standardUserDefaults]boolForKey:@"declinedPushPermissions"] != YES && modalPresent != YES) {
            
            [self parseLocation];
            [self showPushReminder]; //this is showing when user redownloads and opens app - before they've logged in
        }
        //check if user has entered sizes
        else if (![[PFUser currentUser]objectForKey:@"sizeCountry"] && modalPresent != YES) {
            AddSizeController *vc = [[AddSizeController alloc]init];
            [self.navigationController presentViewController:vc animated:YES completion:nil];
        }
        else{
            [self checkIfBanned];
        }
    }
}

#pragma mark - custom header

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    
    if (!self.headerView) {
        self.headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                             withReuseIdentifier:@"Home"
                                                                    forIndexPath:indexPath];
        self.headerView.delegate = self;
        self.headerView.itemsArray = self.homeItems;
    }

    self.segmentedControl = [[HMSegmentedControl alloc] init];
    self.segmentedControl.frame = CGRectMake(self.headerView.headerSegmentControl.frame.origin.x,self.headerView.headerSegmentControl.frame.origin.y,[UIApplication sharedApplication].keyWindow.frame.size.width,  self.headerView.headerSegmentControl.frame.size.height);
    self.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
    self.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
    self.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
    self.segmentedControl.selectionIndicatorColor = [UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0];
    self.segmentedControl.titleTextAttributes = @{NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Medium" size:10]};
    self.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]};
    self.segmentedControl.backgroundColor = [UIColor whiteColor];
    [self.segmentedControl setSectionTitles:@[@"💎  F E A T U R E D",@"🔥  T R E N D I N G"]];


    [self.headerView addSubview:self.segmentedControl];

    if (self.latestMode == YES) {
        [self.segmentedControl setSelectedSegmentIndex:1];
    }

    [self.segmentedControl addTarget:self action:@selector(segmentControlChanged) forControlEvents:UIControlEventValueChanged];
    
    return self.headerView;
}

//-(void)queryParseInfinite{
//    if (self.pullFinished == NO) {
//        return;
//    }
////    NSLog(@"infinity last skipped %d", self.lastInfinSkipped);
//    self.infiniteQuery = nil;
//    self.infiniteQuery = [PFQuery queryWithClassName:@"wantobuys"];
//
//    self.infinFinished = NO;
//    self.infiniteQuery.limit = self.infinLimit;
//    self.infiniteQuery.skip = self.lastInfinSkipped;
//    [self.infiniteQuery whereKey:@"status" equalTo:@"live"];
//
//    if (self.latestMode == YES) {
//        
//        //check if in CMO mode
//        if ([[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"]|| [[PFUser currentUser].objectId isEqualToString:@"IIEf7cUvrO"]) {
//            //CMO switch setup
//            if ([[NSUserDefaults standardUserDefaults]boolForKey:@"CMOModeOn"]==YES) {
//                //just get the latest
//                [self.infiniteQuery orderByDescending:@"createdAt,bumpCount"];
//            }
//            else{
//                //normal latest code
//                [self.infiniteQuery orderByDescending:@"lastUpdated,bumpCount"];
//                if (self.ignoreShownToLatest == NO) {
//                    [self.infiniteQuery whereKey:@"objectId" notContainedIn:[[PFUser currentUser]objectForKey:@"seenListings"]];
//                    //            [self.infiniteQuery whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
//                }
//            }
//        }
//        else{
//            [self.infiniteQuery orderByDescending:@"lastUpdated,bumpCount"];
//            if (self.ignoreShownToLatest == NO) {
//                [self.infiniteQuery whereKey:@"objectId" notContainedIn:[[PFUser currentUser]objectForKey:@"seenListings"]];
//                //            [self.infiniteQuery whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
//            }
//        }
//    }
//    else{
//        if (self.featuredMode == YES) {
//            [self.infiniteQuery whereKey:@"featuredBoost" equalTo:@"YES"];
//            [self.infiniteQuery orderByAscending:@"boostViews,featuredBoostExpiry"];
//            [self.infiniteQuery whereKey:@"objectId" notContainedIn:[[PFUser currentUser]objectForKey:@"seenFeatured"]];
//        }
//        
//        //suggested mode
//        else if (self.cleverMode == YES) {
//            [self.infiniteQuery whereKey:@"searchKeywords" containedIn:self.calcdKeywords];
//            [self.infiniteQuery orderByDescending:@"bumpCount,views"];
//            if (self.ignoreShownTo != YES) {
//                [self.infiniteQuery whereKey:@"objectId" notContainedIn:[[PFUser currentUser]objectForKey:@"seenListings"]];
////                [self.infiniteQuery whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
//            }
//        }
//        else{
//            //clever mode off
//            [self.infiniteQuery orderByDescending:@"lastUpdated,bumpCount"];
//        }
//    }
//
//    [self setupInfinQuery];
//    [self.infiniteQuery cancel];
//    [self.infiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//        if (objects) {
//            int count = (int)[objects count];
//            NSLog(@"infin count %d", count);
//            
//            self.lastInfinSkipped = self.lastInfinSkipped + count;
//            
//            
//            if (count < self.infinLimit) {
//                // count < limit
//                
////                NSLog(@"got less than we need!");
//
//                //add objects to array but check if there first
//                for (PFObject *listing in objects) {
//                    if (![self.resultIDs containsObject:listing.objectId]) {
//                        [self.results addObject:listing];
//                        [self.resultIDs addObject:listing.objectId];
//                    }
//                }
//                
//                //is it feature mode? -> turn off, change the query limit, turn on 'incompletePrevPull' and recall
//                if (self.featuredMode == YES && self.latestMode == NO) {
//                    
////                    NSLog(@"turn featured mode off and recall");
//                    [[PFUser currentUser]setObject:@[] forKey:@"seenFeatured"];
//                    [[PFUser currentUser]saveEventually];
//
//                    self.featuredMode = NO;
//                    self.lastInfinSkipped = 0;
//
//                    self.infinLimit = self.infinLimit - count;
//                    self.infinIncompletePreviousPull = YES;
//                    [self queryParseInfinite];
//                    return;
//                }
//                //is it clever mode? -> is ignoreShownTo on? -> start to ignore, turn on 'incompletePrevPull' & recall
//                if (self.cleverMode == YES && self.latestMode == NO) {
//                    
////                    NSLog(@"turn clever mode off and recall");
//                    
//                    [[PFUser currentUser]setObject:@[] forKey:@"seenListings"];
//                    [[PFUser currentUser]saveEventually];
//
//                    self.cleverMode = NO;
//                    self.lastInfinSkipped = 0;
//                    
//                    self.infinLimit = self.infinLimit - count;
//                    self.infinIncompletePreviousPull = YES;
//                    [self queryParseInfinite];
//                    return;
//                }
//                
//                //is latest mode on
//                else if (self.latestMode == YES && self.ignoreShownToLatest != YES){
//                    
//                    self.ignoreShownToLatest = YES;
//                    
//                    self.infinLimit = self.infinLimit - count;
//                    self.infinIncompletePreviousPull = YES;
//                    [self queryParseInfinite];
//                    return;
//                    
//                }
//                
//            }
//            else{
//                
//                //add to results array
//                for (PFObject *listing in objects) {
//                    if (![self.resultIDs containsObject:listing.objectId]) {
//                        [self.results addObject:listing];
//                        [self.resultIDs addObject:listing.objectId];
//                    }
//                }
//                
//                self.infinIncompletePreviousPull = NO;
//            }
//            
//            //reset limit
//            self.infinLimit = 12;
//
//            [self.collectionView reloadData];
//            [self.collectionView.infiniteScrollingView stopAnimating];
//            self.infinFinished = YES;
//        }
//        else{
//            NSLog(@"error %@", error);
//            self.infinFinished = YES;
//            [self showError];
//        }
//    }];
//}
//-(void)queryParsePullWithRecall:(BOOL)recall{
//    
//    if (self.pullFinished != YES && recall == NO) {
//        return;
//    }
//    
//    //reset the query to remove the home screen constraints
//    self.pullQuery = nil;
//    self.pullQuery = [PFQuery queryWithClassName:@"wantobuys"];
//    self.pullFinished = NO;
//    self.pullQuery.limit = self.pullLimit;
//    
//    if (self.recallMode == YES) {
//        self.recallMode = NO;
//    }
//    else{
//        self.featuredMode = YES;
//    }
//    
//    if (self.latestMode == YES) {
//        
//        //check if in CMO mode
//        if ([[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"]|| [[PFUser currentUser].objectId isEqualToString:@"IIEf7cUvrO"]) {
//            //CMO switch setup
//            if ([[NSUserDefaults standardUserDefaults]boolForKey:@"CMOModeOn"]==YES) {
//                //just get the latest
//                [self.pullQuery orderByDescending:@"createdAt,bumpCount"];
//            }
//            else{
//                //normal latest code
//                [self.pullQuery orderByDescending:@"lastUpdated,bumpCount"];
//                if (self.ignoreShownToLatest == NO ) {
//                    //            [self.pullQuery whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
//                    [self.pullQuery whereKey:@"objectId" notContainedIn:[[PFUser currentUser]objectForKey:@"seenListings"]];
//                }
//            }
//            
//        }
//        else{
//            [self.pullQuery orderByDescending:@"lastUpdated,bumpCount"];
//            if (self.ignoreShownToLatest == NO ) {
//                //            [self.pullQuery whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
//                [self.pullQuery whereKey:@"objectId" notContainedIn:[[PFUser currentUser]objectForKey:@"seenListings"]];
//            }
//        }
//    }
//    else{
//        
//        if (self.featuredMode == YES) {
//            [self.pullQuery whereKey:@"featuredBoost" equalTo:@"YES"];
//            [self.pullQuery orderByAscending:@"boostViews,featuredBoostExpiry"]; //CHECK if expiry is way to go here
//            [self.pullQuery whereKey:@"objectId" notContainedIn:[[PFUser currentUser]objectForKey:@"seenFeatured"]];
//        }
//        else{
//            //intelligent Home
//            //to avoid retrieving featured items already seen
//            [self.pullQuery whereKey:@"featuredBoost" notEqualTo:@"YES"];
//
//            //use previous searches/wants to inform what listings people see
//            self.searchWords = [[PFUser currentUser]objectForKey:@"searches"];
//            NSArray *wantedw = [NSArray array];
//            if ([[PFUser currentUser]objectForKey:@"wantedWords"]) {
//                wantedw = [[PFUser currentUser]objectForKey:@"wantedWords"];
//                self.wantedWords = wantedw;
//            }
//            
//            //check if got any words to inform search
//            if (self.searchWords.count > 0 || wantedw.count > 0) {
//                NSMutableArray *allSearchWords = [NSMutableArray array];
//                //seaprate the searches into search words
//                for (NSString *searchTerm in self.searchWords) {
//                    NSArray *searchTermWords = [[searchTerm lowercaseString] componentsSeparatedByString:@" "];
//                    //then add all search words to an array in lower case
//                    [allSearchWords addObjectsFromArray:searchTermWords];
//                }
//                if ([[PFUser currentUser]objectForKey:@"wantedWords"]) {
//                    [allSearchWords addObjectsFromArray:[[PFUser currentUser]objectForKey:@"wantedWords"]];
//                }
//                self.calcdKeywords = [[allSearchWords reverseObjectEnumerator] allObjects];
//                
//                //add basic search terms in case only posted WTB/searched for 1 thing, which limits results
//                NSMutableArray *baseArray = [NSMutableArray arrayWithArray:self.calcdKeywords];
//                [baseArray addObject:@"supreme"];
//                self.calcdKeywords = baseArray;
//                
//                [self.pullQuery whereKey:@"searchKeywords" containedIn:self.calcdKeywords];
//                if (self.ignoreShownTo == NO) {
//                    [self.pullQuery whereKey:@"objectId" notContainedIn:[[PFUser currentUser]objectForKey:@"seenListings"]];
//                }
//                [self.pullQuery orderByDescending:@"bumpCount,views"];
//            }
//            else{
//                //has no previous searches so show most recent
//                self.calcdKeywords = @[@"supreme", @"yeezy", @"palace", @"stone", @"patta", @"adidas"];
//                [self.pullQuery whereKey:@"searchKeywords" containedIn:self.calcdKeywords];
//                [self.pullQuery orderByDescending:@"lastUpdated,bumpCount"];
//                if (self.ignoreShownTo == NO) {
//                    [self.pullQuery whereKey:@"objectId" notContainedIn:[[PFUser currentUser]objectForKey:@"seenListings"]];
//                    //                [self.pullQuery whereKey:@"shownTo" notEqualTo:[[PFUser currentUser]objectId]];
//                }
//            }
//        }
//    }
//
//    [self setupPullQuery];
//    [self.pullQuery whereKey:@"status" equalTo:@"live"];
//    [self.pullQuery cancel];
//    
////    NSLog(@"limit to retrieve %d", self.pullLimit);
//    
//    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//        if (objects) {
//            int count = (int)[objects count];
//            
//            [self.noresultsLabel setHidden:YES];
//            [self.noResultsImageView setHidden:YES];
//            
////            NSLog(@"PULL OBJECTS COUNT: %d", count);
//            
//            self.lastInfinSkipped = count; //CHECK what about the skip no.
//            
//            //check if count returned is 0 to decide on showing 'no results' label
//            if (count == 0 && self.ignoreShownToLatest == YES && self.latestMode == YES ){
//                // no more latest results!!!
//                
////                NSLog(@"ran out in latest");
//                
//                [self.noresultsLabel setHidden:NO];
//                [self.noResultsImageView setHidden:YES];
//                
//                [self.results removeAllObjects];
//                [self.resultsPlaceholder removeAllObjects];
//                [self.resultIDs removeAllObjects];
//
//                [self.collectionView reloadData];
//                return;
//                
//            }
//            
//            //another check for 0 here for the featured tab //CHECK
//            if (count == 0 && self.featuredMode == NO && self.ignoreShownTo == YES && self.latestMode == NO) {
//                //ran out of everything!
//                
////                NSLog(@"completely ran out");
//                
//                [self.noresultsLabel setHidden:NO];
//                [self.noResultsImageView setHidden:YES];
//                
//                [self.results removeAllObjects];
//                [self.resultsPlaceholder removeAllObjects];
//                [self.resultIDs removeAllObjects];
//
//                [self.collectionView reloadData];
//                return;
//            }
//            
//            //check if count returned is < limit & recall if needed
//            if (count < self.pullLimit) {
//                
////                NSLog(@"got less than we need!");
//                
//                //got < limit
//                
//                //check if have already added items to results array from an incomplete pullQuery
//                if (self.incompletePreviousPull != YES) {
//                    [self.resultsPlaceholder removeAllObjects];
//                    [self.resultIDs removeAllObjects];
//                }
//                
//                //add objects to array but check if there first
//                for (PFObject *listing in objects) {
//                    if (![self.resultIDs containsObject:listing.objectId]) {
//                        [self.resultsPlaceholder addObject:listing];
//                        [self.resultIDs addObject:listing.objectId];
//                    }
//                }
//                
//                //is it feature mode? -> turn off, change the query limit, turn on 'incompletePrevPull' and recall
//                if (self.featuredMode == YES && self.latestMode == NO) {
//                    
////                    NSLog(@"time to recall pull as we're out of featured");
//                    
//                    [[PFUser currentUser]setObject:@[] forKey:@"seenFeatured"];
//                    [[PFUser currentUser]saveEventually];
//                
//                    self.featuredMode = NO;
//                    self.recallMode = YES; //to stop setting featured back on
//                    
//                    self.pullLimit = self.pullLimit - (int)objects.count;
//                    self.incompletePreviousPull = YES;
//                    [self queryParsePullWithRecall:YES];
//                    return;
//                }
//                //is it clever mode? -> is ignoreShownTo on? -> start to ignore, turn on 'incompletePrevPull' & recall
//                if (self.ignoreShownTo == NO && self.latestMode == NO) {
//                    
////                    NSLog(@"time to recall pull as we're out of unseen listings");
//
//                    self.ignoreShownTo = YES;
//                    
//                    [[PFUser currentUser]setObject:@[] forKey:@"seenListings"];
//                    [[PFUser currentUser]saveEventually];
//                    
//                    //CHECK is this needed now?
//                    
////                    if (self.triedAlready != YES) {
////                        self.triedAlready = YES;
////                        [self queryParsePull];
////                        return;
////                    }
//                    
//                    self.pullLimit = self.pullLimit - (int)objects.count;
//                    self.incompletePreviousPull = YES;
//                    [self queryParsePullWithRecall:YES];
//                    return;
//                }
//                
//                if (self.ignoreShownTo == YES && self.latestMode == NO) {
//                    self.lastInfinSkipped = 0;
//                    self.cleverMode = NO;
//                }
//                
//            }
//            else{
//                
//                //got limit
//                if (self.latestMode != YES && self.featuredMode == NO) {
//                    self.cleverMode = YES;
//                }
//                
//                //reset limit & other variables
//                self.ignoreShownTo = NO;
//
//                //check if have already added items to results array from an incomplete pullQuery
//                if (self.incompletePreviousPull != YES) {
//                    [self.resultsPlaceholder removeAllObjects];
//                    [self.resultIDs removeAllObjects];
//                }
//                
//                self.incompletePreviousPull = NO;
//                
//                for (PFObject *listing in objects) {
//                    [self.resultIDs addObject:listing.objectId];
//                    [self.resultsPlaceholder addObject:listing];
//                }
//                
//            }
//            
//            [self.results removeAllObjects];
//            [self.results addObjectsFromArray:self.resultsPlaceholder];
//            
//            self.pullLimit = 12;
//
//            //refresh collection view & end loading animations
//            [self.collectionView performBatchUpdates:^{
//                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
//            } completion:nil];
//            
//            [self.collectionView.pullToRefreshView stopAnimating];
//            self.pullFinished = YES;
//        }
//        else{
//            NSLog(@"error on pull %@", error);
//
//            self.pullLimit = 12;
//
//            [self.collectionView.pullToRefreshView stopAnimating];
//            self.pullFinished = YES;
//            
//            if (error.code == 209) {
//                //invalid access token
//                [PFUser logOut];
//                WelcomeViewController *vc = [[WelcomeViewController alloc]init];
//                vc.delegate = self;
//                NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
//                self.welcomeShowing = YES;
//                [self presentViewController:navController animated:YES completion:nil];
//            }
//            else{
//                [self showError];
//            }
//        }
//    }];
//}
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
                                          message:@"Enable location services in settings to view WTBs nearby!"
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
                //get location
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
            double latitude = geoPoint.latitude;
            double longitude = geoPoint.longitude;
            
            CLLocation *loc = [[CLLocation alloc]initWithLatitude:latitude longitude:longitude];
            CLGeocoder *geocoder = [[CLGeocoder alloc]init];
            [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                if (placemarks) {
                    CLPlacemark *placemark = [placemarks lastObject];
                    NSString *titleString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.ISOcountryCode];
                    
                    if (![titleString containsString:@"(null)"]) { //protect against saving when user hasn't granted location permission
                        [[PFUser currentUser]setObject:titleString forKey:@"profileLocation"];
                        [[PFUser currentUser]saveInBackground];
                    }
                }
                else{
                    NSLog(@"error %@", error);
                }
            }];
        }
        else{
            NSLog(@"no geopoint %@", error);
        }
    }];
}
- (IBAction)filterPressed:(id)sender {
    [Answers logCustomEventWithName:@"Filters pressed"
                   customAttributes:@{
                                      @"page":@"Explore"
                                      }];
    
    FilterVC *vc = [[FilterVC alloc]init];
    vc.delegate = self;
    if (self.filtersArray.count > 0) {
        vc.sendArray = [NSMutableArray arrayWithArray:self.filtersArray];
    }
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)noChange{
    if (self.filtersArray > 0) {
        self.filterButton.titleLabel.text = [NSString stringWithFormat:@"F I L T E R S  %lu",self.filtersArray.count];
    }
}

//-(void)filtersReturned:(NSMutableArray *)filters{
//    [self.results removeAllObjects];
//    [self.resultIDs removeAllObjects];
//
//    [self.collectionView reloadData];
//    self.filtersArray = filters;
//    if (self.filtersArray.count > 0) {
//        self.filtersON = YES;
//        NSLog(@"got some filters brah %lu", self.filtersArray.count);
//        self.filterButton.titleLabel.text = [NSString stringWithFormat:@"F I L T E R S  %lu",self.filtersArray.count];
//        self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1];
//        [self.filterButton setHidden:NO];
//        [self.filterBGView setHidden:NO];
//    }
//    else{
//        self.filtersON = NO;
//        self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
//        [self.filterButton setHidden:YES];
//        [self.filterBGView setHidden:YES];
//    }
//    self.lastInfinSkipped = 0;
//
//    NSLog(@"filters array in explore %@", self.filtersArray);
//    
//    //if array is empty from a 'no results' search then don't scroll to top to avoid crashing as there's 0 index paths to scroll to!
//    if (self.results.count != 0) {
////        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
////                                    atScrollPosition:UICollectionViewScrollPositionTop
////                                            animated:NO];
//        
//    }
//
//    [self queryParsePullWithRecall:NO];
//}

-(void)setupInfinQuery{
    if (self.filtersArray.count > 0) {
//        if ([self.filtersArray containsObject:@"hightolow"]) {
//            [self.infiniteQuery orderByDescending:[NSString stringWithFormat:@"listingPrice%@", self.currency]];
//        }
//        else if ([self.filtersArray containsObject:@"lowtohigh"]){
//            [self.infiniteQuery orderByAscending:[NSString stringWithFormat:@"listingPrice%@", self.currency]];
//        }
        
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
}
-(void)setupPullQuery{
    if (self.filtersArray.count > 0) {
//        if ([self.filtersArray containsObject:@"hightolow"]) {
//            [self.pullQuery orderByDescending:[NSString stringWithFormat:@"listingPrice%@", self.currency]];
//        }
//        else if ([self.filtersArray containsObject:@"lowtohigh"]){
//            [self.pullQuery orderByAscending:[NSString stringWithFormat:@"listingPrice%@", self.currency]];
//        }
        
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
}

//-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
//    
//    if (!self.lastSelected) {
//        self.lastSelected = [[NSIndexPath alloc]init];
//    }
//    self.lastSelected = indexPath;
//    PFObject *listing = [self.results objectAtIndex:indexPath.item];
//    
//    ListingController *vc = [[ListingController alloc]init];
//    vc.listingObject = listing;
//    self.listingTapped = YES;
//    
//    //switch off hiding nav bar
////    self.navigationController.navigationBarHidden = NO;
//    [self.navigationController pushViewController:vc animated:YES];
//    
//    BOOL highlightBoost = NO;
//    BOOL searchBoost = NO;
//    BOOL featureBoost = NO;
//    
//    //check what boosts are enabled then display the correct summary boost icon
//    if ([listing objectForKey:@"highlighted"]) {
//        
//        NSDate *expiryDate = [listing objectForKey:@"highlightExpiry"];
//        
//        if ([[listing objectForKey:@"highlighted"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedDescending) {
//            
//            highlightBoost = YES;
//            
//        }
//        else if ([[listing objectForKey:@"highlighted"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedAscending) {
//            [listing removeObjectForKey:@"highlighted"];
//            [listing saveInBackground];
//        }
//    }
//    
//    if ([listing objectForKey:@"searchBoost"]) {
//        
//        NSDate *expiryDate = [listing objectForKey:@"searchBoostExpiry"];
//        
//        if ([[listing objectForKey:@"searchBoost"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedDescending) {
//            
//            searchBoost = YES;
//            
//        }
//        else if ([[listing objectForKey:@"searchBoost"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedAscending) {
//            [listing removeObjectForKey:@"searchBoost"];
//            [listing saveInBackground];
//        }
//    }
//    
//    if ([listing objectForKey:@"featuredBoost"]) {
//        
//        NSDate *expiryDate = [listing objectForKey:@"featuredBoostExpiry"];
//        
//        if ([[listing objectForKey:@"featuredBoost"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedDescending) {
//            
//            featureBoost = YES;
//            
//            [[PFUser currentUser]addObject:listing.objectId forKey:@"seenFeatured"];
//            [[PFUser currentUser]saveEventually];
//        }
//        else if ([[listing objectForKey:@"featuredBoost"] isEqualToString:@"YES"] && [expiryDate compare:[NSDate date]]==NSOrderedAscending) {
//            [listing removeObjectForKey:@"featuredBoost"];
//            [listing saveInBackground];
//        }
//    }
//    
//    [Answers logCustomEventWithName:@"Tapped Home WTB"
//                   customAttributes:@{
//                                      @"featured":[NSNumber numberWithBool:featureBoost],
//                                      @"highlighted":[NSNumber numberWithBool:highlightBoost],
//                                      @"searchBoost":[NSNumber numberWithBool:searchBoost],
//                                      @"FeaturedTabSelected":[NSNumber numberWithBool:self.latestMode]
//                                      }];
//}

-(void)showError{
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Error"
                                  message:@"Make sure you're connected to the internet!"
                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

//-(void)cellTapped:(id)sender{
//    NSIndexPath *indexPath = [self.collectionView indexPathForCell:(ExploreCell*)sender];
//    
//    PFObject *listingObject = [self.results objectAtIndex:indexPath.item];
//    
//    [Answers logCustomEventWithName:@"Bumped a listing"
//                   customAttributes:@{
//                                      @"where":@"Home"
//                                      }];
//    
//    ExploreCell *cell = sender;
//    NSMutableArray *bumpArray = [NSMutableArray array];
//    if ([listingObject objectForKey:@"bumpArray"]) {
//        [bumpArray addObjectsFromArray:[listingObject objectForKey:@"bumpArray"]];
//    }
//    
//    NSMutableArray *personalBumpArray = [NSMutableArray array];
//    if ([[PFUser currentUser] objectForKey:@"bumpArray"]) {
//        [personalBumpArray addObjectsFromArray:[[PFUser currentUser] objectForKey:@"bumpArray"]];
//    }
//
//    if ([bumpArray containsObject:[PFUser currentUser].objectId]) {
//        NSLog(@"already bumped it m8");
//        [cell.bumpButton setSelected:NO];
//        [cell.transView setBackgroundColor:[UIColor blackColor]];
//        cell.transView.alpha = 0.5;
//        [bumpArray removeObject:[PFUser currentUser].objectId];
//        [listingObject setObject:bumpArray forKey:@"bumpArray"];
//        [listingObject incrementKey:@"bumpCount" byAmount:@-1];
//        
//        if ([personalBumpArray containsObject:listingObject.objectId]) {
//            [personalBumpArray removeObject:listingObject.objectId];
//        }
//        
//        //update bump object
//        PFQuery *bumpQ = [PFQuery queryWithClassName:@"BumpedListings"];
//        [bumpQ whereKey:@"bumpUser" equalTo:[PFUser currentUser]];
//        [bumpQ whereKey:@"listing" equalTo:listingObject];
//        [bumpQ findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//            if (objects) {
//                for (PFObject *bump in objects) {
//                    [bump setObject:@"deleted" forKey:@"status"];
//                    [bump saveInBackground];
//                }
//            }
//        }];
//    }
//    else{
//        NSLog(@"bumped");
//        [cell.bumpButton setSelected:YES];
//        [cell.transView setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
//        cell.transView.alpha = 0.9;
//        [bumpArray addObject:[PFUser currentUser].objectId];
//        [listingObject addObject:[PFUser currentUser].objectId forKey:@"bumpArray"];
//        [listingObject incrementKey:@"bumpCount"];
//        
//        if (![personalBumpArray containsObject:listingObject.objectId]) {
//            [personalBumpArray addObject:listingObject.objectId];
//        }
//        
//        //send push
//        NSString *pushText = [NSString stringWithFormat:@"%@ just liked your listing 👊", [PFUser currentUser].username];
//        
//        if (![[[listingObject objectForKey:@"postUser"]objectId] isEqualToString:[[PFUser currentUser]objectId]]) {
//            NSDictionary *params = @{@"userId": [[listingObject objectForKey:@"postUser"]objectId], @"message": pushText, @"sender": [PFUser currentUser].username, @"bumpValue": @"NO", @"listingID": listingObject.objectId};
//            
//            [PFCloud callFunctionInBackground:@"sendNewPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
//                if (!error) {
//                    NSLog(@"push response %@", response);
//                    [Answers logCustomEventWithName:@"Push Sent"
//                                   customAttributes:@{
//                                                      @"Type":@"Bump"
//                                                      }];
//                }
//                else{
//                    NSLog(@"push error %@", error);
//                }
//            }];
//        }
//        else{
//            [Answers logCustomEventWithName:@"Bumped own listing"
//                           customAttributes:@{
//                                              @"where":@"Home"
//                                              }];
//        }
//        
//        PFObject *bumpObj = [PFObject objectWithClassName:@"BumpedListings"];
//        [bumpObj setObject:listingObject forKey:@"listing"];
//        [bumpObj setObject:[PFUser currentUser] forKey:@"bumpUser"];
//        [bumpObj setObject:@"live" forKey:@"status"];
//        [bumpObj saveInBackground];
//    }
//    
//    //save listing
//    [listingObject saveInBackground];
//    [[PFUser currentUser]setObject:personalBumpArray forKey:@"bumpArray"];
//    [[PFUser currentUser]saveInBackground];
//
//    if (bumpArray.count > 0) {
//        int count = (int)[bumpArray count];
//        [cell.bumpButton setTitle:[NSString stringWithFormat:@"%@",[self abbreviateNumber:count]] forState:UIControlStateNormal];
//    }
//    else{
//        [cell.bumpButton setTitle:@" " forState:UIControlStateNormal];
//    }
//}

- (void)handleBump:(NSNotification*)note {
    NSString *listingID = [note object];
    
    [Answers logCustomEventWithName:@"Opened BumpVC after receiving FB Friend Push"
                   customAttributes:@{}];
    
    BumpVC *vc = [[BumpVC alloc]init];
    vc.listingID = listingID;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showListing:(NSNotification*)note {
    NSString *listingID = [note object];
    
    [Answers logCustomEventWithName:@"Opened listing after receiving Bump Push"
                   customAttributes:@{}];
    
    PFObject *listing = [PFObject objectWithoutDataWithClassName:@"wantobuys" objectId:listingID];
    ListingController *vc = [[ListingController alloc]init];
    vc.listingObject = listing;
    NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
    
    //unhide nav bar
//    self.navigationController.navigationBarHidden = NO;
    [nav pushViewController:vc animated:YES];
}

- (void)showSaleListing:(NSNotification*)note {
    NSString *listingID = [note object];
    
    [Answers logCustomEventWithName:@"Opened listing after receiving Bump Push"
                   customAttributes:@{}];
    
    PFObject *listing = [PFObject objectWithoutDataWithClassName:@"wantobuys" objectId:listingID];
    ListingController *vc = [[ListingController alloc]init];
    vc.listingObject = listing;
    NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
    
    //unhide nav bar
    //    self.navigationController.navigationBarHidden = NO;
    [nav pushViewController:vc animated:YES];
}

- (void)showReleasePage:(NSNotification*)note {
    NSString *itemTitle = [note object];
    
    PFQuery *linkQuery = [PFQuery queryWithClassName:@"Releases"];
    [linkQuery whereKey:@"status" equalTo:@"live"];
    [linkQuery whereKey:@"itemTitle" equalTo:itemTitle];
    [linkQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            NSLog(@"open web view! did finish launching");
            
            NSString *link = [object objectForKey:@"itemLink"];
            
            if (![link isEqualToString:@"soon"]) {
                self.web = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:link]];
                self.web.showUrlWhileLoading = YES;
                self.web.showPageTitles = YES;
                self.web.doneButtonTitle = @"";
//                self.web.infoMode = NO;
                self.web.delegate = self;
                self.web.dropMode = YES;
                
                NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.web];
                [self presentViewController:navigationController animated:YES completion:^{
                    //update reminders array to keep it accurate
                    NSMutableArray *remindersArray = [NSMutableArray array];
                    
                    if ([[PFUser currentUser]objectForKey:@"remindersArray"]) {
                        [remindersArray addObjectsFromArray:[[PFUser currentUser]objectForKey:@"remindersArray"]];
                    }
                    
                    NSMutableArray *discardedItems = [NSMutableArray array];
                    
                    for (NSString *itemTitle in remindersArray) {
                        if ([itemTitle isEqualToString:itemTitle]){
                            [discardedItems addObject:itemTitle];
                        }
                    }
                    [remindersArray removeObjectsInArray:discardedItems];
                    
                    [[PFUser currentUser]setObject:remindersArray forKey:@"remindersArray"];
                    [[PFUser currentUser] saveInBackground];
                }];
            }
        }
        else{
            [Answers logCustomEventWithName:@"Error Opening Release"
                           customAttributes:@{
                                              @"error":error,
                                              @"where":@"Explore"
                                              }];
            
            NSLog(@"error getting release %@", error);
        }
    }];
}

- (void)handleDrop:(NSNotification*)note {
    NSString *listingID = [note object];
    
    [Answers logCustomEventWithName:@"Received in app push"
                   customAttributes:@{
                                      @"type":@"FB Friend just posted"
                                      }];

    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"notView" owner:self options:nil];
    self.dropDown = (notificatView *)[nib objectAtIndex:0];
    self.dropDown.delegate = self;
    self.dropDown.listingID = listingID;
    
    UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDrop)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [self.dropDown addGestureRecognizer:swipeGesture];
    [self.dropDown setFrame:CGRectMake(0, -119, self.view.frame.size.width, 119)];
    
    PFQuery *listingQ = [PFQuery queryWithClassName:@"wantobuys"];
    [listingQ whereKey:@"objectId" equalTo:listingID];
    [listingQ includeKey:@"postUser"];
    [listingQ getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            PFObject *listing = object;
            self.dropDown.listing = listing;
            [self.dropDown.imageView setFile:[object objectForKey:@"image1"]];
            [self.dropDown.imageView loadInBackground:^(UIImage * _Nullable image, NSError * _Nullable error) {
                if (image) {
                    PFUser *postUser = [listing objectForKey:@"postUser"];
                    self.dropDown.mainLabel.text = [NSString stringWithFormat:@"Your Facebook friend %@ just posted a listing - Tap to Bump it 👊", [postUser objectForKey:@"fullname"]];
                    self.justABump = NO;
                    self.justAMessage = NO;
                    self.sendMode = NO;

                    //animate down
                    [[UIApplication sharedApplication].keyWindow addSubview:self.dropDown];
                    
                    [UIView animateWithDuration:1.0
                                          delay:0.0
                         usingSpringWithDamping:0.5
                          initialSpringVelocity:0.5
                                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                                            //Animations
                                            [self.dropDown setFrame:CGRectMake(0, 0, self.view.frame.size.width, 119)];
                                        }
                                     completion:^(BOOL finished) {
                                         //schedule auto dismiss
                                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                             [self dismissDrop];
                                         });
                                     }];
                }
            }];
        }
        else{
            NSLog(@"error finding listing");
        }
    }];
}

-(void)dismissDrop{
    //animate up
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            [self.dropDown setFrame:CGRectMake(0, -300, self.view.frame.size.width, 119)];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         [self.dropDown removeFromSuperview];
                         self.dropDown = nil;
                     }];
}

-(void)handleBumpDrop:(NSNotification*)note {
    NSArray *info = [note object];
    
    //prevent crashes with wrongly formatted pushes
    if (info.count <2) {
        return;
    }
    
    NSString *listingID = info[0];
    NSString *message = info[1];
    
    [Answers logCustomEventWithName:@"Received in app push"
                   customAttributes:@{
                                      @"type":@"Received a Bump"
                                      }];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"notView" owner:self options:nil];
    self.dropDown = nil;
    self.dropDown = (notificatView *)[nib objectAtIndex:0];
    self.dropDown.delegate = self;
    self.dropDown.listingID = listingID;
    
    UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDrop)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [self.dropDown addGestureRecognizer:swipeGesture];
    [self.dropDown setFrame:CGRectMake(0, -119, self.view.frame.size.width, 119)];
    
    PFQuery *listingQ = [PFQuery queryWithClassName:@"wantobuys"];
    [listingQ whereKey:@"objectId" equalTo:listingID];
    [listingQ getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            PFObject *listing = object;
            self.dropDown.listing = listing;
            [self.dropDown.imageView setFile:[object objectForKey:@"image1"]];
            [self.dropDown.imageView loadInBackground:^(UIImage * _Nullable image, NSError * _Nullable error) {
                if (image) {
                    self.dropDown.mainLabel.text = message;
                    self.justABump = YES;
                    self.justAMessage = NO;
                    self.sendMode = NO;

                    //animate down
                    [[UIApplication sharedApplication].keyWindow addSubview:self.dropDown];
                    
                    [UIView animateWithDuration:1.0
                                          delay:0.0
                         usingSpringWithDamping:0.5
                          initialSpringVelocity:0.5
                                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                                            //Animations
                                            [self.dropDown setFrame:CGRectMake(0, 0, self.view.frame.size.width, 119)];
                                        }
                                     completion:^(BOOL finished) {
                                         //schedule auto dismiss
                                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                             [self dismissDrop];
                                         });
                                     }];
                }
            }];
        }
        else{
            NSLog(@"error finding listing");
        }
    }];
}

-(void)bumpTappedForListing:(NSString *)listing{
    
    //all purpose 'drop down' pressed method - not just for bump drop down
    
    //animate up
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            [self.dropDown setFrame:CGRectMake(0, -300, self.view.frame.size.width, 119)];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         [self.dropDown removeFromSuperview];
                     }];
    
    //screenshotted
    if (self.justAMessage == YES && self.sendMode == YES){
        [Answers logCustomEventWithName:@"Tapped in app Push"
                       customAttributes:@{
                                          @"type":@"screenshot"
                                          }];
        //trigger send box
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showSendBox" object:nil];
    }
    else if (self.justAMessage == YES){
        //do nothing
    }
    //fb friend posted
    else if (self.justABump == NO) {
        [Answers logCustomEventWithName:@"Tapped in app Push"
                       customAttributes:@{
                                          @"type":@"fb friend posted"
                                          }];
        BumpVC *vc = [[BumpVC alloc]init];
        vc.listingID = listing;
        [self presentViewController:vc animated:YES completion:nil];
    }
    //my listing got bumped
    else{
        //goto that listing
        [Answers logCustomEventWithName:@"Tapped in app Push"
                       customAttributes:@{
                                          @"type":@"Bump"
                                          }];
        PFObject *listingObj = [PFObject objectWithoutDataWithClassName:@"wantobuys" objectId:listing];
        ListingController *vc = [[ListingController alloc]init];
        vc.listingObject = listingObj;
        //make sure drop down is gone
        self.dropDown = nil;
        NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
        [nav pushViewController:vc animated:YES];
    }
}

-(void)cancellingMainSearch{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

-(void)setUpIntroAlert{
    
    if (self.lowRating == YES) {
        self.searchBgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    }
    else{
        
        //for search intro, only show bg so search bar pops
        self.searchBgView = [[UIView alloc]initWithFrame:CGRectMake(0,(self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height), [UIApplication sharedApplication].keyWindow.frame.size.width, [UIApplication sharedApplication].keyWindow.frame.size.height-(self.navigationController.navigationBar.frame.size.height+[UIApplication sharedApplication].statusBarFrame.size.height))];
        
//        UIImageView *imgView = [[UIImageView alloc]initWithFrame:self.searchBgView.frame];
//        if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
//            //iphone 5
//            [imgView setImage:[UIImage imageNamed:@"searchIntro1"]];
//        }
//        else{
//            //iPhone 6 specific
//            [imgView setImage:[UIImage imageNamed:@"searchIntro"]];
//        }
//        [self.searchBgView addSubview:imgView];
    }
    
    [self.searchBgView setBackgroundColor:[UIColor blackColor]];
    self.searchBgView.alpha = 0.0;
    
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
    
    if (self.lowRating == YES) {
        self.customAlert.titleLabel.text = @"Your Feedback";
        self.customAlert.messageLabel.text = @"Hit 'Message' to send Team Bump some quick feedback 💬";
        self.customAlert.numberOfButtons = 2;
    }
    else{
        self.customAlert.titleLabel.text = @"Selling Something?";
        self.customAlert.messageLabel.text = @"Tap the Search bar ☝️ to find wanted listings that match what you’re selling";
        self.customAlert.numberOfButtons = 1;
        self.searchIntroShowing = YES;
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
    
    [UIView animateWithDuration:1.0
                          delay:1.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, 100, 250, 157)];
                            }
                            else{
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, 100, 300, 188)]; //iPhone 6/7 specific
                            }
                            
                            if (self.lowRating == YES) {
                                self.customAlert.center = self.view.center;
                            }
                        }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)showPushReminder{
    self.shownPushAlert = YES;
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
    self.pushAlert = (customAlertViewClass *)[nib objectAtIndex:0];
    self.pushAlert.delegate = self;
    self.pushAlert.titleLabel.text = @"Enable Push";
    self.pushAlert.messageLabel.text = @"Tap to be notified when sellers & potential buyers send you a message on BUMP";
    self.pushAlert.numberOfButtons = 2;
    [self.pushAlert.secondButton setTitle:@"E N A B L E" forState:UIControlStateNormal];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, -157, 250, 157)];
    }
    else{
        [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, -188, 300, 188)]; //iPhone 6/7 specific
    }
    
    self.pushAlert.layer.cornerRadius = 10;
    self.pushAlert.layer.masksToBounds = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.pushAlert];
    
    [UIView animateWithDuration:0.5
                          delay:0.2
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.pushAlert setFrame:CGRectMake(0, 0, 250, 157)];
                            }
                            else{
                                [self.pushAlert setFrame:CGRectMake(0, 0, 300, 188)]; //iPhone 6/7 specific
                            }
                            self.pushAlert.center = self.view.center;
                            
                        }
                     completion:nil];
}

-(void)donePressed{
    if (self.shownPushAlert == YES) {
        //push re-reminder
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
                                    [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, 1000, 250, 157)];
                                }
                                else{
                                    [self.pushAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, 1000, 300, 188)]; //iPhone 6/7 specific
                                }
                            }
                         completion:^(BOOL finished) {
                             //Completion Block
                             [self.pushAlert setAlpha:0.0];
                             [self.pushAlert removeFromSuperview];
                             self.pushAlert = nil;
                         }];
    }
    else{
        if (self.lowRating == YES) {
            self.lowRating = NO;
        }
        else{
            //search intro
            [[PFUser currentUser]setObject:@"YES" forKey:@"searchIntro"];
            [[PFUser currentUser] saveInBackground];
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
                             [self.customAlert setAlpha:0.0];
                             self.customAlert = nil;
                         }];
    }
}
//custom alert delegates
-(void)firstPressed{
    
    if (self.lowRating == YES) {
        [Answers logCustomEventWithName:@"Dismissed Feedback Ask Prompt"
                       customAttributes:@{}];

    }
    else{
        //push reminder
        if ([PFUser currentUser]) {
            [Answers logCustomEventWithName:@"Denied Push Permissions"
                           customAttributes:@{
                                              @"mode":@"reprompt",
                                              @"username":[PFUser currentUser].username
                                              }];
            [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"declinedPushPermissions"];
            [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"declinedDate"];
        }
    }

    [self donePressed];
}
-(void)secondPressed{
    
    if (self.lowRating == YES) {
        [Answers logCustomEventWithName:@"Message Team Bump pressed from Rate prompt"
                       customAttributes:@{}];
        
        NSLog(@"NAV %@", self.messageNav);
        
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
                NavigationController *nav = (NavigationController*)self.messageNav;
                
                //unhide nav bar
//                self.navigationController.navigationBarHidden = NO;
                [nav pushViewController:vc animated:YES];
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
                        NavigationController *nav = (NavigationController*)self.messageNav;
                        
                        //unhide nav bar
//                        self.navigationController.navigationBarHidden = NO;
                        [nav pushViewController:vc animated:YES];
                    }
                    else{
                        NSLog(@"error saving convo");
                    }
                }];
            }
        }];
    }
    else{
        //push reminder
        
        if ([PFUser currentUser]) {
            [Answers logCustomEventWithName:@"Accepted Push Permissions"
                           customAttributes:@{
                                              @"mode":@"reprompt",
                                              @"username":[PFUser currentUser].username
                                              }];
            [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"askedForPushPermission"];
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"declinedPushPermissions"];
            
            UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                            UIUserNotificationTypeBadge |
                                                            UIUserNotificationTypeSound);
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                     categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
    }
    [self donePressed];
}

-(void)resetHome{
    //only reset if they're looking at home tab
//    if (self.tabBarController.selectedIndex == 0) {
//        
//        if (self.results.count != 0) {
//            //prevents crash when header is not visible, thereofre has no layout attributes // if still seeing crash, layoutifneeded also meant to work
//            [self.collectionView.collectionViewLayout prepareLayout];
//            
//            //scroll to top of header
//            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
//            
//            CGFloat offsetY = [self.collectionView layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath].frame.origin.y;
//            
//            CGFloat contentInsetY = self.collectionView.contentInset.top;
//            CGFloat sectionInsetY = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).sectionInset.top;
//            
//            [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, offsetY - contentInsetY - sectionInsetY) animated:YES];
//        }
//
//        
//        self.ignoreShownTo = NO;
//        [self queryParsePullWithRecall:NO];
//    }
}

-(void)insertLatestListing:(NSNotification*)note {
//    PFObject *listing = [note object];
////    NSLog(@"insert %@", listing);
//    if (self.results.count > 0) {
//        [self.results insertObject:listing atIndex:0];
//        [self.resultIDs addObject:listing.objectId];
//        [self.collectionView reloadData];
//    }
}

-(void)refreshLatestListing:(NSNotification*)note {
//    PFObject *boostedListing = [note object];
//
//    if (self.results.count > 0) {
//        [self.results removeObjectAtIndex:0];
//        [self.results insertObject:boostedListing atIndex:0];
//        [self.collectionView reloadData];
//    }
}

-(void)doubleTapScroll{
    //switch off hiding nav bar
//    self.navigationController.navigationBarHidden = NO;
//    BOOL modalPresent = (self.presentedViewController);
//    
//    if (self.results.count != 0 && self.listingTapped == NO && modalPresent != YES) {
//        
//        //prevents crash when header is not visible, thereofre has no layout attributes // if still seeing crash, layoutifneeded also meant to work
//        [self.collectionView.collectionViewLayout prepareLayout];
//        
//        //scroll to top of header
//        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
//        
//        CGFloat offsetY = [self.collectionView layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath].frame.origin.y;
//        
//        CGFloat contentInsetY = self.collectionView.contentInset.top;
//        CGFloat sectionInsetY = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).sectionInset.top;
//        
//        [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, offsetY - contentInsetY - sectionInsetY) animated:YES];
//    }
}


#pragma mark message drop

-(void)messageSentDrop:(NSNotification*)note {
    PFUser *friend = [note object];
    
    [Answers logCustomEventWithName:@"Showing Message Sent Drop"
                   customAttributes:@{}];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"notView" owner:self options:nil];
    self.dropDown = (notificatView *)[nib objectAtIndex:0];
    self.dropDown.delegate = self;
    self.dropDown.sentMode = YES;
    [self setImageBorder:self.dropDown.imageView];
    
    [friend fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            [self.dropDown.imageView setFile:[friend objectForKey:@"picture"]];
            [self.dropDown.imageView loadInBackground:^(UIImage * _Nullable image, NSError * _Nullable error) {
                if (image) {
                    self.dropDown.mainLabel.text = [NSString stringWithFormat:@"Message sent to %@", friend.username];
                    
                    //setup what happens when user taps notification
                    self.justAMessage = YES;
                    
                    //animate down
                    [[UIApplication sharedApplication].keyWindow addSubview:self.dropDown];
                    
                    [UIView animateWithDuration:1.0
                                          delay:0.0
                         usingSpringWithDamping:0.5
                          initialSpringVelocity:0.5
                                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                                            //Animations
                                            [self.dropDown setFrame:CGRectMake(0, 0, self.view.frame.size.width, 119)];
                                        }
                                     completion:^(BOOL finished) {
                                         //schedule auto dismiss
                                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                             [self dismissDrop];
                                         });
                                     }];
                }
            }];
        }
        else{
            NSLog(@"error fetching user %@", error);
        }
    }];
    
    UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDrop)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [self.dropDown addGestureRecognizer:swipeGesture];
    [self.dropDown setFrame:CGRectMake(0, -119, self.view.frame.size.width, 119)];
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = 30;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)segmentControlChanged{
    if (self.latestMode == YES) {
        //load suggested
        [self.segmentedControl setSelectedSegmentIndex:0];
        self.latestMode = NO;
    }
    else{
        //load latest
        [self.segmentedControl setSelectedSegmentIndex:1];
        self.latestMode = YES;
    }
//    [self queryParsePullWithRecall:NO];
}

-(void)welcomeDismissed{
    self.welcomeShowing = NO;
//    [self queryParsePullWithRecall:NO];
}

-(void)showScreenShot:(NSNotification*)note {
    
    [Answers logCustomEventWithName:@"Showing Screenshot Notification"
                   customAttributes:@{}];
    
    self.dropDown = nil;
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"notView" owner:self options:nil];
    self.dropDown = (notificatView *)[nib objectAtIndex:0];
    self.dropDown.delegate = self;
    self.dropDown.sentMode = YES;
    [self.dropDown.imageView setImage:[UIImage imageNamed:@"envelopeSend"]];
    [self setImageBorder:self.dropDown.imageView];
    
    self.dropDown.mainLabel.text = @"Tap Send to share this listing with friends on Bump!";
    
    //setup what happens when user taps notification
    self.justAMessage = YES;
    self.sendMode = YES;
    
    //animate down
    [self.dropDown setFrame:CGRectMake(0, -119, self.view.frame.size.width, 119)];
    [[UIApplication sharedApplication].keyWindow addSubview:self.dropDown];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            [self.dropDown setFrame:CGRectMake(0, 0, self.view.frame.size.width, 119)];
                        }
                     completion:^(BOOL finished) {
                         //schedule auto dismiss
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                             [self dismissDrop];
                         });
                     }];
    
    UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDrop)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [self.dropDown addGestureRecognizer:swipeGesture];
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


#pragma mark - rate delegates

-(void)setUpRateViewWithNav:(NSNotification*)note {
    
    UINavigationController *nav = [note object];

    self.messageNav = nav;
    
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
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"RateView" owner:self options:nil];
    self.rateView = (RateCustomView *)[nib objectAtIndex:0];
    self.rateView.delegate = self;
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.rateView setFrame:CGRectMake((self.view.frame.size.width/2)-135, -220, 270, 220)];
    }
    else{
        [self.rateView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -210, 300, 210)]; //iPhone 6/7 specific
    }
    
    self.rateView.layer.cornerRadius = 10;
    self.rateView.layer.masksToBounds = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.rateView];
    
    [UIView animateWithDuration:1.0
                          delay:1.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.rateView setFrame:CGRectMake(0, 0, 270,220)];
                            }
                            else{
                                [self.rateView setFrame:CGRectMake(0, 0, 300, 210)]; //iPhone 6/7 specific
                            }
                            
                            self.rateView.center = self.view.center;

                        }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)dismissRatePressed{
    
    [Answers logCustomEventWithName:@"User Dismissed Rate Dialog"
                   customAttributes:@{}];
    
    //save info
    [[PFUser currentUser]setObject:[NSDate date] forKey:@"reviewDate"];
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [[PFUser currentUser]setObject:currentVersion forKey:@"versionReviewed"];
    [[PFUser currentUser]saveInBackground];
    
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
                            [self.rateView setFrame:CGRectMake((self.view.frame.size.width/2)-187.5, 1000, 375, 235)];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         [self.rateView setAlpha:0.0];
                         self.rateView = nil;
                         
                         if (self.lowRating == YES) {
                             //show prompt
                             [self setUpIntroAlert];
                         }
                     }];
    
}
-(void)ratePressedWithNumber:(int)starNumber{
    
    if (starNumber == 0) {
        return;
    }
    
    [Answers logCustomEventWithName:@"User Rated App"
                   customAttributes:@{
                                      @"Rating":[NSString stringWithFormat:@"%d", starNumber]
                                      }];
    
    if (starNumber >= 4) {
        
        NSString *reqSysVer = @"10.3";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending) {
            NSLog(@"10.3 or later");
            [SKStoreReviewController requestReview];
            
            [Answers logCustomEventWithName:@"In-app 10.3 rating triggered"
                           customAttributes:@{
                                              @"Rating":[NSString stringWithFormat:@"%d", starNumber]
                                              }];
        }
        else{
            NSLog(@"current version is %@", currSysVer);
            
            NSURL *storeURL = [NSURL URLWithString:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1096047233&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software&action=write-review"];
            if ([[UIApplication sharedApplication] canOpenURL: storeURL]) {
                [[UIApplication sharedApplication] openURL: storeURL];
            }
            
            [Answers logCustomEventWithName:@"Out-of-app rating triggered"
                           customAttributes:@{
                                              @"Rating":[NSString stringWithFormat:@"%d", starNumber]
                                              }];
        }

        [self dismissRatePressed];
        
    }
    else{
        //prompt for team bump message
        self.lowRating = YES;
        [self dismissRatePressed];
    }
    
    //save info
    [[PFUser currentUser]setObject:[NSNumber numberWithInt:starNumber] forKey:@"lastRating"];
    [[PFUser currentUser]setObject:[NSDate date] forKey:@"reviewDate"];
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [[PFUser currentUser]setObject:currentVersion forKey:@"versionReviewed"];
    [[PFUser currentUser]saveInBackground];
}

#pragma mark - invite view delegates

-(void)showInviteView{
    
    NSLog(@"SHOW INVITE");
    
    if (self.alertShowing == YES) {
        return;
    }
    
    self.alertShowing = YES;
    self.bgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.bgView.alpha = 0.0;
    [self.bgView setBackgroundColor:[UIColor blackColor]];
    [[UIApplication sharedApplication].keyWindow addSubview:self.bgView];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.bgView.alpha = 0.6f;
                     }
                     completion:nil];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"inviteView" owner:self options:nil];
    self.inviteView = (inviteViewClass *)[nib objectAtIndex:0];
    self.inviteView.delegate = self;
    
    //setup images
    NSMutableArray *friendsArray = [NSMutableArray arrayWithArray:[[PFUser currentUser] objectForKey:@"friends"]];
    
    //manage friends count label
    if (friendsArray.count > 5) {
        self.inviteView.friendsLabel.text = [NSString stringWithFormat:@"%lu friends use Bump", (unsigned long)friendsArray.count];
    }
    else{
        self.inviteView.friendsLabel.text = @"Help us grow 🚀";
    }
    
    if (friendsArray.count > 0) {
        [self shuffle:friendsArray];
        if (friendsArray.count >2) {
            NSURL *picUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", friendsArray[0]]];
            [self.inviteView.friendImageOne sd_setImageWithURL:picUrl];
            
            NSURL *picUrl2 = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large",friendsArray[1]]];
            [self.inviteView.friendImageTwo sd_setImageWithURL:picUrl2];
            
            NSURL *picUrl3 = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large",friendsArray[2]]];
            [self.inviteView.friendImageThree sd_setImageWithURL:picUrl3];
        }
        else if (friendsArray.count == 2){
            NSURL *picUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", friendsArray[0]]];
            [self.inviteView.friendImageOne sd_setImageWithURL:picUrl];
            
            NSURL *picUrl2 = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large",friendsArray[1]]];
            [self.inviteView.friendImageTwo sd_setImageWithURL:picUrl2];
            
            NSURL *picUrl3 = [NSURL URLWithString:@"https://graph.facebook.com/10153952930083234/picture?type=large"]; //use my image to fill gap
            [self.inviteView.friendImageThree sd_setImageWithURL:picUrl3];
        }
        else if (friendsArray.count == 1){
            NSURL *picUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", friendsArray[0]]];
            [self.inviteView.friendImageOne sd_setImageWithURL:picUrl];
            
            NSURL *picUrl2 = [NSURL URLWithString:@"https://graph.facebook.com/10153368584907077/picture?type=large"]; //use sam's image
            [self.inviteView.friendImageTwo sd_setImageWithURL:picUrl2];
            
            NSURL *picUrl3 = [NSURL URLWithString:@"https://graph.facebook.com/10153952930083234/picture?type=large"]; //use my image to fill gap
            [self.inviteView.friendImageThree sd_setImageWithURL:picUrl3];
        }
    }
    else{
        NSURL *picUrl = [NSURL URLWithString:@"https://graph.facebook.com/10153952930083234/picture?type=large"]; //use my image
        [self.inviteView.friendImageOne sd_setImageWithURL:picUrl];
        
        NSURL *picUrl2 = [NSURL URLWithString:@"https://graph.facebook.com/10153368584907077/picture?type=large"]; //use sam's image
        [self.inviteView.friendImageTwo sd_setImageWithURL:picUrl2];
        
        NSURL *picUrl3 = [NSURL URLWithString:@"https://graph.facebook.com/10154993039808844/picture?type=large"]; //use tayler's image to fill gap
        [self.inviteView.friendImageThree sd_setImageWithURL:picUrl3];
    }
    
    [self.inviteView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -300, 300, 300)];
    self.inviteView.layer.cornerRadius = 10;
    self.inviteView.layer.masksToBounds = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.inviteView];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            [self.inviteView setFrame:CGRectMake(0, 0, 300, 300)];
                            self.inviteView.center = self.view.center;
                        }
                     completion:^(BOOL finished) {
                         [self.bgView addGestureRecognizer:self.tap];
                     }];
    
    //save info
    [[PFUser currentUser]setObject:[NSDate date] forKey:@"inviteDate"];
    [[PFUser currentUser]saveInBackground];
}

-(void)hideInviteView{

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.bgView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         self.bgView = nil;
                         [self.bgView removeGestureRecognizer:self.tap];
                     }];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            [self.inviteView setFrame:CGRectMake((self.view.frame.size.width/2)-150, 1000, 300, 300)];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         self.alertShowing = NO;
                         [self.inviteView setAlpha:0.0];
                         self.inviteView = nil;
                     }];
}

-(void)whatsappPressed{
    [Answers logCustomEventWithName:@"Share Pressed"
                   customAttributes:@{
                                      @"type":@"whatsapp"
                                      }];
    NSString *shareString = @"Check out Bump for iOS - buy & sell streetwear quickly and with ZERO fees 👟\n\nAvailable here: http://sobump.com";
    NSURL *whatsappURL = [NSURL URLWithString:[NSString stringWithFormat:@"whatsapp://send?text=%@",[self urlencode:shareString]]];
    if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
        [[UIApplication sharedApplication] openURL: whatsappURL];
    }
}

-(void)messengerPressed{
    [Answers logCustomEventWithName:@"Share Pressed"
                   customAttributes:@{
                                      @"type":@"messenger"
                                      }];
    NSURL *messengerURL = [NSURL URLWithString:@"fb-messenger://share/?link=http://sobump.com"];
    if ([[UIApplication sharedApplication] canOpenURL: messengerURL]) {
        [[UIApplication sharedApplication] openURL: messengerURL];
    }
}

-(void)textPressed{
    [self hideInviteView];
    [Answers logCustomEventWithName:@"Share Pressed"
                   customAttributes:@{
                                      @"type":@"share sheet"
                                      }];
    NSMutableArray *items = [NSMutableArray new];
    [items addObject:@"Check out Bump for iOS - buy & sell streetwear quickly and with ZERO fees 👟\n\nAvailable here: http://sobump.com"];
    UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}

#pragma engagement question delegates

-(void)setUpEngagementViewWithNav:(NSNotification*)note {
    
    //final check to ensure welcomeVC not showing
    BOOL modalPresent = (self.presentedViewController);
    
    if (modalPresent) {
        return;
    }
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];

    [Answers logCustomEventWithName:@"Show Engagement Question"
                   customAttributes:@{
                                      @"version":appVersion
                                      }];
    
    UINavigationController *nav = [note object];
    
    self.engageQNav = nav;
    
    self.bgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.bgView.alpha = 0.0;
    [self.bgView setBackgroundColor:[UIColor blackColor]];
    [[UIApplication sharedApplication].keyWindow addSubview:self.bgView];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.bgView.alpha = 0.6f;
                     }
                     completion:nil];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"engagementView" owner:self options:nil];
    self.engageView = (engageTracker *)[nib objectAtIndex:0];
    self.engageView.delegate = self;
    
    [self.engageView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -250, 300, 250)];
    self.engageView.layer.cornerRadius = 10;
    self.engageView.layer.masksToBounds = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.engageView];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            [self.engageView setFrame:CGRectMake(0, 0, 300, 250)];
                            self.engageView.center = self.view.center;
                        }
                     completion:^(BOOL finished) {
                     }];
}

//dismissed engage view
-(void)donePressedWithNumber:(int)number{
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];

    [Answers logCustomEventWithName:@"Engagement Question Answered"
                   customAttributes:@{
                                      @"answer":[NSString stringWithFormat:@"%d", number],
                                      @"version":appVersion
                                      }];
    
    NSDictionary *rateDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:number],@"rating", @"1196",@"version", nil];
    
    [[PFUser currentUser]addObject:rateDictionary forKey:@"engageRatingsArray"];
    [[PFUser currentUser]saveInBackground];
    
    //change build number
    // update this key for each build released so we can monitor answers as updates released
    [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"1196Answered"];
    
    [self hideEngageView];
}

-(void)hideEngageView{
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.bgView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         self.bgView = nil;
                     }];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            [self.engageView setFrame:CGRectMake((self.view.frame.size.width/2)-150, 1000, 300, 250)];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         [self.engageView setAlpha:0.0];
                         self.engageView = nil;
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

- (NSString *)urlencode:(NSString *)stringToEncode{
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[stringToEncode UTF8String];
    int sourceLen = (int)strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

-(void)scheduleTestReminder{
    //schedule local notification
    
//    PFQuery *releases = [PFQuery queryWithClassName:@"Releases"];
//    [releases whereKey:@"itemTitle" equalTo:@"ASICS Gel-Lyte V Green Coffee"];
//    [releases getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
//        if (object) {
//            NSLog(@"GOT RELEASE");
//            
//            NSString *reminderString = @"";
//            NSCalendar *theCalendar = [NSCalendar currentCalendar];
//            NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
//            
//            UILocalNotification *localNotification = [[UILocalNotification alloc]init];
//            
//            //set alert string
//            NSString *releaseTime = [object objectForKey:@"releaseTimeString"];
//            
//            reminderString = [NSString stringWithFormat:@"Reminder: the '%@' drops at %@ - Swipe to cop!", [object objectForKey:@"itemTitle"],releaseTime];
//            
//            //attach the link to the notification for web view when opened
//            NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:[object objectForKey:@"itemTitle"],@"itemTitle",nil];
//            localNotification.userInfo = userDict;
//            
//            //set test push to appear 30 seconds later
//            dayComponent.second = 30;
//            NSDate *dateToFire = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
//            [localNotification setFireDate: dateToFire];
//            [localNotification setAlertBody:reminderString];
//            [localNotification setTimeZone: [NSTimeZone localTimeZone]];
//            [localNotification setRepeatInterval: 0];
//            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
//        }
//        else{
//            NSLog(@"couldnt find release");
//        }
//    }];
}

#pragma mark - carousel data queries

-(void)getCarouselData{
    PFQuery *carouselQuery = [PFQuery queryWithClassName:@"HomeItems"];
    [carouselQuery whereKey:@"status" equalTo:@"live"];
    [carouselQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            self.gotCarousel = YES;
            NSMutableArray *shufArray = [NSMutableArray arrayWithArray:objects];
            [self shuffle:shufArray];
            
            NSMutableArray *placeholder = [NSMutableArray arrayWithArray:shufArray];
            
            //move CC event to beginning for new users
            if ([PFUser currentUser] && [self isDateToday:[PFUser currentUser].createdAt] ) {
                for (PFObject *carouselItem in shufArray) {
                    if ([[carouselItem objectForKey:@"type"]isEqualToString:@"cc"]) {
                        [placeholder removeObject:carouselItem];
                        [placeholder insertObject:carouselItem atIndex:0];
                        break;
                    }
                }
            }
            
            self.homeItems = placeholder;
            self.headerView.itemsArray = placeholder;
            [self.headerView.carousel reloadData];
        }
        else{
            NSLog(@"error getting carousel items %@", error);
        }
    }];
}

#pragma  mark - header delegates

-(void)tabHeaderItemSelected:(int)tabNumber{
    [Answers logCustomEventWithName:@"Header Tapped"
                   customAttributes:@{
                                      @"type":@"Releases"
                                      }];
    
    self.tabBarController.selectedIndex = tabNumber;
}

-(void)webHeaderItemSelected:(NSString *)site{
    [Answers logCustomEventWithName:@"Header Tapped"
                   customAttributes:@{
                                      @"type":@"web",
                                      @"site":site
                                      }];
    
    self.web = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:site]];
    self.web.showUrlWhileLoading = YES;
    self.web.showPageTitles = YES;
    self.web.doneButtonTitle = @"";
//    self.web.infoMode = NO;
    self.web.delegate = self;
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.web];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)searchHeaderSelected{
    [Answers logCustomEventWithName:@"Header Tapped"
                   customAttributes:@{
                                      @"type":@"search"
                                      }];
}

-(void)ccHeaderSelectedWithLink:(NSString *)link andText:(NSString *)text{
    
    [Answers logCustomEventWithName:@"Header Tapped"
                   customAttributes:@{
                                      @"type":@"CC"
                                      }];
    eventDetailController *vc = [[eventDetailController alloc]init];
    vc.eventLink = link;
    vc.eventCopy = text;
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)checkIfBanned{
    PFQuery *bannedQuery = [PFQuery queryWithClassName:@"bannedUsers"];
    [bannedQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    [bannedQuery countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
        if (number >= 1) {
            //user is banned - log them out
            
            [Answers logCustomEventWithName:@"Logging Banned User Out"
                           customAttributes:@{
                                              @"from":@"ExploreDidAppear"
                                              }];
            
            
            [PFUser logOut];
            WelcomeViewController *vc = [[WelcomeViewController alloc]init];
            vc.delegate = self;
            self.welcomeShowing = YES;
            NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:navController animated:NO completion:nil];
        }
    }];
}

-(void)checkPushStatus{
    if ([[NSUserDefaults standardUserDefaults]valueForKey:@"declinedDate"]) {
        
        NSDate *declinedDate = [[NSUserDefaults standardUserDefaults]valueForKey:@"declinedDate"];
        
        //check if declined over a week ago
        NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:declinedDate];
        double secondsInADay = 86400;
        NSInteger daysSinceDeclined = distanceBetweenDates / secondsInADay;
        
        if (daysSinceDeclined > 6) {
            //reprompt after a week
            [Answers logCustomEventWithName:@"Reask Push Permissions"
                           customAttributes:@{}];
            
            [self showPushReminder];
        }
        
    }
    else{
        //no decline date so create one now
        [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"declinedDate"];
    }
}


#pragma mark - in app purchase call backs

-(void)purchaseComplete:(NSNotification*)note {
    
    NSString *productId;
    SKPaymentTransaction *transaction;
    BOOL freePurchase = NO;
    
    if ([[note object] isKindOfClass:[NSString class]]) {
        
        //free purchase that has passed the purchase type as notif
        freePurchase = YES;
        productId = [note object];
        
    }
    else{
        //normal purchase
        transaction = [note object];
        productId = transaction.payment.productIdentifier;
    }
    
    //get listing that has been boosted
    
    //we retrieve the listing from defaults and turn off processing purchase

    NSString *listingId = [[NSUserDefaults standardUserDefaults]objectForKey:@"pendingListingPurchase"];
    
    NSLog(@"COMPLETE PURCHASE WITH LISTING: %@   and product: %@", listingId, productId);
    
    if ([productId isEqualToString:@"ryderjack.wtbtest.featuredBoost"]) {
        [Answers logPurchaseWithPrice:[NSDecimalNumber decimalNumberWithString:@"2.99"]
                             currency:@"GBP"
                              success:@YES
                             itemName:@"Feature"
                             itemType:@"Boost"
                               itemId:@"sku-001"
                     customAttributes:@{
                                        @"free":[NSNumber numberWithBool:freePurchase]
                                        }];
        
        [self completeFeaturedPurchaseWith:listingId andTransaction:transaction freePurchase:freePurchase];
    }
    else if ([productId isEqualToString:@"ryderjack.wtbtest.highlightBoost"]) {
        [Answers logPurchaseWithPrice:[NSDecimalNumber decimalNumberWithString:@"0.99"]
                             currency:@"GBP"
                              success:@YES
                             itemName:@"Highlight"
                             itemType:@"Boost"
                               itemId:@"sku-002"
                     customAttributes:@{
                                        @"free":[NSNumber numberWithBool:freePurchase]
                                        }];
        
        [self completeHighlightPurchaseWith:listingId andTransaction:transaction freePurchase:freePurchase];
    }
    else if ([productId isEqualToString:@"ryderjack.wtbtest.searchBoost"]) {
        [Answers logPurchaseWithPrice:[NSDecimalNumber decimalNumberWithString:@"1.99"]
                             currency:@"GBP"
                              success:@YES
                             itemName:@"Search"
                             itemType:@"Boost"
                               itemId:@"sku-003"
                     customAttributes:@{
                                        @"free":[NSNumber numberWithBool:freePurchase]
                                        }];
        
        [self completeSearchBoostPurchaseWith:listingId andTransaction:transaction freePurchase:freePurchase];
    }
}

-(void)completeFeaturedPurchaseWith:(NSString *)listingId andTransaction:(SKPaymentTransaction *)transaction freePurchase:(BOOL)free{
    
    //save featured boost onto object
    PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"wantobuys" objectId:listingId];
    
    [listingObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            
            //set correct boost mode to YES
            [listingObject setObject:@"YES" forKey:@"featuredBoost"];
            
            //set expiry date
            NSCalendar *theCalendar = [NSCalendar currentCalendar];
            NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
            dayComponent.day = 5;
            NSDate *expiryDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
            
            [listingObject setObject:expiryDate forKey:@"featuredBoostExpiry"];
            
            //set boost date
            [listingObject setObject:[NSDate date] forKey:@"featuredBoostStart"];
            
            [listingObject setObject:[NSDate date] forKey:@"lastUpdated"];

            [listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    //custom animation like paypal tick!
                    NSLog(@"SAVED feature boost in explore");
                    
                    [Answers logCustomEventWithName:@"Boost Purchase Successful"
                                   customAttributes:@{
                                                      @"type":@"Featured",
                                                      @"user":[PFUser currentUser].username,
                                                      @"listingId":listingId,
                                                      @"free":[NSNumber numberWithBool:free]
                                                      }];
                    
                    if (!free) {
                        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    }
                    
                    //communicate save to boost controller in case its still showing
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"featurePurchased" object:[NSNumber numberWithBool:YES]];
                    
                    //schedule local push to notify when runs out
                    NSString *listingTitle = [listingObject objectForKey:@"title"];
                    [self scheduleLocalBoostReminder:@"Featured" forListing:listingTitle];
                    
                }
                else{
                    NSLog(@"error saving feature! boost %@", error);
                    
                    [Answers logCustomEventWithName:@"Boost Purchase Failed"
                                   customAttributes:@{
                                                      @"type":@"Featured",
                                                      @"user":[PFUser currentUser].username,
                                                      @"listingId":listingId,
                                                      @"error":@"saving",
                                                      @"free":[NSNumber numberWithBool:free]
                                                      }];
                    
                    if (!free) {
                        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    }
                    
                    //display error alert w/ instructions on how to resave in boost controller
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseError" object:nil];
                    
                    //communicate save to boost controller in case its still showing
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"featurePurchased" object:[NSNumber numberWithBool:NO]];
                    
                    //save this dictionary to array of unfulfilled purchases in NSUserDefaults so upon next launch, can be boosted!
                    NSMutableDictionary *unfulfilledDic = [[NSMutableDictionary  alloc] init];
                    [unfulfilledDic setObject:@"feature" forKey:@"boost"];
                    [unfulfilledDic setObject:listingId forKey:@"listingId"];
                    
                    NSMutableArray *unfulfilledArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"failedPurchases"]];
                    [unfulfilledArray addObject:unfulfilledDic];
                    
                    [[NSUserDefaults standardUserDefaults] setObject:unfulfilledArray forKey:@"failedPurchases"];
                }
            }];
            
        }
        else{
            NSLog(@"error fetching listing %@", error);
            
            [Answers logCustomEventWithName:@"Boost Purchase Failed"
                           customAttributes:@{
                                              @"type":@"Featured",
                                              @"user":[PFUser currentUser].username,
                                              @"listingId":listingId,
                                              @"error":@"fetching listing"
                                              }];
            
            if (!free) {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
            
            //display error alert w/ instructions on how to resave in boost controller
            [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseError" object:nil];
            
            //communicate save to boost controller in case its still showing
            [[NSNotificationCenter defaultCenter] postNotificationName:@"featurePurchased" object:[NSNumber numberWithBool:NO]];
            
            //save this dictionary to array of unfulfilled purchases in NSUserDefaults so upon next launch, can be boosted!
            NSMutableDictionary *unfulfilledDic = [[NSMutableDictionary  alloc] init];
            [unfulfilledDic setObject:@"feature" forKey:@"boost"];
            [unfulfilledDic setObject:listingId forKey:@"listingId"];
            
            NSMutableArray *unfulfilledArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"failedPurchases"]];
            [unfulfilledArray addObject:unfulfilledDic];
            
            [[NSUserDefaults standardUserDefaults] setObject:unfulfilledArray forKey:@"failedPurchases"];
        }
    }];
    
}

-(void)completeSearchBoostPurchaseWith:(NSString *)listingId andTransaction:(SKPaymentTransaction *)transaction freePurchase:(BOOL)free{
    
    //save featured boost onto object
    PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"wantobuys" objectId:listingId];
    
    [listingObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            
            //set correct boost mode to YES
            [listingObject setObject:@"YES" forKey:@"searchBoost"];
            
            //set expiry date
            NSCalendar *theCalendar = [NSCalendar currentCalendar];
            NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
            dayComponent.day = 5;
            NSDate *expiryDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
            
            [listingObject setObject:expiryDate forKey:@"searchBoostExpiry"];
            
            //set boost date
            [listingObject setObject:[NSDate date] forKey:@"searchBoostStart"];
            
            [listingObject setObject:[NSDate date] forKey:@"lastUpdated"];

            [listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    //custom animation like paypal tick!
                    NSLog(@"SAVED search boost in explore");
                    
                    [Answers logCustomEventWithName:@"Boost Purchase Successful"
                                   customAttributes:@{
                                                      @"type":@"Search",
                                                      @"user":[PFUser currentUser].username,
                                                      @"listingId":listingId
                                                      }];
                    
                    if (!free) {
                        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    }
                    //communicate save to boost controller in case its still showing
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"searchPurchased" object:[NSNumber numberWithBool:YES]];
                    
                    //schedule local push to notify when runs out
                    NSString *listingTitle = [listingObject objectForKey:@"title"];
                    [self scheduleLocalBoostReminder:@"Search" forListing:listingTitle];
                    
                }
                else{
                    NSLog(@"error saving search! boost %@", error);
                    
                    [Answers logCustomEventWithName:@"Boost Purchase Failed"
                                   customAttributes:@{
                                                      @"type":@"Search",
                                                      @"user":[PFUser currentUser].username,
                                                      @"listingId":listingId,
                                                      @"error":@"saving"
                                                      }];
                    
                    //finish transaction
                    if (!free) {
                        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    }
                    //communicate save to boost controller in case its still showing
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"searchPurchased" object:[NSNumber numberWithBool:NO]];
                    
                    //display error alert w/ instructions on how to resave in boost controller
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseError" object:nil];
                    
                    //save this dictionary to array of unfulfilled purchases in NSUserDefaults so upon next launch, can be boosted!
                    NSMutableDictionary *unfulfilledDic = [[NSMutableDictionary  alloc] init];
                    [unfulfilledDic setObject:@"search" forKey:@"boost"];
                    [unfulfilledDic setObject:listingId forKey:@"listingId"];
                    
                    NSMutableArray *unfulfilledArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"failedPurchases"]];
                    [unfulfilledArray addObject:unfulfilledDic];
                    
                    [[NSUserDefaults standardUserDefaults] setObject:unfulfilledArray forKey:@"failedPurchases"];
                    
                }
            }];
            
        }
        else{
            NSLog(@"error fetching listing %@", error);
            
            [Answers logCustomEventWithName:@"Boost Purchase Failed"
                           customAttributes:@{
                                              @"type":@"Search",
                                              @"user":[PFUser currentUser].username,
                                              @"listingId":listingId,
                                              @"error":@"fetching listing"
                                              }];
            
            if (!free) {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
            //communicate save to boost controller in case its still showing
            [[NSNotificationCenter defaultCenter] postNotificationName:@"searchPurchased" object:[NSNumber numberWithBool:NO]];
            
            //display error alert w/ instructions on how to resave in boost controller
            [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseError" object:nil];
            
            //save this dictionary to array of unfulfilled purchases in NSUserDefaults so upon next launch, can be boosted!
            NSMutableDictionary *unfulfilledDic = [[NSMutableDictionary  alloc] init];
            [unfulfilledDic setObject:@"search" forKey:@"boost"];
            [unfulfilledDic setObject:listingId forKey:@"listingId"];
            
            NSMutableArray *unfulfilledArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"failedPurchases"]];
            [unfulfilledArray addObject:unfulfilledDic];
            
            [[NSUserDefaults standardUserDefaults] setObject:unfulfilledArray forKey:@"failedPurchases"];
        }
    }];
    
}

-(void)completeHighlightPurchaseWith:(NSString *)listingId andTransaction:(SKPaymentTransaction *)transaction freePurchase:(BOOL)free{
    
    //save featured boost onto object
    PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"wantobuys" objectId:listingId];
    
    [listingObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            
            //set correct boost mode to YES
            [listingObject setObject:@"YES" forKey:@"highlighted"];
            
            //set expiry date
            NSCalendar *theCalendar = [NSCalendar currentCalendar];
            NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
            dayComponent.day = 5;
            NSDate *expiryDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
            
            [listingObject setObject:expiryDate forKey:@"highlightExpiry"];
            
            //set boost date
            [listingObject setObject:[NSDate date] forKey:@"highlightStart"];

            [listingObject setObject:[NSDate date] forKey:@"lastUpdated"];

            [listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    //custom animation like paypal tick!
                    NSLog(@"SAVED highlight boost in explore");
                    
                    [Answers logCustomEventWithName:@"Boost Purchase Successful"
                                   customAttributes:@{
                                                      @"type":@"Highlight",
                                                      @"user":[PFUser currentUser].username,
                                                      @"listingId":listingId
                                                      }];
                    
                    if (!free) {
                        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    }
                    //communicate save to boost controller in case its still showing
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"highlightPurchased" object:[NSNumber numberWithBool:YES]];
                    
                    //schedule local push to notify when runs out
                    NSString *listingTitle = [listingObject objectForKey:@"title"];
                    [self scheduleLocalBoostReminder:@"Highlight" forListing:listingTitle];
                    
                }
                else{
                    NSLog(@"error saving highlight! boost %@", error);
                    
                    [Answers logCustomEventWithName:@"Boost Purchase Failed"
                                   customAttributes:@{
                                                      @"type":@"Highlight",
                                                      @"user":[PFUser currentUser].username,
                                                      @"listingId":listingId,
                                                      @"error":@"saving"
                                                      }];
                    
                    if (!free) {
                        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    }
                    //communicate save to boost controller in case its still showing
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"highlightPurchased" object:[NSNumber numberWithBool:NO]];
                    
                    //display error alert w/ instructions on how to resave in boost controller
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseError" object:nil];
                    
                    //save this dictionary to array of unfulfilled purchases in NSUserDefaults so upon next launch, can be boosted!
                    NSMutableDictionary *unfulfilledDic = [[NSMutableDictionary  alloc] init];
                    [unfulfilledDic setObject:@"highlight" forKey:@"boost"];
                    [unfulfilledDic setObject:listingId forKey:@"listingId"];
                    
                    NSMutableArray *unfulfilledArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"failedPurchases"]];
                    [unfulfilledArray addObject:unfulfilledDic];
                    
                    [[NSUserDefaults standardUserDefaults] setObject:unfulfilledArray forKey:@"failedPurchases"];
                    
                }
            }];
            
        }
        else{
            NSLog(@"error fetching listing %@", error);
            
            [Answers logCustomEventWithName:@"Boost Purchase Failed"
                           customAttributes:@{
                                              @"type":@"Highlight",
                                              @"user":[PFUser currentUser].username,
                                              @"listingId":listingId,
                                              @"error":@"fetching listing"
                                              }];
            
            if (!free) {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
            //communicate save to boost controller in case its still showing
            [[NSNotificationCenter defaultCenter] postNotificationName:@"highlightPurchased" object:[NSNumber numberWithBool:NO]];
            
            //display error alert w/ instructions on how to resave in boost controller
            [[NSNotificationCenter defaultCenter] postNotificationName:@"purchaseError" object:nil];
            
            //save this dictionary to array of unfulfilled purchases in NSUserDefaults so upon next launch, can be boosted!
            NSMutableDictionary *unfulfilledDic = [[NSMutableDictionary  alloc] init];
            [unfulfilledDic setObject:@"highlight" forKey:@"boost"];
            [unfulfilledDic setObject:listingId forKey:@"listingId"];
            
            NSMutableArray *unfulfilledArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"failedPurchases"]];
            [unfulfilledArray addObject:unfulfilledDic];
            
            [[NSUserDefaults standardUserDefaults] setObject:unfulfilledArray forKey:@"failedPurchases"];
        }
    }];
    
}

-(void)purchaseFailedExplore:(NSNotification*)note {
    
    SKPaymentTransaction *transaction = [note object];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

    NSString *productId = transaction.payment.productIdentifier;
    
    [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"processingPurchase"];
    
    if ([productId isEqualToString:@"ryderjack.wtbtest.featuredBoost"]) {
        
        [Answers logPurchaseWithPrice:[NSDecimalNumber decimalNumberWithString:@"2.99"]
                             currency:@"GBP"
                              success:@NO
                             itemName:@"Feature"
                             itemType:@"Boost"
                               itemId:@"sku-001"
                     customAttributes:@{}];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"featurePurchased" object:[NSNumber numberWithBool:NO]];
    }
    else if ([productId isEqualToString:@"ryderjack.wtbtest.highlightBoost"]) {
        [Answers logPurchaseWithPrice:[NSDecimalNumber decimalNumberWithString:@"0.99"]
                             currency:@"GBP"
                              success:@NO
                             itemName:@"Highlight"
                             itemType:@"Boost"
                               itemId:@"sku-002"
                     customAttributes:@{}];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"highlightPurchased" object:[NSNumber numberWithBool:NO]];
    }
    else if ([productId isEqualToString:@"ryderjack.wtbtest.searchBoost"]) {
        [Answers logPurchaseWithPrice:[NSDecimalNumber decimalNumberWithString:@"1.99"]
                             currency:@"GBP"
                              success:@NO
                             itemName:@"Search"
                             itemType:@"Boost"
                               itemId:@"sku-003"
                     customAttributes:@{}];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"searchPurchased" object:[NSNumber numberWithBool:NO]];
    }
}

-(void)saveFailedBoostWithDict:(NSDictionary *)failedPurchaseDict{
    
    NSString *listingId = [failedPurchaseDict objectForKey:@"listingId"];
    NSString *mode = [failedPurchaseDict objectForKey:@"boost"];
    
    PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"wantobuys" objectId:listingId];
    
    [listingObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            
            //calc expiry date
            NSCalendar *theCalendar = [NSCalendar currentCalendar];
            NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
            dayComponent.day = 5;
            NSDate *expiryDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
            
            if ([mode isEqualToString:@"highlight"]) {
                [listingObject setObject:@"YES" forKey:@"highlighted"];
                [listingObject setObject:expiryDate forKey:@"highlightExpiry"];
                [listingObject setObject:[NSDate date] forKey:@"highlightStart"];
            }
            else if ([mode isEqualToString:@"search"]){

                [listingObject setObject:@"YES" forKey:@"searchBoost"];
                [listingObject setObject:expiryDate forKey:@"searchBoostExpiry"];
                [listingObject setObject:[NSDate date] forKey:@"searchBoostStart"];
            }
            else if ([mode isEqualToString:@"feature"]){

                [listingObject setObject:@"YES" forKey:@"featuredBoost"];
                [listingObject setObject:expiryDate forKey:@"featuredBoostExpiry"];
                [listingObject setObject:[NSDate date] forKey:@"featuredBoostStart"];
            }
            
            [listingObject setObject:[NSDate date] forKey:@"lastUpdated"];

            [listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    
                    //remove from failed purchases array in defaults
                    NSMutableArray *unfulfilledArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"failedPurchases"]];
                    [unfulfilledArray removeObject:failedPurchaseDict];
                    [[NSUserDefaults standardUserDefaults] setObject:unfulfilledArray forKey:@"failedPurchases"];
                    
                    [Answers logCustomEventWithName:@"Boost REPurchase Successful"
                                   customAttributes:@{
                                                      @"type":mode,
                                                      @"user":[PFUser currentUser].username,
                                                      @"listingId":listingId
                                                      }];
                }
                else{
                    NSLog(@"error resaving boost %@", error);
                    
                    [Answers logCustomEventWithName:@"Boost REPurchase Failed"
                                   customAttributes:@{
                                                      @"type":mode,
                                                      @"user":[PFUser currentUser].username,
                                                      @"listingId":listingId,
                                                      @"error":@"saving"
                                                      }];
                }
            }];
            
        }
        else{
            NSLog(@"error fetching listing %@", error);
            
            [Answers logCustomEventWithName:@"Boost REPurchase Failed"
                           customAttributes:@{
                                              @"type":mode,
                                              @"user":[PFUser currentUser].username,
                                              @"listingId":listingId,
                                              @"error":@"fetching listing"
                                              }];
        }
    }];
    
}

-(void)sendFreeBoostMessage{
    
    PFUser *currentUser = [PFUser currentUser];
    
    //create and save FREE boost object then send the message
    PFObject *freeBoostObj = [PFObject objectWithClassName:@"freeBoosts"];
    [freeBoostObj setObject: currentUser forKey:@"user"];
    [freeBoostObj setObject:@"live" forKey:@"status"];
    [freeBoostObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            
            //save Boost message
            NSString *messageString1 = @"⚡️ Introducing Boost ⚡️\n\nWhenever you list a wanted item on Bump you can now get it seen by thousands more sellers just by tapping the Boost icon!\n\nWe're feeling generous so have a FREE Boost on us 😝\n\nSophie @ Team Bump";
            
            //now save Boost intro message
            PFObject *messageObject1 = [PFObject objectWithClassName:@"teamBumpMsgs"];
            messageObject1[@"message"] = messageString1;
            messageObject1[@"sender"] = [PFUser currentUser];
            messageObject1[@"senderId"] = @"BUMP";
            messageObject1[@"senderName"] = @"Team Bump";
            messageObject1[@"convoId"] = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
            messageObject1[@"status"] = @"sent";
            messageObject1[@"offer"] = @"NO";
            messageObject1[@"mediaMessage"] = @"NO";
            messageObject1[@"boostMessage"] = @"YES";
            
            [messageObject1 saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    //update convo
                    
                    PFQuery *convoQuery = [PFQuery queryWithClassName:@"teamConvos"];
                    NSString *convoId = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
                    [convoQuery whereKey:@"convoId" equalTo:convoId];
                    [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                        if (object) {
                            
                            //got the convo
                            [object incrementKey:@"totalMessages"];
                            [object setObject:messageObject1 forKey:@"lastSent"];
                            [object setObject:[NSDate date] forKey:@"lastSentDate"];
                            [object incrementKey:@"userUnseen"];
                            [object saveInBackground];
                            
                            currentUser[@"freeFirstBoost"] = @"YES";
                            [currentUser saveInBackground];
                                                        
                            [Answers logCustomEventWithName:@"Sent Boost Message"
                                           customAttributes:@{
                                                              @"status":@"SENT"
                                                              }];
                            
                            UIImage *image = [UIImage imageNamed:@"boostMessageImg"];
                            NSData *data =  UIImagePNGRepresentation(image);
                            PFFile *filePicture = [PFFile fileWithData:data];
                            
                            PFObject *picObject = [PFObject objectWithClassName:@"teamBumpmMsgImages"];
                            [picObject setObject:filePicture forKey:@"Image"];
                            [picObject setObject:object forKey:@"convo"];
                            [picObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                if (succeeded) {
                                    NSLog(@"saved pic");
                                    
                                    PFObject *imgMessage = [PFObject objectWithClassName:@"teamBumpMsgs"];
                                    imgMessage[@"message"] = picObject.objectId;
                                    imgMessage[@"sender"] = currentUser;
                                    imgMessage[@"senderId"] = @"BUMP";
                                    imgMessage[@"senderName"] = @"Team Bump";
                                    imgMessage[@"convoId"] = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
                                    imgMessage[@"status"] = @"sent";
                                    imgMessage[@"mediaMessage"] = @"YES";
                                    
                                    [imgMessage saveInBackground];
                                    
                                }
                                else{
                                    NSLog(@"error saving pic %@", error);
                                }
                            }];
                            
                        }
                        else{
                            [Answers logCustomEventWithName:@"Sent Boost Message"
                                           customAttributes:@{
                                                              @"status":@"Failed getting convo"
                                                              }];
                        }
                    }];
                }
                else{
                    NSLog(@"error saving boost message %@", error);
                    [Answers logCustomEventWithName:@"Sent Boost Message"
                                   customAttributes:@{
                                                      @"status":@"Failed saving message"
                                                      }];
                }
            }];
        }
        else{
            [Answers logCustomEventWithName:@"Sent Boost Message"
                           customAttributes:@{
                                              @"status":@"Failed saving free boost"
                                              }];
        }
    }];
}

-(void)showSellerApp{
    mainApprovedSellerController *vc = [[mainApprovedSellerController alloc]init];
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)scheduleLocalBoostReminder:(NSString *)boostType forListing:(NSString *)listingTitle{
    
    [Answers logCustomEventWithName:@"Scheduling local boost reminder"
                   customAttributes:@{}];
    
    //schedule 6 day inactivity local notification
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.second = 30;
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *dateToFire = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc]init];
    [localNotification setAlertBody:[NSString stringWithFormat:@"Boost expired ⚡️⏰ %@ Boost for your '%@' listing has just expired", boostType, listingTitle]];
    [localNotification setFireDate: dateToFire];
    [localNotification setTimeZone: [NSTimeZone defaultTimeZone]];
    [localNotification setRepeatInterval: 0];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
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

-(BOOL)signedUpOver10MinsAgo{
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                        fromDate:[PFUser currentUser].createdAt
                                                          toDate:[NSDate date]
                                                         options:0];
    
    if ([components minute] >= 10) {
        gregorianCalendar = nil;
        components = nil;
        return YES;
    }
    else{
        gregorianCalendar = nil;
        components = nil;
        return NO;
    }
}

#pragma table view delegates

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0 || section == 1) {
        return 1;
    }
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        return self.wantedCell;
    }
    else if (indexPath.section == 1) {
        return self.sellingCell;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0 || indexPath.section == 1) {
        return 232;
    }
    return 0;
}

#pragma table view section headers

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0 || section == 1) {
        return 60.0;
    }
    return 32.0f;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    if (section == 0 || section == 1) {
        UILabel *lblSectionName = [[UILabel alloc] init];
        lblSectionName.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        lblSectionName.textColor = [UIColor grayColor];
        if (section == 0) {
            lblSectionName.text = @"These buyers are interested in items similar to what you're selling, send them a message!";
        }
        else{
            lblSectionName.text = @"Based on your wanted listings you may be interested in these items for sale";
        }
        lblSectionName.numberOfLines = 0;
        lblSectionName.textAlignment = NSTextAlignmentCenter;
        lblSectionName.lineBreakMode = NSLineBreakByWordWrapping;
        lblSectionName.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
        
        [lblSectionName sizeToFit];
        
        return lblSectionName;
    }
    return nil;
}

#pragma mark - swipe view delegates

-(UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view{
    
    
    if (swipeView == self.wantedSwipeView) {
        UIView *innerView;
        
        if (view == nil)
        {
            
            //create an inner view so can control padding between cells
            
            NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:@"SmallWantedCell"
                                                              owner:self
                                                            options:nil];
            innerView = (UIView*)[nibViews objectAtIndex:0];
            
            if ([(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"]){
                //iPad (needs to be first as iPad can run in iPhone mode so screen size is same as an iPhones)
                view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 160,210)];
                [innerView setFrame:CGRectMake(0, 0, 140, 210)];
            }
            else if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                //iphone5
                view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 175,215)];
                [innerView setFrame:CGRectMake(0, 0, 148, 215)];
            }
            else if([ [ UIScreen mainScreen ] bounds ].size.height == 736){
                //iphone 7 plus
                view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 220,285)];
                [innerView setFrame:CGRectMake(0, 0, 196, 285)];
                
            }
            else if([ [ UIScreen mainScreen ] bounds ].size.height == 480){
                //iphone 4
                view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140,185)]; //change these for screen sizes
                [innerView setFrame:CGRectMake(0, 0, 124, 180)];
            }
            else{
                //iPhone 6 specific
                view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140,164)];
                [innerView setFrame:CGRectMake(0, 0, 112, 154)];
            }
            
            view.backgroundColor = [UIColor clearColor];
            innerView.backgroundColor = [UIColor whiteColor];
            
            //set corner radius
            innerView.layer.cornerRadius = 4;
            innerView.layer.masksToBounds = YES;
            
            [view addSubview:innerView];
            innerView.center = view.center;
            
        }
        else{
            innerView = [[view subviews] lastObject];
            
        }
        
        ((SmallWantedCell *)innerView).itemImageView.image = nil;
        
        PFObject *listing = [self.wantedMatches objectAtIndex:index];
        
        
        [((SmallWantedCell *)innerView).itemImageView setFile:[listing objectForKey:@"image1"]];
        [((SmallWantedCell *)innerView).itemImageView loadInBackground];
        
        NSString *titleString = [listing objectForKey:@"title"];
        NSString *sizeString = @"";
        
        if ([listing objectForKey:@"sizeLabel"]) {
            
            if (![[listing objectForKey:@"category"]isEqualToString:@"footwear"]) {
                //clothing
                NSString *sizeNoUK = [[listing objectForKey:@"sizeLabel"] stringByReplacingOccurrencesOfString:@"UK" withString:@""];
                sizeNoUK = [sizeNoUK stringByReplacingOccurrencesOfString:@" " withString:@""];
                
                if ([sizeNoUK isEqualToString:@"S"]){
                    sizeString = @"Small";
                }
                else if ([sizeNoUK isEqualToString:@"M"]){
                    sizeString = @"Medium";
                }
                else if ([sizeNoUK isEqualToString:@"L"]){
                    sizeString = @"Large";
                }
                else if ([sizeNoUK isEqualToString:@"XXS"]){
                    sizeString = @"XXSmall";
                }
                else if ([sizeNoUK isEqualToString:@"XS"]){
                    sizeString = @"XSmall";
                }
                else if ([sizeNoUK isEqualToString:@"XXL"]){
                    sizeString = @"XXLarge";
                }
                else if ([sizeNoUK isEqualToString:@"XL"]){
                    sizeString = @"XLarge";
                }
                else{
                    sizeString = sizeNoUK;
                }
            }
            else{
                
                sizeString = [listing objectForKey:@"sizeLabel"];
            }
        }
        else{
            sizeString = @"";
        }
        
        NSString *descLabelText = [NSString stringWithFormat:@"%@\n%@",titleString,sizeString];
        NSMutableAttributedString *descrText = [[NSMutableAttributedString alloc] initWithString:descLabelText];
        [self modifyString:descrText setColorForText:sizeString withColor:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]];
        ((SmallWantedCell *)innerView).itemLowerLabel.attributedText = descrText;
    }
    else{
        //for sale swipe view
        
    }
    return view;
}

-(void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index{
    PFObject *listingObject = [self.wantedMatches objectAtIndex:index];
    ListingController *vc = [[ListingController alloc]init];
    vc.listingObject = listingObject;
    self.listingTapped = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

-(NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView{
    return self.wantedMatches.count;
}

-(void)getWantedMatches{
    //find WTBs where the keywords have at least a 60% match to user's available items for sale
    //call server & pass the number bcoz of array counting bug with cloud code
    
    PFQuery *forSaleQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [forSaleQuery whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
    [forSaleQuery whereKey:@"status" equalTo:@"live"];
    [forSaleQuery orderByDescending:@"lastUpdated"];
    forSaleQuery.limit = 10;
    [forSaleQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            if (objects.count > 0) {
                [self.noForSaleItemLabel setHidden:YES];

                //keep track of how many for sale items we've searched on
                __block int itemCount = 0;
                NSMutableArray *holdingArray = [NSMutableArray array];

                for (PFObject *forSaleItem in objects) {
                    
                    //fire off PFCloud function for each to retrieve relevant WTBs
                    NSArray *keywords = [forSaleItem objectForKey:@"keywords"];
                    
                    
                    NSDictionary *params = @{@"saleItemKeywords":keywords, @"wantNumber":[NSNumber numberWithInt:itemCount]};
                    
                    [PFCloud callFunctionInBackground:@"wantedSearch" withParameters:params block:^(NSArray *response, NSError *error) {
                        if (!error) {
                            itemCount++;

                            NSArray *matchingWTBArray = response;
                            NSLog(@"WANTED SEARCH RESP %@", matchingWTBArray);
                            
                            //if matches array key is empty don't recommend anything
                            if ( matchingWTBArray.count ==0){
                                //do nothing as have no matches from our sellers network
                                NSLog(@"no matches from seller network so don't add this dictionary to array");
                            }
                            else{
                                //don't add duplicates
                                for (PFObject *WTB in matchingWTBArray) {
                                    if (![holdingArray containsObject:WTB]) {
                                        [holdingArray addObject:WTB];
                                    }
                                }
                            }
                            
                            if (itemCount == objects.count) {
                                NSLog(@"finished checking for WTB matches from last 10 for sale items");
                                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                                                    initWithKey: @"lastUpdated" ascending: NO];
                                NSArray *sortedArray = [holdingArray sortedArrayUsingDescriptors: [NSArray arrayWithObject:sortDescriptor]];
                                
                                [self.wantedMatches removeAllObjects];
                                [self.wantedMatches addObjectsFromArray:sortedArray];
                                [self.wantedSwipeView reloadData];
                            }
                        }
                        else{
                            itemCount++;

                            NSLog(@"error  from wantedSearch func %@", error);
                        }
                    }];
                }
                
                
            }
            else{
                NSLog(@"no items for sale");
                [self.noForSaleItemLabel setHidden:NO];
            }
        }
        else{
            NSLog(@"error finding for sale items %@", error);
        }
    }];
}

-(void)getSellingMatches{
    //find for sale listings where the keywords have at least a 60% match to user's available items for sale
    //call server & pass the number bcoz of array counting bug with cloud code
    
    PFQuery *WTBQuery = [PFQuery queryWithClassName:@"wantobuys"];
    [WTBQuery whereKey:@"postUser" equalTo:[PFUser currentUser]];
    [WTBQuery whereKey:@"status" equalTo:@"live"];
    [WTBQuery orderByDescending:@"lastUpdated"];
    WTBQuery.limit = 10;
    [WTBQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            if (objects.count > 0) {
                [self.noWantedListingLabel setHidden:YES];

                //keep track of how many for sale items we've searched on
                __block int itemCount = 0;
                NSMutableArray *holdingArray = [NSMutableArray array];
                
                for (PFObject *WTB in objects) {
                    
                    //fire off PFCloud function for each to retrieve relevant for sale items
                    NSArray *keywords = [WTB objectForKey:@"searchKeywords"];
                    
                    NSDictionary *params = @{@"wantedKeywords":keywords, @"wantNumber":[NSNumber numberWithInt:itemCount]};
                    
                    [PFCloud callFunctionInBackground:@"sellingSearch" withParameters:params block:^(NSArray *response, NSError *error) {
                        if (!error) {
                            itemCount++;
                            
                            NSArray *matchingForSaleArray = response;
                            NSLog(@"SELLING SEARCH RESP %@", matchingForSaleArray);
                            
                            //if matches array key is empty don't recommend anything
                            if ( matchingForSaleArray.count ==0){
                                //do nothing as have no matches from our sellers network
                                NSLog(@"no matches - selling");
                            }
                            else{
                                //don't add duplicates
                                for (PFObject *forSale in matchingForSaleArray) {
                                    if (![holdingArray containsObject:forSale]) {
                                        [holdingArray addObject:forSale];
                                    }
                                }
                            }
                            
                            if (itemCount == objects.count) {
                                NSLog(@"finished checking for for sale matches from last 10 wanted items");
                                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                                                    initWithKey: @"lastUpdated" ascending: NO];
                                NSArray *sortedArray = [holdingArray sortedArrayUsingDescriptors: [NSArray arrayWithObject:sortDescriptor]];
                                
                                [self.sellingMatches removeAllObjects];
                                [self.sellingMatches addObjectsFromArray:sortedArray];
                                [self.sellingSwipeView reloadData];
                            }
                        }
                        else{
                            itemCount++;
                            
                            NSLog(@"error  from sellingSearch func %@", error);
                        }
                    }];
                }
                
                
            }
            else{
                NSLog(@"no wanted listings");
                [self.noWantedListingLabel setHidden:NO];
            }
        }
        else{
            NSLog(@"error finding for wanted items %@", error);
        }
    }];
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

@end
