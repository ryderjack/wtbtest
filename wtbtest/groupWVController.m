//
//  groupWVController.m
//  
//
//  Created by Jack Ryder on 25/03/2016.
//
//

#import "groupWVController.h"

@interface groupWVController ()

@end

@implementation groupWVController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL *url = [NSURL URLWithString:self.groupURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:requestObj];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



@end
