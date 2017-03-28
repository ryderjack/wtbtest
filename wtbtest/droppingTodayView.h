//
//  droppingTodayView.h
//  wtbtest
//
//  Created by Jack Ryder on 22/02/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFCollectionView.h"

@interface droppingTodayView : UIView
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet AFCollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *shopButton;

- (void)setCollectionViewDataSourceDelegate:(id<UICollectionViewDataSource, UICollectionViewDelegate>)dataSourceDelegate indexPath:(NSIndexPath *)indexPath;

@end
