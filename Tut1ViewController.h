//
//  Tut1ViewController.h
//  wtbtest
//
//  Created by Jack Ryder on 24/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "simpleCreateVC.h"

@interface Tut1ViewController : UIViewController <simpleCreateVCDelegate>

@property (assign, nonatomic) NSInteger index;
@property (weak, nonatomic) IBOutlet UIImageView *heroImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *cursorImageView;
@property (weak, nonatomic) IBOutlet UIImageView *screenImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sendOfferImageView;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (nonatomic) BOOL messageExplain;
@property (weak, nonatomic) IBOutlet UIButton *dimissButton;
@property (nonatomic) BOOL explainMode;
@property (nonatomic) BOOL clickMode;


//try bumping
@property (weak, nonatomic) IBOutlet UIImageView *topLeftImageView;
@property (weak, nonatomic) IBOutlet UIImageView *topRightImageView;
@property (weak, nonatomic) IBOutlet UIImageView *bottomLeftImageView;
@property (weak, nonatomic) IBOutlet UIImageView *bottomRightImageView;

@property (weak, nonatomic) IBOutlet PFImageView *itemTopLeftImageView;
@property (weak, nonatomic) IBOutlet PFImageView *itemTopRightImageView;
@property (weak, nonatomic) IBOutlet PFImageView *itemBottomLeftImageView;
@property (weak, nonatomic) IBOutlet PFImageView *itemBottomRightImageView;

@property (nonatomic, strong) NSMutableArray *listings;
@property (nonatomic, strong) PFObject *firstListing;
@property (nonatomic, strong) PFObject *secondListing;
@property (nonatomic, strong) PFObject *thirdListing;
@property (nonatomic, strong) PFObject *fourthListing;

@property (nonatomic, strong) NSString *pushText;

@property (nonatomic) int bumpCount;

@end
