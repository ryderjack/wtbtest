//
//  CreateSuccessView.h
//  wtbtest
//
//  Created by Jack Ryder on 29/12/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFCollectionView.h"

@class CreateSuccessView;
@protocol successDelegate <NSObject>
- (void)editPressed;
- (void)createPressed;
- (void)sharePressed;
- (void)donePressed;
@end

@interface CreateSuccessView : UIView

@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UIView *insideView;
@property (weak, nonatomic) IBOutlet AFCollectionView *collectionView;
@property (nonatomic, weak) id <successDelegate> delegate;

- (void)setCollectionViewDataSourceDelegate:(id<UICollectionViewDataSource, UICollectionViewDelegate>)dataSourceDelegate indexPath:(NSIndexPath *)indexPath;
@end
