//
//  CreateForSaleListing.m
//  wtbtest
//
//  Created by Jack Ryder on 01/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "CreateForSaleListing.h"
#import "UIImage+Resize.h"

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
    
    [self useCurrentLoc];
    
    self.payField.placeholder = @"";
    self.warningLabel.text = @"";
    self.genderSize = @"";
    self.photostotal = 0;
    self.descriptionField.delegate = self;
    self.payField.delegate = self;
    
    [self addDoneButton];
    
    self.descriptionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.payCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.imageCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.profanityList = @[@"fuck",@"fucking",@"shitting", @"cunt", @"sex", @"wanker", @"nigger", @"penis", @"cock", @"shit", @"dick", @"bastard"];
    
    if (self.editMode == YES) {
        [self listingSetup];
    }
    
//    PFQuery *userQueryForRand = [PFUser query];
//    [userQueryForRand whereKey:@"username" containedIn:@[self.usernameToCheck]];
//    [userQueryForRand findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//        for (PFUser *user in objects) {
//            self.cabin = user;
//            NSLog(@"cabin set %@",self.cabin);
//        }
//    }];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.currency = [[PFUser currentUser]objectForKey:@"currency"];
    if ([self.currency isEqualToString:@"GBP"]) {
        self.currencySymbol = @"£";
        self.payField.placeholder = @"£100";
    }
    else if ([self.currency isEqualToString:@"EUR"]) {
        self.currencySymbol = @"€";
        self.payField.placeholder = @"€100";
    }
    else if ([self.currency isEqualToString:@"USD"]) {
        self.currencySymbol = @"$";
        self.payField.placeholder = @"$100";
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
        return self.buttonCell;
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
                    
                    // setup previously selected
                    if (![self.chooseSize.text isEqualToString:@"select"]) {
                        NSArray *selectedArray = [self.chooseSize.text componentsSeparatedByString:@"/"];
                        NSLog(@"selected already %@", selectedArray);
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
                    vc.sellListing = YES;
                    // setup previously selected
                    if (![self.chooseSize.text isEqualToString:@"select"]) {
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
        return 98;
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
        [self dismissViewControllerAnimated:YES completion:nil];
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
    if (textField == self.payField) {
        self.payField.text = [NSString stringWithFormat:@"%@", self.currencySymbol];
    }
}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@"e.g. Supreme Union Jack Bogo #box #logo"]) {
        textView.text = @"";
        textView.textColor = [UIColor colorWithRed:74/255.0f green:74/255.0f blue:74/255.0f alpha:1.0f];
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.payField) {
        NSString *prefixToRemove = [NSString stringWithFormat:@"%@", self.currencySymbol];
        NSString *priceString = [[NSString alloc]init];
        priceString = [self.payField.text substringFromIndex:[prefixToRemove length]];
        
        NSArray *priceArray = [priceString componentsSeparatedByString:@"."];
        
        NSMutableArray *priceArrayMutable = [NSMutableArray arrayWithArray:priceArray];
        
        [priceArrayMutable removeObject:@""];
        
        priceArray = priceArrayMutable;
        
        NSLog(@"price array %lu", (unsigned long)priceArray.count);
        
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
            self.warningLabel.text = @"Enter a valid price!";
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
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Take a picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        CameraController *vc = [[CameraController alloc]init];
        vc.delegate = self;
        vc.offerMode = YES;
        [self presentViewController:vc animated:YES completion:nil];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Choose from library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (!self.picker) {
            self.picker = [[UIImagePickerController alloc] init];
            self.picker.delegate = self;
            self.picker.allowsEditing = NO;
            self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        [self presentViewController:self.picker animated:YES completion:nil];
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    
//    NSLog(@"size of OG image %f %f", chosenImage.size.width, chosenImage.size.height);
    
//    NSData *imgData1 = UIImageJPEGRepresentation(chosenImage, 1.0);
//    NSLog(@"BEFORE (bytes):%lu",(unsigned long)[imgData1 length]);
    
    //display crop picker
    [picker dismissViewControllerAnimated:YES completion:^{
        [self displayCropperWithImage:chosenImage];
    }];
}

- (UIImage *)resizeImage:(UIImage *)image toWidth:(float)width andHeight:(float)height {
    
    CGSize newSize = CGSizeMake(width, height);
    CGRect newRectangle = CGRectMake(0, 0, width, height);
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:newRectangle];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
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
    
    UIImage *newImage = [croppedImage resizedImage:CGSizeMake(750.00, 750.00) interpolationQuality:kCGInterpolationHigh];
    
//    NSLog(@"size of Cropped image %f %f", croppedImage.size.width, croppedImage.size.height);
//    
//    NSData *imgData = UIImageJPEGRepresentation(croppedImage, 1.0);
//    NSLog(@"CROPPED (bytes):%lu",(unsigned long)[imgData length]);
//    
//    NSData *imgData1 = UIImageJPEGRepresentation(newImage, 1.0);
//    NSLog(@"RESIZED (bytes):%lu",(unsigned long)[imgData1 length]);

    [self finalImage:newImage];
}

