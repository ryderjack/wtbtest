//
//  OffersController.m
//  wtbtest
//
//  Created by Jack Ryder on 07/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "OffersController.h"

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
    [flowLayout setItemSize:CGSizeMake(320, 72)]; //iPhone 6 specific
    //    [flowLayout setItemSize:CGSizeMake((self.collectionView.frame.size.width/2)-40, 300)]; //good for iPhone 5
    [flowLayout setMinimumInteritemSpacing:0.0];
    [flowLayout setMinimumLineSpacing:1.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor redColor];
    
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
    NSLog(@"offer object %@", offerObject);
    PFObject *listing = [offerObject objectForKey:@"wtbListing"];
    [listing fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            cell.itemTitle.text = [listing objectForKey:@"title"];
            [cell.imageView setFile:[listing objectForKey:@"image1"]];
            [cell.imageView loadInBackground];
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
    PFUser *buyer = [offerObject objectForKey:@"buyerUser"];
    [buyer fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            cell.buyerName.text = [NSString stringWithFormat:@"%@", buyer.username];
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
    
    cell.priceLabel.text = [offerObject objectForKey:@"totalCost"];
    
    
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
    [query whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
    [query includeKey:@"buyerUser"];
    [query includeKey:@"wtbListing"];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            NSLog(@"results %@", objects);
            [self.results addObjectsFromArray:objects];
            NSLog(@"resultsarray %@", self.results);
            [self.collectionView reloadData];
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}
@end
