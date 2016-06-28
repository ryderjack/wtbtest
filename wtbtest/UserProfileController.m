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

@interface UserProfileController ()

@end

@implementation UserProfileController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    [self.collectionView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    // Register cell classes
    [self.collectionView registerClass:[OfferCell class] forCellWithReuseIdentifier:@"Cell"];
    
    UINib *cellNib = [UINib nibWithNibName:@"OfferCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iPhone5
        [flowLayout setItemSize:CGSizeMake(self.collectionView.frame.size.width-40, 72)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.height == 736){
        //iPhone 6 plus
        [flowLayout setItemSize:CGSizeMake(self.collectionView.frame.size.width-20, 72)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.height == 480){
        //iPhone 4
        [flowLayout setItemSize:CGSizeMake(self.collectionView.frame.size.width-40, 72)];
    }
    else{
        //iPhone 6
        [flowLayout setItemSize:CGSizeMake(self.collectionView.frame.size.width-20, 72)];
    }
    
    [flowLayout setMinimumInteritemSpacing:0.0];
    [flowLayout setMinimumLineSpacing:8.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.alwaysBounceVertical = YES;
    
    self.lisitngsArray = [[NSArray alloc]init];
    self.feedbackArray = [[NSMutableArray alloc]init];
    
    [self loadListings];
    
    [self setImageBorder:self.headerImgView];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = [NSString stringWithFormat:@"%@", self.user.username];
    
    [self.headerImgView setFile:[self.user objectForKey:@"picture"]];
    [self.headerImgView loadInBackground];
    
    int purchased = [[self.user objectForKey:@"purchased"]intValue];
    int sold = [[self.user objectForKey:@"sold"] intValue];
    
    self.dealsLabel.text = [NSString stringWithFormat:@"Purchased: %d\nSold: %d", purchased, sold];
    
    int starNumber = [[self.user objectForKey:@"currentRating"] intValue];
    
    NSLog(@"star number %@", [self.user objectForKey:@"currentRating"]);
    
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
    
    [self.segmentControl setSelectedSegmentIndex:0];
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)loadListings{
    PFQuery *wtbQuery = [PFQuery queryWithClassName:@"wantobuys"];
    [wtbQuery whereKey:@"postUser" equalTo:self.user];
    [wtbQuery orderByDescending:@"createdAt"];
    [wtbQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (objects) {
                self.lisitngsArray = objects;
                [self.collectionView reloadData];
            }
            else{
                NSLog(@"no listings");
            }
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

-(void)loadFeedback{
    //first query for sales feedback
    
    PFQuery *salesQuery = [PFQuery queryWithClassName:@"feedback"];
    [salesQuery whereKey:@"sellerUser" equalTo:self.user];
    [salesQuery includeKey:@"buyerUser"];
    [salesQuery orderByDescending:@"createdAt"];
    [salesQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            [self.feedbackArray removeAllObjects];
            [self.feedbackArray addObjectsFromArray:objects];
            //query for purchase feedback
            
            PFQuery *purchaseQuery = [PFQuery queryWithClassName:@"feedback"];
            [purchaseQuery whereKey:@"buyerUser" equalTo:self.user];
            [purchaseQuery includeKey:@"sellerUser"];
            [purchaseQuery orderByDescending:@"createdAt"];
            [purchaseQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (!error) {
                    [self.feedbackArray addObjectsFromArray:objects];
                    NSSortDescriptor *sortDescriptor;
                    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                                                 ascending:YES];
                    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    NSArray *sortedArray = [self.feedbackArray sortedArrayUsingDescriptors:sortDescriptors];
                    
                    [self.feedbackArray removeAllObjects];
                    [self.feedbackArray addObjectsFromArray:sortedArray];
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
    // Dispose of any resources that can be recreated.
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.segmentControl.selectedSegmentIndex == 0) {
        return self.lisitngsArray.count;
    }
    else{
        return self.feedbackArray.count;
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(8, 8, 8, 8); // top, left, bottom, right
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    OfferCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    
    [self setImageBorder:cell.imageView];
    
    if (self.segmentControl.selectedSegmentIndex == 0) {
        PFObject *listingObject = [self.lisitngsArray objectAtIndex:indexPath.row];
        [cell.imageView setFile:[listingObject objectForKey:@"image1"]];
        [cell.imageView loadInBackground];
        
        cell.itemTitle.text = [NSString stringWithFormat:@"%@", [listingObject objectForKey:@"title"]];
        if ([[listingObject objectForKey:@"condition"] isEqualToString:@"Any"]) {
            cell.buyerName.text = @"Any condition";
        }
        else{
            cell.buyerName.text = [NSString stringWithFormat:@"%@", [listingObject objectForKey:@"condition"]];
        }
        
        cell.priceLabel.text = [NSString stringWithFormat:@"£%@", [listingObject objectForKey:@"listingPrice"]];
        
        // set date
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setDateFormat:@"dd MMM"];
        
        NSDate *formattedDate = listingObject.createdAt;
        cell.dateLabel.text = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:formattedDate]];
        dateFormatter = nil;
    }
    else{
        PFObject *feedbackObject = [self.feedbackArray objectAtIndex:indexPath.row];
        if ([feedbackObject objectForKey:@"sellerUser"]==[PFUser currentUser]) {
            NSLog(@"current user was seller");
            cell.buyerName.text = @"Sale";
            PFUser *buyer = [feedbackObject objectForKey:@"buyerUser"];
            [buyer fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                [cell.imageView setFile:[buyer objectForKey:@"picture"]];
                [cell.imageView loadInBackground];
            }];
        }
        else{
            NSLog(@"current user was buyer");
            cell.buyerName.text = @"Purchase";
            PFUser *seller = [feedbackObject objectForKey:@"sellerUser"];
            [seller fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                [cell.imageView setFile:[seller objectForKey:@"picture"]];
                [cell.imageView loadInBackground];
            }];
        }
        
        cell.itemTitle.text = [NSString stringWithFormat:@"%@", [feedbackObject objectForKey:@"comment"]];

        
        cell.priceLabel.text = [NSString stringWithFormat:@"%@ stars", [feedbackObject objectForKey:@"rating"]];
        
        // set date
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setDateFormat:@"dd MMM"];
        
        NSDate *formattedDate = feedbackObject.createdAt;
        cell.dateLabel.text = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:formattedDate]];
        dateFormatter = nil;
    }
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    PFObject *selected = [self.lisitngsArray objectAtIndex:indexPath.item];
    ListingController *vc = [[ListingController alloc]init];
    vc.listingObject = selected;
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)segmentControlChanged:(id)sender {
    if (self.segmentControl.selectedSegmentIndex == 0) {
        [self loadListings];
    }
    else{
        [self loadFeedback];
    }
}

@end