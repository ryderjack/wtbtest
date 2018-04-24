//
//  FilterVC.h
//  wtbtest
//
//  Created by Jack Ryder on 01/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SwipeView/SwipeView.h>
#import "NMRangeSlider.h"

@class FilterVC;

@protocol FilterDelegate <NSObject>
- (void)filtersReturned:(NSMutableArray *)filters withSizesArray:(NSMutableArray *)sizes andBrandsArray:(NSMutableArray *)brands andColours:(NSMutableArray *)colours andCategories:(NSString *)category andPricLower:(float)lower andPriceUpper:(float)upper andContinents:(NSMutableArray *)continents;
- (void)noChange;

@end

@interface FilterVC : UITableViewController <SwipeViewDelegate, SwipeViewDataSource>

@property (nonatomic, weak) id <FilterDelegate> delegate;

//slider
@property (weak, nonatomic) IBOutlet UILabel *sliderLabel;
@property (weak, nonatomic) IBOutlet NMRangeSlider *doubleSlider;
@property (nonatomic, strong) NSString *currencySymbol;
@property (nonatomic) float filterLower;
@property (nonatomic) float filterUpper;

//general
@property (strong, nonatomic) NSMutableArray *filtersArray;
@property (strong, nonatomic) NSMutableArray *sendArray;

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *priceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *conditionCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *categoryCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sizeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *distanceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *spaceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *brandCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *colourCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *categoryIconCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *priceSliderCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *locationContinentsCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *priceSliderInstantBuy;
@property (strong, nonatomic) IBOutlet UITableViewCell *followingCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *showOnlyCell;

//price buttons
@property (weak, nonatomic) IBOutlet UIButton *hightolowButton;
@property (weak, nonatomic) IBOutlet UIButton *lowtoHighButton;
@property (weak, nonatomic) IBOutlet UIButton *instantBuySwitch;

//condition buttons
@property (weak, nonatomic) IBOutlet UIButton *usedButton;
@property (weak, nonatomic) IBOutlet UIButton *conditionNewButton;

//category buttons
@property (weak, nonatomic) IBOutlet UIButton *clothingButton;
@property (weak, nonatomic) IBOutlet UIButton *footButton;
@property (weak, nonatomic) IBOutlet UIButton *accessoryButton;

//category cell w/ icons
@property (weak, nonatomic) IBOutlet SwipeView *categorySwipeView;
@property (nonatomic, strong) NSArray *categoryArray;
//@property (strong, nonatomic) NSMutableArray *chosenCategoriesArray;
@property (strong, nonatomic) NSString *chosenCategory;
@property (nonatomic, strong) NSArray *categoryImagesArray;
@property (nonatomic, strong) NSArray *categorySelectedImagesArray;

//show only buttons
@property (weak, nonatomic) IBOutlet UIButton *soldOnlyButton;


//location buttons
@property (weak, nonatomic) IBOutlet UIButton *distanceButton;
@property (weak, nonatomic) IBOutlet SwipeView *locationSwipeView;
@property (nonatomic, strong) NSArray *continentsArray;
@property (nonatomic, strong) NSMutableArray *chosenContinentsArray;
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

@property (nonatomic, strong) NSArray *brandImagesArray;
@property (nonatomic, strong) NSArray *brandSelectedImagesArray;

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

//status bar background view
@property (nonatomic, strong) UIView *statusBarBGView;

//seller filters
@property (weak, nonatomic) IBOutlet UIButton *followingButton;
@property (nonatomic) BOOL searchMode;


@end
