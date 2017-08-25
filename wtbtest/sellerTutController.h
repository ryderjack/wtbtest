//
//  sellerTutController.h
//  wtbtest
//
//  Created by Jack Ryder on 05/06/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>

@class sellerTutController;

@protocol sellerTutDelegate <NSObject>
- (void)completedSellerTut;
@end

@interface sellerTutController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *mainImageView;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;

@property (nonatomic) int pageIndex;

//delegate
@property (nonatomic, weak) id <sellerTutDelegate> delegate;

//big button
@property (nonatomic, strong) UIButton *longButton;
@property (nonatomic) BOOL buttonShowing;

@property (nonatomic, strong) PFObject *sellerApp;

//hud
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

//mode
@property (nonatomic) BOOL alreadySeen;

@end
