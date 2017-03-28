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
#import "ForSaleListing.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ListingController ()

@end

@implementation ListingController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"L I S T I N G";
    
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dotsIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(showAlertView)];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    [self.checkImageView setHidden:YES];
    [self.purchasedLabel setHidden:YES];
    [self.purchasedCheckView setHidden:YES];
    
    self.buyNowArray = [NSMutableArray array];
    self.buyNowIDs = [NSMutableArray array];
    
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
            
//            self.picView.contentMode = UIViewContentModeScaleAspectFit;
//            [self.picView setFile:[self.listingObject objectForKey:@"image1"]];
//            [self.picView loadInBackground];
//            self.picView.layer.cornerRadius = 4;     //doesn't work due to content mode..
//            self.picView.layer.masksToBounds = YES;
            
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
                            self.sizeLabel.text = [NSString stringWithFormat:@"%@, %@",[self.listingObject objectForKey:@"sizeGender"], [self.listingObject objectForKey:@"sizeLabel"]];
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
                
                [self.iwantLabel setTitle:@"S H A R E" forState:UIControlStateNormal];
                [self.iwantButton setImage:[UIImage imageNamed:@"otherSend"] forState:UIControlStateNormal]; //CHECK
                self.wantMode = NO;
                
                [self.longButton setTitle:@"E D I T" forState:UIControlStateNormal];
                [self.longButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
                [self.longButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];
            }
            else{
                [self.longButton setTitle:@"M E S S A G E  B U Y E R" forState:UIControlStateNormal];
                self.wantMode = YES;
                //not the same buyer
                [self.listingObject incrementKey:@"views"];
                [self.listingObject saveInBackground];
            }
            
            if ([[self.listingObject objectForKey:@"status"]isEqualToString:@"purchased"]) {
                [self.purchasedLabel setHidden:NO];
                [self.purchasedCheckView setHidden:NO];
            }
            else{
                [self.purchasedLabel setHidden:YES];
                [self.purchasedCheckView setHidden:YES];
            }
            
            NSMutableArray *bumpArray = [NSMutableArray arrayWithArray:[self.listingObject objectForKey:@"bumpArray"]];
            if ([bumpArray containsObject:[PFUser currentUser].objectId]) {
                [self.upVoteButton setSelected:YES];
            }
            else{
                [self.upVoteButton setSelected:NO];
            }
            if (bumpArray.count > 0) {
                [self.viewBumpsButton setTitle:@"V I E W" forState:UIControlStateNormal];
                int count = (int)[bumpArray count];
                [self.viewBumpsButton setEnabled:YES];
                [self.upVoteButton setTitle:[NSString stringWithFormat:@"%@",[self abbreviateNumber:count]] forState:UIControlStateNormal];
            }
            else{
                [self.viewBumpsButton setEnabled:NO];
                [self.upVoteButton setTitle:@"" forState:UIControlStateNormal];
                [self.viewBumpsButton setTitle:@"B U M P" forState:UIControlStateNormal];
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
    [self loadFacebookFriends];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [self.navigationController.navigationBar setHidden:NO];

    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if (self.buttonShowing == NO) {
        [self showBarButton];
    }
    
    if (self.editModePressed == YES) {
        [self listingRefresh];
        self.editModePressed = NO;
    }
    
    if (self.shouldShowSuccess == YES) {
        self.createdListing = YES;
        [self showSuccess];
    }
    
    if (self.createdListing == YES) {
        NSLog(@"new listing %@",[self.similarListing objectForKey:@"sizeLabel"]);

        if ([self.similarListing objectForKey:@"sizeLabel"]) {
            NSLog(@"got a size label");
            [self.successView.firstButton setHidden:YES];
            [self.successView.secondButton setHidden:YES];
        }
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear: animated];
    NSLog(@"DID APPEAR");
    
    //make sure not adding duplicate observers
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [center removeObserver:self name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [center removeObserver:self name:@"showSendBox" object:nil];
    
    [center addObserver:self selector:@selector(listingKeyboardOnScreen:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(listingKeyboardOFFScreen:) name:UIKeyboardWillHideNotification object:nil];
    [center addObserver:self selector:@selector(userDidTakeScreenshot) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [center addObserver:self selector:@selector(sendPressed:) name:@"showSendBox" object:nil];

}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self hideBarButton];
    [self hideSendBox];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [center removeObserver:self name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [center removeObserver:self name:@"showSendBox" object:nil];

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
    NSDate *createdDate = self.listingObject.createdAt;
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
            [self showHUD];
            [self setupMessages];
        }
    }
}

