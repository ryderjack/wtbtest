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
#import "mainApprovedSellerController.h"
#import "ExploreVC.h"
#import "detailSellingCell.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "AppConstant.h"
#import "AddSizeController.h"
#import "ExplainView.h"
#import "AppDelegate.h"

@interface PurchaseTab ()

@end

@implementation PurchaseTab

@synthesize locationManager = _locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.noResultsLabel setHidden:YES];
    
    //setup search bar
    self.navSearchbar = [[UISearchBar alloc]init];
    self.navSearchbar.placeholder = @"Search";
    self.navSearchbar.delegate = self;
    UITextField *txfSearchField = [self.navSearchbar valueForKey:@"searchField"];
    txfSearchField.backgroundColor =[UIColor colorWithRed:0.18 green:0.17 blue:0.18 alpha:1.0];
    [txfSearchField setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:@"Search" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}]];
    UIImageView *imgView = (UIImageView*)txfSearchField.leftView;
    imgView.image = [imgView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    imgView.tintColor = [UIColor whiteColor];
    self.navigationItem.titleView = self.navSearchbar;

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    //collection view setup
    // Register cell classes
    [self.collectionView registerClass:[detailSellingCell class] forCellWithReuseIdentifier:@"Cell"];
    UINib *cellNib = [UINib nibWithNibName:@"detailSellingCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    //calc screen width to avoid hard coding but bug with collection view so width always = 1000
    
    if ([ [ UIScreen mainScreen ] bounds ].size.width == 375) {
        //iPhone6/7
        [flowLayout setItemSize:CGSizeMake(175,222)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
        //iPhone 6 plus
        [flowLayout setItemSize:CGSizeMake(195, 247)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.width == 320){
        //iPhone 4/5
        [flowLayout setItemSize:CGSizeMake(148, 188)];
    }
    else{
        //fall back
        [flowLayout setItemSize:CGSizeMake(175,222)];
    }
    
    [flowLayout setMinimumInteritemSpacing:8.0];
    [flowLayout setMinimumLineSpacing:8.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    flowLayout.headerReferenceSize = CGSizeMake([UIApplication sharedApplication].keyWindow.frame.size.width, 40);
    flowLayout.sectionHeadersPinToVisibleBounds = NO;
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.dataSource = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    //setup header
    [self.collectionView registerNib:[UINib nibWithNibName:@"simpleBannerHeader" bundle:nil]
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                 withReuseIdentifier:@"Header"];
    
    self.products = [NSMutableArray array];
    self.productIds = [NSMutableArray array];
    
    self.skipped = 0;
    
    self.pullFinished = YES;
    self.infinFinished = YES;
    
    [self.anotherPromptButton setHidden:YES];
    
    self.spinnerHUD = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
//    self.navigationController.hidesBarsOnSwipe = YES;
    
    //OBSERVERS
    //navigation
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ensureNavShowing) name:@"ensureNavShowing" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBump:) name:@"showBumpedVC" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showListing:) name:@"listingBumped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSaleListing:) name:@"saleListingBumped" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bigLogOut) name:@"invalidSessionNotification" object:nil];
    
    //update data
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetHome) name:@"refreshHome" object:nil];
    
    //listed an item
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPostingHeader:) name:@"hitListItem" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertLatestListing:) name:@"justPostedSaleListing" object:nil];
    
    //drop down
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBumpDrop:) name:@"showBumpedDropDown" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageSentDrop:) name:@"messageSentDropDown" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showScreenShot:) name:@"screenshotDropDown" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissDrop) name:@"removeDrop" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDrop:) name:@"showDropDown" object:nil];
    
    //pop up triggers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setUpRateViewWithNav:) name:@"showRate" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showInviteView) name:@"showInvite" object:nil];
    
    //verify email
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verifyEmailInHome) name:@"verifyEmail" object:nil];
    
    //location stuff
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"askedForLocationPermission"] || [[[PFUser currentUser]objectForKey:@"completedReg"]isEqualToString:@"YES"]) {
        
        //for users that have already seen the location diaglog before this update - use the completedReg BOOL to check
        if ([[NSUserDefaults standardUserDefaults]boolForKey:@"askedForLocationPermission"]==NO) {
            [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"askedForLocationPermission"];
        }
        self.locationAllowed = [CLLocationManager locationServicesEnabled];
        [self startLocationManager];
    }
    
    PFUser *currentUser = [PFUser currentUser];
    
    if (currentUser) {
        NSLog(@"got a current user");
        if (![FBSDKAccessToken currentAccessToken] && [currentUser objectForKey:@"facebookId"]) {
            NSLog(@"invalid fb token in VDL");
            
            //invalid access token
            [PFUser logOut];
            WelcomeViewController *vc = [[WelcomeViewController alloc]init];
            vc.delegate = self;
            NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:navController animated:YES completion:nil];
        }
        
        else if (![[currentUser objectForKey:@"completedReg"] isEqualToString:@"YES"]) {
            [Answers logCustomEventWithName:@"Registration error"
                           customAttributes:@{
                                              @"error":@"hasn't completed reg",
                                              @"user":currentUser.username
                                              }];
            [PFUser logOut];
            WelcomeViewController *vc = [[WelcomeViewController alloc]init];
            vc.delegate = self;
            NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:navController animated:NO completion:nil];
        }
        
        //check if all essential info saved from reg - if not then let them do it again
        
        else if (![currentUser objectForKey:PF_USER_FULLNAME] || ![currentUser objectForKey:PF_USER_EMAIL] || ![currentUser objectForKey:@"currency"] || currentUser.username.length >20) { //CHECK
            
            //been an error on sign up as user doesn't have all info saved / error with username
            NSLog(@"lack of info after signing up");
            
            [Answers logCustomEventWithName:@"Registration error"
                           customAttributes:@{
                                              @"error":@"lack of info",
                                              @"user":currentUser.username
                                              }];
            
            currentUser[@"completedReg"] = @"NO";
            [currentUser saveInBackground];
            [PFUser logOut];
            
            WelcomeViewController *vc = [[WelcomeViewController alloc]init];
            vc.delegate = self;
            NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:navController animated:NO completion:nil];
        }
        else{
            [self getLatestForSale];
            
            [self sendFeedbackMessage];
            
            //convert old style emailVerified key to new one so we can update it on the client
            if ([[currentUser objectForKey:@"emailVerified"]boolValue] == YES && [[currentUser objectForKey:@"emailIsVerified"]boolValue] != YES){
                [currentUser setObject:[NSNumber numberWithBool:YES] forKey:@"emailIsVerified"];
                [currentUser saveInBackground];
            }

            //user has signed up fine, do final checks & loading
            //get updated friends list if connected with FB
            if ([[PFUser currentUser]objectForKey:@"facebookId"]) {
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
                            NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
                            [self presentViewController:navController animated:YES completion:nil];
                        }
                        else{
                            [self showError];
                        }
                    }
                }];
            }
            
            //check if need to see new explain VC (if signed up earlier than that update)
            NSCalendar *theCalendar = [NSCalendar currentCalendar];
            NSDateComponents *components3 = [[NSDateComponents alloc] init];
            [components3 setYear:2017];
            [components3 setMonth:7];
            [components3 setDay:24];
            NSDate * combinedDate = [theCalendar dateFromComponents:components3];
            
            if( [[PFUser currentUser].createdAt timeIntervalSinceDate:combinedDate] < 0 && ![[PFUser currentUser]objectForKey:@"seenChangeVC"]) {
                ExplainView *vc = [[ExplainView alloc]init];
                vc.changedMode = YES;
                [self presentViewController:vc animated:YES completion:nil];
            }
            
            //check if user has deviceToken set for tracking / banning purposes
            if (![[PFUser currentUser]objectForKey:@"deviceToken"]) {
                NSLog(@"no device token!");

                PFInstallation *installation = [PFInstallation currentInstallation];
                
                //protect agains
                if (installation.deviceToken) {
                    NSLog(@"installation %@", installation);
                    
//                    [[PFUser currentUser] setObject:installation.deviceToken forKey:@"deviceToken"];
//                    [[PFUser currentUser]saveInBackground];
                }
            }
            
            //check if declined push permissions and if need to ask again
            if ([[NSUserDefaults standardUserDefaults]boolForKey:@"declinedPushPermissions"]== YES && [[currentUser objectForKey:@"completedReg"] isEqualToString:@"YES"]) {
                [self checkPushStatus];
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
                        NSLog(@"no deals info");
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
            
            // finally check if they've been banned - put it last because otherwise if logout user from a previous user check this will still run and throw error 'can't do a comparison query for type (null)
            [self checkIfBanned];
        }
    }
    
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
                    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"New update available 📲" message:nil preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                        [Answers logCustomEventWithName:@"Cancel Update pressed"
                                       customAttributes:@{}];
                    }]];
                    [alertView addAction:[UIAlertAction actionWithTitle:@"Update" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        [Answers logCustomEventWithName:@"Update pressed"
                                       customAttributes:@{}];
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:
                                                                    @"itms-apps://itunes.apple.com/app/id1096047233"]];
                    }]];
                    [self presentViewController:alertView animated:YES completion:nil]; //CHANGE
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
    
    //filter setup
    self.filtersArray = [NSMutableArray array];
    self.filterSizesArray = [NSMutableArray array];
    self.filterBrandsArray = [NSMutableArray array];
    self.filterColoursArray = [NSMutableArray array];
    self.filterCategory = @"";

