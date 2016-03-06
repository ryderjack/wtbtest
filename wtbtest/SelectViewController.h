//
//  SelectViewController.h
//  
//
//  Created by Jack Ryder on 26/02/2016.
//
//

#import <UIKit/UIKit.h>

@class SelectViewController;

@protocol SelectViewControllerDelegate <NSObject>
- (void)addItemViewController:(SelectViewController *)controller didFinishEnteringItem:(NSString *)item withitem:(NSString *)item2;
@end

@interface SelectViewController : UITableViewController

@property (nonatomic, weak) id <SelectViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *setting;
@property (nonatomic) BOOL offer;
@property (nonatomic, strong) NSIndexPath *lastSelectedPath;

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *oneCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *twoCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *threeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *fourCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *fiveCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sixCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *sevenCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *eightCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *nineCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *tenCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *elevenCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *selectCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *twelveCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *thirteenCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *fourteenCell;

//labels
@property (weak, nonatomic) IBOutlet UILabel *firstLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdLabel;
@property (weak, nonatomic) IBOutlet UILabel *fourthLabel;
@property (weak, nonatomic) IBOutlet UILabel *fifthLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixthLabel;
@property (weak, nonatomic) IBOutlet UILabel *seventhLabel;
@property (weak, nonatomic) IBOutlet UILabel *eigthLabel;
@property (weak, nonatomic) IBOutlet UILabel *ninthLabel;
@property (weak, nonatomic) IBOutlet UILabel *tenthLabel;
@property (weak, nonatomic) IBOutlet UILabel *eleventhLabel;
@property (weak, nonatomic) IBOutlet UILabel *twelveLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirteenLabel;
@property (weak, nonatomic) IBOutlet UILabel *fourteenthLabel;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentContro;
@property (strong, nonatomic) NSString *genderSelected;



@end