-(void)setupMessages{
    
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"convos"];
    NSString *possID = [NSString stringWithFormat:@"%@%@%@", [PFUser currentUser].objectId, [[self.listingObject objectForKey:@"postUser"]objectId], self.listingObject.objectId];
    NSString *otherId = [NSString stringWithFormat:@"%@%@%@",[[self.listingObject objectForKey:@"postUser"]objectId],[PFUser currentUser].objectId, self.listingObject.objectId];
    NSArray *idArray = [NSArray arrayWithObjects:possID,otherId, nil];
    
    [convoQuery whereKey:@"convoId" containedIn:idArray];
    [convoQuery includeKey:@"buyerUser"];
    [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //convo exists, goto that one
            MessageViewController *vc = [[MessageViewController alloc]init];
            vc.convoId = [object objectForKey:@"convoId"];
            vc.convoObject = object;
            vc.listing = self.listingObject;
            vc.otherUser = [object objectForKey:@"buyerUser"];
            vc.otherUserName = [[object objectForKey:@"buyerUser"]username];
            vc.tabBarHeight = self.tabBarHeight;
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
            [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    //saved
                    MessageViewController *vc = [[MessageViewController alloc]init];
                    vc.convoId = [convoObject objectForKey:@"convoId"];
                    vc.convoObject = convoObject;
                    vc.listing = self.listingObject;
                    vc.userIsBuyer = NO;
                    vc.otherUser = [self.listingObject objectForKey:@"postUser"];
                    vc.otherUserName = [[self.listingObject objectForKey:@"postUser"]username];
                    vc.tabBarHeight = self.tabBarHeight;
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

    if ([self.buyer.objectId isEqualToString:[PFUser currentUser].objectId]) {
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Are you sure you want to delete your listing?" preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self showBarButton];
            }]];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
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
                
                UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Mark as purchased" message:@"Are you sure you want to mark your WTB as purchased? Sellers will no longer be able to view your WTB and offer to sell you items" preferredStyle:UIAlertControllerStyleAlert];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    [self showBarButton];
                    
                }]];
                [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
                [self presentViewController:alertView animated:YES completion:nil];
            }]];
        }
    }
    else{
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Report listing" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Report listing" message:@"Bump takes inappropriate behaviour very seriously.\nIf you feel like this post has violated our terms let us know so we can make your experience on Bump as brilliant as possible. Call +447590554897 if you'd like to speak to one of the team immediately." preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self showBarButton];
            }]];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self showBarButton];
                PFObject *reportObject = [PFObject objectWithClassName:@"Reported"];
                reportObject[@"reportedUser"] = self.buyer;
                reportObject[@"reporter"] = [PFUser currentUser];
                reportObject[@"listing"] = self.listingObject;
                [reportObject saveInBackground];
            }]];
            
            [self presentViewController:alertView animated:YES completion:nil];
            
        }]];
    }
    
//    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//        [Answers logCustomEventWithName:@"General Share Pressed"
//                       customAttributes:@{
//                                          @"where":@"Listing"
//                                          }];
//        NSMutableArray *items = [NSMutableArray new];
//        [items addObject:[NSString stringWithFormat:@"Check out this WTB: %@\nPosted on Bump http://apple.co/2aY3rBk", [self.listingObject objectForKey:@"title"]]];
//        UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
//        
//        [self presentViewController:activityController animated:YES completion:nil];
//    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share to a Facebook Group" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Share to FB Group Pressed"
                       customAttributes:@{
                                          @"where":@"Listing"
                                          }];
        FBGroupShareViewController *vc = [[FBGroupShareViewController alloc]init];
        vc.objectId = self.listingObject.objectId;
        NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navigationController animated:YES completion:nil];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self showBarButton];
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
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

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
}