//    [PFUser logOut]; //CHECK
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
            [self getLatestForSale];
        }
    }];
    
    self.spinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
    [self.collectionView.pullToRefreshView setCustomView:self.spinner forState:SVPullToRefreshStateAll];
    [self.spinner startAnimating];
    
    [self.collectionView addInfiniteScrollingWithActionHandler:^{
        if (self.infinFinished == YES) {
            //infinity query
            [self infinLatestForSale];
        }
    }];
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(8, 8, 8, 8); // top, left, bottom, right
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:12],
                                    NSFontAttributeName, [UIColor blackColor], NSForegroundColorAttributeName,  nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setBarTintColor: [UIColor colorWithRed:0.11 green:0.11 blue:0.11 alpha:1.0]];
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Home"
                                      }];
    
    if (![PFUser currentUser]) {
        WelcomeViewController *vc = [[WelcomeViewController alloc]init];
        vc.delegate = self;
        NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navController animated:NO completion:nil];
    }
    else{

        self.currency = [[PFUser currentUser]objectForKey:@"currency"];
        if ([self.currency isEqualToString:@"GBP"]) {
            self.currencySymbol = @"£";
        }
        else if ([self.currency isEqualToString:@"EUR"]) {
            self.currencySymbol = @"€";
        }
        else if ([self.currency isEqualToString:@"USD"] || [self.currency isEqualToString:@"AUD"]) {
            self.currencySymbol = @"$";
        }
    }
    
    if (self.tappedItem == YES) {
        self.tappedItem = NO;
    }
    
    //to make sure infin not always spinning
    [self.infiniteQuery cancel];
    [self.collectionView.infiniteScrollingView stopAnimating];
    self.infinFinished = YES;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
        
    BOOL modalPresent = (self.presentedViewController);
    if ([PFUser currentUser] && modalPresent != YES) {
        
        //show filter intro
        if (![[[PFUser currentUser] objectForKey:@"filterIntro"] isEqualToString:@"YES"] && [[[PFUser currentUser] objectForKey:@"completedReg"] isEqualToString:@"YES"]) {
            
            if (modalPresent != YES) {
                self.filterIntro = YES;
                [self showPushReminder];
            }
        }
        //if user redownloaded - ask for push/location permissions again
        else if ([[NSUserDefaults standardUserDefaults]boolForKey:@"askedForPushPermission"] == NO && [[[PFUser currentUser] objectForKey:@"completedReg"]isEqualToString:@"YES"] && [[NSUserDefaults standardUserDefaults]boolForKey:@"declinedPushPermissions"] != YES && modalPresent != YES) {
            
            [self parseLocation];
            
            self.filterIntro = NO;
            [self showPushReminder];
        }
        //check if user has entered sizes
        else if (![[PFUser currentUser]objectForKey:@"sizeCountry"] && modalPresent != YES) {
            AddSizeController *vc = [[AddSizeController alloc]init];
            [self.navigationController presentViewController:vc animated:YES completion:nil];
        }
        else{
            //check if banned everytime they come back to home? //CHECK
            [self checkIfBanned];
            
            //get location for filter searches
            [self parseLocation];
        }
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.products.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    detailSellingCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.itemImageView.image = nil;
    [cell.itemImageView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    PFObject *forSaleItem = [self.products objectAtIndex:indexPath.row];
    
    //set image
    [cell.itemImageView setFile:[forSaleItem objectForKey:@"thumbnail"]]; //was image1
    [cell.itemImageView loadInBackground];

    //so first image in listing is loaded faster
    PFFile *image = [forSaleItem objectForKey:@"image1"];
    [image getDataInBackground];
    
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
        if ([conditionString isEqualToString:@"BNWT"] || [conditionString isEqualToString:@"BNWOT"]|| [conditionString isEqualToString:@"Deadstock"]) {
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
    
//    //nslog item title and distance
//    PFGeoPoint *location = [forSaleItem objectForKey:@"geopoint"];
//    if (self.currentLocation && location) {
//        int distance = [location distanceInKilometersTo:self.currentLocation];
//        NSLog(@"TITLE %@   DISTANCE: %@", [forSaleItem objectForKey:@"itemTitle"] ,[NSString stringWithFormat:@"%dkm", distance]);
//    }
//    else{
//        NSLog(@"no location data %@ %@", self.currentLocation, location);
//    }
    
        return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{

    self.tappedItem = YES;

    [Answers logCustomEventWithName:@"Tapped Buy Now Item"
                   customAttributes:@{
                                      @"type":@"for sale"
                                      }];
    
    PFObject *itemObject = [self.products objectAtIndex:indexPath.row];
    
    ForSaleListing *vc = [[ForSaleListing alloc]init];
    vc.listingObject = itemObject;
    vc.source = @"latest";
    vc.fromBuyNow = YES;
    vc.pureWTS = YES;
    //switch off hiding nav bar
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController pushViewController:vc animated:YES];
    
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    self.headerView = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        self.headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
        
        [self.headerView.headerImageView setHidden:YES];
        [self.headerView.simpleHeaderLabel setTextAlignment:NSTextAlignmentCenter];
        [self.headerView.simpleHeaderLabel setTextColor:[UIColor whiteColor]];
        
        if ([PFUser currentUser]) {
            if ([[[PFUser currentUser] objectForKey:@"emailIsVerified"]boolValue] != YES && ![[PFUser currentUser]objectForKey:@"facebookId"]) {
                //user isn't verified at all, show a prompt
                [self.headerView setBackgroundColor:[UIColor colorWithRed:1.00 green:0.75 blue:0.33 alpha:1.0]];
                self.headerView.simpleHeaderLabel.text = @"Verify your email to list items for sale";
            }
            else{
                //all good
                [self.headerView setBackgroundColor:[UIColor colorWithRed:0.42 green:0.42 blue:0.84 alpha:1.0]];
                self.headerView.simpleHeaderLabel.text = @"Latest items for sale";
            }
        }
        
        if (self.postingMode == YES) {
            [self.headerView.headerImageView setImage:self.bannerImage];
            [self.headerView.headerImageView setHidden:NO];
            [self.headerView.simpleHeaderLabel setTextAlignment:NSTextAlignmentLeft];
            [self.headerView setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
            self.headerView.simpleHeaderLabel.text = @"Posting";
            [self.headerView.simpleHeaderLabel setTextColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0]];
        }

    }
    return self.headerView;
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

-(void)doubleTapScroll{
//    NSLog(@"double tap scroll");
    
    BOOL modalPresent = (self.presentedViewController);
    
    if (self.products.count != 0 && self.tappedItem == NO && modalPresent != YES) {
        //prevents crash when header is not visible, thereofre has no layout attributes // if still seeing crash, layoutifneeded also meant to work
        [self.collectionView.collectionViewLayout prepareLayout];
        
        //scroll to top of header
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        
        CGFloat offsetY = [self.collectionView layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath].frame.origin.y;
        
        CGFloat contentInsetY = self.collectionView.contentInset.top;
        CGFloat sectionInsetY = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).sectionInset.top;
        
        [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, offsetY - contentInsetY - sectionInsetY) animated:YES];
    }
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

#pragma mark - search bar delegates

-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    NSLog(@"should begin ending!");
    [self searchPressed];
    return NO;
}

