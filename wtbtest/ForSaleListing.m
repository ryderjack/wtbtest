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
#import "whoBumpedTableView.h"
#import "UIImage+Resize.h"
#import "PurchaseTab.h"
#import "AppDelegate.h"
#import "UIImageView+Letters.h"
#import "SelectViewController.h"
#import <CLPlacemark+HZContinents.h>

@interface ForSaleListing ()

@end

@implementation ForSaleListing

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.pageIndicator setHidden:YES];
    [self.sellerTextLabel setTextColor:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]];
    
    self.navigationItem.title = @"S E L L I N G";
    [self.zoomPromptLabel setHidden:YES];

    self.countryLabel.text = @"";
    
    self.sendLabel.titleLabel.numberOfLines = 0;
    self.upVoteLabel.titleLabel.numberOfLines = 0;
    self.reportLabel.titleLabel.numberOfLines = 0;

    self.soldLabel.adjustsFontSizeToFitWidth = YES;
    self.soldLabel.minimumScaleFactor=0.5;
    
    self.itemTitle.adjustsFontSizeToFitWidth = YES;
    self.itemTitle.minimumScaleFactor=0.5;
    
    //centre button titles
    self.usernameButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.sendLabel.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.upVoteLabel.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.reportLabel.titleLabel.textAlignment = NSTextAlignmentCenter;

    self.usernameButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.usernameButton.titleLabel.minimumScaleFactor=0.5;
    [self.usernameButton setTitle:@"" forState:UIControlStateNormal];
    
    [self.soldLabel setHidden:YES];
    [self.soldCheckImageVoew setHidden:YES];
        
    self.infoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dotsIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(showAlertView)];
    self.navigationItem.rightBarButtonItem = self.infoButton;
    
    if (self.fromBuyNow != YES) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cancelCross"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    
    //when presented from search the tab bar does not belong to parent so its passed from previous VCs
    if (self.tabBarController.tabBar.frame.size.height == 0) {
        
        self.tabBarHeightInt = self.presentingViewController.tabBarController.tabBar.frame.size.height;
        
        //register for notification so we know when to dismiss long button after switching tabs
        //because its a modalVC 'willdisappear' never called
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHideLowerButtons:) name:@"switchedTabs" object:nil];
    }
    else{
        self.tabBarHeightInt = self.tabBarController.tabBar.frame.size.height;
    }
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.infoCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.image2Cell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.carouselCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.extraInfoCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
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
    self.sizeLabel.adjustsFontSizeToFitWidth = YES;
    self.sizeLabel.minimumScaleFactor=0.5;
    
    [self.descriptionLabel sizeToFit];
    
    //hide first table view header
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);

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
    
    //only load if connected to Fb
    if ([[PFUser currentUser] objectForKey:@"facebookId"]){
        [self loadFacebookFriends];
    }
    
    //dismiss Invite gesture
    self.inviteTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideInviteView)];
    self.inviteTap.numberOfTapsRequired = 1;
    
    //prompt user to tap image to zoom
    if (![[NSUserDefaults standardUserDefaults]boolForKey:@"seenZoomPrompt"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"seenZoomPrompt"];
        
        self.zoomPromptShowing = YES;
        self.carouselView.alpha = 0.2;
        [self.zoomPromptLabel setHidden:NO];
    }
    
}

-(void)hideZoomPrompt{
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.carouselView.alpha = 1.0;
                             self.zoomPromptLabel.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             [self.zoomPromptLabel setHidden:YES];
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
        [view setBackgroundColor:[UIColor whiteColor]];
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
    else if (index == 4){
        [((PFImageView *)view)setFile:[self.listingObject objectForKey:@"image5"]];
    }
    else if (index == 5){
        [((PFImageView *)view)setFile:[self.listingObject objectForKey:@"image6"]];
    }
    else if (index == 6){
        [((PFImageView *)view)setFile:[self.listingObject objectForKey:@"image7"]];
    }
    else if (index == 7){
        [((PFImageView *)view)setFile:[self.listingObject objectForKey:@"image8"]];
    }
    [((PFImageView *)view) loadInBackground];

    return view;
}

-(void)carouselWillBeginDragging:(iCarousel *)carousel{
    //hide zoom prompt if showing
    if (self.zoomPromptShowing == YES) {
        [self hideZoomPrompt];
    }
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
    
    //hide zoom prompt if showing
    if (self.zoomPromptShowing == YES) {
        [self hideZoomPrompt];
    }
    
    [Answers logCustomEventWithName:@"Tapped sale listing image"
                   customAttributes:@{}];
    
    DetailImageController *vc = [[DetailImageController alloc]init];
    vc.listingPic = YES;
    vc.chosenIndex = (int)index;
    vc.numberOfPics = self.numberOfPics;
    vc.listing = self.listingObject;
    vc.delegate = self;

    if (self.tabBarController.tabBar.frame.size.height == 0) {
        [self hideBarButton];
        
        //register for delegate so we know when detail disappears on the modal VC thats displaying this for sale VC
    }
    
    [self presentViewController:vc animated:YES completion:nil];
    
}

