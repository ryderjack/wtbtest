//
//  AFCollectionView.h
//  wtbtest
//
//  Created by Jack Ryder on 07/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AFCollectionView : UICollectionView

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic) NSInteger section;

@end
