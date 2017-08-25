//
//  ConditionsOptionsTableView.h
//  wtbtest
//
//  Created by Jack Ryder on 09/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ConditionsOptionsTableView;

@protocol ConditionsDelegate <NSObject>
- (void)firstConditionPressed;
- (void)secondConditionPressed;
- (void)thirdConditionPressed;

@end

@interface ConditionsOptionsTableView : UITableViewController

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *firstCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *secondCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *thirdCell;

//delegate
@property (nonatomic, weak) id <ConditionsDelegate> delegate;

//labels
@property (weak, nonatomic) IBOutlet UILabel *firstLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstBody;
@property (weak, nonatomic) IBOutlet UILabel *secondBody;
@property (weak, nonatomic) IBOutlet UILabel *thirdBody;

//already selected a condition?
@property (nonatomic,strong) NSString *selection;

@end
