//
//  CreateViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 25/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "CreateViewController.h"
#import "NavigationController.h"
#import <Crashlytics/Crashlytics.h>
#import "WelcomeViewController.h"
#import "UIImage+Resize.h"
#import "ForSaleCell.h"
#import "ForSaleListing.h"
#import "FBGroupShareViewController.h"
#import "AppDelegate.h"

@interface CreateViewController ()

@end

@implementation CreateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"C R E A T E";
    
    //hide first table view header
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    self.tapNumber = 0;
        
    //button setup
    [self.firstCam setEnabled:YES];
    [self.secondCam setEnabled:NO];
    [self.thirdCam setEnabled:NO];
    [self.fourthCam setEnabled:NO];
    
    self.somethingChanged = NO;
    self.shouldSave = NO;
    
    self.payField.placeholder = @"";
    
    self.imagesToProcess = [NSMutableArray array];
    self.filesArray = [NSMutableArray array];
    self.placeholderAssetArray = [NSMutableArray array];
    
    self.photostotal = 0;
    self.titleField.delegate = self;
    self.extraField.delegate = self;
    self.payField.delegate = self;
    
    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.picCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.payCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.spaceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.imageCell.selectionStyle = UITableViewCellSelectionStyleNone;

    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    //collection view setup
    [self.imgCollectionView registerClass:[AddImageCell class] forCellWithReuseIdentifier:@"Cell"];
    UINib *cellNib = [UINib nibWithNibName:@"AddImageCell" bundle:nil];
    [self.imgCollectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    
    if([ [ UIScreen mainScreen ] bounds ].size.height == 736){
        //iphone 7 plus
        self.cellWidth = 90;
    }
    else{
        //iPhone 7
        self.cellWidth = 82;
    }
    
    LXReorderableCollectionViewFlowLayout *flowLayout = [[LXReorderableCollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(self.cellWidth,self.cellWidth)];
    [flowLayout setMinimumInteritemSpacing:0];
    [flowLayout setMinimumLineSpacing:10.0];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [self.imgCollectionView setCollectionViewLayout:flowLayout];
    
    [self.imgCollectionView setScrollEnabled:YES];
    self.imgCollectionView.alwaysBounceHorizontal = YES;

    self.locationString = @"";
    self.warningLabel.text = @"";
    self.genderSize = @"";
    self.firstSize = @"";
    self.secondSize = @"";
    self.thirdSize = @"";
    
    //add details is when user taps to add more info after posting
    if (self.editFromListing == YES || self.addDetails == YES) {
        [self resetAll];
        [self listingSetup];
        
        self.navigationItem.hidesBackButton = YES;
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cancelCross"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        
//        UIBarButtonItem *updateButton = [[UIBarButtonItem alloc] initWithTitle:@"Update" style:UIBarButtonItemStylePlain target:self action:@selector(wantobuyPressed:)];
//        self.navigationItem.rightBarButtonItem = updateButton;
    }
    
    //add done button to number pad keyboard on pay field
    [self addDoneButton];
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.profanityList = @[@"fuck",@"fucking",@"shitting", @"cunt", @"sex", @"wanker", @"nigger", @"penis", @"cock", @"shit", @"dick", @"bastard"];
    
    if (self.introMode != YES) {
        self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
        [self.longButton setTitle:@"U P D A T E" forState:UIControlStateNormal];
        [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
        [self.longButton addTarget:self action:@selector(wantobuyPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.longButton.alpha = 0.0f;
        [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.longButton.alpha = 1.0f;
                         }
                         completion:^(BOOL finished) {
                             self.buttonShowing = YES;
                         }];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    
    //sam & jack code only
    if ([[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"]|| [[PFUser currentUser].objectId isEqualToString:@"IIEf7cUvrO"]) {
        
        if ([[NSUserDefaults standardUserDefaults]boolForKey:@"listMode"]==YES) {
            NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:@"listUser"];
            
            PFQuery *userQ = [PFUser query];
            [userQ whereKey:@"objectId" equalTo:userID];
            [userQ getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    self.listAsUser = (PFUser *)object;
                    self.listingAsMode = YES;
                }
                else{
                    NSLog(@"error getting user %@", error);
                }
            }];
        }
        else{
            self.listingAsMode = NO;
        }
    }
    
    if (self.introMode == YES && self.buttonShowing == NO && !self.longButton) {
        self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
        [self.longButton setTitle:@"U P D A T E" forState:UIControlStateNormal];
        [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
        [self.longButton addTarget:self action:@selector(wantobuyPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.longButton.alpha = 0.0f;
        [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.longButton.alpha = 1.0f;
                         }
                         completion:^(BOOL finished) {
                             self.buttonShowing = YES;
                         }];
    }
    
    else if (self.buttonShowing == NO) {
        self.longButton.alpha = 0.0f;
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.longButton.alpha = 1.0f;
                         }
                         completion:^(BOOL finished) {
                             self.buttonShowing = YES;
                         }];
    }
    
    if (![PFUser currentUser]) {
        WelcomeViewController *vc = [[WelcomeViewController alloc]init];
        NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else{
        self.currency = [[PFUser currentUser]objectForKey:@"currency"];
        if ([self.currency isEqualToString:@"GBP"]) {
            self.currencySymbol = @"£";
            self.payField.placeholder = @"£100";
        }
        else if ([self.currency isEqualToString:@"EUR"]) {
            self.currencySymbol = @"€";
            self.payField.placeholder = @"€100";
        }
        else if ([self.currency isEqualToString:@"USD"] || [self.currency isEqualToString:@"AUD"]) {
            self.currencySymbol = @"$";
            self.payField.placeholder = @"$100";
        }
    }
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Edit Listing"
                                      }];
    
    if (self.shouldShowHUD == YES) {
        [self showHUD];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0){
        return 1;
    }
    else if (section == 1){
        return 1;
    }
    else if (section == 2){
        return 3;
    }
    else if (section == 3){
        return 1;
    }
    else{
        return 0;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.titleCell;
        }
    }
    else if (indexPath.section ==1){
        if(indexPath.row == 0){
            return self.imageCell;
        }
    }
    else if (indexPath.section ==2){
        if(indexPath.row == 0){
                return self.condCell;
        }
        else if(indexPath.row == 1){
            return self.catCell;
        }
        else if(indexPath.row == 2){
            return self.sizeCell;
        }
//        else if(indexPath.row == 3){
//            return self.locCell;
//        }
//        else if(indexPath.row == 4){
//            return self.payCell;
//        }
    }
    //add extra cell to ensure 'UPDATE' button doesn't cover footer of last section
    else if (indexPath.section ==3){
        if(indexPath.row == 0){
            return self.spaceCell;
        }
    }

    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 81;
        }
    }
    else if (indexPath.section ==1){
        if(indexPath.row == 0){
            return 104;
        }
    }
    else if (indexPath.section ==2){
        return 44;
    }
    else if (indexPath.section ==3){
        return 60;
    }
    return 44;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    self.somethingChanged = YES;
    
    [self removeKeyboard];
    
    if (indexPath.section ==2){
        if(indexPath.row == 0){
            SelectViewController *vc = [[SelectViewController alloc]init];
            vc.delegate = self;
            vc.setting = @"condition";
            self.selection = @"condition";
            
            if (![self.chooseCondition.text isEqualToString:@"Optional"]) {
                NSArray *selectedArray = [self.chooseCondition.text componentsSeparatedByString:@"."];
                
                NSMutableArray *placeholder = [NSMutableArray arrayWithArray:selectedArray];
                int i = 0;
                
                for (NSString *condition in selectedArray) {
                    if ([condition isEqualToString:@"BNWT"]) {
                        [placeholder replaceObjectAtIndex:i withObject:@"Brand New With Tags"];
                    }
                    else if ([condition isEqualToString:@"BNWOT"]) {
                        [placeholder replaceObjectAtIndex:i withObject:@"Brand New Without Tags"];
                    }
                    i++;
                }
                
                vc.holdingArray = [NSArray arrayWithArray:placeholder];
            }
            [self.navigationController pushViewController:vc animated:YES];

        }
        else if(indexPath.row == 1){
            SelectViewController *vc = [[SelectViewController alloc]init];
            vc.delegate = self;
            vc.setting = @"category";
            self.selection = @"category";
            
            if (![self.chooseCategroy.text isEqualToString:@"Optional"]) {
                NSArray *selectedArray = [self.chooseCategroy.text componentsSeparatedByString:@"."];
                vc.holdingArray = [NSArray arrayWithArray:selectedArray];
            }
            
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if(indexPath.row == 2){
            if ([self.chooseCategroy.text isEqualToString:@"Optional"]) {
                [self sizePopUp];
                [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            }
            else{
                if ([self.chooseCategroy.text isEqualToString:@"Footwear"]) {
                    SelectViewController *vc = [[SelectViewController alloc]init];
                    vc.delegate = self;
                    vc.setting = @"sizefoot";
                    
                    // setup previously selected
                    if (![self.chooseSize.text isEqualToString:@"Optional"]) {
                        NSArray *selectedArray = [self.chooseSize.text componentsSeparatedByString:@"/"];

                        vc.holdingArray = [NSArray arrayWithArray:selectedArray];
                        vc.holdingGender = [[NSString alloc]initWithString:self.genderSize];
                    }
                    else{
                        vc.holdingGender = @"";
                    }
                    
                    self.selection = @"size";
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else if ([self.chooseCategroy.text isEqualToString:@"Clothing"]){
                    SelectViewController *vc = [[SelectViewController alloc]init];
                    vc.delegate = self;
                    vc.setting = @"sizeclothing";
                    
                    // setup previously selected
                    if (![self.chooseSize.text isEqualToString:@"Optional"]) {
                        NSArray *selectedArray = [self.chooseSize.text componentsSeparatedByString:@"/"];
                        vc.holdingArray = [NSArray arrayWithArray:selectedArray];
                    }
                    
                    self.selection = @"size";
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else if ([self.chooseCategroy.text isEqualToString:@"Accessories"]){
                    // can't select accessory sizing for now
                }
                else{
                    SelectViewController *vc = [[SelectViewController alloc]init];
                    vc.delegate = self;
                    vc.setting = @"sizeclothing";
                    
                    // setup previously selected
                    if (![self.chooseSize.text isEqualToString:@"Optional"]) {
                        NSArray *selectedArray = [self.chooseSize.text componentsSeparatedByString:@"/"];
                        vc.holdingArray = [NSArray arrayWithArray:selectedArray];
                    }
                    
                    self.selection = @"size";
                    [self.navigationController pushViewController:vc animated:YES];
                }
            }
        }
        else if(indexPath.row == 3){
            LocationView *vc = [[LocationView alloc]init];
            vc.delegate = self;
            self.selection = @"location";
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

//hide the first header in table view
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 1.0f;
    return 32.0f;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    header.textLabel.textColor = [UIColor grayColor];
    header.textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    CGRect headerFrame = header.frame;
    header.textLabel.frame = headerFrame;
    header.contentView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
}

-(void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section{
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;

    footer.textLabel.textColor = [UIColor lightGrayColor];
    footer.textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:10];
    CGRect footerFrame = footer.frame;
    footer.textLabel.frame = footerFrame;
    footer.contentView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
}

- (NSString*) tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    }
    else if (section ==1){
        return @"Add photos of the item you’d like to buy";
    }
    else if (section ==2){
        return @"Add extra info to your listing";
    }
    else {
        return @"";
    }
}
-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
//    if (section == 2) {
//        return @"Pro Tip: an accurate Budget = interested sellers";
//    }
//    else{
        return @"";
//    }
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section == 3) {
        return 0.0;
    }
    return 32.0f;
}

#pragma mark - Text field/view delegate methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    self.somethingChanged = YES;
    if (textField == self.payField) {
        self.payField.text = [NSString stringWithFormat:@"%@", self.currencySymbol];
    }
}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@"Leave blank if none"]) {
        textView.text = @"";
        textView.textColor = [UIColor colorWithRed:74/255.0f green:74/255.0f blue:74/255.0f alpha:1.0f];
    }
    else{
        self.somethingChanged = YES;
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.titleField) {
        NSArray *words = [textField.text componentsSeparatedByString:@" "];
        for (NSString *string in words) {
            if ([self.profanityList containsObject:string.lowercaseString]) {
                textField.text = @"";
            }
        }
    }
    else if (textField == self.payField){
        if ([textField.text isEqualToString:[NSString stringWithFormat:@"%@", self.currencySymbol]]) {
            textField.text = @"Optional";
        }
    }
}
-(void)textViewDidEndEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"Leave blank if none";
        textView.textColor = [UIColor lightGrayColor];
    }
    else{
        //they've wrote something so do the check for profanity
        NSArray *words = [textView.text componentsSeparatedByString:@" "];
        for (NSString *string in words) {
            if ([self.profanityList containsObject:string.lowercaseString]) {
                textView.text = @"Leave blank if none";
                textView.textColor = [UIColor lightGrayColor];
            }
        }
    }
}

