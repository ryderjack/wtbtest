//
//  productCrawlerView.h
//  
//
//  Created by Jack Ryder on 28/03/2016.
//
//

#import <UIKit/UIKit.h>

@interface productCrawlerView : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *results;

@end
