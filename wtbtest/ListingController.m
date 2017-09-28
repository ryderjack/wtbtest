//
//  ListingController.m
//  
//
//  Created by Jack Ryder on 03/03/2016.
//
//

#import "ListingController.h"
#import "FeedbackController.h"
#import "MessageViewController.h"
#import "FBGroupShareViewController.h"
#import "UserProfileController.h"
#import <Crashlytics/Crashlytics.h>
#import "NavigationController.h"
#import "whoBumpedTableView.h"
#import "SendToUserCell.h"
#import "ExploreVC.h"
#import "ForSaleCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "PresentDetailTransition.h"
#import "DismissDetailTransition.h"
#import "AppDelegate.h"
#import "PurchaseTab.h"
#import "AppDelegate.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import "UIImageView+Letters.h"

@interface ListingController ()

@end

@implementation ListingController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"W A N T";
    
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dotsIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(showAlertView)];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    if (self.showCancelButton) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cancelCross"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
        self.navigationItem.leftBarButtonItem = cancelButton;

    }
    
    self.viewBumpsButton.titleLabel.numberOfLines = 0;
    self.viewBumpsButton.titleLabel.textAlignment = NSTextAlignmentCenter;

    self.sendButtonLabel.titleLabel.numberOfLines = 0;
    self.sendButtonLabel.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.checkImageView setHidden:YES];
    [self.purchasedLabel setHidden:YES];
    [self.purchasedCheckView setHidden:YES];
    
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
    
    self.buyernameLabel.text = @"";
    self.pastDealsLabel.text = @"Loading";
    
    self.facebookUsers = [NSMutableArray array];
    self.friendIndexSelected = 0;
    
    //how to work out cells to display
    //create array of cells and add to it when want to display
    
    self.cellArray = [NSMutableArray array];
    
    //when presented from search the tab bar does not belong to parent so access presenting VC tabbar
    if (self.tabBarController.tabBar.frame.size.height == 0) {
        
        self.tabBarHeightInt = self.presentingViewController.tabBarController.tabBar.frame.size.height;
                
        //register for notification so we know when to dismiss long button after switching tabs
        //because its a modalVC 'willdisappear' never called
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHideLongButton:) name:@"switchedTabs" object:nil];
        self.searchTabsObserverOn = YES;
        self.modalMode = YES;
    }
    else{
        self.tabBarHeightInt = self.tabBarController.tabBar.frame.size.height;
    }
    
    self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(60 + self.tabBarHeightInt), [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
    [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
    [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
    [self.longButton addTarget:self action:@selector(BarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.longButton.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
        
    [self showBarButton];
    self.changeKeyboard = YES;
    
    //carousel setup
    self.carouselView.type = iCarouselTypeLinear;
    self.carouselView.delegate = self;
    self.carouselView.dataSource = self;
    self.carouselView.pagingEnabled = YES;
    self.carouselView.bounceDistance = 0.3;
    
    //self.carouselView.layer.cornerRadius = 4;
    //self.carouselView.layer.masksToBounds = YES; //enable this to restrict the entire carousel to the view specified in the nib
    
    [self.listingObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (!error) {
            NSLog(@"LISTING: %@", self.listingObject);
            
            //check if purchased or not
            [self checkStatus];
            
            if ([self.listingObject objectForKey:@"image4"]){
                [self.picIndicator setNumberOfPages:4];
                self.numberOfPics = 4;
                self.firstImage = [self.listingObject objectForKey:@"image1"];
                self.secondImage = [self.listingObject objectForKey:@"image2"];
                self.thirdImage = [self.listingObject objectForKey:@"image3"];
                self.fourthImage = [self.listingObject objectForKey:@"image4"];
            }
            else if ([self.listingObject objectForKey:@"image3"]){
                [self.picIndicator setNumberOfPages:3];
                self.numberOfPics = 3;
                self.firstImage = [self.listingObject objectForKey:@"image1"];
                self.secondImage = [self.listingObject objectForKey:@"image2"];
                self.thirdImage = [self.listingObject objectForKey:@"image3"];
            }
            else if ([self.listingObject objectForKey:@"image2"]) {
                [self.picIndicator setNumberOfPages:2];
                self.numberOfPics = 2;
                self.firstImage = [self.listingObject objectForKey:@"image1"];
                self.secondImage = [self.listingObject objectForKey:@"image2"];
            }
            else{
                [self.picIndicator setHidden:YES];
                self.numberOfPics = 1;
            }
            
            [self.carouselView reloadData];
            
            self.titleLabel.text = [self.listingObject objectForKey:@"title"];
            self.priceLabel.text = @"Negotiable";
            
            [self.cellArray addObject:self.payCell];
            
            if ([self.listingObject objectForKey:@"condition"]) {
                self.conditionLabel.text = [self.listingObject objectForKey:@"condition"];
                [self.cellArray addObject:self.conditionCell];
            }
            
            if ([self.listingObject objectForKey:@"location"]) {
                NSString *loc = [self.listingObject objectForKey:@"location"];
                self.locationLabel.text = [loc stringByReplacingOccurrencesOfString:@"(null)," withString:@""];
                [self.cellArray addObject:self.locationCell];
            }
            
            if ([self.listingObject objectForKey:@"category"]) {
                if ([[self.listingObject objectForKey:@"category"]isEqualToString:@"Accessories"]) {
                    //do nothing
                }
                else{
                    if ([self.listingObject objectForKey:@"sizeLabel"]) {
                        NSString *sizeNoUK = [[self.listingObject objectForKey:@"sizeLabel"] stringByReplacingOccurrencesOfString:@"UK" withString:@""];
                        
                        if (![self.listingObject objectForKey:@"sizeGender"]) {
                            self.sizeLabel.text = [NSString stringWithFormat:@"%@",sizeNoUK];
                        }
                        else{
                            self.sizeLabel.text = [NSString stringWithFormat:@"%@ %@",[self.listingObject objectForKey:@"sizeGender"], [self.listingObject objectForKey:@"sizeLabel"]];
                        }
                        [self.cellArray addObject:self.sizeCell];
                    }
                }
            }
            
            [self calcPostedDate];
            
            self.idLabel.text = [NSString stringWithFormat:@"ID %@",self.listingObject.objectId];
            [self.cellArray addObject:self.adminCell];
            [self.tableView reloadData];
            
            //buyer info
            self.buyer = [self.listingObject objectForKey:@"postUser"];
            
            if ([self.buyer.objectId isEqualToString:[PFUser currentUser].objectId]) {
                
                [self.longButton setTitle:@"E D I T" forState:UIControlStateNormal];
                [self.longButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
                [self.longButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];
                
                //disable report button
                [self.reportButton setEnabled:NO];
                [self.reportLabel setAlpha:0.5];
            }
            else{
                [self.longButton setTitle:@"M E S S A G E  B U Y E R" forState:UIControlStateNormal];
                self.wantMode = YES;
                
                //not the same buyer
                [self.listingObject incrementKey:@"views"];
                [self.listingObject saveInBackground];
            }
            
            NSMutableArray *bumpArray = [NSMutableArray arrayWithArray:[self.listingObject objectForKey:@"bumpArray"]];

            if ([bumpArray containsObject:[PFUser currentUser].objectId]) {
                //update upvote lower label, allow user to see who else has bumped the listing
                [self.viewBumpsButton setTitle:@"L I K E S" forState:UIControlStateNormal];
                [self.viewBumpsButton setEnabled:YES];
                [self.upVoteButton setSelected:YES];
            }
            else{
                [self.upVoteButton setSelected:NO];
                
                if (bumpArray.count > 0) {
                    [self.viewBumpsButton setTitle:@"L I K E S" forState:UIControlStateNormal];
                    [self.viewBumpsButton setEnabled:YES];
                }
                else{
                    [self.viewBumpsButton setTitle:@"L I K E" forState:UIControlStateNormal];
                    [self.viewBumpsButton setEnabled:NO];
                }
            }
            
            int count = (int)[bumpArray count];
            if (bumpArray.count > 0) {
                [self.upVoteButton setTitle:[NSString stringWithFormat:@"%@",[self abbreviateNumber:count]] forState:UIControlStateNormal];
            }
            else{
                [self.upVoteButton setTitle:@"" forState:UIControlStateNormal];
            }
            
            [self setImageBorder];
            [self.buyer fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    self.buyernameLabel.text = self.buyer.username;
                    PFFile *pic = [self.buyer objectForKey:@"picture"];
                    
                    UIButton *btn =  [UIButton buttonWithType:UIButtonTypeCustom];
                    btn.frame = CGRectMake(0,0,36,36);
                    [btn addTarget:self action:@selector(buyerPressed) forControlEvents:UIControlEventTouchUpInside];
                    PFImageView *buttonView = [[PFImageView alloc]initWithFrame:btn.frame];
                    [buttonView setBackgroundColor:[UIColor lightGrayColor]];
//                    [buttonView.layer setBorderColor: [[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0] CGColor]];
//                    [buttonView.layer setBorderWidth: 1.0];
                    
                    if (pic != nil) {
                        [buttonView setFile:pic];
                        [buttonView loadInBackground];
                    }
                    else{
                        [buttonView setImage:[UIImage imageNamed:@"empty"]];
                    }
                    
                    if ([[self.buyer objectForKey:@"ignoreLikePushes"]isEqualToString:@"YES"]) {
                        self.dontLikePush = YES;
                    }
                    else{
                        self.dontLikePush = NO;
                    }

                    [self setImageBorder:buttonView];
                    [btn addSubview:buttonView];
                    self.profileButton = [[UIBarButtonItem alloc] initWithCustomView:btn];
                    
                    
                    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.profileButton,infoButton, nil]];
                    
//                    if ([[self.listingObject objectForKey:@"status"]isEqualToString:@"purchased"]) {
//                        self.navigationItem.rightBarButtonItem = self.profileButton;
//                    }
//                    else{
//                        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.profileButton,infoButton, nil]];
//                    }
                }
                else{
                    NSLog(@"buyer error %@", error);
                    [self showAlertWithTitle:@"Buyer not found!" andMsg:nil];
                }
            }];
        }
        else{
            NSLog(@"error fetching listing %@", error);
        }
    }];
    
    //dismiss Invite gesture
    self.inviteTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideInviteView)];
    self.inviteTap.numberOfTapsRequired = 1;
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    //hide first table view header
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
    
    self.buyernameLabel.adjustsFontSizeToFitWidth = YES;
    self.buyernameLabel.minimumScaleFactor=0.5;
    
    self.locationLabel.adjustsFontSizeToFitWidth = YES;
    self.locationLabel.minimumScaleFactor=0.5;
    
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor=0.5;
    
    self.extraLabel.adjustsFontSizeToFitWidth = YES;
    self.extraLabel.minimumScaleFactor=0.5;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(comeBackToForeground)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:[UIApplication sharedApplication]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goneToBackground)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:[UIApplication sharedApplication]];
    
    self.carouselMainCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.payCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.sizeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.deliveryCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.locationCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.extraCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.adminCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buyerinfoCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.conditionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.spaceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    [self SetupSendBox];
    
    if ([[PFUser currentUser]objectForKey:@"facebookId"]) {
        [self loadFacebookFriends];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    
    [self.navigationController.navigationBar setHidden:NO];
    [self.navigationController.navigationBar setBarTintColor: nil];

    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [self willAppearSetup];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear: animated];
    
    //reset bar pressed mode only when this view has properly appeared
    if (self.barButtonPressed == YES) {
        self.barButtonPressed = NO;
    }
    
    //make sure not adding duplicate observers
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [center removeObserver:self name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [center removeObserver:self name:@"showSendBox" object:nil];
    [center removeObserver:self name:@"switchingTabs" object:nil];
    
    [center addObserver:self selector:@selector(listingKeyboardOnScreen:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(listingKeyboardOFFScreen:) name:UIKeyboardWillHideNotification object:nil];
    [center addObserver:self selector:@selector(userDidTakeScreenshot) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [center addObserver:self selector:@selector(sendPressed:) name:@"showSendBox" object:nil];
    [center addObserver:self selector:@selector(switchingTabs) name:@"switchingTabs" object:nil];
    
    if (self.searchTabsObserverOn) {
        //these observers are for when user is viewing listing from search, where disappear VC methods aren't called!
        [center removeObserver:self name:@"switchedTabs" object:nil];
        [center addObserver:self selector:@selector(showHideLongButton:) name:@"switchedTabs" object:nil];
    }
    
    if (![[PFUser currentUser]objectForKey:@"seenBumpingIntro"]) {
        //show bumping tutorial
        [self hideBarButton];
        
        BumpingIntroVC *vc = [[BumpingIntroVC alloc]init];
        vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
        vc.delegate = self;
        [self presentViewController:vc animated:YES completion:nil];
    }

}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    NSLog(@"WILL disappearing!");

    
    [self willDisappearSetup];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [center removeObserver:self name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [center removeObserver:self name:@"showSendBox" object:nil];
    [center removeObserver:self name:@"switchingTabs" object:nil];
    
    if (self.searchTabsObserverOn) {
        [center removeObserver:self name:@"switchedTabs" object:nil];
    }
    
    if (self.dropShowing == YES) {
        //make sure its dismissed
        [[NSNotificationCenter defaultCenter] postNotificationName:@"removeDrop" object:nil];
    }
    
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    if (self.barButtonPressed != YES && self.justSwitchedTabs != YES) {
        //fail safe to avoid bar button wrongly showing
        NSLog(@"set to nil in dis");
        self.longButton = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//hide the first header in table view
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 1.0f;
    else if(section == 2 || section == 3){
        return 32.0f;
    }
    return 0.0f;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return @"";
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
   
    if (section == 1 || section == 3 || section == 2)
        return 0.0f;
    return 32.0f;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];

    [headerView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    return headerView;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    [footerView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    return footerView;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return 1;
    }
    else if (section ==1){
        return self.cellArray.count;
    }
    else if (section ==2){
        return 1;
    }
    else if (section ==3){
        return 1;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.carouselMainCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            if (self.cellArray.count >= 1) {
                return self.cellArray[0];
            }
        }
        else if (indexPath.row == 1) {
            if (self.cellArray.count >= 2) {
                return self.cellArray[1];
            }
        }
        else if (indexPath.row == 2) {
            if (self.cellArray.count >= 3) {
                return self.cellArray[2];
            }
        }
        else if (indexPath.row == 3) {
            if (self.cellArray.count >= 4) {
                return self.cellArray[3];
            }
        }
        else if (indexPath.row == 4) {
            if (self.cellArray.count >= 5) {
                return self.cellArray[4];
            }
        }
        else{
            return nil;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return self.buttonCell;
        }
    }
    else if (indexPath.section ==3){
        if(indexPath.row == 0){
            return self.spaceCell;
        }
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 246;
        }
    }
    else if (indexPath.section == 1){
        return 44;
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return 144;
        }
    }
    else if (indexPath.section ==3){
        return 60;
    }
    return 44;
}

