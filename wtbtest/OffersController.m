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
    
    if (self.sentOffers == YES) {
        self.navigationItem.title = @"Sent offers";
    }
    else{
        self.navigationItem.title = @"Received offers";
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
    cell.priceLabel.text = [NSString stringWithFormat:@"£%@",[offerObject objectForKey:@"totalCost"]];

    PFObject *listing = [offerObject objectForKey:@"wtbListing"];
    cell.itemTitle.text = [listing objectForKey:@"title"];
    [cell.imageView setFile:[offerObject objectForKey:@"image1"]];
    [cell.imageView loadInBackground];
    
    if (self.sentOffers == YES) {
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
    PFQuery *query = [PFQuery queryWithClassName:@"offers"];
    
    if (self.sentOffers == YES) {
        [query whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
        [query includeKey:@"buyerUser"];
    }
    else{
        [query whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
        [query includeKey:@"sellerUser"];
    }
    [query includeKey:@"wtbListing"];
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
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (self.sentOffers == YES) {

    }
    else{
        PFObject *selectedOffer = [self.results objectAtIndex:indexPath.item];
        MakeOfferViewController *vc = [[MakeOfferViewController alloc]init];
        vc.offerMode = YES;
        vc.listingObject = selectedOffer;
        [self.navigationController pushViewController:vc animated:YES];
    }
}
@end
