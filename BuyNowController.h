//
//  BuyNowController.h
//  wtbtest
//
//  Created by Jack Ryder on 06/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DGActivityIndicatorView.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface BuyNowController : UIViewController <UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableDictionary *contentOffsetDictionary;
@property (nonatomic, strong) NSMutableArray *wtbArray;

@property (nonatomic, strong) NSMutableArray *viewsArray;
@property (nonatomic, strong) NSMutableArray *products;
@property (nonatomic, strong) NSMutableArray *productIDs;

@property (nonatomic) BOOL showRelated;


@property (nonatomic) BOOL pullFinished;
@property (nonatomic) BOOL infinFinished;
@property (nonatomic) int skipped;

@property (nonatomic, strong) DGActivityIndicatorView *spinner;

@property (nonatomic, strong) PFQuery *infiniteQuery;
@property (nonatomic, strong) PFQuery *pullQuery;

@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@property (nonatomic, strong) UILabel *topLabel;
@property (nonatomic, strong) UILabel *bottomLabel;

@property (nonatomic) BOOL viewedItem;
@property (weak, nonatomic) IBOutlet UIButton *anotherPromptButton;


@end
