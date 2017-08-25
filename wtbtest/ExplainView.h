//
//  ExplainView.h
//  wtbtest
//
//  Created by Jack Ryder on 11/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "customAlertViewClass.h"

@interface ExplainView : UITableViewController <customAlertDelegate>

@property (strong, nonatomic) IBOutlet UITableViewCell *mainCell;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *higherNextButton;

//mode
@property (nonatomic) BOOL introMode;
@property (nonatomic) BOOL changedMode;
@property (nonatomic) BOOL buyingIntro;
@property (nonatomic) BOOL sellingIntro;
@property (nonatomic) BOOL emailIntro;


//helper VC mode
@property (nonatomic) BOOL picAndTextMode;
@property (nonatomic, strong) NSString *titleString;
@property (nonatomic, strong) NSString *mainLabelText;
@property (nonatomic, strong) UIImage *heroImage;

//cancel button
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

//welcome back views
@property (weak, nonatomic) IBOutlet UILabel *welcomeBackLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

//explain views
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *firstImageView;
@property (weak, nonatomic) IBOutlet UILabel *firstLabel;
@property (weak, nonatomic) IBOutlet UIImageView *secondImageView;
@property (weak, nonatomic) IBOutlet UILabel *secondLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thirdImageView;
@property (weak, nonatomic) IBOutlet UILabel *thirdLabel;

//custom alert view
@property (nonatomic, strong) customAlertViewClass *customAlert;
@property (nonatomic, strong) UIView *searchBgView;
@property (nonatomic) BOOL shownPushAlert;

@end
