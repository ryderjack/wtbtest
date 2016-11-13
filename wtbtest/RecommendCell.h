//
//  RecommendCell.h
//  wtbtest
//
//  Created by Jack Ryder on 06/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFCollectionView.h"

@interface RecommendCell : UITableViewCell
@property (weak, nonatomic) IBOutlet AFCollectionView *collectionView;

- (void)setCollectionViewDataSourceDelegate:(id<UICollectionViewDataSource, UICollectionViewDelegate>)dataSourceDelegate indexPath:(NSIndexPath *)indexPath;
@property (weak, nonatomic) IBOutlet UILabel *wtbTitle;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end