-(void) calcPostedDate{
    NSDate *createdDate = [self.listingObject objectForKey:@"lastUpdated"];
    NSDate *now = [NSDate date];
    NSTimeInterval distanceBetweenDates = [now timeIntervalSinceDate:createdDate];
    double secondsInAnHour = 3600;
    float minsBetweenDates = (distanceBetweenDates / secondsInAnHour)*60;
    if (minsBetweenDates > 0 && minsBetweenDates < 1) {
        //seconds
        self.postedLabel.text = [NSString stringWithFormat:@"Posted %.fs ago", (minsBetweenDates*60)];
    }
    else if (minsBetweenDates == 1){
        //1 min
        self.postedLabel.text = @"Posted: 1m ago";
    }
    else if (minsBetweenDates > 1 && minsBetweenDates <60){
        //mins
        self.postedLabel.text = [NSString stringWithFormat:@"Posted %.fm ago", minsBetweenDates];
    }
    else if (minsBetweenDates == 60){
        //1 hour
        self.postedLabel.text = @"Posted: 1h ago";
    }
    else if (minsBetweenDates > 60 && minsBetweenDates <1440){
        //hours
        self.postedLabel.text = [NSString stringWithFormat:@"Posted %.fh ago", (minsBetweenDates/60)];
    }
    else if (minsBetweenDates > 1440 && minsBetweenDates < 2880){
        //1 day
        self.postedLabel.text = [NSString stringWithFormat:@"Posted %.fd ago", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 2880 && minsBetweenDates < 10080){
        //days
        self.postedLabel.text = [NSString stringWithFormat:@"Posted %.fd ago", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 10080){
        //weeks
        self.postedLabel.text = [NSString stringWithFormat:@"Posted %.fw ago", (minsBetweenDates/10080)];
    }
    else{
        //fail safe :D
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setDateFormat:@"MMM YY"];
        
        NSDate *formattedDate = [NSDate date];
        self.postedLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:formattedDate]];
        dateFormatter = nil;
    }
}
- (IBAction)saveForLaterPressed:(id)sender {
   
    [self.saveButton setEnabled:NO];
    [[PFUser currentUser] addObject:self.listingObject.objectId forKey:@"savedItems"];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            NSLog(@"saved item");
        }
        else{
            NSLog(@"error saving %@", error);
            [self.saveButton setEnabled:YES];
        }
    }];
}

-(void)BarButtonPressed{
    [self.longButton setEnabled:NO];
    
    //to prevent setting barbutton to nil in diddisappear
    self.barButtonPressed = YES;
    
    if (self.sendMode == YES) {
        //either send message or dismiss
        if ([self.longButton.titleLabel.text isEqualToString:@"D I S M I S S"]) {
            [Answers logCustomEventWithName:@"Dismissed Send Box"
                           customAttributes:@{
                                              @"where":@"Listing"
                                              }];
            NSLog(@"dismiss");
            [self hideSendBox];
            [self.longButton setEnabled:YES];
        }
        else{
            [Answers logCustomEventWithName:@"Sent listing to friend"
                           customAttributes:@{
                                              @"where":@"Listing",
                                              @"message":self.sendBox.messageField.text
                                              }];
            //increment sent property on listing
            [self.listingObject incrementKey:@"sentNumber"];
            [self.listingObject saveInBackground];
            
            //send a message G
            [self sendMessageWithText:self.sendBox.messageField.text];
            [self hideSendBox];
            self.sendMode = NO;
            [self.longButton setEnabled:YES];
        }
    }
    else{
        if ([self.buyer.objectId isEqualToString:[PFUser currentUser].objectId]) {
            [Answers logCustomEventWithName:@"Edit Pressed"
                           customAttributes:@{
                                              @"where":@"Listing"
                                              }];
            [self hideBarButton];

            self.editModePressed = YES;
            CreateViewController *vc = [[CreateViewController alloc]init];
            vc.status = @"edit";
            vc.listing = self.listingObject;
            vc.editFromListing = YES;
            vc.delegate = self;
            NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
            [self presentViewController:nav animated:YES completion:^{
                [self.longButton setEnabled:YES];
            }];
        }
        else{
            [Answers logCustomEventWithName:@"Message Buyer Pressed"
                           customAttributes:@{
                                              @"where":@"Listing"
                                              }];
            [self showHUDForCopy:NO];
            [self setupMessages];
        }
    }
}