-(void)viewWillAppear:(BOOL)animated{
    
    [self.navigationController.navigationBar setHidden:NO];
    [self.navigationController.navigationBar setBarTintColor: nil];

    if (self.anyButtonPressed == YES) {
        self.anyButtonPressed = NO;
    }
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [self.listingObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (!error) {
//            NSLog(@"Listing %@", [self.listingObject objectForKey:@"geopoint"]);
            self.seller = [self.listingObject objectForKey:@"sellerUser"];
            
            [self.seller fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    self.fetchedUser = YES; //to help stop messages infinite spinner
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.usernameButton setTitle:[NSString stringWithFormat:@"@%@", self.seller.username] forState:UIControlStateNormal];
                    });
                    if ([[self.seller objectForKey:@"ignoreLikePushes"]isEqualToString:@"YES"]) {
                        self.dontLikePush = YES;
                    }
                    else{
                        self.dontLikePush = NO;
                    }
                }
                else{
                    NSLog(@"seller error %@", error);
                    [self showAlertWithTitle:@"Seller not found" andMsg:nil];
                }
            }];
            
            if (self.buttonsShowing == NO && !self.purchased) {
                if (!self.setupButtons) {
                    [self decideButtonSetup];
                }
                else{ //TEST this else statement works fine after switching tabs
                    //for when user comes back after switching tabs we need to be able to recreate the bar buttons
                    if (self.buyButtonShowing && !self.buyButton) {
                        [self setupTwoBarButtons];
                    }
                    else if (!self.messageButton){
                        [self setupMessageBarButton];
                    }
                }

                
                [self showBarButton];
            }
            
            self.fetchedListing = YES;
            
            //hide multiple button by default
            [self.multipleButton setHidden:YES];
            
            if ([self.listingObject objectForKey:@"image8"]){
                [self.pageIndicator setNumberOfPages:8];
                self.numberOfPics = 8;
                [self.pageIndicator setHidden:NO];
            }
            else if ([self.listingObject objectForKey:@"image7"]){
                [self.pageIndicator setNumberOfPages:7];
                self.numberOfPics = 7;
                [self.pageIndicator setHidden:NO];
            }
            else if ([self.listingObject objectForKey:@"image6"]){
                [self.pageIndicator setNumberOfPages:6];
                self.numberOfPics = 6;
                [self.pageIndicator setHidden:NO];
            }
            else if ([self.listingObject objectForKey:@"image5"]){
                [self.pageIndicator setNumberOfPages:5];
                self.numberOfPics = 5;
                [self.pageIndicator setHidden:NO];
            }
            else if ([self.listingObject objectForKey:@"image4"]){
                [self.pageIndicator setNumberOfPages:4];
                self.numberOfPics = 4;
                [self.pageIndicator setHidden:NO];
                
            }
            else if ([self.listingObject objectForKey:@"image3"]){
                [self.pageIndicator setNumberOfPages:3];
                self.numberOfPics = 3;
                [self.pageIndicator setHidden:NO];
                
            }
            else if ([self.listingObject objectForKey:@"image2"]) {
                [self.pageIndicator setNumberOfPages:2];
                self.numberOfPics = 2;
                [self.pageIndicator setHidden:NO];
                
            }
            else{
                [self.pageIndicator setHidden:YES];
                self.numberOfPics = 1;
                
            }
            [self.carouselView reloadData];
            
            if ([[self.listingObject objectForKey:@"status"]isEqualToString:@"sold"]) {
                
                if ([[self.listingObject objectForKey:@"buyerId"]isEqualToString:[PFUser currentUser].objectId]) {
                    self.soldLabel.text = @"P U R C H A S E D";
                }
                else{
                    self.soldLabel.text = @"S O L D";
                }
                [self.soldLabel setHidden:NO];
                
                [self.soldCheckImageVoew setImage:[UIImage imageNamed:@"soldCheck"]];
                [self.soldCheckImageVoew setHidden:NO];
            }
            else if ([[self.listingObject objectForKey:@"status"]isEqualToString:@"deleted"]){
                [self showAlertWithTitle:@"Item Deleted" andMsg:@"The seller has removed the item, it may be no longer unavailable - send them a message to find out"];
            }
            
            if ([[self.listingObject objectForKey:@"category"]isEqualToString:@"proxy"]) {
                if ([[NSUserDefaults standardUserDefaults]boolForKey:@"seenProxyWarning"] != YES) {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"seenProxyWarning"];
                    [self showNormalAlertWithTitle:@"Proxy Warning" andMsg:@"A proxy is when someone is willing to queue up for unreleased items on your behalf, it's like a preorder. Usually, you will pay someone proxying for you the retail price of the item plus a fee for the service.\n\nBe careful, always pay via PayPal Goods & Services and ask the user proxying for references so you can be sure they're legitimate. If a user claims they need the payment to be gifted in order to access the funds faster, it's better to decline and find someone that will accept PayPal Goods & Services.\n\nIf you're ever unsure about a proxy, message Team Bump and we'll help you out 🤝"];
                }
            }
            
            //set title label
            NSString *titleString = [self.listingObject objectForKey:@"itemTitle"];
            NSString *titleLabelText = [NSString stringWithFormat:@"%@\n",titleString];
            
            float price;
            NSString *priceText = @"";

            //do we need to show native currency?
            if(self.buyButtonShowing) {
                self.currency = [self.listingObject objectForKey:@"currency"];
                
                price = [[self.listingObject objectForKey:[NSString stringWithFormat:@"salePrice%@",self.currency]]floatValue];
                
                if ([self.currency isEqualToString:@"GBP"]) {
                    self.currencySymbol = @"£";
                }
                else if ([self.currency isEqualToString:@"EUR"]) {
                    self.currencySymbol = @"€";
                }
                else if ([self.currency isEqualToString:@"USD"] || [self.currency isEqualToString:@"AUD"]) {
                    self.currencySymbol = @"$";
                }
                priceText = [NSString stringWithFormat:@"%@%.2f",self.currencySymbol ,price];
                self.purchasePrice = price;
                
//                [self.buyButton setTitle:[NSString stringWithFormat:@"Purchase for %@", priceText] forState:UIControlStateNormal];
            }
            else{
                price = [[self.listingObject objectForKey:[NSString stringWithFormat:@"salePrice%@", self.currency]]floatValue];

            }
            
            
            if (price != 0.00) {
                priceText = [NSString stringWithFormat:@"%@%.2f",self.currencySymbol ,price];
                
                //we have a price so add onto title label
                titleLabelText = [NSString stringWithFormat:@"%@%@", titleLabelText, priceText];
            }
            
            //bold the title
            NSMutableAttributedString *titleTxt = [[NSMutableAttributedString alloc] initWithString:titleLabelText];
            [self modifyString:titleTxt setFontForText:titleString];
            self.itemTitle.attributedText = titleTxt;
            
            NSString *descLabelText = [NSString stringWithFormat:@"Details %@",[self.listingObject objectForKey:@"description"]];
            
            NSMutableAttributedString *descrText = [[NSMutableAttributedString alloc] initWithString:descLabelText];
            [self modifyString:descrText setColorForText:@"Details" withColor:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]];
            self.descriptionLabel.attributedText = descrText;
            
            //check for condition
            NSString *conditionLabelText = @"Condition";
            
            if ([self.listingObject objectForKey:@"condition"]) {
                NSString *condish = [self.listingObject objectForKey:@"condition"];
                
                if ([condish isEqualToString:@"BNWT"] || [condish isEqualToString:@"BNWOT"] || [condish isEqualToString:@"Deadstock"]) {
                    conditionLabelText = [NSString stringWithFormat:@"Condition New"];
                }
                else{
                    conditionLabelText = [NSString stringWithFormat:@"Condition %@",[self.listingObject objectForKey:@"condition"]];
                }
            }
            //colour correct parts of the sizeLabel
            NSMutableAttributedString *conditionString = [[NSMutableAttributedString alloc] initWithString:conditionLabelText];
            [self modifyString:conditionString setColorForText:@"Condition" withColor:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]];
            self.conditionLabel.attributedText = conditionString;
            
            //get size label text
            NSString *sizeLabel = @"Size";
            
            if (![[self.listingObject objectForKey:@"category"]isEqualToString:@"Accessories"]) {
                sizeLabel = [NSString stringWithFormat:@"Size %@",[self.listingObject objectForKey:@"sizeLabel"]];
                
                if ([sizeLabel containsString:@"Multiple"]) {
                    sizeLabel = @"Size";
                    [self.multipleButton setHidden:NO];
                }
                else if([sizeLabel isEqualToString:@"Other"]){
                    sizeLabel = sizeLabel;
                }
//                else if ([self.listingObject objectForKey:@"sizeGender"] && [[self.listingObject objectForKey:@"category"]isEqualToString:@"footwear"]){
//                    sizeLabel = [NSString stringWithFormat:@"Size %@ %@",[self.listingObject objectForKey:@"sizeGender"], [self.listingObject objectForKey:@"sizeLabel"]];
//                }
                else{
                
                    if ([[self.listingObject objectForKey:@"sizeLabel"] isEqualToString:@"XXL"]){
                        sizeLabel = [NSString stringWithFormat:@"Size XXLarge"];
                    }
                    else if ([[self.listingObject objectForKey:@"sizeLabel"] isEqualToString:@"XL"]){
                        sizeLabel = [NSString stringWithFormat:@"Size XLarge"];
                    }
                    else if ([[self.listingObject objectForKey:@"sizeLabel"] isEqualToString:@"L"]){
                        sizeLabel = [NSString stringWithFormat:@"Size Large"];
                    }
                    else if ([[self.listingObject objectForKey:@"sizeLabel"] isEqualToString:@"M"]){
                        sizeLabel = [NSString stringWithFormat:@"Size Medium"];
                    }
                    else if ([[self.listingObject objectForKey:@"sizeLabel"] isEqualToString:@"S"]){
                        sizeLabel = [NSString stringWithFormat:@"Size Small"];
                    }
                    else if ([[self.listingObject objectForKey:@"sizeLabel"] isEqualToString:@"XS"]){
                        sizeLabel = [NSString stringWithFormat:@"Size XSmall"];
                    }
                    else if ([[self.listingObject objectForKey:@"sizeLabel"] isEqualToString:@"XXS"]){
                        sizeLabel = [NSString stringWithFormat:@"Size XXSmall"];
                    }
                    else{
                        sizeLabel = [NSString stringWithFormat:@"Size %@",[self.listingObject objectForKey:@"sizeLabel"]];
                    }
                }
            }
            
            //colour correct parts of the sizeLabel
            NSMutableAttributedString *sizeString = [[NSMutableAttributedString alloc] initWithString:sizeLabel];
            [self modifyString:sizeString setColorForText:@"Size" withColor:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]];
            self.sizeLabel.attributedText = sizeString;
            
            [self calcPostedDate];
            
            if ([self.seller.objectId isEqualToString:[PFUser currentUser].objectId]) {
                [self.messageButton setTitle:@"E D I T" forState:UIControlStateNormal];
                [self.messageButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
                [self.messageButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];
                
                //change report button into 'mark as sold'
                self.markAsSoldMode = YES;
                
                [self.reportButton setImage:[UIImage imageNamed:@"markSoldButton"] forState:UIControlStateNormal];
                [self.reportButton setImage:[UIImage imageNamed:@"soldButtonFill"] forState:UIControlStateSelected];
                
                if (![[self.listingObject objectForKey:@"status"]isEqualToString:@"sold"]) {
                    [self.reportButton setSelected:NO];
                    [self.reportLabel setTitle:@"M A R K  A S\nS O L D" forState:UIControlStateNormal];
                }
                else{
                    [self.reportButton setSelected:YES];
                    
                    //if listing was sold through BUMP checkout, don't let seller mark as available again
                    if ([[self.listingObject objectForKey:@"purchased"]isEqualToString:@"YES"]) {
                        [self.reportButton setEnabled:NO];
                        [self.reportLabel setTitle:@"S O L D" forState:UIControlStateNormal];
                    }
                    else{
                        [self.reportLabel setTitle:@"U N M A R K  A S\nS O L D" forState:UIControlStateNormal];
                    }
                }
            }
            else{
                //not the same buyer
                [self.listingObject incrementKey:@"views"];
                [self.listingObject saveInBackground];
            }
            
            //setup number of likes
            NSMutableArray *bumpArray = [NSMutableArray arrayWithArray:[self.listingObject objectForKey:@"bumpArray"]];
            if ([bumpArray containsObject:[PFUser currentUser].objectId]) {
                //update upvote lower label, allow user to see who else has bumped the listing
                [self.upVoteLabel setTitle:@"L I K E S" forState:UIControlStateNormal];
                [self.upVoteLabel setEnabled:YES];
                [self.upVoteButton setSelected:YES];
            }
            else{
                if (bumpArray.count > 0) {
                    [self.upVoteLabel setTitle:@"L I K E S" forState:UIControlStateNormal];
                    [self.upVoteLabel setEnabled:YES];
                }
                else{
                    [self.upVoteLabel setTitle:@"L I K E" forState:UIControlStateNormal];
                    [self.upVoteLabel setEnabled:NO];
                }
                [self.upVoteButton setSelected:NO];
            }
            
            int count = (int)[bumpArray count];
            if (bumpArray.count > 0) {
                [self.upVoteButton setTitle:[NSString stringWithFormat:@"%@",[self abbreviateNumber:count]] forState:UIControlStateNormal];
            }
            else{
                [self.upVoteButton setTitle:@"" forState:UIControlStateNormal];
            }
            
            //set extra cell info
            NSString *extraString = @"";

            if ([self.listingObject objectForKey:@"quantity"]) {
                
                int quant = [[self.listingObject objectForKey:@"quantity"]intValue];
                
                if ( quant > 1) {
                    
                    if ([self.listingObject objectForKey:@"location"]) {
                        extraString = [NSString stringWithFormat:@"Location %@\n\nQuantity %d", [self.listingObject objectForKey:@"location"],quant];
                    }
                    else{
                        extraString = [NSString stringWithFormat:@"Quantity %d",quant];
                    }
                }
                else{
                    if ([self.listingObject objectForKey:@"location"]) {
                        extraString = [NSString stringWithFormat:@"Location %@", [self.listingObject objectForKey:@"location"]];
                    }
                }
            }
            else if([self.listingObject objectForKey:@"location"]){
                //no quantity but check if there's location
                extraString = [NSString stringWithFormat:@"Location %@", [self.listingObject objectForKey:@"location"]];
            }
            
            //now set location & quantity on label
            if (![extraString isEqualToString:@""]) {
                
                NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:extraString];

                if ([extraString containsString:@"Location"]) {
                    [self modifyString:string setColorForText:@"Location" withColor:[UIColor lightGrayColor]];
                }
                
                if ([extraString containsString:@"Quantity"]) {
                    [self modifyString:string setColorForText:@"Quantity" withColor:[UIColor lightGrayColor]];
                }
                self.countryLabel.attributedText = string;
            }
            
            
            if ([self.source isEqualToString:@"share"] || self.fromPush == YES) {
                [self.tableView reloadData];
            }
            
        }
        else{
            NSLog(@"error fetching listing %@", error);
        }
    }];
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
    
    if (self.tabBarController.tabBar.frame.size.height == 0) {
        [center removeObserver:self name:@"switchedTabs" object:nil];
    }
    
    if (self.dropShowing == YES) {
        //make sure its dismissed
        [[NSNotificationCenter defaultCenter] postNotificationName:@"removeDrop" object:nil];
    }

}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    if (self.anyButtonPressed != YES) {
        NSLog(@"set to nil");
        //fail safe to avoid bar button wrongly showing
        self.messageButton = nil;
        self.buyButton = nil;
        self.longSendButton = nil;
    }
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
    
    if (self.tabBarController.tabBar.frame.size.height == 0) {
        //these observers are for when user is viewing listing from search, where disappear VC methods aren't called!
        [center removeObserver:self name:@"switchedTabs" object:nil];
        [center addObserver:self selector:@selector(showHideLowerButtons:) name:@"switchedTabs" object:nil];
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
        return 3;
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
        else if (indexPath.row == 2){
            return self.extraInfoCell;
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
            return 399;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return 101;
        }
        else if (indexPath.row == 1){
            return 114;
        }
        else if (indexPath.row == 1){
            return 110;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return 143;
        }
    }
    else if (indexPath.section == 3){
        if (indexPath.row == 0) {
            return 90;
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

//-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
//    return @"";
//
//}
//-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
//    return 0.0f;
//}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.contentView.backgroundColor = [UIColor colorWithRed:0.96 green:0.97 blue:0.99 alpha:1.0];

//    if (self.hasMultiple) {
//        header.textLabel.textColor = [UIColor grayColor];
//        header.textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
//        CGRect headerFrame = header.frame;
//        header.textLabel.frame = headerFrame;
//        if (section ==2){
//            header.textLabel.text =  [NSString stringWithFormat:@" %@ Available", [self.listingObject objectForKey:@"quantity"]];
//        }
//    }
}
//
//-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//
//    if (section ==2 && self.hasMultiple){
//        return [NSString stringWithFormat:@" %@ Available", [self.listingObject objectForKey:@"quantity"]];
//    }
//
//    return nil;
//}

-(void) calcPostedDate{
    NSDate *createdDate = [self.listingObject objectForKey:@"lastUpdated"];
    NSDate *now = [NSDate date];
    NSTimeInterval distanceBetweenDates = [now timeIntervalSinceDate:createdDate];
    double secondsInAnHour = 3600;
    float minsBetweenDates = (distanceBetweenDates / secondsInAnHour)*60;
    
    NSString *postedLabelText = @"";
    if (minsBetweenDates >= 0 && minsBetweenDates < 1) {
        //seconds
        postedLabelText = [NSString stringWithFormat:@"Posted %.fs", (minsBetweenDates*60)];
    }
    else if (minsBetweenDates == 1){
        //1 min
        postedLabelText = @"Posted 1m";
    }
    else if (minsBetweenDates > 1 && minsBetweenDates <60){
        //mins
        postedLabelText = [NSString stringWithFormat:@"Posted %.fm", minsBetweenDates];
    }
    else if (minsBetweenDates == 60){
        //1 hour
        postedLabelText = @"Posted 1h";
    }
    else if (minsBetweenDates > 60 && minsBetweenDates <1440){
        //hours
        postedLabelText = [NSString stringWithFormat:@"Posted %.fh", (minsBetweenDates/60)];
    }
    else if (minsBetweenDates > 1440 && minsBetweenDates < 2880){
        //1 day
        postedLabelText = [NSString stringWithFormat:@"Posted %.fd", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 2880 && minsBetweenDates < 10080){
        //days
        postedLabelText = [NSString stringWithFormat:@"Posted %.fd", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 10080){
        //weeks
        //if posted weeks ago hide label and the clock icon
//        [self.IDLabel setHidden:YES];
        postedLabelText = [NSString stringWithFormat:@"Posted %.fw", (minsBetweenDates/10080)];
    }
    else{
        //fail safe :D
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setDateFormat:@"MMM YY"];
        
        NSDate *formattedDate = [NSDate date];
        postedLabelText = [NSString stringWithFormat:@"Posted %@", [dateFormatter stringFromDate:formattedDate]];
        dateFormatter = nil;
    }
    
    //colour correct parts of the sizeLabel
    NSMutableAttributedString *sizeString = [[NSMutableAttributedString alloc] initWithString:postedLabelText];
    [self modifyString:sizeString setColorForText:@"Posted" withColor:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0]];
    self.IDLabel.attributedText = sizeString;
}

-(void)showAlertView{
    [self hideBarButton];
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self showBarButton];
    }]];
    
    if ([self.seller.objectId isEqualToString:[PFUser currentUser].objectId] || [[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"]|| [[PFUser currentUser].objectId isEqualToString:@"IIEf7cUvrO"]) {
        
//        if ([[self.listingObject objectForKey:@"status"] isEqualToString:@"sold"]) {
//            
//            //user's profile tab is listening for this to reload the cell and not scroll up!
//            [self.delegate changedSoldStatus];
//            
//            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Unmark as sold" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//                [self showBarButton];
//                [self.listingObject setObject:@"live" forKey:@"status"];
//                [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//                    if (succeeded) {
//                        //hide label
//                        self.soldLabel.alpha = 1.0;
//                        self.soldCheckImageVoew.alpha = 1.0;
//                        
//                        [UIView animateWithDuration:0.5
//                                              delay:0
//                                            options:UIViewAnimationOptionCurveEaseIn
//                                         animations:^{
//                                             if([[self.listingObject objectForKey:@"feature"]isEqualToString:@"YES"]){
//                                                 self.soldLabel.text = @"Featured";
//                                                 [self.soldCheckImageVoew setImage:[UIImage imageNamed:@"featuredCheck"]];
//                                             }
//                                             else{
//                                                 self.soldLabel.alpha = 0.0;
//                                                 self.soldCheckImageVoew.alpha = 0.0;
//                                             }
//                                         }
//                                         completion:^(BOOL finished) {
//                                             if(![[self.listingObject objectForKey:@"feature"]isEqualToString:@"YES"]){
//                                                 [self.soldLabel setHidden:YES];
//                                                 [self.soldCheckImageVoew setHidden:YES];
//                                             }
//                                         }];
//                    }
//                }];
//            }]];
//        }
//        else{
//            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Mark as sold" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//                
//                //user's profile tab is listening for this to reload the cell and not scroll up!
//                [self.delegate changedSoldStatus];
//                
//                [self showBarButton];
//                [self.listingObject setObject:@"sold" forKey:@"status"];
//                [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//                    if (succeeded) {
//                        //unhide label
//                        self.soldLabel.alpha = 0.0;
//                        self.soldCheckImageVoew.alpha = 0.0;
//                        
//                        self.soldLabel.text = @"S O L D";
//                        [self.soldCheckImageVoew setImage:[UIImage imageNamed:@"soldCheck"]];
//                        
//                        [self.soldLabel setHidden:NO];
//                        [self.soldCheckImageVoew setHidden:NO];
//                        
//                        [UIView animateWithDuration:0.5
//                                              delay:0
//                                            options:UIViewAnimationOptionCurveEaseIn
//                                         animations:^{
//                                             self.soldLabel.alpha = 1.0;
//                                             self.soldCheckImageVoew.alpha = 1.0;
//                                             
//                                         }
//                                         completion:nil];
//                    }
//                }];
//            }]];
//        }
//        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Are you sure you want to delete your listing?" preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self showBarButton];
            }]];
            [alertView addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self.listingObject setObject:@"deleted" forKey:@"status"];
                [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        [self.delegate deletedItem];
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                }];
            }]];
            
            [self presentViewController:alertView animated:YES completion:nil];
        }]];
    }
    
    //Share
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share Listing" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Shared item"
                       customAttributes:@{
                                          @"link":@"forsale listing"
                                          }];
        
        
        NSMutableArray *items = [NSMutableArray new];
        [items addObject:[NSString stringWithFormat:@"For sale on Bump 🏷\n\n'%@'\n\nhttp://sobump.com/p?selling=%@",[self.listingObject objectForKey:@"itemTitle" ],self.listingObject.objectId]];
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
                                          @"link":@"forsale listing"
                                          }];
        
        NSString *urlString = [NSString stringWithFormat:@"http://sobump.com/p?selling=%@",self.listingObject.objectId];
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
    
    [self presentViewController:actionSheet animated:YES completion:nil];
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

