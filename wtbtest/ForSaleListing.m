//
//  ForSaleListing.m
//  wtbtest
//
//  Created by Jack Ryder on 04/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ForSaleListing.h"
#import <DGActivityIndicatorView.h>
#import "DetailImageController.h"
#import "MessageViewController.h"
#import "UserProfileController.h"
#import "CreateForSaleListing.h"
#import <Crashlytics/Crashlytics.h>
#import "NavigationController.h"

@interface ForSaleListing ()

@end

@implementation ForSaleListing

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItem = cancelButton;
    
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
    
    self.descriptionLabel.adjustsFontSizeToFitWidth = YES;
    self.descriptionLabel.minimumScaleFactor=0.5;
    
    self.descriptionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.spaceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.infoCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    //carousel setup
    self.carouselView.type = iCarouselTypeLinear;
    self.carouselView.delegate = self;
    self.carouselView.dataSource = self;
    self.carouselView.pagingEnabled = YES;
    self.carouselView.bounceDistance = 0.3;
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
    [self presentViewController:vc animated:YES completion:nil];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController.navigationBar setHidden:NO];

    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if (self.buttonShowing == NO) {
        NSLog(@"SHOW BAR BUTTON");
        if (!self.longButton) {
            [self setupBarButton];
        }
        [self showBarButton];
    }
    
    [self.listingObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (!error) {
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
                    self.firstImage = [self.listingObject objectForKey:@"image1"];
                    self.secondImage = [self.listingObject objectForKey:@"image2"];
                    self.thirdImage = [self.listingObject objectForKey:@"image3"];
                    self.fourthImage = [self.listingObject objectForKey:@"image4"];

                }
                else if ([self.listingObject objectForKey:@"image3"]){
                    [self.pageIndicator setNumberOfPages:3];
                    self.numberOfPics = 3;
                    self.firstImage = [self.listingObject objectForKey:@"image1"];
                    self.secondImage = [self.listingObject objectForKey:@"image2"];
                    self.thirdImage = [self.listingObject objectForKey:@"image3"];
                    
                }
                else if ([self.listingObject objectForKey:@"image2"]) {
                    [self.pageIndicator setNumberOfPages:2];
                    self.numberOfPics = 2;
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
                self.sizeLabel.text = [self.listingObject objectForKey:@"location"];
                
                if ([[self.listingObject objectForKey:@"category"]isEqualToString:@"Accessories"]) {
                    self.locationLabel.text = @"-";
                }
                else if (![self.listingObject objectForKey:@"sizeGender"]) {
                    self.locationLabel.text = [NSString stringWithFormat:@"%@", [self.listingObject objectForKey:@"sizeLabel"]];
                }
                else{
                    self.locationLabel.text = [NSString stringWithFormat:@"%@, %@",[self.listingObject objectForKey:@"sizeGender"], [self.listingObject objectForKey:@"sizeLabel"]];
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
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
    
    if ([self.seller.objectId isEqualToString:[PFUser currentUser].objectId]) {
        
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
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                }];
            }]];
            
            [self presentViewController:alertView animated:YES completion:nil];
        }]];
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
                reportObject[@"reportedUser"] = self.seller;
                reportObject[@"reporter"] = [PFUser currentUser];
                reportObject[@"wtslisting"] = self.listingObject;
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
    if (![self.seller.objectId isEqualToString:[PFUser currentUser].objectId]) {
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
            
            if (self.pureWTS == YES) {
                vc.pureWTS = YES;
            }
            else{
                vc.listing = self.WTBObject;
            }
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
                    if (self.pureWTS == YES) {
                        vc.pureWTS = YES;
                    }
                    else{
                        vc.listing = self.WTBObject;
                    }
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
                     }
                     completion:^(BOOL finished) {
                         self.buttonShowing = YES;
                     }];
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)setupBarButton{
    self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(60 + self.tabBarController.tabBar.frame.size.height), [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
    [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
    [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
    [self.longButton addTarget:self action:@selector(BarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.longButton.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
}
@end
