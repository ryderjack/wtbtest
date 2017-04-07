//
//  CreateForSaleListing.m
//  wtbtest
//
//  Created by Jack Ryder on 01/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "CreateForSaleListing.h"
#import "UIImage+Resize.h"
#import <Crashlytics/Crashlytics.h>
#import "NavigationController.h"
#import "SettingsController.h"

@interface CreateForSaleListing ()

@end

@implementation CreateForSaleListing

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"S E L L I N G";
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    //button setup
    [self.firstCam setEnabled:YES];
    [self.secondCam setEnabled:NO];
    [self.thirdCam setEnabled:NO];
    [self.fourthCam setEnabled:NO];
    
    [self.firstDelete setHidden:YES];
    [self.secondDelete setHidden:YES];
    [self.thirdDelete setHidden:YES];
    [self.fourthDelete setHidden:YES];
    
    self.firstImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.secondImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.thirdImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.fourthImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self.firstImageView setImage:[UIImage imageNamed:@"addImage"]];
    [self.secondImageView setImage:[UIImage imageNamed:@"camHolder"]];
    [self.thirdImageView setImage:[UIImage imageNamed:@"camHolder"]];
    [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
    
    self.firstImageView.layer.cornerRadius = 4;
    self.firstImageView.layer.masksToBounds = YES;
    
    self.secondImageView.layer.cornerRadius = 4;
    self.secondImageView.layer.masksToBounds = YES;
    
    self.thirdImageView.layer.cornerRadius = 4;
    self.thirdImageView.layer.masksToBounds = YES;
    
    self.fourthImageView.layer.cornerRadius = 4;
    self.fourthImageView.layer.masksToBounds = YES;
    
    self.payField.placeholder = @"Optional";
    self.genderSize = @"";
    self.photostotal = 0;
    self.descriptionField.delegate = self;
    self.payField.delegate = self;
    
    [self saleaddDoneButton];
    
    self.descriptionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.payCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.imageCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.spaceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.profanityList = @[@"cunt", @"wanker", @"nigger", @"penis", @"cock"];
    self.multipleSizeArray = [NSArray array];
    self.imagesToProcess = [NSMutableArray array];
    
    self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
    
    if (self.editMode == YES) {
        [self saleListingSetup];
        [self.longButton setTitle:@"U P D A T E" forState:UIControlStateNormal];
        
        [Answers logCustomEventWithName:@"Viewed page"
                       customAttributes:@{
                                          @"pageName":@"Create For Sale Listing",
                                          @"mode":@"Edit"
                                          }];
    }
    else{
        //don't reset a previous location when editing
        [self saleuseCurrentLoc];
        [self.longButton setTitle:@"C R E A T E" forState:UIControlStateNormal];
        
        [Answers logCustomEventWithName:@"Viewed page"
                       customAttributes:@{
                                          @"pageName":@"Create For Sale Listing",
                                          @"mode":@"New listing"
                                          }];
    }
    
    
    [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
    [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
    [self.longButton addTarget:self action:@selector(savePressed) forControlEvents:UIControlEventTouchUpInside];
    self.longButton.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
    
    [self showBarButton];
    
    if ([[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"]) {
        PFQuery *userQueryForRand = [PFUser query];
        [userQueryForRand whereKey:@"username" containedIn:@[self.usernameToCheck]];
        [userQueryForRand findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            for (PFUser *user in objects) {
                self.cabin = user;
                NSLog(@"cabin set %@",self.cabin);
            }
        }];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if (self.buttonShowing == NO) {
        [self showBarButton];
    }
    
    self.currency = [[PFUser currentUser]objectForKey:@"currency"];
    if ([self.currency isEqualToString:@"GBP"]) {
        self.currencySymbol = @"£";
    }
    else if ([self.currency isEqualToString:@"EUR"]) {
        self.currencySymbol = @"€";
    }
    else if ([self.currency isEqualToString:@"USD"]) {
        self.currencySymbol = @"$";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        return 5;
    }
    else if (section == 2){
        return 1;
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
            return self.imageCell;
        }
    }
    else if (indexPath.section ==1){
        if(indexPath.row == 0){
            return self.conditionCell;
        }
        else if(indexPath.row == 1){
            return self.categoryCell;
        }
        else if(indexPath.row == 2){
            return self.sizeCell;
        }
        else if(indexPath.row == 3){
            return self.locationCell;
        }
        else if(indexPath.row == 4){
            return self.payCell;
        }
    }
    else if (indexPath.section ==2){
        return self.descriptionCell;
    }
    else if (indexPath.section ==3){
        return self.spaceCell;
    }
    return nil;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    self.somethingChanged = YES;
    
    [self removeKeyboard];
    
    if (indexPath.section ==1){
        if(indexPath.row == 0){
            SelectViewController *vc = [[SelectViewController alloc]init];
            vc.delegate = self;
            vc.sellListing = YES;
            vc.setting = @"condition";
            self.selection = @"condition";
            
            if (![self.chooseCondition.text isEqualToString:@"select"]) {
                NSArray *selectedArray = [self.chooseCondition.text componentsSeparatedByString:@"."];
                vc.holdingArray = [NSArray arrayWithArray:selectedArray];
            }
            
            [self.navigationController pushViewController:vc animated:YES];
            
        }
        else if(indexPath.row == 1){
            SelectViewController *vc = [[SelectViewController alloc]init];
            vc.delegate = self;
            vc.setting = @"category";
            self.selection = @"category";
            
            if (![self.chooseCategroy.text isEqualToString:@"select"]) {
                NSArray *selectedArray = [self.chooseCategroy.text componentsSeparatedByString:@"."];
                vc.holdingArray = [NSArray arrayWithArray:selectedArray];
            }
            
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if(indexPath.row == 2){
            if ([self.chooseCategroy.text isEqualToString:@"select"]) {
                [self sizePopUp];
                [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                
            }
            else{
                if ([self.chooseCategroy.text isEqualToString:@"Footwear"]) {
                    SelectViewController *vc = [[SelectViewController alloc]init];
                    vc.delegate = self;
                    vc.setting = @"sizefoot";
                    vc.sellListing = YES;
                    vc.multipleAllowed = YES;
                    vc.holdingGender = [[NSString alloc]initWithString:self.genderSize];

                    // setup previously selected
                    if (![self.chooseSize.text isEqualToString:@"select"] && ![self.chooseSize.text isEqualToString:@"Multiple"]) {
                        NSArray *selectedArray = [self.chooseSize.text componentsSeparatedByString:@"/"];
                        NSLog(@"selected already %@", selectedArray);
                        vc.holdingArray = [NSArray arrayWithArray:selectedArray];
                        vc.holdingGender = [[NSString alloc]initWithString:self.genderSize];
                    }
                    else if ([self.chooseSize.text isEqualToString:@"Multiple"]){
                        NSMutableArray *placeholder = [NSMutableArray array];
                        
                        for (id object in self.multipleSizeArray) {
                            NSString *string = [NSString stringWithFormat:@"%@", object];
                            [placeholder addObject:string];
                        }
                        vc.holdingArray = placeholder;
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
                    vc.sellListing = YES;
                    vc.multipleAllowed = YES;
                    vc.holdingGender = [[NSString alloc]initWithString:self.genderSize];

                    // setup previously selected
                    if (![self.chooseSize.text isEqualToString:@"select"] && ![self.chooseSize.text isEqualToString:@"Multiple"]) {
                        NSArray *selectedArray = [self.chooseSize.text componentsSeparatedByString:@"/"];
                        vc.holdingArray = [NSArray arrayWithArray:selectedArray];
                    }
                    else if ([self.chooseSize.text isEqualToString:@"Multiple"]){
                        NSMutableArray *placeholder = [NSMutableArray array];
                        
                        for (id object in self.multipleSizeArray) {
                            NSString *string = [NSString stringWithFormat:@"%@", object];
                            [placeholder addObject:string];
                        }
                        vc.holdingArray = placeholder;
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
                    vc.sellListing = YES;
                    // setup previously selected
                    if (![self.chooseSize.text isEqualToString:@"select"]) {
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 104;
        }
    }
    else if (indexPath.section ==1){
        return 44;
    }
    else if (indexPath.section ==2){
        return 104;
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

-(void)dismissVC{
    //only show warning if listing is partially completed
    if (self.editMode == YES && self.somethingChanged == NO) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else{
        if ([self.descriptionField.text isEqualToString:@"e.g. Supreme Union Jack Bogo #box #logo"] && [self.chooseCondition.text isEqualToString:@"select"] && [self.chooseCategroy.text isEqualToString:@"select"] && [self.chooseSize.text isEqualToString:@"select"] && [self.payField.text isEqualToString:@""] && [self.firstImageView.image isEqual:[UIImage imageNamed:@"addImage"]]){
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else{
            UIAlertController *alertView;
            if (self.editMode == YES) {
                alertView = [UIAlertController alertControllerWithTitle:@"Leave this page?" message:@"Are you sure you want to leave? Your changes won't be saved!" preferredStyle:UIAlertControllerStyleAlert];
            }
            else{
                alertView = [UIAlertController alertControllerWithTitle:@"Cancel listing?" message:@"Are you sure you want to cancel your for-sale listing?" preferredStyle:UIAlertControllerStyleAlert];
            }
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Stay" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                if (self.editMode == YES) {
                    [self.navigationController popViewControllerAnimated:YES];
                }
                else{
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            }]];
            [self presentViewController:alertView animated:YES completion:nil];
        }
    }
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
    self.somethingChanged = YES;
    if ([textView.text isEqualToString:@"e.g. Supreme Union Jack Bogo #box #logo"]) {
        textView.text = @"";
        textView.textColor = [UIColor colorWithRed:74/255.0f green:74/255.0f blue:74/255.0f alpha:1.0f];
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.payField) {
        
        if ([self.payField.text isEqualToString:self.currencySymbol]) {
            self.payField.text = @"";
            return;
        }
        
        NSString *prefixToRemove = [NSString stringWithFormat:@"%@", self.currencySymbol];
        NSString *priceString = [[NSString alloc]init];
        priceString = [self.payField.text substringFromIndex:[prefixToRemove length]];
        
        NSArray *priceArray = [priceString componentsSeparatedByString:@"."];
        
        NSMutableArray *priceArrayMutable = [NSMutableArray arrayWithArray:priceArray];
        
        [priceArrayMutable removeObject:@""];
        
        priceArray = priceArrayMutable;
        
       // NSLog(@"price array %lu", (unsigned long)priceArray.count);
        
        if (priceArray.count == 0) {
            priceString = @"0.00";
        }
        else if (priceArray.count > 2) {
            NSLog(@"multiple decimal points added");
            priceString = @"0.00";
        }
        else if (priceArray.count == 1){
            NSString *intAmount = priceArray[0];
            NSLog(@"length of this int %@   int %lu",intAmount ,(unsigned long)intAmount.length);
            priceString = [NSString stringWithFormat:@"%@.00", intAmount];
        }
        else if (priceArray.count > 1){
            NSString *intAmount = priceArray[0];
            
            if (intAmount.length == 1){
                NSLog(@"single digit then a decimal point");
                intAmount = [NSString stringWithFormat:@"%@.00", intAmount];
            }
            else{
                //all good
                NSLog(@"length of int %lu", (unsigned long)intAmount.length);
            }
            
            NSMutableString *centAmount = priceArray[1];
            if (centAmount.length == 2){
                //all good
                NSLog(@"all good");
            }
            else if (centAmount.length == 1){
                NSLog(@"got 1 decimal place");
                centAmount = [NSMutableString stringWithFormat:@"%@0", centAmount];
            }
            else{
                NSLog(@"point but no numbers after it");
                centAmount = [NSMutableString stringWithFormat:@"00"];
            }
            
            priceString = [NSString stringWithFormat:@"%@.%@", intAmount, centAmount];
        }
        else{
            priceString = [NSString stringWithFormat:@"%@.00", priceString];
            NSLog(@"no decimal point so price is %@", priceString);
        }
        
        if ([priceString isEqualToString:[NSString stringWithFormat:@"%@0.00", self.currencySymbol]] || [priceString isEqualToString:@""] || [priceString isEqualToString:[NSString stringWithFormat:@"%@.00", self.currencySymbol]] || [priceString isEqualToString:@"  "]) {
            //invalid price number
            NSLog(@"invalid price number");
            self.payField.text = @"";
        }
        else{
            self.payField.text = [NSString stringWithFormat:@"%@%@", self.currencySymbol, priceString];
        }
    }
}
-(void)textViewDidEndEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"e.g. Supreme Union Jack Bogo #box #logo";
        textView.textColor = [UIColor lightGrayColor];
    }
    else{
        //they've wrote something so do the check for profanity
        NSArray *words = [textView.text componentsSeparatedByString:@" "];
        for (NSString *string in words) {
            if ([self.profanityList containsObject:string.lowercaseString]) {
                textView.text = @"e.g. Supreme Union Jack Bogo #box #logo";
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
    [self.descriptionField resignFirstResponder];
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
            
            if ([dollarAmount isEqualToString:@"£0"]) {
                return NO;
            }
            if (dollarAmount.length > 6)
                return NO;
            // not allowed to enter all 9s
            if ([dollarAmount isEqualToString:[NSString stringWithFormat:@"%@99999", self.currencySymbol]]) {
                return NO;
            }
        }
        return YES;
    }
    
    return YES;
}

-(void)alertSheet{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [self hideBarButton];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self showBarButton];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Take a picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Added for sale picture"
                       customAttributes:@{
                                          @"source":@"Camera"
                                          }];
        
        CameraController *vc = [[CameraController alloc]init];
        vc.delegate = self;
        vc.offerMode = YES;
        [self presentViewController:vc animated:YES completion:nil];
    }]];
    
//    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Choose from library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//        [Answers logCustomEventWithName:@"Added for sale picture"
//                       customAttributes:@{
//                                          @"source":@"Library"
//                                          }];
//        if (!self.picker) {
//            self.picker = [[UIImagePickerController alloc] init];
//            self.picker.delegate = self;
//            self.picker.allowsEditing = NO;
//            self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//        }
//        [self presentViewController:self.picker animated:YES completion:nil];
//    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Choose from library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        [Answers logCustomEventWithName:@"Added for sale picture"
                       customAttributes:@{
                                          @"source":@"Library"
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
                        imagePickerController.numberOfColumnsInPortrait = 3;
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
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self showAlertWithTitle:@"Library Permission" andMsg:@"Bump needs access to your photos to create a listing, enable this in your iPhone's Settings"];
                        });
                    });
                    NSLog(@"denied");
                }
                    break;
                default:
                    break;
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Choose from my Depop" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Added for sale picture"
                       customAttributes:@{
                                          @"source":@"Depop"
                                          }];
        BOOL seen = [[NSUserDefaults standardUserDefaults] boolForKey:@"seenDepop"];
        if (!seen) {
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Add Pics from your Depop" message:@"When you have the images of the items you'd like to send in the middle of your screen, hit 'Screenshot'!" preferredStyle:UIAlertControllerStyleAlert];
            [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self showDepop];
            }]];
            [self presentViewController:alertView animated:YES completion:nil];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"seenDepop"];
        }
        else{
            [self showDepop];
        }
    }]];

    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    [self dismissViewControllerAnimated:YES completion:^{
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        requestOptions.networkAccessAllowed = YES;

        PHImageManager *manager = [PHImageManager defaultManager];
        
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
                                if (self.imagesToProcess.count == assets.count) {
                                    [self processMultiple];
                                }
                            }];
        }
    }];
}