-(void)setupMessages{
    
    NSString *possID = [NSString stringWithFormat:@"%@%@%@", [PFUser currentUser].objectId, [[self.listingObject objectForKey:@"postUser"]objectId], self.listingObject.objectId];
    NSString *otherId = [NSString stringWithFormat:@"%@%@%@",[[self.listingObject objectForKey:@"postUser"]objectId],[PFUser currentUser].objectId, self.listingObject.objectId];
    
    //split into sub queries to avoid the contains parameter which can't be indexed
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"convos"];
    [convoQuery whereKey:@"convoId" equalTo:possID];
    
    PFQuery *otherPossConvo = [PFQuery queryWithClassName:@"convos"];
    [otherPossConvo whereKey:@"convoId" equalTo:otherId];
    
    PFQuery *comboConvoQuery = [PFQuery orQueryWithSubqueries:@[convoQuery, otherPossConvo]];
    [comboConvoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if (object) {
            //convo exists, goto that one
            
            [Answers logCustomEventWithName:@"Message Tapped from WTBListing"
                           customAttributes:@{
                                              @"type":@"normal",
                                              }];
            MessageViewController *vc = [[MessageViewController alloc]init];
            vc.convoId = [object objectForKey:@"convoId"];
            vc.convoObject = object;
            vc.listing = self.listingObject;
            vc.otherUser = [object objectForKey:@"buyerUser"];
            vc.otherUserName = self.buyer.username;
//            vc.tabBarHeight = self.tabBarHeight;
            [self.longButton setEnabled:YES];
            [self hideHUD];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            //create a new convo and goto it
            NSLog(@"create a new convo");
            
            PFObject *convoObject = [PFObject objectWithClassName:@"convos"];
            convoObject[@"sellerUser"] = [PFUser currentUser];
            convoObject[@"buyerUser"] = [self.listingObject objectForKey:@"postUser"];
            convoObject[@"itemId"] = self.listingObject.objectId;
            convoObject[@"wtbListing"] = self.listingObject;
            convoObject[@"convoId"] = [NSString stringWithFormat:@"%@%@%@",[[self.listingObject objectForKey:@"postUser"]objectId],[PFUser currentUser].objectId, self.listingObject.objectId];
            convoObject[@"totalMessages"] = @0;
            convoObject[@"buyerUnseen"] = @0;
            convoObject[@"sellerUnseen"] = @0;
            convoObject[@"source"] = @"WTB";
            convoObject[@"profileConvo"] = @"NO";
            
            [convoObject setObject:@"NO" forKey:@"buyerDeleted"];
            [convoObject setObject:@"NO" forKey:@"sellerDeleted"];
            
            //save additional stuff onto convo object for faster inbox loading
            if ([self.listingObject objectForKey:@"thumbnail"]) {
                convoObject[@"thumbnail"] = [self.listingObject objectForKey:@"thumbnail"];
            }
            
            convoObject[@"buyerUsername"] = self.buyer.username;
            convoObject[@"buyerId"] = self.buyer.objectId;
            
            if ([self.buyer objectForKey:@"picture"]) {
                convoObject[@"buyerPicture"] = [self.buyer objectForKey:@"picture"];
            }
            
            convoObject[@"sellerUsername"] = [PFUser currentUser].username;
            convoObject[@"sellerId"] = [PFUser currentUser].objectId;
            
            if ([[PFUser currentUser] objectForKey:@"picture"]) {
                convoObject[@"sellerPicture"] = [[PFUser currentUser] objectForKey:@"picture"];
            }
            
            [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    //saved
                    
                    [Answers logCustomEventWithName:@"Message Tapped from WTBListing"
                                   customAttributes:@{
                                                      @"type":@"normal"
                                                      }];
                    
                    MessageViewController *vc = [[MessageViewController alloc]init];
                    vc.convoId = [convoObject objectForKey:@"convoId"];
                    vc.convoObject = convoObject;
                    vc.listing = self.listingObject;
                    vc.userIsBuyer = NO;
                    vc.otherUser = self.buyer;
                    vc.otherUserName = self.buyer.username;

                    [self hideHUD];
                    [self.longButton setEnabled:YES];
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else{
                    NSLog(@"error saving convo");
                    [self hideHUD];
                    [self.longButton setEnabled:YES];
                }
            }];
        }
    }];
}

-(void)setImageBorder{
    self.buyerImgView.layer.cornerRadius = 25;
    self.buyerImgView.layer.masksToBounds = YES;
    self.buyerImgView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.buyerImgView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)showAlertView{
    [self hideBarButton];
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    if ([self.buyer.objectId isEqualToString:[PFUser currentUser].objectId] || [[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"]|| [[PFUser currentUser].objectId isEqualToString:@"IIEf7cUvrO"]) {
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Are you sure you want to delete your listing?" preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self showBarButton];
            }]];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self.delegate deletedWantedItem];
                
                [self.listingObject setObject:@"deleted" forKey:@"status"];
                [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                }];
            }]];
            
            [self presentViewController:alertView animated:YES completion:nil];
        }]];
        
        if ([[self.listingObject objectForKey:@"status"] isEqualToString:@"purchased"]) {
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Unmark as purchased" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self.delegate changedPurchasedStatus];
                
                [self.listingObject setObject:@"live" forKey:@"status"];
                [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        //hide label
                        
                        [UIView animateWithDuration:0.5
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseIn
                                         animations:^{
                                             self.purchasedLabel.alpha = 0.0;
                                             self.purchasedCheckView.alpha = 0.0;
                                         }
                                         completion:^(BOOL finished) {
                                             [self.purchasedLabel setHidden:YES];
                                             [self.purchasedCheckView setHidden:YES];
                                         }];
                    }
                }];
            }]];
        }
        else if ([[self.listingObject objectForKey:@"status"] isEqualToString:@"live"]) {
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Mark as purchased" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self.delegate changedPurchasedStatus];

                [self showBarButton];
                [self.listingObject setObject:@"purchased" forKey:@"status"];
                [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        //unhide label
                        self.purchasedLabel.alpha = 0.0;
                        self.purchasedCheckView.alpha = 0.0;
                        
                        [self.purchasedLabel setHidden:NO];
                        [self.purchasedCheckView setHidden:NO];
                        
                        [UIView animateWithDuration:0.5
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseIn
                                         animations:^{
                                             self.purchasedLabel.alpha = 1.0;
                                             self.purchasedCheckView.alpha = 1.0;
                                             
                                         }
                                         completion:nil];
                    }
                }];
            }]];
        }
    }
    
    //Share
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share Listing" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Shared item"
                       customAttributes:@{
                                          @"link":@"wanted listing"
                                          }];
        
        NSMutableArray *items = [NSMutableArray new];
        [items addObject:[NSString stringWithFormat:@"Wanted item on Bump 🙏\n\n'%@'\n\nhttp://sobump.com/p?wanted=%@",[self.listingObject objectForKey:@"title" ],self.listingObject.objectId]];
        UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
        [self presentViewController:activityController animated:YES completion:nil];
        
        [activityController setCompletionWithItemsHandler:
         ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
             [self showBarButton];
         }];
    }]];
    
    //Copy Link
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Copy Link" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Copied Link"
                       customAttributes:@{
                                          @"link":@"wanted listing"
                                          }];
        
        NSString *urlString = [NSString stringWithFormat:@"http://sobump.com/p?wanted=%@",self.listingObject.objectId];
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        [pb setString:urlString];
        
        //show HUD
        [self showHUDForCopy:YES];
        
        double delayInSeconds = 2.0; // number of seconds to wait
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self hideHUD];
            self.hud.labelText = @"";
        });
        [self showBarButton];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self showBarButton];
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)showimageHUD{
    if (!self.imageHud) {
        self.imageHud = [MBProgressHUD showHUDAddedTo:self.picView animated:YES];
    }
    self.imageHud.square = YES;
    self.imageHud.mode = MBProgressHUDModeCustomView;
    self.imageHud.color = [UIColor whiteColor];
    
    if (!self.imageSpinner) {
       self.imageSpinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
    }
    
    self.imageHud.customView = self.imageSpinner;
    [self.imageSpinner startAnimating];
}

-(void)hideImageHud{
    [self.imageSpinner stopAnimating];
    [MBProgressHUD hideHUDForView:self.picView animated:NO];
    self.imageSpinner = nil;
    self.imageHud = nil;
}

-(void)showHUDForCopy:(BOOL)copying{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    if (!copying) {
        self.hud.customView = self.spinner;
        [self.spinner startAnimating];
    }
    else{
        self.hud.labelText = @"Copied";
    }
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.hud = nil;
    });
}

