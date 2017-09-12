//
//  legitCheckController.m
//  wtbtest
//
//  Created by Jack Ryder on 02/06/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "legitCheckController.h"
#import <Crashlytics/Crashlytics.h>
#import "UIImage+Resize.h"

@interface legitCheckController ()

@end

@implementation legitCheckController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //button setup
    
    self.firstCam = [[UIButton alloc]init];
    self.secondCam = [[UIButton alloc]init];
    self.thirdCam = [[UIButton alloc]init];
    self.fourthCam = [[UIButton alloc]init];
    
    [self.firstCam setEnabled:YES];
    [self.secondCam setEnabled:NO];
    [self.thirdCam setEnabled:NO];
    [self.fourthCam setEnabled:NO];
    
    self.topCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.imageCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.infoCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.spaceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.infoTextView.delegate = self;

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
    
    //need done button added to keyboard?
    
    self.imagesToProcess = [NSMutableArray array];
    self.placeholderAssetArray = [NSMutableArray array];
    self.filesArray = [NSMutableArray array];
    
    //bar button setup
    self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
    [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
    
    [self.longButton setTitle:@"D O N E" forState:UIControlStateNormal];
    [self.longButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
    
    [self.longButton addTarget:self action:@selector(savePressed) forControlEvents:UIControlEventTouchUpInside];
    self.longButton.alpha = 0.0f;
    [self.view addSubview:self.longButton];
    
    //check if existing legit check info exists
    if ([self.sellerApp objectForKey:@"description"]) {
        self.infoTextView.text = [NSString stringWithFormat:@"%@",[self.sellerApp objectForKey:@"description"]];
        self.infoTextView.textColor = [UIColor colorWithRed:74/255.0f green:74/255.0f blue:74/255.0f alpha:1.0f];
        self.textEntered = YES;
    }
    
    self.nameLabel.text = [self.nameLabel.text stringByReplacingOccurrencesOfString:@"name" withString:[NSString stringWithFormat:@"%@", [[PFUser currentUser] objectForKey:@"fullname"]]];
    
    //images
    if ([self.sellerApp objectForKey:@"image1"]) {
        [self.secondCam setEnabled:YES];
        
        [self.firstCam setEnabled:NO];
        
        [self.filesArray addObject:[self.sellerApp objectForKey:@"image1"]];
        self.photostotal = 1;
    }
    
    if ([self.sellerApp objectForKey:@"image2"]) {

        [self.thirdCam setEnabled:YES];
        [self.secondCam setEnabled:NO];
        
        [self.filesArray addObject:[self.sellerApp objectForKey:@"image2"]];
        self.photostotal = 2;
    }
    
    if ([self.sellerApp objectForKey:@"image3"]) {

        [self.fourthCam setEnabled:YES];
        [self.thirdCam setEnabled:NO];
        
        [self.filesArray addObject:[self.sellerApp objectForKey:@"image3"]];
        self.photostotal = 3;
    }
    
    if ([self.sellerApp objectForKey:@"image4"]) {

        [self.fourthCam setEnabled:NO];
        
        [self.filesArray addObject:[self.sellerApp objectForKey:@"image4"]];
        self.photostotal = 4;
    }
    
    [self checkStatus];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row == 0) {
        return self.topCell;
    }
    else if (indexPath.row == 1) {
        return self.imageCell;
    }
    else if (indexPath.row == 2) {
        return self.infoCell;
    }
    else if (indexPath.row == 3) {
        return self.spaceCell;
    }
    else{
        return nil;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return 300;
    }
    else if (indexPath.row == 1) {
        return 105;
    }
    else if (indexPath.row == 2) {
        return 155;
    }
    else if (indexPath.row == 3) {
        return 60;
    }
    else{
        return 44;
    }
}

- (IBAction)crossPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - text view delegates

-(void)textViewDidEndEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"Quickly tell us what kind of stuff you sell (e.g. Supreme, Yeezys) and how much you have to sell";
        textView.textColor = [UIColor lightGrayColor];
        self.textEntered = NO;
    }
    else{
        self.textEntered = YES;
        [self checkStatus];
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

-(void)textViewDidBeginEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@"Quickly tell us what kind of stuff you sell (e.g. Supreme, Yeezys) and how much you have to sell"]) {
        textView.text = @"";
        textView.textColor = [UIColor colorWithRed:74/255.0f green:74/255.0f blue:74/255.0f alpha:1.0f];
    }
    else{
        self.somethingChanged = YES;
    }
}

