//
//  ForSaleListing.m
//  wtbtest
//
//  Created by Jack Ryder on 04/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ForSaleListing.h"
#import <DGActivityIndicatorView.h>
#import "MessageViewController.h"
#import "UserProfileController.h"
#import "CreateForSaleListing.h"
#import <Crashlytics/Crashlytics.h>
#import "NavigationController.h"
#import "SendToUserCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "ExploreVC.h"

@interface ForSaleListing ()

@end

@implementation ForSaleListing

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.pageIndicator setHidden:YES];
    self.priceLabel.text = @"";
    self.locationLabel.text = @"";
    self.IDLabel.text = @"";

    self.navigationItem.title = @"S E L L I N G";
    
    self.soldLabel.adjustsFontSizeToFitWidth = YES;
    self.soldLabel.minimumScaleFactor=0.5;
    
    self.priceLabel.adjustsFontSizeToFitWidth = YES;
    self.priceLabel.minimumScaleFactor=0.5;
    
    [self.soldLabel setHidden:YES];
    [self.soldCheckImageVoew setHidden:YES];
        
    if (self.relatedProduct != YES) {
        self.infoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dotsIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(showAlertView)];
        self.navigationItem.rightBarButtonItem = self.infoButton;
    }
    else{
        [self.sellerImgView setHidden:YES];
        [self.trustedCheck setHidden:YES];
    }
    
    if (self.fromBuyNow != YES) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    
    //when presented from search the tab bar does not belong to parent so its passed from previous VCs
    if (self.tabBarController.tabBar.frame.size.height == 0) {
        
        self.tabBarHeightInt = self.presentingViewController.tabBarController.tabBar.frame.size.height;
        
        //register for notification so we know when to dismiss long button after switching tabs
        //because its a modalVC 'willdisappear' never called
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHideLongButton:) name:@"switchedTabs" object:nil];
    }
    else{
        self.tabBarHeightInt = self.tabBarController.tabBar.frame.size.height;
    }
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.infoCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.image2Cell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.carouselCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
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
    self.sizeLabel.adjustsFontSizeToFitWidth = YES;
    self.sizeLabel.minimumScaleFactor=0.5;
    
    [self.descriptionLabel sizeToFit];
    
    //hide first table view header
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
    
    self.locationLabel.adjustsFontSizeToFitWidth = YES;
    self.locationLabel.minimumScaleFactor=0.5;
    
    [self.locationLabel setHidden:YES];
    [self.multipleButton setHidden:YES];
    
    self.descriptionLabel.adjustsFontSizeToFitWidth = YES;
    self.descriptionLabel.minimumScaleFactor=0.5;
    
    self.descriptionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.spaceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.infoCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.sendCell.selectionStyle = UITableViewCellSelectionStyleNone;

    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    //carousel setup
    self.carouselView.type = iCarouselTypeLinear;
    self.carouselView.delegate = self;
    self.carouselView.dataSource = self;
    self.carouselView.pagingEnabled = YES;
    self.carouselView.bounceDistance = 0.3;
    
    //send box setup
    self.facebookUsers = [NSMutableArray array];
    self.friendIndexSelected = 0;
    
    //add keyboard observers
    self.changeKeyboard = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(comeBackToForeground)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:[UIApplication sharedApplication]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goneToBackground)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:[UIApplication sharedApplication]];
    
    [self SetupSendBox];
    [self loadFacebookFriends];
    
    //dismiss Invite gesture
    self.inviteTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideInviteView)];
    self.inviteTap.numberOfTapsRequired = 1;

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
        [view setBackgroundColor:[UIColor whiteColor]];
    }
    
    if (self.affiliateMode == YES) {
        if (index == 0) {
            [((PFImageView *)view)sd_setImageWithURL:[NSURL URLWithString:[self.affiliateObject objectForKey:@"imageURL"]]];
        }
    }
    else{
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
    }

    return view;
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel{
    self.pageIndicator.currentPage = self.carouselView.currentItemIndex;
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
    
    if (self.numberOfPics == 1) {
        vc.numberOfPics = 1;
        if (self.affiliateMode == YES) {
            vc.listing = self.affiliateObject;
            vc.affiliate = YES;
        }
        else{
            vc.listing = self.listingObject;
        }
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
    
    if (self.tabBarController.tabBar.frame.size.height == 0) {
        [self hideBarButton];
        
        //register for delegate so we know when detail disappears on the modal VC thats displaying this for sale VC
        vc.delegate = self;
    }
    [self presentViewController:vc animated:YES completion:nil];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController.navigationBar setHidden:NO];
    
    NSLog(@"APPEAR");

    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if (self.buttonShowing == NO) {
        NSLog(@"BAR B NOT SHOWING");
        if (!self.longButton) {
            NSLog(@"ABOUT TO SETUP");
            [self setupBarButton];
        }
        [self showBarButton];
    }
    
    if (self.affiliateMode == YES) {
        //set button title
        [self.longButton setTitle:@"V I S I T  S T O R E" forState:UIControlStateNormal];
        
        //hide send button
        
        //hide user button
        [self.trustedCheck setHidden:YES];
        [self.sellerImgView setHidden:YES];
        
        //get affiliate object
        [self.affiliateObject fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                
                //description
                NSString *descText = [self.affiliateObject objectForKey:@"description"];
                if ([self.affiliateObject objectForKey:@"brand"]) {
                    //got a brand so display in description
                    self.descriptionLabel.text = [NSString stringWithFormat:@"%@ | %@",[[self.affiliateObject objectForKey:@"brand"] capitalizedString], descText];
                }
                else{
                    self.descriptionLabel.text = descText;
                }
                
                //retailer
                self.sizeLabel.text = [[self.affiliateObject objectForKey:@"retailer"] capitalizedString];
                
                //price
                NSString *priceText = [self.affiliateObject objectForKey:@"price"];
                
                if ([self.affiliateObject objectForKey:@"currency"]) {
                    self.priceLabel.text = [NSString stringWithFormat:@"%@ %@",[self.affiliateObject objectForKey:@"currency"],priceText];
                }
                else{
                    self.priceLabel.text = [NSString stringWithFormat:@"£%@", priceText];
                }
                
                self.IDLabel.text = @"";
                [self.timeIcon setHidden:YES];
                [self.sizeIcon setHidden:YES];
                [self.sendButton setHidden:YES];
                [self.sendLabel setHidden:YES];
                
                //images
                self.numberOfPics = 1;
                [self.carouselView reloadData];
                [self.pageIndicator setHidden:YES];
            }
            else{
                NSLog(@"error fetching object %@", error);
            }
        }];
    }
    else{
        [self.listingObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (!error) {
                //hide multiple button by default
                [self.multipleButton setHidden:YES];
                [self.locationLabel setHidden:NO];
                
                if (self.relatedProduct == YES) {
                    
                    //setup image
                    [self.pageIndicator setHidden:YES];
                    
                    self.numberOfPics = 1;
                    self.firstImage = [self.listingObject objectForKey:@"image1"];
                    
                    self.imageViewTwo.contentMode = UIViewContentModeScaleAspectFit;
                    [self.imageViewTwo setFile:[self.listingObject objectForKey:@"image1"]];
                    [self.imageViewTwo loadInBackground];
                    
                    [self.soldLabel setHidden:NO];
                    self.soldLabel.text = @"fulfilled by END.";
                    [self.soldCheckImageVoew setImage:[UIImage imageNamed:@"fulfillCheck"]];
                    [self.soldCheckImageVoew setHidden:NO];
                    
                    self.priceLabel.text = [self.listingObject objectForKey:@"price"];
                    self.sizeLabel.text = @"Ships to UK";
                    self.locationLabel.text = @"Multiple";
                    self.descriptionLabel.text = [self.listingObject objectForKey:@"title"];
                    
                    [self calcPostedDate];
                    
                    [self.listingObject incrementKey:@"views"];
                    [self.listingObject saveInBackground];
                    
                }
                else{
                    if ([self.listingObject objectForKey:@"image4"]){
                        [self.pageIndicator setNumberOfPages:4];
                        self.numberOfPics = 4;
                        [self.pageIndicator setHidden:NO];
                        self.firstImage = [self.listingObject objectForKey:@"image1"];
                        self.secondImage = [self.listingObject objectForKey:@"image2"];
                        self.thirdImage = [self.listingObject objectForKey:@"image3"];
                        self.fourthImage = [self.listingObject objectForKey:@"image4"];
                        
                    }
                    else if ([self.listingObject objectForKey:@"image3"]){
                        [self.pageIndicator setNumberOfPages:3];
                        self.numberOfPics = 3;
                        [self.pageIndicator setHidden:NO];
                        self.firstImage = [self.listingObject objectForKey:@"image1"];
                        self.secondImage = [self.listingObject objectForKey:@"image2"];
                        self.thirdImage = [self.listingObject objectForKey:@"image3"];
                        
                    }
                    else if ([self.listingObject objectForKey:@"image2"]) {
                        [self.pageIndicator setNumberOfPages:2];
                        self.numberOfPics = 2;
                        [self.pageIndicator setHidden:NO];
                        self.firstImage = [self.listingObject objectForKey:@"image1"];
                        self.secondImage = [self.listingObject objectForKey:@"image2"];
                        
                    }
                    else{
                        [self.pageIndicator setHidden:YES];
                        self.numberOfPics = 1;
                        
                    }
                    [self.carouselView reloadData];
                    
                    self.imageViewTwo.contentMode = UIViewContentModeScaleAspectFit;
                    [self.imageViewTwo setFile:[self.listingObject objectForKey:@"image1"]];
                    [self.imageViewTwo loadInBackground];
                    
                    if ([[self.listingObject objectForKey:@"status"]isEqualToString:@"sold"]) {
                        self.soldLabel.text = @"Sold";
                        [self.soldLabel setHidden:NO];
                        
                        [self.soldCheckImageVoew setImage:[UIImage imageNamed:@"soldCheck"]];
                        [self.soldCheckImageVoew setHidden:NO];
                    }
                    else if([[self.listingObject objectForKey:@"feature"]isEqualToString:@"YES"]){
                        //check if featured
                        self.soldLabel.text = @"Featured";
                        [self.soldLabel setHidden:NO];
                        
                        [self.soldCheckImageVoew setImage:[UIImage imageNamed:@"featuredCheck"]];
                        [self.soldCheckImageVoew setHidden:NO];
                    }
                    
                    self.descriptionLabel.text = [self.listingObject objectForKey:@"description"];
                    
                    float price = [[self.listingObject objectForKey:[NSString stringWithFormat:@"salePrice%@", self.currency]]floatValue];
                    
                    if (price == 0.00) {
                        self.priceLabel.text = @"Negotiable";
                    }
                    else{
                        self.priceLabel.text = [NSString stringWithFormat:@"%@%.2f",self.currencySymbol ,price];
                    }
                    
                    //size & location have been switched around
                    self.sizeLabel.text = [self.listingObject objectForKey:@"location"];
                    
                    
                    if ([[self.listingObject objectForKey:@"category"]isEqualToString:@"Accessories"]) {
                        self.locationLabel.text = @"-";
                    }
                    else{
                        NSString *sizeLabel = [self.listingObject objectForKey:@"sizeLabel"];
                        
                        if ([sizeLabel isEqualToString:@"Multiple"]) {
                            [self.multipleButton setHidden:NO];
                            [self.locationLabel setHidden:YES];
                        }
                        else if([sizeLabel isEqualToString:@"Other"]){
                            self.locationLabel.text = sizeLabel;
                        }
                        else if (![self.listingObject objectForKey:@"sizeGender"]) {
                            self.locationLabel.text = [NSString stringWithFormat:@"%@", sizeLabel];
                        }
                        else{
                            self.locationLabel.text = [NSString stringWithFormat:@"%@, %@",[self.listingObject objectForKey:@"sizeGender"], [self.listingObject objectForKey:@"sizeLabel"]];
                        }
                    }
                    
                    [self calcPostedDate];
                    
                    //seller info
                    self.seller = [self.listingObject objectForKey:@"sellerUser"];
                    
                    if ([self.seller.objectId isEqualToString:[PFUser currentUser].objectId]) {
                        [self.longButton setTitle:@"E D I T" forState:UIControlStateNormal];
                        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
                        [self.longButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];
                    }
                    else{
                        //not the same buyer
                        [self.longButton setTitle:@"M E S S A G E  S E L L E R" forState:UIControlStateNormal];
                        [self.listingObject incrementKey:@"views"];
                        [self.listingObject saveInBackground];
                    }
                    
                    [self setImageBorder];
                    [self.seller fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                        if (object) {
                            
                            PFFile *pic = [self.seller objectForKey:@"picture"];
                            if (pic != nil) {
                                [self.sellerImgView setFile:pic];
                                [self.sellerImgView loadInBackground];
                            }
                            else{
                                [self.sellerImgView setImage:[UIImage imageNamed:@"empty"]];
                            }
                        }
                        else{
                            NSLog(@"seller error %@", error);
                            [self showAlertWithTitle:@"Seller not found!" andMsg:nil];
                        }
                    }];
                    
                    if ([self.source isEqualToString:@"share"]) {
                        [self.tableView reloadData];
                    }
                }
            }
            else{
                NSLog(@"error fetching listing %@", error);
            }
        }];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    NSLog(@"DISAPPEAR");
    
    [self hideBarButton];
    
    if (self.affiliateMode != YES) {
        [self hideSendBox];
    }
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [center removeObserver:self name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [center removeObserver:self name:@"showSendBox" object:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //make sure not adding duplicate observers
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [center removeObserver:self name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [center removeObserver:self name:@"showSendBox" object:nil]; /////adding observers to for sale now for screenshots
    
    [center addObserver:self selector:@selector(listingKeyboardOnScreen:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(listingKeyboardOFFScreen:) name:UIKeyboardWillHideNotification object:nil];
    [center addObserver:self selector:@selector(userDidTakeScreenshot) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [center addObserver:self selector:@selector(sendPressed:) name:@"showSendBox" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        return 2;
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
            return self.carouselCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.infoCell;
        }
        else if (indexPath.row == 1){
            return self.descriptionCell;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return self.sendCell;
        }
    }
    else if (indexPath.section == 3){
        if (indexPath.row == 0) {
            return self.spaceCell;
        }
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 320;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return 83;
        }
        else if (indexPath.row == 1){
            return 105;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return 143;
        }
    }
    else if (indexPath.section == 3){
        if (indexPath.row == 0) {
            return 100;
        }
    }
    return 44;
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

//hide the first header in table view
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == 1){
        return 20.0f;
    }
    return 0.0f;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return @"";
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.0f;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    return headerView;
}

-(void) calcPostedDate{
    NSDate *createdDate = self.listingObject.createdAt;
    NSDate *now = [NSDate date];
    NSTimeInterval distanceBetweenDates = [now timeIntervalSinceDate:createdDate];
    double secondsInAnHour = 3600;
    float minsBetweenDates = (distanceBetweenDates / secondsInAnHour)*60;
    if (minsBetweenDates > 0 && minsBetweenDates < 1) {
        //seconds
        self.IDLabel.text = [NSString stringWithFormat:@"%.fs ago", (minsBetweenDates*60)];
    }
    else if (minsBetweenDates == 1){
        //1 min
        self.IDLabel.text = @"1m ago";
    }
    else if (minsBetweenDates > 1 && minsBetweenDates <60){
        //mins
        self.IDLabel.text = [NSString stringWithFormat:@"%.fm ago", minsBetweenDates];
    }
    else if (minsBetweenDates == 60){
        //1 hour
        self.IDLabel.text = @"1h ago";
    }
    else if (minsBetweenDates > 60 && minsBetweenDates <1440){
        //hours
        self.IDLabel.text = [NSString stringWithFormat:@"%.fh ago", (minsBetweenDates/60)];
    }
    else if (minsBetweenDates > 1440 && minsBetweenDates < 2880){
        //1 day
        self.IDLabel.text = [NSString stringWithFormat:@"%.fd ago", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 2880 && minsBetweenDates < 10080){
        //days
        self.IDLabel.text = [NSString stringWithFormat:@"%.fd ago", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 10080){
        //weeks
        self.IDLabel.text = [NSString stringWithFormat:@"%.fw ago", (minsBetweenDates/10080)];
    }
    else{
        //fail safe :D
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setDateFormat:@"MMM YY"];
        
        NSDate *formattedDate = [NSDate date];
        self.IDLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:formattedDate]];
        dateFormatter = nil;
    }
}

