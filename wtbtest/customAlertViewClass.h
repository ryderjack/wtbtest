//
//  customAlertViewClass.h
//  wtbtest
//
//  Created by Jack Ryder on 08/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class customAlertViewClass;
@protocol customAlertDelegate <NSObject>
- (void)donePressed;
- (void)firstPressed;
- (void)secondPressed;
@end

@interface customAlertViewClass : UIView
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (nonatomic, weak) id <customAlertDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *secondButton;
@property (weak, nonatomic) IBOutlet UIButton *firstButton;
@property (nonatomic) int numberOfButtons;

@end