-(void)searchPressed{
    
    self.navigationController.hidesBarsOnSwipe = NO;
    
    TheMainSearchView *vc = [[TheMainSearchView alloc]init];
    vc.currency = self.currency;
    vc.delegate = self;
    vc.currencySymbol = self.currencySymbol;
    vc.geoPoint = self.currentLocation;
    vc.tabBarHeight = [NSNumber numberWithFloat:self.tabBarController.tabBar.frame.size.height];
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    self.definesPresentationContext = YES;
    nav.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)cancellingMainSearch{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
//    self.navigationController.hidesBarsOnSwipe = YES;
}

#pragma mark - load objects

-(void)getLatestForSale{
    if (self.pullFinished != YES) {
        return;
    }
    
    //make sure infin is cancelled before loading pull
    [self.collectionView.infiniteScrollingView stopAnimating];
    [self.infiniteQuery cancel];
    
    self.pullFinished = NO;
    [self showFilter];
    
    self.pullQuery = nil;
    self.pullQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    
    [self setupPullQuery];

    [self.pullQuery whereKey:@"status" equalTo:@"live"];
    
    self.pullQuery.limit = 20;
    
    //brand filter
    if (self.filterBrandsArray.count > 0) {
        [self.pullQuery whereKey:@"keywords" containedIn:self.filterBrandsArray];
    }
    
    [self.pullQuery cancel];
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error getting for sale items");
            
            if (error.code == 209) {
                //invalid token so log out
                [Answers logCustomEventWithName:@"invalid token on pullquery (error 209)"
                               customAttributes:@{}];
                
                [self bigLogOut];
            }
            else{
                [self showAlertWithTitle:@"Bad Connection" andMsg:@"Make sure you're connected to the internet"];
            }
            
            [self.collectionView.pullToRefreshView stopAnimating];
            self.pullFinished = YES;
            
        }
        else{
            if (objects.count == 0) {
                //show no results label
                [self.noResultsLabel setHidden:NO];
            }
            else{
                //hide no results label
                [self.noResultsLabel setHidden:YES];
            }
            
            self.skipped = (int)objects.count;

            [self.products removeAllObjects];
            [self.products addObjectsFromArray:objects];
            [self.collectionView reloadData];
            
            //track which objectIds have been added to avoid duplication in infin
            [self.productIds removeAllObjects];
            for (PFObject *listing in objects) {
                [self.productIds addObject:listing.objectId];
            }
            
            [self.collectionView.pullToRefreshView stopAnimating];
            self.pullFinished = YES;
        }
    }];
}

