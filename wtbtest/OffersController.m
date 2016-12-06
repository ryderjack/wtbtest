//
//  OffersController.m
//  wtbtest
//
//  Created by Jack Ryder on 07/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "OffersController.h"
#import "OrderSummaryController.h"
#import "ListingController.h"

@interface OffersController ()

@end

@implementation OffersController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.noResultsLabel setHidden:YES];
    
    if ([self.mode isEqualToString:@"purchased"]){
        self.navigationItem.title = @"P U R C H A S E D";
    }
    else if ([self.mode isEqualToString:@"sold"]){
        self.navigationItem.title = @"S O L D";
    }
    else if ([self.mode isEqualToString:@"saved"]){
        self.navigationItem.title = @"S A V E D";
    }
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [self.collectionView registerClass:[OfferCell class] forCellWithReuseIdentifier:@"Cell"];
    
    UINib *cellNib = [UINib nibWithNibName:@"OfferCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iPhone5
        [flowLayout setItemSize:CGSizeMake(self.view.frame.size.width-40, 72)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.height == 736){
        //iPhone 6 plus
        [flowLayout setItemSize:CGSizeMake(self.view.frame.size.width-20, 72)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.height == 480){
        //iPhone 4
        [flowLayout setItemSize:CGSizeMake(self.view.frame.size.width-40, 72)];
    }
    else{
        //iPhone 6
        [flowLayout setItemSize:CGSizeMake(self.view.frame.size.width-20, 72)];
    }
    
    [flowLayout setMinimumInteritemSpacing:0.0];
    [flowLayout setMinimumLineSpacing:8.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.alwaysBounceVertical = YES;
    
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
    [cell.imageView setBackgroundColor:[UIColor whiteColor]];
    
    PFObject *orderObject = [self.results objectAtIndex:indexPath.row];
    
    //setup currency
    NSString *currency = [orderObject objectForKey:@"currency"];
    NSString *currencySymbol = @"";
    if ([currency isEqualToString:@"GBP"]) {
        currencySymbol = @"£";
    }
    else{
        currencySymbol = @"$";
    }
    
    if ([self.mode isEqualToString:@"saved"]) {
        //saved items so orderObject is actually a listingOb
        cell.itemTitle.text = [orderObject objectForKey:@"title"];
        [cell.imageView setFile:[orderObject objectForKey:@"image1"]];
        
        NSLog(@"currency %@", currency);
        
        int price = [[orderObject objectForKey:[NSString stringWithFormat:@"listingPrice%@", currency]]intValue];
        cell.priceLabel.text = [NSString stringWithFormat:@"%@%d",currencySymbol,price];
    }
    else{
        //sold or purchased items
        PFObject *confirmedOffer = [orderObject objectForKey:@"offerObject"];
        cell.itemTitle.text = [confirmedOffer objectForKey:@"title"];
        if ([confirmedOffer objectForKey:@"image"]) {
            [cell.imageView setFile:[confirmedOffer objectForKey:@"image"]];
        }
        else{
            cell.imageView.image = nil;
        }
        
        //could do a check here for mode and display different prices if fees intro'd
        cell.priceLabel.text = [NSString stringWithFormat:@"%@%.2f",currencySymbol,[[orderObject objectForKey:@"salePrice"] floatValue]];
    }
    [cell.imageView loadInBackground];
    
    if ([self.mode isEqualToString:@"sold"]) {
        PFUser *buyer = [orderObject objectForKey:@"buyerUser"];
        cell.buyerName.text = [NSString stringWithFormat:@"Buyer: %@", buyer.username];
    }
    else if ([self.mode isEqualToString:@"purchased"]) {
        PFUser *seller = [orderObject objectForKey:@"sellerUser"];
        cell.buyerName.text = [NSString stringWithFormat:@"Seller: %@", seller.username];
    }
    else if ([self.mode isEqualToString:@"saved"]){
        PFUser *buyer = [orderObject objectForKey:@"postUser"];
        cell.buyerName.text = [NSString stringWithFormat:@"Buyer: %@", buyer.username];
    }
    
    // set date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    [dateFormatter setDateFormat:@"dd MMM"];
    NSDate *formattedDate = orderObject.createdAt;
    cell.dateLabel.text = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:formattedDate]];
    dateFormatter = nil;
    
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
    
    if ([self.mode isEqualToString:@"saved"]) {
        
        NSArray *savedItems = [[PFUser currentUser]objectForKey:@"savedItems"];
        PFQuery *listingQuery = [PFQuery queryWithClassName:@"wantobuys"];
        [listingQuery whereKey:@"objectId" containedIn:savedItems];
        [listingQuery orderByDescending:@"createdAt"];
        [listingQuery includeKey:@"postUser"];
        [listingQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                if (objects.count == 0) {
                    [self.noResultsLabel setHidden:NO];
                }
                else{
                    [self.noResultsLabel setHidden:YES];
                }
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
        
        //to prevent showing unconfirmed orders
        [query whereKey:@"status" notEqualTo:@"waiting"];
        
        [query includeKey:@"offerObject"];
        [query orderByDescending:@"createdAt"];
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                if (objects.count == 0) {
                    [self.noResultsLabel setHidden:NO];
                }
                else{
                    [self.noResultsLabel setHidden:YES];
                }
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
    PFObject *selectedOffer = [self.results objectAtIndex:indexPath.item];
    
    if ([self.mode isEqualToString:@"purchased"]){
        //goto order summary
        OrderSummaryController *vc = [[OrderSummaryController alloc]init];
        vc.purchased = YES;
        vc.orderDate = selectedOffer.createdAt;
        vc.orderObject = selectedOffer;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([self.mode isEqualToString:@"sold"]){
        //goto order summary
        OrderSummaryController *vc = [[OrderSummaryController alloc]init];
        vc.purchased = NO;
        vc.orderDate = selectedOffer.createdAt;
        vc.orderObject = selectedOffer;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([self.mode isEqualToString:@"saved"]){
        //goto order summary
        ListingController *vc = [[ListingController alloc]init];
        vc.listingObject = selectedOffer;
        [self.navigationController pushViewController:vc animated:YES];
    }
}
@end
