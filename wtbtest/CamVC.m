//
//  CamVC.m
//  wtbtest
//
//  Created by Jack Ryder on 18/02/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import "CamVC.h"

@interface CamVC ()

@end

@implementation CamVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _fastCamera = [FastttCamera new];
    self.fastCamera.delegate = self;
    
    self.mainCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.tableView. scrollEnabled = NO;
    
    [self.retakeButton setHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(comeBackToForeground)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:[UIApplication sharedApplication]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wentBackground)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:[UIApplication sharedApplication]];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    if (!self.loaded) {
        self.loaded = YES;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self fastttAddChildViewController:self.fastCamera];
            if([ [ UIScreen mainScreen ] bounds ].size.height == 812){
                //iPhone X
                self.fastCamera.view.frame = CGRectMake(0, 95, self.previewImageView.frame.size.width, self.previewImageView.frame.size.height);
            }
            else{
                self.fastCamera.view.frame = CGRectMake(0, 75, self.previewImageView.frame.size.width, self.previewImageView.frame.size.height);
            }
            self.fastCamera.cameraFlashMode = FastttCameraFlashModeOff;
        });
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        return self.titleCell;
    }
    else if (indexPath.row == 1) {
        return self.mainCell;
    }
    else if (indexPath.row == 2) {
        return self.buttonCell;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        if([ [ UIScreen mainScreen ] bounds ].size.height == 812){
            //iPhone X
            return 95;
        }
        return 75;
    }
    else if (indexPath.row == 1) {
        return [ [ UIScreen mainScreen ] bounds ].size.width;
    }
    else if (indexPath.row == 2) {
        if ([ [ UIScreen mainScreen ] bounds ].size.width == 320){
            return 170;
        }
        return 220;
    }
    return 220;
}

- (IBAction)photoButtonPressed:(id)sender {
    
    if (self.confirmMode) {
        [self imageConfirmed:self.capturedImage.fullImage];
    }
    else{
        [self.fastCamera takePicture];

        self.confirmMode = YES;
        
        [self.photoButton setEnabled:NO];
        
        //change buttons
        self.retakeButton.alpha = 0.0;
        [self.retakeButton setHidden:NO];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.photoButton setImage:[UIImage imageNamed:@"confirmButton"] forState:UIControlStateNormal];
                             
                             [self.switchButton setAlpha:0.0];
                             [self.flashButton setAlpha:0.0];
                             
                             self.retakeButton.alpha = 1.0;
                             
                         }
                         completion:^(BOOL finished) {
                             [self.switchButton setHidden:YES];
                             [self.flashButton setHidden:YES];
                         }];
    }
}

- (IBAction)switchPressed:(id)sender {
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
            [self.flashButton setImage:[UIImage imageNamed:@"FlashOffGrey"] forState:UIControlStateNormal];
            [self.flashButton setEnabled:NO];
            break;
    }
    if ([FastttCamera isCameraDeviceAvailable:cameraDevice]) {
        [self.fastCamera setCameraDevice:cameraDevice];
        if (![self.fastCamera isFlashAvailableForCurrentDevice]) {
            [self.flashButton setImage:[UIImage imageNamed:@"FlashOffGrey"] forState:UIControlStateNormal];
        }
    }
}
- (IBAction)flashPressed:(id)sender {
    FastttCameraFlashMode flashMode;
    switch (self.fastCamera.cameraFlashMode) {
        case FastttCameraFlashModeOn:
            flashMode = FastttCameraFlashModeOff;
            [self.flashButton setImage:[UIImage imageNamed:@"FlashOffGrey"] forState:UIControlStateNormal];
            break;
        case FastttCameraFlashModeOff:
        default:
            flashMode = FastttCameraFlashModeOn;
            [self.flashButton setImage:[UIImage imageNamed:@"flashOnGrey"] forState:UIControlStateNormal];
            break;
    }
    if ([self.fastCamera isFlashAvailableForCurrentDevice]) {
        [self.fastCamera setCameraFlashMode:flashMode];
    }
}
- (IBAction)cancelPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate dismissPressed:YES];
    }];
}

#pragma mark - IFTTTFastttCameraDelegate

- (void)cameraController:(id<FastttCameraInterface>)cameraController didFinishCapturingImage:(FastttCapturedImage *)capturedImage
{
    NSLog(@"A photo was taken");
    
    //pause camera
    [self.fastCamera stopRunning];
    
    self.capturedImage = capturedImage;
}

- (void)cameraController:(id<FastttCameraInterface>)cameraController didFinishNormalizingCapturedImage:(FastttCapturedImage *)capturedImage
{
    NSLog(@"Photos are ready");
    self.imagesReady = YES;
    [self.photoButton setEnabled:YES];
    
}

-(void)dismissConfirmController:(ConfirmController *)controller{
    //adding children VCs was causing xib's to be < full screen so just presenting/dimissing modallying
    
    //    [self fastttRemoveChildViewController:controller];
//    self.confirmController = nil;
}

-(void)imageConfirmed:(UIImage *)image{
    
    self.finishedImage = image;
    [self.delegate finalImage:image];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)retakePressed:(id)sender {
    
    if (self.killedFastCam) {
        self.previewImageView.image = nil;
        
        self.killedFastCam = NO;
        
        _fastCamera = [FastttCamera new];
        self.fastCamera.delegate = self;
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self fastttAddChildViewController:self.fastCamera];
            self.fastCamera.view.frame = CGRectMake(0, 75, self.previewImageView.frame.size.width, self.previewImageView.frame.size.height);
            self.fastCamera.cameraFlashMode = FastttCameraFlashModeOff;
        });
    }
    
    [self.photoButton setEnabled:YES];
    self.confirmMode = NO;
    self.imagesReady = NO;

    //switch buttons back
    self.switchButton.alpha = 0.0;
    [self.switchButton setHidden:NO];
    
    self.flashButton.alpha = 0.0;
    [self.flashButton setHidden:NO];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.photoButton setImage:[UIImage imageNamed:@"cameraIcon"] forState:UIControlStateNormal];
                         
                         [self.switchButton setAlpha:1.0];
                         [self.flashButton setAlpha:1.0];
                         
                         self.retakeButton.alpha = 0.0;
                         
                     }
                     completion:^(BOOL finished) {
                         [self.retakeButton setHidden:YES];
                     }];
    
    //restart camera
    [self.fastCamera startRunning];
}

-(void)comeBackToForeground{
    if (self.confirmMode) {
        [self.fastCamera stopRunning];
    }
}

-(void)wentBackground{
    if (self.confirmMode) {
        
        self.previewImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.previewImageView setImage:self.capturedImage.fullImage];
        
        self.killedFastCam = YES;
        [self.fastCamera.view removeFromSuperview];
        [self.fastCamera removeFromParentViewController];
        self.fastCamera = nil;
    }
}
@end
