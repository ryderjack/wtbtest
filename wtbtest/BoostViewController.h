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
- (void)PaidBOOSTPressed;
- (void)FreeBoostPressed;
- (void)WaitBOOSTPressed;
- (void)DismissBOOSTPressed;

@end

@interface BoostViewController : UIView

@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *lowerWaitLabel;
@property (weak, nonatomic) IBOutlet UIButton *mainButton;

//pay screen
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet UILabel *payExplainLabel;
@property (nonatomic, strong) NSString *priceString;
@property (nonatomic, strong) NSString *waitHoursString;

//modes
@property (nonatomic,strong) NSString *mode;

//delegate
@property (nonatomic, weak) id <BOOSTViewDelegate> delegate;

//intro boost mode
@property (weak, nonatomic) IBOutlet UIImageView *bolttImageView;
@property (weak, nonatomic) IBOutlet UILabel *introLowerLabel;



@end
