//
//  AddSizeController.h
//  wtbtest
//
//  Created by Jack Ryder on 01/04/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SwipeView/SwipeView.h>
#import <Parse/Parse.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>

@class AddSizeController;

@protocol sizeDelegate <NSObject>
- (void)addSizeDismissed;
@end

@interface AddSizeController : UITableViewController <SwipeViewDelegate, SwipeViewDataSource>

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sneakerCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *clothingCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *emptyCell;

//sneaker cell
@property (weak, nonatomic) IBOutlet UIButton *ukButton;
@property (weak, nonatomic) IBOutlet UIButton *usButton;
@property (weak, nonatomic) IBOutlet UIButton *euButton;
@property (strong, nonatomic) IBOutlet SwipeView *sneakerSwipeView;

//clothing cell
@property (weak, nonatomic) IBOutlet SwipeView *templateSwipeView;
@property (strong, nonatomic) SwipeView *clothingSwipeView;
@property (weak, nonatomic) IBOutlet UILabel *extraLabel;

//settings
@property (nonatomic, strong) NSString *selectedCountry;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;

//swipeView
@property (nonatomic, strong) NSArray *shoeSizesArray;
@property (nonatomic, strong) NSArray *clothingSizesArray;

@property (nonatomic, strong) NSArray *UKShoeSizes;
@property (nonatomic, strong) NSArray *USShoeSizes;
@property (nonatomic, strong) NSArray *EUShoeSizes;

//long button
@property (nonatomic, strong) UIButton *longButton;
@property (nonatomic) BOOL longShowing;

//delegate
@property (nonatomic, weak) id <sizeDelegate> delegate;

//spinner
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

//mode
@property (nonatomic) BOOL editMode;

@end

