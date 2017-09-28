//
//  CreateTab.m
//  wtbtest
//
//  Created by Jack Ryder on 08/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "CreateTab.h"
#import "CreateForSaleListing.h"
#import "WelcomeViewController.h"
#import <Crashlytics/Crashlytics.h>
#import "CreateViewController.h"
#import "ForSaleCell.h"
#import "ForSaleListing.h"
#import "ListingController.h"
#import "AppDelegate.h"

@interface CreateTab () <simpleCreateVCDelegate, CreateForSaleDelegate>

@end

@implementation CreateTab

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.skipButton setHidden:YES];
    
    self.buyNowArray = [NSArray array];
    self.WTBArray = [NSArray array];
    
    self.bigSellButton.titleLabel.numberOfLines = 0;
    self.bigWantButton.titleLabel.numberOfLines = 0;
    self.bigSellButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.bigWantButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    //open WTB immediately
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wantedPressed:) name:@"openWTB" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sellPressed:) name:@"openSell" object:nil];
    
    //listed an item
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listingStarted) name:@"postingItem" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listingFinished) name:@"justPostedSaleListing" object:nil];
    
    if (self.introMode) {
        self.skipButton.alpha = 0.0;
        [self.skipButton setHidden:NO];
        
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:1.0
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [self.skipButton setAlpha:1.0];
                             }
                             completion:nil];
        });
    }

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
    
    if (![PFUser currentUser]) {
        WelcomeViewController *vc = [[WelcomeViewController alloc]init];
        NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navController animated:YES completion:nil];
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
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Create Listing"
                                      }];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    
    if (self.setupYes != YES) {
        [self setUpSuccess];
    }
    
    if (self.introMode == YES && self.shownPushAlert != YES) {
        //show prompt for enabling push
        [self showPushAlert];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

- (IBAction)wantedPressed:(id)sender {
    [Answers logCustomEventWithName:@"Create listing pressed"
                   customAttributes:@{
                                      @"type":@"wanted"
                                      }];
    
    simpleCreateVC *vc = [[simpleCreateVC alloc]init];
    vc.currency = self.currency;
    vc.currencySymbol = self.currencySymbol;
    vc.delegate = self;
    NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];

    [self presentViewController:navController animated:YES completion:nil];
}
- (IBAction)sellPressed:(id)sender {
    
    if (self.listingInProgress == YES) {
        [Answers logCustomEventWithName:@"Wait for listing save alert shown"
                       customAttributes:@{}];
        
        [self showAlertWithTitle:@"Save in progress" andMsg:@"Once your latest listing is done saving you'll be able to create another listing.\n\nCheck out the progress at the top of the home tab"];
        
        return;
    }
    
    [Answers logCustomEventWithName:@"Create listing pressed"
                   customAttributes:@{
                                      @"type":@"sale"
                                      }];
    
    CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
    vc.delegate = self;
    vc.fromSuccess = YES;
    vc.introMode = self.introMode;
    NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];

    [self presentViewController:navController animated:YES completion:nil];
}

-(void)dismissSimpleCreateVC:(simpleCreateVC *)controller{
    //do nothing
}

-(void)showWantedSuccessForListing:(PFObject *)listing{
    self.justPostedListing = listing;

    //show drop down
    self.sellingSuccessMode = NO;
    [self setupSuccessForWTB];
    
    [self triggerSuccess];
}
#pragma wanted success delegates

#pragma mark - success view methods

-(void)setUpSuccess{
    self.successView = nil;
    self.bgView = nil;
    
    self.completionShowing = YES;
    self.setupYes = YES;
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SuccessView" owner:self options:nil];
    self.successView = (CreateSuccessView *)[nib objectAtIndex:0];
    self.successView.delegate = self;
    self.successView.alpha = 0.0;
    [self.successView setCollectionViewDataSourceDelegate:self indexPath:nil];
    [self.navigationController.view addSubview:self.successView];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -480, 300, 480)];
    }
    else{
        [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-170, -500, 340, 500)]; //iPhone 6/7 specific
    }
    
    self.successView.layer.cornerRadius = 10;
    self.successView.layer.masksToBounds = YES;
    
    self.bgView = [[UIView alloc]initWithFrame:self.view.frame];
    self.bgView.backgroundColor = [UIColor blackColor];
    self.bgView.alpha = 0.0;
    [self.navigationController.view insertSubview:self.bgView belowSubview:self.successView];
    
    //keep the success view neutral until loaded
    self.successView.mainLabel.text = @"";
    [self.successView.blueButton setTitle:@"" forState:UIControlStateNormal];
    
    [self getLatestForSale];
    
