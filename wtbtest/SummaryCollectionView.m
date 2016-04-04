//
//  SummaryCollectionView.m
//  
//
//  Created by Jack Ryder on 29/03/2016.
//
//

#import "SummaryCollectionView.h"
#import "OrderSummaryController.h"
#import "SummaryCell.h"

@interface SummaryCollectionView ()

@end

@implementation SummaryCollectionView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.noResultsLabel setHidden:YES];
    
    if ([self.mode isEqualToString:@"purchased"]){
        self.navigationItem.title = @"Purchased";
    }
    else if ([self.mode isEqualToString:@"sold"]){
        self.navigationItem.title = @"Sold";
    }
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [self.collectionView registerClass:[SummaryCell class] forCellWithReuseIdentifier:@"Cell"];
    
    UINib *cellNib = [UINib nibWithNibName:@"OfferCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iPhone5
        [flowLayout setItemSize:CGSizeMake(self.collectionView.frame.size.width-40, 72)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.height == 736){
        //iPhone 6 plus
        [flowLayout setItemSize:CGSizeMake(self.collectionView.frame.size.width-20, 72)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.height == 480){
        //iPhone 4
        [flowLayout setItemSize:CGSizeMake(self.collectionView.frame.size.width-40, 72)];
    }
    else{
        //iPhone 6
        [flowLayout setItemSize:CGSizeMake(self.collectionView.frame.size.width-20, 72)];
    }
    
    [flowLayout setMinimumInteritemSpacing:0.0];
    [flowLayout setMinimumLineSpacing:8.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.alwaysBounceVertical = YES;
    
    self.results = [[NSMutableArray alloc]init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self parseQuery];
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(8, 8, 8, 8); // top, left, bottom, right
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    SummaryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    PFObject *order = [self.results objectAtIndex:indexPath.row];
    
    if ([[order objectForKey:@"status"] isEqualToString:@"paid"]) {
        cell.shipImageView.image = [UIImage imageNamed:@"planeOff"];
        cell.fbImageView.image = [UIImage imageNamed:@"starOff"];
    }
    else if ([[order objectForKey:@"status"] isEqualToString:@"paid"]) {
        cell.shipImageView.image = [UIImage imageNamed:@"planeOn"];
        cell.fbImageView.image = [UIImage imageNamed:@"starOff"];
    }
    else if ([[order objectForKey:@"status"] isEqualToString:@"paid"]) {
        cell.shipImageView.image = [UIImage imageNamed:@"planeOn"];
        cell.fbImageView.image = [UIImage imageNamed:@"starOn"];
    }
    
    
    
    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.results.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    PFObject *selectedOffer = [self.results objectAtIndex:indexPath.item];
    
    if ([self.mode isEqualToString:@"purchased"]){
        //goto order summary
        OrderSummaryController *vc = [[OrderSummaryController alloc]init];
        vc.purchased = YES;
        vc.orderObject = selectedOffer;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([self.mode isEqualToString:@"sold"]){
        //goto order summary
        OrderSummaryController *vc = [[OrderSummaryController alloc]init];
        vc.purchased = NO;
        vc.orderObject = selectedOffer;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(void)parseQuery{
    PFQuery *query = [PFQuery queryWithClassName:@"orders"];
    
    if ([self.mode isEqualToString:@"sold"]) {
        [query whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
        [query includeKey:@"buyerUser"];
    }
    else if ([self.mode isEqualToString:@"purchased"]){
        [query whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
        [query includeKey:@"sellerUser"];
    }
    [query includeKey:@"offerObject"];
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            if (objects.count == 0) {
                [self.noResultsLabel setHidden:NO];
            }
            else{
                [self.noResultsLabel setHidden:YES];
            }
            [self.results removeAllObjects];
            [self.results addObjectsFromArray:objects];
            [self.collectionView reloadData];
        }
        else{
            NSLog(@"error %@", error);
        }
    }];

}

@end
