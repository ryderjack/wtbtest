//
//  UserProfileController.h
//  wtbtest
//
//  Created by Jack Ryder on 26/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface UserProfileController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *WTBArray;
@property (nonatomic, strong) NSArray *forSaleArray;

@property (nonatomic, strong) NSMutableArray *feedbackArray;
@property (weak, nonatomic) IBOutlet PFImageView *headerImgView;
@property (weak, nonatomic) IBOutlet UILabel *dealsLabel;
@property (weak, nonatomic) IBOutlet UIImageView *starImgView;
@property (nonatomic, strong) PFUser *user;
@property (weak, nonatomic) IBOutlet UILabel *nothingLabel;
@property (weak, nonatomic) IBOutlet PFImageView *checkImageView;

//currency
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

//other labels
@property (weak, nonatomic) IBOutlet UILabel *sellerLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberLabel;

@property (nonatomic) BOOL isSeller;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sellerSegmentControl;

@property (nonatomic) BOOL forSalePressed;
@property (nonatomic) BOOL WTBPressed;

@property (nonatomic, strong) NSString *usernameToList;

@end
