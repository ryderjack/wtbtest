//
//  FilterVC.h
//  wtbtest
//
//  Created by Jack Ryder on 01/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "brandObject.h"

@class FilterVC;

@protocol FilterDelegate <NSObject>
- (void)filtersReturned:(NSMutableArray *)filters;
@end

@interface FilterVC : UITableViewController

@property (nonatomic, weak) id <FilterDelegate> delegate;

@property (strong, nonatomic) NSMutableArray *filtersArray;
@property (strong, nonatomic) NSMutableArray *sendArray;

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *priceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *conditionCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *categoryCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sizeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *applyCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *brandCell;

//price buttons
@property (weak, nonatomic) IBOutlet UIButton *hightolowButton;
@property (weak, nonatomic) IBOutlet UIButton *lowtoHighButton;

//condition buttons
@property (weak, nonatomic) IBOutlet UIButton *usedButton;
@property (weak, nonatomic) IBOutlet UIButton *BNWTconditionButton;
@property (weak, nonatomic) IBOutlet UIButton *BNWOTButton;

//category buttons
@property (weak, nonatomic) IBOutlet UIButton *clothingButton;
@property (weak, nonatomic) IBOutlet UIButton *footButton;

//size
@property (weak, nonatomic) IBOutlet UIScrollView *sizeScrollButton;
@property (weak, nonatomic) IBOutlet UIScrollView *brandScrollView;
@property (weak, nonatomic) IBOutlet UIButton *menButton;
@property (weak, nonatomic) IBOutlet UIButton *womenButton;

@property (strong, nonatomic) UIButton *lasttapped;
@property (strong, nonatomic) UIButton *lastBrandButtonTapped;
@property (strong, nonatomic) NSString *lastBrandTapped;
@property (strong, nonatomic) UIImageView *lastBrandImageView;
@property (strong, nonatomic) UILabel *lastLabelTapped;

@property (nonatomic) BOOL clothingEnabled;

@property (nonatomic, strong) NSArray *sizeLabels;
@property (nonatomic, strong) NSArray *shoesArray;
@property (nonatomic, strong) NSArray *brandImageArray;
@property (nonatomic, strong) NSArray *brandNamesArray;

//apply
@property (weak, nonatomic) IBOutlet UIButton *applyButton;

//brand Img Views
@property (strong, nonatomic) UIImageView *adidasImageView;
@property (strong, nonatomic) UIImageView *nikeImageView;
@property (strong, nonatomic) UIImageView *palaceImageView;
@property (strong, nonatomic) UIImageView *stoneyImageView;
@property (strong, nonatomic) UIImageView *supremeImageView;
@property (strong, nonatomic) UIImageView *ralphImageView;

@property (nonatomic, strong) brandObject *adidas;
@property (nonatomic, strong) brandObject *nike;
@property (nonatomic, strong) brandObject *palace;
@property (nonatomic, strong) brandObject *stoney;
@property (nonatomic, strong) brandObject *supreme;
@property (nonatomic, strong) brandObject *ralph;

@end
