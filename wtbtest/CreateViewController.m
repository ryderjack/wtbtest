//
//  CreateViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 25/02/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "CreateViewController.h"
#import <TWPhotoPickerController.h>


@interface CreateViewController ()

@end

@implementation CreateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Create a listing";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    //hide first table view header
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
        
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
    [self.firstImageView setImage:[UIImage imageNamed:@"addImage"]];
    [self.secondImageView setImage:[UIImage imageNamed:@"camHolder"]];
    [self.thirdImageView setImage:[UIImage imageNamed:@"camHolder"]];
    [self.fourthImageView setImage:[UIImage imageNamed:@"camHolder"]];
    
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
    
    self.resetButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(resetForm)];
    
    if (self.editFromListing == YES) {
        [self listingSetup];
        self.resetButton.title = @"Delete";
        self.resetButton.action = @selector(deleteListing);
    }
    
    self.navigationItem.rightBarButtonItem = self.resetButton;
    
    //add done button to number pad keyboard on pay field
    [self addDoneButton];
    
    [self.titleField becomeFirstResponder];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if ([self.status isEqualToString:@"new"]) {
        [self resetForm];
    }
    if ([self.status isEqualToString:@"edit"] && [self.resetButton.title isEqualToString:@"Clear"]) {
        [self.navigationItem setRightBarButtonItems:nil animated:YES];
        [self.saveButton setImage:[UIImage imageNamed:@"updateButton"] forState:UIControlStateNormal];
    }
    else{
        self.navigationItem.rightBarButtonItem = self.resetButton;
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
        return 6;
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
        else if(indexPath.row == 4){
            return self.deliveryCell;
        }
        else if(indexPath.row == 5){
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
        if(indexPath.row == 0){
            return 44;
        }
        else if(indexPath.row == 1){
            return 44;
        }
        else if(indexPath.row == 2){
            return 44;
        }
        else if(indexPath.row == 3){
            return 44;
        }
        else if(indexPath.row == 4){
            return 44;
        }
        else if(indexPath.row == 5){
            return 44;
        }
    }
    else if (indexPath.section ==3){
        return 105;
    }
    else if (indexPath.section ==4){
        return 156;
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
    
    [self removeKeyboard];
    
    if (indexPath.section ==2){
        if(indexPath.row == 0){
            SelectViewController *vc = [[SelectViewController alloc]init];
            vc.delegate = self;
            vc.setting = @"condition";
            vc.offer = NO;
            self.selection = @"condition";
            [self.navigationController pushViewController:vc animated:YES];

        }
        else if(indexPath.row == 1){
            SelectViewController *vc = [[SelectViewController alloc]init];
            vc.delegate = self;
            vc.setting = @"category";
            vc.offer = NO;
            self.selection = @"category";
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if(indexPath.row == 2){
            if ([self.chooseCategroy.text isEqualToString:@"Choose"]) {
                //prompt to choose category first
                [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            }
            else{
                if ([self.chooseCategroy.text isEqualToString:@"Footwear"]) {
                    SelectViewController *vc = [[SelectViewController alloc]init];
                    vc.delegate = self;
                    vc.setting = @"sizefoot";
                    vc.offer = NO;
                    self.selection = @"size";
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else{
                    SelectViewController *vc = [[SelectViewController alloc]init];
                    vc.delegate = self;
                    vc.setting = @"sizeclothing";
                    vc.offer = NO;
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
        else if(indexPath.row == 4){
            SelectViewController *vc = [[SelectViewController alloc]init];
            vc.delegate = self;
            vc.setting = @"delivery";
            vc.offer = NO;
            self.selection = @"delivery";
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
    header.textLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:12];
    CGRect headerFrame = header.frame;
    header.textLabel.frame = headerFrame;
    header.contentView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    
    [footerView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    return footerView;
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
        return @"Tell sellers exactly what you wantobuy";
    }
    else {
        return @"";
    }
}
-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return @"";

}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section ==2 || section ==3 || section == 4) {
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
        self.payField.text = @"£";
    }
}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@"eg. Must come with original box"]) {
        textView.text = @"";
        textView.textColor = [UIColor colorWithRed:74/255.0f green:74/255.0f blue:74/255.0f alpha:1.0f];
    }
}
-(void)textViewDidEndEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"eg. Must come with original box";
        textView.textColor = [UIColor lightGrayColor];
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
        // Check for deletion of the $ sign
        if (range.location == 0 && [textField.text hasPrefix:@"£"])
            return NO;
        
        NSString *updatedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray *stringsArray = [updatedText componentsSeparatedByString:@"."];
        
        // Check for an absurdly large amount
        if (stringsArray.count > 0)
        {
            NSString *dollarAmount = stringsArray[0];
            if (dollarAmount.length > 6)
                return NO;
        }
        
        // Check for more than 2 chars after the decimal point
        if (stringsArray.count > 1)
        {
            NSString *centAmount = stringsArray[1];
            if (centAmount.length > 2)
                return NO;
        }
        
        // Check for a second decimal point
        if (stringsArray.count > 2)
            return NO;
        
        return YES;
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
        [self presentViewController:vc animated:YES completion:nil];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Choose from library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        TWPhotoPickerController *photoPicker = [[TWPhotoPickerController alloc] init];
        photoPicker.cropBlock = ^(UIImage *image) {
            [self finalImage:image];
        };
        [self presentViewController:photoPicker animated:YES completion:nil];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Search Instagram" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        // search insta
        
        if ([self.titleField.text isEqualToString:@""]) {
            [self popUpAlert];
        }
        else{
            DZNPhotoPickerController *picker = [DZNPhotoPickerController new];
            picker.supportedServices =  DZNPhotoPickerControllerServiceInstagram;
            picker.allowsEditing = NO;
            picker.cropMode = DZNPhotoEditorViewControllerCropModeSquare;
            picker.initialSearchTerm = self.titleField.text;
            picker.enablePhotoDownload = YES;
            picker.allowAutoCompletedSearch = YES;
            picker.infiniteScrollingEnabled = YES;
            picker.title = @"Search Instagram";
        
            
            picker.cancellationBlock = ^(DZNPhotoPickerController *picker) {
                [self dismissViewControllerAnimated:YES completion:nil];
            };
            
            picker.finalizationBlock = ^(DZNPhotoPickerController *picker, NSDictionary *info) {
                [self handleImagePicker:picker withMediaInfo:info];
                [self dismissViewControllerAnimated:YES completion:nil];
            };
            [self presentViewController:picker animated:YES completion:nil];
        }
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)popUpAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Enter a title" message:@"Make sure you've entered a title for the item you wantobuy!" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

#pragma web picker delegates

-(void)photoPickerControllerDidCancel:(DZNPhotoPickerController *)picker{
}

-(void)photoPickerController:(DZNPhotoPickerController *)picker didFinishPickingPhotoWithInfo:(NSDictionary *)userInfo{
}

- (void)handleImagePicker:(DZNPhotoPickerController *)picker withMediaInfo:(NSDictionary *)info
{
    [self updateImageWithPayload:info];
}

- (void)updateImageWithPayload:(NSDictionary *)payload
{
    UIImage *image = payload[UIImagePickerControllerEditedImage];
    if (!image) image = payload[UIImagePickerControllerOriginalImage];
    
    [self finalImage:image];
}

-(void)photoPickerController:(DZNPhotoPickerController *)picker didFailedPickingPhotoWithError:(NSError *)error{
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

- (void)addItemViewController:(SelectViewController *)controller didFinishEnteringItem:(NSString *)item withitem:(NSString *)item2
{
    if ([self.selection isEqualToString:@"condition"]) {
        self.chooseCondition.text = item;
    }
    else if ([self.selection isEqualToString:@"category"]){
        self.chooseCategroy.text = item;
        self.chooseSize.text = @"Choose";
    }
    else if ([self.selection isEqualToString:@"size"]){
        self.chooseSize.text = item;
        if (item2) {
            NSLog(@"gendersize being set %@", item2);
            self.genderSize = item2;
        }
    }
    else if ([self.selection isEqualToString:@"delivery"]){
        self.chooseDelivery.text = item;
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
            self.chooseLocation.text = @"Choose";
        }
}
- (IBAction)wantobuyPressed:(id)sender {
    [self.saveButton setEnabled:NO];
    [self removeKeyboard];
    
    if ([self.chooseCategroy.text isEqualToString:@"Choose"] || [self.chooseCondition.text isEqualToString:@"Choose"] || [self.chooseDelivery.text isEqualToString:@"Choose"] || [self.chooseLocation.text isEqualToString:@"Choose"] || [self.chooseSize.text isEqualToString:@"Choose"] || [self.payField.text isEqualToString:@""] || [self.titleField.text isEqualToString:@""] || self.photostotal == 0) {
        self.warningLabel.text = @"Fill out all the above fields";
        [self.saveButton setEnabled:YES];
    }
    else{

        NSString *prefixToRemove = @"£";
        NSString *priceString = [[NSString alloc]init];
        priceString = [self.payField.text substringFromIndex:[prefixToRemove length]];
        
        int price = [priceString intValue];
        
        NSString *itemTitle = self.titleField.text;
        NSString *extraInfo = self.extraField.text;
        
        if ([self.status isEqualToString:@"edit"]) {
            PFQuery *query = [PFQuery queryWithClassName:@"wantobuys"];
            [query whereKey:@"objectId" equalTo:self.lastId];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    self.listing = object;
                    NSLog(@"self.listing id %@", self.listing.objectId);
                }
                else{
                    NSLog(@"error %@", error);
                }
            }];
        }
        else{
            self.listing =[PFObject objectWithClassName:@"wantobuys"];
        }
        
        [self.listing setObject:itemTitle forKey:@"title"];
        [self.listing setObject:self.chooseCondition.text forKey:@"condition"];
        [self.listing setObject:self.chooseCategroy.text forKey:@"category"];
        [self.listing setObject:self.chooseSize.text forKey:@"size"];
        NSLog(@"gender size %@", self.genderSize);
        if (![self.genderSize isEqualToString:@""]) {
            [self.listing setObject:self.genderSize forKey:@"sizeGender"];
        }
        
        if (self.editFromListing != YES) {
            //don't update location on listing if just editing
            [self.listing setObject:self.chooseLocation.text forKey:@"location"];
            [self.listing setObject:self.geopoint forKey:@"geopoint"];
        }
        
        [self.listing setObject:self.chooseDelivery.text forKey:@"delivery"];
        self.listing[@"listingPrice"] = @(price);
        [self.listing setObject:[PFUser currentUser] forKey:@"postUser"];
        
        if (self.photostotal == 1) {
            NSData* data = UIImageJPEGRepresentation(self.firstImageView.image, 0.7f);
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data];
            NSLog(@"image1 %@", imageFile1);
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
        if ([self.extraField.text isEqualToString:@"eg. Must come with original box"]) {
            //don't save its placeholder
        }
        else{
            [self.listing setObject:extraInfo forKey:@"extra"];
        }
        NSLog(@"listing %@", self.listing);
        
        [self.listing saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                [self.saveButton setEnabled:YES];
                if (self.editFromListing == YES) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
                else{
                    NSLog(@"listing saved! %@", self.listing.objectId);
                    ListingCompleteView *vc = [[ListingCompleteView alloc]init];
                    vc.delegate = self;
                    vc.lastObjectId = self.listing.objectId;
                    vc.orderMode = NO;
                    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
                    [self.navigationController pushViewController:vc animated:YES];
                }
            }
            else{
                [self.saveButton setEnabled:YES];
                NSLog(@"error saving %@", error);
            }
        }];
    }
}

