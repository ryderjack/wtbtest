//
//  droppingTodayView.m
//  wtbtest
//
//  Created by Jack Ryder on 22/02/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "droppingTodayView.h"
#import "droppingCell.h"
@implementation droppingTodayView


- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    //setup collectionView
    [self.collectionView.collectionViewLayout invalidateLayout]; //ADDED THIS TO SOLVE BAD ACCESS???
    
    [self.collectionView registerClass:[droppingCell class] forCellWithReuseIdentifier:@"Cell"];
    
    UINib *cellNib = [UINib nibWithNibName:@"droppingCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
//    layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    layout.itemSize = CGSizeMake(80,80);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    [self.collectionView setCollectionViewLayout:layout]; //got a bad access here..//CHECK - added in invalidate layout before reloading - HAVEN'T SEEN SINCE
    self.collectionView.showsHorizontalScrollIndicator = NO;
}

- (void)setCollectionViewDataSourceDelegate:(id<UICollectionViewDataSource, UICollectionViewDelegate>)dataSourceDelegate indexPath:(NSIndexPath *)indexPath
{
    self.collectionView.dataSource = dataSourceDelegate;
    self.collectionView.delegate = dataSourceDelegate;
    
    [self.collectionView.collectionViewLayout invalidateLayout]; //ADDED THIS TO SOLVE BAD ACCESS???
    [self.collectionView reloadData];
}

@end