-(void)buyButtonPressed{
    self.anyButtonPressed = YES;
    [self.buyButton setEnabled:NO];
    
    CheckoutSummary *vc = [[CheckoutSummary alloc]init];
    vc.listingObject = self.listingObject;
    
//    if (![[PFUser currentUser]objectForKey:@"address"]) {
//        vc.addAddress = YES;
//    }
    
    self.anyButtonPressed = YES;
    vc.delegate = self;

    if (self.tabBarController.tabBar.frame.size.height == 0) {
        [self hideBarButton];
    }
    
    vc.salePrice = self.purchasePrice;
    vc.currencySymbol = self.currencySymbol;
    
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self.navigationController presentViewController:nav animated:YES completion:^{
        [self.buyButton setEnabled:YES];
    }];

}

-(void)longSendButtonPressed{
    self.anyButtonPressed = YES;
    [self.longSendButton setEnabled:NO];
    
    //either send message or dismiss
    if ([self.longSendButton.titleLabel.text isEqualToString:@"D I S M I S S"]) {
        [Answers logCustomEventWithName:@"Dismissed Send Box"
                       customAttributes:@{
                                          @"where":@"for sale"
                                          }];
        [self hideSendBox];
        [self.longSendButton setEnabled:YES];
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
        [self.longSendButton setEnabled:YES];
    }
    
}

