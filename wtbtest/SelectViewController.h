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
#import "customAlertViewClass.h"

@class SelectViewController;

@protocol SelectViewControllerDelegate <NSObject>
- (void)addItemViewController:(SelectViewController *)controller didFinishEnteringItem:(NSString *)selectionString withgender:(NSString *)genderString andsizes:(NSArray *)array;
@end

@interface SelectViewController : UITableViewController <selectCellDelegate, customAlertDelegate, SelectViewControllerDelegate>

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
@property (nonatomic, strong) NSArray *clothingyDescriptionArray;
@property (nonatomic, strong) NSArray *clothingCategoryArray;

@property (nonatomic, strong) NSMutableArray *selectedSizes;
@property (nonatomic, strong) NSArray *holdingArray;
@property (nonatomic, strong) NSString *holdingGender;

@property (nonatomic, strong) selectCell *cell;

@property (nonatomic) BOOL sellListing;
@property (nonatomic) BOOL multipleAllowed;
@property (nonatomic) BOOL pushingClothing;

//viewing multiple sizes from a listing
@property (nonatomic) BOOL viewingMode; //when showing sizes from a lisitng
@property (nonatomic, strong) NSMutableArray *viewingArray;

//multiple reminder
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;
@end
