//
//  FeaturedItems.m
//  wtbtest
//
//  Created by Jack Ryder on 17/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "FeaturedItems.h"
#import "ForSaleListing.h"
#import "NavigationController.h"
#import "ProfileItemCell.h"


@interface FeaturedItems ()

@end

@implementation FeaturedItems

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Featured";
    
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
    
    self.listings = [NSMutableArray array];
    
    [self loadListings];

}

-(void)loadListings{
    PFQuery *featuredQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [featuredQuery whereKey:@"status" equalTo:@"live"];
    [featuredQuery whereKey:@"feature" equalTo:@"YES"];
    [featuredQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            NSLog(@"found %lu featured items", objects.count);
            
            [self.listings removeAllObjects];
            [self.listings addObjectsFromArray:objects];

            PFQuery *forSaleQuery = [PFQuery queryWithClassName:@"forSaleItems"];
            [forSaleQuery whereKey:@"status" equalTo:@"live"];
            [forSaleQuery orderByAscending:@"views"];
            forSaleQuery.limit = 30-self.listings.count;
            [forSaleQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (objects) {
                    for (PFObject *listing in objects) {
                        if (![self.listings containsObject:listing]) {
                            NSLog(@"not already there so add");
                            [self.listings addObject:listing];
                        }
                        else{
                            NSLog(@"listing already featured");
                        }
                    }
                    [self.collectionView reloadData];
                }
                else{
                    NSLog(@"error getting for sale listings %@", error);
                }
            }];
        
        
        }
        else{
            NSLog(@"error getting for sale listings %@", error);
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
    return self.listings.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ProfileItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    [cell.purchasedImageView setHidden:YES];
    cell.itemImageView.image = nil;
    cell.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    PFObject *listingObject = [self.listings objectAtIndex:indexPath.item];
    
    [cell.itemImageView setFile:[listingObject objectForKey:@"image1"]];
    [cell.itemImageView loadInBackground];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    PFObject *selected = [self.listings objectAtIndex:indexPath.item];
    ForSaleListing *vc = [[ForSaleListing alloc]init];
    vc.listingObject = selected;
    vc.source = @"featured";
    vc.pureWTS = YES;
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

@end