-(void)messageBarButtonPressed{
    [self.messageButton setEnabled:NO];
    
    self.anyButtonPressed = YES;
    
    if (![self.seller.objectId isEqualToString:[PFUser currentUser].objectId]) {
        [self showHUDForCopy:NO];
        [self setupMessages];
    }
    else{
        [self hideBarButton];
        
        CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
        vc.editMode = YES;
        vc.listing = self.listingObject;
        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:^{
            [self.messageButton setEnabled:YES];
        }];
        
    }
}
-(void)setupMessages{
    
    NSString *descr;

    if (![self.listingObject objectForKey:@"itemTitle"]) {
        descr = [self.listingObject objectForKey:@"description"];
        
        if (descr.length > 25) {
            descr = [descr substringToIndex:25];
            descr = [NSString stringWithFormat:@"%@..", descr];
        }
    }

    PFQuery *convoQuery = [PFQuery queryWithClassName:@"convos"];
    [convoQuery whereKey:@"sellerUser" equalTo:[self.listingObject objectForKey:@"sellerUser"]];
    [convoQuery whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
    [convoQuery whereKey:@"convoId" equalTo: [NSString stringWithFormat:@"%@%@%@",[[self.listingObject objectForKey:@"sellerUser"]objectId],[PFUser currentUser].objectId, self.listingObject.objectId]];
    [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //convo exists, goto that one but pretype a message like "I'm interested in your Supreme bogo" etc.
            MessageViewController *vc = [[MessageViewController alloc]init];
            vc.convoId = [object objectForKey:@"convoId"];
            vc.convoObject = object;
            vc.listing = self.listingObject;
            vc.otherUser = self.seller;
            vc.otherUserName = @""; //self.seller.username messages VC will load this even if its not given it
            
            //only prefill messages with 'is this available' if the item is available
            if ([[self.listingObject objectForKey:@"status"]isEqualToString:@"live"]) {
                vc.messageSellerPressed = YES;
            }
            
            if (![self.listingObject objectForKey:@"itemTitle"]) {
                vc.sellerItemTitle = descr;
            }
            else{
                vc.sellerItemTitle = [self.listingObject objectForKey:@"itemTitle"];
            }
            vc.userIsBuyer = YES;
            
            if ([self.source isEqualToString:@"latest"]) {
                vc.fromLatest = YES;
            }
            
            vc.pureWTS = YES;

            [self hideHUD];
            [self.messageButton setEnabled:YES];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            
            if (!self.fetchedUser) {
                NSLog(@"no username fetched yet");
                [Answers logCustomEventWithName:@"Message tapped before seller fetched"
                               customAttributes:@{}];
                [self hideHUD];
                [self.messageButton setEnabled:YES];
                
                return;
            }
            
            //create a new convo and goto it
            PFObject *convoObject = [PFObject objectWithClassName:@"convos"];
            convoObject[@"buyerUser"] = [PFUser currentUser];
            convoObject[@"sellerUser"] = [self.listingObject objectForKey:@"sellerUser"];
            convoObject[@"wtsListing"] = self.listingObject;
            convoObject[@"pureWTS"] = @"YES";
            convoObject[@"convoId"] = [NSString stringWithFormat:@"%@%@%@",[[self.listingObject objectForKey:@"sellerUser"]objectId],[PFUser currentUser].objectId, self.listingObject.objectId];
            
            if (self.source) {
                convoObject[@"source"] = self.source; //where did the convo originate from
            }
            
            convoObject[@"totalMessages"] = @0;
            convoObject[@"buyerUnseen"] = @0;
            convoObject[@"sellerUnseen"] = @0;
            convoObject[@"profileConvo"] = @"NO";
            [convoObject setObject:@"NO" forKey:@"buyerDeleted"];
            [convoObject setObject:@"NO" forKey:@"sellerDeleted"];

            //save additional stuff onto convo object for faster inbox loading
            if ([self.listingObject objectForKey:@"thumbnail"]) {
                convoObject[@"thumbnail"] = [self.listingObject objectForKey:@"thumbnail"];
            }
            
            convoObject[@"sellerUsername"] = self.seller.username;
            convoObject[@"sellerId"] = self.seller.objectId;

            if ([self.seller objectForKey:@"picture"]) {
                convoObject[@"sellerPicture"] = [self.seller objectForKey:@"picture"];
                NSLog(@"set seller picture");
            }

            convoObject[@"buyerUsername"] = [PFUser currentUser].username;
            convoObject[@"buyerId"] = [PFUser currentUser].objectId;

            if ([[PFUser currentUser] objectForKey:@"picture"]) {
                convoObject[@"buyerPicture"] = [[PFUser currentUser] objectForKey:@"picture"];
            }

            [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    //saved
                    MessageViewController *vc = [[MessageViewController alloc]init];
                    vc.convoId = [convoObject objectForKey:@"convoId"];
                    vc.convoObject = convoObject;
                    vc.otherUser = self.seller;
                    vc.otherUserName = self.seller.username;
                    vc.messageSellerPressed = YES;
                    if (![self.listingObject objectForKey:@"itemTitle"]) {
                        vc.sellerItemTitle = descr;
                    }
                    else{
                        vc.sellerItemTitle = [self.listingObject objectForKey:@"itemTitle"];
                    }
                    vc.userIsBuyer = YES;
                    vc.listing = self.listingObject;
                    vc.pureWTS = YES;
                    if ([self.source isEqualToString:@"latest"]) {
                        vc.fromLatest = YES;
                    }
                    
                    [self hideHUD];
                    [self.messageButton setEnabled:YES];
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else{
                    NSLog(@"error saving convo");
                    [self.messageButton setEnabled:YES];
                    [self hideHUD];
                }
            }];
        }
    }];
}
- (IBAction)trustedSellerPressed:(id)sender {
    [Answers logCustomEventWithName:@"User tapped"
                   customAttributes:@{
                                      @"where":@"For Sale listing"
                                      }];
    UserProfileController *vc = [[UserProfileController alloc]init];
    vc.user = self.seller;
    vc.saleMode = YES;
    [self.navigationController pushViewController:vc animated:YES];
}
-(void)dismissVC{
    [self.delegate dismissForSaleListing];
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)hideBarButton{
    NSLog(@"HIDE BAR BUTTON");
    self.buttonsShowing = NO;

    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.messageButton setAlpha:0.0];
                         [self.buyButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)showBarButton{
    NSLog(@"SHOW BAR BUTTON");
    self.buttonsShowing = YES;

    self.messageButton.alpha = 0.0f;
    self.buyButton.alpha = 0.0;
    
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.messageButton.alpha = 1.0f;
                         self.buyButton.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)showSendButton{
    self.sendButtonShowing = YES;
    self.longSendButton.alpha = 0.0f;
    
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.longSendButton.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)hideSendButton{
    self.sendButtonShowing = NO;

    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longSendButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{

    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if (self.fromCreate != YES) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else{
            [self dismissVC];
        }
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showNormalAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    [self hideBarButton];
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self showBarButton];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)decideButtonSetup{
    
    if ([self.seller.objectId isEqualToString:[PFUser currentUser].objectId] || [[self.listingObject objectForKey:@"status"]isEqualToString:@"sold"]) {
        [self setupMessageBarButton];
    }
    else{
        //check if instant buy is on & if countries are the same - if not, is global shipping enabled to show both anyway
        if ([[self.listingObject objectForKey:@"instantBuy"] isEqualToString:@"YES"]) {
            
            if ([self.listingObject objectForKey:@"countryCode"] && ([[PFUser currentUser]objectForKey:@"countryCode"] || [[self.listingObject objectForKey:@"globalShipping"]isEqualToString:@"YES"])) {
                
                //we compare country codes to decide on whether purchase is possible
                NSString *listingCountry = [self.listingObject objectForKey:@"countryCode"];
                NSString *userCountry = [[PFUser currentUser]objectForKey:@"countryCode"];
                
                //check if countries are the same
                if ([listingCountry isEqualToString:userCountry]) {
                    //same so show both
                    [self setupTwoBarButtons];
                }
                else if ([[self.listingObject objectForKey:@"globalShipping"]isEqualToString:@"YES"]){
                    [self setupTwoBarButtons];
                }
                else{
                    [self setupMessageBarButton];
                }
            }
            else{
                if (![[PFUser currentUser]objectForKey:@"countryCode"]) {
                    //show prompt to get user's country if this fails
                    [self showAddCountryPrompt];
                }
            }
        }
        else{
            [self setupMessageBarButton];
        }
    }
    
    self.setupButtons = YES;
}