-(void)buyerPressed{
    [Answers logCustomEventWithName:@"User tapped"
                   customAttributes:@{
                                      @"where":@"Wanted listing"
                                      }];
    
    self.barButtonPressed = YES;
    
    UserProfileController *vc = [[UserProfileController alloc]init];
    vc.user = self.buyer;
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)upvotePressed:(id)sender {
    
    [Answers logCustomEventWithName:@"Bumped a listing"
                   customAttributes:@{
                                      @"where":@"Listing",
                                      @"type": @"WTB"
                                      }];
    
    //bump array is stored on listing and is the ultimate guide
    //personal bump array is used for displaying on profile quickly
    //also save a Bump object whenever there's a bump so we can access dates/users later
    
    NSMutableArray *bumpArray = [NSMutableArray array];
    if ([self.listingObject objectForKey:@"bumpArray"]) {
        [bumpArray addObjectsFromArray:[self.listingObject objectForKey:@"bumpArray"]];
    }
    
    NSMutableArray *personalBumpArray = [NSMutableArray array];
    if ([[PFUser currentUser] objectForKey:@"wantedBumpArray"]) {
        [personalBumpArray addObjectsFromArray:[[PFUser currentUser] objectForKey:@"wantedBumpArray"]];
    }
    
    //user's general bump array (WTB + WTS)
    NSMutableArray *generalBumpedArray = [NSMutableArray array];
    if ([[PFUser currentUser] objectForKey:@"totalBumpArray"]) {
        [generalBumpedArray addObjectsFromArray:[[PFUser currentUser] objectForKey:@"totalBumpArray"]];
    }
    
    //update profile if viewing item from there
    [self.delegate likedWantedItem];

    if ([bumpArray containsObject:[PFUser currentUser].objectId]) {
        NSLog(@"already bumped it m8");
        
        [self.upVoteButton setSelected:NO];
        [bumpArray removeObject:[PFUser currentUser].objectId];
        
        if (bumpArray.count > 0) {
            [self.viewBumpsButton setTitle:@"L I K E S" forState:UIControlStateNormal];
            [self.viewBumpsButton setEnabled:YES];
        }
        else{
            [self.viewBumpsButton setTitle:@"L I K E" forState:UIControlStateNormal];
            [self.viewBumpsButton setEnabled:NO];
        }
        
        [self.listingObject setObject:bumpArray forKey:@"bumpArray"];
        [self.listingObject incrementKey:@"bumpCount" byAmount:@-1];
        
        if ([personalBumpArray containsObject:self.listingObject.objectId]) {
            [personalBumpArray removeObject:self.listingObject.objectId];
        }
        
        if ([generalBumpedArray containsObject:self.listingObject.objectId]) {
            [generalBumpedArray removeObject:self.listingObject.objectId];
        }
    }
    else{
        NSLog(@"bumped");
        //update upvote lower label, allow user to see who else has bumped the listing
        
        [self.upVoteButton setSelected:YES];
        [bumpArray addObject:[PFUser currentUser].objectId];
        
        if (bumpArray.count > 0) {
            [self.viewBumpsButton setTitle:@"L I K E S" forState:UIControlStateNormal];
            [self.viewBumpsButton setEnabled:YES];
        }
        else{
            [self.viewBumpsButton setTitle:@"L I K E" forState:UIControlStateNormal];
            [self.viewBumpsButton setEnabled:NO];
        }
        
        [self.listingObject addObject:[PFUser currentUser].objectId forKey:@"bumpArray"];
        [self.listingObject incrementKey:@"bumpCount"];
        
        if (![personalBumpArray containsObject:self.listingObject.objectId]) {
            [personalBumpArray addObject:self.listingObject.objectId];
        }
        
        if (![generalBumpedArray containsObject:self.listingObject.objectId]) {
            [generalBumpedArray addObject:self.listingObject.objectId];
        }
        NSString *pushText = [NSString stringWithFormat:@"%@ just liked your wanted listing 👊", [PFUser currentUser].username];
        
        if (![self.buyer.objectId isEqualToString:[PFUser currentUser].objectId]) {
            NSDictionary *params = @{@"userId": [[self.listingObject objectForKey:@"postUser"]objectId], @"message": pushText, @"sender": [PFUser currentUser].username, @"bumpValue": @"NO", @"listingID": self.listingObject.objectId};
            
            if (self.dontLikePush != YES && self.likedAlready != YES) {
                self.likedAlready = YES;
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
        }
        else{
            [Answers logCustomEventWithName:@"Bumped own listing"
                           customAttributes:@{
                                              @"where":@"Listing"
                                              }];
        }
    }
    
    [self.listingObject saveInBackground];
    [[PFUser currentUser]setObject:personalBumpArray forKey:@"wantedBumpArray"];
    [[PFUser currentUser]setObject:generalBumpedArray forKey:@"totalBumpArray"];
    [[PFUser currentUser]saveInBackground];
    
    int count = (int)[bumpArray count];
    if (bumpArray.count > 0) {
        [self.upVoteButton setTitle:[NSString stringWithFormat:@"%@",[self abbreviateNumber:count]] forState:UIControlStateNormal];
    }
    else{
        [self.upVoteButton setTitle:@"" forState:UIControlStateNormal];
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
- (IBAction)viewbumpsPressed:(id)sender {
    if (![self.buyer.objectId isEqualToString:[PFUser currentUser].objectId]) {
        [Answers logCustomEventWithName:@"View Bumps"
                       customAttributes:@{
                                          @"own listing":@"NO"
                                          }];
    }
    else{
        [Answers logCustomEventWithName:@"View Bumps"
                       customAttributes:@{
                                          @"own listing":@"YES"
                                          }];
    }
    
    self.barButtonPressed = YES;

    whoBumpedTableView *vc = [[whoBumpedTableView alloc]init];
    vc.bumpArray = [self.listingObject objectForKey:@"bumpArray"];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)listingRefresh{
    [self.cellArray removeAllObjects];
    NSLog(@"REFRESHING");
    [self.listingObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (!error) {
            if ([self.listingObject objectForKey:@"image4"]){
                [self.picIndicator setNumberOfPages:4];
                [self.picIndicator setHidden:NO];
                self.numberOfPics = 4;
                self.firstImage = [self.listingObject objectForKey:@"image1"];
                self.secondImage = [self.listingObject objectForKey:@"image2"];
                self.thirdImage = [self.listingObject objectForKey:@"image3"];
                self.fourthImage = [self.listingObject objectForKey:@"image4"];
            }
            else if ([self.listingObject objectForKey:@"image3"]){
                [self.picIndicator setNumberOfPages:3];
                self.numberOfPics = 3;
                [self.picIndicator setHidden:NO];
                self.firstImage = [self.listingObject objectForKey:@"image1"];
                self.secondImage = [self.listingObject objectForKey:@"image2"];
                self.thirdImage = [self.listingObject objectForKey:@"image3"];
            }
            else if ([self.listingObject objectForKey:@"image2"]) {
                [self.picIndicator setNumberOfPages:2];
                self.numberOfPics = 2;
                [self.picIndicator setHidden:NO];
                self.firstImage = [self.listingObject objectForKey:@"image1"];
                self.secondImage = [self.listingObject objectForKey:@"image2"];
            }
            else{
                [self.picIndicator setHidden:YES];
                self.numberOfPics = 1;
            }
            
            [self.carouselView reloadData];
            
//            self.picView.contentMode = UIViewContentModeScaleAspectFit;
//            [self.picView setFile:[self.listingObject objectForKey:@"image1"]];
//            [self.picView loadInBackground];
            
            self.titleLabel.text = [self.listingObject objectForKey:@"title"];
            
//            if ([[self.listingObject objectForKey:[NSString stringWithFormat:@"listingPrice%@", self.currency]]intValue]) {
//                int price = [[self.listingObject objectForKey:[NSString stringWithFormat:@"listingPrice%@", self.currency]]intValue];
//                self.priceLabel.text = [NSString stringWithFormat:@"%@%d",self.currencySymbol ,price];
//            }
//            else{
                self.priceLabel.text = @"Negotiable";
//            }
            
            [self.cellArray addObject:self.payCell];
            
            if ([self.listingObject objectForKey:@"condition"]) {
                self.conditionLabel.text = [self.listingObject objectForKey:@"condition"];
                [self.cellArray addObject:self.conditionCell];
            }
            
            if ([self.listingObject objectForKey:@"geopoint"]) {
                NSString *loc = [self.listingObject objectForKey:@"location"];
                self.locationLabel.text = [loc stringByReplacingOccurrencesOfString:@"(null)," withString:@""];
                [self.cellArray addObject:self.locationCell];
            }
            
            if ([self.listingObject objectForKey:@"category"]) {
                if ([[self.listingObject objectForKey:@"category"]isEqualToString:@"Accessories"]) {
                    //do nothing
                }
                else{
                    if ([self.listingObject objectForKey:@"sizeLabel"]) {
                        NSString *sizeNoUK = [[self.listingObject objectForKey:@"sizeLabel"] stringByReplacingOccurrencesOfString:@"UK" withString:@""];
                        
                        if (![self.listingObject objectForKey:@"sizeGender"]) {
                            self.sizeLabel.text = [NSString stringWithFormat:@"%@",sizeNoUK];
                        }
                        else{
                            self.sizeLabel.text = [NSString stringWithFormat:@"%@, %@",[self.listingObject objectForKey:@"sizeGender"], [self.listingObject objectForKey:@"sizeLabel"]];
                        }
                        [self.cellArray addObject:self.sizeCell];
                    }
                }
            }
            
            self.idLabel.text = [NSString stringWithFormat:@"ID %@",self.listingObject.objectId];
            [self.cellArray addObject:self.adminCell];
        }
        [self.tableView reloadData];
    }];
}

-(void)hideBarButton{
    self.buttonShowing = NO;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                         NSLog(@"HIDING");
                     }];
}

-(void)showBarButton{
    self.buttonShowing = YES;
    self.longButton.alpha = 0.0f;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.longButton.alpha = 1.0f;
                         [self.longButton setEnabled:YES];
                     }
                     completion:^(BOOL finished) {
                         NSLog(@"SHOWING");
                     }];
}

#pragma mark - carousel delegates

- (NSInteger)numberOfItemsInCarousel:(__unused iCarousel *)carousel
{
    return self.numberOfPics;
}