-(void)infinLatestForSale{
    if (self.infinFinished != YES || self.pullFinished != YES) {
        return;
    }
    
    if (self.products.count < 20) {
        //no point loading
        [self.collectionView.infiniteScrollingView stopAnimating];
        return;
    }
    
    [self hideFilter];

    self.infinFinished = NO;
    
    self.infiniteQuery = nil;
    self.infiniteQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    
    [self.infiniteQuery whereKey:@"status" equalTo:@"live"];
    [self.infiniteQuery whereKey:@"objectId" notContainedIn:self.productIds];

    [self.infiniteQuery orderByDescending:@"lastUpdated"];
    self.infiniteQuery.limit = 20;
    self.infiniteQuery.skip = self.skipped;
    
    [self setupInfinQuery];
    
    //brand filter
    if (self.filterBrandsArray.count > 0) {
        [self.infiniteQuery whereKey:@"keywords" containedIn:self.filterBrandsArray];
    }

    [self.infiniteQuery cancel];
    [self.infiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error getting for sale items infin %@", error);
            [self showFilter];
            
            [self.collectionView.infiniteScrollingView stopAnimating];
            self.infinFinished = YES;
        }
        else{
            [self showFilter];

            self.skipped = self.skipped + (int)objects.count;

            [self.products addObjectsFromArray:objects];
            [self.collectionView reloadData];
            
            [self.collectionView.infiniteScrollingView stopAnimating];
            self.infinFinished = YES;
            
            //update tracking of objectIds to avoid duplication
            for (PFObject *listing in objects) {
                [self.productIds addObject:listing.objectId];
            }
        }
    }];
}

-(void)setupPullQuery{
    if (self.filtersArray.count > 0) {
        
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
        
        //location
        if ([self.filtersArray containsObject:@"aroundMe"]) {
//            [self.pullQuery whereKeyExists:@"geopoint"];
            
            if (self.currentLocation) {
                [self.pullQuery whereKey:@"geopoint" nearGeoPoint:self.currentLocation withinKilometers:400];
            }
            else{
                //prompt to turn location on?
            }
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

-(void)setupInfinQuery{
    if (self.filtersArray.count > 0) {
        
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
//            [self.infiniteQuery whereKeyExists:@"geopoint"];
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
//            NSLog(@"filters colour array %@", self.filterBrandsArray);
            [self.infiniteQuery whereKey:@"coloursArray" containedIn:self.filterColoursArray]; //was mainColour
        }
        
    }
    else{
        [self.infiniteQuery orderByDescending:@"lastUpdated"];
    }
}

#pragma mark helper methods

-(void)bigLogOut{
    
    [Answers logCustomEventWithName:@"BIG LOG OUT"
                   customAttributes:@{}];
    
    [PFUser logOut];
    WelcomeViewController *vc = [[WelcomeViewController alloc]init];
    vc.delegate = self;
    NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navController animated:NO completion:nil];
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

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = 30;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)checkIfBanned{
    
    //check if user is banned
    PFQuery *bannedQuery = [PFQuery queryWithClassName:@"bannedUsers"];
    [bannedQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    
    //also check if device is banned to prevent creating new accounts
    PFInstallation *installation = [PFInstallation currentInstallation];
    PFQuery *bannedInstallsQuery = [PFQuery queryWithClassName:@"bannedUsers"];
    
    if (installation.deviceToken) {
        [bannedInstallsQuery whereKey:@"deviceToken" equalTo:installation.deviceToken];
    }
    else{
        //to prevent simulator returning loads of results and fucking up banning logic
        [bannedInstallsQuery whereKey:@"deviceToken" equalTo:@"thisISNothing"];
    }
    
    PFQuery *megaBanQuery = [PFQuery orQueryWithSubqueries:@[bannedQuery]];
    [megaBanQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //user is banned - log them out
            
            [Answers logCustomEventWithName:@"Logging Banned User Out"
                           customAttributes:@{
                                              @"from":@"Home"
                                              }];
            
            
            [PFUser logOut];
            WelcomeViewController *vc = [[WelcomeViewController alloc]init];
            vc.delegate = self;
            NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:navController animated:NO completion:nil];
            
            //to prevent user signing up again if they don't have a device token
            [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"banned"];
        }
        else if (error){
            NSLog(@"error checking if banned %@", error);
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


-(void)parseLocation{
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint * _Nullable geoPoint, NSError * _Nullable error) {
        if (geoPoint) {
            NSLog(@"got location: %@", self.currentLocation);
            
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
                        
                        //only save if user doesn't have a profile location set
                        if (![[PFUser currentUser]objectForKey:@"profileLocation"]) {
                            [[PFUser currentUser]setObject:titleString forKey:@"profileLocation"];
                            [[PFUser currentUser]saveInBackground];
                        }
                    }
                }
                else{
                    NSLog(@"placemark error %@", error);
                }
            }];
        }
        else{
            NSLog(@"no geopoint %@", error);
            
            [Answers logCustomEventWithName:@"Error getting geopoint"
                           customAttributes:@{}];
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

-(void)showPushReminder{
    if (self.alertShowing) {
        return;
    }
    
    self.alertShowing = YES;
    
    self.shownPushAlert = YES;
    self.searchBgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.searchBgView.alpha = 0.0;
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"customAlertView" owner:self options:nil];
    self.pushAlert = (customAlertViewClass *)[nib objectAtIndex:0];
    self.pushAlert.delegate = self;
    
    float delay = 0.2;
    
    if (self.filterIntro) {
        //draw focus to filter button
        
        UIImageView *imgView = [[UIImageView alloc]initWithFrame:self.searchBgView.frame];
        [self.searchBgView addSubview:imgView];
        
        if ([ [ UIScreen mainScreen ] bounds ].size.width == 375) {
            //iPhone 7
            [imgView setImage:[UIImage imageNamed:@"filterTut"]];
        }
        else if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
            //iPhone 7 plus
            [imgView setImage:[UIImage imageNamed:@"filterTutPlus"]];
        }
        else if([ [ UIScreen mainScreen ] bounds ].size.width == 320){
            //iPhone SE
            [imgView setImage:[UIImage imageNamed:@"filterTutSmall"]];
        }
        else{
            //fall back
        }
        
        //add button in case user taps filter button
        UIButton *filterProxy = [[UIButton alloc]initWithFrame:CGRectMake(self.filterButton.frame.origin.x, self.filterButton.frame.origin.y+65, self.filterButton.frame.size.width, self.filterButton.frame.size.height)];
        [filterProxy addTarget:self action:@selector(proxyFilterPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.searchBgView insertSubview:filterProxy aboveSubview:imgView];
        
        self.pushAlert.titleLabel.text = @"Filter";
        self.pushAlert.messageLabel.text = @"Tap to filter items by brand, colour, size and more! If you're looking for something in particular hit the search bar at the top of the screen 👟";
        self.pushAlert.numberOfButtons = 1;
        
        delay = 1.5;
        
        [Answers logCustomEventWithName:@"Saw filter intro"
                       customAttributes:@{}];
    }
    else{
        [self.searchBgView setBackgroundColor:[UIColor blackColor]];

        self.pushAlert.titleLabel.text = @"Enable Push";
        self.pushAlert.messageLabel.text = @"Tap to be notified when sellers & potential buyers send you a message on Bump";
        self.pushAlert.numberOfButtons = 2;
        [self.pushAlert.secondButton setTitle:@"E N A B L E" forState:UIControlStateNormal];
    }
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.searchBgView];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.searchBgView.alpha = 0.7f;
                     }
                     completion:nil];
    

    
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
                          delay:delay
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
                             self.alertShowing = NO;

                             [self.pushAlert setAlpha:0.0];
                             [self.pushAlert removeFromSuperview];
                             self.pushAlert = nil;
                             
                             if (self.filterIntro) {
                                 self.filterIntro = NO;
                                 [[PFUser currentUser]setObject:@"YES" forKey:@"filterIntro"];
                                 [[PFUser currentUser]saveInBackground];
                             }
                         }];
    }
    else{
        if (self.lowRating == YES) {
            self.lowRating = NO;
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

-(void)proxyFilterPressed{
    [self donePressed];
    [self filterPressed:self];
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
                             [self setupRateMessagePrompt];
                         }
                     }];
    
}

