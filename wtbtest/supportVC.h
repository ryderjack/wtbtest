//
//  supportVC.h
//  wtbtest
//
//  Created by Jack Ryder on 10/03/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MBProgressHUD.h>
#import <SpinKit/RTSpinKitView.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <MessageUI/MessageUI.h>

@interface supportVC : UITableViewController

@property (nonatomic, strong) NSArray *resultArray;

//modes
@property (nonatomic) BOOL tier1Mode;
@property (nonatomic, strong) PFObject *supportObject;

//hud
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

@end
