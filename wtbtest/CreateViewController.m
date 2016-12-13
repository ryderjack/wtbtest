//
//  CreateViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 25/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "CreateViewController.h"
#import "NavigationController.h"
#import "Flurry.h"
#import "WelcomeViewController.h"
#import "UIImage+Resize.h"

@interface CreateViewController ()

@end

@implementation CreateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"C R E A T E";
    
    //hide first table view header
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    if (self.introMode == NO) {
        [self.skipButton setHidden:YES];
    }
        
    //button setup
    [self.firstCam setEnabled:YES];
    [self.secondCam setEnabled:NO];
    [self.thirdCam setEnabled:NO];
    [self.fourthCam setEnabled:NO];
    
    self.somethingChanged = NO;
    self.shouldSave = NO;
    
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
    
    self.payField.placeholder = @"";
    
    self.photostotal = 0;
    self.titleField.delegate = self;
    self.extraField.delegate = self;
    self.payField.delegate = self;
    
    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.picCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.infoCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.payCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    self.warningLabel.text = @"";
    self.genderSize = @"";
    self.firstSize = @"";
    self.secondSize = @"";
    self.thirdSize = @"";
    self.resetButton = [[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStylePlain target:self action:@selector(resetForm)];
    
    if (self.editFromListing == YES) {
        [self listingSetup];
        
        self.navigationItem.rightBarButtonItem = nil;
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    
    if (self.introMode == YES) {
        self.navigationItem.hidesBackButton = YES;
    }
    else{
        self.navigationItem.rightBarButtonItem = self.resetButton;
    }
    
    //add done button to number pad keyboard on pay field
    [self addDoneButton];
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.profanityList = @[@"fuck",@"fucking",@"shitting", @"cunt", @"sex", @"wanker", @"nigger", @"penis", @"cock", @"shit", @"dick", @"bastard"];
    
    if (![self.status isEqualToString:@"edit"]) {
        [self useCurrentLoc];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"dd/MM/YYYY"];
    NSString *dateString=[dateFormatter stringFromDate:[NSDate date]];
    NSString *midnight = [NSString stringWithFormat:@"%@ 12:00 AM", dateString];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/MM/yyyy hh:mm a"];
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [formatter setTimeZone:gmt];
    self.todayDate = [formatter dateFromString:midnight];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    
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
        else if ([self.currency isEqualToString:@"USD"]) {
            self.currencySymbol = @"$";
            self.payField.placeholder = @"$100";
        }
    }
    
    if ([self.status isEqualToString:@"new"]) {
        [self resetForm];
    }
    else if ([self.status isEqualToString:@"edit"] && [self.resetButton.title isEqualToString:@"Reset"]) {
        [self.navigationItem setRightBarButtonItems:nil animated:YES];
        [self.saveButton setImage:[UIImage imageNamed:@"updateButton"] forState:UIControlStateNormal];
    }
    else if(self.introMode != YES){
        self.navigationItem.rightBarButtonItem = self.resetButton;
        [Flurry logEvent:@"Create_Tapped"];
    }
    
    if (self.shouldShowHUD == YES) {
        [self showHUD];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0){
        return 1;
    }
    else if (section == 1){
        return 1;
    }
    else if (section == 2){
        return 5;
    }
    else if (section == 3){
        return 1;
    }
    else if (section == 4){
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
            return self.picCell;
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
        else if(indexPath.row == 3){
            return self.locCell;
        }
//        else if(indexPath.row == 4){
//            return self.deliveryCell;
//        }
        else if(indexPath.row == 4){
            return self.payCell;
        }
    }
    else if (indexPath.section ==3){
        return self.infoCell;
    }
    else if (indexPath.section ==4){
        return self.buttonCell;
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
        return 105;
    }
    else if (indexPath.section ==4){
        return 138;
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
            if (self.editFromListing != YES) {
                LocationView *vc = [[LocationView alloc]init];
                vc.delegate = self;
                self.selection = @"location";
                [self.navigationController pushViewController:vc animated:YES];
            }
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
        return @"Tell sellers exactly what you're looking for";
    }
    else {
        return @"";
    }
}
-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    if (section == 2) {
        return @"Pro Tip: an accurate Budget = interested sellers";
    }
    else{
        return @"";
    }
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section ==3 || section == 4) {
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
    if (textField == self.payField) {
        self.payField.text = [NSString stringWithFormat:@"%@", self.currencySymbol];
    }
}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@"Leave blank if none"]) {
        textView.text = @"";
        textView.textColor = [UIColor colorWithRed:74/255.0f green:74/255.0f blue:74/255.0f alpha:1.0f];
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
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Take a picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        CameraController *vc = [[CameraController alloc]init];
        vc.delegate = self;
        vc.offerMode = NO;
        self.shouldSave = YES;
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
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Search Google" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        // search insta
        
        if ([self.titleField.text isEqualToString:@""]) {
            [self popUpAlert];
        }
        
        // instructions on saving images from google
        BOOL seen = [[NSUserDefaults standardUserDefaults] boolForKey:@"seenGoogle"];
        if (!seen) {
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Search Google" message:@"Simply tap the image you'd like to use to get it fullscreen and when you're happy, hit Choose!" preferredStyle:UIAlertControllerStyleAlert];
            [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self showGoogle];
            }]];
            [self presentViewController:alertView animated:YES completion:nil];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"seenGoogle"];
        }
        else{
            [self showGoogle];
        }
    }]];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)showGoogle{
    NSString *searchString = [self.titleField.text stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSString *URLString = [NSString stringWithFormat:@"https://www.google.co.uk/search?tbm=isch&q=%@&tbs=iar:s#imgrc=_",searchString];
    self.webViewController = [[TOWebViewController alloc] initWithURL:[NSURL URLWithString:URLString]];
    self.webViewController.title = [NSString stringWithFormat:@"%@", self.titleField.text];
    self.webViewController.showUrlWhileLoading = NO;
    self.webViewController.showPageTitles = NO;
    self.webViewController.delegate = self;
    self.webViewController.doneButtonTitle = @"Choose";
    self.webViewController.paypalMode = NO;
    self.webViewController.infoMode = NO;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.webViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)didPressDone:(UIImage *)screenshot{
    [self.webViewController dismissViewControllerAnimated:YES completion:^{
        [self displayCropperWithImage:screenshot];
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    //display crop picker
    
//    UIImage *newImage = [self resizeImage:chosenImage toWidth:375.0f andHeight:375.0f];

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

    [self finalImage:newImage];
}

- (void)squareCropperDidCancelCropInCropper:(BASSquareCropperViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

-(void)popUpAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Enter a title" message:@"Make sure you've entered a title for your WTB!" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)sizePopUp{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Choose a category first!" message:@"Make sure you've entered a category for your WTB!" preferredStyle:UIAlertControllerStyleAlert];
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

#pragma delegate callbacks

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
            self.chooseLocation.text = @"select";
        }
}

- (IBAction)wantobuyPressed:(id)sender {
    self.warningLabel.text = @"";
    [self.saveButton setEnabled:NO];
    [self removeKeyboard];
    
    if ([self.payField.text isEqualToString:[NSString stringWithFormat:@"%@11", self.currencySymbol]]) {
        [self showAlertWithTitle:@"Enter a valid price" andMsg:@"Pro Tip: a more accurate price 99leads to more sellers getting in touch!"];
        self.warningLabel.text = @"Enter a valid price";
        [self.saveButton setEnabled:YES];
    }
    else if([self.chooseCategroy.text isEqualToString:@"Accessories"] && ( [self.chooseCondition.text isEqualToString:@"select"] || [self.chooseLocation.text isEqualToString:@"select"] || [self.payField.text isEqualToString:@""] || [self.titleField.text isEqualToString:@""] || self.photostotal == 0 || [self.payField.text isEqualToString:[NSString stringWithFormat:@"%@", self.currencySymbol]])){
        NSLog(@"accessories selected but haven't filled everything else in");
        self.warningLabel.text = @"Fill out all the above fields";
        [self.saveButton setEnabled:YES];
    }
    else if ([self.chooseCategroy.text isEqualToString:@"select"] || [self.chooseCondition.text isEqualToString:@"select"] || [self.chooseLocation.text isEqualToString:@"select"] || [self.chooseSize.text isEqualToString:@"select"] || [self.payField.text isEqualToString:@""] || [self.titleField.text isEqualToString:@""] || self.photostotal == 0 || [self.payField.text isEqualToString:[NSString stringWithFormat:@"%@", self.currencySymbol]]) {
        self.warningLabel.text = @"Fill out all the above fields";
        [self.saveButton setEnabled:YES];
    }
    else{
        [self showHUD];
        
        NSString *prefixToRemove = [NSString stringWithFormat:@"%@", self.currencySymbol];
        NSString *priceString = [[NSString alloc]init];
        priceString = [self.payField.text substringFromIndex:[prefixToRemove length]];
        
        int price = [priceString intValue];
        
        NSString *itemTitle = [self.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *extraInfo = [self.extraField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if ([self.status isEqualToString:@"edit"]) {
            PFQuery *query = [PFQuery queryWithClassName:@"wantobuys"];
            [query whereKey:@"objectId" equalTo:self.lastId];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    self.listing = object;
                }
                else{
                    NSLog(@"error %@", error);
                    [self hidHUD];
                    return;
                }
            }];
        }
        else{
            self.listing =[PFObject objectWithClassName:@"wantobuys"];
        }
        
        [self.listing setObject:itemTitle forKey:@"title"];
        [self.listing setObject:[itemTitle lowercaseString]forKey:@"titleLower"];
        [self.listing setObject:self.chooseCondition.text forKey:@"condition"];
        [self.listing setObject:self.chooseCategroy.text forKey:@"category"];
        
        //save keywords (minus useless words)
        NSArray *wasteWords = [NSArray arrayWithObjects:@"x",@"to",@"with",@"and",@"the",@"wtb",@"or",@" ",@".",@"very",@"interested", @"in",@"wanted", @"", @"all",@"any", @"&",@"looking",@"size", @"buy", @"these", @"this", @"that", nil];
        NSString *title = [itemTitle lowercaseString];
        NSArray *strings = [title componentsSeparatedByString:@" "];
        NSMutableArray *mutableStrings = [NSMutableArray arrayWithArray:strings];
        [mutableStrings removeObjectsInArray:wasteWords];
        
        if ([mutableStrings containsObject:@"bogo"]) {
            [mutableStrings addObject:@"box"];
            [mutableStrings addObject:@"logo"];
        }
        
        if ([mutableStrings containsObject:@"tee"]) {
            [mutableStrings addObject:@"t"];
        }
        
        if ([mutableStrings containsObject:@"camo"]) {
            [mutableStrings addObject:@"camouflage"];
        }
        
        if ([mutableStrings containsObject:@"hoodie"]) {
            [mutableStrings addObject:@"hoody"];
        }
        
        if ([mutableStrings containsObject:@"crew"]) {
            [mutableStrings addObject:@"crewneck"];
            [mutableStrings addObject:@"sweatshirt"];
            [mutableStrings addObject:@"sweater"];
            [mutableStrings addObject:@"sweat"];
        }
        
        [self.listing setObject:mutableStrings forKey:@"keywords"];
        
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

        if ([self.chooseSize.text isEqualToString:@"Any"]) {
            //set YES to all sizes for search purposes
            
            NSArray *allSizes = [NSArray array];
            
            if ([self.chooseCategroy.text isEqualToString:@"Clothing"]) {
                //clothing sizes
                allSizes = @[@"XXS",@"XS", @"S", @"M", @"L", @"XL", @"XXL", @"OS"];
            }
            else{
                //footwear sizes
                allSizes = @[@"size1", @"size1dot5", @"size2", @"size2dot5", @"size3", @"size3dot5",@"size4", @"size4dot5", @"size5", @"size5dot5", @"size6",@"size6dot5",@"size7", @"size7dot5", @"size8",@"size8dot5",@"size9", @"size9dot5", @"size10",@"size10dot5",@"size11", @"size11dot5", @"size12",@"size12dot5",@"size13", @"size13dot5", @"size14"];
            }
            for (NSString *stringKey in allSizes) {
                [self.listing setObject:@"YES" forKey:stringKey];
            }
        }
        [self.listing setObject:self.chooseSize.text forKey:@"sizeLabel"];
        [self.listing setObject:@"live" forKey:@"status"];
        
        //expiration in 2 weeks
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.minute = 1;
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        NSDate *expirationDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
        [self.listing setObject:expirationDate forKey:@"expiration"];
        
        if (![self.genderSize isEqualToString:@""]) {
            [self.listing setObject:self.genderSize forKey:@"sizeGender"];
        }
        
        if (self.editFromListing != YES) {
            //don't update location on listing if just editing
            [self.listing setObject:self.chooseLocation.text forKey:@"location"];
            [self.listing setObject:self.geopoint forKey:@"geopoint"];
            [self.listing setObject:@0 forKey:@"views"];
        }
        
        [self.listing setObject:self.chooseDelivery.text forKey:@"delivery"];
        [self.listing setObject:self.currency forKey:@"currency"];
        
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
        [self.listing setObject:[PFUser currentUser] forKey:@"postUser"];
        
        if (self.photostotal == 1) {
            NSData* data = UIImageJPEGRepresentation(self.firstImageView.image, 0.7f);
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data];
            [self.listing setObject:imageFile1 forKey:@"image1"];
            
            if (self.editFromListing == YES) {
                [self.listing removeObjectForKey:@"image2"];
                [self.listing removeObjectForKey:@"image3"];
                [self.listing removeObjectForKey:@"image4"];
            }
        }
        else if (self.photostotal == 2){
            NSData* data1 = UIImageJPEGRepresentation(self.firstImageView.image, 0.7f);
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data1];
            [self.listing setObject:imageFile1 forKey:@"image1"];
            
            NSData* data2 = UIImageJPEGRepresentation(self.secondImageView.image, 0.7f);
            PFFile *imageFile2 = [PFFile fileWithName:@"Image2.jpg" data:data2];
            [self.listing setObject:imageFile2 forKey:@"image2"];
            
            if (self.editFromListing == YES) {
                [self.listing removeObjectForKey:@"image3"];
                [self.listing removeObjectForKey:@"image4"];
            }
        }
        else if (self.photostotal == 3){
            NSData* data1 = UIImageJPEGRepresentation(self.firstImageView.image, 0.7f);
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data1];
            [self.listing setObject:imageFile1 forKey:@"image1"];
            
            NSData* data2 = UIImageJPEGRepresentation(self.secondImageView.image, 0.7f);
            PFFile *imageFile2 = [PFFile fileWithName:@"Image2.jpg" data:data2];
            [self.listing setObject:imageFile2 forKey:@"image2"];
            
            NSData* data3 = UIImageJPEGRepresentation(self.thirdImageView.image, 0.7f);
            PFFile *imageFile3 = [PFFile fileWithName:@"Imag3.jpg" data:data3];
            [self.listing setObject:imageFile3 forKey:@"image3"];
            
            if (self.editFromListing == YES) {
                [self.listing removeObjectForKey:@"image4"];
            }
        }
        else if (self.photostotal == 4){
            NSData* data1 = UIImageJPEGRepresentation(self.firstImageView.image, 0.7f);
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data1];
            [self.listing setObject:imageFile1 forKey:@"image1"];
            
            NSData* data2 = UIImageJPEGRepresentation(self.secondImageView.image, 0.7f);
            PFFile *imageFile2 = [PFFile fileWithName:@"Image2.jpg" data:data2];
            [self.listing setObject:imageFile2 forKey:@"image2"];
            
            NSData* data3 = UIImageJPEGRepresentation(self.thirdImageView.image, 0.7f);
            PFFile *imageFile3 = [PFFile fileWithName:@"Imag3.jpg" data:data3];
            [self.listing setObject:imageFile3 forKey:@"image3"];
            
            NSData* data4 = UIImageJPEGRepresentation(self.fourthImageView.image, 0.7f);
            PFFile *imageFile4 = [PFFile fileWithName:@"Imag4.jpg" data:data4];
            [self.listing setObject:imageFile4 forKey:@"image4"];
        }
        if ([self.extraField.text isEqualToString:@"Leave blank if none"] || [extraInfo isEqualToString:@""]) {
            //don't save its placeholder
        }
        else{
            [self.listing setObject:self.extraField.text forKey:@"extra"];
        }
        [self.listing saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                
                //check if intro mode so can show posted HUD otherwise just hide it
                if (self.introMode == YES) {
                    self.hud.labelText = @"Posted!";
                    [Flurry logEvent:@"WTB_INTRO_DONE"];
                    double delayInSeconds = 1.0; // number of seconds to wait
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                    });
                }
                else{
                    [self hidHUD];
                }
                
                //check if in edit mode as only increment post number if not in edit mode
                if (![self.status isEqualToString:@"edit"]) {
                    NSLog(@"not in edit mode so increment post number");
                    [[PFUser currentUser]incrementKey:@"postNumber"];
                    [[PFUser currentUser] saveInBackground];
                }
                
                [self.saveButton setEnabled:YES];
                
                //check if editing from listing as need to pop VC rather than display a 'listing complete' VC
                if (self.editFromListing == YES) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
                else if (self.introMode == YES){
                    //do nothing as intro screens will be dismissed automatically
                }
                else{
                    NSLog(@"listing saved! %@", self.listing.objectId);
                    
                    ListingCompleteView *vc = [[ListingCompleteView alloc]init];
                    vc.delegate = self;
                    vc.lastObjectId = self.listing.objectId;
                    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
                    [self.navigationController pushViewController:vc animated:YES];
                }
            }
            else{
                //error saving listing
                [self hidHUD];
                [self.saveButton setEnabled:YES];
                NSLog(@"error saving %@", error);
                
                if (self.introMode == YES) {
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                    [self.delegate dismissCreateController:self];
                }
            }
        }];
    }
}

