//
//  BumpingIntroVC.h
//  wtbtest
//
//  Created by Jack Ryder on 21/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BumpingIntroVC;

@protocol BumpingIntroDelegate <NSObject>
- (void)dismissedBumpingIntro;
@end

@interface BumpingIntroVC : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *mainImageView;
@property (weak, nonatomic) IBOutlet UIImageView *cursorImageView;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIImageView *selectedMainImageView;

//delegate
@property (nonatomic, weak) id <BumpingIntroDelegate> delegate;

@end
