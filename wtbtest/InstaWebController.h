//
//  InstaWebController.h
//  wtbtest
//
//  Created by Jack Ryder on 29/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InstaWebController : UIViewController
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) NSURL *url;
@end