- (UIView *)carousel:(__unused iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        view = [[PFImageView alloc] initWithFrame:CGRectMake(0, 0, self.carouselView.frame.size.width,self.carouselView.frame.size.height)];
        view.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    if (index == 0) {
        [((PFImageView *)view)setFile:[self.listingObject objectForKey:@"image1"]];
    }
    else if (index == 1){
        [((PFImageView *)view)setFile:[self.listingObject objectForKey:@"image2"]];
    }
    else if (index == 2){
        [((PFImageView *)view)setFile:[self.listingObject objectForKey:@"image3"]];
    }
    else if (index == 3){
        [((PFImageView *)view)setFile:[self.listingObject objectForKey:@"image4"]];
    }    
    [((PFImageView *)view) loadInBackground];
    
    return view;
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel{
    self.picIndicator.currentPage = self.carouselView.currentItemIndex;
}

- (NSInteger)numberOfPlaceholdersInCarousel:(__unused iCarousel *)carousel
{
    //note: placeholder views are only displayed on some carousels if wrapping is disabled
    return 2;
}

- (UIView *)carousel:(__unused iCarousel *)carousel placeholderViewAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    if (view == nil)
    {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.carouselView.frame.size.width,self.carouselView.frame.size.height)];
        view.contentMode = UIViewContentModeCenter;
        view.backgroundColor = [UIColor whiteColor];
    }
    return view;
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index{
    
    DetailImageController *vc = [[DetailImageController alloc]init];
    vc.listingPic = YES;
    vc.chosenIndex = (int)index;
    vc.delegate = self;
    
    if (self.numberOfPics == 1) {
        vc.numberOfPics = 1;
        vc.listing = self.listingObject;
    }
    else if (self.numberOfPics == 2){
        vc.numberOfPics = 2;
        vc.listing = self.listingObject;
    }
    else if (self.numberOfPics == 3){
        vc.numberOfPics = 3;
        vc.listing = self.listingObject;
    }
    else if (self.numberOfPics == 4){
        vc.numberOfPics = 4;
        vc.listing = self.listingObject;
    }
    vc.modalPresentationStyle = UIModalPresentationCustom;
    vc.transitioningDelegate = self;
    
    [self hideBarButton];
    [self.navigationController presentViewController:vc animated:YES completion:nil];
    
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showNormalAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)dismissedDetailImageViewWithIndex:(NSInteger)lastSelected{
    [self.carouselView scrollToItemAtIndex:lastSelected animated:NO];
    self.picIndicator.currentPage = self.carouselView.currentItemIndex;

    [self showBarButton];
}

-(void)SetupSendBox{
    //setup
    self.sendBox = nil;
    self.bgView = nil;
    self.setupBox = YES;
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SendDialogView" owner:self options:nil];
    self.sendBox = (SendDialogBox *)[nib objectAtIndex:0];
    //self.sendBox.alpha = 0.0;
    [self.sendBox setCollectionViewDataSourceDelegate:self indexPath:nil];
    [self.sendBox setBackgroundColor:[UIColor whiteColor]];
    [self.sendBox.noFriendsButton addTarget:self action:@selector(inviteFriendsPressed) forControlEvents:UIControlEventTouchUpInside];
    
    self.sendBox.messageField.layer.borderColor = [UIColor colorWithRed:0.86 green:0.86 blue:0.86 alpha:1.0].CGColor;
    [self.sendBox.messageField setHidden:YES];
    self.sendBox.messageField.delegate = self;
    
    [self.navigationController.view addSubview:self.sendBox];
    
    [self.sendBox setFrame:CGRectMake(0,[UIApplication sharedApplication].keyWindow.frame.size.height,[UIApplication sharedApplication].keyWindow.frame.size.width,290)];
    
    self.bgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.bgView.backgroundColor = [UIColor blackColor];
    self.bgView.alpha = 0.0;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideSendBox)];
    tap.numberOfTapsRequired = 1;
    [self.bgView addGestureRecognizer:tap];
    [self.navigationController.view insertSubview:self.bgView belowSubview:self.sendBox];
}
- (IBAction)sendPressed:(id)sender {
    [Answers logCustomEventWithName:@"Pressed send listing button"
                   customAttributes:@{
                                      @"where":@"wanted"
                                      }];
    [self ShowInitialSendBox];
}

-(void)hideSendBox{
    
    self.sendMode = NO;
    if ([self.sendBox.messageField isFirstResponder]) {
        //hide text field & prep for keyboard will dismiss delegate being called
        self.hidingSendBox = YES;
        [self.sendBox.messageField resignFirstResponder];
    }
    
    //reset BOOL for other calls to keyboard will hide
    self.hidingSendBox = NO;
    
    //reset textfield
    self.sendBox.messageField.text = @"";
    
    if ([self.buyer.objectId isEqualToString:[PFUser currentUser].objectId]) {
        [self.longButton setTitle:@"E D I T" forState:UIControlStateNormal];
        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
        [self.longButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];
    }
    else{
        [self.longButton setTitle:@"M E S S A G E  B U Y E R" forState:UIControlStateNormal];
        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
        [self.longButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    [self.longButton setEnabled:YES];
    
    //reset collection view
    self.selectedFriend = NO;
    [self.sendBox.collectionView reloadData];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations

                            [self.sendBox setFrame:CGRectMake(0,[UIApplication sharedApplication].keyWindow.frame.size.height,[UIApplication sharedApplication].keyWindow.frame.size.width,290)]; //iPhone 6/7 specific
                            [self.bgView setAlpha:0.0];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                     }];
}

#pragma collection view delegates

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    return self.facebookUsers.count;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    //if user deselects the user thats already selected
    if (self.selectedFriend == YES && self.friendIndexSelected == indexPath.row) {
        //already selected this user so deselect him
        NSLog(@"deselect");
        
        self.selectedFriend = NO;
        [self.sendBox.collectionView reloadData];
        [self.sendBox.smallInviteButton setHidden:NO];
        
        if ([self.sendBox.messageField isFirstResponder]) {
            //dismiss keyboard only and show initial will be called there
            [self.sendBox.messageField resignFirstResponder];
        }
        else{
            //reset to OG appearance by calling show initial
            [self ShowInitialSendBox];
        }
    }
    
    //if user selects another friend instead of the friend currently selected
    else if (self.selectedFriend == YES && self.friendIndexSelected != indexPath.row){
        
        //update the selected friend
        self.friendIndexSelected = (int)indexPath.row;
        
        //refresh
        [self.sendBox.collectionView reloadData];
    }
    
    //first tap of a user
    else{
        //after tapping a user
        [self.sendBox.smallInviteButton setHidden:YES];
        self.selectedFriend = YES;
        self.friendIndexSelected = (int)indexPath.row;
        [self.sendBox.collectionView reloadData];
        
        //scroll up
        [UIView animateWithDuration:0.5
                              delay:0.0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseIn animations:^{
                                //Animations
                                self.bgView.alpha = 0.8;
                                
                                [self.sendBox setFrame:CGRectMake(0,[UIApplication sharedApplication].keyWindow.frame.size.height-(290+self.tabBarHeightInt),[UIApplication sharedApplication].keyWindow.frame.size.width,290)];
                                [self.sendBox.messageField setHidden:NO];
                            }
                         completion:^(BOOL finished) {
                             
                         }];
        
        //title button
        [self.longButton setTitle:@"S E N D" forState:UIControlStateNormal];
        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
        [self.longButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    SendToUserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.userImageView.image = nil;
    
    PFUser *fbUser = [self.facebookUsers objectAtIndex:indexPath.item];
    
    if (![fbUser objectForKey:@"picture"]) {
        NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:15],
                                        NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
        
        [cell.userImageView setImageWithString:fbUser.username color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes];
    }
    else{
        [cell.userImageView setFile:[fbUser objectForKey:@"picture"]];
        [cell.userImageView loadInBackground];
    }
    
    cell.userImageView.layer.cornerRadius = 30;
    cell.userImageView.layer.masksToBounds = YES;
    cell.userImageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    cell.userImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    cell.outerView.layer.cornerRadius = 34;
    cell.outerView.layer.masksToBounds = YES;
    cell.outerView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    cell.outerView.contentMode = UIViewContentModeScaleAspectFill;
    
    if (self.selectedFriend == YES) {
        if (indexPath.row == self.friendIndexSelected) {
            [cell.outerView.layer setBorderColor: [[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0] CGColor]];
            [cell.outerView.layer setBorderWidth: 2.0];
            
            cell.alpha = 1.0;
            self.sendBox.usernameLabel.text = [fbUser objectForKey:@"username"];
        }
        else{
            cell.alpha = 0.5;
            [cell.outerView.layer setBorderWidth: 0.0];
        }
    }
    else{
        [cell.outerView.layer setBorderWidth: 0.0];

        self.sendBox.usernameLabel.text = @"";
        cell.alpha = 1.0;
    }
    
    cell.usernameLabel.text = [fbUser objectForKey:@"username"];
    cell.fullnameLabel.text = [fbUser objectForKey:@"fullname"];
    
    return cell;
}

