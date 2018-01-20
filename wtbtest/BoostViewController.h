//
//  BoostViewController.h
//  wtbtest
//
//  Created by Jack Ryder on 15/01/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MZTimerLabel/MZTimerLabel.h>

@class BoostViewController;
@protocol BOOSTViewDelegate <NSObject>
- (void)BoostMainButtonPressedRemindMode:(BOOL)remind;
@end

@interface BoostViewController : UIView

@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *lowerWaitLabel;
@property (weak, nonatomic) IBOutlet UIButton *mainButton;

@property (weak, nonatomic) IBOutlet MZTimerLabel *timerLabel;

//modes
@property (nonatomic,strong) NSString *mode;

//delegate
@property (nonatomic, weak) id <BOOSTViewDelegate> delegate;


//intro boost mode
@property (weak, nonatomic) IBOutlet UIImageView *bolttImageView;
@property (weak, nonatomic) IBOutlet UILabel *introLowerLabel;

//success mode
@property (weak, nonatomic) IBOutlet MZTimerLabel *lowerTimerLabel;
@property (weak, nonatomic) IBOutlet UILabel *successLowerLabel;

@end
