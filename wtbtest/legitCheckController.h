//
//  legitCheckController.h
//  wtbtest
//
//  Created by Jack Ryder on 02/06/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QBImagePickerController/QBImagePickerController.h>
#import "AddImageCell.h"
#import <LXReorderableCollectionViewFlowLayout.h>
#import <Parse/Parse.h>
#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD.h>

@class legitCheckController;

@protocol legitDelegate <NSObject>
- (void)completedLegitVC;
@end

@interface legitCheckController : UITableViewController <QBImagePickerControllerDelegate,UICollectionViewDelegate, LXReorderableCollectionViewDataSource,LXReorderableCollectionViewDelegateFlowLayout,AddImageCellDelegate,UITextViewDelegate>

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *topCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *imageCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *infoCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *spaceCell;

//delegate
@property (nonatomic, weak) id <legitDelegate> delegate;

//top cell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

//img cell
@property (weak, nonatomic) IBOutlet UICollectionView *imgCollectionView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSMutableArray *filesArray;
@property (nonatomic) int cellWidth;

//info cell
@property (weak, nonatomic) IBOutlet UITextView *infoTextView;

//camera buttons
@property (nonatomic, strong) UIButton *firstCam;
@property (nonatomic, strong) UIButton *secondCam;
@property (nonatomic, strong) UIButton *thirdCam;
@property (nonatomic, strong) UIButton *fourthCam;
@property (nonatomic) int camButtonTapped;

//add images
@property (nonatomic) BOOL multipleMode;
@property (nonatomic, strong) NSMutableArray *imagesToProcess;
@property (nonatomic, strong) NSMutableArray *placeholderAssetArray;
@property (nonatomic) int photostotal;
@property (nonatomic) BOOL somethingChanged;
@property (nonatomic) BOOL textEntered;

//big button
@property (nonatomic, strong) UIButton *longButton;
@property (nonatomic) BOOL buttonShowing;
@property (nonatomic) BOOL barButtonPressed;

//location
@property (strong, nonatomic) PFGeoPoint *geopoint;

//application Obj
@property (nonatomic, strong) PFObject *sellerApp;

//hud
@property (nonatomic, strong) RTSpinKitView *spinner;
@property (nonatomic, strong) MBProgressHUD *hud;

@end