-(void)setupRateMessagePrompt{
    
    if (self.lowRating == YES) {
        self.searchBgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
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
            
            NSURL *picUrl3 = [NSURL URLWithString:@"https://graph.facebook.com/781237282045226/picture?type=large"]; //use viv's image to fill gap
            [self.inviteView.friendImageThree sd_setImageWithURL:picUrl3];
        }
        else if (friendsArray.count == 1){
            NSURL *picUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", friendsArray[0]]];
            [self.inviteView.friendImageOne sd_setImageWithURL:picUrl];
            
            NSURL *picUrl2 = [NSURL URLWithString:@"https://graph.facebook.com/781237282045226/picture?type=large"]; //use viv's image
            [self.inviteView.friendImageTwo sd_setImageWithURL:picUrl2];
            
            NSURL *picUrl3 = [NSURL URLWithString:@"https://graph.facebook.com/10154993039808844/picture?type=large"]; //use tayler's image to fill gap
            [self.inviteView.friendImageThree sd_setImageWithURL:picUrl3];
        }
    }
    else{
        NSURL *picUrl = [NSURL URLWithString:@"https://graph.facebook.com/10207070036095375/picture?type=large"]; //use matsisland's image
        [self.inviteView.friendImageOne sd_setImageWithURL:picUrl];
        
        NSURL *picUrl2 = [NSURL URLWithString:@"https://graph.facebook.com/781237282045226/picture?type=large"]; //use viv's image
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

#pragma mark - observer callbacks

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
        
        PFObject *listingObj = [PFObject objectWithoutDataWithClassName:@"forSaleItems" objectId:listing];
        
        ForSaleListing *vc = [[ForSaleListing alloc]init];
        vc.listingObject = listingObj;
        vc.source = @"bump";
        vc.fromBuyNow = YES;
        vc.pureWTS = YES;
        vc.fromPush = YES;
        NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
        //            [nav pushViewController:vc animated:YES];
        
        if (nav.visibleViewController.presentedViewController) {
            
            //nav bar is showing something
            if ([nav.visibleViewController.presentedViewController isKindOfClass:[NavigationController class]]) {
                
                //2nd nav is showing so push from there instead of tab bar nav
                NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                [presenter pushViewController:vc animated:YES];
            }
        }
        else{
            //no other VC showing so push!
            [nav pushViewController:vc animated:YES];
        }
        
//        BumpVC *vc = [[BumpVC alloc]init];
//        vc.listingID = listing;
//        [self presentViewController:vc animated:YES completion:nil];
        
    }
    //my listing got bumped
    else{
        //goto that listing
        [Answers logCustomEventWithName:@"Tapped in app Push"
                       customAttributes:@{
                                          @"type":@"Bump"
                                          }];
        if (self.wantedListing) {
            PFObject *listingObj = [PFObject objectWithoutDataWithClassName:@"wantobuys" objectId:listing];
            ListingController *vc = [[ListingController alloc]init];
            vc.listingObject = listingObj;
            //make sure drop down is gone
            self.dropDown = nil;
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
//            [nav pushViewController:vc animated:YES];
            
            if (nav.visibleViewController.presentedViewController) {
                
                //nav bar is showing something
                if ([nav.visibleViewController.presentedViewController isKindOfClass:[NavigationController class]]) {
                    
                    //2nd nav is showing so push from there instead of tab bar nav
                    NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                    [presenter pushViewController:vc animated:YES];
                }
            }
            else{
                //no other VC showing so push!
                [nav pushViewController:vc animated:YES];
            }
        }
        else{
            PFObject *listingObj = [PFObject objectWithoutDataWithClassName:@"forSaleItems" objectId:listing];
            
            ForSaleListing *vc = [[ForSaleListing alloc]init];
            vc.listingObject = listingObj;
            vc.source = @"bump";
            vc.fromBuyNow = YES;
            vc.pureWTS = YES;
            vc.fromPush = YES;
            NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
//            [nav pushViewController:vc animated:YES];
            
            if (nav.visibleViewController.presentedViewController) {
                
                //nav bar is showing something
                if ([nav.visibleViewController.presentedViewController isKindOfClass:[NavigationController class]]) {
                    
                    //2nd nav is showing so push from there instead of tab bar nav
                    NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
                    [presenter pushViewController:vc animated:YES];
                }
            }
            else{
                //no other VC showing so push!
                [nav pushViewController:vc animated:YES];
            }
        }

    }
}