-(void)listingEdit:(ListingCompleteView *)controller didFinishEnteringItem:(NSString *)item{
    NSLog(@"updating status to %@", item);
    self.status = item;
}

-(void)resetForm{
    NSLog(@"reset form with status %@", self.status);
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    self.status = @"";
    self.chooseCategroy.text = @"select";
    self.chooseCondition.text = @"select";
    self.chooseDelivery.text = @"select";
    self.chooseLocation.text = @"select";
    self.chooseSize.text = @"select";
    self.payField.text = @"";
    self.titleField.text = @"";
    self.extraField.text = @"Leave blank if none";
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
    
    [self.saveButton setImage:[UIImage imageNamed:@"buyButton"] forState:UIControlStateNormal];
    
    self.photostotal = 0;
    self.camButtonTapped = 0;
    
    self.geopoint = nil;
    
    if (![self.status isEqualToString:@"edit"]) {
        [self useCurrentLoc];
    }
}
-(void)lastId:(ListingCompleteView *)controller didFinishEnteringItem:(NSString *)item{
    self.lastId = item;
}

-(void)finalImage:(UIImage *)image{
    //save image if just been taken
    if (self.shouldSave == YES) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        self.shouldSave = NO;
    }
    
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

-(void)listingSetup{
    self.navigationItem.title = @"E D I T";
    
    [self.saveButton setImage:[UIImage imageNamed:@"updateButton"] forState:UIControlStateNormal];
    
    self.titleField.text = [self.listing objectForKey:@"title"];
    
    NSString *symbol = @"";
    
    if ([[self.listing objectForKey:@"currency"] isEqualToString:@"GBP"]) {
        symbol = @"£";
    }
    else{
        symbol = @"$";
    }
    self.payField.text = [NSString stringWithFormat:@"%@%@",symbol,[self.listing objectForKey:[NSString stringWithFormat:@"listingPrice%@", [self.listing objectForKey:@"currency"]]]];
    self.chooseCondition.text = [self.listing objectForKey:@"condition"];
    
    //location is not updatable when editing listing
    self.chooseLocation.text = [self.listing objectForKey:@"location"];
    self.locCell.accessoryType = UITableViewCellAccessoryNone;
    self.locCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.chooseDelivery.text = [self.listing objectForKey:@"delivery"];
    self.chooseCategroy.text = [self.listing objectForKey:@"category"];
    
    //if gendersize required (if category is footwear) set variable
    if ([self.listing objectForKey:@"sizeGender"]) {
       self.genderSize = [self.listing objectForKey:@"sizeGender"];
    }
    
    //sizing
    self.chooseSize.text = [self.listing objectForKey:@"sizeLabel"];
    if ([self.listing objectForKey:@"firstSize"]) {
        self.firstSize = [NSString stringWithFormat:@"%@",[self.listing objectForKey:@"firstSize"]];
        NSLog(@"setting 1st %@",[self.listing objectForKey:@"firstSize"]);
        
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
        NSLog(@"setting 2nd %@",[self.listing objectForKey:@"secondSize"]);
        
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
        NSLog(@"setting 3rd %@",[self.listing objectForKey:@"thirdSize"]);
        
        //get string
        NSString *first = [self.listing objectForKey:@"thirdSize"];
        
        //change string to get key
        NSString *keyS = [first stringByReplacingOccurrencesOfString:@"." withString:@"dot"];
        NSString *finalKey = [NSString stringWithFormat:@"size%@", keyS];
        
        //set key to NO or delete key?
        [self.listing removeObjectForKey:finalKey];
    }
    
    //extra info
    if ([self.listing objectForKey:@"extra"]) {
        self.extraField.text = [self.listing objectForKey:@"extra"];
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
- (IBAction)skipPressed:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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

-(void)dismissVC{
    //only show warning if listing has been editing
    if (self.somethingChanged == NO){
        NSLog(@"nothing changed");
        [self.navigationController popViewControllerAnimated:YES];
    }
    else{
        NSLog(@"here");
        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Leave this page?" message:@"Are you sure you want to leave? Your changes won't be saved!" preferredStyle:UIAlertControllerStyleAlert];
        
        [alertView addAction:[UIAlertAction actionWithTitle:@"Stay" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
        [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:alertView animated:YES completion:nil];
    }
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}
@end