//return key removes keyboard in text view
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

-(void)removeKeyboard{
    [self.titleField resignFirstResponder];
    [self.extraField resignFirstResponder];
    [self.payField resignFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.payField) {
        // Check for deletion of the currency sign
        if (range.location == 0 && [textField.text hasPrefix:[NSString stringWithFormat:@"%@", self.currencySymbol]])
            return NO;
        
        NSString *updatedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray *stringsArray = [updatedText componentsSeparatedByString:@"."];
        
        // Check for an absurdly large amount & 0
        if (stringsArray.count > 0)
        {
            NSString *dollarAmount = stringsArray[0];
            
            if ([dollarAmount isEqualToString:[NSString stringWithFormat:@"%@0", self.currencySymbol]]) {
                [self showAlertWithTitle:@"Enter a valid price" andMsg:@"Pro Tip: a more accurate price 99leads to more sellers getting in touch!"];
                return NO;
            }

            if (dollarAmount.length > 5)
                return NO;
            // not allowed to enter all 9s
            if ([dollarAmount isEqualToString:[NSString stringWithFormat:@"%@9999", self.currencySymbol]]) {
                return NO;
            }
        } //add check for #1 to before save
        
        return YES;
    }
    else if(textField == self.titleField){
        if(range.length + range.location > textField.text.length)
        {
            return NO;
        }
        
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return newLength <= 50;
    }
    return YES;
}
-(void)alertSheet{
    self.somethingChanged = YES;
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Search Google" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Add image from Google"
                       customAttributes:@{
                                          @"where":@"edit"
                                          }];
        if ([self.titleField.text isEqualToString:@""]) {
            [self popUpAlert];
        }
        
        [self showGoogle]; // don't need instructions - will be on the JRWebView if needed
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Choose from library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Choose pictures tapped"
                       customAttributes:@{
                                          @"where":@"edit"
                                          }];
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            switch (status) {
                case PHAuthorizationStatusAuthorized:{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        QBImagePickerController *imagePickerController = [QBImagePickerController new];
                        imagePickerController.delegate = self;
                        imagePickerController.allowsMultipleSelection = YES;
                        imagePickerController.maximumNumberOfSelection = 4-self.photostotal;
                        imagePickerController.mediaType = QBImagePickerMediaTypeImage;
                        imagePickerController.numberOfColumnsInPortrait = 4;
                        imagePickerController.showsNumberOfSelectedAssets = YES;
                        [self.navigationController presentViewController:imagePickerController animated:YES completion:NULL];
                    });
                }
                    break;
                case PHAuthorizationStatusRestricted:{
                    NSLog(@"restricted");
                }
                    break;
                case PHAuthorizationStatusDenied:
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //show alert
                        [self showAlertWithTitle:@"Library Permission" andMsg:@"Bump needs access to your photos to create a listing, enable this in your iPhone's Settings"];
                    });
                    NSLog(@"denied");
                }
                    break;
                default:
                    break;
            }
        }];
//        if (!self.picker) {
//            self.picker = [[UIImagePickerController alloc] init];
//            self.picker.delegate = self;
//            self.picker.allowsEditing = NO;
//            self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//        }
//        [self presentViewController:self.picker animated:YES completion:nil];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Take a picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Take a picture tapped"
                       customAttributes:@{
                                          @"where":@"edit"
                                          }];
        CameraController *vc = [[CameraController alloc]init];
        vc.delegate = self;
        vc.offerMode = NO;
        self.shouldSave = YES;
        [self presentViewController:vc animated:YES completion:nil];
    }]];
    

    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    [imagePickerController dismissViewControllerAnimated:YES completion:^{
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        requestOptions.networkAccessAllowed = YES;
        
        PHImageManager *manager = [PHImageManager defaultManager];
        
        [self.placeholderAssetArray removeAllObjects];
        [self.imagesToProcess removeAllObjects];
        
        for (PHAsset *asset in assets) {
            //goto cropper
            [manager requestImageForAsset:asset
                               targetSize:PHImageManagerMaximumSize
                              contentMode:PHImageContentModeDefault
                                  options:requestOptions
                            resultHandler:^void(UIImage *image, NSDictionary *info) {
                                
                                //new policy: all resizing done in finalImage, instead of scattered
                                [self.imagesToProcess addObject:image];
                                [self.placeholderAssetArray addObject:asset];

                                if (self.imagesToProcess.count == assets.count) {
                                    
                                    //to keep track of reorder
                                    NSMutableArray *placeholder = [NSMutableArray array];
                                    NSMutableArray *imagesPlaceholder = [NSMutableArray array];

                                    //reorder to match OG selection order - gets jumbled coz some assets are converted to UIImages faster
                            
                                    //coz we can't compare assets and images we have to compare the correct order of assets with a placeholder array of assets which are in the jumbled order
                                    //also coz images are in the same order as these jumbled assets we can use the indexes of the assets to reorder the images too
                                    
                                    for (PHAsset *orderedAsset in assets) {
                                        
                                        for (PHAsset *asset in self.placeholderAssetArray) {

                                            if ([asset.localIdentifier isEqualToString:orderedAsset.localIdentifier]) {
                                                
                                                [placeholder addObject:asset];
                                                
                                                NSUInteger indexOfAsset = [self.placeholderAssetArray indexOfObject:asset];
                                                [imagesPlaceholder addObject:self.imagesToProcess[indexOfAsset]];
                                                break;
                                            }
                                        }
                                    }
                                    
//                                    NSLog(@"CORRECT ORDER: %@", assets);
//                                    NSLog(@"AFTER SORT: %@", placeholder);

                                    //update ordered images array
                                    self.imagesToProcess = imagesPlaceholder;
                                    
                                    [self processMultiple];
                                }
                            }];
        }
        
    }];
}

- (BOOL)image:(UIImage *)image1 isEqualTo:(UIImage *)image2
{
    NSData *data1 = UIImagePNGRepresentation(image1);
    NSData *data2 = UIImagePNGRepresentation(image2);
    
    return [data1 isEqual:data2];
}

-(void)processMultiple{
    //got array of images to crop
    self.multipleMode = YES;
    
    if (self.imagesToProcess.count > 0) {
        [self displayCropperWithImage:self.imagesToProcess[0]];
    }
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [imagePickerController dismissViewControllerAnimated:YES completion:NULL];
}



