//
//  FilterVC.h
//  wtbtest
//
//  Created by Jack Ryder on 01/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

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

//price buttons
@property (weak, nonatomic) IBOutlet UIButton *hightolowButton;
@property (weak, nonatomic) IBOutlet UIButton *lowtoHighButton;

//condition buttons
@property (weak, nonatomic) IBOutlet UIButton *usedButton;
@property (weak, nonatomic) IBOutlet UIButton *newconditionButton;

//category buttons
@property (weak, nonatomic) IBOutlet UIButton *clothingButton;
@property (weak, nonatomic) IBOutlet UIButton *footButton;

//size
@property (weak, nonatomic) IBOutlet UIScrollView *sizeScrollButton;

//apply
@property (weak, nonatomic) IBOutlet UIButton *applyButton;

@end