-(void)showAlertView{
    [self hideBarButton];
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self showBarButton];
    }]];
    
    if ([self.seller.objectId isEqualToString:[PFUser currentUser].objectId] || [[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"]|| [[PFUser currentUser].objectId isEqualToString:@"IIEf7cUvrO"]) {
        
        if ([[self.listingObject objectForKey:@"status"] isEqualToString:@"sold"]) {
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Unmark as sold" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self showBarButton];
                [self.listingObject setObject:@"live" forKey:@"status"];
                [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        //hide label
                        self.soldLabel.alpha = 1.0;
                        self.soldCheckImageVoew.alpha = 1.0;
                        
                        [UIView animateWithDuration:0.5
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseIn
                                         animations:^{
                                             if([[self.listingObject objectForKey:@"feature"]isEqualToString:@"YES"]){
                                                 self.soldLabel.text = @"Featured";
                                                 [self.soldCheckImageVoew setImage:[UIImage imageNamed:@"featuredCheck"]];
                                             }
                                             else{
                                                 self.soldLabel.alpha = 0.0;
                                                 self.soldCheckImageVoew.alpha = 0.0;
                                             }
                                         }
                                         completion:^(BOOL finished) {
                                             if(![[self.listingObject objectForKey:@"feature"]isEqualToString:@"YES"]){
                                                 [self.soldLabel setHidden:YES];
                                                 [self.soldCheckImageVoew setHidden:YES];
                                             }
                                         }];
                    }
                }];
            }]];
        }
        else{
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Mark as sold" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
                UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Mark as sold" message:@"Are you sure you want to mark your item as sold? It will no longer be recommended to interested buyers" preferredStyle:UIAlertControllerStyleAlert];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    [self showBarButton];
                    
                }]];
                [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self showBarButton];
                    [self.listingObject setObject:@"sold" forKey:@"status"];
                    [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (succeeded) {
                            //unhide label
                            self.soldLabel.alpha = 0.0;
                            self.soldCheckImageVoew.alpha = 0.0;
                            
                            self.soldLabel.text = @"Sold";
                            [self.soldCheckImageVoew setImage:[UIImage imageNamed:@"soldCheck"]];
                            
                            [self.soldLabel setHidden:NO];
                            [self.soldCheckImageVoew setHidden:NO];
                            
                            [UIView animateWithDuration:0.5
                                                  delay:0
                                                options:UIViewAnimationOptionCurveEaseIn
                                             animations:^{
                                                 self.soldLabel.alpha = 1.0;
                                                 self.soldCheckImageVoew.alpha = 1.0;
                                                 
                                             }
                                             completion:nil];
                        }
                    }];
                }]];
                [self presentViewController:alertView animated:YES completion:nil];
            }]];
        }
        
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
    }
    else{
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Report listing" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Report listing" message:@"Bump takes inappropriate behaviour very seriously. If you feel like this post has violated our terms let us know so we can make your experience on Bump as brilliant as possible. Send Team Bump a message from Settings if you'd like to chat immediately." preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self showBarButton];
            }]];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self showBarButton];
                PFObject *reportObject = [PFObject objectWithClassName:@"Reported"];
                
                if (self.affiliateMode == YES) {
                    reportObject[@"affiliateDic"] = self.affiliateObject;
                }
                else{
                    reportObject[@"reportedUser"] = self.seller;
                    reportObject[@"wtslisting"] = self.listingObject;
                }
                
                reportObject[@"reporter"] = [PFUser currentUser];
                [reportObject saveInBackground];
            }]];
            
            [self presentViewController:alertView animated:YES completion:nil];
            
        }]];
    }
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)setImageBorder{
    self.sellerImgView.layer.cornerRadius = 25;
    self.sellerImgView.layer.masksToBounds = YES;
    self.sellerImgView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.sellerImgView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
}

