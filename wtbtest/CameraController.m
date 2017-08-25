//
//  CameraController.m
//  
//
//  Created by Jack Ryder on 01/03/2016.
//
//

#import "CameraController.h"
#import <Parse/Parse.h>

@interface CameraController ()

@end

@implementation CameraController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _fastCamera = [FastttCamera new];
    self.fastCamera.delegate = self;
    
    [self fastttAddChildViewController:self.fastCamera];
    self.fastCamera.view.frame = self.camView.frame;
    self.fastCamera.cameraFlashMode = FastttCameraFlashModeOff;
    
    if (self.offerMode == YES) {
        // add tag label as camera overlay
        [self.fastCamera.view addSubview:self.tageLabel];
        
        // set date
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setDateFormat:@"MMM YY"];
        
        NSDate *formattedDate = [NSDate date];
        self.tageLabel.text = [NSString stringWithFormat:@"%@\n%@", [PFUser currentUser].username, [dateFormatter stringFromDate:formattedDate]];
        dateFormatter = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)takePhotoPressed:(id)sender {
    [self.fastCamera takePicture];
}
- (IBAction)dismissPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate dismissPressed:YES];
    }];
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
            [self.flashButton setEnabled:YES];
            break;
        case FastttCameraDeviceRear:
        default:
            cameraDevice = FastttCameraDeviceFront;
            self.fastCamera.cameraFlashMode = FastttCameraFlashModeOff;
            [self.flashButton setImage:[UIImage imageNamed:@"FlashOff"] forState:UIControlStateNormal];
            [self.flashButton setEnabled:NO];
            break;
    }
    if ([FastttCamera isCameraDeviceAvailable:cameraDevice]) {
        [self.fastCamera setCameraDevice:cameraDevice];
        if (![self.fastCamera isFlashAvailableForCurrentDevice]) {
            [self.flashButton setImage:[UIImage imageNamed:@"FlashOff"] forState:UIControlStateNormal];
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
    
    if (self.offerMode == YES) {
        self.confirmController.offerMode = YES;
        self.confirmController.tagText = self.tageLabel.text;
    }
    
//    [self fastttAddChildViewController:self.confirmController];

    [self presentViewController:self.confirmController animated:YES completion:nil];
}

- (void)cameraController:(id<FastttCameraInterface>)cameraController didFinishNormalizingCapturedImage:(FastttCapturedImage *)capturedImage
{
    NSLog(@"Photos are ready");
    self.confirmController.imagesReady = YES;

}

-(void)dismissConfirmController:(ConfirmController *)controller{
    //adding children VCs was causing xib's to be < full screen so just presenting/dimissing modallying
    
//    [self fastttRemoveChildViewController:controller];
    self.confirmController = nil;
}

-(void)imageConfirmed:(UIImage *)image{
    [self dismissViewControllerAnimated:NO completion:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    self.finishedImage = image;
    [self.delegate finalImage:image];
    
    if (self.offerMode == YES) {
        [self.delegate tagString:self.tageLabel.text];
    }
}


@end