-(void)loadFacebookFriends{
    
    [self.facebookUsers removeAllObjects];
    
    NSArray *recentArray = [[PFUser currentUser]objectForKey:@"recentFriends"];
    
    //protect against duplicates
    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:recentArray];
    NSArray *recentsWithoutDuplicates = [orderedSet array];
    
    //get recents first
    PFQuery *recentsQuery = [PFUser query];
    [recentsQuery whereKey:@"facebookId" containedIn:recentsWithoutDuplicates];
    [recentsQuery whereKey:@"completedReg" equalTo:@"YES"];
    [recentsQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (objects.count > 0) {
                //order array based on recentFriends array
                for (NSString *facebookID in recentArray) {
                    
                    for (PFUser *friend in objects) {
                        if ([[friend objectForKey:@"facebookId"] isEqualToString:facebookID] && ![self.facebookUsers containsObject:friend]) {
                            [self.facebookUsers addObject:friend];
                            break;
                        }
                    }
                }
            }

            //now get other friends
            PFQuery *friendsQuery = [PFUser query];
            [friendsQuery whereKey:@"facebookId" containedIn:[[PFUser currentUser]objectForKey:@"friends"]];
            [friendsQuery whereKey:@"completedReg" equalTo:@"YES"];
            [friendsQuery orderByAscending:@"fullname"];
            [friendsQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (objects) {
                    if (objects.count == 0) {
                        [self.sendBox.noFriendsButton setHidden:NO];
                        [self.sendBox.smallInviteButton setHidden:YES];
                    }
                    else if (self.facebookUsers.count == 1 && objects.count == 1){
                        //only got one friend who's a recent
                        [self.sendBox.noFriendsButton setHidden:YES];
                        [self.sendBox.collectionView reloadData];
                        
                        [self.sendBox.smallInviteButton setHidden:NO];
                        [self.sendBox.smallInviteButton addTarget:self action:@selector(inviteFriendsPressed) forControlEvents:UIControlEventTouchUpInside];
                    }
                    else{
                        [self.sendBox.smallInviteButton setHidden:NO];
                        [self.sendBox.smallInviteButton addTarget:self action:@selector(inviteFriendsPressed) forControlEvents:UIControlEventTouchUpInside];
                        
                        [self.sendBox.noFriendsButton setHidden:YES];
                        [self.facebookUsers addObjectsFromArray:objects];
                        [self.sendBox.collectionView reloadData];
                    }

                }
                else{
                    NSLog(@"error getting facebook friends %@", error);
                    if (self.facebookUsers.count == 0) {
                        [self.sendBox.noFriendsButton setHidden:NO];
                        [self.sendBox.smallInviteButton setHidden:YES];
                    }
                }
            }];
        }
        else{
            NSLog(@"error loading recent friends! %@", error);
            if (self.facebookUsers.count == 0) {
                [self.sendBox.noFriendsButton setHidden:NO];
                [self.sendBox.smallInviteButton setHidden:YES];
            }
        }
    }];
}

#pragma keyboard observer methods

-(void)listingKeyboardOnScreen:(NSNotification *)notification
{
    NSLog(@"KEYBOARD WILL SHOW");
    if (self.changeKeyboard == NO) {
        return;
    }
    NSDictionary *info  = notification.userInfo;
    NSValue      *value = info[UIKeyboardFrameEndUserInfoKey];
    
    CGRect rawFrame      = [value CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:rawFrame fromView:nil];
    
    //move up sendbox
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            
                            //animate the send box

                            [self.sendBox setFrame:CGRectMake(0,[UIApplication sharedApplication].keyWindow.frame.size.height-(keyboardFrame.size.height + self.sendBox.frame.size.height),self.sendBox.frame.size.width,self.sendBox.frame.size.height)];
                            
                            //animate the long button up
                            [self.longButton setFrame: CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(60 + keyboardFrame.size.height), [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
                        }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)listingKeyboardOFFScreen:(NSNotification *)notification
{
    NSLog(@"KEYBOARD WILL HIDE");

    if (self.changeKeyboard == NO) {
        return;
    }
    self.selectedFriend = NO;
    [self.sendBox.collectionView reloadData];
    [self.sendBox.messageField resignFirstResponder];
    
    //scroll down to hide textfield & change title button
    [self ShowInitialSendBox];
    
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            
                            //animate the long button down
                            [self.longButton setFrame: CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(60 + self.tabBarHeightInt), [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
                        }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)ShowInitialSendBox{
    NSLog(@"SHOW INITIAL");
    if ([[PFUser currentUser]objectForKey:@"facebookId"]) {
        [self.sendBox.smallInviteButton setHidden:NO];
    }
    else{
        [self.sendBox.smallInviteButton setHidden:YES];
        
        [self.sendBox.noFriendsButton setTitle:@"Connect your Facebook to share listings with Friends on Bump!" forState:UIControlStateNormal];
        [self.sendBox.noFriendsButton setHidden:NO];
        [self.sendBox.noFriendsButton addTarget:self action:@selector(connectFacebookPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    
    //update bar button title
    [self.longButton setTitle:@"D I S M I S S" forState:UIControlStateNormal];
    [self.longButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
    [self.longButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];
    
    //show
    [self.sendBox setAlpha:1.0];
    
    if (self.hidingSendBox != YES) {
        //if hiding don't set sendmode as YES!
        self.sendMode = YES;
    }
    
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            self.bgView.alpha = 0.8;

                            [self.sendBox setFrame:CGRectMake(0,[UIApplication sharedApplication].keyWindow.frame.size.height-(240+self.tabBarHeightInt),[UIApplication sharedApplication].keyWindow.frame.size.width,290)];
                        }
                     completion:^(BOOL finished) {
                     }];
}


-(void)sendMessageWithText:(NSString *)messageText{
    //check if there is a profile convo between the users
    
    //seen a crash here [__NSArrayM objectAtIndex:]: index 0 beyond bounds for empty array
    //so added protection
    if (self.facebookUsers.count == 0) {
        return;
    }
    
    PFUser *selectedUser = [self.facebookUsers objectAtIndex:self.friendIndexSelected];
    
    //update recents
    if ([[PFUser currentUser]objectForKey:@"recentFriends"]) {
        NSMutableArray *recentFriends = [NSMutableArray arrayWithArray:[[PFUser currentUser]objectForKey:@"recentFriends"]];
        
        if (recentFriends.count >= 1) {
            if ([recentFriends containsObject:[selectedUser objectForKey:@"facebookId"]]) {
                [recentFriends removeObject:[selectedUser objectForKey:@"facebookId"]];
            }
            
            if (recentFriends.count == 0) {
                //just add back in
                [recentFriends addObject:[selectedUser objectForKey:@"facebookId"]];
            }
            else if(![recentFriends[0]isEqualToString:[selectedUser objectForKey:@"facebookId"]]){
                //check if most recent friend is the same, if so don't readd to array
                [recentFriends insertObject:[selectedUser objectForKey:@"facebookId"] atIndex:0];
            }
            
            [[PFUser currentUser]setObject:recentFriends forKey:@"recentFriends"];
        }
    }
    else{
        NSLog(@"creating recent friends");
        NSMutableArray *recentFriends = [NSMutableArray array];
        [recentFriends insertObject:[selectedUser objectForKey:@"facebookId"] atIndex:0];
        [[PFUser currentUser]setObject:recentFriends forKey:@"recentFriends"];
    }
    [[PFUser currentUser]saveInBackground];
    
    //possible convoIDs
    NSString *possID = [NSString stringWithFormat:@"%@%@", [PFUser currentUser].objectId,selectedUser.objectId];
    NSString *otherId = [NSString stringWithFormat:@"%@%@",selectedUser.objectId,[PFUser currentUser].objectId];
    
    //split into sub queries to avoid the contains parameter which can't be indexed
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"convos"];
    [convoQuery whereKey:@"convoId" equalTo:possID];
    
    PFQuery *otherPossConvo = [PFQuery queryWithClassName:@"convos"];
    [otherPossConvo whereKey:@"convoId" equalTo:otherId];
    
    PFQuery *comboConvoQuery = [PFQuery orQueryWithSubqueries:@[convoQuery, otherPossConvo]];
    [comboConvoQuery whereKey:@"profileConvo" equalTo:@"YES"];
    [comboConvoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //convo exists
            PFObject *convo = object;
            
            //send image
            PFFile *imageFile;
            
            if ([self.listingObject objectForKey:@"thumbnail"]) {
                imageFile = [self.listingObject objectForKey:@"thumbnail"];
            }
            else{
                imageFile = [self.listingObject objectForKey:@"image1"];
            }
            
            PFObject *picObject = [PFObject objectWithClassName:@"messageImages"];
            [picObject setObject:imageFile forKey:@"Image"];
            [picObject setObject:convo forKey:@"convo"];
            [picObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    
                    //save first message
                    PFObject *msgObject = [PFObject objectWithClassName:@"messages"];
                    msgObject[@"message"] = picObject.objectId;
                    msgObject[@"sender"] = [PFUser currentUser];
                    msgObject[@"senderId"] = [PFUser currentUser].objectId;
                    msgObject[@"senderName"] = [PFUser currentUser].username;
                    msgObject[@"convoId"] = [convo objectForKey:@"convoId"];
                    msgObject[@"sharedMessage"] = @"YES";
                    msgObject[@"sharedListing"] = self.listingObject;
                    msgObject[@"status"] = @"sent";
                    msgObject[@"mediaMessage"] = @"YES";
                    [msgObject saveInBackground];
                    
                    //save boiler plate message
                    PFObject *boilerObject = [PFObject objectWithClassName:@"messages"];
                    boilerObject[@"message"] = [NSString stringWithFormat:@"%@ shared %@'s wanted listing.\nTap to view", [PFUser currentUser].username, [[self.listingObject objectForKey:@"postUser"]username]];
                    boilerObject[@"sender"] = [PFUser currentUser];
                    boilerObject[@"senderId"] = [PFUser currentUser].objectId;
                    boilerObject[@"senderName"] = [PFUser currentUser].username;
                    boilerObject[@"convoId"] = [convo objectForKey:@"convoId"];
                    boilerObject[@"status"] = @"sent";
                    boilerObject[@"mediaMessage"] = @"NO";
                    boilerObject[@"sharedMessage"] = @"YES";
                    boilerObject[@"sharedListing"] = self.listingObject;
                    
                    [boilerObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (succeeded) {
                            PFObject *lastSent = boilerObject;
                            
                            NSString *stringCheck = [messageText stringByReplacingOccurrencesOfString:@" " withString:@""];
                            if (![stringCheck isEqualToString:@""]) {
                                //send message too
                                
                                //save boiler plate message
                                PFObject *customObject = [PFObject objectWithClassName:@"messages"];
                                customObject[@"message"] = messageText;
                                customObject[@"sender"] = [PFUser currentUser];
                                customObject[@"senderId"] = [PFUser currentUser].objectId;
                                customObject[@"senderName"] = [PFUser currentUser].username;
                                customObject[@"convoId"] = [convo objectForKey:@"convoId"];
                                customObject[@"status"] = @"sent";
                                customObject[@"mediaMessage"] = @"NO";
                                [customObject saveInBackground];
                                
                                lastSent = customObject;
                            }
                            NSString *pushString = [NSString stringWithFormat:@"%@ shared a wanted listing with you 📲",[[PFUser currentUser]username]];
                            
                            //send push to other user
                            NSDictionary *params = @{@"userId": selectedUser.objectId, @"message": pushString, @"sender": [PFUser currentUser].username};
                            [PFCloud callFunctionInBackground:@"sendPush" withParameters: params block:^(NSDictionary *response, NSError *error) {
                                if (!error) {
                                    NSLog(@"response %@", response);
                                }
                                else{
                                    NSLog(@"image push error %@", error);
                                }
                            }];
                            
                            if ([[[convo objectForKey:@"sellerUser"]objectId]isEqualToString:[[PFUser currentUser]objectId]]) {
                                [convo incrementKey:@"buyerUnseen"];
                            }
                            else{
                                [convo incrementKey:@"sellerUnseen"];
                            }
                            
                            //do all this after final message saved
                            [convo setObject:lastSent forKey:@"lastSent"];
                            [convo incrementKey:@"totalMessages"];
                            [convo setObject:[NSDate date] forKey:@"lastSentDate"];
                            [convo saveInBackground];
                            
                            self.dropShowing = YES;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"messageSentDropDown" object:selectedUser];
                        }
                        else{
                            NSLog(@"error sending message %@", error);
                        }
                    }];
                }
            }];
        }
        else{
            //create a new convo and goto it
            PFObject *convoObject = [PFObject objectWithClassName:@"convos"];
            convoObject[@"sellerUser"] = [PFUser currentUser];
            convoObject[@"buyerUser"] = selectedUser;
            convoObject[@"convoId"] = [NSString stringWithFormat:@"%@%@", [PFUser currentUser].objectId,selectedUser.objectId];
            convoObject[@"profileConvo"] = @"YES";
            convoObject[@"totalMessages"] = @0;
            convoObject[@"buyerUnseen"] = @0;
            convoObject[@"sellerUnseen"] = @0;
            
            ///extra fields for new inbox logic
            convoObject[@"buyerUsername"] = selectedUser.username;
            convoObject[@"buyerId"] = selectedUser.objectId;
            
            if ([selectedUser objectForKey:@"picture"]) {
                convoObject[@"buyerPicture"] = [selectedUser objectForKey:@"picture"];
            }
            
            convoObject[@"sellerUsername"] = [PFUser currentUser].username;
            convoObject[@"sellerId"] = [PFUser currentUser].objectId;
            
            if ([[PFUser currentUser] objectForKey:@"picture"]) {
                convoObject[@"sellerPicture"] = [[PFUser currentUser] objectForKey:@"picture"];
            }
            
            [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    NSLog(@"saved new convo");
                    
                    PFObject *convo = convoObject;
                    
                    //send image
                    PFFile *imageFile;
                    
                    if ([self.listingObject objectForKey:@"thumbnail"]) {
                        imageFile = [self.listingObject objectForKey:@"thumbnail"];
                    }
                    else{
                        imageFile = [self.listingObject objectForKey:@"image1"];
                    }
                    
                    PFObject *picObject = [PFObject objectWithClassName:@"messageImages"];
                    [picObject setObject:imageFile forKey:@"Image"];
                    [picObject setObject:convo forKey:@"convo"];
                    [picObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded) {
                            
                            //save first message
                            PFObject *msgObject = [PFObject objectWithClassName:@"messages"];
                            msgObject[@"message"] = picObject.objectId;
                            msgObject[@"sender"] = [PFUser currentUser];
                            msgObject[@"senderId"] = [PFUser currentUser].objectId;
                            msgObject[@"senderName"] = [PFUser currentUser].username;
                            msgObject[@"convoId"] = [convo objectForKey:@"convoId"];
                            msgObject[@"status"] = @"sent";
                            msgObject[@"mediaMessage"] = @"YES";
                            msgObject[@"sharedMessage"] = @"YES";
                            msgObject[@"sharedListing"] = self.listingObject;
                            
                            [msgObject saveInBackground];
                            
                            //save boiler plate message
                            PFObject *boilerObject = [PFObject objectWithClassName:@"messages"];
                            boilerObject[@"message"] = [NSString stringWithFormat:@"%@ shared %@'s wanted listing.\nTap to view", [PFUser currentUser].username, [[self.listingObject objectForKey:@"postUser"]username]];
                            boilerObject[@"sender"] = [PFUser currentUser];
                            boilerObject[@"senderId"] = [PFUser currentUser].objectId;
                            boilerObject[@"senderName"] = [PFUser currentUser].username;
                            boilerObject[@"convoId"] = [convo objectForKey:@"convoId"];
                            boilerObject[@"status"] = @"sent";
                            boilerObject[@"mediaMessage"] = @"NO";
                            boilerObject[@"sharedMessage"] = @"YES";
                            boilerObject[@"sharedListing"] = self.listingObject;
                            [boilerObject saveInBackground];
                            
                            PFObject *lastSent = boilerObject;
                            
                            NSString *stringCheck = [messageText stringByReplacingOccurrencesOfString:@" " withString:@""];
                            if (![stringCheck isEqualToString:@""]) {
                                //send message too
                                
                                //save custom message
                                PFObject *customObject = [PFObject objectWithClassName:@"messages"];
                                customObject[@"message"] = [messageText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                customObject[@"sender"] = [PFUser currentUser];
                                customObject[@"senderId"] = [PFUser currentUser].objectId;
                                customObject[@"senderName"] = [PFUser currentUser].username;
                                customObject[@"convoId"] = [convo objectForKey:@"convoId"];
                                customObject[@"status"] = @"sent";
                                customObject[@"mediaMessage"] = @"NO";
                                [customObject saveInBackground];
                                
                                lastSent = customObject;
                            }
                            
                            NSString *pushString = [NSString stringWithFormat:@"%@ shared a wanted listing with you 📲",[[PFUser currentUser]username]];
                            
                            //send push to other user
                            NSDictionary *params = @{@"userId": selectedUser.objectId, @"message": pushString, @"sender": [PFUser currentUser].username};
                            [PFCloud callFunctionInBackground:@"sendPush" withParameters: params block:^(NSDictionary *response, NSError *error) {
                                if (!error) {
                                    NSLog(@"response %@", response);
                                }
                                else{
                                    NSLog(@"image push error %@", error);
                                }
                            }];
                            
                            if ([[[convo objectForKey:@"sellerUser"]objectId]isEqualToString:[[PFUser currentUser]objectId]]) {
                                [convo incrementKey:@"buyerUnseen"];
                            }
                            else{
                                [convo incrementKey:@"sellerUnseen"];
                            }
                            
                            //do all this after final message saved
                            [convo setObject:lastSent forKey:@"lastSent"];
                            [convo incrementKey:@"totalMessages"];
                            [convo setObject:[NSDate date] forKey:@"lastSentDate"];
                            [convo saveInBackground];
                            
                            self.dropShowing = YES;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"messageSentDropDown" object:selectedUser];
                            
                            [self.listingObject incrementKey:@"shares"];
                            [self.listingObject saveInBackground];
                        }
                    }];
                }
                else{
                    NSLog(@"error saving convo in profile");
                }
            }];
        }
    }];
}