-(void)BarButtonPressed{
    [self.longButton setEnabled:NO];
    
    if (self.affiliateMode == YES) {
        NSString *descText = [self.affiliateObject objectForKey:@"description"];
        NSString *retailerText = [self.affiliateObject objectForKey:@"retailer"];
        
        [Answers logCustomEventWithName:@"Pressed Visit Affiliate Store"
                       customAttributes:@{
                                          @"item":descText,
                                          @"retailer":retailerText
                                          }];
        
        //open WebView
        self.web = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:[self.affiliateObject objectForKey:@"productURL"]]];
        self.web.showUrlWhileLoading = YES;
        self.web.showPageTitles = YES;
        self.web.doneButtonTitle = @"";
        self.web.infoMode = NO;
        self.web.delegate = self;
        self.web.storeMode = YES;
        
        NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.web];
        [self presentViewController:navigationController animated:YES completion:nil];
        
    }
    else if (self.sendMode == YES) {
        //either send message or dismiss
        if ([self.longButton.titleLabel.text isEqualToString:@"D I S M I S S"]) {
            [Answers logCustomEventWithName:@"Dismissed Send Box"
                           customAttributes:@{
                                              @"where":@"for sale"
                                              }];
            NSLog(@"dismiss");
            [self hideSendBox];
            [self.longButton setEnabled:YES];
        }
        else{
            [Answers logCustomEventWithName:@"Sent listing to friend"
                           customAttributes:@{
                                              @"where":@"for sale",
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
        if (![self.seller.objectId isEqualToString:[PFUser currentUser].objectId]) {
            [self showHUD];
            [self setupMessages];
        }
        else{
            NSLog(@"edit listing");
            CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
            vc.editMode = YES;
            vc.listing = self.listingObject;
            [self.longButton setEnabled:YES];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}
-(void)setupMessages{
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"convos"];
    
    NSString *possID = @"";
    NSString *otherId = @"";
    NSString *descr = [self.listingObject objectForKey:@"description"];
    
    if (descr.length > 25) {
        descr = [descr substringToIndex:25];
        descr = [NSString stringWithFormat:@"%@..", descr];
    }
    
    if (self.pureWTS == YES) {
        //no WTB so use WTS to create convo ID
        possID = [NSString stringWithFormat:@"%@%@%@", [PFUser currentUser].objectId, [[self.listingObject objectForKey:@"sellerUser"]objectId], self.listingObject.objectId];
        otherId = [NSString stringWithFormat:@"%@%@%@",[[self.listingObject objectForKey:@"sellerUser"]objectId],[PFUser currentUser].objectId, self.listingObject.objectId];
    }
    else{
        //there's a WTB so use that for convo ID
        possID = [NSString stringWithFormat:@"%@%@%@", [PFUser currentUser].objectId, [[self.listingObject objectForKey:@"sellerUser"]objectId], self.WTBObject.objectId];
        otherId = [NSString stringWithFormat:@"%@%@%@",[[self.listingObject objectForKey:@"sellerUser"]objectId],[PFUser currentUser].objectId, self.WTBObject.objectId];
    }
    
    NSArray *idArray = [NSArray arrayWithObjects:possID,otherId, nil];
    
    [convoQuery whereKey:@"convoId" containedIn:idArray];
    [convoQuery includeKey:@"buyerUser"];
    [convoQuery includeKey:@"sellerUser"];
    
    [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //convo exists, goto that one but pretype a message like "I'm interested in your Supreme bogo" etc.
            MessageViewController *vc = [[MessageViewController alloc]init];
            vc.convoId = [object objectForKey:@"convoId"];
            vc.convoObject = object;
            vc.listing = self.listingObject;
            vc.otherUser = [object objectForKey:@"sellerUser"];
            vc.otherUserName = [[object objectForKey:@"sellerUser"]username];
            vc.messageSellerPressed = YES;
            vc.sellerItemTitle = descr;
            vc.userIsBuyer = YES;
            
            vc.pureWTS = YES;

//            if (self.pureWTS == YES) {
//            }
//            else{
//                vc.listing = self.WTBObject;
//            }
            [self hideHUD];
            [self.longButton setEnabled:YES];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            //create a new convo and goto it
            PFObject *convoObject = [PFObject objectWithClassName:@"convos"];
            convoObject[@"buyerUser"] = [PFUser currentUser];
            convoObject[@"sellerUser"] = [self.listingObject objectForKey:@"sellerUser"];
            if (self.pureWTS == YES) {
                convoObject[@"pureWTS"] = @"YES";
                convoObject[@"convoId"] = [NSString stringWithFormat:@"%@%@%@",[[self.listingObject objectForKey:@"sellerUser"]objectId],[PFUser currentUser].objectId, self.listingObject.objectId];
            }
            else{
                convoObject[@"pureWTS"] = @"NO";
                convoObject[@"wtbListing"] = self.WTBObject;
                convoObject[@"itemId"] = self.WTBObject.objectId;
                convoObject[@"convoId"] = [NSString stringWithFormat:@"%@%@%@",[[self.listingObject objectForKey:@"sellerUser"]objectId],[PFUser currentUser].objectId, self.WTBObject.objectId];
            }
            
            convoObject[@"wtsListing"] = self.listingObject;
            
            if (self.source) {
                convoObject[@"source"] = self.source; //where did the convo originate from - featured vs WTS
            }
            
            convoObject[@"totalMessages"] = @0;
            convoObject[@"buyerUnseen"] = @0;
            convoObject[@"sellerUnseen"] = @0;
            
            [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    NSLog(@"saved new convo");
                    //saved
                    MessageViewController *vc = [[MessageViewController alloc]init];
                    vc.convoId = [convoObject objectForKey:@"convoId"];
                    vc.convoObject = convoObject;
                    vc.otherUser = [self.listingObject objectForKey:@"sellerUser"];
                    vc.otherUserName = [[self.listingObject objectForKey:@"sellerUser"]username];
                    vc.messageSellerPressed = YES;
                    vc.sellerItemTitle = descr;
                    vc.userIsBuyer = YES;
                    vc.listing = self.listingObject;
                    vc.pureWTS = YES;

//                    if (self.pureWTS == YES) {
//                        vc.pureWTS = YES;
//                    }
//                    else{
//                        vc.listing = self.WTBObject;
//                    }

                    [self hideHUD];
                    [self.longButton setEnabled:YES];
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else{
                    NSLog(@"error saving convo");
                    [self.longButton setEnabled:YES];
                    [self hideHUD];
                }
            }];
        }
    }];
}
- (IBAction)trustedSellerPressed:(id)sender {
    UserProfileController *vc = [[UserProfileController alloc]init];
    vc.user = self.seller;
    vc.saleMode = YES;
    [self.navigationController pushViewController:vc animated:YES];
}
-(void)dismissVC{
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)hideBarButton{
    NSLog(@"HIDE BAR BUTTON");
    self.buttonShowing = NO;

    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)showBarButton{
    NSLog(@"SHOW BAR BUTTON");
    self.buttonShowing = YES;

    self.longButton.alpha = 0.0f;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.longButton.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)setupBarButton{
    self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(60 +self.tabBarHeightInt), [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
    [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
    [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
    [self.longButton addTarget:self action:@selector(BarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.longButton.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
}

#pragma marl - send box delegates
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
                                      @"where":@"for sale"
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
    
    if ([self.seller.objectId isEqualToString:[PFUser currentUser].objectId]) {
        [self.longButton setTitle:@"E D I T" forState:UIControlStateNormal];
        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
        [self.longButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];
    }
    else{
        [self.longButton setTitle:@"M E S S A G E  S E L L E R" forState:UIControlStateNormal];
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

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{

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
            
            //get rest
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
                            [self.longButton setFrame: CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(60+self.tabBarHeightInt), [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
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
                            
                            [self.sendBox setFrame:CGRectMake(0,[UIApplication sharedApplication].keyWindow.frame.size.height-(240 + self.tabBarHeightInt),[UIApplication sharedApplication].keyWindow.frame.size.width,290)];
                        }
                     completion:^(BOOL finished) {
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

-(void)sendMessageWithText:(NSString *)messageText{
    //check if there is a profile convo between the users
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"convos"];
    PFUser *selectedUser = [self.facebookUsers objectAtIndex:self.friendIndexSelected];
    
    //update recents
    if ([[PFUser currentUser]objectForKey:@"recentFriends"]) {
        NSMutableArray *recentFriends = [NSMutableArray arrayWithArray:[[PFUser currentUser]objectForKey:@"recentFriends"]];
        if (recentFriends.count >= 1) {
            
            if ([recentFriends containsObject:[selectedUser objectForKey:@"facebookId"]]) {
                NSLog(@"removing user from recents before adding again");
                [recentFriends removeObject:[selectedUser objectForKey:@"facebookId"]];
            }
            
            //check if most recent friend is the same, if so don't readd to array
            if (![recentFriends[0]isEqualToString:[selectedUser objectForKey:@"facebookId"]]) {
                NSLog(@"not the same so add to recent array");
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
                    msgObject[@"status"] = @"sent";
                    msgObject[@"mediaMessage"] = @"YES";
                    msgObject[@"sharedMessage"] = @"YES";
                    msgObject[@"sharedSaleListing"] = self.listingObject;
                    msgObject[@"Sale"] = @"YES";

                    [msgObject saveInBackground];
                    
                    //save boiler plate message
                    PFObject *boilerObject = [PFObject objectWithClassName:@"messages"];
                    boilerObject[@"message"] = [NSString stringWithFormat:@"%@ shared %@'s for-sale item.\nTap to view", [PFUser currentUser].username, [[self.listingObject objectForKey:@"sellerUser"]username]];
                    boilerObject[@"sender"] = [PFUser currentUser];
                    boilerObject[@"senderId"] = [PFUser currentUser].objectId;
                    boilerObject[@"senderName"] = [PFUser currentUser].username;
                    boilerObject[@"convoId"] = [convo objectForKey:@"convoId"];
                    boilerObject[@"status"] = @"sent";
                    boilerObject[@"mediaMessage"] = @"NO";
                    boilerObject[@"sharedMessage"] = @"YES";
                    boilerObject[@"Sale"] = @"YES";
                    boilerObject[@"sharedSaleListing"] = self.listingObject;
                    
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
                            NSString *pushString = [NSString stringWithFormat:@"%@ shared a for-sale item with you 📲",[[PFUser currentUser]username]];
                            
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
                            msgObject[@"sharedSaleListing"] = self.listingObject;
                            msgObject[@"Sale"] = @"YES";

                            [msgObject saveInBackground];
                            
                            //save boiler plate message
                            PFObject *boilerObject = [PFObject objectWithClassName:@"messages"];
                            boilerObject[@"message"] = [NSString stringWithFormat:@"%@ shared %@'s for-sale item.\nTap to view", [PFUser currentUser].username, [[self.listingObject objectForKey:@"sellerUser"]username]];
                            boilerObject[@"sender"] = [PFUser currentUser];
                            boilerObject[@"senderId"] = [PFUser currentUser].objectId;
                            boilerObject[@"senderName"] = [PFUser currentUser].username;
                            boilerObject[@"convoId"] = [convo objectForKey:@"convoId"];
                            boilerObject[@"status"] = @"sent";
                            boilerObject[@"mediaMessage"] = @"NO";
                            boilerObject[@"sharedMessage"] = @"YES";
                            boilerObject[@"Sale"] = @"YES";
                            boilerObject[@"sharedSaleListing"] = self.listingObject;
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
                            
                            NSString *pushString = [NSString stringWithFormat:@"%@ shared a for-sale item with you 📲",[[PFUser currentUser]username]];
                            
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
- (IBAction)multiplePressed:(id)sender {
    [self showMultipleALert];
}

-(void)showMultipleALert{
    if (self.alertShowing == YES) {
        return;
    }
    self.alertShowing = YES;
    
    [Answers logCustomEventWithName:@"View Multiple Sizes Pressed"
                   customAttributes:@{}];
    
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
    
    NSArray *sizes = [self.listingObject objectForKey:@"multipleSizes"];
    NSString *displayString = @"";
    
    for (NSString *sizeString in sizes) {
        displayString = [NSString stringWithFormat:@"%@UK %@ | ",displayString,sizeString];
    }
    
    self.customAlert.titleLabel.text = @"Available Sizes";
    self.customAlert.messageLabel.text = [NSString stringWithFormat:@"%@", displayString];
    
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
    
    [UIView animateWithDuration:0.5
                          delay:0.2
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
}

-(void)secondPressed{
}

-(void)userDidTakeScreenshot{
    
    [Answers logCustomEventWithName:@"Screenshot taken"
                   customAttributes:@{
                                      @"where":@"For sale"
                                      }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"screenshotDropDown" object:self.firstImage];
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

#pragma mark - detail image viewer delegate
-(void)dismissedDetailImageView{
    [self showBarButton];
}

@end