- (void)handleBump:(NSNotification*)note {
    NSString *listingID = [note object];
    
    [Answers logCustomEventWithName:@"Opened Listing after receiving FB Friend Push"
                   customAttributes:@{}];
    
//    BumpVC *vc = [[BumpVC alloc]init];
//    vc.listingID = listingID;
//    [self presentViewController:vc animated:YES completion:nil];
    
    PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"forSaleItems" objectId:listingID];
    
    ForSaleListing *vc = [[ForSaleListing alloc]init];
    vc.listingObject = listingObject;
    vc.source = @"push";
    vc.fromBuyNow = YES;
    vc.pureWTS = YES;
    vc.fromPush = YES;

    NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
//    [nav pushViewController:vc animated:YES];
    if (nav.visibleViewController.presentedViewController) {
        
        //nav bar is showing something
        if ([nav.visibleViewController.presentedViewController isKindOfClass:[NavigationController class]]) {
            
            //2nd nav is showing so push from there instead of tab bar nav
            NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
            [presenter pushViewController:vc animated:YES];
        }
    }
    else{
        //no other VC showing so push!
        [nav pushViewController:vc animated:YES];
    }
}

- (void)showListing:(NSNotification*)note {
    NSString *listingID = [note object];
    
    [Answers logCustomEventWithName:@"Opened wanted listing after receiving Bump Push"
                   customAttributes:@{}];
    
    PFObject *listing = [PFObject objectWithoutDataWithClassName:@"wantobuys" objectId:listingID];
    ListingController *vc = [[ListingController alloc]init];
    vc.listingObject = listing;
    NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
    
    //unhide nav bar
    //    self.navigationController.navigationBarHidden = NO;
//    [nav pushViewController:vc animated:YES];
    if (nav.visibleViewController.presentedViewController) {
        
        //nav bar is showing something
        if ([nav.visibleViewController.presentedViewController isKindOfClass:[NavigationController class]]) {
            
            //2nd nav is showing so push from there instead of tab bar nav
            NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
            [presenter pushViewController:vc animated:YES];
        }
    }
    else{
        //no other VC showing so push!
        [nav pushViewController:vc animated:YES];
    }
}

- (void)showSaleListing:(NSNotification*)note {
    NSString *listingID = [note object];
    
    PFObject *listingObject = [PFObject objectWithoutDataWithClassName:@"forSaleItems" objectId:listingID];
    
    ForSaleListing *vc = [[ForSaleListing alloc]init];
    vc.listingObject = listingObject;
    vc.source = @"bump";
    vc.fromBuyNow = YES;
    vc.pureWTS = YES;
    vc.fromPush = YES;

    NavigationController *nav = (NavigationController*)self.tabBarController.selectedViewController;
//    [nav pushViewController:vc animated:YES];
    if (nav.visibleViewController.presentedViewController) {
        
        //nav bar is showing something
        if ([nav.visibleViewController.presentedViewController isKindOfClass:[NavigationController class]]) {
            
            //2nd nav is showing so push from there instead of tab bar nav
            NavigationController *presenter = (NavigationController*)nav.visibleViewController.presentedViewController;
            [presenter pushViewController:vc animated:YES];
        }
    }
    else{
        //no other VC showing so push!
        [nav pushViewController:vc animated:YES];
    }
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
    
    PFQuery *listingQ = [PFQuery queryWithClassName:@"forSaleItems"];
    [listingQ whereKey:@"objectId" equalTo:listingID];
    [listingQ includeKey:@"sellerUser"];
    [listingQ getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            PFObject *listing = object;
            self.dropDown.listing = listing;
            [self.dropDown.imageView setFile:[object objectForKey:@"thumbnail"]];
            [self.dropDown.imageView loadInBackground:^(UIImage * _Nullable image, NSError * _Nullable error) {
                if (image) {
                    PFUser *postUser = [listing objectForKey:@"sellerUser"];
                    self.dropDown.mainLabel.text = [NSString stringWithFormat:@"Your Facebook friend %@ just listed an item for sale - Tap to like it", [postUser objectForKey:@"fullname"]];
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

-(void)resetHome{
    //only reset if they're looking at home tab
    if (self.tabBarController.selectedIndex == 0) {
        if (self.products.count != 0) {
            //prevents crash when header is not visible, thereofre has no layout attributes // if still seeing crash, layoutifneeded also meant to work
            [self.collectionView.collectionViewLayout prepareLayout];

            //scroll to top of header
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];

            CGFloat offsetY = [self.collectionView layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath].frame.origin.y;

            CGFloat contentInsetY = self.collectionView.contentInset.top;
            CGFloat sectionInsetY = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).sectionInset.top;

            [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, offsetY - contentInsetY - sectionInsetY) animated:YES];
        }

        self.pullFinished = YES;
        [self getLatestForSale];
    }
}

-(void)insertLatestListing:(NSNotification*)note {
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        NSLog(@"posted!");
//        
//        //reset collection view header
//        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
//        
//        if ([ [ UIScreen mainScreen ] bounds ].size.width == 375) {
//            //iPhone6/7
//            [flowLayout setItemSize:CGSizeMake(175,222)];
//        }
//        else if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
//            //iPhone 6 plus
//            [flowLayout setItemSize:CGSizeMake(195, 247)];
//        }
//        else if([ [ UIScreen mainScreen ] bounds ].size.width == 320){
//            //iPhone 4/5
//            [flowLayout setItemSize:CGSizeMake(148, 188)];
//        }
//        else{
//            //fall back
//            [flowLayout setItemSize:CGSizeMake(175,222)];
//        }
//        
//        [flowLayout setMinimumInteritemSpacing:8.0];
//        [flowLayout setMinimumLineSpacing:8.0];
//        [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
//        
//        flowLayout.headerReferenceSize = CGSizeMake([UIApplication sharedApplication].keyWindow.frame.size.width,40);
//        flowLayout.sectionHeadersPinToVisibleBounds = NO;
//        
//        [self.collectionView setCollectionViewLayout:flowLayout];
//        
//        self.postingMode = NO;
//        [self.collectionView.collectionViewLayout invalidateLayout];
//        [self.headerView setNeedsDisplay];
//        
//        PFObject *listing = [note object];
//        //    NSLog(@"insert %@", listing);
//        if (self.products.count > 0) {
//            [self.products insertObject:listing atIndex:0];
//            [self.collectionView reloadData];
//        }
//    });
    
    PFObject *listing = [note object];
    if (self.products.count > 0) {
        [self.products insertObject:listing atIndex:0];
        [self.collectionView reloadData];
    }
}

-(void)handleBumpDrop:(NSNotification*)note {
    NSArray *info = [note object];
    
    NSLog(@"info %@", info);
    
    //prevent crashes with wrongly formatted pushes
    if (info.count <2) {
        return;
    }
    
    NSLog(@"lez go");
    
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
    
    if ([message containsString:@"wanted listing"]) {
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
                        self.wantedListing = YES;

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
    else{
        //sale listing bumped
        NSLog(@"sale listing bumped");
        
        PFQuery *listingQ = [PFQuery queryWithClassName:@"forSaleItems"];
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
                        self.wantedListing = NO;
                        
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
}

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

-(void)showScreenShot:(NSNotification*)note {
    
    if (self.screenshotShowing) {
        return;
    }
    
    self.screenshotShowing = YES;
    
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
                             self.screenshotShowing = NO;
                             [self dismissDrop];
                         });
                     }];
    
    UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDrop)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [self.dropDown addGestureRecognizer:swipeGesture];
}

