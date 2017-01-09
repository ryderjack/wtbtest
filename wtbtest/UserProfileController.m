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
#import "ForSaleListing.h"

@interface UserProfileController ()

@end

@implementation UserProfileController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dealsLabel.text = @"";
    self.numberLabel.text = @"";
    [self.sellerSegmentControl setHidden:YES];
    [self.sellerLabel setHidden:YES];
    [self.checkImageView setHidden:YES];
    self.forSalePressed = NO;
    self.WTBPressed = NO;
    
    self.dealsLabel.adjustsFontSizeToFitWidth = YES;
    self.dealsLabel.minimumScaleFactor=0.5;
    
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
    
    self.WTBArray = [[NSArray alloc]init];
    self.forSaleArray = [[NSMutableArray alloc]init];
    
    [self.nothingLabel setHidden:YES];
    
//    NSLog(@"USER %@", self.user);
    
    if (self.fromSearch == YES) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    
//    UIBarButtonItem *addForSaleItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addForSalePressed)];
//    self.navigationItem.rightBarButtonItem = addForSaleItem;

    PFQuery *trustedQuery = [PFQuery queryWithClassName:@"trustedSellers"];
    [trustedQuery whereKey:@"user" equalTo:self.user];
    [trustedQuery countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
        if (number >= 1) {
            self.isSeller = YES;
            [self.checkImageView setHidden:NO];
        }
        else{
            [self.checkImageView setHidden:YES];
        }
        
        if (![self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
            //show link to users' FB if not looking at own profile
            UIBarButtonItem *fbButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"FBIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(fbPressed)];
            UIBarButtonItem *extraButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dotsIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(reportUser)];
            if (self.isSeller == YES) {
                [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:extraButton, nil]];
            }
            else{
                [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:extraButton, fbButton, nil]];
            }
        }
        
        if (self.user == [PFUser currentUser] && self.isSeller == YES) {
            //trusted seller so load WTSs
            [self.sellerSegmentControl setHidden:NO];
            [self loadWTBListings];
            [self loadWTSListings];
            
            UIBarButtonItem *addForSaleItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addForSalePressed)];
            self.navigationItem.rightBarButtonItem = addForSaleItem;
        }
        else if (self.saleMode == YES){
            [self loadWTSListings];
        }
        else{
            [self.sellerSegmentControl setHidden:YES];
            self.isSeller = NO;
            [self loadWTBListings];
        }
    }];

    self.headerImgView.layer.cornerRadius = 40;
    self.headerImgView.layer.masksToBounds = YES;
    self.headerImgView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.headerImgView.contentMode = UIViewContentModeScaleAspectFill;
    
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    [self.sellerSegmentControl setSelectedSegmentIndex:0];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = [NSString stringWithFormat:@"%@", self.user.username];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
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
    
    if (self.forSalePressed == YES) {
        [self.sellerSegmentControl setSelectedSegmentIndex:1];
        [self loadWTSListings];
    }
    if (self.WTBPressed == YES) {
        [self.sellerSegmentControl setSelectedSegmentIndex:0];
        self.WTBPressed = NO;
        [self loadWTBListings];
    }
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
        if (objects) {
            self.WTBArray = objects;
            if (self.isSeller != YES) {
                if (objects.count == 1) {
                    self.numberLabel.text = @"1 wanted item";
                }
                else{
                    self.numberLabel.text = [NSString stringWithFormat:@"%lu wanted items", objects.count];
                }
            }
            else{
                if (objects.count == 1) {
                    [self.sellerSegmentControl setTitle:@"1 Wanted" forSegmentAtIndex:0];
                }
                else{
                    [self.sellerSegmentControl setTitle:[NSString stringWithFormat:@"%lu Wanted", objects.count] forSegmentAtIndex:0];
                }
            }
            [self.collectionView performBatchUpdates:^{
                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            } completion:nil];
        }
        else{
            NSLog(@"error getting WTBs %@", error);
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
                self.forSaleArray = objects;
                [self.sellerSegmentControl setTitle:[NSString stringWithFormat:@"%lu Selling", objects.count] forSegmentAtIndex:1];
                
                if (self.forSalePressed == YES) {
                    [self.collectionView reloadData];
                    self.forSalePressed = NO;
                }
                else if (self.saleMode == YES){
                    [self.collectionView reloadData];
                    if (objects.count == 1) {
                        self.numberLabel.text = @"1 item for sale";
                    }
                    else{
                        self.numberLabel.text = [NSString stringWithFormat:@"%lu items for sale", objects.count];
                    }
                }
            }
            else{
                // no WTSs
            }
        }
        else{
            NSLog(@"error getting WTSs %@", error);
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
    if (self.sellerSegmentControl.selectedSegmentIndex == 1 || self.saleMode) {
        return self.forSaleArray.count;
    }
    else{
        return self.WTBArray.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    ProfileItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    [cell.purchasedImageView setHidden:YES];
    cell.itemImageView.image = nil;
    cell.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    PFObject *listingObject;
    
    if (self.saleMode== YES) {
        listingObject = [self.forSaleArray objectAtIndex:indexPath.row];
    }
    else if (self.sellerSegmentControl.selectedSegmentIndex == 0) {
        listingObject = [self.WTBArray objectAtIndex:indexPath.row];
    }
    else{
        listingObject = [self.forSaleArray objectAtIndex:indexPath.row];
    }
    
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

    PFObject *selected;
    
    if (self.saleMode == YES) {
        selected = [self.forSaleArray objectAtIndex:indexPath.item];
        self.forSalePressed = YES;
        ForSaleListing *vc = [[ForSaleListing alloc]init];
        vc.listingObject = selected;
        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }
    else if (self.sellerSegmentControl.selectedSegmentIndex == 0) {
        selected = [self.WTBArray objectAtIndex:indexPath.item];
        self.WTBPressed = YES;
        ListingController *vc = [[ListingController alloc]init];
        vc.listingObject = selected;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else{
        selected = [self.forSaleArray objectAtIndex:indexPath.item];
        self.forSalePressed = YES;
        ForSaleListing *vc = [[ForSaleListing alloc]init];
        vc.listingObject = selected;
        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

-(void)showAlertViewWithPath:(NSIndexPath *)indexPath{
    
    PFObject *selected;

    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    }]];
    
    if (self.sellerSegmentControl.selectedSegmentIndex == 0) {
        //for WTBs
        
        selected = [self.WTBArray objectAtIndex:indexPath.item];
        
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
                            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                        }
                    }];
                }]];
                [self presentViewController:alertView animated:YES completion:nil];
            }]];
            
