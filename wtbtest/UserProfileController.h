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
@property (nonatomic, strong) NSArray *lisitngsArray;
@property (nonatomic, strong) NSMutableArray *feedbackArray;
@property (weak, nonatomic) IBOutlet PFImageView *headerImgView;
@property (weak, nonatomic) IBOutlet UILabel *dealsLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UIImageView *starImgView;
@property (nonatomic, strong) PFUser *user;
@property (weak, nonatomic) IBOutlet UILabel *nothingLabel;

//currency
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *currencySymbol;

//infin
@property (nonatomic) int lastSkipped;
@property (nonatomic) BOOL pullFinished;
@property (nonatomic) BOOL infinFinished;
@end
