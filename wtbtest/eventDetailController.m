//
//  eventDetailController.m
//  wtbtest
//
//  Created by Jack Ryder on 15/05/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "eventDetailController.h"
#import "NavigationController.h"
#import "customMapPin.h"
#import <Crashlytics/Crashlytics.h>

@interface eventDetailController ()

@end

@implementation eventDetailController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.bodyCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.mapCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.spaceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.lowerTitleLabel.adjustsFontSizeToFitWidth = YES;
    self.lowerTitleLabel.minimumScaleFactor=0.5;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    [self.bodyView.layer setCornerRadius:20.0];
    
    self.mapView.delegate = self;
    
    if (![self.eventCopy isEqualToString:@""]) {
        [self.bodyTextView setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:14]];
        self.bodyTextView.text = self.eventCopy;
    }

    //51.520735, -0.073091 = Truman Brewery
    CLLocationCoordinate2D eventLoc = CLLocationCoordinate2DMake(51.520735, -0.073091);
    
    customMapPin *customAnnotation = [[customMapPin alloc]initWithLocation:eventLoc];
    [self.mapView addAnnotation:customAnnotation];

    MKCoordinateRegion region;
    region.center = eventLoc;
    MKCoordinateSpan span;
    span.latitudeDelta  = 0.01; // Change these values to change the zoom
    span.longitudeDelta = 0.01;
    region.span = span;

    [self.mapView setRegion:region animated:YES];
    
    //bar button setup
    self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-80, [UIApplication sharedApplication].keyWindow.frame.size.width, 80)];
    [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:13]];
    
    //make shift title
    UILabel *newTitleLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.longButton.frame.size.width/2)-50, 20, 100, 30)];
    [newTitleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
    newTitleLabel.text = @"T I C K E T S";
    newTitleLabel.textAlignment = NSTextAlignmentCenter;
    [newTitleLabel setTextColor:[UIColor whiteColor]];
    [self.longButton addSubview:newTitleLabel];
    
    UIImageView *eventImageView = [[UIImageView alloc]initWithFrame:CGRectMake((self.longButton.frame.size.width/2)-30, newTitleLabel.frame.origin.y+30, 60, 10)];
    [eventImageView setImage:[UIImage imageNamed:@"eventbrite"]];
    [self.longButton addSubview:eventImageView];
    
    [self.longButton setBackgroundColor:[UIColor colorWithRed:1.00 green:0.47 blue:0.00 alpha:1.0]];
    [self.longButton addTarget:self action:@selector(barPressed) forControlEvents:UIControlEventTouchUpInside];
    self.longButton.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    self.bodyTextView.editable = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (self.buttonShowing == NO) {
        [self showBarButton];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self hideBarButton];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    if (self.barButtonPressed != YES) {
        self.longButton = nil;
    }
}

-(void)hideBarButton{
    self.buttonShowing = NO;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)showBarButton{
    self.buttonShowing = YES;
    self.longButton.alpha = 0.0f;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.longButton.alpha = 1.0f;
                         [self.longButton setEnabled:YES];
                     }
                     completion:^(BOOL finished) {
                     }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.titleCell;
        }
        else if (indexPath.row == 1) {
            return self.bodyCell;
        }
        else if (indexPath.row == 2) {
            return self.mapCell;
        }
        else if (indexPath.row == 3) {
            return self.spaceCell;
        }
    }
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 119;
        }
        else if (indexPath.row == 1) {
            return 309;
        }
        else if (indexPath.row == 2) {
            return 167;
        }
        else if (indexPath.row == 3) {
            return 80;
        }
    }
    return 44;
}

-(void)barPressed{
    
    [Answers logCustomEventWithName:@"Get CC Tickets Pressed"
                   customAttributes:@{}];
    
    self.barButtonPressed = YES;
    [self.longButton setEnabled:NO];
    
    //open webview
    self.webView = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:self.eventLink]];
    self.webView.title = @"C C  S 1 7";
    self.webView.showUrlWhileLoading = YES;
    self.webView.showPageTitles = NO;
    self.webView.doneButtonTitle = @"";
    self.webView.payMode = NO;
    self.webView.infoMode = NO;
    self.webView.delegate = self;
    
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.webView];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)cancelWebPressed{
    [self.webView dismissViewControllerAnimated:YES completion:nil];
}

-(void)screeshotPressed:(UIImage *)screenshot withTaps:(int)taps{
}

-(void)cameraPressed{
}

-(void)paidPressed{
}

- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    if ([annotation isKindOfClass:[customMapPin class]]) {
        
        customMapPin *customPin = (customMapPin *)annotation;
        MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"custom"];
        
        if (annotationView == nil) {
            annotationView = customPin.annotationView;
        }
        else{
            annotationView.annotation = annotation;
        }
        return annotationView;
    }
    else{
        return nil;
    }
}


@end