- (void)squareCropperDidCancelCropInCropper:(BASSquareCropperViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
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
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Choose a category first!" message:@"Make sure you've entered a category for your item!" preferredStyle:UIAlertControllerStyleAlert];
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
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    self.chooseCategroy.text = @"select";
    self.chooseCondition.text = @"select";
    self.chooseLocation.text = @"select";
    self.chooseSize.text = @"select";
    self.payField.text = @"";
    self.descriptionField.text = @"e.g. Supreme Union Jack Bogo #box #logo";
    self.warningLabel.text = @"";
    
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
    
    [self.saveButton setImage:[UIImage imageNamed:@"buyButton"] forState:UIControlStateNormal];
    
    self.photostotal = 0;
    self.camButtonTapped = 0;
    
    self.geopoint = nil;
}

-(void)finalImage:(UIImage *)image{
    if (self.camButtonTapped == 1) {
        [self.firstImageView setHidden:NO];
        [self.firstImageView setImage:image];
        
        [self.firstDelete setHidden:NO];
        [self.secondCam setEnabled:YES];
        [self.firstCam setEnabled:NO];
        
        [self.secondImageView setImage:[UIImage imageNamed:@"addImage"]];
        [self.thirdImageView setImage:[UIImage imageNamed:@"camHolder"]];
        [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
    }
    else if (self.camButtonTapped ==2){
        [self.secondImageView setHidden:NO];
        [self.secondImageView setImage:image];
        
        [self.secondDelete setHidden:NO];
        [self.thirdCam setEnabled:YES];
        [self.secondCam setEnabled:NO];
        
        [self.thirdImageView setImage:[UIImage imageNamed:@"addImage"]];
        [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
    }
    else if (self.camButtonTapped ==3){
        [self.thirdImageView setHidden:NO];
        [self.thirdImageView setImage:image];
        
        [self.thirdDelete setHidden:NO];
        [self.fourthCam setEnabled:YES];
        [self.thirdCam setEnabled:NO];
        
        [self.fourthImageView setImage:[UIImage imageNamed:@"addImage"]];
    }
    else if (self.camButtonTapped ==4){
        [self.fourthImageView setHidden:NO];
        [self.fourthImageView setImage:image];
        
        [self.fourthDelete setHidden:NO];
        [self.fourthCam setEnabled:NO];
    }
    self.photostotal ++;
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
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    self.payField.inputAccessoryView = keyboardToolbar;
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
                    NSString *titleString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.administrativeArea];
                    
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
        [self.firstImageView setImage:[UIImage imageNamed:@"addImage"]];
        [self.secondImageView setImage:[UIImage imageNamed:@"camHolder"]];
        [self.firstDelete setHidden:YES];
        
        [self.firstCam setEnabled:YES];
        [self.secondCam setEnabled:NO];
    }
    else if (self.photostotal ==2){
        self.photostotal--;
        [self.firstImageView setImage:self.secondImageView.image];
        [self.secondImageView setImage:[UIImage imageNamed:@"addImage"]];
        [self.thirdImageView setImage:[UIImage imageNamed:@"camHolder"]];
        [self.secondDelete setHidden:YES];
        
        [self.secondCam setEnabled:YES];
        [self.thirdCam setEnabled:NO];
    }
    else if (self.photostotal ==3){
        self.photostotal--;
        [self.firstImageView setImage:self.secondImageView.image];
        [self.secondImageView setImage:self.thirdImageView.image];
        [self.thirdImageView setImage:[UIImage imageNamed:@"addImage"]];
        [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
        [self.thirdDelete setHidden:YES];
        
        [self.thirdCam setEnabled:YES];
        [self.fourthCam setEnabled:NO];
    }
    else if (self.photostotal ==4){
        self.photostotal--;
        [self.firstImageView setImage:self.secondImageView.image];
        [self.secondImageView setImage:self.thirdImageView.image];
        [self.thirdImageView setImage:self.fourthImageView.image];
        [self.fourthImageView setImage:[UIImage imageNamed:@"addImage"]];
        [self.fourthDelete setHidden:YES];
        [self.fourthCam setEnabled:YES];
    }
}
- (IBAction)secondDeletePressed:(id)sender {
    
    if (self.photostotal ==2){
        self.photostotal--;
        [self.secondImageView setImage:[UIImage imageNamed:@"addImage"]];
        [self.thirdImageView setImage:[UIImage imageNamed:@"camHolder"]];
        [self.secondDelete setHidden:YES];
        
        [self.secondCam setEnabled:YES];
        [self.thirdCam setEnabled:NO];
    }
    else if (self.photostotal ==3){
        self.photostotal--;
        [self.secondImageView setImage:self.thirdImageView.image];
        [self.thirdImageView setImage:[UIImage imageNamed:@"addImage"]];
        [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
        [self.thirdDelete setHidden:YES];
        
        [self.thirdCam setEnabled:YES];
        [self.fourthCam setEnabled:NO];
    }
    else if (self.photostotal ==4){
        self.photostotal--;
        [self.secondImageView setImage:self.thirdImageView.image];
        [self.thirdImageView setImage:self.fourthImageView.image];
        [self.fourthImageView setImage:[UIImage imageNamed:@"addImage"]];
        [self.fourthDelete setHidden:YES];
        [self.fourthCam setEnabled:YES];
    }
}
- (IBAction)thirdDeletePressed:(id)sender {
    
    if (self.photostotal ==3){
        self.photostotal--;
        [self.thirdImageView setImage:[UIImage imageNamed:@"addImage"]];
        [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
        [self.thirdDelete setHidden:YES];
        
        [self.thirdCam setEnabled:YES];
        [self.fourthCam setEnabled:NO];
    }
    else if (self.photostotal ==4){
        self.photostotal--;
        [self.thirdImageView setImage:self.fourthImageView.image];
        [self.fourthImageView setImage:[UIImage imageNamed:@"addImage"]];
        [self.fourthDelete setHidden:YES];
        [self.fourthCam setEnabled:YES];
    }
}
- (IBAction)fourthDeletePressed:(id)sender {
    self.photostotal--;
    [self.fourthImageView setImage:[UIImage imageNamed:@"addImage"]];
    [self.fourthCam setEnabled:YES];
    [self.fourthDelete setHidden:YES];
}
- (IBAction)listItemPressed:(id)sender {
    [self.saveButton setEnabled:NO];
    
    NSString *descriptionCheck = [self.descriptionField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if([self.chooseCategroy.text isEqualToString:@"Accessories"] && ( [self.chooseCondition.text isEqualToString:@"select"] || [self.chooseLocation.text isEqualToString:@"select"] || [self.descriptionField.text isEqualToString:@"e.g. Supreme Union Jack Bogo #box #logo"]|| [self.payField.text isEqualToString:@""] || self.photostotal == 0 || [self.payField.text isEqualToString:[NSString stringWithFormat:@"%@", self.currencySymbol]])){
        NSLog(@"accessories selected but haven't filled everything else in");
        self.warningLabel.text = @"Fill out all the above fields";
        [self.saveButton setEnabled:YES];
    }
    else if ([self.chooseCategroy.text isEqualToString:@"select"] || [self.chooseCondition.text isEqualToString:@"select"] || [self.chooseLocation.text isEqualToString:@"select"] || [self.chooseSize.text isEqualToString:@"select"] || [self.payField.text isEqualToString:@""] || [self.descriptionField.text isEqualToString:@"e.g. Supreme Union Jack Bogo #box #logo"]|| [descriptionCheck isEqualToString:@""] || self.photostotal == 0 || [self.payField.text isEqualToString:[NSString stringWithFormat:@"%@", self.currencySymbol]]) {
        self.warningLabel.text = @"Fill out all the above fields";
        [self.saveButton setEnabled:YES];
    }
    else{
        [self showHUD];
        
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
        
        if ([priceString isEqualToString:[NSString stringWithFormat:@"%@0.00", self.currencySymbol]] || [priceString isEqualToString:@""] || [priceString isEqualToString:[NSString stringWithFormat:@"%@.00", self.currencySymbol]] || [priceString isEqualToString:@"  "]) {
            //invalid price number
            NSLog(@"invalid price number");
            self.warningLabel.text = @"Enter a valid price!";
            [self.saveButton setEnabled:YES];
            return;
        }
        
        CGFloat strFloat = (CGFloat)[priceString floatValue];
        
        PFObject *forSaleItem;
        
        if (self.editMode == YES) {
            forSaleItem = self.listing;
        }
        else{
            forSaleItem = [PFObject objectWithClassName:@"forSaleItems"];
            [forSaleItem setObject:@0 forKey:@"views"];
        }
        
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
        
        NSString *descriptionKeywordsString = [self.descriptionField.text stringByReplacingOccurrencesOfString:@"#" withString:@""];
        
        [forSaleItem setObject:self.descriptionField.text forKey:@"description"];
        [forSaleItem setObject:[self.descriptionField.text  lowercaseString]forKey:@"descriptionLower"];
        [forSaleItem setObject:self.chooseCondition.text forKey:@"condition"];
        [forSaleItem setObject:self.chooseCategroy.text forKey:@"category"];
        [forSaleItem setObject:self.chooseSize.text forKey:@"sizeLabel"];
        [forSaleItem setObject:@"live" forKey:@"status"];
        
        //save keywords (minus useless words)
        NSArray *wasteWords = [NSArray arrayWithObjects:@"x",@"to",@"with",@"and",@"the",@"wtb",@"or",@" ",@".",@"very",@"interested", @"in",@"wanted", @"",@"selling", @"new", @"condition", @"good", @"great",@"wts", nil];
        
        NSString *title = [descriptionKeywordsString lowercaseString];
        NSArray *strings = [title componentsSeparatedByString:@" "];
        NSMutableArray *mutableStrings = [NSMutableArray arrayWithArray:strings];
        [mutableStrings removeObjectsInArray:wasteWords];
        [forSaleItem setObject:mutableStrings forKey:@"keywords"];
        
        if (![self.genderSize isEqualToString:@""]) {
            [forSaleItem setObject:self.genderSize forKey:@"sizeGender"];
        }
        [forSaleItem setObject:self.chooseLocation.text forKey:@"location"];
        [forSaleItem setObject:self.geopoint forKey:@"geopoint"];
        [forSaleItem setObject:self.currency forKey:@"currency"];
        [forSaleItem setObject:[PFUser currentUser] forKey:@"sellerUser"];
//        [forSaleItem setObject:self.cabin forKey:@"sellerUser"];
        
        UIImage *imageOne = [self.firstImageView.image resizedImage:CGSizeMake(200.0, 200.0) interpolationQuality:kCGInterpolationHigh];
        NSData* dataOne = UIImageJPEGRepresentation(imageOne, 0.7f);
        PFFile *thumbFile = [PFFile fileWithName:@"thumb1.jpg" data:dataOne];
        [forSaleItem setObject:thumbFile forKey:@"thumbnail"];
        
        if (self.photostotal == 1) {
            NSData* data = UIImageJPEGRepresentation(self.firstImageView.image, 0.7f);
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            if (self.editMode == YES) {
                [self.listing removeObjectForKey:@"image2"];
                [self.listing removeObjectForKey:@"image3"];
                [self.listing removeObjectForKey:@"image4"];
            }
        }
        else if (self.photostotal == 2){
            NSData* data1 = UIImageJPEGRepresentation(self.firstImageView.image, 0.7f);
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data1];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            NSData* data2 = UIImageJPEGRepresentation(self.secondImageView.image, 0.7f);
            PFFile *imageFile2 = [PFFile fileWithName:@"Image2.jpg" data:data2];
            [forSaleItem setObject:imageFile2 forKey:@"image2"];
            
            if (self.editMode == YES) {
                [self.listing removeObjectForKey:@"image3"];
                [self.listing removeObjectForKey:@"image4"];
            }
        }
        else if (self.photostotal == 3){
            NSData* data1 = UIImageJPEGRepresentation(self.firstImageView.image, 0.7);
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data1];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            NSData* data2 = UIImageJPEGRepresentation(self.secondImageView.image, 0.7f);
            PFFile *imageFile2 = [PFFile fileWithName:@"Image2.jpg" data:data2];
            [forSaleItem setObject:imageFile2 forKey:@"image2"];
            
            NSData* data3 = UIImageJPEGRepresentation(self.thirdImageView.image, 0.7f);
            PFFile *imageFile3 = [PFFile fileWithName:@"Imag3.jpg" data:data3];
            [forSaleItem setObject:imageFile3 forKey:@"image3"];
            
            if (self.editMode == YES) {
                [self.listing removeObjectForKey:@"image4"];
            }
        }
        else if (self.photostotal == 4){
            NSData* data1 = UIImageJPEGRepresentation(self.firstImageView.image, 0.7f);
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data1];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            NSData* data2 = UIImageJPEGRepresentation(self.secondImageView.image, 0.7f);
            PFFile *imageFile2 = [PFFile fileWithName:@"Image2.jpg" data:data2];
            [forSaleItem setObject:imageFile2 forKey:@"image2"];
            
            NSData* data3 = UIImageJPEGRepresentation(self.thirdImageView.image, 0.7f);
            PFFile *imageFile3 = [PFFile fileWithName:@"Imag3.jpg" data:data3];
            [forSaleItem setObject:imageFile3 forKey:@"image3"];
            
            NSData* data4 = UIImageJPEGRepresentation(self.fourthImageView.image, 0.7f);
            PFFile *imageFile4 = [PFFile fileWithName:@"Imag4.jpg" data:data4];
            [forSaleItem setObject:imageFile4 forKey:@"image4"];
        }
        
        [forSaleItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                [[PFUser currentUser]incrementKey:@"forSalePostNumber"];
                [[PFUser currentUser] saveInBackground];
//                [self.cabin incrementKey:@"forSalePostNumber"];
//                [self.cabin saveInBackground];
                
                [self.saveButton setEnabled:YES];
                
                self.hud.labelText = @"Saved!";

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
                [self.saveButton setEnabled:YES];
                NSLog(@"error saving %@", error);

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
}

-(void)listingSetup{
    self.navigationItem.title = @"Edit";
    
    [self.saveButton setImage:[UIImage imageNamed:@"updateButton"] forState:UIControlStateNormal];
    
    self.descriptionField.text = [self.listing objectForKey:@"description"];
    
    NSString *symbol = @"";
    
    if ([[self.listing objectForKey:@"currency"] isEqualToString:@"GBP"]) {
        symbol = @"£";
    }
    else{
        symbol = @"$";
    }
    self.payField.text = [NSString stringWithFormat:@"%@%@",symbol,[self.listing objectForKey:[NSString stringWithFormat:@"salePrice%@", [self.listing objectForKey:@"currency"]]]];
    
    
    self.chooseCondition.text = [self.listing objectForKey:@"condition"];
    
    //location is not updatable when editing listing
    self.chooseLocation.text = [self.listing objectForKey:@"location"];
    self.locationCell.accessoryType = UITableViewCellAccessoryNone;
    self.locationCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.chooseCategroy.text = [self.listing objectForKey:@"category"];
    
    //sizing
    self.chooseSize.text = [self.listing objectForKey:@"sizeLabel"];
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

@end