-(void)welcomeDismissed{
    self.pullFinished = YES;
    [self resetHome];
}

-(void)ensureNavShowing{
    
    BOOL modalPresent = (self.presentedViewController);
        
    if (modalPresent != YES && self.tabBarController.selectedIndex == 0) {
        [self.navigationController.navigationBar setHidden:NO];
    }
}

-(void)verifyEmailInHome{
    
    if ([PFUser currentUser]) {
        
        NSArray *notificationArray = [[UIApplication sharedApplication] scheduledLocalNotifications];
        
        for(UILocalNotification *notification in notificationArray){
            
            if ([notification.alertBody containsString:@"Verify your Bump email address now!"]) {
                // delete this notification
                [[UIApplication sharedApplication] cancelLocalNotification:notification];
            }
        }
        
        //check if already verified
        if ([[[PFUser currentUser] objectForKey:@"emailIsVerified"]boolValue] != YES) {
            
            [[PFUser currentUser]setObject:[NSNumber numberWithBool:YES] forKey:@"emailIsVerified"];
            [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    
                    //refresh header in home
                    self.pullFinished = YES;
                    [self getLatestForSale];
                    
                    //refresh verified with image in profile if selected tab is 4
                    if (self.tabBarController.selectedIndex == 3) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshVeri" object:nil];
                    }
                    
                    [Answers logCustomEventWithName:@"Email Verified"
                                   customAttributes:@{
                                                      @"status":@"Success"
                                                      }];
                    
                    [self showAlertWithTitle:@"Email Verified ✅" andMsg:@"Congrats, you just verified your email! If you haven't already, connect your Facebook to share listings with friends on Bump"];
                    
                    //send welcome email if haven't already signed up with fb & received it that way
                    if (![[PFUser currentUser]objectForKey:@"facebookId"]) {
                        
                        NSDictionary *params = @{@"toEmail": [[PFUser currentUser] objectForKey:@"email"]};
                        [PFCloud callFunctionInBackground:@"sendWelcomeEmail" withParameters:params block:^(NSDictionary *response, NSError *error) {
                            if (!error) {
                                
                                [Answers logCustomEventWithName:@"Sent Welcome Email"
                                               customAttributes:@{
                                                                  @"where":@"after email verified"
                                                                  }];
                                
                            }
                            else{
                                NSLog(@"email error %@", error);
                                
                                [Answers logCustomEventWithName:@"Error sending Welcome Email"
                                               customAttributes:@{
                                                                  @"where":@"after email verified"
                                                                  }];
                            }
                        }];
                    }
                }
                else{
                    NSLog(@"error saving user %@", error);
                    [Answers logCustomEventWithName:@"Email Verified"
                                   customAttributes:@{
                                                      @"status":@"error"
                                                      }];
                    [self showAlertWithTitle:@"Email Error" andMsg:@"Make sure you're connected to the internet then try tapping the verification in the email we sent again!"];
                }
            }];
        }
    }
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

#pragma mark - filters delegates

- (IBAction)filterPressed:(id)sender {
    [Answers logCustomEventWithName:@"Filters pressed"
                   customAttributes:@{
                                      @"page":@"Home"
                                      }];
    FilterVC *vc = [[FilterVC alloc]init];
    vc.delegate = self;
    vc.sellingSearch = YES;
    vc.currencySymbol = self.currencySymbol;
    if (self.filtersArray.count > 0) {

        NSLog(@"self.filtersarray: %@", self.filtersArray);
        
        vc.filterLower = self.filterLower;
        vc.filterUpper = self.filterUpper;
        
        vc.sendArray = [NSMutableArray arrayWithArray:self.filtersArray];
    }
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)filtersReturned:(NSMutableArray *)filters withSizesArray:(NSMutableArray *)sizes andBrandsArray:(NSMutableArray *)brands andColours:(NSMutableArray *)colours andCategories:(NSString *)category andPricLower:(float)lower andPriceUpper:(float)upper{
    //reset collection view
    [self.products removeAllObjects];
    [self.productIds removeAllObjects];
    [self.collectionView reloadData];
    
    self.filtersArray = filters;
    if (self.filtersArray.count > 0) {
        self.filterSizesArray = sizes;
        self.filterBrandsArray = brands;
        self.filterColoursArray = colours;
        self.filterCategory = category;
        self.filterUpper = upper;
        self.filterLower = lower;
        
        //change colour of filter number
        NSMutableAttributedString *filterString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"F I L T E R  %lu",self.filtersArray.count]];
        [self modifyString:filterString setColorForText:[NSString stringWithFormat:@"%lu",self.filtersArray.count] withColor:[UIColor colorWithRed:0.31 green:0.89 blue:0.76 alpha:1.0]];
        [self.filterButton setAttributedTitle:filterString forState:UIControlStateNormal];
        
    }
    else{
        //no filters so reset everything
        NSMutableAttributedString *filterString = [[NSMutableAttributedString alloc] initWithString:@"F I L T E R"];
        [self.filterButton setAttributedTitle:filterString forState:UIControlStateNormal];
        
        [self.filterSizesArray removeAllObjects];
        [self.filterBrandsArray removeAllObjects];
        [self.filterColoursArray removeAllObjects];
        self.filterCategory = @"";
    }
    
    //reset skip
    self.skipped = 0;
    
    NSLog(@"filters array in home tab %@   brands: %@", self.filtersArray, self.filterBrandsArray);
    
    if (self.products.count != 0) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:NO];
    }
    [self getLatestForSale];
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
        self.filterCategory = @"";
    }
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

