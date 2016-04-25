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
@end

@interface selectCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic) BOOL firstSelected;
@property (nonatomic, weak) id <selectCellDelegate> delegate;

@end