-(void)buyerPressed{
    UserProfileController *vc = [[UserProfileController alloc]init];
    vc.user = self.buyer;
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)upvotePressed:(id)sender {
    
    [Answers logCustomEventWithName:@"Bumped a listing"
                   customAttributes:@{
                                      @"where":@"Listing"
                                      }];
    
    //bump array is stored on listing and is the ultimate guide
    //personal bump array is used for displaying on profile quickly
    //also save a Bump object whenever there's a bump so we can access dates/users later
    
    NSMutableArray *bumpArray = [NSMutableArray array];
    if ([self.listingObject objectForKey:@"bumpArray"]) {
        [bumpArray addObjectsFromArray:[self.listingObject objectForKey:@"bumpArray"]];
    }
    
    NSMutableArray *personalBumpArray = [NSMutableArray array];
    if ([[PFUser currentUser] objectForKey:@"bumpArray"]) {
        [personalBumpArray addObjectsFromArray:[[PFUser currentUser] objectForKey:@"bumpArray"]];
    }

    if ([bumpArray containsObject:[PFUser currentUser].objectId]) {
        NSLog(@"already bumped it m8");
        [self.upVoteButton setSelected:NO];
        [bumpArray removeObject:[PFUser currentUser].objectId];
        [self.listingObject setObject:bumpArray forKey:@"bumpArray"];
        [self.listingObject incrementKey:@"bumpCount" byAmount:@-1];
        
        if ([personalBumpArray containsObject:self.listingObject.objectId]) {
            [personalBumpArray removeObject:self.listingObject.objectId];
        }
        
        //update bump object
        PFQuery *bumpQ = [PFQuery queryWithClassName:@"BumpedListings"];
        [bumpQ whereKey:@"bumpUser" equalTo:[PFUser currentUser]];
        [bumpQ whereKey:@"listing" equalTo:self.listingObject];
        [bumpQ findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                for (PFObject *bump in objects) {
                    [bump setObject:@"deleted" forKey:@"status"];
                    [bump saveInBackground];
                }
            }
        }];
    }
    else{
        NSLog(@"bumped");
        [self.upVoteButton setSelected:YES];
        [bumpArray addObject:[PFUser currentUser].objectId];
        [self.listingObject addObject:[PFUser currentUser].objectId forKey:@"bumpArray"];
        [self.listingObject incrementKey:@"bumpCount"];
        
        if (![personalBumpArray containsObject:self.listingObject.objectId]) {
            [personalBumpArray addObject:self.listingObject.objectId];
        }
        NSString *pushText = [NSString stringWithFormat:@"%@ just bumped your listing 👊", [PFUser currentUser].username];
        
        if (![self.buyer.objectId isEqualToString:[PFUser currentUser].objectId]) {
            NSDictionary *params = @{@"userId": [[self.listingObject objectForKey:@"postUser"]objectId], @"message": pushText, @"sender": [PFUser currentUser].username, @"bumpValue": @"NO", @"listingID": self.listingObject.objectId};
            
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
        else{
            [Answers logCustomEventWithName:@"Bumped own listing"
                           customAttributes:@{
                                              @"where":@"Listing"
                                              }];
        }
        
        PFObject *bumpObj = [PFObject objectWithClassName:@"BumpedListings"];
        [bumpObj setObject:self.listingObject forKey:@"listing"];
        [bumpObj setObject:[PFUser currentUser] forKey:@"bumpUser"];
        [bumpObj setObject:@"live" forKey:@"status"];
        [bumpObj saveInBackground];
    }
    
    [self.listingObject saveInBackground];
    [[PFUser currentUser]setObject:personalBumpArray forKey:@"bumpArray"];
    [[PFUser currentUser]saveInBackground];
    
    if (bumpArray.count > 0) {
        [self.viewBumpsButton setTitle:@"V I E W" forState:UIControlStateNormal];
        int count = (int)[bumpArray count];
        [self.viewBumpsButton setEnabled:YES];
        [self.upVoteButton setTitle:[NSString stringWithFormat:@"%@",[self abbreviateNumber:count]] forState:UIControlStateNormal];
    }
    else{
        [self.viewBumpsButton setTitle:@"B U M P" forState:UIControlStateNormal];
        [self.viewBumpsButton setEnabled:NO];
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
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                         self.buttonShowing = NO;
                     }];
}