-(void)hideFilter{
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.filterButton.alpha = 0.0;
                     }
                     completion:nil];
}

-(void)showFilter{
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.filterButton.alpha = 1.0;
                     }
                     completion:nil];
}

//for a floating button sitting below the CV header
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    
//    float scrollOffset = scrollView.contentOffset.y;
//    NSLog(@"offset: %f", scrollOffset);
//    
//    //scroll button up as user scrolls down
//    if(scrollView.contentOffset.y >= 0 && scrollView.contentOffset.y <= 40.0) {
//        self.floatingLocationButton.transform = CGAffineTransformMakeTranslation(0, -scrollOffset);
//    }
////    //scroll button down as user scrolls up
////    else if(scrollView.contentOffset.y == 40.0) {
////        self.floatingLocationButton.transform = CGAffineTransformMakeTranslation(0, +scrollOffset);
////    }
//    else if (scrollView.contentOffset.y == 0.0){
//        //reset to zero as user passes zero to keep gaps consistent
//        self.floatingLocationButton.transform = CGAffineTransformMakeTranslation(0,0);
//    }
//    else if (scrollView.contentOffset.y < 0) {
//        //scroll the button down as user goes beyong offset 0 to make it look like its in the same place
//        self.floatingLocationButton.transform = CGAffineTransformMakeTranslation(0, -scrollOffset);
//    }
//}

-(void)sendFeedbackMessage{
    //check how long user has had Bump
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                         fromDate:[PFUser currentUser].createdAt
                                                           toDate:[NSDate date]
                                                          options:0];
    NSString *sentSevenDayFeedback = [PFUser currentUser][@"sevenDayFBSent"];
    
    //now check if current user is highly active enough
    
    //number of sessions
    NSArray *sessionArray = [[PFUser currentUser]objectForKey:@"activeSessions"];
    
    //listings for sale
    int postNumber = [[[PFUser currentUser]objectForKey:@"forSalePostNumber"]intValue];
    
    if ([components day] >= 7 && ![sentSevenDayFeedback isEqualToString:@"YES"] && postNumber > 2 && sessionArray.count > 4) {
        //user had the app for over 7 days and now they're on it!
        //send them a feedback message from Team Bump
        [self sendTeamBumpFeedbackMessage];
    }
}

-(void)sendTeamBumpFeedbackMessage{
    
    //get latest message text from DB - updated remotely
    PFQuery *messageStringQuery = [PFQuery queryWithClassName:@"feedbackMessageString"];
    [messageStringQuery orderByDescending:@"createdAt"];
    [messageStringQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
       
        if (object) {
            NSString *messageString = [object objectForKey:@"messageText"];
            
            //customize with current user's name
            messageString = [messageString stringByReplacingOccurrencesOfString:@"USER" withString:[PFUser currentUser][@"firstName"]];
            
            //now save report message
            PFObject *messageObject1 = [PFObject objectWithClassName:@"teamBumpMsgs"];
            messageObject1[@"message"] = messageString;
            messageObject1[@"sender"] = [PFUser currentUser];
            messageObject1[@"senderId"] = @"BUMP";
            messageObject1[@"senderName"] = @"Team Bump";
            messageObject1[@"convoId"] = [NSString stringWithFormat:@"BUMP%@", [PFUser currentUser].objectId];
            messageObject1[@"status"] = @"sent";
            messageObject1[@"mediaMessage"] = @"NO";
            [messageObject1 saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    
                    //update profile tab bar badge
                    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    [[appDelegate.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:@"1"];
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NewTBMessageReg"];
                    
                    //update user to avoid duplicate sends
                    [[PFUser currentUser]setObject:@"YES" forKey:@"sevenDayFBSent"];
                    [[PFUser currentUser]saveInBackground];
                    
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
                            
                            [Answers logCustomEventWithName:@"Sent 7 day Feedback Message"
                                           customAttributes:@{
                                                              @"status":@"SENT"
                                                              }];
                        }
                        else{
                            [Answers logCustomEventWithName:@"Sent 7 day Feedback Message"
                                           customAttributes:@{
                                                              @"status":@"Failed getting convo"
                                                              }];
                        }
                    }];
                }
                else{
                    NSLog(@"error saving report message %@", error);
                    [Answers logCustomEventWithName:@"Sent 7 day Feedback Message"
                                   customAttributes:@{
                                                      @"status":@"Failed saving message"
                                                      }];
                }
            }];
            
        }
        
    }];
}

-(void)showPostingHeader:(NSNotification*)note{
    
    UIImage *image = [note object];
    self.bannerImage = image;
    
    NSLog(@"posting header");
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    //calc screen width to avoid hard coding but bug with collection view so width always = 1000
    
    if ([ [ UIScreen mainScreen ] bounds ].size.width == 375) {
        //iPhone6/7
        [flowLayout setItemSize:CGSizeMake(175,222)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
        //iPhone 6 plus
        [flowLayout setItemSize:CGSizeMake(195, 247)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.width == 320){
        //iPhone 4/5
        [flowLayout setItemSize:CGSizeMake(148, 188)];
    }
    else{
        //fall back
        [flowLayout setItemSize:CGSizeMake(175,222)];
    }
    
    [flowLayout setMinimumInteritemSpacing:8.0];
    [flowLayout setMinimumLineSpacing:8.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    flowLayout.headerReferenceSize = CGSizeMake([UIApplication sharedApplication].keyWindow.frame.size.width, 60);
    flowLayout.sectionHeadersPinToVisibleBounds = NO;
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    
    self.postingMode = YES;
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.headerView setNeedsDisplay];
    
    if (self.products.count != 0) {
        //prevents crash when header is not visible, thereofre has no layout attributes // if still seeing crash, layoutifneeded also meant to work
        [self.collectionView.collectionViewLayout prepareLayout];
        NSLog(@"scroll!");
        
        //scroll to top of header
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        
        CGFloat offsetY = [self.collectionView layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath].frame.origin.y;
        
        CGFloat contentInsetY = self.collectionView.contentInset.top;
        CGFloat sectionInsetY = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).sectionInset.top;
        
        [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, offsetY - contentInsetY - sectionInsetY) animated:YES];
    }
}
@end
