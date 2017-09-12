//
//  selectCell.h
//  wtbtest
//
//  Created by Jack Ryder on 23/04/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class selectCell;

@protocol selectCellDelegate <NSObject>
- (void)genderSelected:(NSString *)gender;
- (void)proxyExplainPressed;

@end

@interface selectCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic) BOOL firstSelected;
@property (nonatomic, weak) id <selectCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UIButton *proxyExplainButton;

@end