-(void)showGoogle{
    NSString *searchString = [self.titleField.text stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSString *URLString = [NSString stringWithFormat:@"https://www.google.co.uk/search?tbm=isch&q=%@&tbs=iar:s#imgrc=_",searchString];
    self.webViewController = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
    self.webViewController.title = [NSString stringWithFormat:@"%@", self.titleField.text];
    self.webViewController.showUrlWhileLoading = NO;
    self.webViewController.showPageTitles = NO;
    self.webViewController.delegate = self;
    self.webViewController.editMode = YES;
    self.webViewController.doneButtonTitle = @"";
//    self.webViewController.infoMode = NO;
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.webViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)paidPressed{
    //do nothing
}

-(void)cameraPressed{
    //do nothing
}

-(void)cancelWebPressed{
    [self.webViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)screeshotPressed:(UIImage *)screenshot withTaps:(int)taps{
    self.tapNumber = taps;
    [self.webViewController dismissViewControllerAnimated:YES completion:^{
        [self displayCropperWithImage:screenshot];
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(nonnull NSDictionary<NSString *,id> *)info{
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    //display crop picker
    [picker dismissViewControllerAnimated:YES completion:^{
        [self displayCropperWithImage:chosenImage];
    }];
}

-(void)displayCropperWithImage:(UIImage *)image{
    BASSquareCropperViewController *squareCropperViewController = [[BASSquareCropperViewController alloc] initWithImage:image minimumCroppedImageSideLength:375.0f];
    squareCropperViewController.squareCropperDelegate = self;
    squareCropperViewController.backgroundColor = [UIColor whiteColor];
    squareCropperViewController.borderColor = [UIColor whiteColor];
    squareCropperViewController.doneFont = [UIFont fontWithName:@"PingFangSC-Regular" size:18.0f];
    squareCropperViewController.cancelFont = [UIFont fontWithName:@"PingFangSC-Regular" size:16.0f];
    squareCropperViewController.excludedBackgroundColor = [UIColor blackColor];
//    squareCropperViewController.tapNumber = self.tapNumber;
    [self.navigationController presentViewController:squareCropperViewController animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)squareCropperDidCropImage:(UIImage *)croppedImage inCropper:(BASSquareCropperViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
    
    [self finalImage:croppedImage];
}

- (void)squareCropperDidCancelCropInCropper:(BASSquareCropperViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
    
    if (self.multipleMode == YES && self.imagesToProcess.count > 1) {
        [self.imagesToProcess removeObjectAtIndex:0];
        [self processMultiple];
    }
}

-(void)popUpAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Enter a title" message:@"Make sure you've entered a title for your listing!" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)sizePopUp{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Choose a category first" message:@"Make sure you've entered a category for your listing!" preferredStyle:UIAlertControllerStyleAlert];
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)locationPopUp{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Location error" message:@"Please choose a different location!" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

#pragma camera buttons

- (IBAction)firstCamPressed:(id)sender{
    
    if (self.firstCam.enabled == YES) {
        self.camButtonTapped = 1;
        [self alertSheet];        
    }
}
- (IBAction)secondCamPressed:(id)sender{

    if (self.secondCam.enabled == YES) {
        //show action sheet for either picker, library or web (eventually)
        self.camButtonTapped = 2;
        [self alertSheet];
    }
}
- (IBAction)thirdPressed:(id)sender {

    if (self.thirdCam.enabled == YES) {
        //show action sheet for either picker, library or web (eventually)
        self.camButtonTapped = 3;
        [self alertSheet];
    }
}
- (IBAction)fourthCamPressed:(id)sender {

    if (self.fourthCam.enabled == YES) {
        //show action sheet for either picker, library or web (eventually)
        self.camButtonTapped = 4;
        [self alertSheet];
    }
}

#pragma delegate callbacks

-(void)addItemViewController:(SelectViewController *)controller didFinishEnteringItem:(NSString *)selectionString withgender:(NSString *)genderString andsizes:(NSArray *)array{
    
    if ([selectionString isEqualToString:@""]) {
        selectionString = @"Optional";
    }
    
    if ([self.selection isEqualToString:@"condition"]) {
        if ([selectionString isEqualToString:@"Brand New With Tags"]) {
            selectionString = @"BNWT";
        }
        else if ([selectionString isEqualToString:@"Brand New Without Tags"]) {
            selectionString = @"BNWOT";
        }
        self.chooseCondition.text = selectionString;
    }
    else if ([self.selection isEqualToString:@"category"]){
        self.chooseCategroy.text = @"Optional";
        
        if ([selectionString isEqualToString:@"Accessories"]) {
            self.chooseSize.text = @"";
        }
        else{
            self.chooseSize.text = @"Optional";
        }
        self.chooseCategroy.text = selectionString;
    }
    else if ([self.selection isEqualToString:@"size"]){
        if (genderString) {
            self.genderSize = genderString;
        }
        self.chooseSize.text = @"Optional";
        
        if (array) {
            self.sizesArray = [NSArray arrayWithArray:array];
            
            if (self.sizesArray.count == 1) {
                if ([self.sizesArray[0] isKindOfClass:[NSString class]]) {
                    if ([self.sizesArray[0] isEqualToString:@"Any"]) {
                        self.chooseSize.text = @"Any";
                    }
                    else if ([self.sizesArray[0] isEqualToString:@"XXL"] || [self.sizesArray[0] isEqualToString:@"XS"] || [self.sizesArray[0] isEqualToString:@"XXS"] || [self.sizesArray[0] isEqualToString:@"XL"] || [self.sizesArray[0] isEqualToString:@"S"] || [self.sizesArray[0] isEqualToString:@"M"] ||[self.sizesArray[0] isEqualToString:@"L"]){
                        //its a clothing size
                        self.chooseSize.text = [NSString stringWithFormat:@"%@",self.sizesArray[0]];
                    }
                    else{
                        //its a shoe size so show the country
                        self.chooseSize.text = [NSString stringWithFormat:@"UK %@",self.sizesArray[0]];
                    }
                }
                else{
                    //not a string so probs a shoe size
                    self.chooseSize.text = [NSString stringWithFormat:@"UK %@",self.sizesArray[0]];
                }
                self.firstSize = [NSString stringWithFormat:@"%@",self.sizesArray[0]];
                self.secondSize = @"";
                self.thirdSize = @"";
            }
            else if (self.sizesArray.count == 2){
                if ([self.sizesArray[0] isKindOfClass:[NSString class]]) {
                    if ([self.sizesArray[0] isEqualToString:@"XXL"] || [self.sizesArray[0] isEqualToString:@"XS"] || [self.sizesArray[0] isEqualToString:@"XXS"] || [self.sizesArray[0] isEqualToString:@"XL"] || [self.sizesArray[0] isEqualToString:@"S"] || [self.sizesArray[0] isEqualToString:@"M"] ||[self.sizesArray[0] isEqualToString:@"L"]){
                        self.chooseSize.text = [NSString stringWithFormat:@"%@/%@",self.sizesArray[0],self.sizesArray[1]];
                    }
                    else{
                        self.chooseSize.text = [NSString stringWithFormat:@"UK %@/%@",self.sizesArray[0],self.sizesArray[1]];
                    }
                }
                else{
                    self.chooseSize.text = [NSString stringWithFormat:@"UK %@/%@",self.sizesArray[0],self.sizesArray[1]];
                }
                
                self.firstSize = [NSString stringWithFormat:@"%@",self.sizesArray[0]];
                self.secondSize = [NSString stringWithFormat:@"%@",self.sizesArray[1]];
                self.thirdSize = @"";
            }
            else if (self.sizesArray.count == 3){
                if ([self.sizesArray[0] isKindOfClass:[NSString class]]) {
                    if ([self.sizesArray[0] isEqualToString:@"XXL"] || [self.sizesArray[0] isEqualToString:@"XS"] || [self.sizesArray[0] isEqualToString:@"XXS"] || [self.sizesArray[0] isEqualToString:@"XL"] || [self.sizesArray[0] isEqualToString:@"S"] || [self.sizesArray[0] isEqualToString:@"M"] ||[self.sizesArray[0] isEqualToString:@"L"]){
                        self.chooseSize.text = [NSString stringWithFormat:@"%@/%@/%@",self.sizesArray[0],self.sizesArray[1],self.sizesArray[2]];
                    }
                    else{
                        self.chooseSize.text = [NSString stringWithFormat:@"UK %@/%@/%@",self.sizesArray[0],self.sizesArray[1],self.sizesArray[2]];
                    }
                }
                else{
                    self.chooseSize.text = [NSString stringWithFormat:@"UK %@/%@/%@",self.sizesArray[0],self.sizesArray[1],self.sizesArray[2]];
                }
            
                self.firstSize = [NSString stringWithFormat:@"%@",self.sizesArray[0]];
                self.secondSize = [NSString stringWithFormat:@"%@",self.sizesArray[1]];
                self.thirdSize = [NSString stringWithFormat:@"%@",self.sizesArray[2]];
            }
        }
        else{
            NSLog(@"no array, been an error");
        }
    }
    else if ([self.selection isEqualToString:@"delivery"]){
        self.chooseDelivery.text = selectionString;
    }
}

-(void)addLocation:(LocationView *)controller didFinishEnteringItem:(NSString *)item longi:(CLLocationDegrees)item1 lati:(CLLocationDegrees)item2{
    self.chooseLocation.text = item;
    self.geopoint = [PFGeoPoint geoPointWithLatitude:item2 longitude:item1];
}

-(void)addCurrentLocation:(LocationView *)controller didPress:(PFGeoPoint *)geoPoint title:(NSString *)placemark{
    
        if (geoPoint) {
            self.geopoint = geoPoint;
            self.chooseLocation.text = [NSString stringWithFormat:@"%@",placemark];
        }
        else{
            NSLog(@"error with location");
            self.chooseLocation.text = @"Optional";
        }
}

- (IBAction)wantobuyPressed:(id)sender {
    if (self.editFromListing == YES) {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
    [self.longButton setEnabled:NO];
    self.warningLabel.text = @"";
    [self removeKeyboard];
    
    if (self.somethingChanged == NO) {
        [self.delegate dismissCreateController:self];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    NSString *stringChecker = [self.titleField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if ([self.payField.text isEqualToString:[NSString stringWithFormat:@"%@1", self.currencySymbol]] || [self.payField.text isEqualToString:[NSString stringWithFormat:@"%@0", self.currencySymbol]] || [stringChecker isEqualToString:@""] || self.photostotal == 0) {
        [self showAlertWithTitle:@"Essentials" andMsg:@"Make sure you have a title, image and if you enter a price ensure it's accurate!"];
        [self.longButton setEnabled:YES];
        if (self.editFromListing == YES) {
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
        }
    }
    else{
        [self showHUD];
        [self.listing fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                self.listing = object;
                
                //save boiler plate stuff first
                [self.listing setObject:@"live" forKey:@"status"];
                
                //expiration in 2 weeks
//                NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
//                dayComponent.day = 14;
//                NSCalendar *theCalendar = [NSCalendar currentCalendar];
//                NSDate *expirationDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
//                [self.listing setObject:expirationDate forKey:@"expiration"];
                
                [self.listing setObject:self.currency forKey:@"currency"];
                
                if (self.listingAsMode != YES) {
                    [self.listing setObject:[PFUser currentUser] forKey:@"postUser"];
                }
                else{
                    [self.listing setObject:self.listAsUser forKey:@"postUser"];
                }
                
                NSString *itemTitle = [self.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                [self.listing setObject:itemTitle forKey:@"title"];
                [self.listing setObject:[itemTitle lowercaseString]forKey:@"titleLower"];
                
                //save keywords (minus useless words)
                NSArray *wasteWords = [NSArray arrayWithObjects:@"x",@"to",@"with",@"and",@"the",@"wtb",@"or",@" ",@".",@"very",@"interested", @"in",@"wanted", @"", @"all",@"any", @"&",@"looking",@"size", @"buy", @"these", @"this", @"that", @"-",@"(", @")",@"/", nil];
                NSString *title = [itemTitle lowercaseString];
                NSArray *strings = [title componentsSeparatedByString:@" "];
                NSMutableArray *mutableStrings = [NSMutableArray arrayWithArray:strings];
                [mutableStrings removeObjectsInArray:wasteWords];
                
                NSMutableArray *finalKeywordArray = [NSMutableArray array];
                
                for (NSString *string in mutableStrings) {
                    if (![string canBeConvertedToEncoding:NSASCIIStringEncoding]) {
                        NSLog(@"can't be converted %@", string);
                    }
                    else{
                        [finalKeywordArray addObject:string];
                    }
                }
                [self.listing setObject:finalKeywordArray forKey:@"keywords"];
                finalKeywordArray = [self addAlternativeKeywordsFromArray:finalKeywordArray];
                [self.listing setObject:finalKeywordArray forKey:@"searchKeywords"];
                
                //if got price
                if (![self.payField.text isEqualToString:@"Optional"]) {
                    NSString *prefixToRemove = [NSString stringWithFormat:@"%@", self.currencySymbol];
                    NSString *priceString = [[NSString alloc]init];
                    priceString = [self.payField.text substringFromIndex:[prefixToRemove length]];
                    int price = [priceString intValue];
                    
                    if ([self.currency isEqualToString:@"GBP"]) {
                        self.listing[@"listingPriceGBP"] = @(price);
                        int USD = price*1.32;
                        self.listing[@"listingPriceUSD"] = @(USD);
                        int EUR = price*1.16;
                        self.listing[@"listingPriceEUR"] = @(EUR);
                    }
                    else if ([self.currency isEqualToString:@"USD"]) {
                        self.listing[@"listingPriceUSD"] = @(price);
                        int GBP = price*0.76;
                        self.listing[@"listingPriceGBP"] = @(GBP);
                        int EUR = price*0.89;
                        self.listing[@"listingPriceEUR"] = @(EUR);
                    }
                    else if ([self.currency isEqualToString:@"EUR"]) {
                        self.listing[@"listingPriceEUR"] = @(price);
                        int GBP = price*0.86;
                        self.listing[@"listingPriceGBP"] = @(GBP);
                        int USD = price*1.12;
                        self.listing[@"listingPriceUSD"] = @(USD);
                    }
                }
                
                //if got condition
                if (![self.chooseCondition.text isEqualToString:@"Optional"]) {
                    [self.listing setObject:self.chooseCondition.text forKey:@"condition"];
                }
                else{
                    //set default condition wanted to any
                    [self.listing setObject:@"Any" forKey:@"condition"];
                }
                
                //if got category
                if (![self.chooseCategroy.text isEqualToString:@"Optional"]) {
                    [self.listing setObject:self.chooseCategroy.text forKey:@"category"];
                }
                
                //if got size(s)
                NSMutableArray *placeholderSizeArray = [NSMutableArray array];

                if (![self.chooseSize.text isEqualToString:@"Optional"]) {
                    [self.listing setObject:self.chooseSize.text forKey:@"sizeLabel"];
                    
                    if (![self.genderSize isEqualToString:@""]) {
                        [self.listing setObject:self.genderSize forKey:@"sizeGender"];
                    }

                    if ([self.chooseSize.text isEqualToString:@"Any"]) {
                        //set YES to all sizes for search purposes
                        
                        NSArray *allSizes = [NSArray array];
                        
                        if ([self.chooseCategroy.text isEqualToString:@"Clothing"]) {
                            //clothing sizes
                            allSizes = @[@"XXS",@"XS", @"S", @"M", @"L", @"XL", @"XXL"];
                        }
                        else{
                            //footwear sizes
                            allSizes = @[@"1", @"1.5", @"2", @"2.5", @"3", @"3.5",@"4", @"4.5", @"5", @"5.5", @"6",@"6.5",@"7", @"7.5", @"8",@"8.5",@"9", @"9.5", @"10",@"10.5",@"11", @"11.5", @"12",@"12.5",@"13", @"13.5", @"14"];
                        }
                        for (NSString *stringKey in allSizes) {
                            [placeholderSizeArray addObject:stringKey];
                        }
                    }
                    else{
                        //add sizes from size array
                        if ([self.chooseCategroy.text isEqualToString:@"Footwear"]) {
                            
                            
                            for (id shoeSize in self.sizesArray) {
                                NSString *shoeSizeString = [NSString stringWithFormat:@"%@", shoeSize];
                                NSString *size = [shoeSizeString stringByReplacingOccurrencesOfString:@"UK " withString:@""];
                                [placeholderSizeArray addObject:size];

                            }
                        }
                        else if([self.chooseCategroy.text isEqualToString:@"Clothing"]){
                            [placeholderSizeArray addObjectsFromArray:self.sizesArray];
                        }
                    }
                }
                else{
                    //need to add a size!
                }
                
                [self.listing setObject:placeholderSizeArray forKey:@"sizeArray"];
                placeholderSizeArray = nil;
                
                //sizing explained
                //listing sets YES to all sizes it is registered to, making filtering & search easier - just check if that Key == YES
                if (![self.firstSize isEqualToString:@""]) {
                    [self.listing setObject:self.firstSize forKey:@"firstSize"];
                    NSString *newKey = [self.firstSize stringByReplacingOccurrencesOfString:@"." withString:@"dot"];
                    [self.listing setObject:@"YES"forKey:[NSString stringWithFormat:@"size%@", newKey]];
                }
                if (![self.secondSize isEqualToString:@""]) {
                    [self.listing setObject:self.secondSize forKey:@"secondSize"];
                    NSString *newKey = [self.secondSize stringByReplacingOccurrencesOfString:@"." withString:@"dot"];
                    [self.listing setObject:@"YES"forKey:[NSString stringWithFormat:@"size%@", newKey]];
                }
                if (![self.thirdSize isEqualToString:@""]) {
                    [self.listing setObject:self.thirdSize forKey:@"thirdSize"];
                    NSString *newKey = [self.thirdSize stringByReplacingOccurrencesOfString:@"." withString:@"dot"];
                    [self.listing setObject:@"YES"forKey:[NSString stringWithFormat:@"size%@", newKey]];
                }
                
                //if got location
                if (self.geopoint) {
                    [self.listing setObject:self.geopoint forKey:@"geopoint"];
                }
                if (![self.locationString isEqualToString:@""]) {
                    [self.listing setObject:self.locationString forKey:@"location"];
                }
                
                //save a smaller thumbnail image from first cell's image
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                AddImageCell *firstCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:indexPath];
                
                UIImage *imageOne = [firstCell.itemImageView.image scaleImageToSize:CGSizeMake(200, 200)];
                
                NSData* dataOne = UIImageJPEGRepresentation(imageOne, 0.8f);
                PFFile *thumbFile = [PFFile fileWithName:@"thumb1.jpg" data:dataOne];
                [self.listing setObject:thumbFile forKey:@"thumbnail"];
                
                //save photos
                if (self.photostotal == 1) {
                    
                    PFFile *imageFile1 = self.filesArray[0];
                    [self.listing setObject:imageFile1 forKey:@"image1"];
                    
                    if (self.editFromListing == YES) {
                        [self.listing removeObjectForKey:@"image2"];
                        [self.listing removeObjectForKey:@"image3"];
                        [self.listing removeObjectForKey:@"image4"];
                    }
                }
                else if (self.photostotal == 2){

                    PFFile *imageFile1 = self.filesArray[0];
                    [self.listing setObject:imageFile1 forKey:@"image1"];
                    
                    PFFile *imageFile2 = self.filesArray[1];
                    [self.listing setObject:imageFile2 forKey:@"image2"];
                    
                    if (self.editFromListing == YES) {
                        [self.listing removeObjectForKey:@"image3"];
                        [self.listing removeObjectForKey:@"image4"];
                    }
                }
                else if (self.photostotal == 3){
                    
                    PFFile *imageFile1 = self.filesArray[0];
                    [self.listing setObject:imageFile1 forKey:@"image1"];
                    
                    PFFile *imageFile2 = self.filesArray[1];
                    [self.listing setObject:imageFile2 forKey:@"image2"];

                    PFFile *imageFile3 = self.filesArray[2];
                    [self.listing setObject:imageFile3 forKey:@"image3"];
                    
                    if (self.editFromListing == YES) {
                        [self.listing removeObjectForKey:@"image4"];
                    }
                }
                else if (self.photostotal == 4){
                    
                    PFFile *imageFile1 = self.filesArray[0];
                    [self.listing setObject:imageFile1 forKey:@"image1"];
                    
                    PFFile *imageFile2 = self.filesArray[1];
                    [self.listing setObject:imageFile2 forKey:@"image2"];
                    
                    PFFile *imageFile3 = self.filesArray[2];
                    [self.listing setObject:imageFile3 forKey:@"image3"];

                    PFFile *imageFile4 = self.filesArray[3];
                    [self.listing setObject:imageFile4 forKey:@"image4"];
                }
                
                [self.listing setObject:[NSDate date] forKey:@"lastUpdated"];
                
                [self.listing saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        
//                        NSLog(@"listing updated! %@", self.listing.objectId);
                        
                        //sam and jack code only
                        if (self.listingAsMode == YES) {
                            [self hidHUD];
                            [self dismissViewControllerAnimated:YES completion:nil];
                            return;
                        }
                        
                        //check if editing from listing as need to pop VC rather than display a 'listing complete' VC
                        if (self.editFromListing == YES) {
                            [Answers logCustomEventWithName:@"Listing Updated"
                                           customAttributes:@{
                                                              @"mode":@"Edit from listing"
                                                              }];
                            [self hidHUD];
                            [self dismissViewControllerAnimated:YES completion:nil];
                        }
                        else if (self.addDetails == YES){
                            [Answers logCustomEventWithName:@"Listing Updated"
                                           customAttributes:@{
                                                              @"mode":@"Add details"
                                                              }];
                            [self hidHUD];
                            [self dismissViewControllerAnimated:YES completion:nil];
                        }
                    }
                    else{
                        //error saving listing
                        [self hidHUD];
                        [self.longButton setEnabled:YES];
                        [self showAlertWithTitle:@"Error Updating" andMsg:@"Please check your connection and try again!"];
                        NSLog(@"error saving %@", error);
                    }
                }];
            }
            else{
                NSLog(@"error %@", error);
                [self hidHUD];
                [self showAlertWithTitle:@"Error Updating" andMsg:@"Please check your connection and try again!"];
                return;
            }
        }];
    }
}

-(void)resetFormAsk{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Reset listing?" message:@"Are you sure you want to start your listing again?" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [alertView addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self resetAll];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)resetAll{
    //reset displaying reset button
    self.navigationItem.leftBarButtonItem = nil;
    self.somethingChanged = NO;
    
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    self.status = @"";
    self.chooseCategroy.text = @"Optional";
    self.chooseCondition.text = @"Optional";
    self.chooseLocation.text = @"Optional";
    self.chooseSize.text = @"Optional";
    self.payField.text = @"Optional";
    
    self.titleField.text = @"";

    self.warningLabel.text = @"";
    self.firstSize = @"";
    self.secondSize = @"";
    self.thirdSize = @"";
    
    self.firstImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.secondImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.thirdImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.fourthImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self.firstImageView setImage:[UIImage imageNamed:@"addImage"]];
    [self.secondImageView setImage:[UIImage imageNamed:@"camHolder"]];
    [self.thirdImageView setImage:[UIImage imageNamed:@"camHolder"]];
    [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
    
    [self.firstCam setEnabled:YES];
    [self.secondCam setEnabled:NO];
    [self.thirdCam setEnabled:NO];
    [self.fourthCam setEnabled:NO];
    
    [self.firstDelete setHidden:YES];
    [self.secondDelete setHidden:YES];
    [self.thirdDelete setHidden:YES];
    [self.fourthDelete setHidden:YES];
    
    self.photostotal = 0;
    self.camButtonTapped = 0;
    
    self.geopoint = nil;
    self.locationString = @"";

}

-(void)finalImage:(UIImage *)image{
    //save image if just been taken    
//    UIImage *newImage = [image resizedImage:CGSizeMake(750.00, 750.00) interpolationQuality:kCGInterpolationHigh];

    UIImage *newImage = [image scaleImageToSize:CGSizeMake(750, 750)];

    if (self.shouldSave == YES) {
        UIImageWriteToSavedPhotosAlbum(newImage, nil, nil, nil);
        self.shouldSave = NO;
    }
    
    //cells to access their image views
    NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    AddImageCell *firstCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:firstIndexPath];
    
    NSIndexPath *secondIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    AddImageCell *secondCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:secondIndexPath];
    
    NSIndexPath *thirdIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
    AddImageCell *thirdCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:thirdIndexPath];
    
    NSIndexPath *fourthIndexPath = [NSIndexPath indexPathForRow:3 inSection:0];
    AddImageCell *fourthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fourthIndexPath];
    
    if (self.multipleMode == YES) {
        
        //add to CV array
        NSData *data = UIImageJPEGRepresentation(newImage, 0.8);
        
        if (data == nil) {
            [Answers logCustomEventWithName:@"PFFile Nil Data"
                           customAttributes:@{
                                              @"pageName":@"CreateVC",
                                              @"photosTotal": [NSNumber numberWithInt:self.photostotal]
                                              }];
            
            //prevent crash when creating a PFFile with nil data
            [self hidHUD];
            [self showAlertWithTitle:@"Image Error" andMsg:@"Please check your connection and try again!"];
            [self.longButton setEnabled:YES];
            
            return;
        }
        
        if (self.photostotal == 0) {
            //add image to first image view
            [firstCell.itemImageView setImage:newImage];
            
            [firstCell.deleteButton setHidden:NO];
            [self.secondCam setEnabled:YES];
            [self.firstCam setEnabled:NO];
            
            [secondCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
            [thirdCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
            [fourthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.photostotal == 1){
            [secondCell.itemImageView setImage:newImage];

            [secondCell.deleteButton setHidden:NO];
            [self.thirdCam setEnabled:YES];
            [self.secondCam setEnabled:NO];
            
            [thirdCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
            [fourthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.photostotal == 2){
            [thirdCell.itemImageView setImage:newImage];

            [thirdCell.deleteButton setHidden:NO];
            [self.fourthCam setEnabled:YES];
            [self.thirdCam setEnabled:NO];
            
            [fourthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else if (self.photostotal == 3){
            [fourthCell.itemImageView setImage:newImage];

            [fourthCell.deleteButton setHidden:NO];
            [self.fourthCam setEnabled:NO];
        }
        
        //add to CV array
        PFFile *imageFile = [PFFile fileWithName:@"Image1.jpg" data:data];
        [self.filesArray addObject:imageFile];
        [imageFile saveInBackground]; //speeds up save

        self.photostotal ++;
        
        if (self.imagesToProcess.count > 0) {
            [self.imagesToProcess removeObjectAtIndex:0];
            
            //call process again
            [self processMultiple];
        }
    }
    else{
        
        //add to CV array
        NSData *data = UIImageJPEGRepresentation(newImage, 0.8);
        
        if (data == nil) {
            [Answers logCustomEventWithName:@"PFFile Nil Data"
                           customAttributes:@{
                                              @"pageName":@"CreateVC",
                                              @"photosTotal": [NSNumber numberWithInt:self.photostotal]
                                              }];
            
            //prevent crash when creating a PFFile with nil data
            [self hidHUD];
            [self showAlertWithTitle:@"Image Error" andMsg:@"Please check your connection and try again!"];
            [self.longButton setEnabled:YES];
            
            return;
        }
        
        if (self.camButtonTapped == 1) {
            //add image to first image view
            [firstCell.itemImageView setImage:newImage];

            [firstCell.deleteButton setHidden:NO];
            [self.secondCam setEnabled:YES];
            [self.firstCam setEnabled:NO];
            
            [secondCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
            [thirdCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
            [fourthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.camButtonTapped == 2){
            [secondCell.itemImageView setImage:newImage];

            [secondCell.deleteButton setHidden:NO];
            [self.thirdCam setEnabled:YES];
            [self.secondCam setEnabled:NO];
            
            [thirdCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
            [fourthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.camButtonTapped == 3){
            [thirdCell.itemImageView setImage:newImage];

            [thirdCell.deleteButton setHidden:NO];
            [self.fourthCam setEnabled:YES];
            [self.thirdCam setEnabled:NO];
            
            [fourthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else if (self.camButtonTapped == 4){
            [fourthCell.itemImageView setImage:newImage];

            [fourthCell.deleteButton setHidden:NO];
            [self.fourthCam setEnabled:NO];
        }
        
        PFFile *imageFile = [PFFile fileWithName:@"Image1.jpg" data:data];
        [self.filesArray addObject:imageFile];
        [imageFile saveInBackground]; //speeds up save

        self.photostotal ++;
    }
}

-(void)listingSetup{
    self.navigationItem.title = @"E D I T";
    
    self.titleField.text = [self.listing objectForKey:@"title"];
    
    NSString *symbol = @"";
    
    if ([[self.listing objectForKey:@"currency"] isEqualToString:@"GBP"]) {
        symbol = @"£";
    }
    else{
        symbol = @"$";
    }
    
    if (![self.listing objectForKey:[NSString stringWithFormat:@"listingPrice%@",[self.listing objectForKey:@"currency"]]]) {
        self.payField.text = @"Optional";
    }
    else{
        self.payField.text = [NSString stringWithFormat:@"%@%@",symbol,[self.listing objectForKey:[NSString stringWithFormat:@"listingPrice%@", [self.listing objectForKey:@"currency"]]]];
    }
    
    if (![self.listing objectForKey:@"condition"]) {
        self.chooseCondition.text = @"Optional";
    }
    else{
        self.chooseCondition.text = [self.listing objectForKey:@"condition"];
    }
    
    if (![self.listing objectForKey:@"sizeLabel"]) {
        self.chooseSize.text = @"Optional";
    }
    else{
        self.chooseSize.text = [self.listing objectForKey:@"sizeLabel"];
    }
    
    if (![self.listing objectForKey:@"category"]) {
        self.chooseCategroy.text = @"Optional";
    }
    else{
        if ([[self.listing objectForKey:@"category"]isEqualToString:@"Accessories"]) {
            //set to blank for accessories
            self.chooseSize.text = @"";
        }
        self.chooseCategroy.text = [self.listing objectForKey:@"category"];
    }
    
    if (![self.listing objectForKey:@"location"]) {
        self.chooseLocation.text = @"Optional";
    }
    else{
        self.chooseLocation.text = [self.listing objectForKey:@"location"];
    }
    
    //if gendersize required (if category is footwear) set variable
    if ([self.listing objectForKey:@"sizeGender"]) {
       self.genderSize = [self.listing objectForKey:@"sizeGender"];
    }
    
    //sizing
    if ([self.listing objectForKey:@"firstSize"]) {
        self.firstSize = [NSString stringWithFormat:@"%@",[self.listing objectForKey:@"firstSize"]];
//        NSLog(@"setting 1st %@",[self.listing objectForKey:@"firstSize"]);
        
        //get string
        NSString *first = [self.listing objectForKey:@"firstSize"];
        
        //change string to get key
        NSString *keyS = [first stringByReplacingOccurrencesOfString:@"." withString:@"dot"];
        NSString *finalKey = [NSString stringWithFormat:@"size%@", keyS];
        
        //set key to NO or delete key?
        [self.listing removeObjectForKey:finalKey];
        
        //don't save because if they hit save the new keys will be set
    }
    
    if ([self.listing objectForKey:@"secondSize"]) {
        self.secondSize = [NSString stringWithFormat:@"%@",[self.listing objectForKey:@"secondSize"]];
//        NSLog(@"setting 2nd %@",[self.listing objectForKey:@"secondSize"]);
        
        //get string
        NSString *first = [self.listing objectForKey:@"secondSize"];
        
        //change string to get key
        NSString *keyS = [first stringByReplacingOccurrencesOfString:@"." withString:@"dot"];
        NSString *finalKey = [NSString stringWithFormat:@"size%@", keyS];
        
        //set key to NO or delete key?
        [self.listing removeObjectForKey:finalKey];
    }
    
    if ([self.listing objectForKey:@"thirdSize"]) {
        self.thirdSize = [NSString stringWithFormat:@"%@",[self.listing objectForKey:@"thirdSize"]];
//        NSLog(@"setting 3rd %@",[self.listing objectForKey:@"thirdSize"]);
        
        //get string
        NSString *first = [self.listing objectForKey:@"thirdSize"];
        
        //change string to get key
        NSString *keyS = [first stringByReplacingOccurrencesOfString:@"." withString:@"dot"];
        NSString *finalKey = [NSString stringWithFormat:@"size%@", keyS];
        
        //set key to NO or delete key?
        [self.listing removeObjectForKey:finalKey];
    }
    
    //images
    if ([self.listing objectForKey:@"image1"]) {
        [self.firstImageView setFile:[self.listing objectForKey:@"image1"]];
        [self.firstImageView loadInBackground];
        
        [self.firstDelete setHidden:NO];
        [self.secondCam setEnabled:YES];
        [self.firstCam setEnabled:NO];
        
        [self.secondImageView setImage:[UIImage imageNamed:@"addImage"]];
        [self.thirdImageView setImage:[UIImage imageNamed:@"camHolder"]];
        [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];

        [self.filesArray addObject:[self.listing objectForKey:@"image1"]];
        self.photostotal = 1;
    }
    
    if ([self.listing objectForKey:@"image2"]) {
        [self.secondImageView setFile:[self.listing objectForKey:@"image2"]];
        [self.secondImageView loadInBackground];
        
        [self.secondDelete setHidden:NO];
        [self.thirdCam setEnabled:YES];
        [self.secondCam setEnabled:NO];
        
        [self.thirdImageView setImage:[UIImage imageNamed:@"addImage"]];
        [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
        
        [self.filesArray addObject:[self.listing objectForKey:@"image2"]];
        self.photostotal = 2;
    }
    
    if ([self.listing objectForKey:@"image3"]) {
        [self.thirdImageView setFile:[self.listing objectForKey:@"image3"]];
        [self.thirdImageView loadInBackground];
        
        [self.thirdDelete setHidden:NO];
        [self.fourthCam setEnabled:YES];
        [self.thirdCam setEnabled:NO];
        
        [self.fourthImageView setImage:[UIImage imageNamed:@"addImage"]];
       
        [self.filesArray addObject:[self.listing objectForKey:@"image3"]];
        self.photostotal = 3;
    }
    
    if ([self.listing objectForKey:@"image4"]) {
        [self.fourthImageView setFile:[self.listing objectForKey:@"image4"]];
        [self.fourthImageView loadInBackground];
        
        [self.fourthDelete setHidden:NO];
        [self.fourthCam setEnabled:NO];
        
        [self.filesArray addObject:[self.listing objectForKey:@"image4"]];
        self.photostotal = 4;
    }
}

- (void)addDoneButton {
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
    [keyboardToolbar sizeToFit];
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self.view action:@selector(endEditing:)];
    
    [doneBarButton setTintColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1]];
    keyboardToolbar.barTintColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];
    
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    self.payField.inputAccessoryView = keyboardToolbar;
}

-(void)tagString:(NSString *)tag{
    //do nothing only for images shown in offer mode
}
-(void)dismissPressed:(BOOL)yesorno{
    //do nothing in create VC
}

-(void)hidHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
        self.hudShowing = NO;
        self.shouldShowHUD = NO;
    });
}

-(void)viewWillDisappear:(BOOL)animated{
    if (self.hudShowing == YES) {
        [self hidHUD];
    }
    self.picker = nil;
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                         self.buttonShowing = NO;
                     }];
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
    self.hudShowing = YES;
    self.shouldShowHUD = YES;
}

-(void)useCurrentLoc{
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint * _Nullable geoPoint, NSError * _Nullable error) {
        if (!error) {
            double latitude = geoPoint.latitude;
            double longitude = geoPoint.longitude;
            
            CLLocation *loc = [[CLLocation alloc]initWithLatitude:latitude longitude:longitude];
            CLGeocoder *geocoder = [[CLGeocoder alloc]init];
            [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                if (placemarks) {
                    CLPlacemark *placemark = [placemarks lastObject];
                    NSString *titleString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.ISOcountryCode];
                    
                    if (geoPoint) {
                        self.somethingChanged = YES;
                        self.geopoint = geoPoint;
                        self.locationString = titleString;
                    }
                    else{
                        NSLog(@"error with location");
                        self.locationString = @"";
                        self.geopoint = nil;
                    }
                }
                else{
                    NSLog(@"error %@", error);
                }
            }];
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

-(void)dismissVC{
    //only show warning if listing has been editing
    if (self.somethingChanged == NO){
        [self.delegate dismissCreateController:self];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else{
        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Leave this page?" message:@"Are you sure you want to leave? Your changes won't be saved!" preferredStyle:UIAlertControllerStyleAlert];
        
        [alertView addAction:[UIAlertAction actionWithTitle:@"Stay" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
        [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.delegate dismissCreateController:self];
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        [self presentViewController:alertView animated:YES completion:nil];
    }
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

#pragma mark - collection view delegates

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{

    AddImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.delegate = self;
    
    NSLog(@"PHOTOS TOTAL %d", self.photostotal);
    
    if (self.photostotal == 0) {
        
        [cell.deleteButton setHidden:YES];
        
        if (indexPath.row == 0) {
            [cell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else if (indexPath.row == 1) {
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (indexPath.row == 2) {
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (indexPath.row == 3) {
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
    }
    else if (self.photostotal == 1) {
        if (indexPath.row == 0) {
            [cell.deleteButton setHidden:NO];

            [cell.itemImageView setFile:self.filesArray[0]];
        }
        else if (indexPath.row == 1) {
            [cell.deleteButton setHidden:YES];
            [cell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else if (indexPath.row == 2) {
            [cell.deleteButton setHidden:YES];
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (indexPath.row == 3) {
            [cell.deleteButton setHidden:YES];
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
    }
    else if (self.photostotal == 2) {
        if (indexPath.row == 0) {
            [cell.deleteButton setHidden:NO];

            [cell.itemImageView setFile:self.filesArray[0]];
        }
        else if (indexPath.row == 1) {
            [cell.deleteButton setHidden:NO];

            [cell.itemImageView setFile:self.filesArray[1]];
        }
        else if (indexPath.row == 2) {
            [cell.deleteButton setHidden:YES];
            [cell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else if (indexPath.row == 3) {
            [cell.deleteButton setHidden:YES];
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
    }
    else if (self.photostotal == 3) {
        if (indexPath.row == 0) {
            [cell.deleteButton setHidden:NO];

            [cell.itemImageView setFile:self.filesArray[0]];
        }
        else if (indexPath.row == 1) {
            [cell.deleteButton setHidden:NO];

            [cell.itemImageView setFile:self.filesArray[1]];
        }
        else if (indexPath.row == 2) {
            [cell.deleteButton setHidden:NO];

            [cell.itemImageView setFile:self.filesArray[2]];
        }
        else if (indexPath.row == 3) {
            [cell.deleteButton setHidden:YES];
            [cell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
    }
    else if (self.photostotal == 4) {
        if (indexPath.row == 0) {
            [cell.deleteButton setHidden:NO];

            [cell.itemImageView setFile:self.filesArray[0]];
        }
        else if (indexPath.row == 1) {
            [cell.deleteButton setHidden:NO];

            [cell.itemImageView setFile:self.filesArray[1]];
        }
        else if (indexPath.row == 2) {
            [cell.deleteButton setHidden:NO];

            [cell.itemImageView setFile:self.filesArray[2]];
        }
        else if (indexPath.row == 3) {
            [cell.deleteButton setHidden:NO];
            
            [cell.itemImageView setFile:self.filesArray[3]];
        }
    }
    
    [cell.itemImageView loadInBackground];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        [self firstCamPressed:self];
    }
    else if (indexPath.row == 1) {
        [self secondCamPressed:self];
    }
    else if (indexPath.row == 2) {
        [self thirdPressed:self];

    }
    else if (indexPath.row == 3) {
        [self fourthCamPressed:self];
    }
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 4;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row < self.photostotal){
        return YES;
    }
    else{
        return NO;
    }
}

-(BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath{
    
    if (toIndexPath.row < self.photostotal){
        return YES;
    }
    else{
        return NO;
    }
}
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {

    self.somethingChanged = YES;
    
    NSMutableArray *placeholder = [NSMutableArray arrayWithArray:self.filesArray];
    
    PFFile *image = [placeholder objectAtIndex:fromIndexPath.item];
    [placeholder removeObjectAtIndex:fromIndexPath.item];
    [placeholder insertObject:image atIndex:toIndexPath.item];
    
    self.filesArray = placeholder;

}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        return UIEdgeInsetsZero;
    }
    
    NSInteger viewWidth = [UIApplication sharedApplication].keyWindow.frame.size.width;
    
    NSInteger totalCellWidth = self.cellWidth * 4;
    NSInteger totalSpacingWidth = 10 * (4 -1);
    
    NSInteger leftInset = (viewWidth - (totalCellWidth + totalSpacingWidth)) / 2;
    NSInteger rightInset = leftInset;
    
    return UIEdgeInsetsMake(0, leftInset, 0, rightInset);
}

//cv cell delegate to detect delete button action

-(void)imageCellDeleteTapped:(AddImageCell *)cell{
    
    self.somethingChanged = YES;

    NSIndexPath *indexPath = [self.imgCollectionView indexPathForCell:cell];
    
    if (indexPath.row == 0) {
        [self firstDeletePressedOnCell:cell];
    }
    else if (indexPath.row == 1){
        [self secondDeletePressedOnCell:cell];
    }
    else if (indexPath.row == 2){
        [self thirdDeletePressedOnCell:cell];
    }
    else if (indexPath.row == 3){
        [self fourthDeletePressedOnCell:cell];
    }
}

-(void)firstDeletePressedOnCell:(AddImageCell *)cell{
    
    NSIndexPath *indexPath = [self.imgCollectionView indexPathForCell:cell];

    NSIndexPath *secondIndexPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:0];
    AddImageCell *secondCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:secondIndexPath];
    
    NSIndexPath *thirdIndexPath = [NSIndexPath indexPathForRow:indexPath.row+2 inSection:0];
    AddImageCell *thirdCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:thirdIndexPath];
    
    NSIndexPath *fourthIndexPath = [NSIndexPath indexPathForRow:indexPath.row+3 inSection:0];
    AddImageCell *fourthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fourthIndexPath];

    //update CV array
    [self.filesArray removeObjectAtIndex:0];

    if (self.photostotal == 1) {
        self.photostotal--;
        
        [UIView transitionWithView:cell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [cell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.firstCam setEnabled:YES];
                        }];
        
        [UIView transitionWithView:secondCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [secondCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
                        } completion:^(BOOL finished) {
                            [self.secondCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [cell.deleteButton setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [cell.deleteButton setHidden:YES];
                             [cell.deleteButton setAlpha:1.0f];
                         }];
    }
    else if (self.photostotal ==2){
        self.photostotal--;
        
        [UIView transitionWithView:cell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [cell.itemImageView setImage:secondCell.itemImageView.image];
                        } completion:^(BOOL finished) {
                            [self.firstCam setEnabled:NO];
                        }];
        
        [UIView transitionWithView:secondCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [secondCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.secondCam setEnabled:YES];
                        }];
        
        [UIView transitionWithView:thirdCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [thirdCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
                        } completion:^(BOOL finished) {
                            [self.thirdCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [secondCell.deleteButton setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [secondCell.deleteButton setHidden:YES];
                             [secondCell.deleteButton setAlpha:1.0f];
                         }];
    }
    else if (self.photostotal ==3){
        self.photostotal--;
        
        [UIView transitionWithView:cell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [cell.itemImageView setImage:secondCell.itemImageView.image];
                        } completion:^(BOOL finished) {
                            [self.firstCam setEnabled:NO];
                        }];
        
        [UIView transitionWithView:secondCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [secondCell.itemImageView setImage:thirdCell.itemImageView.image];
                        } completion:^(BOOL finished) {
                            [self.secondCam setEnabled:NO];
                        }];
        
        [UIView transitionWithView:thirdCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [thirdCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.thirdCam setEnabled:YES];
                        }];
        
        [UIView transitionWithView:fourthCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [fourthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
                        } completion:^(BOOL finished) {
                            [self.fourthCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [thirdCell.deleteButton setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [thirdCell.deleteButton setHidden:YES];
                             [thirdCell.deleteButton setAlpha:1.0f];
                         }];
    }
    else if (self.photostotal ==4){
        self.photostotal--;
        
        [UIView transitionWithView:cell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [cell.itemImageView setImage:secondCell.itemImageView.image];
                        } completion:^(BOOL finished) {
                            [self.firstCam setEnabled:NO];
                        }];
        
        [UIView transitionWithView:secondCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [secondCell.itemImageView setImage:thirdCell.itemImageView.image];
                        } completion:^(BOOL finished) {
                            [self.secondCam setEnabled:NO];
                        }];
        
        [UIView transitionWithView:thirdCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [thirdCell.itemImageView setImage:fourthCell.itemImageView.image];
                        } completion:^(BOOL finished) {
                            [self.thirdCam setEnabled:NO];
                        }];
        
        [UIView transitionWithView:fourthCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [fourthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.fourthCam setEnabled:YES];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [fourthCell.deleteButton setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             NSLog(@"finished animating deleteb");
                             [fourthCell.deleteButton setHidden:YES];
                             [fourthCell.deleteButton setAlpha:1.0f];
                         }];
    }
}

-(void)secondDeletePressedOnCell:(AddImageCell *)cell{
    
    NSIndexPath *secondIndexPath = [self.imgCollectionView indexPathForCell:cell];
    AddImageCell *secondCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:secondIndexPath];
    
    NSIndexPath *thirdIndexPath = [NSIndexPath indexPathForRow:secondIndexPath.row+1 inSection:0];
    AddImageCell *thirdCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:thirdIndexPath];
    
    NSIndexPath *fourthIndexPath = [NSIndexPath indexPathForRow:secondIndexPath.row+2 inSection:0];
    AddImageCell *fourthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fourthIndexPath];
    
    //update CV array
    [self.filesArray removeObjectAtIndex:1];
    
    if (self.photostotal ==2){
        self.photostotal--;
        
        [UIView transitionWithView:secondCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [secondCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.secondCam setEnabled:YES];
                        }];
        
        [UIView transitionWithView:thirdCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [thirdCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
                        } completion:^(BOOL finished) {
                            [self.thirdCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [secondCell.deleteButton setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [secondCell.deleteButton setHidden:YES];
                             [secondCell.deleteButton setAlpha:1.0f];
                         }];
    }
    else if (self.photostotal ==3){
        self.photostotal--;
        
        [UIView transitionWithView:secondCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [secondCell.itemImageView setImage:thirdCell.itemImageView.image];
                        } completion:^(BOOL finished) {
                            [self.secondCam setEnabled:NO];
                        }];
        
        [UIView transitionWithView:thirdCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [thirdCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.thirdCam setEnabled:YES];
                        }];
        
        [UIView transitionWithView:fourthCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [fourthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
                        } completion:^(BOOL finished) {
                            [self.fourthCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [thirdCell.deleteButton setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [thirdCell.deleteButton setHidden:YES];
                             [thirdCell.deleteButton setAlpha:1.0f];
                         }];
    }
    else if (self.photostotal ==4){
        self.photostotal--;
        
        [UIView transitionWithView:secondCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [secondCell.itemImageView setImage:thirdCell.itemImageView.image];
                        } completion:^(BOOL finished) {
                            [self.secondCam setEnabled:NO];
                        }];
        
        [UIView transitionWithView:thirdCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [thirdCell.itemImageView setImage:fourthCell.itemImageView.image];
                        } completion:^(BOOL finished) {
                            [self.thirdCam setEnabled:NO];
                        }];
        
        [UIView transitionWithView:fourthCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [fourthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.fourthCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [fourthCell.deleteButton setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [fourthCell.deleteButton setHidden:YES];
                             [fourthCell.deleteButton setAlpha:1.0f];
                         }];
    }
}

-(void)thirdDeletePressedOnCell:(AddImageCell *)cell{
    
    NSIndexPath *thirdIndexPath = [self.imgCollectionView indexPathForCell:cell];
    AddImageCell *thirdCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:thirdIndexPath];
    
    NSIndexPath *fourthIndexPath = [NSIndexPath indexPathForRow:thirdIndexPath.row+1 inSection:0];
    AddImageCell *fourthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fourthIndexPath];
    
    //update CV array
    [self.filesArray removeObjectAtIndex:2];
    
    if (self.photostotal ==3){
        self.photostotal--;
        
        [UIView transitionWithView:thirdCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [thirdCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.thirdCam setEnabled:YES];
                        }];
        
        [UIView transitionWithView:fourthCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [fourthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
                        } completion:^(BOOL finished) {
                            [self.fourthCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [thirdCell.deleteButton setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [thirdCell.deleteButton setHidden:YES];
                             [thirdCell.deleteButton setAlpha:1.0f];
                         }];
    }
    else if (self.photostotal ==4){
        self.photostotal--;
        
        [UIView transitionWithView:thirdCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [thirdCell.itemImageView setImage:fourthCell.itemImageView.image];
                        } completion:^(BOOL finished) {
                            [self.thirdCam setEnabled:NO];
                        }];
        
        [UIView transitionWithView:fourthCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [fourthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.fourthCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [fourthCell.deleteButton setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [fourthCell.deleteButton setHidden:YES];
                             [fourthCell.deleteButton setAlpha:1.0f];
                         }];
    }
}

-(void)fourthDeletePressedOnCell:(AddImageCell *)cell{
    
    NSIndexPath *fourthIndexPath = [self.imgCollectionView indexPathForCell:cell];
    AddImageCell *fourthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fourthIndexPath];
    
    NSIndexPath *thirdIndexPath = [NSIndexPath indexPathForRow:fourthIndexPath.row-1 inSection:0];
    AddImageCell *thirdCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:thirdIndexPath];
    
    //update CV array
    [self.filesArray removeObjectAtIndex:3];
    
    if (self.photostotal ==4){
        self.photostotal--;
        
        [UIView transitionWithView:thirdCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [thirdCell.itemImageView setImage:fourthCell.itemImageView.image];
                        } completion:^(BOOL finished) {
                            [self.thirdCam setEnabled:NO];
                        }];
        
        [UIView transitionWithView:fourthCell.itemImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [fourthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.fourthCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [fourthCell.deleteButton setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [fourthCell.deleteButton setHidden:YES];
                             [fourthCell.deleteButton setAlpha:1.0f];
                         }];
    }
}

-(NSMutableArray *)addAlternativeKeywordsFromArray:(NSMutableArray *)finalKeywordArray{
    //t shirt variations
    if ([finalKeywordArray containsObject:@"tee"]) {
        [finalKeywordArray addObject:@"shirt"];
        [finalKeywordArray addObject:@"t"];
        [finalKeywordArray addObject:@"t-shirt"];
        [finalKeywordArray addObject:@"tshirt"];
        [finalKeywordArray addObject:@"top"];
        [finalKeywordArray addObject:@"tees"];
    }
    else if ([finalKeywordArray containsObject:@"tshirt"]) {
        [finalKeywordArray addObject:@"shirt"];
        [finalKeywordArray addObject:@"t"];
        [finalKeywordArray addObject:@"t-shirt"];
        [finalKeywordArray addObject:@"tee"];
        [finalKeywordArray addObject:@"top"];
        [finalKeywordArray addObject:@"tees"];
    }
    else if ([finalKeywordArray containsObject:@"t-shirt"]) {
        [finalKeywordArray addObject:@"shirt"];
        [finalKeywordArray addObject:@"t"];
        [finalKeywordArray addObject:@"tshirt"];
        [finalKeywordArray addObject:@"tee"];
        [finalKeywordArray addObject:@"top"];
        [finalKeywordArray addObject:@"tees"];
    }
    else if ([finalKeywordArray containsObject:@"t"] && [finalKeywordArray containsObject:@"shirt"]) {
        [finalKeywordArray addObject:@"t-shirt"];
        [finalKeywordArray addObject:@"tshirt"];
        [finalKeywordArray addObject:@"tee"];
        [finalKeywordArray addObject:@"top"];
        [finalKeywordArray addObject:@"tees"];
    }
    
    //bogo variations
    if ([finalKeywordArray containsObject:@"bogo"]) {
        [finalKeywordArray addObject:@"box"];
        [finalKeywordArray addObject:@"logo"];
        [finalKeywordArray addObject:@"boxlogo"];
        [finalKeywordArray addObject:@"bogos"];
    }
    else if ([finalKeywordArray containsObject:@"box logo"]) {
        [finalKeywordArray addObject:@"bogo"];
        [finalKeywordArray addObject:@"boxlogo"];
        [finalKeywordArray addObject:@"bogos"];
    }
    
    //triferg variations
    if ([finalKeywordArray containsObject:@"triferg"]) {
        [finalKeywordArray addObject:@"tri-ferg"];
        [finalKeywordArray addObject:@"tri"];
        [finalKeywordArray addObject:@"ferg"];
    }
    else if ([finalKeywordArray containsObject:@"tri-ferg"]) {
        [finalKeywordArray addObject:@"triferg"];
        [finalKeywordArray addObject:@"tri"];
        [finalKeywordArray addObject:@"ferg"];
    }
    else if ([finalKeywordArray containsObject:@"tri"] && [finalKeywordArray containsObject:@"ferg"]) {
        [finalKeywordArray addObject:@"triferg"];
        [finalKeywordArray addObject:@"tri-ferg"];
    }
    
    //numbers
    if ([finalKeywordArray containsObject:@"1"] || [finalKeywordArray containsObject:@"one"]) {
        [finalKeywordArray addObject:@"1"];
        [finalKeywordArray addObject:@"one"];
    }
    if ([finalKeywordArray containsObject:@"2"] || [finalKeywordArray containsObject:@"two"]) {
        [finalKeywordArray addObject:@"2"];
        [finalKeywordArray addObject:@"two"];
    }
    if ([finalKeywordArray containsObject:@"3"] || [finalKeywordArray containsObject:@"three"]) {
        [finalKeywordArray addObject:@"3"];
        [finalKeywordArray addObject:@"three"];
    }
    if ([finalKeywordArray containsObject:@"4"] || [finalKeywordArray containsObject:@"four"]) {
        [finalKeywordArray addObject:@"4"];
        [finalKeywordArray addObject:@"four"];
    }
    if ([finalKeywordArray containsObject:@"5"] || [finalKeywordArray containsObject:@"five"]) {
        [finalKeywordArray addObject:@"five"];
        [finalKeywordArray addObject:@"5"];
    }
    if ([finalKeywordArray containsObject:@"6"] || [finalKeywordArray containsObject:@"six"]) {
        [finalKeywordArray addObject:@"6"];
        [finalKeywordArray addObject:@"six"];
    }
    if ([finalKeywordArray containsObject:@"7"] || [finalKeywordArray containsObject:@"seven"]) {
        [finalKeywordArray addObject:@"seven"];
        [finalKeywordArray addObject:@"7"];
    }
    if ([finalKeywordArray containsObject:@"8"] || [finalKeywordArray containsObject:@"eight"]) {
        [finalKeywordArray addObject:@"8"];
        [finalKeywordArray addObject:@"eight"];
    }
    if ([finalKeywordArray containsObject:@"9"] || [finalKeywordArray containsObject:@"nine"]) {
        [finalKeywordArray addObject:@"9"];
        [finalKeywordArray addObject:@"nine"];
    }
    if ([finalKeywordArray containsObject:@"10"] || [finalKeywordArray containsObject:@"ten"]) {
        [finalKeywordArray addObject:@"10"];
        [finalKeywordArray addObject:@"ten"];
    }
    
    //pullover/anorak
    if ([finalKeywordArray containsObject:@"pullover"]) {
        [finalKeywordArray addObject:@"anorak"];
        [finalKeywordArray addObject:@"pull"];
        [finalKeywordArray addObject:@"over"];
        [finalKeywordArray addObject:@"anarak"];
    }
    else if ([finalKeywordArray containsObject:@"anorak"]) {
        [finalKeywordArray addObject:@"pullover"];
        [finalKeywordArray addObject:@"pull"];
        [finalKeywordArray addObject:@"over"];
        [finalKeywordArray addObject:@"anarak"];
    }
    else if ([finalKeywordArray containsObject:@"anarak"]) {
        [finalKeywordArray addObject:@"pullover"];
        [finalKeywordArray addObject:@"pull"];
        [finalKeywordArray addObject:@"over"];
        [finalKeywordArray addObject:@"anorak"];
    }
    //quarter zip
    if ([finalKeywordArray containsObject:@"quarter"] && [finalKeywordArray containsObject:@"zip"] ) {
        [finalKeywordArray addObject:@"1/4"];
        [finalKeywordArray addObject:@"zip"];
        [finalKeywordArray addObject:@"quarterzip"];
    }
    else if ([finalKeywordArray containsObject:@"1/4"] && [finalKeywordArray containsObject:@"zip"] ) {
        [finalKeywordArray addObject:@"1/4"];
        [finalKeywordArray addObject:@"zip"];
        [finalKeywordArray addObject:@"quarterzip"];
    }
    else if ([finalKeywordArray containsObject:@"quarterzip"]) {
        [finalKeywordArray addObject:@"1/4"];
        [finalKeywordArray addObject:@"zip"];
        [finalKeywordArray addObject:@"quarter"];
    }
    
    //half zip
    if ([finalKeywordArray containsObject:@"half"] && [finalKeywordArray containsObject:@"zip"] ) {
        [finalKeywordArray addObject:@"1/2"];
        [finalKeywordArray addObject:@"quarterzip"];
        [finalKeywordArray addObject:@"quarter"];
    }
    else if ([finalKeywordArray containsObject:@"1/2"] && [finalKeywordArray containsObject:@"zip"] ) {
        [finalKeywordArray addObject:@"halfzip"];
        [finalKeywordArray addObject:@"half"];
    }
    else if ([finalKeywordArray containsObject:@"halfzip"]) {
        [finalKeywordArray addObject:@"1/2"];
        [finalKeywordArray addObject:@"zip"];
        [finalKeywordArray addObject:@"half"];
    }
    
    //overshirt
    if ([finalKeywordArray containsObject:@"over"] && [finalKeywordArray containsObject:@"shirt"] ) {
        [finalKeywordArray addObject:@"overshirt"];
    }
    else if ([finalKeywordArray containsObject:@"overshirt"]) {
        [finalKeywordArray addObject:@"over"];
        [finalKeywordArray addObject:@"shirt"];
    }
    
    //hoodie/jumper/hood jumper
    if ([finalKeywordArray containsObject:@"hooded"] && [finalKeywordArray containsObject:@"jumper"] ) {
        [finalKeywordArray addObject:@"hoodie"];
        [finalKeywordArray addObject:@"hoody"];
    }
    else if ([finalKeywordArray containsObject:@"hoodie"]) {
        [finalKeywordArray addObject:@"hooded"];
        [finalKeywordArray addObject:@"hoody"];
        [finalKeywordArray addObject:@"jumper"];
    }
    else if ([finalKeywordArray containsObject:@"hoody"]) {
        [finalKeywordArray addObject:@"hoodie"];
        [finalKeywordArray addObject:@"hoody"];
        [finalKeywordArray addObject:@"jumper"];
        [finalKeywordArray addObject:@"hooded"];
    }
    
    //ultraboost
    if ([finalKeywordArray containsObject:@"ultra"] && [finalKeywordArray containsObject:@"boost"] ) {
        [finalKeywordArray addObject:@"ultraboost"];
        [finalKeywordArray addObject:@"UB"];
    }
    else if ([finalKeywordArray containsObject:@"ultraboost"]) {
        [finalKeywordArray addObject:@"ultra"];
        [finalKeywordArray addObject:@"boost"];
        [finalKeywordArray addObject:@"UB"];
    }
    //primeknit
    if ([finalKeywordArray containsObject:@"prime"] && [finalKeywordArray containsObject:@"knit"] ) {
        [finalKeywordArray addObject:@"primeknit"];
        [finalKeywordArray addObject:@"pk"];
    }
    else if ([finalKeywordArray containsObject:@"primeknit"]) {
        [finalKeywordArray addObject:@"prime"];
        [finalKeywordArray addObject:@"knit"];
        [finalKeywordArray addObject:@"pk"];
    }
    
    //parker
    if ([finalKeywordArray containsObject:@"parker"]) {
        [finalKeywordArray addObject:@"parka"];
    }
    else if ([finalKeywordArray containsObject:@"parka"]) {
        [finalKeywordArray addObject:@"parker"];
    }
    
    //cap/hat
    if ([finalKeywordArray containsObject:@"cap"]) {
        [finalKeywordArray addObject:@"hat"];
    }
    else if ([finalKeywordArray containsObject:@"hat"]) {
        [finalKeywordArray addObject:@"cap"];
    }
    
    //assc
    if ([finalKeywordArray containsObject:@"assc"]) {
        [finalKeywordArray addObject:@"antisocialsocialclub"];
        [finalKeywordArray addObject:@"anti"];
        [finalKeywordArray addObject:@"social"];
        [finalKeywordArray addObject:@"club"];
    }
    else if ([finalKeywordArray containsObject:@"anti"] && [finalKeywordArray containsObject:@"social"] && [finalKeywordArray containsObject:@"club"]) {
        [finalKeywordArray addObject:@"assc"];
        [finalKeywordArray addObject:@"antisocialsocialclub"];
    }
    
    //gosha
    if ([finalKeywordArray containsObject:@"gosha"]) {
        [finalKeywordArray addObject:@"rubchinskiy"];
        [finalKeywordArray addObject:@"gosharubchinskiy"];
        [finalKeywordArray addObject:@"rubchinsky"];
        [finalKeywordArray addObject:@"ruchinskiy"];
    }
    else if ([finalKeywordArray containsObject:@"rubchinskiy"]) {
        [finalKeywordArray addObject:@"gosha"];
        [finalKeywordArray addObject:@"gosharubchinskiy"];
        [finalKeywordArray addObject:@"rubchinsky"];
        [finalKeywordArray addObject:@"ruchinskiy"];
    }
    
    //raf simons
    if ([finalKeywordArray containsObject:@"simons"]) {
        [finalKeywordArray addObject:@"raf"];
        [finalKeywordArray addObject:@"raph"];
        [finalKeywordArray addObject:@"rafsimons"];
        [finalKeywordArray addObject:@"raphsimons"];
        [finalKeywordArray addObject:@"simmons"];
    }
    else if ([finalKeywordArray containsObject:@"simmons"]) {
        [finalKeywordArray addObject:@"raf"];
        [finalKeywordArray addObject:@"raph"];
        [finalKeywordArray addObject:@"rafsimons"];
        [finalKeywordArray addObject:@"raphsimons"];
        [finalKeywordArray addObject:@"simons"];
    }
    
    //yeezy
    if ([finalKeywordArray containsObject:@"yeezy"]) {
        [finalKeywordArray addObject:@"yeezys"];
        [finalKeywordArray addObject:@"kanye"];
        [finalKeywordArray addObject:@"yeezus"];
    }
    else if ([finalKeywordArray containsObject:@"yeezys"]) {
        [finalKeywordArray addObject:@"yeezy"];
        [finalKeywordArray addObject:@"kanye"];
        [finalKeywordArray addObject:@"yeezus"];
    }
    else if ([finalKeywordArray containsObject:@"kanye"]) {
        [finalKeywordArray addObject:@"yeezy"];
        [finalKeywordArray addObject:@"yeezys"];
        [finalKeywordArray addObject:@"yeezus"];
    }
    
    //palidas
    if ([finalKeywordArray containsObject:@"palace"] && [finalKeywordArray containsObject:@"adidas"]) {
        [finalKeywordArray addObject:@"palidas"];
    }
    
    //crew
    if ([finalKeywordArray containsObject:@"crew"]) {
        [finalKeywordArray addObject:@"crewneck"];
        [finalKeywordArray addObject:@"sweatshirt"];
        [finalKeywordArray addObject:@"sweat"];
        [finalKeywordArray addObject:@"jumper"];
        [finalKeywordArray addObject:@"sweater"];
        [finalKeywordArray addObject:@"top"];
    }
    else if ([finalKeywordArray containsObject:@"crewneck"]) {
        [finalKeywordArray addObject:@"crew"];
        [finalKeywordArray addObject:@"sweatshirt"];
        [finalKeywordArray addObject:@"sweat"];
        [finalKeywordArray addObject:@"jumper"];
        [finalKeywordArray addObject:@"sweater"];
        [finalKeywordArray addObject:@"top"];
    }
    
    //bred/black&red
    if ([finalKeywordArray containsObject:@"bred"]) {
        [finalKeywordArray addObject:@"black"];
        [finalKeywordArray addObject:@"red"];
    }
    else if ([finalKeywordArray containsObject:@"black"] && [finalKeywordArray containsObject:@"red"]) {
        [finalKeywordArray addObject:@"bred"];
    }
    
    //stone island
    if ([finalKeywordArray containsObject:@"stoney"]) {
        [finalKeywordArray addObject:@"stone"];
        [finalKeywordArray addObject:@"island"];
    }
    else if ([finalKeywordArray containsObject:@"stone"] && [finalKeywordArray containsObject:@"island"]) {
        [finalKeywordArray addObject:@"stoney"];
    }
    
    //bape
    if ([finalKeywordArray containsObject:@"bape"]) {
        [finalKeywordArray addObject:@"bathing"];
        [finalKeywordArray addObject:@"ape"];
    }
    else if ([finalKeywordArray containsObject:@"bathing"] && [finalKeywordArray containsObject:@"ape"]) {
        [finalKeywordArray addObject:@"bape"];
    }
    
    //off white
    if ([finalKeywordArray containsObject:@"offwhite"]) {
        [finalKeywordArray addObject:@"off"];
        [finalKeywordArray addObject:@"white"];
        [finalKeywordArray addObject:@"off-white"];
        [finalKeywordArray addObject:@"ofwhite"];
    }
    else if ([finalKeywordArray containsObject:@"off-white"]) {
        [finalKeywordArray addObject:@"off"];
        [finalKeywordArray addObject:@"white"];
        [finalKeywordArray addObject:@"offwhite"];
        [finalKeywordArray addObject:@"ofwhite"];
    }
    else if ([finalKeywordArray containsObject:@"of"] && [finalKeywordArray containsObject:@"white"]) {
        [finalKeywordArray addObject:@"off"];
        [finalKeywordArray addObject:@"white"];
        [finalKeywordArray addObject:@"off-white"];
        [finalKeywordArray addObject:@"offwhite"];
        [finalKeywordArray addObject:@"ofwhite"];
    }
    
    //pants
    if ([finalKeywordArray containsObject:@"joggers"]) {
        [finalKeywordArray addObject:@"sweatpants"];
        [finalKeywordArray addObject:@"trackpants"];
        [finalKeywordArray addObject:@"tracksuit"];
        [finalKeywordArray addObject:@"bottoms"];
        [finalKeywordArray addObject:@"tracksuits"];
    }
    else if ([finalKeywordArray containsObject:@"sweatpants"]) {
        [finalKeywordArray addObject:@"trackpants"];
        [finalKeywordArray addObject:@"tracksuit"];
        [finalKeywordArray addObject:@"bottoms"];
        [finalKeywordArray addObject:@"tracksuits"];
        [finalKeywordArray addObject:@"joggers"];
    }
    else if ([finalKeywordArray containsObject:@"trackpants"]) {
        [finalKeywordArray addObject:@"joggers"];
        [finalKeywordArray addObject:@"tracksuit"];
        [finalKeywordArray addObject:@"bottoms"];
        [finalKeywordArray addObject:@"tracksuits"];
        [finalKeywordArray addObject:@"sweatpants"];
    }
    else if ([finalKeywordArray containsObject:@"tracksuit"] && [finalKeywordArray containsObject:@"bottoms"]) {
        [finalKeywordArray addObject:@"joggers"];
        [finalKeywordArray addObject:@"tracksuits"];
        [finalKeywordArray addObject:@"sweatpants"];
        [finalKeywordArray addObject:@"trackpants"];
    }
    
    //longsleeve
    if ([finalKeywordArray containsObject:@"longsleeve"]) {
        [finalKeywordArray addObject:@"long-sleeve"];
        [finalKeywordArray addObject:@"long"];
        [finalKeywordArray addObject:@"sleeve"];
        [finalKeywordArray addObject:@"l/s"];
        [finalKeywordArray addObject:@"ls"];
    }
    else if ([finalKeywordArray containsObject:@"long-sleeve"]) {
        [finalKeywordArray addObject:@"longsleeve"];
        [finalKeywordArray addObject:@"long"];
        [finalKeywordArray addObject:@"sleeve"];
        [finalKeywordArray addObject:@"l/s"];
        [finalKeywordArray addObject:@"ls"];
    }
    else if ([finalKeywordArray containsObject:@"ls"]) {
        [finalKeywordArray addObject:@"longsleeve"];
        [finalKeywordArray addObject:@"long"];
        [finalKeywordArray addObject:@"sleeve"];
        [finalKeywordArray addObject:@"l/s"];
        [finalKeywordArray addObject:@"long-sleeve"];
    }
    else if ([finalKeywordArray containsObject:@"l/s"]) {
        [finalKeywordArray addObject:@"longsleeve"];
        [finalKeywordArray addObject:@"long"];
        [finalKeywordArray addObject:@"sleeve"];
        [finalKeywordArray addObject:@"ls"];
        [finalKeywordArray addObject:@"long-sleeve"];
    }
    
    //shortsleeve
    if ([finalKeywordArray containsObject:@"shortsleeve"]) {
        [finalKeywordArray addObject:@"short-sleeve"];
        [finalKeywordArray addObject:@"short"];
        [finalKeywordArray addObject:@"sleeve"];
    }
    else if ([finalKeywordArray containsObject:@"short-sleeve"]) {
        [finalKeywordArray addObject:@"shortsleeve"];
        [finalKeywordArray addObject:@"short"];
        [finalKeywordArray addObject:@"sleeve"];
    }
    
    //shortsleeve
    if ([finalKeywordArray containsObject:@"jacket"]) {
        [finalKeywordArray addObject:@"coat"];
    }
    else if ([finalKeywordArray containsObject:@"coat"]) {
        [finalKeywordArray addObject:@"jacket"];
    }
    
    //puffa
    if ([finalKeywordArray containsObject:@"puffa"]) {
        [finalKeywordArray addObject:@"puffer"];
    }
    else if ([finalKeywordArray containsObject:@"puffer"]) {
        [finalKeywordArray addObject:@"puffa"];
    }
    
    //supreme
    if ([finalKeywordArray containsObject:@"supreme"]) {
        [finalKeywordArray addObject:@"preme"];
    }
    else if ([finalKeywordArray containsObject:@"preme"]) {
        [finalKeywordArray addObject:@"supreme"];
    }
    
    //camo
    if ([finalKeywordArray containsObject:@"camo"]) {
        [finalKeywordArray addObject:@"camouflage"];
        [finalKeywordArray addObject:@"camaflage"];
        [finalKeywordArray addObject:@"camauflage"];
    }
    else if ([finalKeywordArray containsObject:@"camouflage"]) {
        [finalKeywordArray addObject:@"camo"];
        [finalKeywordArray addObject:@"camaflage"];
        [finalKeywordArray addObject:@"camauflage"];
    }
    else if ([finalKeywordArray containsObject:@"camaflage"]) {
        [finalKeywordArray addObject:@"camo"];
        [finalKeywordArray addObject:@"camouflage"];
        [finalKeywordArray addObject:@"camauflage"];
    }
    else if ([finalKeywordArray containsObject:@"camauflage"]) {
        [finalKeywordArray addObject:@"camo"];
        [finalKeywordArray addObject:@"camouflage"];
        [finalKeywordArray addObject:@"camaflage"];
    }
    
    //LV
    if ([finalKeywordArray containsObject:@"louisvuitton"]) {
        [finalKeywordArray addObject:@"louis"];
        [finalKeywordArray addObject:@"vuitton"];
        [finalKeywordArray addObject:@"lv"];
    }
    else if ([finalKeywordArray containsObject:@"louis"] && [finalKeywordArray containsObject:@"vuitton"]) {
        [finalKeywordArray addObject:@"lv"];
        [finalKeywordArray addObject:@"louisvuitton"];
    }
    
    //TNF
    if ([finalKeywordArray containsObject:@"tnf"]) {
        [finalKeywordArray addObject:@"northface"];
        [finalKeywordArray addObject:@"north"];
        [finalKeywordArray addObject:@"face"];
    }
    else if ([finalKeywordArray containsObject:@"north"] && [finalKeywordArray containsObject:@"face"]) {
        [finalKeywordArray addObject:@"tnf"];
        [finalKeywordArray addObject:@"northface"];
    }
    
    
    //remove duplications
    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:finalKeywordArray];
    NSArray *arrayWithoutDuplicates = [orderedSet array];
    
    [finalKeywordArray removeAllObjects];
    [finalKeywordArray addObjectsFromArray:arrayWithoutDuplicates];
    
    return finalKeywordArray;
}
@end