-(void)showBarButton{
    self.longButton.alpha = 0.0f;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.longButton.alpha = 1.0f;
                         [self.longButton setEnabled:YES];
                     }
                     completion:^(BOOL finished) {
                         self.buttonShowing = YES;
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

-(void)dismissedDetailImageView{
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
    
    NSLog(@"HIDE");
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
    if (collectionView == self.sendBox.collectionView) {
        return self.facebookUsers.count;
    }
    else{
        return self.buyNowArray.count;
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (collectionView != self.sendBox.collectionView) {
        //buy now items
        if (indexPath.row == self.buyNowArray.count-1 && self.buyNowArray.count > 1) {
            
            [Answers logCustomEventWithName:@"Tapped 'view more' after creating listing"
                           customAttributes:@{}];

            self.tabBarController.selectedIndex = 1;
            [self successDonePressed];
        }
        else{
            [Answers logCustomEventWithName:@"Tapped for sale listing after creating listing"
                           customAttributes:@{}];
            
            [self hideSuccess];
            
            self.shouldShowSuccess = YES;
            
            PFObject *WTS = [self.buyNowArray objectAtIndex:indexPath.item];
            ForSaleListing *vc = [[ForSaleListing alloc]init];
            vc.listingObject = WTS;
            vc.WTBObject = self.similarListing;
            vc.source = @"I want too";
            vc.pureWTS = NO;
            NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
            [self presentViewController:nav animated:YES completion:nil];
        }
    }
    else{
        //send collection view
        NSLog(@"selected");
        
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
        else{
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
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView != self.sendBox.collectionView) {
        ForSaleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
        cell.itemView.image = nil;
        
        if (indexPath.row == self.buyNowArray.count-1 && self.buyNowArray.count > 1) {
            [cell.itemView setImage:[UIImage imageNamed:@"viewMore"]];
        }
        else{
            PFObject *WTS = [self.buyNowArray objectAtIndex:indexPath.item];
            //        NSLog(@"WTS: %@ at index: %ld", WTS, (long)indexPath.row);
            //setup cell
            [cell.itemView setFile:[WTS objectForKey:@"thumbnail"]];
            [cell.itemView loadInBackground];
        }
        
        cell.itemView.layer.cornerRadius = 35;
        cell.itemView.layer.masksToBounds = YES;
        cell.itemView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
        cell.itemView.contentMode = UIViewContentModeScaleAspectFill;
        
        return cell;
    }
    
    SendToUserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.userImageView.image = nil;
    
    PFObject *fbUser = [self.facebookUsers objectAtIndex:indexPath.item];

    [cell.userImageView setFile:[fbUser objectForKey:@"picture"]];
    [cell.userImageView loadInBackground];
    
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
                    
                    for (PFObject *friend in objects) {
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
    [self.sendBox.smallInviteButton setHidden:NO];
    
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
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"convos"];
    PFUser *selectedUser = [self.facebookUsers objectAtIndex:self.friendIndexSelected];
    
    //update recents
    if ([[PFUser currentUser]objectForKey:@"recentFriends"]) {
        NSMutableArray *recentFriends = [NSMutableArray arrayWithArray:[[PFUser currentUser]objectForKey:@"recentFriends"]];
        if (recentFriends.count >= 1) {
            //check if most recent friend is the same, if so don't re-add to array
            if (![recentFriends[0]isEqualToString:[selectedUser objectForKey:@"facebookId"]]) {
                NSLog(@"not the same so add to recent array");
                
                if ([recentFriends containsObject:[selectedUser objectForKey:@"facebookId"]]) {
                    NSLog(@"removing user from recents before adding again");
                    [recentFriends removeObject:[selectedUser objectForKey:@"facebookId"]];
                }
                
                [recentFriends insertObject:[selectedUser objectForKey:@"facebookId"] atIndex:0];
                [[PFUser currentUser]setObject:recentFriends forKey:@"recentFriends"];
            }
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
    
    NSArray *idArray = [NSArray arrayWithObjects:possID,otherId, nil];
    
    [convoQuery whereKey:@"convoId" containedIn:idArray];
    [convoQuery includeKey:@"buyerUser"];
    [convoQuery includeKey:@"sellerUser"];
    
    [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //convo exists
            PFObject *convo = object;
            
            //send image1
            PFFile *imageFile = [self.listingObject objectForKey:@"image1"];
            
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
            
            [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    NSLog(@"saved new convo");
                    
                    PFObject *convo = convoObject;
                    
                    //send image1
                    PFFile *imageFile = [self.listingObject objectForKey:@"image1"];
                    
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
    NSLog(@"INvite pressed");
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
        if ([vc.visibleViewController isKindOfClass:[ExploreVC class]]){
            [self showBarButton];
        }
        else{
            [self hideBarButton];
        }
    }
}
- (IBAction)iwantbuttonPressed:(id)sender {
    if (self.wantMode == YES) {
        //present confirmation step
        [self showWantConfirmation];
    }
    else{
        //share
        [self hideBarButton];
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share to a Facebook Group" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [Answers logCustomEventWithName:@"Share to FB Group Pressed"
                           customAttributes:@{
                                              @"where":@"Listing"
                                              }];
            FBGroupShareViewController *vc = [[FBGroupShareViewController alloc]init];
            vc.objectId = self.listingObject.objectId;
            NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:navigationController animated:YES completion:nil];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self showBarButton];
        }]];
        
        [self presentViewController:actionSheet animated:YES completion:nil];
    }
}

