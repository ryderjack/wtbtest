//
//  TOJRWebView.h
//  wtbtest
//
//  Created by Jack Ryder on 26/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <TOWebViewController/TOWebViewController.h>
#import "customAlertViewClass.h"

@class TOJRWebView;

@protocol JRWebViewDelegate <NSObject,UIAlertViewDelegate>
- (void)screeshotPressed:(UIImage *)screenshot withTaps:(int)taps;
- (void)cameraPressed;
- (void)paidPressed;
- (void)cancelWebPressed;

@end

@interface TOJRWebView : TOWebViewController <UIGestureRecognizerDelegate, customAlertDelegate>

//delegate
@property (nonatomic, weak) id <JRWebViewDelegate> delegate;

//Modes
@property (nonatomic) BOOL createMode;
@property (nonatomic) BOOL depopMode;
@property (nonatomic) BOOL editMode;
@property (nonatomic) BOOL balanceMode;
@property (nonatomic) BOOL payMode;


//update button
@property (nonatomic, strong) UIButton *longButton;
@property (nonatomic) BOOL buttonShowing;

//placeholder
@property (nonatomic, strong) UIImageView *placeholderView;

//count taps
@property (nonatomic) int tapCount;
@property (nonatomic) BOOL seenOneTapWarning;

//custom alert view
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic) BOOL alertShowing;


@end