//    //find wanted items that match up to this listing
//    PFQuery *wantedQuery = [PFQuery queryWithClassName:@"wantobuys"];
//    [wantedQuery whereKey:@"status" equalTo:@"live"];
//    [wantedQuery orderByDescending:@"lastUpdated,bumpCount"];
//    NSArray *listingKeywords = @[@"supreme", @"box", @"logo"];
//    [wantedQuery whereKey:@"searchKeywords" containsAllObjectsInArray:listingKeywords];
//    wantedQuery.limit = 10;
//    [wantedQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//        if (objects) {
//            self.WTBArray = objects;
//            [self.successView.collectionView reloadData];
//        }
//        else{
//            NSLog(@"error getting relevant wanted items %@", error);
//        }
//    }];
}

-(void)triggerSuccess{
    self.completionShowing = YES;
    self.bgView.alpha = 0.8;
    [self.successView setAlpha:1.0];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.successView setFrame:CGRectMake(0, 0, 300, 480)];
                            }
                            else{
                                [self.successView setFrame:CGRectMake(0, 0, 340, 500)];
                            }
                            self.successView.center = self.view.center;
                        }
                     completion:^(BOOL finished) {
                     }];
}

-(void)hideSuccess{
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-150,1000, 300, 480)];
                            }
                            else{
                                [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-170,1000, 340, 480)]; //iPhone 6/7 specific
                            }
                            [self.bgView setAlpha:0.0];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         self.completionShowing = NO;
                         [self.successView setAlpha:0.0];
                         
                         if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                             //iphone5
                             [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -480, 300, 480)];
                         }
                         else{
                             [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-170, -480, 340, 480)]; //iPhone 6/7 specific
                         }
                         
                         //reset success view appearance
                         self.successView.mainLabel.text = @"";
                         [self.successView.blueButton setTitle:@"" forState:UIControlStateNormal];
                         
                         //dismissVC if in intro mode
                         if (self.introMode && self.createBPressed != YES) {
                             [self skipPressed:self];
                         }
                         else if(self.introMode){
                             self.createBPressed = NO;
                             [self wantedPressed:self];
                         }
                         
                         //load this again for next listing so different items
                         [self getLatestForSale];
                     }];
}

-(void)successDonePressed{
    [Answers logCustomEventWithName:@"Success Done pressed"
                   customAttributes:@{
                                      @"pageName":@"create"
                                      }];
    [self hideSuccess];
    
    if (self.introMode) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshHome" object:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else{
        self.tabBarController.selectedIndex = 0;
    }
}

-(void)createPressed{
    if (self.sellingSuccessMode) {
        [Answers logCustomEventWithName:@"Success Create pressed"
                       customAttributes:@{
                                          @"pageName":@"create"
                                          }];
        [self hideSuccess];
        [self sellPressed:self];
    }
    else{
        [Answers logCustomEventWithName:@"Success Create pressed"
                       customAttributes:@{
                                          @"pageName":@"create"
                                          }];
        if (self.introMode == YES) {
            self.createBPressed = YES;
            [self hideSuccess];
        }
        else{
            [self hideSuccess];
            [self wantedPressed:self];
        }
    }
}

