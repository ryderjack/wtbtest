//
//  FilterVC.h
//  wtbtest
//
//  Created by Jack Ryder on 01/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SwipeView/SwipeView.h>

@class FilterVC;

@protocol FilterDelegate <NSObject>
- (void)filtersReturned:(NSMutableArray *)filters withSizesArray:(NSMutableArray *)sizes andBrandsArray:(NSMutableArray *)brands andColours:(NSMutableArray *)colours;
- (void)noChange;

@end

@interface FilterVC : UITableViewController <SwipeViewDelegate, SwipeViewDataSource>

@property (nonatomic, weak) id <FilterDelegate> delegate;

//general
@property (strong, nonatomic) NSMutableArray *filtersArray;
@property (strong, nonatomic) NSMutableArray *sendArray;

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *priceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *conditionCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *categoryCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sizeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *applyCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *distanceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *spaceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *brandCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *colourCell;

//price buttons
@property (weak, nonatomic) IBOutlet UIButton *hightolowButton;
@property (weak, nonatomic) IBOutlet UIButton *lowtoHighButton;

//condition buttons
@property (weak, nonatomic) IBOutlet UIButton *usedButton;
@property (weak, nonatomic) IBOutlet UIButton *deadstockButton;
@property (weak, nonatomic) IBOutlet UIButton *conditionNewButton;

//category buttons
@property (weak, nonatomic) IBOutlet UIButton *clothingButton;
@property (weak, nonatomic) IBOutlet UIButton *footButton;
@property (weak, nonatomic) IBOutlet UIButton *accessoryButton;

//location buttons
@property (weak, nonatomic) IBOutlet UIButton *distanceButton;

//applyButton
@property (nonatomic, strong) UIButton *applyButton;

//size swipe view
@property (weak, nonatomic) IBOutlet SwipeView *swipeView;
@property (nonatomic, strong) NSString *sizeMode;
@property (nonatomic, strong) NSString *lastSelected;

//brand swipe view
@property (weak, nonatomic) IBOutlet SwipeView *brandSwipeView;
@property (nonatomic, strong) NSArray *brandArray;
@property (nonatomic, strong) NSArray *brandAcronymArray;

@property (strong, nonatomic) NSMutableArray *chosenBrandsArray;

//size buttons
@property (weak, nonatomic) IBOutlet UIButton *menButton;
@property (weak, nonatomic) IBOutlet UIButton *womenButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) NSArray *sizeLabels;
@property (nonatomic, strong) NSArray *shoesArray;
@property (strong, nonatomic) NSMutableArray *chosenSizesArray;

//colour filter
@property (weak, nonatomic) IBOutlet SwipeView *colourSwipeView;
@property (nonatomic, strong) NSArray *coloursArray;
@property (nonatomic, strong) NSArray *colourValuesArray;
@property (nonatomic, strong) NSMutableArray *chosenColourArray;

//mode
@property (nonatomic) BOOL sellingSearch;
@property (nonatomic) BOOL profileSearch;

@end
