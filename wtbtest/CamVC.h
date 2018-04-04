//
//  CamVC.h
//  wtbtest
//
//  Created by Jack Ryder on 18/02/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FastttCamera.h"
#import "ConfirmController.h"

@class CamVC;

@protocol CameraVCDelegate <NSObject>
- (void)finalImage:(UIImage *)image;
-(void)dismissPressed:(BOOL)yesorno;
@end

@interface CamVC : UITableViewController <FastttCameraDelegate, ConfirmControllerDelegate>

@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *mainCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *buttonCell;

@property (weak, nonatomic) IBOutlet UIButton *switchButton;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (weak, nonatomic) IBOutlet UIButton *photoButton;
@property (weak, nonatomic) IBOutlet UIButton *retakeButton;

@property (nonatomic, weak) id <CameraVCDelegate> delegate;

@property (nonatomic, strong) FastttCamera *fastCamera;
@property (nonatomic, strong) FastttCapturedImage *capturedImage;

@property (nonatomic, strong) ConfirmController *confirmController;
@property (nonatomic, strong) UIImage *finishedImage;
@property (nonatomic) BOOL loaded;

@property (nonatomic) BOOL confirmMode;
@property (nonatomic) BOOL imagesReady;

@property (nonatomic) BOOL killedFastCam;
@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;

@end