-(void)editPressed{
    
    if (self.sellingSuccessMode) {
        CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
        vc.editMode = YES;
        vc.fromSuccess = YES;
        vc.introMode = self.introMode;
        vc.listing = self.justPostedListing;
        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }
    else{
        [Answers logCustomEventWithName:@"Success Edit pressed"
                       customAttributes:@{
                                          @"pageName":@"create"
                                          }];
        //show edit VC
        CreateViewController *vc = [[CreateViewController alloc]init];
        vc.status = @"edit";
        vc.listing = self.justPostedListing;
        vc.addDetails = YES;
        vc.introMode = self.introMode;
        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

-(void)addMorePressed{
    
    if (self.sellingSuccessMode) {
        CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
        vc.editMode = YES;
        vc.introMode = self.introMode;
        vc.listing = self.justPostedListing;
        vc.fromSuccess = YES;
        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }
    else{
        [Answers logCustomEventWithName:@"Success Add more pressed"
                       customAttributes:@{
                                          @"pageName":@"create"
                                          }];
        //show edit VC
        CreateViewController *vc = [[CreateViewController alloc]init];
        vc.status = @"edit";
        vc.listing = self.justPostedListing;
        vc.addDetails = YES;
        vc.introMode = self.introMode;
        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

-(void)sharePressed{
    //do nothing
}

-(void)boostPressed{
    //do nothing
}

-(void)blueButtonPressed{
    
    if (self.introMode == YES) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshHome" object:nil];
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            appDelegate.tabBarController.selectedIndex = 0;
        }];
    }
    else{
        self.tabBarController.selectedIndex = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshHome" object:nil];
    }
}

-(void)invitePressed{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showInvite" object:nil];
}

#pragma collection view delegates
-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    return self.buyNowArray.count;

//    if (self.sellingSuccessMode) {
//        return self.WTBArray.count;
//    }
//    else{
//        return self.buyNowArray.count;
//    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row == self.buyNowArray.count-1 && self.buyNowArray.count > 1) {
        
        [Answers logCustomEventWithName:@"Tapped 'view more' after creating WTB"
                       customAttributes:@{}];
        
        if (self.introMode == YES) {
            //                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"viewMorePressed"];
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshHome" object:nil];

                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                appDelegate.tabBarController.selectedIndex = 0;
            }];
        }
        else{
            self.tabBarController.selectedIndex = 0;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshHome" object:nil];

            [self successDonePressed];
        }
    }
    else{
        [Answers logCustomEventWithName:@"Tapped for sale listing after creating WTB"
                       customAttributes:@{}];
        
        PFObject *WTS = [self.buyNowArray objectAtIndex:indexPath.item];
        ForSaleListing *vc = [[ForSaleListing alloc]init];
        vc.listingObject = WTS;
        vc.source = @"create";
        vc.pureWTS = YES;
        vc.fromCreate = YES;
        vc.seller = [WTS objectForKey:@"sellerUser"];

        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }
//    
//    if (self.sellingSuccessMode) {
//        //tapping WTBs
//        PFObject *listing = [self.WTBArray objectAtIndex:indexPath.row];
//        
//        ListingController *vc = [[ListingController alloc]init];
//        vc.listingObject = listing;
//        vc.showCancelButton = YES;
//        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
//        
//        [self presentViewController:nav animated:YES completion:nil];
//    }
//    else{
//        if (indexPath.row == self.buyNowArray.count-1 && self.buyNowArray.count > 1) {
//            
//            [Answers logCustomEventWithName:@"Tapped 'view more' after creating WTB"
//                           customAttributes:@{}];
//            
//            if (self.introMode == YES) {
////                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"viewMorePressed"];
//                [self.navigationController dismissViewControllerAnimated:YES completion:^{
//                    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//                    appDelegate.tabBarController.selectedIndex = 0;
//                }];
//            }
//            else{
//                self.tabBarController.selectedIndex = 1;
//                [self successDonePressed];
//            }
//        }
//        else{
//            [Answers logCustomEventWithName:@"Tapped for sale listing after creating WTB"
//                           customAttributes:@{}];
//            
//            PFObject *WTS = [self.buyNowArray objectAtIndex:indexPath.item];
//            ForSaleListing *vc = [[ForSaleListing alloc]init];
//            vc.listingObject = WTS;
//            vc.WTBObject = self.justPostedListing;
//            vc.source = @"create";
//            vc.pureWTS = NO;
//            vc.fromCreate = YES;
//            NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
//            [self presentViewController:nav animated:YES completion:nil];
//        }
//    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ForSaleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.itemView.image = nil;
    
    if (indexPath.row == self.buyNowArray.count-1 && self.buyNowArray.count > 1) {
        [cell.itemView setImage:[UIImage imageNamed:@"viewMore"]];
    }
    else{
        PFObject *WTS = [self.buyNowArray objectAtIndex:indexPath.item];
        //setup cell
        [cell.itemView setFile:[WTS objectForKey:@"thumbnail"]];
        [cell.itemView loadInBackground];
    }
    
//    if (self.sellingSuccessMode) {
//        PFObject *WTB = [self.WTBArray objectAtIndex:indexPath.item];
//        //setup cell
//        [cell.itemView setFile:[WTB objectForKey:@"image1"]];
//        [cell.itemView loadInBackground];
//    }
//    else{
//        if (indexPath.row == self.buyNowArray.count-1 && self.buyNowArray.count > 1) {
//            [cell.itemView setImage:[UIImage imageNamed:@"viewMore"]];
//        }
//        else{
//            PFObject *WTS = [self.buyNowArray objectAtIndex:indexPath.item];
//            //setup cell
//            [cell.itemView setFile:[WTS objectForKey:@"thumbnail"]];
//            [cell.itemView loadInBackground];
//        }
//    }
    
    cell.itemView.layer.cornerRadius = 25;
    cell.itemView.layer.masksToBounds = YES;
    cell.itemView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    cell.itemView.contentMode = UIViewContentModeScaleAspectFill;
    
    return cell;
}

