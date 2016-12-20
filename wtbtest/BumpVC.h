//
//  BumpVC.h
//  wtbtest
//
//  Created by Jack Ryder on 14/12/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface BumpVC : UIViewController

@property (weak, nonatomic) IBOutlet PFImageView *listingImageView;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UIButton *bumpButton;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (nonatomic, strong) NSString *listingID;
@property (nonatomic, strong) PFObject *listing;
@property (weak, nonatomic) IBOutlet UILabel *plusOneImageView;
@end
