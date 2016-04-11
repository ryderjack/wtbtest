//
//  CameraController.h
//  
//
//  Created by Jack Ryder on 01/03/2016.
//
//

#import <UIKit/UIKit.h>
#import <FastttCamera.h>
#import "ConfirmController.h"

@class CameraController;

@protocol CameraControllerDelegate <NSObject>
- (void)finalImage:(UIImage *)image;
-(void)tagString:(NSString *)tag;
@end

@interface CameraController : UIViewController <FastttCameraDelegate, ConfirmControllerDelegate>

@property (nonatomic, strong) FastttCamera *fastCamera;
@property (weak, nonatomic) IBOutlet UIView *camView;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (weak, nonatomic) IBOutlet UIButton *switchButton;
@property (nonatomic, strong) ConfirmController *confirmController;
@property (nonatomic, strong) UIImage *finishedImage;
@property (nonatomic, weak) id <CameraControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *tageLabel;
@property (nonatomic) BOOL offerMode;

@end
