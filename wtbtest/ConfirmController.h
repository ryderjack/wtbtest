//
//  ConfirmController.h
//  wtbtest
//
//  Created by Jack Ryder on 01/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FastttCamera.h"

@class ConfirmController;

@protocol ConfirmControllerDelegate <NSObject>
- (void)dismissConfirmController:(ConfirmController *)controller;
- (void)imageConfirmed:(UIImage *)image;
@end

@interface ConfirmController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (nonatomic, strong) FastttCapturedImage *capturedImage;
@property (nonatomic, assign) BOOL imagesReady;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (nonatomic, weak) id <ConfirmControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *tageLabel;
@property (nonatomic, strong) NSString *tagText;
@property (nonatomic) BOOL offerMode;

@end
