//
//  MakeOfferViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 05/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "MakeOfferViewController.h"
#import <TWPhotoPickerController.h>
#import "ExplainViewController.h"

@interface MakeOfferViewController ()

@end

@implementation MakeOfferViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Make an offer";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.picCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.extraCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.deliveryCostCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buyerCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.totalCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.saleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.itemTitle.adjustsFontSizeToFitWidth = YES;
    self.itemTitle.minimumScaleFactor=0.5;
    
    self.buyerName.adjustsFontSizeToFitWidth = YES;
    self.buyerName.minimumScaleFactor=0.5;
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    self.itemTitle.text = [self.listingObject objectForKey:@"title"];
    
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
    
    self.warningLabel.text = @"";
    self.status = @"";
    self.totalsumLabel.text = @"";
    
    self.priceField.delegate = self;
    self.extraFiel.delegate = self;
    self.deliveryField.delegate = self;
    
    //buyer info
    PFUser *buyer = [self.listingObject objectForKey:@"postUser"];
    
    [self setImageBorder];
    
    [buyer fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            self.buyerUser = buyer;
            PFFile *pic = [buyer objectForKey:@"picture"];
            [self.profileView setFile:pic];
            [self.profileView loadInBackground];
            self.buyerName.text = buyer.username;
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
    
    //hightlight part of label
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self.tagExplain.text];
    NSRange selectedRange = NSMakeRange(82, 4); // 4 characters, starting at index 22
    
    [string beginEditing];
    [string addAttribute:NSForegroundColorAttributeName
                   value:[UIColor colorWithRed:0.29 green:0.565 blue:0.886 alpha:1]
                   range:selectedRange];
    
    [string endEditing];
    [self.tagExplain setAttributedText:string];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return 1;
    }
    else if (section ==1){
        return 1;
    }
    else if (section ==2){
        return 1;
    }
    else if (section ==3){
        return 7;
    }
    else if (section ==4){
        return 1;
    }
    else if (section ==5){
        return 1;
    }
    else if (section ==6){
        return 1;
    }
    return 1;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.titleCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.buyerCell;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return self.picCell;
        }
    }
    else if (indexPath.section ==3){
        if (indexPath.row == 0){
            return self.saleCell;
        }
        else if (indexPath.row == 1){
            return self.conditionCell;
        }
        else if (indexPath.row == 2){
            return self.categoryCell;
        }
        else if (indexPath.row == 3){
            return self.sizeCell;
        }
        else if (indexPath.row == 4){
            return self.locationCell;
        }
        else if (indexPath.row == 5){
            return self.methodCell;
        }
        else if (indexPath.row == 6){
            return self.deliveryCostCell;
        }
    }
    else if (indexPath.section == 4){
        if (indexPath.row == 0) {
            return self.totalCell;
        }
    }
    else if (indexPath.section == 5){
        if (indexPath.row == 0) {
            return self.extraCell;
        }
    }
    else if (indexPath.section == 6){
        if (indexPath.row == 0) {
            return self.buttonCell;
        }
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 90;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return 130;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return 190;
        }
    }
    else if (indexPath.section ==3){
        if (indexPath.row == 0){
            return 44;
        }
        else if (indexPath.row == 1){
            return 44;
        }
        else if (indexPath.row == 2){
            return 44;
        }
        else if (indexPath.row == 3){
            return 44;
        }
        else if (indexPath.row == 4){
            return 44;
        }
        else if (indexPath.row == 5){
            return 44;
        }
        else if (indexPath.row == 6){
            return 44;
        }
    }
    else if (indexPath.section == 4){
        if (indexPath.row == 0) {
            return 44;
        }
    }
    else if (indexPath.section == 5){
        if (indexPath.row == 0) {
            return 104;
        }
    }
    else if (indexPath.section == 6){
        if (indexPath.row == 0) {
            return 164;
        }
    }
    return 100;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 3 || section == 2 || section == 0)
        return 0.0f;
    else if (section == 1){
        return 1.0f;
    }
    return 32.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section ==3 || section == 4 || section == 5 || section == 6 || section == 0) {
        return 0.0;
    }
    return 32.0f;
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
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

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

