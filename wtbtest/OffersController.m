//
//  OffersController.m
//  wtbtest
//
//  Created by Jack Ryder on 07/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "OffersController.h"
#import "MakeOfferViewController.h"

@interface OffersController ()

@end

@implementation OffersController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self.mode isEqualToString:@"sent"]) {
        self.navigationItem.title = @"Sent offers";
    }
    else if ([self.mode isEqualToString:@"received"]){
        self.navigationItem.title = @"Received offers";
    }
    else if ([self.mode isEqualToString:@"purchased"]){
        self.navigationItem.title = @"Purchased";
    }
    else if ([self.mode isEqualToString:@"sold"]){
        self.navigationItem.title = @"Sold";
    }
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [self.collectionView registerClass:[OfferCell class] forCellWithReuseIdentifier:@"Cell"];
    
    UINib *cellNib = [UINib nibWithNibName:@"OfferCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(self.collectionView.frame.size.width-20, 72)]; //iPhone 6 specific
    //    [flowLayout setItemSize:CGSizeMake((self.collectionView.frame.size.width/2)-40, 300)]; //good for iPhone 5
    [flowLayout setMinimumInteritemSpacing:0.0];
    [flowLayout setMinimumLineSpacing:8.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    self.results = [[NSMutableArray alloc]init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(8, 8, 8, 8); // top, left, bottom, right
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    OfferCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    
    PFObject *offerObject = [self.results objectAtIndex:indexPath.row];
    
    if ([self.mode isEqualToString:@"sent"]) {
        //labels relevant to seller
        if ([[offerObject objectForKey:@"status"]isEqualToString:@"purchased"]) {
            cell.priceLabel.text = @"Sold";
            cell.priceLabel.textColor = [UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1];
        }
        else if ([[offerObject objectForKey:@"status"]isEqualToString:@"declined"]) {
            cell.priceLabel.text = @"Declined";
            cell.priceLabel.textColor = [UIColor colorWithRed:1 green:0.294 blue:0.38 alpha:1];
        }
        else{
            cell.priceLabel.text = [NSString stringWithFormat:@"£%@",[offerObject objectForKey:@"totalCost"]];
            cell.priceLabel.textColor = [UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1];
        }
    }
    else if ([self.mode isEqualToString:@"received"]){
        //labels relevant to buyer
        if ([[offerObject objectForKey:@"status"]isEqualToString:@"purchased"]) {
            cell.priceLabel.text = @"Purchased";
            cell.priceLabel.textColor = [UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1];
        }
        else if ([[offerObject objectForKey:@"status"]isEqualToString:@"declined"]) {
            cell.priceLabel.text = @"Declined";
            cell.priceLabel.textColor = [UIColor colorWithRed:1 green:0.294 blue:0.38 alpha:1];
        }
        else{
            cell.priceLabel.text = [NSString stringWithFormat:@"£%@",[offerObject objectForKey:@"totalCost"]];
            cell.priceLabel.textColor = [UIColor colorWithRed:0.314 green:0.89 blue:0.761 alpha:1];
        }
    }
    else if ([self.mode isEqualToString:@"purchased"]){
        //display total price including fees that buyer pays
        cell.priceLabel.text = [NSString stringWithFormat:@"£%@",[offerObject objectForKey:@"total"]];
    }
    else if ([self.mode isEqualToString:@"sold"]){
        //display just sale price that they'll receieve
        cell.priceLabel.text = [NSString stringWithFormat:@"£%@",[offerObject objectForKey:@"salePrice"]];
    }
    
    if ([self.mode isEqualToString:@"sent"] || [self.mode isEqualToString:@"received"]) {
        cell.itemTitle.text = [offerObject objectForKey:@"title"];
        [cell.imageView setFile:[offerObject objectForKey:@"image1"]];
    }
    else{
        PFObject *confirmedOffer = [offerObject objectForKey:@"offerObject"];
        cell.itemTitle.text = [confirmedOffer objectForKey:@"title"];
        [cell.imageView setFile:[confirmedOffer objectForKey:@"image1"]];
    }
    [cell.imageView loadInBackground];
    
    if ([self.mode isEqualToString:@"sent"] || [self.mode isEqualToString:@"sold"]) {
        PFUser *buyer = [offerObject objectForKey:@"buyerUser"];
        cell.buyerName.text = [NSString stringWithFormat:@"Buyer: %@", buyer.username];
    }
    else{
        PFUser *seller = [offerObject objectForKey:@"sellerUser"];
        cell.buyerName.text = [NSString stringWithFormat:@"Seller: %@", seller.username];
    }
    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.results.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self offerQuery];
}

-(void)offerQuery{
    
    if ([self.mode isEqualToString:@"sent"] || [self.mode isEqualToString:@"received"]) {
        PFQuery *query = [PFQuery queryWithClassName:@"offers"];
        
        if ([self.mode isEqualToString:@"sent"]) {
            [query whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
            [query includeKey:@"buyerUser"];
        }
        else if ([self.mode isEqualToString:@"received"]){
            [query whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
            [query includeKey:@"sellerUser"];
        }
        [query includeKey:@"wtbListing"];
        [query orderByDescending:@"createdAt"];
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                [self.results removeAllObjects];
                [self.results addObjectsFromArray:objects];
                [self.collectionView reloadData];
            }
            else{
                NSLog(@"error %@", error);
            }
        }];
    }
    else{
        //purchased or sold
        PFQuery *query = [PFQuery queryWithClassName:@"orders"];
        
        if ([self.mode isEqualToString:@"sold"]) {
            [query whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
            [query includeKey:@"buyerUser"];
        }
        else if ([self.mode isEqualToString:@"purchased"]){
            [query whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
            [query includeKey:@"sellerUser"];
        }
        [query includeKey:@"offerObject"];
        [query orderByDescending:@"createdAt"];
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                [self.results removeAllObjects];
                [self.results addObjectsFromArray:objects];
                [self.collectionView reloadData];
            }
            else{
                NSLog(@"error %@", error);
            }
        }];
        
    }
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if ([self.mode isEqualToString:@"sent"]) {
    }
    else if ([self.mode isEqualToString:@"received"]){
        PFObject *selectedOffer = [self.results objectAtIndex:indexPath.item];
        if ([[selectedOffer objectForKey:@"status"]isEqualToString:@"purchased"]) {
            //show order summary
        }
        else{
            MakeOfferViewController *vc = [[MakeOfferViewController alloc]init];
            vc.reviewMode = YES;
            vc.listingObject = selectedOffer;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else if ([self.mode isEqualToString:@"purchased"]){
    
    }
}
@end