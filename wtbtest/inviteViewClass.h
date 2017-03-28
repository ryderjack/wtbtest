//
//  inviteViewClass.h
//  wtbtest
//
//  Created by Jack Ryder on 05/03/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@class inviteViewClass;
@protocol inviteDelegate <NSObject>
- (void)whatsappPressed;
- (void)messengerPressed;
- (void)textPressed;

@end

@interface inviteViewClass : UIView

//friends on bump
@property (weak, nonatomic) IBOutlet PFImageView *friendImageOne;
@property (weak, nonatomic) IBOutlet PFImageView *friendImageTwo;
@property (weak, nonatomic) IBOutlet PFImageView *friendImageThree;
@property (weak, nonatomic) IBOutlet UILabel *friendsLabel;

//shareButtons
@property (weak, nonatomic) IBOutlet UIButton *whatsAppButton;
@property (weak, nonatomic) IBOutlet UIButton *messengerButton;
@property (weak, nonatomic) IBOutlet UIButton *textButton;

//delegate
@property (nonatomic, weak) id <inviteDelegate> delegate;

@end