-(void)showWantConfirmation{
    if (self.alertShowing == YES) {
        return;
    }
    
    [Answers logCustomEventWithName:@"I want too confirmation seen"
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
    self.customAlert.titleLabel.text = @"Want this too?";
    self.customAlert.messageLabel.text = @"Tap to create a similar listing on Bump & browse relevant for sale items immediately";
    self.customAlert.numberOfButtons = 2;
    [self.customAlert.secondButton setTitle:@"C R E A T E" forState:UIControlStateNormal];
    
    if ([ [ UIScreen mainScreen ] bounds].size.height == 568) {
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
    
    //get current loc in time for when they create the listing
    [self useCurrentLoc];
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
    //dismiss the custom alert view
    //but keep bg darkened out
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
    
    //create the listing
    [self saveListing];
    
}

-(void)saveListing{
    [self showHUD];
    
    NSString *itemTitle = [self.listingObject objectForKey:@"title"];
    
    self.similarListing =[PFObject objectWithClassName:@"wantobuys"];
    
    [self.similarListing setObject:itemTitle forKey:@"title"];
    [self.similarListing setObject:[itemTitle lowercaseString]forKey:@"titleLower"];
    
    //save keywords (minus useless words)
    [self.similarListing setObject:[self.listingObject objectForKey:@"keywords"] forKey:@"keywords"];

    if ([self.listingObject objectForKey:@"searchKeywords"]) {
        [self.similarListing setObject:[self.listingObject objectForKey:@"searchKeywords"] forKey:@"searchKeywords"];
    }
    else{
        [self.similarListing setObject:[self.listingObject objectForKey:@"keywords"] forKey:@"searchKeywords"];
    }
    
    [self.similarListing setObject:@"live" forKey:@"status"];
    
    //expiration in 2 weeks
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.minute = 1;
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *expirationDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
    [self.similarListing setObject:expirationDate forKey:@"expiration"];
        
    if (self.similarGeopoint != nil) {
        [self.similarListing setObject:self.similarLocationString forKey:@"location"];
        [self.similarListing setObject:self.similarGeopoint forKey:@"geopoint"];
    }
    
    [self.similarListing setObject:[NSDate date] forKey:@"lastUpdated"];
    [self.similarListing setObject:@0 forKey:@"views"];
    [self.similarListing setObject:@0 forKey:@"bumpCount"];
    [self.similarListing setObject:self.currency forKey:@"currency"];
    [self.similarListing setObject:[PFUser currentUser] forKey:@"postUser"];
    [self.similarListing setObject:[self.listingObject objectForKey:@"image1"] forKey:@"image1"];
    
    [self.similarListing saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            
            NSLog(@"listing saved! %@", self.similarListing.objectId);
            
            self.createdListing = YES;
            
            [self findRelevantItems];
            
            //analytics
            [Answers logCustomEventWithName:@"Listing Complete"
                           customAttributes:@{
                                              @"mode":@"I want too"
                                              }];
            
            //add listing to home page via notif.
            [[NSNotificationCenter defaultCenter] postNotificationName:@"justPostedListing" object:self.similarListing];
            
            //schedule local notif. for first listing
            if (![[PFUser currentUser] objectForKey:@"postNumber"]) {
                
                //local notifications set up
                NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
                dayComponent.day = 2;
                NSCalendar *theCalendar = [NSCalendar currentCalendar];
                NSDate *dateToFire = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
                
                UILocalNotification *localNotification = [[UILocalNotification alloc]init];
                [localNotification setAlertBody:@"Congrats on your first wanted listing! Swipe to browse recommended items that you can purchase on Bump"];
                [localNotification setFireDate: dateToFire];
                [localNotification setTimeZone: [NSTimeZone defaultTimeZone]];
                [localNotification setRepeatInterval: 0];
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            }
            
            [[PFUser currentUser]incrementKey:@"postNumber"];
            [[PFUser currentUser] saveInBackground];
            
            //send FB friends a push asking them to Bump listing!
            NSString *pushText = [NSString stringWithFormat:@"Your Facebook friend %@ just posted a listing - Tap to Bump it 👊", [[PFUser currentUser] objectForKey:@"fullname"]];
            
            PFQuery *bumpedQuery = [PFQuery queryWithClassName:@"Bumped"];
            [bumpedQuery whereKey:@"facebookId" containedIn:[[PFUser currentUser]objectForKey:@"friends"]];
            [bumpedQuery whereKey:@"safeDate" lessThanOrEqualTo:[NSDate date]];
            [bumpedQuery whereKeyExists:@"user"];
            [bumpedQuery includeKey:@"user"];
            bumpedQuery.limit = 10;
            [bumpedQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (objects) {
                    NSLog(@"these objects can be pushed to %@", objects);
                    if (objects.count > 0) {
                        //create safe date which is 3 days from now
                        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
                        dayComponent.day = 3;
                        NSCalendar *theCalendar = [NSCalendar currentCalendar];
                        NSDate *safeDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
                        
                        for (PFObject *bumpObj in objects) {
                            [bumpObj setObject:safeDate forKey:@"safeDate"];
                            [bumpObj incrementKey:@"timesBumped"];
                            [bumpObj saveInBackground];
                            PFUser *friendUser = [bumpObj objectForKey:@"user"];
                            
                            NSDictionary *params = @{@"userId": friendUser.objectId, @"message": pushText, @"sender": [PFUser currentUser].username, @"bumpValue": @"YES", @"listingID": self.similarListing.objectId};
                            
                            [PFCloud callFunctionInBackground:@"sendNewPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                                if (!error) {
                                    NSLog(@"push response %@", response);
                                    [Answers logCustomEventWithName:@"Sent FB Friend a Bump Push"
                                                   customAttributes:@{}];
                                    [Answers logCustomEventWithName:@"Push Sent"
                                                   customAttributes:@{
                                                                      @"Type":@"FB Friend"
                                                                      }];
                                }
                                else{
                                    NSLog(@"push error %@", error);
                                }
                            }];
                        }
                    }
                }
                else{
                    NSLog(@"error finding relevant bumped obj's %@", error);
                }
            }];
            
            //update wanted words from previous 10 listings
            PFQuery *myPosts = [PFQuery queryWithClassName:@"wantobuys"];
            [myPosts whereKey:@"postUser" equalTo:[PFUser currentUser]];
            [myPosts orderByDescending:@"createdAt"];
            myPosts.limit = 10;
            [myPosts findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (objects) {
                    NSMutableArray *wantedWords = [NSMutableArray array];
                    
                    for (PFObject *listing in objects) {
                        NSArray *keywords = [listing objectForKey:@"keywords"];
                        
                        for (NSString *word in keywords) {
                            if (![wantedWords containsObject:word]) {
                                [wantedWords addObject:word];
                            }
                        }
                    }
                    [[PFUser currentUser] setObject:wantedWords forKey:@"wantedWords"];
                    [[PFUser currentUser] saveInBackground];
                }
                else{
                    NSLog(@"nee posts pet");
                }
            }];
            
            [self hideHUD];
            [self setUpSuccess];
            
        }
        else{
            //error saving listing
            NSLog(@"error saving listing so hiding");
            [self hideHUD];
            NSLog(@"error saving %@", error);
        }
    }];
}

