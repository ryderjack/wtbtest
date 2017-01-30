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
#import "customAlertViewClass.h"
#import "viewItemClass.h"
#import "TOJRWebView.h"

@interface BuyNowController : UIViewController <UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource,customAlertDelegate,viewItemDelegate,JRWebViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableDictionary *contentOffsetDictionary;
@property (nonatomic, strong) NSMutableArray *wtbArray;

@property (nonatomic, strong) NSMutableArray *viewsArray;
@property (nonatomic, strong) NSMutableArray *products;
@property (nonatomic, strong) NSMutableArray *productIDs;

@property (nonatomic, strong) NSArray *searchWords;
@property (nonatomic, strong) NSArray *calcdKeywords;
@property (nonatomic, strong) NSArray *wantedWords;

@property (nonatomic) int productSkipped;
@property (nonatomic) int moreProductSkipped;

@property (nonatomic) BOOL showRelated;

@property (nonatomic) BOOL reloadingRelated;

@property (nonatomic) BOOL pullFinished;
@property (nonatomic) BOOL infinFinished;
@property (nonatomic) BOOL ignoreRelatedShown;
@property (nonatomic) int skipped;

@property (nonatomic, strong) DGActivityIndicatorView *spinner;

@property (nonatomic, strong) PFQuery *infiniteQuery;
@property (nonatomic, strong) PFQuery *pullQuery;

@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@property (nonatomic, strong) UILabel *topLabel;
@property (nonatomic, strong) UILabel *bottomLabel;

@property (nonatomic) BOOL viewedItem;
@property (weak, nonatomic) IBOutlet UIButton *anotherPromptButton;

//custom alert view
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic) BOOL alertShowing;

//ebay
@property (nonatomic) BOOL fromInfinEbay;
@property (nonatomic) BOOL ebayEnabled;
@property (nonatomic, strong) NSMutableArray *seenEbayItems;

//item viewer
@property (nonatomic, strong) viewItemClass *itemView;
@property (nonatomic, strong) PFObject *listingToView;
@property (nonatomic, strong) NSDictionary *ebayToView;
@property (nonatomic) BOOL ebayTapped;
@property (nonatomic, strong) UIView *viewerBg;
@property (nonatomic) BOOL itemShowing;

@property (nonatomic) int pullSkipped;

//web view
@property (nonatomic, strong) TOJRWebView *web;


@end
