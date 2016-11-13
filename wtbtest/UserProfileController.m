//
//  UserProfileController.m
//  wtbtest
//
//  Created by Jack Ryder on 26/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "UserProfileController.h"
#import "OfferCell.h"
#import "ListingController.h"
#import <TOWebViewController.h>
#import <SVPullToRefresh/SVPullToRefresh.h>
#import "CreateForSaleListing.h"
#import "NavigationController.h"
#import "ProfileItemCell.h"
#import "ReviewsVC.h"

@interface UserProfileController ()

@end

@implementation UserProfileController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dealsLabel.text = @"Reviews";
    self.numberLabel.text = @"";
    [self.sellerLabel setHidden:YES];
    [self.checkImageView setHidden:YES];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    // Register cell classes
    [self.collectionView registerClass:[ProfileItemCell class] forCellWithReuseIdentifier:@"Cell"];
    UINib *cellNib = [UINib nibWithNibName:@"ProfileItemCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    //calc screen width to avoid hard coding but bug with collection view so width always = 1000
    
    if ([ [ UIScreen mainScreen ] bounds ].size.width == 375) {
        //iPhone6/7
        [flowLayout setItemSize:CGSizeMake(124,124)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.width == 414){
        //iPhone 6 plus
        [flowLayout setItemSize:CGSizeMake(137, 137)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.width == 320){
        //iPhone 4/5
        [flowLayout setItemSize:CGSizeMake(106, 106)];
    }
    else{
        //fall back
        [flowLayout setItemSize:CGSizeMake(124,124)];
    }
    
    [flowLayout setMinimumInteritemSpacing:1.0];
    [flowLayout setMinimumLineSpacing:1.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.alwaysBounceVertical = YES;
    
    self.lisitngsArray = [[NSArray alloc]init];
    self.feedbackArray = [[NSMutableArray alloc]init];
    
    [self.nothingLabel setHidden:YES];
    
    if ([[self.user objectForKey:@"trustedSeller"] isEqualToString:@"YES"]) {
        //trusted seller so load WTSs
        self.isSeller = YES;
        [self.checkImageView setHidden:NO];
        [self.sellerLabel setHidden:NO];
        [self loadWTSListings];
    }
    else{
        self.isSeller = NO;
        [self.checkImageView setHidden:NO]; ///////////////////////////////////////////////////
        [self.sellerLabel setHidden:NO];
        [self loadWTBListings];
    }

    self.headerImgView.layer.cornerRadius = 40;
    self.headerImgView.layer.masksToBounds = YES;
    self.headerImgView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.headerImgView.contentMode = UIViewContentModeScaleAspectFill;
    
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    [self.segmentControl setSelectedSegmentIndex:0];
    
    if (![self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
        //show link to users' FB if not looking at own profile
        UIBarButtonItem *fbButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"FBIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(fbPressed)];
        UIBarButtonItem *extraButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dotsIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(reportUser)];
        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:extraButton, fbButton, nil]];
    }
    else{
        UIBarButtonItem *addForSaleItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addForSalePressed)];
        self.navigationItem.rightBarButtonItem = addForSaleItem;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = [NSString stringWithFormat:@"%@", self.user.username];
    
    PFFile *img = [self.user objectForKey:@"picture"];
    if ( img != nil) {
        [self.headerImgView setFile:[self.user objectForKey:@"picture"]];
        [self.headerImgView loadInBackground];
    }
    else{
        [self.headerImgView setImage:[UIImage imageNamed:@"empty"]];
    }

    PFQuery *dealsQuery = [PFQuery queryWithClassName:@"deals"];
    [dealsQuery whereKey:@"User" equalTo:self.user];
    [dealsQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            int starNumber = [[object objectForKey:@"currentRating"] intValue];
            
            if (starNumber == 0) {
                [self.starImgView setImage:[UIImage imageNamed:@"0star"]];
            }
            else if (starNumber == 1){
                [self.starImgView setImage:[UIImage imageNamed:@"1star"]];
            }
            else if (starNumber == 2){
                [self.starImgView setImage:[UIImage imageNamed:@"2star"]];
            }
            else if (starNumber == 3){
                [self.starImgView setImage:[UIImage imageNamed:@"3star"]];
            }
            else if (starNumber == 4){
                [self.starImgView setImage:[UIImage imageNamed:@"4star"]];
            }
            else if (starNumber == 5){
                [self.starImgView setImage:[UIImage imageNamed:@"5star"]];
            }
            
            int purchased = [[object objectForKey:@"purchased"]intValue];
            int sold = [[object objectForKey:@"sold"] intValue];
            
            int total = purchased+sold;
            
            if (total != 0) {
                self.dealsLabel.text = [NSString stringWithFormat:@"%d Reviews",total];
            }
            else{
                self.dealsLabel.text = @"No reviews";
            }
            
            if (![self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
                // looking at other user's profile
                NSArray *friends = [[PFUser currentUser] objectForKey:@"friends"];
                if ([friends containsObject:[self.user objectForKey:@"facebookId"]]) {
                    if (total != 0) {
                        self.dealsLabel.text = [NSString stringWithFormat:@"%d Reviews\nYou're friends on Facebook", total];
                    }
                    else{
                        self.dealsLabel.text = @"No reviews\nYou're friends on Facebook";
                    }
                }
            }
        }
        else{
            NSLog(@"error getting deals data!");
        }
    }];
    
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
    
    PFQuery *wtbNummber = [PFQuery queryWithClassName:@"wantobuys"];
    [wtbNummber whereKey:@"postUser" equalTo:self.user];
    [wtbNummber whereKey:@"status" notEqualTo:@"deleted"];
    [wtbNummber countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
        if (!error) {
            if (number == 1) {
                [self.segmentControl setTitle:@"1 WTB" forSegmentAtIndex:0];
            }
            else if (number > 0){
                [self.segmentControl setTitle:[NSString stringWithFormat:@"%d WTBs", number] forSegmentAtIndex:0];
            }
        }
        else{
            NSLog(@"count errror %@", error);
        }
    }];
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)loadWTBListings{
    [self.nothingLabel setHidden:YES];
    PFQuery *wtbQuery = [PFQuery queryWithClassName:@"wantobuys"];
    [wtbQuery whereKey:@"postUser" equalTo:self.user];
    [wtbQuery whereKey:@"status" notEqualTo:@"deleted"];
    [wtbQuery orderByDescending:@"createdAt"];
    [wtbQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (objects.count > 0) {
                self.lisitngsArray = objects;
                self.numberLabel.text = [NSString stringWithFormat:@"%lu wanted items", objects.count];
                [self.collectionView reloadData];
            }
            else{
                // no WTBs
                [self.nothingLabel setHidden:NO];
            }
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

-(void)loadWTSListings{
    [self.nothingLabel setHidden:YES];
    PFQuery *wtbQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [wtbQuery whereKey:@"sellerUser" equalTo:self.user];
    [wtbQuery whereKey:@"status" notEqualTo:@"deleted"];
    [wtbQuery orderByDescending:@"createdAt"];
    [wtbQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (objects.count > 0) {
                self.lisitngsArray = objects;
                self.numberLabel.text = [NSString stringWithFormat:@"%lu items for sale", objects.count];
                [self.collectionView reloadData];
            }
            else{
                // no WTBs
                [self.nothingLabel setHidden:NO];
            }
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

-(void)loadFeedback{
    //first query for sales feedback
    [self.nothingLabel setHidden:YES];
    PFQuery *salesQuery = [PFQuery queryWithClassName:@"feedback"];
    [salesQuery whereKey:@"sellerUser" equalTo:self.user];
    [salesQuery whereKey:@"gaveFeedback" notEqualTo:self.user];
    [salesQuery includeKey:@"buyerUser"];
    [salesQuery orderByDescending:@"createdAt"];
    [salesQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            [self.feedbackArray removeAllObjects];
            [self.feedbackArray addObjectsFromArray:objects];
            
            //query for purchase feedback
            PFQuery *purchaseQuery = [PFQuery queryWithClassName:@"feedback"];
            [purchaseQuery whereKey:@"buyerUser" equalTo:self.user];
            [purchaseQuery whereKey:@"gaveFeedback" notEqualTo:self.user];
            [purchaseQuery includeKey:@"sellerUser"];
            [purchaseQuery orderByDescending:@"createdAt"];
            [purchaseQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (!error) {
                    [self.feedbackArray addObjectsFromArray:objects];
                    NSSortDescriptor *sortDescriptor;
                    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                                                 ascending:NO];
                    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    NSArray *sortedArray = [self.feedbackArray sortedArrayUsingDescriptors:sortDescriptors];
                    
                    [self.feedbackArray removeAllObjects];
                    [self.feedbackArray addObjectsFromArray:sortedArray];
                   
                    if (self.feedbackArray.count == 0) {
                        [self.nothingLabel setHidden:NO];
                    }

                    [self.collectionView reloadData];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.lisitngsArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    ProfileItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    [cell.purchasedImageView setHidden:YES];
    cell.itemImageView.image = nil;
    
    PFObject *listingObject = [self.lisitngsArray objectAtIndex:indexPath.row];
    [cell.itemImageView setFile:[listingObject objectForKey:@"image1"]];
    [cell.itemImageView loadInBackground];

    if ([[listingObject objectForKey:@"status"]isEqualToString:@"purchased"]) {
        cell.itemImageView.alpha = 0.5;
        [cell.purchasedImageView setImage:[UIImage imageNamed:@"purchasedIcon"]];
        [cell.purchasedImageView setHidden:NO];
    }
    else if ([[listingObject objectForKey:@"status"]isEqualToString:@"sold"]) {
        cell.itemImageView.alpha = 0.5;
        [cell.purchasedImageView setImage:[UIImage imageNamed:@"soldIcon"]];
        [cell.purchasedImageView setHidden:NO];
    }
    else{
        cell.itemImageView.alpha = 1.0;
        [cell.purchasedImageView setHidden:YES];
    }
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
        if ([PFUser currentUser]==self.user) {
            //allow editing
            [self showAlertViewWithPath:indexPath];
        }
        else{
            //goto listing if its live
            PFObject *selected = [self.lisitngsArray objectAtIndex:indexPath.item];
            if ([[selected objectForKey:@"status"] isEqualToString:@"live"]) {
                ListingController *vc = [[ListingController alloc]init];
                vc.listingObject = selected;
                [self.navigationController pushViewController:vc animated:YES];
            }
        }
}

-(void)showAlertViewWithPath:(NSIndexPath *)indexPath{
    
    PFObject *selected = [self.lisitngsArray objectAtIndex:indexPath.item];
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"View listing" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        ListingController *vc = [[ListingController alloc]init];
        vc.listingObject = selected;
        [self.navigationController pushViewController:vc animated:YES];
    }]];
    
    if ([[selected objectForKey:@"status"] isEqualToString:@"purchased"]) {
//        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Unmark as purchased" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//            [selected setObject:@"live" forKey:@"status"];
//            [selected saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//                if (succeeded) {
//                    [self.collectionView reloadData];
//                }
//            }];
//        }]];
    }
    else{
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Mark as purchased" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Mark as purchased" message:@"Are you sure you want to mark your WTB as purchased? Sellers will no longer be able to view your WTB and offer to sell you items" preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                
            }]];
            [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [selected setObject:@"purchased" forKey:@"status"];
                [selected saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        [self.collectionView reloadData];
                    }
                }];
            }]];
            [self presentViewController:alertView animated:YES completion:nil];
        }]];
        
        if ([[selected objectForKey:@"status"]isEqualToString:@"ended"]) {
           
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Relist WTB" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Relist" message:@"Are you sure you want to relist your WTB?" preferredStyle:UIAlertControllerStyleAlert];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    
                }]];
                [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [selected setObject:@"live" forKey:@"status"];
                    
                    //expiration in 2 weeks
                    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
                    dayComponent.day = 14;
                    NSCalendar *theCalendar = [NSCalendar currentCalendar];
                    NSDate *expirationDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
                    [selected setObject:expirationDate forKey:@"expiration"];
                    
                    [selected saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (succeeded) {
                            [self.collectionView reloadData];
                        }
                    }];
                }]];
                [self presentViewController:alertView animated:YES completion:nil];
            }]];
        }
    }
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Are you sure you want to delete your WTB?" preferredStyle:UIAlertControllerStyleAlert];
        
        [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            
        }]];
        [alertView addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            PFObject *selected = [self.lisitngsArray objectAtIndex:indexPath.item];
            [selected setObject:@"deleted" forKey:@"status"];
            [selected saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    [self.collectionView reloadData];
                }
            }];
        }]];
        
        [self presentViewController:alertView animated:YES completion:nil];
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)fbPressed{
    NSString *URLString = [NSString stringWithFormat:@"https://facebook.com/%@", [self.user objectForKey:@"facebookId"]];
    TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURL:[NSURL URLWithString:URLString]];
    webViewController.title = @"Facebook";
    webViewController.showUrlWhileLoading = YES;
    webViewController.showPageTitles = NO;
    webViewController.doneButtonTitle = @"";
    webViewController.paypalMode = NO;
    webViewController.infoMode = NO;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)reportUser{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Report" message:@"Bump takes inappropriate behaviour very seriously.\nIf you feel like this user has violated our terms let us know so we can make your experience on Bump as brilliant as possible. Call +447590554897 if you'd like to speak to one of the team immediately or message Team Bump from the Profile Tab within the app." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        PFObject *reportObject = [PFObject objectWithClassName:@"ReportedUsers"];
        reportObject[@"reportedUser"] = self.user;
        reportObject[@"reporter"] = [PFUser currentUser];
        [reportObject saveInBackground];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)addForSalePressed{
    CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}
- (IBAction)reviewsPressed:(id)sender {
    NSLog(@"reviews pressed");
    ReviewsVC *vc = [[ReviewsVC alloc]init];
    vc.user = self.user;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
