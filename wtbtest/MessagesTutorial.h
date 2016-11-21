//
//  MessagesTutorial.h
//  wtbtest
//
//  Created by Jack Ryder on 26/10/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessagesTutorial : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *heroImageView;
@property (weak, nonatomic) IBOutlet UILabel *explainLabel;
@property (weak, nonatomic) IBOutlet UIButton *progressButton;
@property (nonatomic) int progressNumber;

@property (weak, nonatomic) IBOutlet UIButton *crossButton;
@property (nonatomic) BOOL sellerMode;
@property (nonatomic) BOOL fromMessageVC;

@end
