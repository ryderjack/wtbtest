//
//  SummaryCollectionView.h
//  
//
//  Created by Jack Ryder on 29/03/2016.
//
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface SummaryCollectionView : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UILabel *noResultsLabel;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic) NSString *mode;
@end
