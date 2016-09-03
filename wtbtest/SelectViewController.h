//
//  SelectViewController.h
//  
//
//  Created by Jack Ryder on 26/02/2016.
//
//

#import <UIKit/UIKit.h>
#import "selectCell.h"
#import <Parse/Parse.h>


@class SelectViewController;

@protocol SelectViewControllerDelegate <NSObject>
- (void)addItemViewController:(SelectViewController *)controller didFinishEnteringItem:(NSString *)selectionString withgender:(NSString *)genderString andsizes:(NSArray *)array;
@end

@interface SelectViewController : UITableViewController <selectCellDelegate>

@property (nonatomic, weak) id <SelectViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *setting;

@property (nonatomic, strong) NSIndexPath *lastSelectedPath;

@property (strong, nonatomic) NSString *genderSelected;

@property (nonatomic, strong) NSArray *mensSizeArray;
@property (nonatomic, strong) NSArray *femaleSizeArray;

@property (nonatomic, strong) NSArray *mensSizeUKArray;
@property (nonatomic, strong) NSArray *femaleSizeUKArray;

@property (nonatomic, strong) NSArray *conditionArray;
@property (nonatomic, strong) NSArray *deliveryArray;
@property (nonatomic, strong) NSArray *categoryArray;
@property (nonatomic, strong) NSArray *clothingyArray;

@property (nonatomic, strong) NSMutableArray *selectedSizes;
@property (nonatomic, strong) NSArray *holdingArray;
@property (nonatomic, strong) NSString *holdingGender;

@property (nonatomic, strong) selectCell *cell;
@end