-(void)useCurrentLoc{
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint * _Nullable geoPoint, NSError * _Nullable error) {
        if (!error) {
            double latitude = geoPoint.latitude;
            double longitude = geoPoint.longitude;
            
            CLLocation *loc = [[CLLocation alloc]initWithLatitude:latitude longitude:longitude];
            CLGeocoder *geocoder = [[CLGeocoder alloc]init];
            [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                if (placemarks) {
                    CLPlacemark *placemark = [placemarks lastObject];
                    self.similarLocationString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.administrativeArea];
                    
                    if (geoPoint) {
                        self.similarGeopoint = geoPoint;
                    }
                    else{
                        NSLog(@"error with location");
                    }
                }
                else{
                    NSLog(@"error %@", error);
                }
            }];
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}


#pragma mark - success view methods

-(void)setUpSuccess{
    self.successView = nil;
    
    self.completionShowing = YES;
    self.setupYes = YES;
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SuccessView" owner:self options:nil];
    self.successView = (CreateSuccessView *)[nib objectAtIndex:0];
    self.successView.delegate = self;
    self.successView.alpha = 0.0;
    [self.successView setCollectionViewDataSourceDelegate:self indexPath:nil];
    [[UIApplication sharedApplication].keyWindow insertSubview:self.successView aboveSubview:self.searchBgView];

    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -460, 300, 460)];
    }
    else{
        [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-170, -480, 340, 480)]; //iPhone 6/7 specific
    }
    
    self.successView.layer.cornerRadius = 10;
    self.successView.layer.masksToBounds = YES;
    
    [self.successView.firstButton setHidden:NO];
    [self.successView.secondButton setHidden:NO];
    
    [self showSuccess];
}