-(void)setupMessageBarButton{
    self.messageButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(50 +self.tabBarHeightInt), [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
    [self.messageButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:12]];
    [self.messageButton setTitle:@"M E S S A G E" forState:UIControlStateNormal];
    [self.messageButton setBackgroundColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0]];
    [self.messageButton addTarget:self action:@selector(messageBarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.messageButton.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:self.messageButton];
}
-(void)setupSendBarButton{
    self.longSendButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(50 +self.tabBarHeightInt), [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
    [self.longSendButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:12]];
    [self.longSendButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
    [self.longSendButton addTarget:self action:@selector(longSendButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.longSendButton.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:self.longSendButton];
}

-(void)setupTwoBarButtons{
    self.buyButtonShowing = YES;
    
    //setup message button
    self.messageButton = [[UIButton alloc]initWithFrame:CGRectMake([UIApplication sharedApplication].keyWindow.frame.size.width/2, [UIApplication sharedApplication].keyWindow.frame.size.height-(50 +self.tabBarHeightInt), [UIApplication sharedApplication].keyWindow.frame.size.width/2, 50)];
    [self.messageButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:12]];
    [self.messageButton setBackgroundColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0]];
    [self.messageButton setTitle:@"M E S S A G E" forState:UIControlStateNormal];
    [self.messageButton addTarget:self action:@selector(messageBarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.messageButton.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:self.messageButton];
    
    //setup buy button
    self.buyButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(50 +self.tabBarHeightInt), [UIApplication sharedApplication].keyWindow.frame.size.width/2, 50)];
    [self.buyButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:12]];
    [self.buyButton setTitle:@"B U Y" forState:UIControlStateNormal];
    [self.buyButton setBackgroundColor:[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]];
    [self.buyButton addTarget:self action:@selector(buyButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.buyButton.alpha = 0.0f;
    
    //title is set when listing fetched for price
    [self.buyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.buyButton];
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
    
    [self hideSendButton];
    
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
    
        //if user selects another friend instead of the friend currently selected
        else if (self.selectedFriend == YES && self.friendIndexSelected != indexPath.row){
            
            //update the selected friend
            self.friendIndexSelected = (int)indexPath.row;
            
            //refresh
            [self.sendBox.collectionView reloadData];
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
            [self.longSendButton setTitle:@"Send" forState:UIControlStateNormal];
            [self.longSendButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
            [self.longSendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{

    SendToUserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.userImageView.image = nil;
    
    NSLog(@"fb users");
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
    NSLog(@"load fb friends");
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
                            [self.longSendButton setFrame: CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(50 + keyboardFrame.size.height), [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
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
                            [self.longSendButton setFrame: CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(50+self.tabBarHeightInt), [UIApplication sharedApplication].keyWindow.frame.size.width, 50)];
                        }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)ShowInitialSendBox{
    NSLog(@"SHOW INITIAL");
    
    if (!self.longSendButton) {
        [self setupSendBarButton];
    }
    
    [self showSendButton];
    
    if ([[PFUser currentUser]objectForKey:@"facebookId"] && self.facebookUsers.count > 0) {
        [self.sendBox.smallInviteButton setHidden:NO];
    }
    else if ([[PFUser currentUser]objectForKey:@"facebookId"] && self.facebookUsers.count == 0){
        [self.sendBox.smallInviteButton setHidden:YES];
    }
    else{
        [self.sendBox.smallInviteButton setHidden:YES];
        [self.sendBox.noFriendsButton setTitle:@"Connect your Facebook to share listings with Friends on Bump!" forState:UIControlStateNormal];
        [self.sendBox.noFriendsButton setHidden:NO];
        [self.sendBox.noFriendsButton addTarget:self action:@selector(connectFacebookPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    
    //update bar button title
    [self.longSendButton setTitle:@"D I S M I S S" forState:UIControlStateNormal];
    [self.longSendButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
    [self.longSendButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];
    
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
    if (![[PFUser currentUser]objectForKey:@"facebookId"]) {
        return;
    }
    
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
                NSLog(@"not the same so add to recent array");
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
            PFFile *imageFile = [self.listingObject objectForKey:@"thumbnail"]; //was image1
            
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
                    boilerObject[@"message"] = [NSString stringWithFormat:@"%@ shared %@'s for sale item.\nTap to view", [PFUser currentUser].username, [[self.listingObject objectForKey:@"sellerUser"]username]];
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
                            NSString *pushString = [NSString stringWithFormat:@"%@ shared a for sale item with you 📲",[[PFUser currentUser]username]];
                            
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
                    PFFile *imageFile = [self.listingObject objectForKey:@"thumbnail"]; //was image1
                    
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
                            boilerObject[@"message"] = [NSString stringWithFormat:@"%@ shared %@'s for sale item.\nTap to view", [PFUser currentUser].username, [[self.listingObject objectForKey:@"sellerUser"]username]];
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
                            
                            NSString *pushString = [NSString stringWithFormat:@"%@ shared a for sale item with you 📲",[[PFUser currentUser]username]];
                            
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
- (IBAction)multiplePressed:(id)sender {
    
    SelectViewController *vc = [[SelectViewController alloc]init];
    vc.viewingMode = YES;
    vc.viewingArray = [self.listingObject objectForKey:@"multipleSizes"];
    [self.navigationController pushViewController:vc animated:YES];
    
    
//    [self showMultipleALert];
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
    
    for (id sizeString in sizes) {
        
        NSString *string = [NSString stringWithFormat:@"%@", sizeString];
        
        if ([displayString isEqualToString:@""]) {
            displayString = string;
        }
        else{
            displayString = [NSString stringWithFormat:@"%@\n%@",displayString,string];
        }
    }
    
    if ([[self.listingObject objectForKey:@"category"]isEqualToString:@"Footwear"]) {
        self.customAlert.titleLabel.text = @"Available UK Sizes";
    }
    else{
        self.customAlert.titleLabel.text = @"Available Sizes";
    }
    
    self.customAlert.messageLabel.text = [NSString stringWithFormat:@"%@", displayString];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, -157, 250, 157)];
    }
    else{
        [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, -220, 300, 250)]; //iPhone 6/7 specific
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
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, 100, 300, 250)]; //iPhone 6/7 specific
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
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, 1000, 300, 250)]; //iPhone 6/7 specific
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
    self.dropShowing = YES;
    [Answers logCustomEventWithName:@"Screenshot taken"
                   customAttributes:@{
                                      @"where":@"For sale"
                                      }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"screenshotDropDown" object:[self.listingObject objectForKey:@"image1"]];
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
    NSString *shareString = @"Check out Bump on the App Store - Safely Buy & Sell Streetwear\n\nAvailable here: http://sobump.com";
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
    [items addObject:@"Check out Bump on the App Store - Safely Buy & Sell Streetwear\n\nAvailable here: http://sobump.com"];
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
        
        NSLog(@"shuffle");
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

-(void)showHideLowerButtons:(NSNotification*)note {
    NSLog(@"switching");
    
    self.anyButtonPressed = YES;

    UIViewController *viewController = [note object];
    if ([viewController isKindOfClass:[NavigationController class]]) {
        
        NavigationController *vc = (NavigationController *)viewController;
        
        if ([vc.visibleViewController isKindOfClass:[PurchaseTab class]]){
            [self showBarButton];
            if (self.sendButtonShowing) {
                [self showSendButton];
            }
        }
        else{
            [self hideBarButton];
            
            if (self.sendButtonShowing) {
                [self hideSendButton];
            }
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
-(void)dismissedDetailImageViewWithIndex:(NSInteger)lastSelected{
    if (self.tabBarController.tabBar.frame.size.height == 0) {
        [self showBarButton];
    }

    [self.carouselView scrollToItemAtIndex:lastSelected animated:NO];
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

-(NSMutableAttributedString *)modifyString: (NSMutableAttributedString *)mainString setFontForText:(NSString*) textToFind
{
    NSRange range = [mainString.mutableString rangeOfString:textToFind options:NSCaseInsensitiveSearch];
    
    if (range.location != NSNotFound) {
        [mainString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFangSC-Medium" size:13] range:range];
    }
    
    return mainString;
}

#pragma bumping logic
- (IBAction)upVotePressed:(id)sender {
    if (self.fetchedListing != YES) {
        [Answers logCustomEventWithName:@"Like tapped before item fetched"
                       customAttributes:@{}];
        
        [self showNormalAlertWithTitle:@"Hang on!" andMsg:@"Make sure your connection is up to scratch! Try liking again in a minute"];
        
        return;
    }
    
    [Answers logCustomEventWithName:@"Bumped a listing"
                   customAttributes:@{
                                      @"where":@"Listing",
                                      @"type": @"WTS"
                                      }];
    
    //bump array is stored on listing and is the ultimate guide
    //personal bump array is used for displaying on profile quickly
    //also save a Bump object whenever there's a bump so we can access dates/users later - no use surely!?!?? just use tracking
    
    //listing's bump array
    NSMutableArray *bumpArray = [NSMutableArray array];
    if ([self.listingObject objectForKey:@"bumpArray"]) {
        [bumpArray addObjectsFromArray:[self.listingObject objectForKey:@"bumpArray"]];
    }
    
    //user's WTS bump array
    NSMutableArray *personalSaleBumpArray = [NSMutableArray array];
    if ([[PFUser currentUser] objectForKey:@"saleBumpArray"]) {
        [personalSaleBumpArray addObjectsFromArray:[[PFUser currentUser] objectForKey:@"saleBumpArray"]];
    }
    
    //user's general bump array (WTB + WTS)
    NSMutableArray *generalBumpedArray = [NSMutableArray array];
    if ([[PFUser currentUser] objectForKey:@"totalBumpArray"]) {
        [generalBumpedArray addObjectsFromArray:[[PFUser currentUser] objectForKey:@"totalBumpArray"]];
    }
    
    //update profile if viewing item from there
    [self.delegate likedItem];
    
    if ([bumpArray containsObject:[PFUser currentUser].objectId]) {
        NSLog(@"already bumped it m8");
        
        [self.upVoteButton setSelected:NO];
        
        [bumpArray removeObject:[PFUser currentUser].objectId];
        
        if (bumpArray.count > 0) {
            [self.upVoteLabel setTitle:@"L I K E S" forState:UIControlStateNormal];
            [self.upVoteLabel setEnabled:YES];
        }
        else{
            [self.upVoteLabel setTitle:@"L I K E" forState:UIControlStateNormal];
            [self.upVoteLabel setEnabled:NO];
        }
        
        [self.listingObject setObject:bumpArray forKey:@"bumpArray"];
        [self.listingObject incrementKey:@"bumpCount" byAmount:@-1];
        
        //update personal array of bumped WTS lisitngs by removing this listing's ID
        if ([personalSaleBumpArray containsObject:self.listingObject.objectId]) {
            [personalSaleBumpArray removeObject:self.listingObject.objectId];
        }
        
        if ([generalBumpedArray containsObject:self.listingObject.objectId]) {
            [generalBumpedArray removeObject:self.listingObject.objectId];
        }
    }
    else{
        NSLog(@"bumped");
        
        //update upvote lower label, allow user to see who else has bumped the listing
        
        [self.upVoteButton setSelected:YES];
        
        //update listing's bump array & bump count
        [bumpArray addObject:[PFUser currentUser].objectId];
        
        if (bumpArray.count > 0) {
            [self.upVoteLabel setTitle:@"L I K E S" forState:UIControlStateNormal];
            [self.upVoteLabel setEnabled:YES];
        }
        else{
            [self.upVoteLabel setTitle:@"L I K E" forState:UIControlStateNormal];
            [self.upVoteLabel setEnabled:NO];
        }
        
        [self.listingObject addObject:[PFUser currentUser].objectId forKey:@"bumpArray"];
        [self.listingObject incrementKey:@"bumpCount"];
        
        //update personal array of bumped WTS lisitngs by adding this listing's ID
        if (![personalSaleBumpArray containsObject:self.listingObject.objectId]) {
            [personalSaleBumpArray addObject:self.listingObject.objectId];
        }
        
        if (![generalBumpedArray containsObject:self.listingObject.objectId]) {
            [generalBumpedArray addObject:self.listingObject.objectId];
        }
        
        //send push to the seller notifying them of the Bump
        NSString *pushText = [NSString stringWithFormat:@"%@ just liked your listing", [PFUser currentUser].username];
        
        if (![self.seller.objectId isEqualToString:[PFUser currentUser].objectId]) {
            
            NSDictionary *params = @{@"userId": [[self.listingObject objectForKey:@"sellerUser"]objectId], @"message": pushText, @"sender": [PFUser currentUser].username, @"bumpValue": @"NO", @"listingID": self.listingObject.objectId};
            
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
    
    //save update personal for sale bumped array and personal total bumped array
    [self.listingObject saveInBackground];
    [[PFUser currentUser]setObject:personalSaleBumpArray forKey:@"saleBumpArray"];
    [[PFUser currentUser]setObject:generalBumpedArray forKey:@"totalBumpArray"];
    [[PFUser currentUser]saveInBackground];

    //update the Bump count on the label
    int count = (int)[bumpArray count];
    if (bumpArray.count > 0) {
        [self.upVoteButton setTitle:[NSString stringWithFormat:@"%@",[self abbreviateNumber:count]] forState:UIControlStateNormal];
    }
    else{
        [self.upVoteButton setTitle:@"" forState:UIControlStateNormal];
    }
}

- (IBAction)viewbumpsPressed:(id)sender {
    if (![self.seller.objectId isEqualToString:[PFUser currentUser].objectId]) {
        [Answers logCustomEventWithName:@"View WTS Bumps"
                       customAttributes:@{
                                          @"own listing":@"NO"
                                          }];
    }
    else{
        [Answers logCustomEventWithName:@"View WTS Bumps"
                       customAttributes:@{
                                          @"own listing":@"YES"
                                          }];
    }
    
    self.anyButtonPressed = YES;
    
    whoBumpedTableView *vc = [[whoBumpedTableView alloc]init];
    vc.bumpArray = [self.listingObject objectForKey:@"bumpArray"];
    [self.navigationController pushViewController:vc animated:YES];
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
                NSLog(@"abbrev");
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
- (IBAction)reportButtonPressed:(id)sender {
    if (self.markAsSoldMode) {
        [self.delegate changedSoldStatus];

        if ([[self.listingObject objectForKey:@"status"]isEqualToString:@"sold"]) {
            //mark as live again
            [Answers logCustomEventWithName:@"Unmark as sold pressed"
                           customAttributes:@{}];
            
            [self.reportButton setSelected:NO];
            [self.reportLabel setTitle:@"M A R K  A S\nS O L D" forState:UIControlStateNormal];

            [self.listingObject setObject:@"live" forKey:@"status"];
            [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    //hide label
                    self.soldLabel.alpha = 1.0;
                    self.soldCheckImageVoew.alpha = 1.0;
                    
                    [UIView animateWithDuration:0.3
                                          delay:0
                                        options:UIViewAnimationOptionCurveEaseIn
                                     animations:^{
                                         self.soldLabel.alpha = 0.0;
                                         self.soldCheckImageVoew.alpha = 0.0;
                                     }
                                     completion:^(BOOL finished) {
                                         [self.soldLabel setHidden:YES];
                                         [self.soldCheckImageVoew setHidden:YES];
                                     }];
                }
            }];
        }
        else{
            //mark as sold
            [Answers logCustomEventWithName:@"Mark as sold pressed"
                           customAttributes:@{}];
            
            [self.reportButton setSelected:YES];
            [self.reportLabel setTitle:@"U N M A R K  A S\nS O L D" forState:UIControlStateNormal];

            [self.listingObject setObject:@"sold" forKey:@"status"];
            [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    //unhide label
                    self.soldLabel.alpha = 0.0;
                    self.soldCheckImageVoew.alpha = 0.0;
                    
                    self.soldLabel.text = @"S O L D";
                    [self.soldCheckImageVoew setImage:[UIImage imageNamed:@"soldCheck"]];
                    
                    [self.soldLabel setHidden:NO];
                    [self.soldCheckImageVoew setHidden:NO];
                    
                    [UIView animateWithDuration:0.3
                                          delay:0
                                        options:UIViewAnimationOptionCurveEaseIn
                                     animations:^{
                                         self.soldLabel.alpha = 1.0;
                                         self.soldCheckImageVoew.alpha = 1.0;
                                         
                                     }
                                     completion:nil];
                }
            }];
        }
        
    }
    else{
        
        [self hideBarButton];
        
        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Report listing" message:@"Why would you like to report this listing?" preferredStyle:UIAlertControllerStyleAlert];
        
        [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self showBarButton];
        }]];
        
        [alertView addAction:[UIAlertAction actionWithTitle:@"Fake" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showBarButton];
            [self selectedReportReason:@"Fake"];
        }]];
        
        [alertView addAction:[UIAlertAction actionWithTitle:@"Offensive" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showBarButton];
            [self selectedReportReason:@"Offensive listing"];
        }]];
        
        [alertView addAction:[UIAlertAction actionWithTitle:@"Spam" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showBarButton];
            [self selectedReportReason:@"Spam"];
        }]];
        
        [alertView addAction:[UIAlertAction actionWithTitle:@"Other" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showBarButton];
            [self selectedReportReason:@"Other"];
        }]];
        
        [self presentViewController:alertView animated:YES completion:nil];
    }
}

