//
//  ConfirmController.m
//  wtbtest
//
//  Created by Jack Ryder on 01/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ConfirmController.h"
@import AssetsLibrary;

@interface ConfirmController ()

@end

@implementation ConfirmController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.previewImage setImage:self.capturedImage.rotatedPreviewImage];
    self.previewImage.contentMode = UIViewContentModeScaleAspectFit;
    
    if (!self.capturedImage.isNormalized) {
        self.confirmButton.enabled = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
- (IBAction)confirmButtonPressed:(id)sender {
    //send image to create vc
    [self.delegate imageConfirmed:self.capturedImage.fullImage];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setImagesReady:(BOOL)imagesReady
{
    _imagesReady = imagesReady;
    if (imagesReady) {
        self.confirmButton.enabled = YES;
    }
}
- (void)savePhotoToCameraRoll
{
}
- (IBAction)backButtonPressed:(id)sender {
    [self.delegate dismissConfirmController:self];
}
@end