-(void)getLatestForSale{
    PFQuery *pullQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [pullQuery whereKey:@"status" equalTo:@"live"];
    [pullQuery orderByDescending:@"lastUpdated"];
    pullQuery.limit = 10;
    [pullQuery cancel];
    [pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error getting for sale items");
        }
        else{
            self.buyNowArray = objects;
            [self.successView.collectionView reloadData];
        }
    }];
}

-(void)showForSaleSuccessForListing:(PFObject *)listing{
    self.sellingSuccessMode = YES;
    self.justPostedListing = listing;
    self.createdAListing = YES;
    
    [self setupSuccessForSelling];
    [self triggerSuccess];
    
}

-(void)setupSuccessForWTB{
    //make changes to success view for for sale item
    
    //change blue button
    [self.successView.blueButton setTitle:@"Browse latest items for sale" forState:UIControlStateNormal];
    
    //change text label
    self.successView.mainLabel.text = @"Sellers can now search for your wanted ad. Check out what else is for sale on Bump 👊";
    
    //change add details label
    self.successView.addDetailLabel.text = @"A D D  D E T A I L";
}

-(void)setupSuccessForSelling{
    //make changes to success view for for sale item
    
    //change blue button
    [self.successView.blueButton setTitle:@"Browse latest items for sale" forState:UIControlStateNormal];
    
    //change text label
    self.successView.mainLabel.text = @"Buyers on Bump can also create wanted listings. If you're in a hurry to sell, try searching through wanted items 🤑";
    
    //change add details label to 'edit'
    self.successView.addDetailLabel.text = @"E D I T";
}
- (IBAction)skipPressed:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshHome" object:nil];
    
    if (self.createdAListing != YES) {
        //schedule local push reminder
        //local notifications set up
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = 1;
        
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        NSDate *dateToFire = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
        
        // Create new date
        NSDateComponents *components1 = [theCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                       fromDate:dateToFire];
        
        NSDateComponents *components3 = [[NSDateComponents alloc] init];
        
        [components3 setYear:components1.year];
        [components3 setMonth:components1.month];
        [components3 setDay:components1.day];
        [components3 setHour:20];
        
        // Generate a new NSDate from components3.
        NSDate * combinedDate = [theCalendar dateFromComponents:components3];
        
        UILocalNotification *localNotification = [[UILocalNotification alloc]init];
        [localNotification setAlertBody:@"What are you selling? List your first item for sale on BUMP now 🏷"]; //make sure this matches the app delegate local notifications handler method
        [localNotification setFireDate: combinedDate];
        [localNotification setTimeZone: [NSTimeZone defaultTimeZone]];
        [localNotification setRepeatInterval: 0];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - push prompt
-(void)showPushAlert{
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
    self.customAlert = (customAlertViewClass *)[nib objectAtIndex:0];
    self.customAlert.delegate = self;
    self.customAlert.titleLabel.text = @"Enable Push";
    self.customAlert.messageLabel.text = @"Tap to be notified when buyers send you a message on BUMP";
    self.customAlert.numberOfButtons = 2;
    [self.customAlert.secondButton setTitle:@"E N A B L E" forState:UIControlStateNormal];
    
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
                     completion:nil];
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
                         [self.customAlert removeFromSuperview];
                         self.customAlert = nil;
                     }];
}

-(void)firstPressed{
    [Answers logCustomEventWithName:@"Denied Push Permissions"
                   customAttributes:@{
                                      @"username":[PFUser currentUser].username
                                      }];
    [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"declinedPushPermissions"];
    [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"declinedDate"];
    
    [self donePressed];
}

-(void)secondPressed{
    //present push dialog
    [Answers logCustomEventWithName:@"Accepted Push Permissions"
                   customAttributes:@{
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
    
    [self donePressed];
}

-(void)listingStarted{
    self.listingInProgress = YES;
    self.listingDidFail = NO;
}

-(void)listingFinished{
    self.listingInProgress = NO;
    self.listingDidFail = NO;
}

-(void)dismissCreateParent{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshHome" object:nil];

    [self dismissViewControllerAnimated:YES completion:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

@end