-(void)selectedReportReason:(NSString *)reason{
    [Answers logCustomEventWithName:@"Reported Listing"
                   customAttributes:@{
                                      @"type":@"For Sale"
                                      }];
    
    [self.reportLabel setTitle:@"R E P O R T E D" forState:UIControlStateNormal];
    [self.reportButton setEnabled:NO];
    [self.reportLabel setAlpha:0.5];
    
    [self showBarButton];
    
    //send message from team bump saying we're looking into it
    [self sendReportMessageWithReason:reason];
    
    PFObject *reportObject = [PFObject objectWithClassName:@"Reported"];
    reportObject[@"reportedUser"] = self.seller;
    reportObject[@"wtslisting"] = self.listingObject;
    reportObject[@"reporter"] = [PFUser currentUser];
    reportObject[@"reason"] = reason;
    reportObject[@"status"] = @"live"; //CHANGE add this on every reported object created
    [reportObject saveInBackground];
    
    [self.listingObject incrementKey:@"reportedNumber"];
    [self.listingObject saveInBackground];
}
-(void)sendReportMessageWithReason:(NSString *)reason{
    //save message first
    NSString *messageString = @"";
    
    if ([reason isEqualToString:@"Other"]) {
        if ([[PFUser currentUser]objectForKey:@"firstName"]) {
            messageString = [NSString stringWithFormat:@"Hey %@,\n\nThanks for reporting an issue with the following listing: '%@'\n\nMind telling us why you reported the listing?\n\nSophie\nTeam Bump",[[PFUser currentUser]objectForKey:@"firstName"],[self.listingObject objectForKey:@"itemTitle"]];
        }
        else{
            messageString = [NSString stringWithFormat:@"Hey,\n\nThanks for reporting an issue with the following listing: '%@'\n\nMind telling us why you reported the listing?\n\nSophie\nTeam Bump",[self.listingObject objectForKey:@"itemTitle"]];
        }
    }
    else{
        if ([[PFUser currentUser]objectForKey:@"firstName"]) {
            messageString = [NSString stringWithFormat:@"Hey %@,\n\nThanks for reporting an issue with the following listing: '%@'\n\nReason: %@\n\nWe'll get in touch if we have any more questions 👊\n\nSophie\nTeam Bump",[[PFUser currentUser]objectForKey:@"firstName"],[self.listingObject objectForKey:@"itemTitle"],reason];
        }
        else{
            messageString = [NSString stringWithFormat:@"Hey,\n\nThanks for reporting an issue with the following listing: '%@'\n\nReason: %@\n\nWe'll get in touch if we have any more questions 👊\n\nSophie\nTeam Bump",[self.listingObject objectForKey:@"itemTitle"],reason];
        }
    }

    
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
                    
                    [Answers logCustomEventWithName:@"Sent Report Message"
                                   customAttributes:@{
                                                      @"status":@"SENT"
                                                      }];
                }
                else{
                    [Answers logCustomEventWithName:@"Sent Report Message"
                                   customAttributes:@{
                                                      @"status":@"Failed getting convo"
                                                      }];
                }
            }];
        }
        else{
            NSLog(@"error saving report message %@", error);
            [Answers logCustomEventWithName:@"Sent Report Message"
                           customAttributes:@{
                                              @"status":@"Failed saving message"
                                              }];
        }
    }];
}