//            if ([[selected objectForKey:@"status"]isEqualToString:@"ended"]) {
//                
//                [actionSheet addAction:[UIAlertAction actionWithTitle:@"Relist WTB" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//                    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Relist" message:@"Are you sure you want to relist your WTB?" preferredStyle:UIAlertControllerStyleAlert];
//                    
//                    [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
//                        
//                    }]];
//                    [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//                        [selected setObject:@"live" forKey:@"status"];
//                        
//                        //expiration in 2 weeks
//                        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
//                        dayComponent.day = 14;
//                        NSCalendar *theCalendar = [NSCalendar currentCalendar];
//                        NSDate *expirationDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
//                        [selected setObject:expirationDate forKey:@"expiration"];
//                        
//                        [selected saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//                            if (succeeded) {
//                                [self.collectionView reloadData];
//                            }
//                        }];
//                    }]];
//                    [self presentViewController:alertView animated:YES completion:nil];
//                }]];
//            }
        }
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Are you sure you want to delete your WTB?" preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                
            }]];
            [alertView addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                PFObject *selected = [self.WTBArray objectAtIndex:indexPath.item];
                [selected setObject:@"deleted" forKey:@"status"];
                [selected saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        NSMutableArray *deletedArray = [NSMutableArray arrayWithArray:self.WTBArray];
                        [deletedArray removeObjectAtIndex:indexPath.item];
                        self.WTBArray = deletedArray;
                        [self.collectionView reloadData];
                        if (self.isSeller == YES) {
                            if (self.WTBArray.count == 1) {
                                [self.sellerSegmentControl setTitle:@"1 Wanted" forSegmentAtIndex:0];
                            }
                            else{
                                [self.sellerSegmentControl setTitle:[NSString stringWithFormat:@"%lu Wanted", self.WTBArray.count] forSegmentAtIndex:0];
                            }
                        }
                        else{
                            if (self.WTBArray.count == 1) {
                                self.numberLabel.text = @"1 wanted item";
                            }
                            else{
                                self.numberLabel.text = [NSString stringWithFormat:@"%lu wanted items", self.WTBArray.count];
                            }
                        }
                    }
                }];
            }]];
            
            [self presentViewController:alertView animated:YES completion:nil];
        }]];
    }
    else{
        //for WTSs
        selected = [self.forSaleArray objectAtIndex:indexPath.item];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"View listing" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            ForSaleListing *vc = [[ForSaleListing alloc]init];
            vc.listingObject = selected;
            NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
            [self presentViewController:nav animated:YES completion:nil];
        }]];
        
        if ([[selected objectForKey:@"status"] isEqualToString:@"sold"]) {
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Unmark as sold" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [selected setObject:@"live" forKey:@"status"];
                [selected saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                    }
                }];
            }]];
        }
        else{
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Mark as sold" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
                UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Mark as sold" message:@"Are you sure you want to mark your item as sold? It will no longer be recommended to interested buyers" preferredStyle:UIAlertControllerStyleAlert];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    
                }]];
                [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [selected setObject:@"sold" forKey:@"status"];
                    [selected saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (succeeded) {
                            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                        }
                    }];
                }]];
                [self presentViewController:alertView animated:YES completion:nil];
            }]];
        }
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Are you sure you want to delete your listing?" preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [alertView addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [selected setObject:@"deleted" forKey:@"status"];
                [selected saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        NSMutableArray *deletedArray = [NSMutableArray arrayWithArray:self.forSaleArray];
                        [deletedArray removeObjectAtIndex:indexPath.item];
                        self.forSaleArray = deletedArray;
                        [self.collectionView reloadData];
                        [self.sellerSegmentControl setTitle:[NSString stringWithFormat:@"%lu Selling", self.forSaleArray.count] forSegmentAtIndex:1];
                    }
                }];
            }]];
            
            [self presentViewController:alertView animated:YES completion:nil];
        }]];
    }

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

