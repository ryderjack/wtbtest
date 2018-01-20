//
//  ConnectPayPalViewClass.h
//  wtbtest
//
//  Created by Jack Ryder on 06/01/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ConnectPayPalViewClass;
@protocol ConnectPPDelegate <NSObject>
- (void)connectPressed;
- (void)remindMePressed;
@end

@interface ConnectPayPalViewClass : UIView
@property (weak, nonatomic) IBOutlet UIButton *connectButton;


//delegate
@property (nonatomic, weak) id <ConnectPPDelegate> delegate;
@end