#pragma mark app invite stuff
-(void)inviteFriendsPressed{
    if (![[PFUser currentUser]objectForKey:@"facebookId"]) {
        return;
    }
    [self showInviteView];
    [self hideSendBox];
    
//    FBSDKAppInviteContent *content =[[FBSDKAppInviteContent alloc] init];
//    content.appLinkURL = [NSURL URLWithString:@"https://www.mydomain.com/myapplink"];
//    //optionally set previewImageURL
//    content.appInvitePreviewImageURL = [NSURL URLWithString:@"https://www.mydomain.com/my_invite_image.jpg"];
//    
//    // Present the dialog. Assumes self is a view controller
//    // which implements the protocol `FBSDKAppInviteDialogDelegate`.
//    [FBSDKAppInviteDialog showFromViewController:self
//                                     withContent:content
//                                        delegate:self];
}

-(void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results{
    NSLog(@"results %@", results);
}

-(void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error{
    NSLog(@"error %@", error);
}

-(void)showHideLongButton:(NSNotification*)note {
    UIViewController *viewController = [note object];
    if ([viewController isKindOfClass:[NavigationController class]]) {
        NavigationController *vc = (NavigationController *)viewController;

        if ([vc.visibleViewController isKindOfClass:[PurchaseTab class]]){
            [self showBarButton];
            
            if (self.modalMode) {
                [self addKeyBoardObservers];
            }

        }
        else{
            [self hideBarButton];
            
            if (self.modalMode) {
                [self removeKeyBoardObservers];
            }

        }
    }
}

-(void)goneToBackground{
    //block further keyboard changes
    self.changeKeyboard = NO;

    //remember keyboard state
    if ([self.sendBox.messageField isFirstResponder]) {
        self.wasShowing = YES;
    }
    else{
        self.wasShowing = NO;
    }
}

-(void)comeBackToForeground{
    self.changeKeyboard = YES;
    
    if (self.wasShowing == YES) {
        [self.sendBox.messageField becomeFirstResponder];
    }
}

-(void)userDidTakeScreenshot{
    [Answers logCustomEventWithName:@"Screenshot taken"
                   customAttributes:@{
                                      @"where":@"Listing"
                                      }];
    self.dropShowing = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"screenshotDropDown" object:self.firstImage];
}

-(void)dismissCreateController:(CreateViewController *)controller{
    [self willAppearSetup];
}

#pragma mark - invite view delegates

-(void)showInviteView{
    [Answers logCustomEventWithName:@"Invite Showing"
                   customAttributes:@{
                                      @"where": @"listing"
                                      }];
    
    if (self.inviteAlertShowing == YES) {
        return;
    }
    
    self.inviteAlertShowing = YES;
    self.inviteBgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.inviteBgView.alpha = 0.0;
    [self.inviteBgView setBackgroundColor:[UIColor blackColor]];
    [[UIApplication sharedApplication].keyWindow addSubview:self.inviteBgView];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.inviteBgView.alpha = 0.8f;
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
                         [self.inviteBgView addGestureRecognizer:self.inviteTap];
                     }];
}

