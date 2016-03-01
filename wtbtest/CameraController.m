//
//  CameraController.m
//  
//
//  Created by Jack Ryder on 01/03/2016.
//
//

#import "CameraController.h"

@interface CameraController ()

@end

@implementation CameraController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _fastCamera = [FastttCamera new];
    self.fastCamera.delegate = self;
    
    [self fastttAddChildViewController:self.fastCamera];
    self.fastCamera.view.frame = self.camView.frame;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)takePhotoPressed:(id)sender {
    [self.fastCamera takePicture];
}
- (IBAction)dismissPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)flashPressed:(id)sender {
    FastttCameraFlashMode flashMode;
    switch (self.fastCamera.cameraFlashMode) {
        case FastttCameraFlashModeOn:
            flashMode = FastttCameraFlashModeOff;
            [self.flashButton setImage:[UIImage imageNamed:@"FlashOff"] forState:UIControlStateNormal];
            break;
        case FastttCameraFlashModeOff:
        default:
            flashMode = FastttCameraFlashModeOn;
            [self.flashButton setImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
            break;
    }
    if ([self.fastCamera isFlashAvailableForCurrentDevice]) {
        [self.fastCamera setCameraFlashMode:flashMode];
    }
}
- (IBAction)switchCameraPressed:(id)sender {
    
    FastttCameraDevice cameraDevice;
    switch (self.fastCamera.cameraDevice) {
        case FastttCameraDeviceFront:
            cameraDevice = FastttCameraDeviceRear;
            break;
        case FastttCameraDeviceRear:
        default:
            cameraDevice = FastttCameraDeviceFront;
            break;
    }
    if ([FastttCamera isCameraDeviceAvailable:cameraDevice]) {
        [self.fastCamera setCameraDevice:cameraDevice];
        if (![self.fastCamera isFlashAvailableForCurrentDevice]) {
//            [self.flashButton setTitle:@"Flash Off" forState:UIControlStateNormal];
        }
    }
}

#pragma mark - IFTTTFastttCameraDelegate

- (void)cameraController:(id<FastttCameraInterface>)cameraController didFinishCapturingImage:(FastttCapturedImage *)capturedImage
{
    NSLog(@"A photo was taken");
    
    self.confirmController = [[ConfirmController alloc]init];
    self.confirmController.capturedImage = capturedImage;
    self.confirmController.delegate = self;
    [self fastttAddChildViewController:self.confirmController];
}

- (void)cameraController:(id<FastttCameraInterface>)cameraController didFinishNormalizingCapturedImage:(FastttCapturedImage *)capturedImage
{
    NSLog(@"Photos are ready");
    self.confirmController.imagesReady = YES;

}

-(void)dismissConfirmController:(ConfirmController *)controller{
    [self fastttRemoveChildViewController:controller];
    self.confirmController = nil;
}

-(void)imageConfirmed:(UIImage *)image{
    self.finishedImage = image;
    [self.delegate finalImage:image];
}


@end
