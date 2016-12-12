//
//  Tut1ViewController.h
//  wtbtest
//
//  Created by Jack Ryder on 24/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CreateViewController.h"

@interface Tut1ViewController : UIViewController <CreateViewControllerDelegate>

@property (assign, nonatomic) NSInteger index;
@property (weak, nonatomic) IBOutlet UIImageView *heroImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *cursorImageView;
@property (weak, nonatomic) IBOutlet UIImageView *screenImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sendOfferImageView;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (nonatomic) BOOL messageExplain;
@property (weak, nonatomic) IBOutlet UIButton *dimissButton;
@property (nonatomic) BOOL explainMode;
@end