#pragma mark - collection view delegates

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    AddImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.delegate = self;
    
    if (self.photostotal == 0) {
        
        [cell.deleteButton setHidden:YES];
        
        if (indexPath.row == 0) {
            [cell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
            [self.firstCam setEnabled:YES];
        }
        else if (indexPath.row == 1) {
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
            [self.secondCam setEnabled:NO];
        }
        else if (indexPath.row == 2) {
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
            [self.thirdCam setEnabled:NO];
        }
        else if (indexPath.row == 3) {
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
            [self.fourthCam setEnabled:NO];
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

- (void)firstCamPressed:(id)sender {
    
    if (self.firstCam.enabled == YES) {
        [self showPicker];
    }
}
- (void)secondCamPressed:(id)sender {
    if (self.secondCam.enabled == YES) {
        //show action sheet for either picker, library or web (eventually)
        [self showPicker];
    }
}
- (void)thirdPressed:(id)sender {
    if (self.thirdCam.enabled == YES) {
        //show action sheet for either picker, library or web (eventually)
        [self showPicker];
    }
}
- (void)fourthCamPressed:(id)sender {
    if (self.fourthCam.enabled == YES) {
        //show action sheet for either picker, library or web (eventually)
        [self showPicker];
    }
}

-(void)showPicker{
    
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
                    
                    self.barButtonPressed = YES;
                    
                    [self presentViewController:imagePickerController animated:YES completion:NULL];
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
                        [self showAlertWithTitle:@"Library Permission" andMsg:@"Bump needs access to your photos to add images here, enable this in your iPhone's Settings"];
                    });
                });
                NSLog(@"denied");
            }
                break;
            default:
                break;
        }
    }];
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 4;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row < self.photostotal){ //sometimes a cell can be moved and it will be enlarged when held but user can't move it - i think this is related to the speed of this evaluation here. To speed it up, maybe just save the correct return value somewhere and always just return that
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

#pragma mark - helper methods

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

#pragma bar button delegates

-(void)hideBarButton{
    self.buttonShowing = NO;
    
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)showBarButton{
    self.buttonShowing = YES;
    
    self.longButton.alpha = 0.0f;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.longButton.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self hideBarButton];
}

-(void)viewDidDisappear:(BOOL)animated{
    if (self.barButtonPressed != YES) {
        self.longButton = nil;
    }
}

-(void)savePressed{
    
    if (self.somethingChanged != YES) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
        
    [self.longButton setEnabled:NO];
    [self showHUD];
    
    self.sellerApp[@"legitCheck"] = @"YES";

    //save description
    self.sellerApp[@"description"] = self.infoTextView.text;

    //save photos
    if (self.photostotal == 1) {
        
        PFFile *imageFile1 = self.filesArray[0];
        [self.sellerApp setObject:imageFile1 forKey:@"image1"];

    }
    else if (self.photostotal == 2){
        
        PFFile *imageFile1 = self.filesArray[0];
        [self.sellerApp setObject:imageFile1 forKey:@"image1"];
        
        PFFile *imageFile2 = self.filesArray[1];
        [self.sellerApp setObject:imageFile2 forKey:@"image2"];

    }
    else if (self.photostotal == 3){
        
        PFFile *imageFile1 = self.filesArray[0];
        [self.sellerApp setObject:imageFile1 forKey:@"image1"];
        
        PFFile *imageFile2 = self.filesArray[1];
        [self.sellerApp setObject:imageFile2 forKey:@"image2"];
        
        PFFile *imageFile3 = self.filesArray[2];
        [self.sellerApp setObject:imageFile3 forKey:@"image3"];

    }
    else if (self.photostotal == 4){
        
        PFFile *imageFile1 = self.filesArray[0];
        [self.sellerApp setObject:imageFile1 forKey:@"image1"];
        
        PFFile *imageFile2 = self.filesArray[1];
        [self.sellerApp setObject:imageFile2 forKey:@"image2"];
        
        PFFile *imageFile3 = self.filesArray[2];
        [self.sellerApp setObject:imageFile3 forKey:@"image3"];
        
        PFFile *imageFile4 = self.filesArray[3];
        [self.sellerApp setObject:imageFile4 forKey:@"image4"];
    }
    
    //save location
    if ([[PFUser currentUser] objectForKey:@"profileLocation"]) {
        NSString *locString = [PFUser currentUser][@"profileLocation"];
        [self.sellerApp setObject:locString forKey:@"location"];
    }
    
    [self.sellerApp saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            [self hidHUD];
            [self.delegate completedLegitVC];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else{
            [self hidHUD];
            [self showAlertWithTitle:@"Save Error" andMsg:@"Make sure you're connected to the internet!"];
            [self.longButton setEnabled:YES];
        }
    }];
}

#pragma image picker delegates

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
                                    
                                    //update ordered images array
                                    self.imagesToProcess = imagesPlaceholder;
                                    
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
        [self finalImage:self.imagesToProcess[0]];
    }
}

-(void)finalImage:(UIImage *)image{
    UIImage *newImage = [image scaleImageToSize:CGSizeMake(750, 750)];
    
    self.somethingChanged = YES;
    
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
                                              @"pageName":@"CreateForSale",
                                              @"photosTotal": [NSNumber numberWithInt:self.photostotal]
                                              }];
            
            //prevent crash when creating a PFFile with nil data
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
        
        self.photostotal ++;
    }
    
    [self checkStatus];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [imagePickerController dismissViewControllerAnimated:YES completion:NULL];
}

-(void)checkStatus{
    
    if (self.photostotal > 0 && self.textEntered == YES && self.buttonShowing == NO) {
        [self showBarButton];
    }
    else if ((self.photostotal == 0 || self.textEntered == NO) && self.buttonShowing == YES){
        [self hideBarButton];
    }
}

-(void)hidHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
}

@end