-(void)hideInviteView{
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.inviteBgView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         self.inviteBgView = nil;
                         [self.inviteBgView removeGestureRecognizer:self.inviteTap];
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
                         self.inviteAlertShowing = NO;
                         [self.inviteView setAlpha:0.0];
                         self.inviteView = nil;
                     }];
}

-(void)whatsappPressed{
    [Answers logCustomEventWithName:@"Share Pressed"
                   customAttributes:@{
                                      @"type":@"whatsapp"
                                      }];
    NSString *shareString = @"Check out Bump on the App Store - Safely Buy & Sell Streetwear with ZERO fees\n\nAvailable here: http://sobump.com";
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
    [Answers logCustomEventWithName:@"Share Pressed"
                   customAttributes:@{
                                      @"type":@"share sheet"
                                      }];
    NSMutableArray *items = [NSMutableArray new];
    [items addObject:@"Check out Bump on the App Store - Safely Buy & Sell Streetwear with ZERO fees\n\nAvailable here: http://sobump.com"];
    UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
    
    [self hideBarButton];
    [self hideInviteView];
    
    activityController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *error){
        //called when dismissed
        [self showBarButton];
    };
    
    [self presentViewController:activityController animated:YES completion:nil];
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

-(void)checkStatus{
    if ([[self.listingObject objectForKey:@"status"]isEqualToString:@"purchased"]) {
        [self.purchasedLabel setHidden:NO];
        [self.purchasedCheckView setHidden:NO];
    }
    else{
        [self.purchasedLabel setHidden:YES];
        [self.purchasedCheckView setHidden:YES];
    }
}

#pragma custom VC transition delegate methods

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    
    return [[PresentDetailTransition alloc] init];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    
    return [[DismissDetailTransition alloc] init];
}
-(void)switchingTabs{
    self.justSwitchedTabs = YES;
    
}

-(void)willAppearSetup{
    if (self.justSwitchedTabs == YES) {
        self.justSwitchedTabs = NO;
    }
    
    if (self.buttonShowing == NO) {
        [self showBarButton];
    }
    
    if (self.editModePressed == YES) {
        [self listingRefresh];
        self.editModePressed = NO;
    }

}

-(void)willDisappearSetup{
    [self hideBarButton];
    [self hideSendBox];
}

#pragma for sale listing delegate
-(void)dismissForSaleListing{
    [self willAppearSetup];
}

-(void)addKeyBoardObservers{
    //only called when in modal mode
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(listingKeyboardOnScreen:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(listingKeyboardOFFScreen:) name:UIKeyboardWillHideNotification object:nil];
    [center addObserver:self selector:@selector(userDidTakeScreenshot) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [center addObserver:self selector:@selector(sendPressed:) name:@"showSendBox" object:nil];
}

-(void)removeKeyBoardObservers{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [center removeObserver:self name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [center removeObserver:self name:@"showSendBox" object:nil];
}

-(void)dismissVC{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)reportPressed:(id)sender {
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Report listing" message:@"If you feel like this listing is not genuine or has violated our terms let us know so we can take action asap. Send Team Bump a message from Settings if you'd like to chat immediately." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self showBarButton];
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [Answers logCustomEventWithName:@"Reported Listing"
                       customAttributes:@{
                                          @"type":@"Wanted"
                                          }];
        [self.reportLabel setTitle:@"R E P O R T E D" forState:UIControlStateNormal];
        [self.reportButton setEnabled:NO];
        [self.reportLabel setAlpha:0.5];

        [self showBarButton];
        
        PFObject *reportObject = [PFObject objectWithClassName:@"Reported"];
        
        reportObject[@"reportedUser"] = self.buyer;
        reportObject[@"wtblisting"] = self.listingObject;
        reportObject[@"reporter"] = [PFUser currentUser];
        [reportObject saveInBackground];
    }]];
    
    [self presentViewController:alertView animated:YES completion:nil];
}

#pragma mark - bumping intro delegate
-(void)dismissedBumpingIntro{
    [Answers logCustomEventWithName:@"Seen Bumping Intro"
                   customAttributes:@{
                                      @"where":@"wanted"
                                      }];
    [self showBarButton];
    
    [[PFUser currentUser]setObject:@"YES" forKey:@"seenBumpingIntro"];
    [[PFUser currentUser]saveInBackground];
}

-(void)connectFacebookPressed{
    [self linkFacebookToUser];
}

-(void)linkFacebookToUser{
    
    if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        NSLog(@"it is linked");
        self.barButtonPressed = YES;
        [self hideBarButton];
        
        [PFFacebookUtils linkUserInBackground:[PFUser currentUser] withPublishPermissions:@[] block:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                NSLog(@"linked now!");
                [Answers logCustomEventWithName:@"Successfully Linked Facebook Account"
                               customAttributes:@{
                                                  @"where":@"listing"
                                                  }];
                
                [self retrieveFacebookData];
            }
            else{
                NSLog(@"not linked! %@", error);
                [self showBarButton];
                
                if (error) {
                    [Answers logCustomEventWithName:@"Failed to Link Facebook Account"
                                   customAttributes:@{
                                                      @"where":@"listing"
                                                      }];
                    
                    [self showNormalAlertWithTitle:@"Linking Error" andMsg:@"You may have already signed up for Bump with your Facebook account\n\nSend Team Bump a message from Settings and we'll get it sorted!"];
                }
            }
        }];
    }
    else{
        [Answers logCustomEventWithName:@"Already Linked Facebook Account"
                       customAttributes:@{}];
        
        NSLog(@"is already linked!");
        [self retrieveFacebookData];
    }
}

-(void)retrieveFacebookData{
    NSLog(@"retrieve fb data");
    [self showBarButton];
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setValue:@"id,gender" forKey:@"fields"];
    
    //get FacebookId
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:parameters]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                  id result, NSError *error) {
         if (error == nil)
         {
             NSDictionary *userData = (NSDictionary *)result;
             
             if ([userData objectForKey:@"gender"]) {
                 [[PFUser currentUser] setObject:[userData objectForKey:@"gender"] forKey:@"gender"];
             }
             
             if ([userData objectForKey:@"id"]) {
                 [[PFUser currentUser] setObject:[userData objectForKey:@"id"] forKey:@"facebookId"];
                 [[PFUser currentUser]saveInBackground];
                 
                 //create bumped object so can know when friends create listings
                 PFObject *bumpedObj = [PFObject objectWithClassName:@"Bumped"];
                 [bumpedObj setObject:[[PFUser currentUser] objectForKey:@"facebookId"] forKey:@"facebookId"];
                 [bumpedObj setObject:[PFUser currentUser] forKey:@"user"];
                 [bumpedObj setObject:[NSDate date] forKey:@"safeDate"];
                 [bumpedObj setObject:@0 forKey:@"timesBumped"];
                 [bumpedObj setObject:@"live" forKey:@"status"];
                 [bumpedObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                     if (succeeded) {
                         NSLog(@"saved bumped obj");
                     }
                 }];
             }
             
             //if user doesn't have a profile picture, set their fb one
             if (![[PFUser currentUser]objectForKey:@"picture"]) {
                 if ([userData objectForKey:@"picture"]) {
                     NSString *userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", userData[@"id"]];
                     NSURL *picUrl = [NSURL URLWithString:userImageURL];
                     NSData *picData = [NSData dataWithContentsOfURL:picUrl];
                     
                     //save image
                     if (picData == nil) {
                         
                         [Answers logCustomEventWithName:@"PFFile Nil Data"
                                        customAttributes:@{
                                                           @"pageName":@"Adding FB pic after linking in Wanted Listing"
                                                           }];
                     }
                     else{
                         PFFile *picFile = [PFFile fileWithData:picData];
                         [picFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                             if (succeeded) {
                                 [PFUser currentUser] [@"picture"] = picFile;
                                 [[PFUser currentUser] saveInBackground];
                             }
                             else{
                                 NSLog(@"error saving new facebook pic");
                             }
                         }];
                     }
                 }
             }
             
             
         }
         else{
             NSLog(@"error connecting facebook %@", error);
         }
     }];
    
    //get friends
    FBSDKGraphRequest *friendRequest = [[FBSDKGraphRequest alloc]
                                        initWithGraphPath:@"me/friends/?limit=5000"
                                        parameters:@{@"fields": @"id, name"}
                                        HTTPMethod:@"GET"];
    [friendRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
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
            
            if (friendsHoldingArray.count > 0) {
                [self loadFacebookFriends];

                [[PFUser currentUser]setObject:friendsHoldingArray forKey:@"friends"];
                [[PFUser currentUser] saveInBackground];
            }
        }
        else{
            NSLog(@"error on friends %li", (long)error.code);
        }
    }];
}

-(void)deletedItem{
    //ignore
}

-(void)changedSoldStatus{
    //ignore
}

-(void)likedItem{
    //ignore
}
@end