-(void)processMultiple{
    //got array of images to crop
    self.multipleMode = YES;
    
    if (self.imagesToProcess.count > 0) {
        [self displayCropperWithImage:self.imagesToProcess[0]];
    }
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(nonnull NSDictionary<NSString *,id> *)info{
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    
//    NSLog(@"size of OG image %f %f", chosenImage.size.width, chosenImage.size.height);
    
//    NSData *imgData1 = UIImageJPEGRepresentation(chosenImage, 1.0);
//    NSLog(@"BEFORE (bytes):%lu",(unsigned long)[imgData1 length]);
    
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
    [self.navigationController presentViewController:squareCropperViewController animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)squareCropperDidCropImage:(UIImage *)croppedImage inCropper:(BASSquareCropperViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
    
//    UIImage *newImage = [croppedImage resizedImage:CGSizeMake(750.00, 750.00) interpolationQuality:kCGInterpolationHigh];
    
//    NSLog(@"size of Cropped image %f %f", croppedImage.size.width, croppedImage.size.height);
//    
//    NSData *imgData = UIImageJPEGRepresentation(croppedImage, 1.0);
//    NSLog(@"CROPPED (bytes):%lu",(unsigned long)[imgData length]);
//    
//    NSData *imgData1 = UIImageJPEGRepresentation(newImage, 1.0);
//    NSLog(@"RESIZED (bytes):%lu",(unsigned long)[imgData1 length]);

    [self finalImage:croppedImage];
}

- (void)squareCropperDidCancelCropInCropper:(BASSquareCropperViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
    
    if (self.multipleMode == YES && self.imagesToProcess.count > 1) {
        [self.imagesToProcess removeObjectAtIndex:0];
        [self processMultiple];
    }
}

-(void)dismissPressed:(BOOL)yesorno{
    //do nothing in create VC
}

-(void)popUpAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Enter a description" message:@"Tell buyers what you're selling!" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)sizePopUp{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Choose a category first" message:@"Make sure you've entered a category for your item!" preferredStyle:UIAlertControllerStyleAlert];
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)locationPopUp{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Location error" message:@"Please try again!" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)resetForm{
    //ask if sure
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Reset listing?" message:@"Are you sure you want to start your listing again?" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [alertView addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
        self.chooseCategroy.text = @"select";
        self.chooseCondition.text = @"select";
        self.chooseLocation.text = @"select";
        self.chooseSize.text = @"select";
        self.payField.text = @"";
        self.descriptionField.text = @"e.g. Supreme Union Jack Bogo #box #logo";
        
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
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)finalImage:(UIImage *)image{
    UIImage *newImage = [image scaleImageToSize:CGSizeMake(750, 750)];

    self.somethingChanged = YES;
    
    if (self.multipleMode == YES) {
        if (self.photostotal == 0) {
            //add image to first image view
            [self.firstImageView setHidden:NO];
            [self.firstImageView setImage:newImage];
            
            [self.firstDelete setHidden:NO];
            [self.secondCam setEnabled:YES];
            [self.firstCam setEnabled:NO];
            
            [self.secondImageView setImage:[UIImage imageNamed:@"addImage"]];
            [self.thirdImageView setImage:[UIImage imageNamed:@"camHolder"]];
            [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.photostotal == 1){
            [self.secondImageView setHidden:NO];
            [self.secondImageView setImage:newImage];
            
            [self.secondDelete setHidden:NO];
            [self.thirdCam setEnabled:YES];
            [self.secondCam setEnabled:NO];
            
            [self.thirdImageView setImage:[UIImage imageNamed:@"addImage"]];
            [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.photostotal == 2){
            [self.thirdImageView setHidden:NO];
            [self.thirdImageView setImage:newImage];
            
            [self.thirdDelete setHidden:NO];
            [self.fourthCam setEnabled:YES];
            [self.thirdCam setEnabled:NO];
            
            [self.fourthImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else if (self.photostotal == 3){
            [self.fourthImageView setHidden:NO];
            [self.fourthImageView setImage:newImage];
            
            [self.fourthDelete setHidden:NO];
            [self.fourthCam setEnabled:NO];
        }
        
        self.photostotal ++;

        if (self.imagesToProcess.count > 0) {
            [self.imagesToProcess removeObjectAtIndex:0];
            
            //call process again
            [self processMultiple];
        }
    }
    else{
        if (self.camButtonTapped == 1) {
            [self.firstImageView setHidden:NO];
            [self.firstImageView setImage:newImage];
            
            [self.firstDelete setHidden:NO];
            [self.secondCam setEnabled:YES];
            [self.firstCam setEnabled:NO];
            
            [self.secondImageView setImage:[UIImage imageNamed:@"addImage"]];
            [self.thirdImageView setImage:[UIImage imageNamed:@"camHolder"]];
            [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.camButtonTapped ==2){
            [self.secondImageView setHidden:NO];
            [self.secondImageView setImage:newImage];
            
            [self.secondDelete setHidden:NO];
            [self.thirdCam setEnabled:YES];
            [self.secondCam setEnabled:NO];
            
            [self.thirdImageView setImage:[UIImage imageNamed:@"addImage"]];
            [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.camButtonTapped ==3){
            [self.thirdImageView setHidden:NO];
            [self.thirdImageView setImage:newImage];
            
            [self.thirdDelete setHidden:NO];
            [self.fourthCam setEnabled:YES];
            [self.thirdCam setEnabled:NO];
            
            [self.fourthImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else if (self.camButtonTapped ==4){
            [self.fourthImageView setHidden:NO];
            [self.fourthImageView setImage:newImage];
            
            [self.fourthDelete setHidden:NO];
            [self.fourthCam setEnabled:NO];
        }
        self.photostotal ++;
    }
}

- (void)saleaddDoneButton {
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
    [keyboardToolbar sizeToFit];
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self.view action:@selector(endEditing:)];
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    self.payField.inputAccessoryView = keyboardToolbar;
}

-(void)saleuseCurrentLoc{
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
                        self.geopoint = geoPoint;
                        self.chooseLocation.text = [NSString stringWithFormat:@"%@",titleString];
                    }
                    else{
                        NSLog(@"error with location");
                        self.chooseLocation.text = @"select";
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

-(void)tagString:(NSString *)tag{
    self.tagString = tag;
}

-(void)addItemViewController:(SelectViewController *)controller didFinishEnteringItem:(NSString *)selectionString withgender:(NSString *)genderString andsizes:(NSArray *)array{
    
    //empty array
    self.multipleSizeArray = @[];
    
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
        if ([selectionString isEqualToString:@"Accessories"]) {
            self.chooseSize.text = @"";
        }
        else{
            self.chooseSize.text = @"select";
        }
        self.chooseCategroy.text = selectionString;
    }
    else if ([self.selection isEqualToString:@"size"]){
        self.chooseSize.text = @"select";
        if (genderString) {
            self.genderSize = genderString;
        }
        if (array) {
            if (array.count == 1) {
                if ([array[0] isKindOfClass:[NSString class]]) {
                    if ([array[0] isEqualToString:@"Other"]) {
                       self.chooseSize.text = [NSString stringWithFormat:@"%@",array[0]];
                    }
                    else{
                        self.chooseSize.text = [NSString stringWithFormat:@"UK %@",array[0]];
                    }
                }
                else{
                    self.chooseSize.text = [NSString stringWithFormat:@"UK %@",array[0]];
                }
            }
            else if (array.count>1){
                self.chooseSize.text = @"Multiple";
                self.multipleSizeArray = array;
            }
        }
        else{
            NSLog(@"no array, been an error");
        }
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
        self.chooseLocation.text = @"select";
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
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

- (NSString*) tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger)section
{

    if (section ==0){
        return @"Add photos of the item you’re selling";
    }
    else if (section ==1){
        return @"Tell us what you're selling so we can show buyers";
    }
    else {
        return @"";
    }
}
-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return @"";
    
}

#pragma camera buttons

- (IBAction)firstCamPressed:(id)sender {
    if (self.firstCam.enabled == YES) {
        self.camButtonTapped = 1;
        [self alertSheet];
    }
}
- (IBAction)secondCamPressed:(id)sender {
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

- (IBAction)firstDeletePressed:(id)sender {
    if (self.photostotal == 1) {
        self.photostotal--;
        
        [UIView transitionWithView:self.firstImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.firstImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.firstCam setEnabled:YES];
                        }];
        
        [UIView transitionWithView:self.secondImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.secondImageView setImage:[UIImage imageNamed:@"camHolder"]];
                        } completion:^(BOOL finished) {
                            [self.secondCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.firstDelete setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [self.firstDelete setHidden:YES];
                             [self.firstDelete setAlpha:1.0f];
                         }];
    }
    else if (self.photostotal ==2){
        self.photostotal--;
        
        [UIView transitionWithView:self.firstImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.firstImageView setImage:self.secondImageView.image];
                        } completion:^(BOOL finished) {
                        }];
        
        [UIView transitionWithView:self.secondImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.secondImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.secondCam setEnabled:YES];
                        }];
        
        [UIView transitionWithView:self.thirdImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.thirdImageView setImage:[UIImage imageNamed:@"camHolder"]];
                        } completion:^(BOOL finished) {
                            [self.thirdCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.secondDelete setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [self.secondDelete setHidden:YES];
                             [self.secondDelete setAlpha:1.0f];
                         }];
    }
    else if (self.photostotal ==3){
        self.photostotal--;
    
        [UIView transitionWithView:self.firstImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.firstImageView setImage:self.secondImageView.image];
                        } completion:^(BOOL finished) {
                        }];
        
        [UIView transitionWithView:self.secondImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.secondImageView setImage:self.thirdImageView.image];
                        } completion:^(BOOL finished) {
                            [self.secondCam setEnabled:YES];
                        }];
        
        [UIView transitionWithView:self.thirdImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.thirdImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.thirdCam setEnabled:YES];
                        }];
        
        [UIView transitionWithView:self.fourthImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
                        } completion:^(BOOL finished) {
                            [self.fourthCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.thirdDelete setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [self.thirdDelete setHidden:YES];
                             [self.thirdDelete setAlpha:1.0f];
                         }];
    }
    else if (self.photostotal ==4){
        self.photostotal--;
        
        [UIView transitionWithView:self.firstImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.firstImageView setImage:self.secondImageView.image];
                        } completion:^(BOOL finished) {
                        }];
        
        [UIView transitionWithView:self.secondImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.secondImageView setImage:self.thirdImageView.image];
                        } completion:^(BOOL finished) {
                        }];
        
        [UIView transitionWithView:self.thirdImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.thirdImageView setImage:self.fourthImageView.image];
                        } completion:^(BOOL finished) {
                        }];
        
        [UIView transitionWithView:self.fourthImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.fourthImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.fourthCam setEnabled:YES];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.fourthDelete setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [self.fourthDelete setHidden:YES];
                             [self.fourthDelete setAlpha:1.0f];
                         }];
    }
}
- (IBAction)secondDeletePressed:(id)sender {
    
    if (self.photostotal ==2){
        self.photostotal--;
        
        [UIView transitionWithView:self.secondImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.secondImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.secondCam setEnabled:YES];
                        }];
        
        [UIView transitionWithView:self.thirdImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.thirdImageView setImage:[UIImage imageNamed:@"camHolder"]];
                        } completion:^(BOOL finished) {
                            [self.thirdCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.secondDelete setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [self.secondDelete setHidden:YES];
                             [self.secondDelete setAlpha:1.0f];
                         }];
    }
    else if (self.photostotal ==3){
        self.photostotal--;
        
        [UIView transitionWithView:self.secondImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.secondImageView setImage:self.thirdImageView.image];
                        } completion:^(BOOL finished) {
                        }];
        
        [UIView transitionWithView:self.thirdImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.thirdImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.thirdCam setEnabled:YES];
                        }];
        
        [UIView transitionWithView:self.fourthImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
                        } completion:^(BOOL finished) {
                            [self.fourthCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.thirdDelete setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [self.thirdDelete setHidden:YES];
                             [self.thirdDelete setAlpha:1.0f];
                         }];
    }
    else if (self.photostotal ==4){
        self.photostotal--;
        
        [UIView transitionWithView:self.secondImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.secondImageView setImage:self.thirdImageView.image];
                        } completion:^(BOOL finished) {
                        }];
        
        [UIView transitionWithView:self.thirdImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.thirdImageView setImage:self.fourthImageView.image];
                        } completion:^(BOOL finished) {
                        }];
        
        [UIView transitionWithView:self.fourthImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.fourthImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.fourthCam setEnabled:YES];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.fourthDelete setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [self.fourthDelete setHidden:YES];
                             [self.fourthDelete setAlpha:1.0f];
                         }];
    }
}
- (IBAction)thirdDeletePressed:(id)sender {
    
    if (self.photostotal ==3){
        self.photostotal--;
        
        [UIView transitionWithView:self.thirdImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.thirdImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.thirdCam setEnabled:YES];
                        }];
        
        [UIView transitionWithView:self.fourthImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
                        } completion:^(BOOL finished) {
                            [self.fourthCam setEnabled:NO];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.thirdDelete setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [self.thirdDelete setHidden:YES];
                             [self.thirdDelete setAlpha:1.0f];
                         }];
    }
    else if (self.photostotal ==4){
        self.photostotal--;
        
        [UIView transitionWithView:self.thirdImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.thirdImageView setImage:self.fourthImageView.image];
                        } completion:^(BOOL finished) {
                        }];
        
        [UIView transitionWithView:self.fourthImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.fourthImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.fourthCam setEnabled:YES];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.fourthDelete setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [self.fourthDelete setHidden:YES];
                             [self.fourthDelete setAlpha:1.0f];
                         }];
    }
}
- (IBAction)fourthDeletePressed:(id)sender {
    self.photostotal--;
    
    if (self.photostotal ==4){
        
        [UIView transitionWithView:self.fourthImageView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.fourthImageView setImage:[UIImage imageNamed:@"addImage"]];
                        } completion:^(BOOL finished) {
                            [self.fourthCam setEnabled:YES];
                        }];
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.fourthDelete setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             NSLog(@"FINISHED");
                             [self.fourthDelete setHidden:YES];
                             [self.fourthDelete setAlpha:1.0f];
                         }];
    }
}
- (void)savePressed{
    [self.longButton setEnabled:NO];
    
    NSString *descriptionCheck = [self.descriptionField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if([self.chooseCategroy.text isEqualToString:@"Accessories"] && ( [self.chooseCondition.text isEqualToString:@"select"] || [self.chooseLocation.text isEqualToString:@"select"] || [self.descriptionField.text isEqualToString:@"e.g. Supreme Union Jack Bogo #box #logo"] || self.photostotal == 0)){
        NSLog(@"accessories selected but haven't filled everything else in");
        [self showAlertWithTitle:@"Empty Fields" andMsg:@"Make sure you add all your item info!"];
        [self.longButton setEnabled:YES];
    }
    else if ([self.chooseCategroy.text isEqualToString:@"select"] || [self.chooseCondition.text isEqualToString:@"select"] || [self.chooseLocation.text isEqualToString:@"select"] || [self.chooseSize.text isEqualToString:@"select"] || [self.descriptionField.text isEqualToString:@"e.g. Supreme Union Jack Bogo #box #logo"]|| [descriptionCheck isEqualToString:@""] || self.photostotal == 0 ) {
        [self showAlertWithTitle:@"Empty Fields" andMsg:@"Make sure you add all your item info!"];
        [self.longButton setEnabled:YES];
    }
    else{
        [self showHUD];
        
        PFObject *forSaleItem;
        
        if (self.editMode == YES) {
            forSaleItem = self.listing;
        }
        else{
            forSaleItem = [PFObject objectWithClassName:@"forSaleItems"];
            [forSaleItem setObject:@0 forKey:@"views"];
        }
        
        NSString *priceCheck = [self.payField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (![priceCheck isEqualToString:@""] &&
            ![self.payField.text isEqualToString:[NSString stringWithFormat:@"%@0.00", self.currencySymbol]] &&
            ![self.payField.text isEqualToString:[NSString stringWithFormat:@"%@.00", self.currencySymbol]]) {
            
            NSString *prefixToRemove = [NSString stringWithFormat:@"%@", self.currencySymbol];
            NSString *priceString = [[NSString alloc]init];
            priceString = [self.payField.text substringFromIndex:[prefixToRemove length]];
            
            NSArray *priceArray = [priceString componentsSeparatedByString:@"."];
            if ([priceArray[0] isEqualToString:self.currencySymbol]) {
                priceString = [NSString stringWithFormat:@"%@0.00", self.currencySymbol];
            }
            else if (priceArray.count > 1){
                NSString *intAmount = priceArray[0];
                
                if (intAmount.length == 1){
                    NSLog(@"just the currency symbol then a decimal point");
                    intAmount = [NSString stringWithFormat:@"%@00", self.currencySymbol];
                }
                else{
                    //all good
                    NSLog(@"length of int %lu", (unsigned long)intAmount.length);
                }
                
                NSMutableString *centAmount = priceArray[1];
                if (centAmount.length == 2){
                    //all good
                }
                else if (centAmount.length == 1){
                    NSLog(@"got 1 decimal place");
                    centAmount = [NSMutableString stringWithFormat:@"%@0", centAmount];
                }
                else{
                    NSLog(@"point but no numbers after it");
                    centAmount = [NSMutableString stringWithFormat:@"%@00", centAmount];
                }
                
                priceString = [NSString stringWithFormat:@"%@.%@", intAmount, centAmount];
            }
            else{
                priceString = [NSString stringWithFormat:@"%@.00", priceString];
                NSLog(@"no decimal point so price is %@", priceString);
            }
            
            CGFloat strFloat = (CGFloat)[priceString floatValue];
            
            if ([self.currency isEqualToString:@"GBP"]) {
                forSaleItem[@"salePriceGBP"] = @(strFloat);
                float USD = strFloat*1.32;
                forSaleItem[@"salePriceUSD"] = @(USD);
                float EUR = strFloat*1.16;
                forSaleItem[@"salePriceEUR"] = @(EUR);
            }
            else if ([self.currency isEqualToString:@"USD"]) {
                forSaleItem[@"salePriceUSD"] = @(strFloat);
                float GBP = strFloat*0.76;
                forSaleItem[@"salePriceGBP"] = @(GBP);
                float EUR = strFloat*0.89;
                forSaleItem[@"salePriceEUR"] = @(EUR);
            }
            else if ([self.currency isEqualToString:@"EUR"]) {
                forSaleItem[@"salePriceEUR"] = @(strFloat);
                float GBP = strFloat*0.86;
                forSaleItem[@"salePriceGBP"] = @(GBP);
                float USD = strFloat*1.12;
                forSaleItem[@"salePriceUSD"] = @(USD);
            }
        }
        else{
            // price not set so save as 0.00 and in for sale listing, display this as 'Negotiable'
            forSaleItem[@"salePriceUSD"] = @(0.00);
            forSaleItem[@"salePriceGBP"] = @(0.00);
            forSaleItem[@"salePriceEUR"] = @(0.00);
        }
        
        NSString *descriptionKeywordsString = [self.descriptionField.text stringByReplacingOccurrencesOfString:@"#" withString:@""];
        NSString *description = [self.descriptionField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        [forSaleItem setObject:description forKey:@"description"];
        [forSaleItem setObject:[description  lowercaseString]forKey:@"descriptionLower"];
        [forSaleItem setObject:self.chooseCondition.text forKey:@"condition"];
        [forSaleItem setObject:self.chooseCategroy.text forKey:@"category"];
        [forSaleItem setObject:self.chooseSize.text forKey:@"sizeLabel"];
        [forSaleItem setObject:@"live" forKey:@"status"];
        
        if (self.multipleSizeArray.count != 0) {
            [forSaleItem setObject:self.multipleSizeArray forKey:@"multipleSizes"];
        }
        
        //save keywords (minus useless words)
        NSArray *wasteWords = [NSArray arrayWithObjects:@"x",@"to",@"with",@"and",@"the",@"wtb",@"or",@" ",@".",@"very",@"interested", @"in",@"wanted", @"",@"selling", @"new", @"condition", @"good", @"great",@"wts", nil];
        NSCharacterSet *charactersToRemove = [[NSCharacterSet alphanumericCharacterSet] invertedSet];

        NSString *title = [descriptionKeywordsString lowercaseString];
        NSArray *strings = [title componentsSeparatedByString:@" "];
        NSMutableArray *mutableStrings = [NSMutableArray arrayWithArray:strings];
        [mutableStrings removeObjectsInArray:wasteWords];
        [mutableStrings removeObjectsInArray:[NSArray arrayWithObject:charactersToRemove]];
        
        NSMutableArray *finalKeywordArray = [NSMutableArray array];
        
        for (NSString *string in mutableStrings) {
            if (![string canBeConvertedToEncoding:NSASCIIStringEncoding]) {
                NSLog(@"can't be converted %@", string);
            }
            else{
                [finalKeywordArray addObject:string];
            }
        }

        NSLog(@"keywords: %@", finalKeywordArray);
        
        [forSaleItem setObject:finalKeywordArray forKey:@"keywords"];
        
        if (![self.genderSize isEqualToString:@""]) {
            [forSaleItem setObject:self.genderSize forKey:@"sizeGender"];
        }
        [forSaleItem setObject:self.chooseLocation.text forKey:@"location"];
        [forSaleItem setObject:self.geopoint forKey:@"geopoint"];
        [forSaleItem setObject:self.currency forKey:@"currency"];
        
        if ([[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"]) {
            [forSaleItem setObject:self.cabin forKey:@"sellerUser"];
        }
        else{
            [forSaleItem setObject:[PFUser currentUser] forKey:@"sellerUser"];
        }
        
        UIImage *imageOne = [self.firstImageView.image scaleImageToSize:CGSizeMake(200, 200)];
        
        NSData* dataOne = UIImageJPEGRepresentation(imageOne, 0.8f);
        PFFile *thumbFile = [PFFile fileWithName:@"thumb1.jpg" data:dataOne];
        [forSaleItem setObject:thumbFile forKey:@"thumbnail"];
        
        if (self.photostotal == 1) {
            NSData* data = UIImageJPEGRepresentation(self.firstImageView.image, 0.8f);
            
            if (data == nil) {
                [Answers logCustomEventWithName:@"PFFile Nil Data"
                               customAttributes:@{
                                                  @"pageName":@"Selling",
                                                  @"imageView":@"first",
                                                  @"photosTotal":@1
                                                  }];
                
                //prevent crash when creating a PFFile with nil data
                [self hidHUD];
                [self showAlertWithTitle:@"Image Error" andMsg:@"Please check your connection and try again!"];
                [self.longButton setEnabled:YES];
                return;
            }
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            if (self.editMode == YES) {
                [self.listing removeObjectForKey:@"image2"];
                [self.listing removeObjectForKey:@"image3"];
                [self.listing removeObjectForKey:@"image4"];
            }
        }
        else if (self.photostotal == 2){
            NSData* data1 = UIImageJPEGRepresentation(self.firstImageView.image, 0.8f);
            
            if (data1 == nil) {
                [Answers logCustomEventWithName:@"PFFile Nil Data"
                               customAttributes:@{
                                                  @"pageName":@"Selling",
                                                  @"imageView":@"first",
                                                  @"photosTotal":@2
                                                  }];
                
                //prevent crash when creating a PFFile with nil data
                [self hidHUD];
                [self showAlertWithTitle:@"Image Error" andMsg:@"Please check your connection and try again!"];
                [self.longButton setEnabled:YES];
                return;
            }
            
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data1];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            NSData* data2 = UIImageJPEGRepresentation(self.secondImageView.image, 0.8f);
            
            if (data2 == nil) {
                [Answers logCustomEventWithName:@"PFFile Nil Data"
                               customAttributes:@{
                                                  @"pageName":@"Selling",
                                                  @"imageView":@"second",
                                                  @"photosTotal":@2
                                                  }];
                
                //prevent crash when creating a PFFile with nil data
                [self hidHUD];
                [self showAlertWithTitle:@"Image Error" andMsg:@"Please check your connection and try again!"];
                [self.longButton setEnabled:YES];
                return;
            }
            
            PFFile *imageFile2 = [PFFile fileWithName:@"Image2.jpg" data:data2];
            [forSaleItem setObject:imageFile2 forKey:@"image2"];
            
            if (self.editMode == YES) {
                [self.listing removeObjectForKey:@"image3"];
                [self.listing removeObjectForKey:@"image4"];
            }
        }
        else if (self.photostotal == 3){
            NSData* data1 = UIImageJPEGRepresentation(self.firstImageView.image, 0.8);
            if (data1 == nil) {
                [Answers logCustomEventWithName:@"PFFile Nil Data"
                               customAttributes:@{
                                                  @"pageName":@"Selling",
                                                  @"imageView":@"first",
                                                  @"photosTotal":@3
                                                  }];
                
                //prevent crash when creating a PFFile with nil data
                [self hidHUD];
                [self showAlertWithTitle:@"Image Error" andMsg:@"Please check your connection and try again!"];
                [self.longButton setEnabled:YES];
                return;
            }
            
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data1];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            NSData* data2 = UIImageJPEGRepresentation(self.secondImageView.image, 0.8f);
            
            if (data2 == nil) {
                [Answers logCustomEventWithName:@"PFFile Nil Data"
                               customAttributes:@{
                                                  @"pageName":@"Selling",
                                                  @"imageView":@"second",
                                                  @"photosTotal":@3
                                                  }];
                
                //prevent crash when creating a PFFile with nil data
                [self hidHUD];
                [self showAlertWithTitle:@"Image Error" andMsg:@"Please check your connection and try again!"];
                [self.longButton setEnabled:YES];
                return;
            }
            
            PFFile *imageFile2 = [PFFile fileWithName:@"Image2.jpg" data:data2];
            [forSaleItem setObject:imageFile2 forKey:@"image2"];
            
            NSData* data3 = UIImageJPEGRepresentation(self.thirdImageView.image, 0.8f);
            
            if (data3 == nil) {
                [Answers logCustomEventWithName:@"PFFile Nil Data"
                               customAttributes:@{
                                                  @"pageName":@"Selling",
                                                  @"imageView":@"third",
                                                  @"photosTotal":@3
                                                  }];
                
                //prevent crash when creating a PFFile with nil data
                [self hidHUD];
                [self showAlertWithTitle:@"Image Error" andMsg:@"Please check your connection and try again!"];
                [self.longButton setEnabled:YES];
                return;
            }
            
            PFFile *imageFile3 = [PFFile fileWithName:@"Imag3.jpg" data:data3];
            [forSaleItem setObject:imageFile3 forKey:@"image3"];
            
            if (self.editMode == YES) {
                [self.listing removeObjectForKey:@"image4"];
            }
        }
        else if (self.photostotal == 4){
            NSData* data1 = UIImageJPEGRepresentation(self.firstImageView.image, 0.8f);
            
            if (data1 == nil) {
                [Answers logCustomEventWithName:@"PFFile Nil Data"
                               customAttributes:@{
                                                  @"pageName":@"Selling",
                                                  @"imageView":@"first",
                                                  @"photosTotal":@4
                                                  }];
                
                //prevent crash when creating a PFFile with nil data
                [self hidHUD];
                [self showAlertWithTitle:@"Image Error" andMsg:@"Please check your connection and try again!"];
                [self.longButton setEnabled:YES];
                return;
            }
            
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data1];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            NSData* data2 = UIImageJPEGRepresentation(self.secondImageView.image, 0.8f);
            
            if (data2 == nil) {
                [Answers logCustomEventWithName:@"PFFile Nil Data"
                               customAttributes:@{
                                                  @"pageName":@"Selling",
                                                  @"imageView":@"second",
                                                  @"photosTotal":@4
                                                  }];
                
                //prevent crash when creating a PFFile with nil data
                [self hidHUD];
                [self showAlertWithTitle:@"Image Error" andMsg:@"Please check your connection and try again!"];
                [self.longButton setEnabled:YES];
                return;
            }
            
            PFFile *imageFile2 = [PFFile fileWithName:@"Image2.jpg" data:data2];
            [forSaleItem setObject:imageFile2 forKey:@"image2"];
            
            NSData* data3 = UIImageJPEGRepresentation(self.thirdImageView.image, 0.8f);
            
            if (data3 == nil) {
                [Answers logCustomEventWithName:@"PFFile Nil Data"
                               customAttributes:@{
                                                  @"pageName":@"Selling",
                                                  @"imageView":@"third",
                                                  @"photosTotal":@4
                                                  }];
                
                //prevent crash when creating a PFFile with nil data
                [self hidHUD];
                [self showAlertWithTitle:@"Image Error" andMsg:@"Please check your connection and try again!"];
                [self.longButton setEnabled:YES];
                return;
            }
            
            PFFile *imageFile3 = [PFFile fileWithName:@"Imag3.jpg" data:data3];
            [forSaleItem setObject:imageFile3 forKey:@"image3"];
            
            NSData* data4 = UIImageJPEGRepresentation(self.fourthImageView.image, 0.8f);
            
            if (data4 == nil) {
                [Answers logCustomEventWithName:@"PFFile Nil Data"
                               customAttributes:@{
                                                  @"pageName":@"Selling",
                                                  @"imageView":@"fourth",
                                                  @"photosTotal":@4
                                                  }];
                
                //prevent crash when creating a PFFile with nil data
                [self hidHUD];
                [self showAlertWithTitle:@"Image Error" andMsg:@"Please check your connection and try again!"];
                [self.longButton setEnabled:YES];
                return;
            }
            PFFile *imageFile4 = [PFFile fileWithName:@"Imag4.jpg" data:data4];
            [forSaleItem setObject:imageFile4 forKey:@"image4"];
        }
        
        PFQuery *latestIndex = [PFQuery queryWithClassName:@"forSaleItems"];
        [forSaleItem setObject:[NSDate date] forKey:@"lastUpdated"];
        [latestIndex countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
            if (number) {
                NSNumber *index = [NSNumber numberWithInt:number+1];
                [forSaleItem setObject:index forKey:@"index"];
                [forSaleItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        
                        [Answers logCustomEventWithName:@"Created for sale listing"
                                       customAttributes:@{}];
                        
                        if ([[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"]) {
                            [self.cabin incrementKey:@"forSalePostNumber"];
                            [self.cabin saveInBackground];
                        }
                        else{
                            [[PFUser currentUser]incrementKey:@"forSalePostNumber"];
                            [[PFUser currentUser] saveInBackground];
                        }
                        
                        [self.longButton setEnabled:YES];
                        
                        self.hud.labelText = @"Posted!";
                        
                        double delayInSeconds = 1.0; // number of seconds to wait
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            if (self.editMode == YES) {
                                [self.navigationController popViewControllerAnimated:YES];
                            }
                            else{
                                [self dismissViewControllerAnimated:YES completion:nil];
                            }
                        });
                    }
                    else{
                        //error saving listing
                        [self hidHUD];
                        [self.longButton setEnabled:YES];
                        NSLog(@"error saving %@", error);
                    }
                }];
            }
            else{
                NSLog(@"error counting %@", error);
                [self hidHUD];
                [self showAlertWithTitle:@"Save Error" andMsg:@"Check your connection and try again!"];
                [self.longButton setEnabled:YES];
                return;
            }
        }];
    }
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
}

