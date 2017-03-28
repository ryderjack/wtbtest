//
//  UIImage+Resize.h
//  wtbtest
//
//  Created by Jack Ryder on 14/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resize)
- (UIImage *)croppedImage:(CGRect)bounds;

- (UIImage *)resizedImage:(CGSize)newSize
     interpolationQuality:(CGInterpolationQuality)quality;

- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality;

//aspect fill
- (UIImage *)scaleImageToSize:(CGSize)newSize;

//aspect fit
- (UIImage *)scaleImageToSizeFIT:(CGSize)newSize;

@end