-(void)SetupListing{
    CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
    vc.usernameToCheck = self.usernameToList;
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    self.forSalePressed = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)addForSalePressed{
    //uncomment when adding items for other users
//    UIAlertController *alertController = [UIAlertController
//                                          alertControllerWithTitle:@"Post as User"
//                                          message:@"Enter username"
//                                          preferredStyle:UIAlertControllerStyleAlert];
//
//    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
//     {
//         textField.placeholder = @"username";
//     }];
//
//    UIAlertAction *okAction = [UIAlertAction
//                               actionWithTitle:@"DONE"
//                               style:UIAlertActionStyleDefault
//                               handler:^(UIAlertAction *action)
//                               {
//                                   UITextField *usernameField = alertController.textFields.firstObject;
//                                   self.usernameToList = usernameField.text;
//                                   [self SetupListing];
//                               }];
//
//    [alertController addAction:okAction];
    
//    [self presentViewController:alertController animated:YES completion:nil];
    
    CreateForSaleListing *vc = [[CreateForSaleListing alloc]init];
    vc.usernameToCheck = self.usernameToList;
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    self.forSalePressed = YES;
    [self presentViewController:nav animated:YES completion:nil];
}
- (IBAction)reviewsPressed:(id)sender {
    ReviewsVC *vc = [[ReviewsVC alloc]init];
    vc.user = self.user;
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)sellerSegmentControlChanged:(id)sender {
    [self.collectionView reloadData];
}

-(void)dismissVC{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