-(void)showSuccess{
    NSLog(@"SHOW SUCCESS");
    
    [self.successView setAlpha:1.0];
    [UIView animateWithDuration:1.5
                          delay:0.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.successView setFrame:CGRectMake(0, 0, 300, 460)];
                            }
                            else{
                                [self.successView setFrame:CGRectMake(0, 0, 340, 480)];
                            }
                            self.successView.center = self.view.center;
                            
                            if (self.shouldShowSuccess == YES) {
                                self.searchBgView.alpha = 0.8;
                                self.shouldShowSuccess = NO;
                            }
                            
                        }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)hideSuccess{
    self.createdListing = NO;
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-150,1000, 300, 460)];
                            }
                            else{
                                [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-170,1000, 340, 480)]; //iPhone 6/7 specific
                            }
                            [self.searchBgView setAlpha:0.0];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         self.completionShowing = NO;
                         [self.successView setAlpha:0.0];
                         
                         if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                             //iphone5
                             [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -460, 300, 460)];
                         }
                         else{
                             [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-170, -480, 340, 480)]; //iPhone 6/7 specific
                         }
                         
                         //reset buttons
                         [self.successView.firstButton setHidden:NO];
                         [self.successView.secondButton setHidden:NO];
                     }];
}

-(void)sharePressed{
    [Answers logCustomEventWithName:@"Success Share pressed"
                   customAttributes:@{
                                      @"pageName":@"I want too"
                                      }];
    [self hideSuccess];
    
    self.shouldShowSuccess = YES;
    
    FBGroupShareViewController *vc = [[FBGroupShareViewController alloc]init];
    vc.objectId = self.similarListing.objectId;
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)successDonePressed{
    [Answers logCustomEventWithName:@"Success Done pressed"
                   customAttributes:@{
                                      @"pageName":@"I want too"
                                      }];
    [self hideSuccess];
}

-(void)createPressed{
    [Answers logCustomEventWithName:@"Success Create pressed"
                   customAttributes:@{
                                      @"pageName":@"I want too"
                                      }];
    [self hideSuccess];
    self.tabBarController.selectedIndex = 2;
}