#pragma mark - bumping intro delegate
-(void)dismissedBumpingIntro{
    [Answers logCustomEventWithName:@"Seen Bumping Intro"
                   customAttributes:@{
                                      @"where":@"for sale"
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
        self.anyButtonPressed = YES;
        [self hideBarButton];
        
        [PFFacebookUtils linkUserInBackground:[PFUser currentUser] withPublishPermissions:@[] block:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                NSLog(@"linked now!");
                [Answers logCustomEventWithName:@"Successfully Linked Facebook Account"
                               customAttributes:@{
                                                  @"where":@"sale listing"
                                                  }];
                
                [self retrieveFacebookData];
            }
            else{
                NSLog(@"not linked! %@", error);
                [self showBarButton];

                if (error) {
                    
                    [Answers logCustomEventWithName:@"Failed to Link Facebook Account"
                                   customAttributes:@{
                                                      @"where":@"sale listing"
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
                 
                 //    //create bumped object so can know when friends create listings
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
                                                           @"pageName":@"Adding FB pic after linking in Sale Listing"
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
                                        initWithGraphPath:@"me/friends"
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

#pragma mark - dismiss checkout
-(void)dismissedCheckout{
    NSLog(@"dismiss delegate");
    [self showBarButton];
}

-(void)PurchasedItemCheckout{
    //refresh buttons
    NSLog(@"purchased in listing");
    self.purchased = YES;
    
    self.buyButton = nil;
    self.messageButton = nil;
//    [self setupMessageBarButton];
    
    //show purchased icon
    self.soldLabel.text = @"P U R C H A S E D";
    [self.soldLabel setHidden:NO];
    
    [self.soldCheckImageVoew setImage:[UIImage imageNamed:@"soldCheck"]];
    [self.soldCheckImageVoew setHidden:NO];
}

-(void)showAddCountryPrompt{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Add Location" message:@"Let us know where you're shopping from so we can show you what items you can instantly buy on BUMP" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Add Location" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Add Location pressed on sale listing"
                       customAttributes:@{}];
        
        LocationView *vc = [[LocationView alloc]init];
        vc.delegate = self;
        [self.navigationController pushViewController:vc animated:YES];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

#pragma mark - location view delegates

-(void)addCurrentLocation:(LocationView *)controller didPress:(PFGeoPoint *)geoPoint title:(NSString *)placemark{
    //do nothing
}

-(void)addLocation:(LocationView *)controller didFinishEnteringItem:(NSString *)item longi:(CLLocationDegrees)item1 lati:(CLLocationDegrees)item2{
    //do nothing
}

-(void)selectedPlacemark:(CLPlacemark *)placemark{
    
    NSString *titleString;
    
    if (!placemark.locality) {
        titleString = [NSString stringWithFormat:@"%@",placemark.country];
    }
    else{
        titleString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
    }
    
    if (![titleString containsString:@"(null)"]) { //protect against saving erroneous location
        
        [[PFUser currentUser]setObject:titleString forKey:@"profileLocation"];
        
        if (![[placemark continent] isEqualToString:@""]) {
            [[PFUser currentUser]setObject:[placemark continent] forKey:@"continent"];
        }
        
        //get geopoint for new location for this user's listings
        PFGeoPoint *geopoint = [PFGeoPoint geoPointWithLocation:placemark.location];
        if (geopoint) {
            [[PFUser currentUser]setObject:geopoint forKey:@"geopoint"];
        }
        
        if (![[placemark country]isEqualToString:@""]) {
            [[PFUser currentUser]setObject:[placemark country] forKey:@"country"];
            [[PFUser currentUser]setObject:[placemark ISOcountryCode] forKey:@"countryCode"];
            
            [self decideButtonSetup];
        }
        
        [[PFUser currentUser]saveInBackground];
    }
    else{
        [self showAlertWithTitle:@"Location Error #1" andMsg:@"We couldn't grab your location, make sure you enter a valid location and are connected to the internet"];
    }
}
@end
