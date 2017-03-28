//
//  FeaturedItems.h
//  wtbtest
//
//  Created by Jack Ryder on 17/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>
#import <MBProgressHUD.h>
#import <DGActivityIndicatorView.h>

@interface FeaturedItems : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *listings;
@property (nonatomic) BOOL viewedItem;


//spinner
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) DGActivityIndicatorView *otherSpinner;

//modes
@property (nonatomic, strong) NSString *mode;
@property (nonatomic, strong) NSString *shop;

//queries
@property (nonatomic, strong) PFQuery *infiniteQuery;
@property (nonatomic, strong) PFQuery *pullQuery;
@property (nonatomic) int skipped;
@property (nonatomic) BOOL pullFinished;
@property (nonatomic) BOOL infinFinished;

@end