-(void)listingEdit:(ListingCompleteView *)controller didFinishEnteringItem:(NSString *)item{
    self.status = item;
}

-(void)resetForm{
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    self.status = @"";
    self.chooseCategroy.text = @"Choose";
    self.chooseCondition.text = @"Choose";
    self.chooseDelivery.text = @"Choose";
    self.chooseLocation.text = @"Choose";
    self.chooseSize.text = @"Choose";
    self.payField.text = @"";
    self.titleField.text = @"";
    self.extraField.text = @"eg. Must come with original box";
    self.warningLabel.text = @"";
    
    self.firstImageView.contentMode = UIViewContentModeScaleAspectFit;
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
}
-(void)lastId:(ListingCompleteView *)controller didFinishEnteringItem:(NSString *)item{
    self.lastId = item;
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

-(void)listingSetup{
    self.navigationItem.title = @"Edit listing";
    
    [self.saveButton setImage:[UIImage imageNamed:@"updateButton"] forState:UIControlStateNormal];
    
    self.titleField.text = [self.listing objectForKey:@"title"];
    self.payField.text = [NSString stringWithFormat:@"£%@",[self.listing objectForKey:@"listingPrice"]];
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
    else{
        
    }
    
    self.chooseSize.text = [self.listing objectForKey:@"size"];
    
    if ([self.listing objectForKey:@"extra"]) {
        self.extraField.text = [self.listing objectForKey:@"extra"];
    }
    
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
-(void)deleteListing{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Are you sure you want to delete your wantobuy?" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }]];
    [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.listing deleteInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }];
    }]];
    
    [self presentViewController:alertView animated:YES completion:nil];
}

+ (void)initialize
{
    [DZNPhotoPickerController registerFreeService:DZNPhotoPickerControllerServiceInstagram consumerKey:@"16759bba4b7e4831b80bf3412e7dcb16" consumerSecret:@"701c5a99144a401c8285b0c9df999509"];
}
@end