-(void)hidHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
}

-(void)viewWillDisappear:(BOOL)animated{
    [self hidHUD];
    [self hideBarButton];
}

-(void)saleListingSetup{
    self.navigationItem.title = @"E D I T";
    
    self.descriptionField.text = [self.listing objectForKey:@"description"];
    
    NSString *symbol = @"";
    
    if ([[self.listing objectForKey:@"currency"] isEqualToString:@"GBP"]) {
        symbol = @"£";
    }
    else{
        symbol = @"$";
    }
    float price = [[self.listing objectForKey:@"salePriceUSD"]floatValue]; //if it wasn't set all prices should be 0.00

    if (price == 0.00) {
        self.payField.text = @"";
    }
    else{
        self.payField.text = [NSString stringWithFormat:@"%@%@",symbol,[self.listing objectForKey:[NSString stringWithFormat:@"salePrice%@", [self.listing objectForKey:@"currency"]]]];
    }
    
    self.chooseCondition.text = [self.listing objectForKey:@"condition"];
    
    //location is not updatable when editing listing
    self.chooseLocation.text = [self.listing objectForKey:@"location"];
    self.locationCell.accessoryType = UITableViewCellAccessoryNone;
    self.locationCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.chooseCategroy.text = [self.listing objectForKey:@"category"];
    
    //sizing
    NSString *sizeLabel = [self.listing objectForKey:@"sizeLabel"];
    
    if ([sizeLabel isEqualToString:@"Multiple"]) {
        self.multipleSizeArray = [self.listing objectForKey:@"multipleSizes"];
    }

    self.chooseSize.text = sizeLabel;
    
    //if gendersize required (if category is footwear) set variable
    if ([self.listing objectForKey:@"sizeGender"]) {
        self.genderSize = [self.listing objectForKey:@"sizeGender"];
    }
    
    self.geopoint = [self.listing objectForKey:@"geopoint"];
    
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
        self.photostotal = 2;
    }
    
    if ([self.listing objectForKey:@"image3"]) {
        [self.thirdImageView setFile:[self.listing objectForKey:@"image3"]];
        [self.thirdImageView loadInBackground];
        
        [self.thirdDelete setHidden:NO];
        [self.fourthCam setEnabled:YES];
        [self.thirdCam setEnabled:NO];
        
        [self.fourthImageView setImage:[UIImage imageNamed:@"addImage"]];
        self.photostotal = 3;
    }
    
    if ([self.listing objectForKey:@"image4"]) {
        [self.fourthImageView setFile:[self.listing objectForKey:@"image4"]];
        [self.fourthImageView loadInBackground];
        
        [self.fourthDelete setHidden:NO];
        [self.fourthCam setEnabled:NO];
        self.photostotal = 4;
    }
}


