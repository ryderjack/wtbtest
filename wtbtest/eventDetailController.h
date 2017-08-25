//
//  eventDetailController.h
//  wtbtest
//
//  Created by Jack Ryder on 15/05/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "TOJRWebView.h"

@interface eventDetailController : UITableViewController <MKMapViewDelegate,JRWebViewDelegate>

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *bodyCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *mapCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *spaceCell;

//title cell
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UILabel *lowerTitleLabel;

//body cell
@property (weak, nonatomic) IBOutlet UIView *bodyView;
@property (weak, nonatomic) IBOutlet UITextView *bodyTextView;

//map cell
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

//big button
@property (nonatomic, strong) UIButton *longButton;
@property (nonatomic) BOOL buttonShowing;
@property (nonatomic) BOOL barButtonPressed;

//web view
@property (nonatomic, strong) TOJRWebView *webView;

//event setup
@property (nonatomic, strong) NSString *eventLink;
@property (nonatomic, strong) NSString *eventCopy;

@end
