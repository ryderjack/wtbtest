//
//  CreateSuccessView.m
//  wtbtest
//
//  Created by Jack Ryder on 29/12/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "CreateSuccessView.h"
#import "ForSaleCell.h"

@implementation CreateSuccessView


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    self.backgroundColor = [UIColor clearColor];
    
    self.insideView.layer.cornerRadius = 10;
    
    //setup collectionView
    [self.collectionView registerClass:[ForSaleCell class] forCellWithReuseIdentifier:@"Cell"];
    
    UINib *cellNib = [UINib nibWithNibName:@"ForSaleCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    layout.itemSize = CGSizeMake(70, 70);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    [self.collectionView setCollectionViewLayout:layout];
    self.collectionView.showsHorizontalScrollIndicator = NO;
}

//collection view

- (void)setCollectionViewDataSourceDelegate:(id<UICollectionViewDataSource, UICollectionViewDelegate>)dataSourceDelegate indexPath:(NSIndexPath *)indexPath
{
    self.collectionView.dataSource = dataSourceDelegate;
    self.collectionView.delegate = dataSourceDelegate;
    [self.collectionView reloadData];
}

- (IBAction)doneButtonPressed:(id)sender {
    [self.delegate successDonePressed];
}
- (IBAction)sharePressed:(id)sender {
    [self.delegate sharePressed];
}
- (IBAction)editPressed:(id)sender {
    [self.delegate editPressed];
}
- (IBAction)createPressed:(id)sender {
    [self.delegate createPressed];
}
- (IBAction)addMorePressed:(id)sender {
    [self.delegate addMorePressed];
}

@end
