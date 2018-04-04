//
//  supportAnswerVC.h
//  wtbtest
//
//  Created by Jack Ryder on 10/03/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <MBProgressHUD.h>
#import <SpinKit/RTSpinKitView.h>

@interface supportAnswerVC : UITableViewController
@property (strong, nonatomic) IBOutlet UITableViewCell *mainCell;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;

//content objects
@property (nonatomic, strong) PFObject *supportObject;
@property (nonatomic, strong) PFObject *answerObject;

//content mode (from order summary we sometimes just want to load the shipping answer)
@property (nonatomic) BOOL showShippingAnswer;

//long button
@property (nonatomic, strong) UIButton *longButton;
@property (nonatomic) BOOL longShowing;
@property (nonatomic) BOOL messageMode;

//hud
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

@end