-(void)editPressed{
    [Answers logCustomEventWithName:@"Success Edit pressed"
                   customAttributes:@{
                                      @"pageName":@"I want too"
                                      }];
    [self hideSuccess];
    
    self.shouldShowSuccess = YES;
    
    //show edit VC
    CreateViewController *vc = [[CreateViewController alloc]init];
    vc.status = @"edit";
    vc.listing = self.similarListing;
    vc.addDetails = YES;
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)addMorePressed{
    [Answers logCustomEventWithName:@"Success Add more pressed"
                   customAttributes:@{
                                      @"pageName":@"create"
                                      }];
    [self hideSuccess];
    
    self.shouldShowSuccess = YES;

    //show edit VC
    CreateViewController *vc = [[CreateViewController alloc]init];
    vc.status = @"edit";
    vc.listing = self.similarListing;
    vc.addDetails = YES;
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)findRelevantItems{
    [self.buyNowArray removeAllObjects];
    [self.buyNowIDs removeAllObjects];
    
    NSArray *WTBKeywords = [self.similarListing objectForKey:@"keywords"];
    
    PFQuery *salesQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [salesQuery whereKey:@"status" equalTo:@"live"];
    [salesQuery whereKey:@"keywords" containedIn:WTBKeywords];
    //    [salesQuery orderByDescending:@"createdAt"];
    salesQuery.limit = 10;
    [salesQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            [self.buyNowArray addObjectsFromArray:objects];
            
            for (PFObject *forSale in objects) {
                [self.buyNowIDs addObject:forSale.objectId];
            }
            
            NSLog(@"FIRST LOT %lu", objects.count);
            
            if (objects.count < 10) {
                PFQuery *salesQuery2 = [PFQuery queryWithClassName:@"forSaleItems"];
                [salesQuery2 whereKey:@"status" equalTo:@"live"];
                [salesQuery2 orderByDescending:@"createdAt"];
                [salesQuery whereKey:@"objectId" notContainedIn:self.buyNowIDs];
                salesQuery2.limit = 10-self.buyNowArray.count;
                [salesQuery2 findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (objects) {
                        for (PFObject *forSale in objects) {
                            if (![self.buyNowIDs containsObject:forSale.objectId]) {
                                [self.buyNowArray addObject:forSale];
                                [self.buyNowIDs addObject:forSale.objectId];
                            }
                        }
                        NSLog(@"SECOND LOT %lu", objects.count);
                        [self.successView.collectionView reloadData];
                    }
                    else{
                        NSLog(@"error in second query %@", error);
                    }
                }];
            }
            else{
                [self.successView.collectionView reloadData];
            }
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"screenshotDropDown" object:self.firstImage];
}

-(void)dismissCreateController:(CreateViewController *)controller{
    [self showBarButton];
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
    [Answers logCustomEventWithName:@"Whatsapp share pressed"
                   customAttributes:@{}];
    NSString *shareString = @"Check out Bump on the App Store - the one place for all streetwear WTBs & the latest releases 👟\n\nAvailable here: http://sobump.com";
    NSURL *whatsappURL = [NSURL URLWithString:[NSString stringWithFormat:@"whatsapp://send?text=%@",[self urlencode:shareString]]];
    if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
        [[UIApplication sharedApplication] openURL: whatsappURL];
    }
}

-(void)messengerPressed{
    [Answers logCustomEventWithName:@"Messenger share pressed"
                   customAttributes:@{}];
    NSURL *messengerURL = [NSURL URLWithString:@"fb-messenger://share/?link=http://sobump.com"];
    if ([[UIApplication sharedApplication] canOpenURL: messengerURL]) {
        [[UIApplication sharedApplication] openURL: messengerURL];
    }
}

-(void)textPressed{
    [Answers logCustomEventWithName:@"More share pressed"
                   customAttributes:@{}];
    NSMutableArray *items = [NSMutableArray new];
    [items addObject:@"Check out Bump on the App Store - the one place for all streetwear WTBs & the latest releases 👟\n\nAvailable here: http://sobump.com"];
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


@end
