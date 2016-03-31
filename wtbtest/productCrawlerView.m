//
//  productCrawlerView.m
//  
//
//  Created by Jack Ryder on 28/03/2016.
//
//

#import "productCrawlerView.h"

@interface productCrawlerView ()

@end

@implementation productCrawlerView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"My wantobuys";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    //collection view/cell setup
//    [self.collectionView registerClass:[ExploreCell class] forCellWithReuseIdentifier:@"Cell"];
    
    UINib *cellNib = [UINib nibWithNibName:@"ExploreCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(175, 300)]; //iPhone 6 specific
    [flowLayout setMinimumInteritemSpacing:0];
    [flowLayout setMinimumLineSpacing:8.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    
    self.results = [[NSMutableArray alloc]init];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(8, 8, 8, 8); // top, left, bottom, right
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    //create the custom cell next then hook it up jacky boi
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.results.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}



@end