-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)showDepop{
    if ([[PFUser currentUser]objectForKey:@"depopHandle"]) {
        //has added their depop handle
        NSString *handle = [[PFUser currentUser]objectForKey:@"depopHandle"];
        NSString *URLString = [NSString stringWithFormat:@"http://depop.com/%@",handle];
        self.webViewController = nil;
        self.webViewController = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
        self.webViewController.title = [NSString stringWithFormat:@"%@", handle];
        self.webViewController.showUrlWhileLoading = NO;
        self.webViewController.showPageTitles = NO;
        self.webViewController.delegate = self;
        self.webViewController.depopMode = YES;
        self.webViewController.doneButtonTitle = @"";
        self.webViewController.infoMode = NO;
        NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.webViewController];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
    else{
        //hasn't added handle, prompt to do so
        [self showDepopAlert];
    }
}

-(void)showDepopAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"No Depop Username" message:@"Add your Depop Username in Settings on Bump and you'll be able to add images of items you've already listed there without leaving Bump #zerofees" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"ADD" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Add Depop Pressed in Create For Sale"
                       customAttributes:@{}];
        SettingsController *vc = [[SettingsController alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    }]];
    [alertView addAction:[UIAlertAction actionWithTitle:@"Later" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Add Depop Later in Create For Sale"
                       customAttributes:@{}];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)paidPressed{
    //do nothing
}

-(void)cancelWebPressed{
    [self.webViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)cameraPressed{
    //do nothing
}

-(void)screeshotPressed:(UIImage *)screenshot withTaps:(int)taps{
    [self.webViewController dismissViewControllerAnimated:YES completion:^{
        [self displayCropperWithImage:screenshot];
    }];
}

-(void)showBarButton{
    NSLog(@"SHOW");
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

-(void)hideBarButton{
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
@end
