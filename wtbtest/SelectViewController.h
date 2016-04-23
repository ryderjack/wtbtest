//
//  SelectViewController.h
//  
//
//  Created by Jack Ryder on 26/02/2016.
//
//

#import <UIKit/UIKit.h>
#import "selectCell.h"

@class SelectViewController;

@protocol SelectViewControllerDelegate <NSObject>
- (void)addItemViewController:(SelectViewController *)controller didFinishEnteringItem:(NSString *)item withitem:(NSString *)item2;
@end

@interface SelectViewController : UITableViewController

@property (nonatomic, weak) id <SelectViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *setting;
@property (nonatomic) BOOL offer;
@property (nonatomic, strong) NSIndexPath *lastSelectedPath;

@property (strong, nonatomic) NSString *genderSelected;

@property (nonatomic, strong) NSArray *sizeArray;
@property (nonatomic, strong) NSArray *conditionArray;
@property (nonatomic, strong) NSArray *deliveryArray;
@property (nonatomic, strong) NSArray *categoryArray;
@property (nonatomic, strong) NSArray *clothingyArray;

@property (nonatomic, strong) selectCell *cell;
@end