- (void)addItemViewController:(SelectViewController *)controller didFinishEnteringItem:(NSString *)item withitem:(NSString *)item2
{
    if ([self.selection isEqualToString:@"condition"]) {
        self.chooseCondition.text = item;
    }
    else if ([self.selection isEqualToString:@"category"]){
        self.chooseCategory.text = item;
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section ==3){
        if(indexPath.row == 1){
            SelectViewController *vc = [[SelectViewController alloc]init];
            vc.delegate = self;
            vc.setting = @"condition";
            self.selection = @"condition";
            vc.offer = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if(indexPath.row == 2){
            SelectViewController *vc = [[SelectViewController alloc]init];
            vc.delegate = self;
            vc.setting = @"category";
            self.selection = @"category";
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if(indexPath.row == 3){
            if ([self.chooseCategory.text isEqualToString:@"Choose"]) {
                //prompt to choose category first
                [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            }
            else{
                if ([self.chooseCategory.text isEqualToString:@"Footwear"]) {
                    SelectViewController *vc = [[SelectViewController alloc]init];
                    vc.delegate = self;
                    vc.setting = @"sizefoot";
                    vc.offer = YES;
                    self.selection = @"size";
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else{
                    SelectViewController *vc = [[SelectViewController alloc]init];
                    vc.delegate = self;
                    vc.setting = @"sizeclothing";
                    vc.offer = YES;
                    self.selection = @"size";
                    [self.navigationController pushViewController:vc animated:YES];
                }
            }
        }
        else if(indexPath.row == 4){
            LocationView *vc = [[LocationView alloc]init];
            vc.delegate = self;
            self.selection = @"location";
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if(indexPath.row == 5){
            SelectViewController *vc = [[SelectViewController alloc]init];
            vc.delegate = self;
            vc.setting = @"delivery";
            vc.offer = YES;
            self.selection = @"delivery";
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

-(void)addLocation:(LocationView *)controller didFinishEnteringItem:(NSString *)item longi:(CLLocationDegrees)item1 lati:(CLLocationDegrees)item2{
    self.chooseLocation.text = item;
    self.geopoint = [PFGeoPoint geoPointWithLatitude:item2 longitude:item1];
}

#pragma mark - Text field/view delegate methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}
-(void)textFieldDidBeginEditing:(UITextField *)textField{
    if (textField == self.priceField || textField == self.deliveryField) {
        textField.text = @"£";
    }
}
-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.priceField || textField == self.deliveryField) {
        
        if ([self.priceField.text isEqualToString:@""] || [self.deliveryField.text isEqualToString:@""] || [self.deliveryField.text isEqualToString:@"£"] || [self.priceField.text isEqualToString:@"£"]) {
            
            NSString *prefixToRemove = @"£";
            
            if ([textField.text hasPrefix:prefixToRemove]){
                NSString *stringToEnter = [textField.text substringFromIndex:[prefixToRemove length]];
                self.totalsumLabel.text = [NSString stringWithFormat:@"£%@", stringToEnter];
            }
            else{
                self.totalsumLabel.text = [NSString stringWithFormat:@"£%@", textField.text];
            }
        }
        else{
            NSString *prefixToRemove = @"£";
            NSString *price = [[NSString alloc]init];
            NSString *delivery = [[NSString alloc]init];
            
            if ([self.priceField.text hasPrefix:prefixToRemove]){
                price = [self.priceField.text substringFromIndex:[prefixToRemove length]];
            }
            if ([self.deliveryField.text hasPrefix:prefixToRemove]){
                delivery = [self.deliveryField.text substringFromIndex:[prefixToRemove length]];
            }
            int priceInt = [price intValue];
            int deliveryInt = [delivery intValue];
            int total = (priceInt + deliveryInt);
            self.totalsumLabel.text = [NSString stringWithFormat:@"£%d", total];
        }
    }
}
-(void)textViewDidBeginEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@"eg. Includes original box"]) {
        textView.text = @"";
        textView.textColor = [UIColor colorWithRed:74/255.0f green:74/255.0f blue:74/255.0f alpha:1.0f];
    }
}
-(void)textViewDidEndEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"eg. Includes with original box";
        textView.textColor = [UIColor lightGrayColor];
    }
}
-(void)removeKeyboard{
    [self.priceField resignFirstResponder];
    [self.extraFiel resignFirstResponder];
    [self.deliveryField resignFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (textField == self.priceField || textField == self.deliveryField) {
        // Prevent crashing undo bug – see note below.
        if(range.length + range.location > textField.text.length)
        {
            return NO;
        }
        
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return newLength <= 4;
    }
    return string;
}
-(void)setImageBorder{
    self.profileView.layer.cornerRadius = self.profileView.frame.size.width / 2;
    self.profileView.layer.masksToBounds = YES;
    
    self.profileView.layer.borderWidth = 1.0f;
    self.profileView.layer.borderColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1].CGColor;
    
    self.profileView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.profileView.contentMode = UIViewContentModeScaleAspectFill;
}
- (IBAction)sendOfferPressed:(id)sender {
    [self removeKeyboard];
    
    if ([self.chooseCategory.text isEqualToString:@"Choose"] || [self.chooseCondition.text isEqualToString:@"Choose"] || [self.chooseDelivery.text isEqualToString:@"Choose"] || [self.chooseLocation.text isEqualToString:@"Choose"] || [self.chooseSize.text isEqualToString:@"Choose"] || [self.priceField.text isEqualToString:@""] || [self.deliveryField.text isEqualToString:@""] || self.photostotal == 0) {
        self.warningLabel.text = @"Fill out all the above fields";
    }
    else{
        NSString *saleprice = [[self.priceField.text componentsSeparatedByCharactersInSet:
                                   [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                                  componentsJoinedByString:@""];
        NSString *deliverycost = [[self.deliveryField.text componentsSeparatedByCharactersInSet:
                                   [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                                  componentsJoinedByString:@""];
        NSString *extraInfo = [self.extraFiel.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        PFObject *offerObject =[PFObject objectWithClassName:@"offers"];
        [offerObject setObject:self.listingObject forKey:@"wtbListing"];
        [offerObject setObject:self.chooseCondition.text forKey:@"condition"];
        [offerObject setObject:self.chooseCategory.text forKey:@"category"];
        [offerObject setObject:self.chooseSize.text forKey:@"size"];
        if (self.genderSize) {
            [offerObject setObject:self.genderSize forKey:@"sizeGender"];
        }
        [offerObject setObject:self.chooseLocation.text forKey:@"itemLocation"];
        [offerObject setObject:self.geopoint forKey:@"geopoint"];
        [offerObject setObject:self.chooseDelivery.text forKey:@"deliveryMethod"];
        [offerObject setObject:saleprice forKey:@"salePrice"];
        [offerObject setObject:deliverycost forKey:@"deliveryCost"];
        [offerObject setObject:deliverycost forKey:@"totalCost"];
        [offerObject setObject:self.buyerUser forKey:@"buyerUser"];
        [offerObject setObject:[PFUser currentUser] forKey:@"sellerUser"];
        
        if (self.photostotal == 1) {
            NSData* data = UIImageJPEGRepresentation(self.firstImageView.image, 0.7f);
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data];
            [offerObject setObject:imageFile1 forKey:@"image1"];
        }
        else if (self.photostotal == 2){
            NSData* data1 = UIImageJPEGRepresentation(self.firstImageView.image, 0.7f);
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data1];
            [offerObject setObject:imageFile1 forKey:@"image1"];
            
            NSData* data2 = UIImageJPEGRepresentation(self.secondImageView.image, 0.7f);
            PFFile *imageFile2 = [PFFile fileWithName:@"Image2.jpg" data:data2];
            [offerObject setObject:imageFile2 forKey:@"image2"];
        }
        else if (self.photostotal == 3){
            NSData* data1 = UIImageJPEGRepresentation(self.firstImageView.image, 0.7f);
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data1];
            [offerObject setObject:imageFile1 forKey:@"image1"];
            
            NSData* data2 = UIImageJPEGRepresentation(self.secondImageView.image, 0.7f);
            PFFile *imageFile2 = [PFFile fileWithName:@"Image2.jpg" data:data2];
            [offerObject setObject:imageFile2 forKey:@"image2"];
            
            NSData* data3 = UIImageJPEGRepresentation(self.thirdImageView.image, 0.7f);
            PFFile *imageFile3 = [PFFile fileWithName:@"Imag3.jpg" data:data3];
            [offerObject setObject:imageFile3 forKey:@"image3"];
        }
        else if (self.photostotal == 4){
            NSData* data1 = UIImageJPEGRepresentation(self.firstImageView.image, 0.7f);
            PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data1];
            [offerObject setObject:imageFile1 forKey:@"image1"];
            
            NSData* data2 = UIImageJPEGRepresentation(self.secondImageView.image, 0.7f);
            PFFile *imageFile2 = [PFFile fileWithName:@"Image2.jpg" data:data2];
            [offerObject setObject:imageFile2 forKey:@"image2"];
            
            NSData* data3 = UIImageJPEGRepresentation(self.thirdImageView.image, 0.7f);
            PFFile *imageFile3 = [PFFile fileWithName:@"Imag3.jpg" data:data3];
            [offerObject setObject:imageFile3 forKey:@"image3"];
            
            NSData* data4 = UIImageJPEGRepresentation(self.fourthImageView.image, 0.7f);
            PFFile *imageFile4 = [PFFile fileWithName:@"Imag4.jpg" data:data4];
            [offerObject setObject:imageFile4 forKey:@"image4"];
        }
        
        if ([self.extraFiel.text isEqualToString:@"eg. Includes original box"]) {
            //don't save its placeholder
        }
        else{
            [offerObject setObject:extraInfo forKey:@"extraInfo"];
        }
        
        [offerObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                NSLog(@"offer saved! %@", offerObject.objectId);
                [self.navigationController popViewControllerAnimated:YES];
            }
            else{
                NSLog(@"error saving %@", error);
            }
        }];
    }
}
- (IBAction)taggedExlpainTapped:(id)sender {
    ExplainViewController *vc = [[ExplainViewController alloc]init];
    vc.setting = @"tagged";
    [self presentViewController:vc animated:YES completion:nil];
}
@end
