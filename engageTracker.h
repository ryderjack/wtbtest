//
//  engageTracker.h
//  wtbtest
//
//  Created by Jack Ryder on 20/06/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class engageTracker;
@protocol engageDelegate <NSObject>
-(void)addImagePressed;
@end

@interface engageTracker : UIView
@property (weak, nonatomic) IBOutlet UIButton *onePressed;
@property (weak, nonatomic) IBOutlet UIButton *twoPressed;
@property (weak, nonatomic) IBOutlet UIButton *threePressed;
@property (weak, nonatomic) IBOutlet UIButton *fourPressed;
@property (weak, nonatomic) IBOutlet UIButton *fivePressed;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UILabel *bottomLabel;

@property (nonatomic) int numberSelected;
@property (nonatomic) BOOL doneShowing;
//delegate
@property (nonatomic, weak) id <engageDelegate> delegate;

//add picture *new*
@property (weak, nonatomic) IBOutlet UIButton *addButton;


@end
