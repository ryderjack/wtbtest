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
#import "AppDelegate.h"
#import "ExplainView.h"

@interface CreateForSaleListing ()

@end

@implementation CreateForSaleListing

- (void)viewDidLoad {
    [super viewDidLoad];

    //THE PLAN
    //use images when creating a listing. It's fast & reliable AND can use smaller thumbnails so looks better
    //when editing though we only have pffiles.... is there a reliable/nice way of converting them to data->UIImage?
    //what if we used getData and on success of each call we allocate that to the correctly UIImage property - self.firstImage
    //then we do a check in each callback to see if we have the rest - if so, stop the spinner & load up the CV
    
    self.navigationItem.title = @"S E L L";
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    //hide swipe view to start (unless in edit mode)
    self.colourSwipeView.alpha = 0.0;
    self.coloursArray = @[@"Black", @"White", @"Grey",@"Blue", @"Orange", @"Green", @"Red", @"Camo",@"Peach", @"Yellow", @"Purple", @"Pink"];
    self.categories = @[@"footwear", @"clothing", @"accessories",@"shirt", @"tshirt", @"shoes", @"shoe", @"trouser"];

    self.chosenColour = @"";
    
    self.chosenColourSArray = [NSMutableArray array];
    
    self.chosenColourImageView.alpha = 0.0;
    [self setImageBorder:self.chosenColourImageView];
    
    self.secondChosenColourImageView.alpha = 0.0;
    [self setImageBorder:self.secondChosenColourImageView];
    
    //UIColor objects that correspond to the colours in above array (added brown as a placeholder for camo so the indexes are still correct)
    self.colourValuesArray = @[[UIColor blackColor],[UIColor whiteColor],[UIColor lightGrayColor],[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0],[UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1.0],[UIColor colorWithRed:0.49 green:0.83 blue:0.13 alpha:1.0],[UIColor colorWithRed:0.95 green:0.20 blue:0.30 alpha:1.0],[UIColor brownColor],[UIColor colorWithRed:1.00 green:0.81 blue:0.50 alpha:1.0],[UIColor colorWithRed:0.97 green:0.91 blue:0.11 alpha:1.0],[UIColor colorWithRed:0.56 green:0.07 blue:1.00 alpha:1.0],[UIColor colorWithRed:0.93 green:0.58 blue:1.00 alpha:1.0],[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]];

    //setup colour swipe view
    self.colourSwipeView.delegate = self;
    self.colourSwipeView.dataSource = self;
    self.colourSwipeView.clipsToBounds = YES;
    self.colourSwipeView.pagingEnabled = NO;
    self.colourSwipeView.truncateFinalPage = NO;
    [self.colourSwipeView setBackgroundColor:[UIColor clearColor]];
    self.colourSwipeView.alignment = SwipeViewAlignmentCenter;
    [self.colourSwipeView reloadData];
    
    //scroll to middle
    self.colourSwipeView.currentItemIndex = self.coloursArray.count/2;

    //button setup
    self.firstCam = [[UIButton alloc]init];
    self.secondCam = [[UIButton alloc]init];
    self.thirdCam = [[UIButton alloc]init];
    self.fourthCam = [[UIButton alloc]init];
    self.fifthCam = [[UIButton alloc]init];
    self.sixthCam = [[UIButton alloc]init];
    self.sevenCam = [[UIButton alloc]init];
    self.eightCam = [[UIButton alloc]init];
    
    [self.firstCam setEnabled:YES];
    [self.secondCam setEnabled:NO];
    [self.thirdCam setEnabled:NO];
    [self.fourthCam setEnabled:NO];
    [self.fifthCam setEnabled:NO];
    [self.sixthCam setEnabled:NO];
    [self.sevenCam setEnabled:NO];
    [self.eightCam setEnabled:NO];
    
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
    
    self.payField.placeholder = [NSString stringWithFormat:@"0.00"];
    
    self.genderSize = @"";
    self.locationString = @"";
    
    self.photostotal = 0;
    self.runningPhotosTotal = 0;

    self.descriptionField.delegate = self;
    self.payField.delegate = self;
    self.itemTitleTextField.delegate = self;
    self.quantityField.delegate = self;
    
    [self saleaddDoneButton];
    [self quantityAddDoneButton];
    
    self.descriptionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.payCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.itemTitleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.spaceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.imagesCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.colourCell.selectionStyle = UITableViewCellSelectionStyleNone;

    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cancelCross"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.profanityList = @[@"cunt", @"wanker", @"nigger", @"penis", @"cock", @"depop", @"grailed"];
    self.flagWords = @[@"fake", @"replica", @"ua", @"unauthentic"];
    
    self.filesArray = [NSMutableArray array];
    self.imagesArray = [NSMutableArray array];

    self.multipleSizeArray = [NSArray array];
    self.imagesToProcess = [NSMutableArray array];
    self.placeholderAssetArray = [NSMutableArray array];
    self.multipleSizeAcronymArray = [NSMutableArray array];
    self.finalSizeArray = [NSMutableArray array];
    
    self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
    if (self.introMode != YES) {
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
            //don't reset a previous location when editing so just get loc when creating
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
    }

    
    if ([[PFUser currentUser].objectId isEqualToString:@"qnxRRxkY2O"] || [[PFUser currentUser].objectId isEqualToString:@"IIEf7cUvrO"]) {
        if ([[NSUserDefaults standardUserDefaults]boolForKey:@"listMode"]==YES) {
            NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:@"listUser"];
            
            PFQuery *userQ = [PFUser query];
            [userQ whereKey:@"objectId" equalTo:userID];
            [userQ getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    self.cabin = (PFUser *)object;
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
    
    if (self.editMode != YES) {
        [self.itemTitleTextField becomeFirstResponder];
    }
    
    //check if verified by facebook or email, if neither then show verify email flow
    if ([[[PFUser currentUser] objectForKey:@"emailIsVerified"]boolValue] != YES && ![[PFUser currentUser]objectForKey:@"facebookId"]) {
        //user isn't verified
        self.verified = NO;
        [self showVerifyAlert];
    }
    else{
        self.verified = YES;
        
        //check if user is banned
        PFQuery *bannedQuery = [PFQuery queryWithClassName:@"bannedUsers"];
        [bannedQuery whereKey:@"user" equalTo:[PFUser currentUser]];
        [bannedQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                self.banMode = YES;
                [self showAlertWithTitle:@"Account Restricted" andMsg:@"If you feel you're seeing this as a mistake then let us know hello@sobump.com"];
            }
        }];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if (self.introMode == YES) {
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
    }
    
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
    else if ([self.currency isEqualToString:@"USD"] || [self.currency isEqualToString:@"AUD"]) {
        self.currencySymbol = @"$";
    }
    self.payField.placeholder = [NSString stringWithFormat:@"%@0.00", self.currencySymbol];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0){
        return 1;
    }
    else if (section == 1){
        return 1;
    }
    else if (section == 2){
        return 4;
    }
    else if (section == 3){
        return 1;
    }
    else if (section == 4){
        return 1;
    }
    else if (section == 5){
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
            return self.itemTitleCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.imagesCell;
        }
    }
    else if (indexPath.section ==2){
        if(indexPath.row == 0){
            return self.conditionCell;
        }
        else if(indexPath.row == 1){
            return self.categoryCell;
        }
        else if(indexPath.row == 2){
            return self.sizeCell;
        }
//        else if(indexPath.row == 3){
//            return self.locationCell;
//        }
        else if(indexPath.row == 3){
            return self.payCell;
        }
    }
    else if (indexPath.section ==3){
        return self.colourCell;
    }
    else if (indexPath.section ==4){
        return self.descriptionCell;
    }
    else if (indexPath.section ==5){
        return self.spaceCell;
    }
    return nil;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    self.somethingChanged = YES;
    
    [self removeKeyboard];
    [self dismissColour];
    
    if (indexPath.section ==2){
        if(indexPath.row == 0){
            
            ConditionsOptionsTableView *vc = [[ConditionsOptionsTableView alloc]init];
            vc.delegate = self;
            
            //setup already selected condition
            if (![self.chooseCondition.text isEqualToString:@"Select"]) {
                vc.selection = self.chooseCondition.text;
            }
            
            [self.navigationController pushViewController:vc animated:YES];
            
//            SelectViewController *vc = [[SelectViewController alloc]init];
//            vc.delegate = self;
//            vc.sellListing = YES;
//            vc.setting = @"condition";
//            self.selection = @"condition";
//            
//            if (![self.chooseCondition.text isEqualToString:@"select"]) {
//                NSArray *selectedArray = [self.chooseCondition.text componentsSeparatedByString:@"."];
//                
//                NSMutableArray *placeholder = [NSMutableArray arrayWithArray:selectedArray];
//                int i = 0;
//                
//                for (NSString *condition in selectedArray) {
//                    if ([condition isEqualToString:@"BNWT"]) {
//                        [placeholder replaceObjectAtIndex:i withObject:@"Brand New With Tags"];
//                    }
//                    else if ([condition isEqualToString:@"BNWOT"]) {
//                        [placeholder replaceObjectAtIndex:i withObject:@"Brand New Without Tags"];
//                    }
//                    i++;
//                }
//                
//                vc.holdingArray = [NSArray arrayWithArray:placeholder];
//            }
//            
//            [self.navigationController pushViewController:vc animated:YES];
            
        }
        else if(indexPath.row == 1){
            SelectViewController *vc = [[SelectViewController alloc]init];
            vc.delegate = self;
            vc.setting = @"category";
            self.selection = @"category";
            
            if (![self.chooseCategroy.text isEqualToString:@"Select"]) {
                NSArray *selectedArray = [self.chooseCategroy.text componentsSeparatedByString:@"."];
                vc.holdingArray = [NSArray arrayWithArray:selectedArray];
            }
            
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if(indexPath.row == 2){
            if ([self.chooseCategroy.text isEqualToString:@"Select"]) {
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
                    if (![self.chooseSize.text isEqualToString:@"Select"] && ![self.chooseSize.text isEqualToString:@"Multiple"]) {
                        NSArray *selectedArray = [self.chooseSize.text componentsSeparatedByString:@"/"];
                        NSLog(@"selected already %@", selectedArray);
                        vc.holdingArray = [NSArray arrayWithArray:selectedArray];
                        vc.holdingGender = [[NSString alloc]initWithString:self.genderSize];
                    }
                    else if ([self.chooseSize.text isEqualToString:@"Multiple"]){
                        NSMutableArray *placeholder = [NSMutableArray array];
                        
                        for (id object in self.multipleSizeArray) { //pass sizes back in the shortened version they came in
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
                else if ([self.chooseCategroy.text isEqualToString:@"Clothing"] || [self.chooseCategroy.text isEqualToString:@"Tops"] || [self.chooseCategroy.text isEqualToString:@"Bottoms"] || [self.chooseCategroy.text isEqualToString:@"Outerwear"]){
                    SelectViewController *vc = [[SelectViewController alloc]init];
                    vc.delegate = self;
                    vc.setting = @"sizeclothing";
                    vc.sellListing = YES;
                    vc.multipleAllowed = YES;
                    vc.holdingGender = [[NSString alloc]initWithString:self.genderSize];

                    // setup previously selected
                    if (![self.chooseSize.text isEqualToString:@"Select"] && ![self.chooseSize.text isEqualToString:@"Multiple"]) {
                        NSArray *selectedArray = [self.chooseSize.text componentsSeparatedByString:@"/"];
                        vc.holdingArray = [NSArray arrayWithArray:selectedArray];
                    }
                    else if ([self.chooseSize.text isEqualToString:@"Multiple"]){
                        NSMutableArray *placeholder = [NSMutableArray array];
                        
                        for (id object in self.multipleSizeAcronymArray) {
                            NSString *string = [NSString stringWithFormat:@"%@", object];
                            [placeholder addObject:string];
                        }
                        vc.holdingArray = placeholder;
                    }
                    
                    self.selection = @"size";
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else if ([self.chooseCategroy.text isEqualToString:@"Accessories"] || [self.chooseCategroy.text isEqualToString:@"Proxy"]){
                    // can't select accessory sizing for now or for proxies either
                }
                else{
                    SelectViewController *vc = [[SelectViewController alloc]init];
                    vc.delegate = self;
                    vc.setting = @"sizeclothing";
                    vc.sellListing = YES;
                    // setup previously selected
                    if (![self.chooseSize.text isEqualToString:@"Select"]) {
                        NSArray *selectedArray = [self.chooseSize.text componentsSeparatedByString:@"/"];
                        vc.holdingArray = [NSArray arrayWithArray:selectedArray];
                    }
                    
                    self.selection = @"size";
                    [self.navigationController pushViewController:vc animated:YES];
                }
            }
        }

    }
    else if(indexPath.section == 3){
        [self addColourPressed:self];
    }
    else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        return 69;
    }
    else if (indexPath.section == 1){
        return 104;
    }
    else if (indexPath.section ==2 || indexPath.section == 3){
        return 44;
    }
    else if (indexPath.section ==4){
        return 104;
    }
    else if (indexPath.section ==5){
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
    if (self.somethingChanged == NO) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else{
        if ([self.descriptionField.text isEqualToString:@"Describe the item's style, sizing, and any possible flaws"] && [self.chooseCondition.text isEqualToString:@"Select"] && [self.chooseCategroy.text isEqualToString:@"Select"] && [self.chooseSize.text isEqualToString:@"Select"] && [self.payField.text isEqualToString:@""] && self.photostotal == 0){
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else{
            UIAlertController *alertView;
            if (self.editMode == YES) {
                alertView = [UIAlertController alertControllerWithTitle:@"Leave this page?" message:@"Are you sure you want to leave? Your changes won't be saved!" preferredStyle:UIAlertControllerStyleAlert];
            }
            else{
                alertView = [UIAlertController alertControllerWithTitle:@"Cancel listing?" message:@"Are you sure you want to cancel your for sale listing?" preferredStyle:UIAlertControllerStyleAlert];
            }
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Stay" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self dismissViewControllerAnimated:YES completion:nil];
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
    if (self.editMode) {
        self.somethingChanged = YES;
    }
    
    [self dismissColour];
    
    if (textField == self.payField) {
        self.payField.text = [NSString stringWithFormat:@"%@", self.currencySymbol];
    }
}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    self.somethingChanged = YES;
    [self dismissColour];

    if ([textView.text isEqualToString:@"Describe the item's style, sizing, and any possible flaws"]) {
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
        
//        NSLog(@"price array %lu", (unsigned long)priceArray.count);
        
        if (priceArray.count == 0) {
            //entered nothing
            priceString = @"0.00";
        }
        else if (priceArray.count > 2) {
            //multiple decimal points added
            priceString = @"0.00";
        }
        else if (priceArray.count == 1){
            //just entered an int
            NSString *intAmount = priceArray[0];
            
            //check if just zeros
            if ([[intAmount stringByReplacingOccurrencesOfString:@"0" withString:@""]isEqualToString:@""]) {
                intAmount = @"0";
            }
            
//            NSLog(@"length of this int %@   int %lu",intAmount ,(unsigned long)intAmount.length);
            priceString = [NSString stringWithFormat:@"%@.00", intAmount];
        }
        else if (priceArray.count > 1){
            
            NSString *intAmount = priceArray[0];
            
            //check if its just all zeros
            if ([[intAmount stringByReplacingOccurrencesOfString:@"0" withString:@""]isEqualToString:@""]) {
                intAmount = @"0";
            }
            else if (intAmount.length == 1){
                NSLog(@"single digit then a decimal point");
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
            if ([[priceString stringByReplacingOccurrencesOfString:@"0" withString:@""]isEqualToString:@""]) {
                priceString = @"0.00";
            }
            else{
                priceString = [NSString stringWithFormat:@"%@.00", priceString];
            }
            NSLog(@"no decimal point so price is %@", priceString);
        }
        
//        NSLog(@"price string %@", priceString);
        
//        CGFloat strFloat = (CGFloat)[priceString floatValue];
//        NSLog(@"PRICE FLOAT %.2f", strFloat);
        
        if ([priceString isEqualToString:@"0.00"] || [priceString isEqualToString:@""] || [priceString isEqualToString:[NSString stringWithFormat:@".00"]] || [priceString isEqualToString:@"  "]) {
            //invalid price number
            NSLog(@"invalid price number");
            self.payField.text = @"";
        }
        else{
            self.payField.text = [NSString stringWithFormat:@"%@%@", self.currencySymbol, priceString];
        }
    }
    else if (textField == self.itemTitleTextField){
        NSArray *autoColourCheck = @[@"black", @"blue",@"navy", @"orange", @"green", @"red", @"peach", @"yellow", @"purple", @"pink", @"grey", @"camo",@"camouflage",@"bred",@"oreo", @"breds", @"oreos", @"navy"];
        BOOL checkedColours = NO;
        
        //check for profanity and see if colour mentioned to prefill
        NSArray *words = [textField.text componentsSeparatedByString:@" "];
        for (NSString *string in words) {
            if ([self.profanityList containsObject:string.lowercaseString]) {
                textField.text = @"";
                return;
            }
            else if ([self.flagWords containsObject:string.lowercaseString]){
                textField.text = @"";
                [self showAlertWithTitle:@"Authenticity Warning" andMsg:@"BUMP is for buying/selling authentic streetwear, if you're found to be selling fake or replica items we will be forced to ban your account to protect the community"];
                return;
            }
            else if([autoColourCheck containsObject:string.lowercaseString] && self.chosenColourSArray.count < 2 && ![self.chosenColourSArray containsObject:string.capitalizedString]){
                
                //if already have navy don't add blue again
                if ([string.capitalizedString isEqualToString:@"Navy"] && [self.chosenColourSArray containsObject:@"Blue"]) {
                    return;
                }
                //to make sure we stop when we have 2 colours
                if (checkedColours != YES) {
                    self.chosenColour = string.capitalizedString;
                    [self setImageBorder:self.chosenColourImageView];
                    [self setImageBorder:self.secondChosenColourImageView];
                    
                    if ([string.capitalizedString isEqualToString:@"Camo"] || [string.capitalizedString isEqualToString:@"Camouflage"]) {
                        
                        [self.chosenColourSArray addObject:@"Camo"];
                        
                        if (self.chosenColourSArray.count < 2) {
                            [self.chosenColourImageView setImage:[UIImage imageNamed:@"camoColour"]];

                        }
                        else{
                            [self.secondChosenColourImageView setImage:[UIImage imageNamed:@"camoColour"]];
                        }
                    }
                    
                    //auto fill for breds
                    else if ([string.capitalizedString isEqualToString:@"Bred"] || [string.capitalizedString isEqualToString:@"Breds"]) {
                        [self.chosenColourSArray addObject:@"Black"];
                        [self.chosenColourSArray addObject:@"Red"];

                        self.secondChosenColourImageView.image = nil;
                        [self.secondChosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[0]]]];
                        
                        self.chosenColourImageView.image = nil;
                        [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[1]]]];
                    }
                    
                    //auto fill for oreos
                    else if ([string.capitalizedString isEqualToString:@"Oreo"] || [string.capitalizedString isEqualToString:@"Oreos"]) {
                        [self.chosenColourSArray addObject:@"Black"];
                        [self.chosenColourSArray addObject:@"White"];
                        
                        self.secondChosenColourImageView.image = nil;
                        [self.secondChosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[0]]]];
                        
                        self.chosenColourImageView.image = nil;
                        [self setWhiteImageBorder:self.chosenColourImageView];
                        [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[1]]]];
                    }
                    else{
                        //add to chosen colours array
                        if ([string.capitalizedString isEqualToString:@"Navy"]) {
                            [self.chosenColourSArray addObject:@"Blue"];
                        }
                        else{
                            [self.chosenColourSArray addObject:string.capitalizedString];
                        }

                        //if have 1 colour set the right hand side image view
                        if (self.chosenColourSArray.count < 2) {
                            //got 1 colour
                            self.chosenColourImageView.image = nil;
                            [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[0]]]];
                        }
                        
                        //if we have 1 colour already, move that to the left handside so it reads the same as title
                        else{
                            //got 2 colours
                            self.secondChosenColourImageView.image = nil;
                            [self.secondChosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[0]]]];
                            
                            self.chosenColourImageView.image = nil;
                            [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[1]]]];
                        }
                    }
                    
                    if (self.chosenColourSArray.count == 2) {
                        checkedColours = YES;
                    }
                    
                    [self.colourSwipeView reloadData];
                    
                    [UIView animateWithDuration:0.3
                                          delay:0
                                        options:UIViewAnimationOptionCurveEaseIn
                                     animations:^{
                                         
                                         if (self.chosenColourSArray.count == 2) {
                                             self.chosenColourImageView.alpha = 1.0;
                                             self.secondChosenColourImageView.alpha = 1.0;
                                         }
                                         else{
                                             self.chosenColourImageView.alpha = 1.0;
                                             self.secondChosenColourImageView.alpha = 0.0;
                                         }
                                         
                                         self.colourLabel.alpha = 1.0;
                                         self.chooseColourLabel.alpha = 0.0;
                                         self.colourSwipeView.alpha = 0.0;
                                     }
                                     completion:nil];
                }
            }
        }
        
        if (self.chosenColourSArray.count == 0) {
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.chosenColourImageView.alpha = 0.0;
                                 self.secondChosenColourImageView.alpha = 0.0;

                                 self.chooseColourLabel.alpha = 1.0;
                                 self.colourSwipeView.alpha = 0.0;
                                 self.colourLabel.alpha = 1.0;
                             }
                             completion:nil];
        }
    }
    else if (textField == self.quantityField){
        NSString *check = [textField.text stringByReplacingOccurrencesOfString:@"0" withString:@""];
        
        if ([check isEqualToString:@""]) {
            textField.text = @"";
        }
        
    }
}
-(void)textViewDidEndEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"Describe the item's style, sizing, and any possible flaws";
        textView.textColor = [UIColor lightGrayColor];
    }
    else{
        //they've wrote something so do the check for profanity
        NSArray *words = [textView.text componentsSeparatedByString:@" "];
        for (NSString *string in words) {
            if ([self.profanityList containsObject:string.lowercaseString]) {
                textView.text = @"Describe the item's style, sizing, and any possible flaws";
                textView.textColor = [UIColor lightGrayColor];
            }
            else if ([self.flagWords containsObject:string.lowercaseString]){
                textView.text = @"Describe the item's style, sizing, and any possible flaws";
                
                [self showAlertWithTitle:@"Authenticity Warning" andMsg:@"Bump is for buying/selling authentic streetwear, if you're found to be selling fake or replica items we will be forced to ban your account to protect the community"];
                return;
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
    [self.itemTitleTextField resignFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.payField) {
        // Check for deletion of the currency sign
        if (range.location == 0 && [textField.text hasPrefix:[NSString stringWithFormat:@"%@", self.currencySymbol]])
            return NO;
        
        NSString *updatedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray *stringsArray = [updatedText componentsSeparatedByString:@"."];
        
        //check for multiple decimal points
        if (stringsArray.count > 2) {
            return NO;
        }
        
//        //check for entering decimal point before any numbers
        if ([string isEqualToString:@"."] && [textField.text isEqualToString:self.currencySymbol]) {
            textField.text = [NSString stringWithFormat:@"%@0", self.currencySymbol];
            return YES;
        }
        
        // Check for an absurdly large amount & 0
        if (stringsArray.count > 0)
        {
            NSString *dollarAmount = stringsArray[0];
            
            if (stringsArray.count > 1) {
                NSString *centAmount = stringsArray[1];
                
                //DONT LET ADD MORE NUMBERS IF ALREADY HAVE 2 NUMBERS AFTER DECIMAL POINT
                if ([centAmount length] > 2) {
                    return NO;
                }
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
    else if(textField == self.itemTitleTextField){
        //limit number of characters
        if(range.length + range.location > textField.text.length)
        {
            return NO;
        }
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return newLength <= 50;
    }
    else if(textField == self.quantityField){
        //limit number of characters
        if(range.length + range.location > textField.text.length)
        {
            return NO;
        }
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return newLength <= 3;
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
        self.multipleMode = NO;
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
                        imagePickerController.maximumNumberOfSelection = 8-self.photostotal;
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
                               targetSize:PHImageManagerMaximumSize // CGSizeMake(750, 750) - quality is notably better with MaxSize target size, so keep that for now
                              contentMode:PHImageContentModeDefault
                                  options:requestOptions
                            resultHandler:^void(UIImage *image, NSDictionary *info) {
                                                        
                                if (image.CGImage == nil || image == nil) {
                                    [Answers logCustomEventWithName:@"Image Error: CGImage is nil from Asset"
                                                   customAttributes:@{
                                                                      @"pageName":@"Create for sale"
                                                                      }];
                                    [self showAlertWithTitle:@"Image Error" andMsg:@"If this problem persists, screenshot the picture and try again!\n\nThe original may be too big to upload"];
                                    return;
                                }
                                
                                
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
        [self displayCropperWithImage:self.imagesToProcess[0]];
    }
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [imagePickerController dismissViewControllerAnimated:YES completion:NULL];
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

-(void)finalImage:(UIImage *)image{
    UIImage *newImage = [image scaleImageToSize:CGSizeMake(750, 750)]; //manipulate bytes for testing here
    UIImage *smallImage = [image scaleImageToSize:CGSizeMake(200,200)];

    self.somethingChanged = YES;
    
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
            [self hidHUD];
            [self showAlertWithTitle:@"Image Error" andMsg:@"Please check your connection and try again!"];
            [self.longButton setEnabled:YES];
            
            return;
        }
        
        self.photostotal ++;

        //add to CV array
        PFFile *imageFile = [PFFile fileWithName:@"Image1.jpg" data:data];
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                NSLog(@"saved file");
                
                //add in check so only runs for first image
//                if (self.calledImgAnalyzer) { //CHECK add ! to enable
//                    //now call img analyzer
//                    NSDictionary *params = @{@"imageURL": imageFile.url};
//                    
//                    [PFCloud callFunctionInBackground:@"analyzeImage" withParameters:params block:^(NSDictionary *response, NSError *error) {
//                        if (!error) {
//                            self.calledImgAnalyzer = YES;
//                            
//                            NSLog(@"analyzer response %@", response);
//                            
//                            //set category (depending on confidence)
//                            if([response valueForKey:@"tags"] != nil) {
//                                
//                                NSArray *tagArray = [NSArray arrayWithArray:[response valueForKey:@"tags"]];
//                                
//                                for (NSDictionary *tag in tagArray) {
//                                    
//                                    NSString *tagString = [tag valueForKey:@"name"];
//                                    float confidence = [[tag valueForKey:@"confidence"]floatValue];
//                                    
//                                    if ([self.categories containsObject:tagString] && confidence > 0.6) {
//                                        NSLog(@"CATEGORY: %@",tagString);
//                                        
//                                        if ([[tagString lowercaseString] isEqualToString:@"clothing"] || [[tagString lowercaseString] isEqualToString:@"shirt"] || [[tagString lowercaseString] isEqualToString:@"jumper"]) {
//                                            self.chooseCategroy.text = @"Clothing";
//                                        }
//                                        else if([[tagString lowercaseString] isEqualToString:@"footwear"] || [[tagString lowercaseString] isEqualToString:@"shoes"]){
//                                            self.chooseCategroy.text = @"Footwear";
//                                        }
//                                    }
//                                }
//                            }
//                            
//                            //set main colour
//                            if([response valueForKey:@"color"] != nil) {
//                                
//                                NSDictionary *colorDic = [response valueForKey:@"color"];
//                                NSString *color = [colorDic valueForKey:@"dominantColorForeground"];
//                                
//                                if ([self.coloursArray containsObject:[color capitalizedString]]) {
//                                    NSLog(@"got this colour: %@", [color capitalizedString]);
//                                    
//                                    [self.chosenColourSArray addObject:[color capitalizedString]];
//                                    
//                                    self.chosenColourImageView.image = nil;
//                                    [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[0]]]];
//                                    
//                                    [self.colourSwipeView reloadData];
//                                    
//                                    [UIView animateWithDuration:0.3
//                                                          delay:0
//                                                        options:UIViewAnimationOptionCurveEaseIn
//                                                     animations:^{
//                                                         
//                                                         if (self.chosenColourSArray.count == 2) {
//                                                             self.chosenColourImageView.alpha = 1.0;
//                                                             self.secondChosenColourImageView.alpha = 1.0;
//                                                         }
//                                                         else{
//                                                             self.chosenColourImageView.alpha = 1.0;
//                                                             self.secondChosenColourImageView.alpha = 0.0;
//                                                         }
//                                                         
//                                                         self.colourLabel.alpha = 1.0;
//                                                         self.chooseColourLabel.alpha = 0.0;
//                                                         self.colourSwipeView.alpha = 0.0;
//                                                     }
//                                                     completion:nil];
//                                }
//                                
//                            }
//                            
//                            //monitor adult rating
//                            
//                            
//                        }
//                        else{
//                            NSLog(@"analyzer error %@", error);
//                        }
//                    }];
//                }
            }
            else{
                NSLog(@"error saving small file %@", error);
            }
        }];
        
        [self.filesArray addObject:imageFile];
        [self.imagesArray addObject:smallImage];
        
        //reload table view then after that scroll to the most recent image
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.imgCollectionView.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             [self.imgCollectionView reloadData];
                             [UIView animateWithDuration:0.3
                                                   delay:0
                                                 options:UIViewAnimationOptionCurveEaseIn
                                              animations:^{
                                                  self.imgCollectionView.alpha = 1.0;
                                              }
                                              completion:^(BOOL finished) {
                                                  self.imgCollectionView.alpha = 1.0;
                                                  
                                                  NSIndexPath *lastItem = [NSIndexPath indexPathForRow:[self.imgCollectionView numberOfItemsInSection:0]-1 inSection:0];
                                                  
                                                  [self.imgCollectionView scrollToItemAtIndexPath:lastItem atScrollPosition:UICollectionViewScrollPositionRight animated:YES];

                                              }];
                         }];
        
//        NSLog(@"image file %@", imageFile);
//        NSLog(@"IMAGE BYTES (bytes):%lu",(unsigned long)[data length]);
        [self.imagesToProcess removeObjectAtIndex:0];

        if (self.imagesToProcess.count > 0) {
        
            //call process again
            [self processMultiple];
        }
        else{
            if (self.photostotal >= 2) {
                self.imgFooterLabel.text = @"Pro tip: Hold down on images to rearrange";
                [self.imgFooterView setNeedsDisplay];
            }
            else{
                if ([self.chooseCategroy.text isEqualToString:@"Proxy"]) {
                    self.imgFooterLabel.text = @"Photos: Max 8";
                }
                else{
                    self.imgFooterLabel.text = @"Photos: Min 2 | Max 8";
                }
                [self.imgFooterView setNeedsDisplay];
            }
        }
    }
    else{
        //when user takes a photo they end up in here
        NSData *data = UIImageJPEGRepresentation(newImage, 0.8);
        
        if (data == nil) {
            [Answers logCustomEventWithName:@"PFFile Nil Data"
                           customAttributes:@{
                                              @"pageName":@"CreateForSale",
                                              @"photosTotal": [NSNumber numberWithInt:self.photostotal],
                                              @"tookPic": @"Yup"
                                              }];
            
            //prevent crash when creating a PFFile with nil data
            [self hidHUD];
            [self showAlertWithTitle:@"Image Error" andMsg:@"Please check your connection and try again!"];
            [self.longButton setEnabled:YES];
            
            return;
        }
        
        self.photostotal ++;
        
        //add to CV array
        PFFile *imageFile = [PFFile fileWithName:@"Image1.jpg" data:data];
        [imageFile saveInBackground]; //speeds up final save
        
        [self.filesArray addObject:imageFile];
        [self.imagesArray addObject:smallImage];
        
        //reload table view then after that scroll to the most recent image
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.imgCollectionView.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             [self.imgCollectionView reloadData];
                             [UIView animateWithDuration:0.3
                                                   delay:0
                                                 options:UIViewAnimationOptionCurveEaseIn
                                              animations:^{
                                                  self.imgCollectionView.alpha = 1.0;
                                              }
                                              completion:^(BOOL finished) {
                                                  self.imgCollectionView.alpha = 1.0;
                                                  
                                                  NSIndexPath *lastItem = [NSIndexPath indexPathForRow:[self.imgCollectionView numberOfItemsInSection:0]-1 inSection:0];
                                                  
                                                  [self.imgCollectionView scrollToItemAtIndexPath:lastItem atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
                                              }];
                         }];
        
        if (self.photostotal >= 2) {
            self.imgFooterLabel.text = @"Pro tip: Hold down on images to rearrange";
            [self.imgFooterView setNeedsDisplay];
        }
        else{
            if ([self.chooseCategroy.text isEqualToString:@"Proxy"]) {
                self.imgFooterLabel.text = @"Photos: Max 8";
            }
            else{
                self.imgFooterLabel.text = @"Photos: Min 2 | Max 8";
            }
            [self.imgFooterView setNeedsDisplay];
        }
    }
}

- (void)quantityAddDoneButton {
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
    self.quantityField.inputAccessoryView = keyboardToolbar;
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
    
    [doneBarButton setTintColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1]];
    keyboardToolbar.barTintColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];
    
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
                    NSString *titleString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                    
                    if (geoPoint) {
                        self.geopoint = geoPoint;
                        self.locationString = titleString;
                    }
                    else{
                        self.locationString = @"";
                        self.geopoint = nil;
                        
                        [Answers logCustomEventWithName:@"Location Error on sale listing"
                                       customAttributes:@{}];
                    }
                }
                else{
                    NSLog(@"loc error 1 %@", error);
                }
            }];
        }
        else{
            NSLog(@"loc error 2 %@", error);
        }
    }];
}

-(void)tagString:(NSString *)tag{
}

#pragma condition delegate

-(void)firstConditionPressed{
    self.chooseCondition.text = @"Deadstock";
}

-(void)secondConditionPressed{
    self.chooseCondition.text = @"New";
}

-(void)thirdConditionPressed{
    self.chooseCondition.text = @"Used";
}

-(void)addItemViewController:(SelectViewController *)controller didFinishEnteringItem:(NSString *)selectionString withgender:(NSString *)genderString andsizes:(NSArray *)array{
    
    //empty array
    self.multipleSizeArray = @[];
    
    if ([self.selection isEqualToString:@"category"]){
        if ([selectionString isEqualToString:@"Accessories"] || [selectionString isEqualToString:@"Proxy"]) {
            self.chooseSize.text = @"";
        }
        else{
            self.chooseSize.text = @"Select";
        }
        
        //don't require 2 images for a proxy
        if ([selectionString isEqualToString:@"Proxy"]) {
            self.ignore2Pics = YES;
            
            if (self.photostotal >= 2) {
                self.imgFooterLabel.text = @"Pro tip: Hold down on images to rearrange";
            }
            else{
                self.imgFooterLabel.text = @"Photos: Max 8";
            }
            [self.imgFooterView setNeedsDisplay];
            
        }
        else{
            self.ignore2Pics = NO;
        }
        
        self.chooseCategroy.text = selectionString;
    }
    else if ([self.selection isEqualToString:@"size"]){
        self.chooseSize.text = @"Select";
        
        if (genderString) {
            self.genderSize = genderString;
        }
        
        if (array) {
            if (array.count == 1) {
                if ([array[0] isKindOfClass:[NSString class]]) {
                    if ([array[0] isEqualToString:@"Other"]) {
                       self.chooseSize.text = [NSString stringWithFormat:@"%@",array[0]];
                    }
                    else if ([array[0] isEqualToString:@"XXL"] || [array[0] isEqualToString:@"XS"] || [array[0] isEqualToString:@"XXS"] || [array[0] isEqualToString:@"XL"] || [array[0] isEqualToString:@"S"] || [array[0] isEqualToString:@"M"] ||[array[0] isEqualToString:@"L"] || [array[0] isEqualToString:@"Other"]){
                        
                        //its a clothing size
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
                self.multipleSizeAcronymArray = array;
                
                NSMutableArray *placehoderSizesArray = [NSMutableArray array];
                
                //remove the UK and convert to longer text if clothing size
                for (id size in array) {
                    if ([size isKindOfClass:[NSString class]]) {
                        if ([size isEqualToString:@"XXS"]){
                            [placehoderSizesArray addObject:@"XXSmall"];
                        }
                        else if ([size isEqualToString:@"XS"]){
                            [placehoderSizesArray addObject:@"XSmall"];
                        }
                        else if ([size isEqualToString:@"S"]){
                            [placehoderSizesArray addObject:@"Small"];
                        }
                        else if ([size isEqualToString:@"M"]){
                            [placehoderSizesArray addObject:@"Medium"];
                        }
                        else if ([size isEqualToString:@"L"]){
                            [placehoderSizesArray addObject:@"Large"];
                        }
                        else if ([size isEqualToString:@"XL"]){
                            [placehoderSizesArray addObject:@"XLarge"];
                        }
                        else if ([size isEqualToString:@"XXL"]){
                            [placehoderSizesArray addObject:@"XXLarge"];
                        }
                        else{
                            [placehoderSizesArray addObject:size];
                        }
                    }
                    else{
                        //multiple shoe sizes returned
                        NSString *shoeString = [NSString stringWithFormat:@"%@", size];
                        NSString *shoeSize = [shoeString stringByReplacingOccurrencesOfString:@"UK " withString:@""];
                        NSLog(@"add shoe size to array %@", shoeSize);
                        [placehoderSizesArray addObject:shoeSize];
                    }
                }
                
                NSLog(@"placeholder sizes array %@", placehoderSizesArray);
                
                self.multipleSizeArray = placehoderSizesArray;
            }
        }
        else{
            NSLog(@"no array, been an error");
        }
    }
    
    //only change the quantity if it hasn't been entered already
    if ((self.multipleSizeArray.count > 0 && [self.quantityField.text isEqualToString:@""]) || [self.quantityField.text intValue] < self.multipleSizeArray.count) {
        self.quantityField.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.multipleSizeArray.count];
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0 || section == 2) {
        return 0.01;
    }
    else if (section == 1) {
        return 80.0;
    }
    return 32.0f;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    
    if (section != 1 && section != 4) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.contentView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section == 1) {
        return 32;
    }
    else{
        return 0.01;
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    
    if (section == 1) {
        if (!self.imgFooterView) {
            self.imgFooterView = [[UIView alloc]initWithFrame:CGRectMake(10, 0, self.view.frame.size.width-20, 32)];
            self.imgFooterView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
            
            self.imgFooterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0,self.imgFooterView.frame.size.width, 32)];
            self.imgFooterLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
            self.imgFooterLabel.textColor = [UIColor lightGrayColor];
            
            if (self.photostotal >= 2) {
                self.imgFooterLabel.text = @"Pro tip: Hold down on images to rearrange";
            }
            else{
                if ([self.chooseCategroy.text isEqualToString:@"Proxy"]) {
                    self.imgFooterLabel.text = @"Photos: Max 8";
                }
                else{
                    self.imgFooterLabel.text = @"Photos: Min 2 | Max 8";
                }
            }
            
            self.imgFooterLabel.numberOfLines = 1;
            self.imgFooterLabel.textAlignment = NSTextAlignmentCenter;
            self.imgFooterLabel.lineBreakMode = NSLineBreakByWordWrapping;
            self.imgFooterLabel.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
            [self.imgFooterView addSubview:self.imgFooterLabel];
            
            self.imgFooterLabel.center = self.imgFooterView.center;
        }

        
        return self.imgFooterView;
    }
    return nil;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    if (section == 1) {
        UIView *containerView = [[UIView alloc]initWithFrame:CGRectMake(10, 0, self.view.frame.size.width-20, 80)];
        
        //tap to explain what a tagged pic is to bottom half of header
        UIButton *tagButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 30, self.view.frame.size.width-20, 40)];
        [tagButton addTarget:self action:@selector(taggedPressed) forControlEvents:UIControlEventTouchUpInside];
        [containerView addSubview:tagButton];
        
        containerView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];

        UILabel *lblSectionName = [[UILabel alloc] initWithFrame:CGRectMake(0, 0,containerView.frame.size.width, 60)];
        lblSectionName.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        lblSectionName.textColor = [UIColor lightGrayColor];
        
        NSMutableAttributedString *labelString = [[NSMutableAttributedString alloc] initWithString:@"Bump encourages tagged photos to keep buyers safe, untagged items may be removed\nWhat's a tagged photo?"];
        [self modifyString:labelString setColorForText:@"What's a tagged photo?" withColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
        
        lblSectionName.attributedText = labelString;
        
        lblSectionName.numberOfLines = 0;
        lblSectionName.textAlignment = NSTextAlignmentCenter;
        lblSectionName.lineBreakMode = NSLineBreakByWordWrapping;
        lblSectionName.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
        [lblSectionName sizeToFit];
        [containerView addSubview:lblSectionName];
        
        lblSectionName.center = containerView.center;
        
        return containerView;
    }
    else if (section == 4){
        
        if (!self.colourContainerView) {
            self.colourContainerView = [[UIView alloc]initWithFrame:CGRectMake(10, 0, self.view.frame.size.width-20, 32)];
            self.colourContainerView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
            
            if (!self.dismissColourButton) {
                //            NSLog(@"dismiss colour button");
                self.dismissColourButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0,self.colourContainerView.frame.size.width, 32)];
                [self.dismissColourButton addTarget:self action:@selector(dismissColour) forControlEvents:UIControlEventTouchUpInside];
                self.dismissColourButton.alpha = 0.0;
                
                self.dismissColourButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
                
                [self.dismissColourButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];
                
                [self.dismissColourButton setTitle:@"Dismiss" forState:UIControlStateNormal];
                self.dismissColourButton.titleLabel.numberOfLines = 1;
                self.dismissColourButton.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
                [self.colourContainerView addSubview:self.dismissColourButton];
                self.dismissColourButton.center = self.colourContainerView.center;
            }
        }

        return self.colourContainerView;
    }
    return nil;
}

//- (NSString*) tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger)section
//{
//
//    if (section == 1){
//        return @"Bump encourages tagged photos to reassure buyers that what they’re purchasing actually exists";
//    }
//    else {
//        return @"";
//    }
//}
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
- (IBAction)fifthCamPressed:(id)sender {
    if (self.fifthCam.enabled == YES) {
        //show action sheet for either picker, library or web (eventually)
        self.camButtonTapped = 5;
        [self alertSheet];
    }
}
- (IBAction)sixthCamPressed:(id)sender {
    if (self.sixthCam.enabled == YES) {
        //show action sheet for either picker, library or web (eventually)
        self.camButtonTapped = 6;
        [self alertSheet];
    }
}
- (void)seventhCamPressed{
    if (self.sevenCam.enabled == YES) {
        //show action sheet for either picker, library or web (eventually)
        self.camButtonTapped = 7;
        [self alertSheet];
    }
}
- (void)eightCamPressed{
    if (self.eightCam.enabled == YES) {
        //show action sheet for either picker, library or web (eventually)
        self.camButtonTapped = 8;
        [self alertSheet];
    }
}

- (void)savePressed{
    if (self.editMode == YES && self.somethingChanged != YES) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    [self.longButton setEnabled:NO];
    
    NSString *descriptionCheck = [self.descriptionField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *titleCheck = [self.itemTitleTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *priceCheck = [self.payField.text stringByReplacingOccurrencesOfString:self.currencySymbol withString:@""];
    
    //check for one word titles
    NSArray *titleWordsArray = [self.itemTitleTextField.text componentsSeparatedByString:@" "];
    
    if (self.photostotal < 2 && self.ignore2Pics != YES){
        
        [self showAlertWithTitle:@"2 Photos Needed 📸" andMsg:@"To help fight scammers and strengthen the community please add at least 2 tagged photos to your listing"];
        [self.longButton setEnabled:YES];
    }
    else if(([self.chooseCategroy.text isEqualToString:@"Accessories"] || [self.chooseCategroy.text isEqualToString:@"Proxy"]) && ([self.chooseCondition.text isEqualToString:@"Select"] || [self.descriptionField.text isEqualToString:@"Describe the item's style, sizing, and any possible flaws"] || (self.photostotal < 2 && self.ignore2Pics != YES) || (self.photostotal == 0 && self.ignore2Pics == YES) || [titleCheck isEqualToString:@""] || [self.payField.text isEqualToString:@""] || [priceCheck isEqualToString:@"0.00"])){
//        NSLog(@"accessories selected but haven't filled everything else in");
        
        [self showAlertWithTitle:@"Empty Fields" andMsg:@"Make sure you've added the item title, condition, description, price and 2 tagged photos!"];
        [self.longButton setEnabled:YES];
    }
    else if ([self.chooseCategroy.text isEqualToString:@"Select"] || [self.chooseCondition.text isEqualToString:@"Select"] || [self.chooseSize.text isEqualToString:@"Select"] || [self.descriptionField.text isEqualToString:@"Describe the item's style, sizing, and any possible flaws"]|| [descriptionCheck isEqualToString:@""] || (self.photostotal < 2 && self.ignore2Pics != YES) || (self.photostotal == 0 && self.ignore2Pics == YES) || [titleCheck isEqualToString:@""] || [self.payField.text isEqualToString:@""] || [priceCheck isEqualToString:@"0.00"]) {
        
        [self showAlertWithTitle:@"Empty Fields" andMsg:@"Make sure you've added the item title, condition, description, price and 2 tagged photos!"];
        [self.longButton setEnabled:YES];
    }
    else if(titleWordsArray.count == 1){
        
        [self showAlertWithTitle:@"Item title" andMsg:@"Make sure your item title is as descriptive as possible"];
        [self.longButton setEnabled:YES];
    }
    else{
        
//        [self showHUD];
        NSLog(@"good to save");
        
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
            
            CGFloat strFloat = (CGFloat)[priceString floatValue];
            
//            NSLog(@"PRICE FLOAT %.2f", strFloat);
            
            if ([self.currency isEqualToString:@"GBP"]) {
                forSaleItem[@"salePriceGBP"] = @(strFloat);
                
                float USD = strFloat*1.30;
                forSaleItem[@"salePriceUSD"] = @(USD);
                
                float EUR = strFloat*1.11;
                forSaleItem[@"salePriceEUR"] = @(EUR);
                
                float AUD = strFloat*1.62;
                forSaleItem[@"salePriceAUD"] = @(AUD);
                
            }
            else if ([self.currency isEqualToString:@"USD"]) {
                forSaleItem[@"salePriceUSD"] = @(strFloat);
                float GBP = strFloat*0.77;
                forSaleItem[@"salePriceGBP"] = @(GBP);
                float EUR = strFloat*0.85;
                forSaleItem[@"salePriceEUR"] = @(EUR);
                
                float AUD = strFloat*1.25;
                forSaleItem[@"salePriceAUD"] = @(AUD);
            }
            else if ([self.currency isEqualToString:@"EUR"]) {
                forSaleItem[@"salePriceEUR"] = @(strFloat);
                float GBP = strFloat*0.90;
                forSaleItem[@"salePriceGBP"] = @(GBP);
                float USD = strFloat*1.17;
                forSaleItem[@"salePriceUSD"] = @(USD);
                
                float AUD = strFloat*1.49;
                forSaleItem[@"salePriceAUD"] = @(AUD);
            }
            else if ([self.currency isEqualToString:@"AUD"]) {
                float EUR = strFloat*0.67;
                forSaleItem[@"salePriceEUR"] = @(EUR);
                float GBP = strFloat*0.62;
                forSaleItem[@"salePriceGBP"] = @(GBP);
                float USD = strFloat*0.80;
                forSaleItem[@"salePriceUSD"] = @(USD);
                
                forSaleItem[@"salePriceAUD"] = @(strFloat);
            }
            
            [Answers logCustomEventWithName:@"Created Sale Listing with Price"
                           customAttributes:@{
                                              @"price":@"YES"
                                              }];
        }
        else{
            [Answers logCustomEventWithName:@"Created Sale Listing with Price"
                           customAttributes:@{
                                              @"price":@"NO"
                                              }];
            
            [self showAlertWithTitle:@"Price Error" andMsg:@"Make sure you've entered a valid price"];
            return;
        }
        
        NSString *description = [self.descriptionField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        [forSaleItem setObject:description forKey:@"description"];
        [forSaleItem setObject:[description  lowercaseString]forKey:@"descriptionLower"];
        [forSaleItem setObject:self.chooseCondition.text forKey:@"condition"];
        [forSaleItem setObject:self.chooseCategroy.text forKey:@"category"];
        [forSaleItem setObject:self.chooseSize.text forKey:@"sizeLabel"];
        [forSaleItem setObject:[self.itemTitleTextField.text capitalizedString] forKey:@"itemTitle"];
        [forSaleItem setObject:[self.itemTitleTextField.text lowercaseString] forKey:@"itemTitleLower"];
        
        if (self.chosenColourSArray.count > 0) {
            [forSaleItem setObject:self.chosenColourSArray forKey:@"coloursArray"];
        }
        else if (self.editMode){
            [forSaleItem removeObjectForKey:@"coloursArray"];
        }
        
        if (self.editMode != YES) {
            [forSaleItem setObject:@"live" forKey:@"status"];
        }
        [forSaleItem setObject:self.multipleSizeArray forKey:@"multipleSizes"];

        //opt into each selected size
        if (self.multipleSizeArray.count != 0) {
            
            if ([self.chooseCategroy.text isEqualToString:@"Footwear"]) {
                //footwear selected so iterate over the multipleSizeArray which only contains the numbers in string form (no UK prefix)
                for (id object in self.multipleSizeArray) {
                    NSString *size = [NSString stringWithFormat:@"%@", object];
                    [self.finalSizeArray addObject:size];
                }
            }
            else{
                //clothing selected - so add acronyms to the sizeArray (to correspond with filter)
                for (id object in self.multipleSizeAcronymArray) {
                    NSString *size = [NSString stringWithFormat:@"%@", object];
                    [self.finalSizeArray addObject:size];
                }
            }
        }
        else{
            //only one size selected
            NSString *size = [NSString stringWithFormat:@"%@", self.chooseSize.text];
            if ([self.chooseCategroy.text isEqualToString:@"Footwear"]) {
                //do extra trimming here to remove 'UK ' from start of shoe size
                NSString *shoeSize = [size stringByReplacingOccurrencesOfString:@"UK " withString:@""];
                [self.finalSizeArray addObject:shoeSize];
            }
            else{
                [self.finalSizeArray addObject:size];
            }
        }
        
//        NSLog(@"finalSizeArray: %@", self.finalSizeArray);
        [forSaleItem setObject:self.finalSizeArray forKey:@"sizeArray"];
        
        //calc keywords
        NSArray *wasteWords = [NSArray arrayWithObjects:@"x",@"to",@"with",@"and",@"the",@"wtb",@"or",@" ",@".",@"very",@"interested", @"in",@"wanted", @"",@"selling", @"new", @"condition", @"good", @"great",@"wts", nil];
        NSCharacterSet *charactersToRemove = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
        
        NSString *title = [self.itemTitleTextField.text lowercaseString];
        NSArray *strings = [title componentsSeparatedByString:@" "];
        NSMutableArray *mutableStrings = [NSMutableArray arrayWithArray:strings];
        [mutableStrings removeObjectsInArray:wasteWords];
        [mutableStrings removeObjectsInArray:[NSArray arrayWithObject:charactersToRemove]];
        
        NSMutableArray *finalKeywordArray = [NSMutableArray array];
        
        for (NSString *string in mutableStrings) {
            if (![string canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            }
            else{
                NSString* cleanedString = [string stringByTrimmingCharactersInSet: [NSCharacterSet punctuationCharacterSet]];
                [finalKeywordArray addObject:cleanedString];
            }
        }
        
        //add extra keywords that make the listing easier to find
        finalKeywordArray = [self addAlternativeKeywordsFromArray:finalKeywordArray];
        [forSaleItem setObject:finalKeywordArray forKey:@"keywords"];
        
        if (![self.genderSize isEqualToString:@""]) {
            [forSaleItem setObject:self.genderSize forKey:@"sizeGender"];
        }
        
        //check if user has location on their profile to add to listing
        if (self.listingAsMode == YES) {
            if ([self.cabin objectForKey:@"profileLocation"]) {
                if (![[self.cabin objectForKey:@"profileLocation"] containsString:@"(null)"]) {
                    [forSaleItem setObject:[self.cabin objectForKey:@"profileLocation"] forKey:@"location"];
                }
            }
        }
        else {
            if ([[PFUser currentUser] objectForKey:@"profileLocation"]) {
                if (![[[PFUser currentUser] objectForKey:@"profileLocation"] containsString:@"(null)"]) {
                    [forSaleItem setObject:[[PFUser currentUser] objectForKey:@"profileLocation"] forKey:@"location"];
                }
            }
            
            if ([[PFUser currentUser] objectForKey:@"continent"]) {
                [forSaleItem setObject:[[PFUser currentUser] objectForKey:@"continent"] forKey:@"continent"];
            }
        }
        
        //use geopoint info from profile so matches to the label
        if ([[PFUser currentUser] objectForKey:@"geopoint"]) {
            [forSaleItem setObject:[[PFUser currentUser] objectForKey:@"geopoint"] forKey:@"geopoint"];
        }
        else if (self.geopoint){
            [forSaleItem setObject:self.geopoint forKey:@"geopoint"];
        }

        [forSaleItem setObject:self.currency forKey:@"currency"];
        
        if (self.listingAsMode == YES) {
            [forSaleItem setObject:self.cabin forKey:@"sellerUser"];
        }
        else{
            [forSaleItem setObject:[PFUser currentUser] forKey:@"sellerUser"];
        }
        
        //save a smaller thumbnail image from first cell's image
        UIImage *imageOne = [self.imagesArray[0] scaleImageToSize:CGSizeMake(200, 200)];
        NSData* dataOne = UIImageJPEGRepresentation(imageOne, 0.8f);
        
        if (dataOne == nil) {
            [Answers logCustomEventWithName:@"PFFile Nil Data"
                           customAttributes:@{
                                              @"pageName":@"CreateForSale",
                                              @"photosTotal": [NSNumber numberWithInt:self.photostotal],
                                              @"type":@"thumbnail"
                                              }];
            
            //prevent crash when creating a PFFile with nil data
            [self hidHUD];
            [self showAlertWithTitle:@"First Image Error" andMsg:@"We had an issue processing your first image - please delete it and reupload\n\nIf the problem persists, try using a different photo as the image size may be too large"];
            [self.longButton setEnabled:YES];
            
            return;
        }
        
        PFFile *thumbFile = [PFFile fileWithName:@"thumb1.jpg" data:dataOne];
        [forSaleItem setObject:thumbFile forKey:@"thumbnail"];
        
        //save photos
        if (self.photostotal == 1) {
            
            PFFile *imageFile1 = self.filesArray[0];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            if (self.editMode == YES) {
                [forSaleItem removeObjectForKey:@"image2"];
                [forSaleItem removeObjectForKey:@"image3"];
                [forSaleItem removeObjectForKey:@"image4"];
                [forSaleItem removeObjectForKey:@"image5"];
                [forSaleItem removeObjectForKey:@"image6"];
                [forSaleItem removeObjectForKey:@"image7"];
                [forSaleItem removeObjectForKey:@"image8"];
            }
        }
        else if (self.photostotal == 2){
            
            PFFile *imageFile1 = self.filesArray[0];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            PFFile *imageFile2 = self.filesArray[1];
            [forSaleItem setObject:imageFile2 forKey:@"image2"];
            
            if (self.editMode == YES) {
                [forSaleItem removeObjectForKey:@"image3"];
                [forSaleItem removeObjectForKey:@"image4"];
                [forSaleItem removeObjectForKey:@"image5"];
                [forSaleItem removeObjectForKey:@"image6"];
                [forSaleItem removeObjectForKey:@"image7"];
                [forSaleItem removeObjectForKey:@"image8"];
            }
        }
        else if (self.photostotal == 3){
            
            PFFile *imageFile1 = self.filesArray[0];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            PFFile *imageFile2 = self.filesArray[1];
            [forSaleItem setObject:imageFile2 forKey:@"image2"];
            
            PFFile *imageFile3 = self.filesArray[2];
            [forSaleItem setObject:imageFile3 forKey:@"image3"];
            
            if (self.editMode == YES) {
                [forSaleItem removeObjectForKey:@"image4"];
                [forSaleItem removeObjectForKey:@"image5"];
                [forSaleItem removeObjectForKey:@"image6"];
                [forSaleItem removeObjectForKey:@"image7"];
                [forSaleItem removeObjectForKey:@"image8"];
            }
        }
        else if (self.photostotal == 4){
            
            PFFile *imageFile1 = self.filesArray[0];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            PFFile *imageFile2 = self.filesArray[1];
            [forSaleItem setObject:imageFile2 forKey:@"image2"];
            
            PFFile *imageFile3 = self.filesArray[2];
            [forSaleItem setObject:imageFile3 forKey:@"image3"];
            
            PFFile *imageFile4 = self.filesArray[3];
            [forSaleItem setObject:imageFile4 forKey:@"image4"];
            
            if (self.editMode == YES) {
                [forSaleItem removeObjectForKey:@"image5"];
                [forSaleItem removeObjectForKey:@"image6"];
                [forSaleItem removeObjectForKey:@"image7"];
                [forSaleItem removeObjectForKey:@"image8"];
            }
        }
        else if (self.photostotal == 5){
            
            PFFile *imageFile1 = self.filesArray[0];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            PFFile *imageFile2 = self.filesArray[1];
            [forSaleItem setObject:imageFile2 forKey:@"image2"];
            
            PFFile *imageFile3 = self.filesArray[2];
            [forSaleItem setObject:imageFile3 forKey:@"image3"];
            
            PFFile *imageFile4 = self.filesArray[3];
            [forSaleItem setObject:imageFile4 forKey:@"image4"];
            
            PFFile *imageFile5 = self.filesArray[4];
            [forSaleItem setObject:imageFile5 forKey:@"image5"];
            
            if (self.editMode == YES) {
                [forSaleItem removeObjectForKey:@"image6"];
                [forSaleItem removeObjectForKey:@"image7"];
                [forSaleItem removeObjectForKey:@"image8"];
            }
        }
        else if (self.photostotal == 6){
            
            PFFile *imageFile1 = self.filesArray[0];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            PFFile *imageFile2 = self.filesArray[1];
            [forSaleItem setObject:imageFile2 forKey:@"image2"];
            
            PFFile *imageFile3 = self.filesArray[2];
            [forSaleItem setObject:imageFile3 forKey:@"image3"];
            
            PFFile *imageFile4 = self.filesArray[3];
            [forSaleItem setObject:imageFile4 forKey:@"image4"];
            
            PFFile *imageFile5 = self.filesArray[4];
            [forSaleItem setObject:imageFile5 forKey:@"image5"];
            
            PFFile *imageFile6 = self.filesArray[5];
            [forSaleItem setObject:imageFile6 forKey:@"image6"];
            
            if (self.editMode == YES) {
                [forSaleItem removeObjectForKey:@"image7"];
                [forSaleItem removeObjectForKey:@"image8"];
            }
        }
        else if (self.photostotal == 7){
            
            PFFile *imageFile1 = self.filesArray[0];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            PFFile *imageFile2 = self.filesArray[1];
            [forSaleItem setObject:imageFile2 forKey:@"image2"];
            
            PFFile *imageFile3 = self.filesArray[2];
            [forSaleItem setObject:imageFile3 forKey:@"image3"];
            
            PFFile *imageFile4 = self.filesArray[3];
            [forSaleItem setObject:imageFile4 forKey:@"image4"];
            
            PFFile *imageFile5 = self.filesArray[4];
            [forSaleItem setObject:imageFile5 forKey:@"image5"];
            
            PFFile *imageFile6 = self.filesArray[5];
            [forSaleItem setObject:imageFile6 forKey:@"image6"];
            
            PFFile *imageFile7 = self.filesArray[6];
            [forSaleItem setObject:imageFile7 forKey:@"image7"];
            
            if (self.editMode == YES) {
                [forSaleItem removeObjectForKey:@"image8"];
            }
        }
        
        else if (self.photostotal == 8){
            
            PFFile *imageFile1 = self.filesArray[0];
            [forSaleItem setObject:imageFile1 forKey:@"image1"];
            
            PFFile *imageFile2 = self.filesArray[1];
            [forSaleItem setObject:imageFile2 forKey:@"image2"];
            
            PFFile *imageFile3 = self.filesArray[2];
            [forSaleItem setObject:imageFile3 forKey:@"image3"];
            
            PFFile *imageFile4 = self.filesArray[3];
            [forSaleItem setObject:imageFile4 forKey:@"image4"];
            
            PFFile *imageFile5 = self.filesArray[4];
            [forSaleItem setObject:imageFile5 forKey:@"image5"];
            
            PFFile *imageFile6 = self.filesArray[5];
            [forSaleItem setObject:imageFile6 forKey:@"image6"];
            
            PFFile *imageFile7 = self.filesArray[6];
            [forSaleItem setObject:imageFile7 forKey:@"image7"];
            
            PFFile *imageFile8 = self.filesArray[7];
            [forSaleItem setObject:imageFile8 forKey:@"image8"];
        }
        
        [forSaleItem setObject:[NSDate date] forKey:@"lastUpdated"];
        
        int quantInt = 1;
        
        if (![self.quantityField.text isEqualToString:@""]) {
            quantInt = (int)[self.quantityField.text intValue];
        }
        
        [forSaleItem setObject:@(quantInt) forKey:@"quantity"];
        
        if (self.editMode || self.listingAsMode) {
            [self showHUD];
            [forSaleItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    NSLog(@"saved listing");
                    [Answers logCustomEventWithName:@"Created for sale listing"
                                   customAttributes:@{}];
                    
                    if (self.listingAsMode == YES) {
                        [self.cabin incrementKey:@"forSalePostNumber"];
                        [self.cabin saveInBackground];
                    }
                    else{
                        
                        //schedule local notif. for first listing
                        if (![[PFUser currentUser] objectForKey:@"forSalePostNumber"]) {
                            
                            //cancel first listing local push
                            NSArray *notificationArray = [[UIApplication sharedApplication] scheduledLocalNotifications];
                            for(UILocalNotification *notification in notificationArray){
                                if ([notification.alertBody.lowercaseString containsString:@"what are you selling? list your first item for sale on bump"]) {
                                    // delete this notification
                                    [[UIApplication sharedApplication] cancelLocalNotification:notification] ;
                                }
                            }
                            
                            //local notifications set up
                            NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
                            dayComponent.day = 1;
                            NSCalendar *theCalendar = [NSCalendar currentCalendar];
                            NSDate *dateToFire = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
                            
                            // Create new date
                            NSDateComponents *components1 = [theCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                                           fromDate:dateToFire];
                            
                            NSDateComponents *components3 = [[NSDateComponents alloc] init];
                            
                            [components3 setYear:components1.year];
                            [components3 setMonth:components1.month];
                            [components3 setDay:components1.day];
                            
                            [components3 setHour:20];
                            
                            // Generate a new NSDate from components3.
                            NSDate * combinedDate = [theCalendar dateFromComponents:components3];
                            
                            UILocalNotification *localNotification = [[UILocalNotification alloc]init];
                            [localNotification setAlertBody:@"Congrats on your first listing! Want to sell faster? Try searching through wanted listings on BUMP"]; //make sure this matches the app delegate local notifications handler method
                            [localNotification setFireDate: combinedDate];
                            [localNotification setTimeZone: [NSTimeZone defaultTimeZone]];
                            [localNotification setRepeatInterval: 0];
                            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                        }

                    }
                    
                    [self.longButton setEnabled:YES];
                    [self dismissViewControllerAnimated:YES completion:nil];

                }
                else{
                    //error saving listing
                    [Answers logCustomEventWithName:@"Error Saving Sale Listing"
                                   customAttributes:@{
                                                      @"error":[NSString stringWithFormat:@"%@", error]
                                                      }];
                    
                    [self hidHUD];
                    [self.longButton setEnabled:YES];
                    [self showAlertWithTitle:@"Save Error 477" andMsg:@"We couln't save your item! Make sure you have a strong connection\n\nYour listing images may be too big. Try screenshotting the original images and adding the screenshots to the listing instead\n\nSend Team Bump a message from Settings if you need more help"];
                    
                    NSLog(@"error saving listing %@", error);
                }
            }];

        }
        else{
            //pass the saving onto the purchase tab
            [[NSNotificationCenter defaultCenter] postNotificationName:@"postingItem" object:@[forSaleItem,imageOne]];
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            appDelegate.tabBarController.selectedIndex = 0;
            
            if (self.introMode) {
                [self.delegate dismissCreateParent];
            }
            else{
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
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

-(void)finishLoadingImages{
    
    //order the images array
    if (self.photostotal == 1) {
        [self.imagesArray addObject:self.firstImage];
        [self.filesArray addObject:[self.listing objectForKey:@"image1"]];
        
    }
    else if (self.photostotal == 2){
        [self.imagesArray addObject:self.firstImage];
        [self.imagesArray addObject:self.secondImage];
        
        [self.filesArray addObject:[self.listing objectForKey:@"image1"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image2"]];

        
    }
    else if (self.photostotal == 3){
        [self.imagesArray addObject:self.firstImage];
        [self.imagesArray addObject:self.secondImage];
        [self.imagesArray addObject:self.thirdImage];
        
        [self.filesArray addObject:[self.listing objectForKey:@"image1"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image2"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image3"]];
        
    }
    else if (self.photostotal == 4){
        [self.imagesArray addObject:self.firstImage];
        [self.imagesArray addObject:self.secondImage];
        [self.imagesArray addObject:self.thirdImage];
        [self.imagesArray addObject:self.fourthImage];
        
        [self.filesArray addObject:[self.listing objectForKey:@"image1"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image2"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image3"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image4"]];

    }
    else if (self.photostotal == 5){
        [self.imagesArray addObject:self.firstImage];
        [self.imagesArray addObject:self.secondImage];
        [self.imagesArray addObject:self.thirdImage];
        [self.imagesArray addObject:self.fourthImage];
        [self.imagesArray addObject:self.fifthImage];
        
        [self.filesArray addObject:[self.listing objectForKey:@"image1"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image2"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image3"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image4"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image5"]];


    }
    else if (self.photostotal == 6){
        [self.imagesArray addObject:self.firstImage];
        [self.imagesArray addObject:self.secondImage];
        [self.imagesArray addObject:self.thirdImage];
        [self.imagesArray addObject:self.fourthImage];
        [self.imagesArray addObject:self.fifthImage];
        [self.imagesArray addObject:self.sixthImage];
        
        [self.filesArray addObject:[self.listing objectForKey:@"image1"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image2"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image3"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image4"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image5"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image6"]];


    }
    else if (self.photostotal == 7){
        [self.imagesArray addObject:self.firstImage];
        [self.imagesArray addObject:self.secondImage];
        [self.imagesArray addObject:self.thirdImage];
        [self.imagesArray addObject:self.fourthImage];
        [self.imagesArray addObject:self.fifthImage];
        [self.imagesArray addObject:self.sixthImage];
        [self.imagesArray addObject:self.seventhImage];
        
        [self.filesArray addObject:[self.listing objectForKey:@"image1"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image2"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image3"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image4"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image5"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image6"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image7"]];

        
    }
    else if (self.photostotal == 8){
        [self.imagesArray addObject:self.firstImage];
        [self.imagesArray addObject:self.secondImage];
        [self.imagesArray addObject:self.thirdImage];
        [self.imagesArray addObject:self.fourthImage];
        [self.imagesArray addObject:self.fifthImage];
        [self.imagesArray addObject:self.sixthImage];
        [self.imagesArray addObject:self.seventhImage];
        [self.imagesArray addObject:self.eighthImage];
        
        [self.filesArray addObject:[self.listing objectForKey:@"image1"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image2"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image3"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image4"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image5"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image6"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image7"]];
        [self.filesArray addObject:[self.listing objectForKey:@"image8"]];

    }
    [self hidHUD];

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.imgCollectionView.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [self.imgCollectionView reloadData];
                         [UIView animateWithDuration:0.3
                                               delay:0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              self.imgCollectionView.alpha = 1.0;
                                          }
                                          completion:^(BOOL finished) {
                                              self.imgCollectionView.alpha = 1.0;
                                              
                                              NSIndexPath *lastItem = [NSIndexPath indexPathForRow:[self.imgCollectionView numberOfItemsInSection:0]-1 inSection:0];
                                              
                                              [self.imgCollectionView scrollToItemAtIndexPath:lastItem atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
                                          }];
                     }];
}

-(void)saleListingSetup{
    self.navigationItem.title = @"E D I T";
    [self showHUD];
    
    //images
    if ([self.listing objectForKey:@"image8"]) {
        
        self.photostotal = 8;
        
        PFFile *imageFile = [self.listing objectForKey:@"image8"];
        [imageFile getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
            if (data) {
                self.runningPhotosTotal++;
                
                UIImage *image = [UIImage imageWithData:data];
                self.eighthImage = image;
                
//                NSLog(@"got data 8 %@", self.eighthImage);
                
                
                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
            else{
                //error getting the data so
                self.runningPhotosTotal++;
                self.eighthImage = [UIImage imageNamed:@"camHolder"];
                
                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
        }];
    }
    
    if ([self.listing objectForKey:@"image7"]) {
        
        if (self.photostotal == 0) {
            self.photostotal = 7;
        }
        PFFile *imageFile = [self.listing objectForKey:@"image7"];
        [imageFile getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
            if (data) {
                self.runningPhotosTotal++;
                
                UIImage *image = [UIImage imageWithData:data];
                self.seventhImage = image;
                
//                NSLog(@"got data 7 %@", self.seventhImage);
                
                
                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
            else{
                //error getting the data so
                self.runningPhotosTotal++;
                self.seventhImage = [UIImage imageNamed:@"camHolder"];
                
                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
        }];
    }
    
    if ([self.listing objectForKey:@"image6"]) {
        
        if (self.photostotal == 0) {
            self.photostotal = 6;
        }
        PFFile *imageFile = [self.listing objectForKey:@"image6"];
        [imageFile getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
            if (data) {
                self.runningPhotosTotal++;
                
                UIImage *image = [UIImage imageWithData:data];
                self.sixthImage = image;
                
//                NSLog(@"got data 6 %@", self.sixthImage);
                
                
                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
            else{
                //error getting the data so
                self.runningPhotosTotal++;
                self.sixthImage = [UIImage imageNamed:@"camHolder"];
                
                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
        }];
    }
    
    if ([self.listing objectForKey:@"image5"]) {
        
        if (self.photostotal == 0) {
            self.photostotal = 5;
        }
        PFFile *imageFile = [self.listing objectForKey:@"image5"];
        [imageFile getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
            if (data) {
                self.runningPhotosTotal++;
                
                UIImage *image = [UIImage imageWithData:data];
                self.fifthImage = image;
                
//                NSLog(@"got data 5 %@", self.fifthImage);
                
                
                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
            else{
                //error getting the data so
                self.runningPhotosTotal++;
                self.fifthImage = [UIImage imageNamed:@"camHolder"];
                
                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
        }];
    }
    
    if ([self.listing objectForKey:@"image4"]) {
        
        if (self.photostotal == 0) {
            self.photostotal = 4;
        }
        PFFile *imageFile = [self.listing objectForKey:@"image4"];
        [imageFile getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
            if (data) {
                self.runningPhotosTotal++;
                
                UIImage *image = [UIImage imageWithData:data];
                self.fourthImage = image;
                
//                NSLog(@"got data 4 %@", self.fourthImage);
                
                
                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
            else{
                //error getting the data so
                self.runningPhotosTotal++;
                self.fourthImage = [UIImage imageNamed:@"camHolder"];

                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
        }];
    }
    
    if ([self.listing objectForKey:@"image3"]) {
        
        if (self.photostotal == 0) {
            self.photostotal = 3;
        }
        
        PFFile *imageFile = [self.listing objectForKey:@"image3"];
        [imageFile getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
            if (data) {
                self.runningPhotosTotal++;
                
                UIImage *image = [UIImage imageWithData:data];
                self.thirdImage = image;
                
//                NSLog(@"got data 3 %@", self.thirdImage);
                
                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
            else{
                self.runningPhotosTotal++;
                self.thirdImage = [UIImage imageNamed:@"camHolder"];

                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
        }];
    }
    
    if ([self.listing objectForKey:@"image2"]) {
        
        if (self.photostotal == 0) {
            self.photostotal = 2;
        }
        PFFile *imageFile = [self.listing objectForKey:@"image2"];
        [imageFile getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
            if (data) {
                self.runningPhotosTotal++;
                
                UIImage *image = [UIImage imageWithData:data];
                self.secondImage = image;
                
//                NSLog(@"got data 2 %@", self.secondImage);
                
                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
            else{
                self.runningPhotosTotal++;
                self.secondImage = [UIImage imageNamed:@"camHolder"];
                
                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
        }];
    }
    
    if ([self.listing objectForKey:@"image1"]) {
        if (self.photostotal == 0) {
            self.photostotal = 1;
        }
        
        PFFile *imageFile = [self.listing objectForKey:@"image1"];
        [imageFile getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
            if (data) {
                self.runningPhotosTotal++;
                UIImage *image = [UIImage imageWithData:data];
                self.firstImage = image;
                
//                NSLog(@"got data 1 %@", self.firstImage);

                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
            else{
                self.runningPhotosTotal++;
                self.firstImage = [UIImage imageNamed:@"camHolder"];
                
                if (self.runningPhotosTotal == self.photostotal) {
                    [self finishLoadingImages];
                }
            }
        }];
    }
    
    if ([self.listing objectForKey:@"itemTitle"]) {
        self.itemTitleTextField.text = [self.listing objectForKey:@"itemTitle"];
    }
    
    if ([self.listing objectForKey:@"condition"]) {
        self.chooseCondition.text = [self.listing objectForKey:@"condition"];
    }
    
    if ([self.listing objectForKey:@"coloursArray"]) {
        self.chosenColourSArray = [self.listing objectForKey:@"coloursArray"];
                
        [self.colourSwipeView reloadData];
        
        if (self.chosenColourSArray.count == 1) {
            //got 1 colour
            if ([self.chosenColourSArray[0] isEqualToString:@"Camo"]) {
                [self.chosenColourImageView setImage:[UIImage imageNamed:@"camoColour"]];
            }
            else{
                self.chosenColourImageView.image = nil;
                [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[0]]]];
            }
            self.colourLabel.alpha = 1.0;
            self.chooseColourLabel.alpha = 0.0;
            self.chosenColourImageView.alpha = 1.0;
            self.secondChosenColourImageView.alpha = 0.0;

            if ([self.chosenColourSArray[0] isEqualToString:@"White"]) {
                [self setWhiteImageBorder:self.chosenColourImageView];
            }
            else{
                [self setImageBorder:self.chosenColourImageView];
            }
        }
        else if(self.chosenColourSArray.count == 2){
            //2 colours
            if ([self.chosenColourSArray[0] isEqualToString:@"Camo"]) {
                [self.secondChosenColourImageView setImage:[UIImage imageNamed:@"camoColour"]];
                self.chosenColourImageView.image = nil;
                [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[1]]]];

            }
            else if ([self.chosenColourSArray[1] isEqualToString:@"Camo"]){
                [self.chosenColourImageView setImage:[UIImage imageNamed:@"camoColour"]];
                self.secondChosenColourImageView.image = nil;
                [self.secondChosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[0]]]];
            }
            else{
                self.chosenColourImageView.image = nil;
                [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[1]]]];

                self.secondChosenColourImageView.image = nil;
                [self.secondChosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[0]]]];
            }

            self.colourLabel.alpha = 1.0;
            self.chooseColourLabel.alpha = 0.0;
            self.chosenColourImageView.alpha = 1.0;
            self.secondChosenColourImageView.alpha = 1.0;
                        
            if ([self.chosenColourSArray[0] isEqualToString:@"White"]) {
                [self setWhiteImageBorder:self.secondChosenColourImageView];
                [self setImageBorder:self.chosenColourImageView];
            }
            else if ([self.chosenColourSArray[1] isEqualToString:@"White"]){
                [self setWhiteImageBorder:self.chosenColourImageView];
                [self setImageBorder:self.secondChosenColourImageView];
            }
        }
    }
    else if ([self.listing objectForKey:@"mainColour"]) {
        self.chosenColour = [self.listing objectForKey:@"mainColour"];
//        NSLog(@"chosen colour %@", self.chosenColour);
        [self.colourSwipeView reloadData];
        
        if ([self.chosenColour isEqualToString:@"Camo"]) {
            [self.chosenColourImageView setImage:[UIImage imageNamed:@"camoColour"]];
        }
        else{
            self.chosenColourImageView.image = nil;
            [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColour]]];
        }
        self.colourLabel.alpha = 1.0;
        self.chooseColourLabel.alpha = 0.0;
        self.chosenColourImageView.alpha = 1.0;
        
        if ([self.chosenColour isEqualToString:@"White"]) {
            [self setWhiteImageBorder:self.chosenColourImageView];
            
        }
        else{
            [self setImageBorder:self.chosenColourImageView];
        }
    }
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
        self.payField.text = [NSString stringWithFormat:@"%@%.2f",symbol,[[self.listing objectForKey:[NSString stringWithFormat:@"salePrice%@", [self.listing objectForKey:@"currency"]]]floatValue]];
    }
    
    self.chooseCategroy.text = [self.listing objectForKey:@"category"];
    
    if ([self.chooseCategroy.text isEqualToString:@"Proxy"]) {
        self.ignore2Pics = YES;
    }
    
    //sizing
    NSString *sizeLabel = [self.listing objectForKey:@"sizeLabel"];
    
    if ([sizeLabel isEqualToString:@"Multiple"]) {
        self.multipleSizeArray = [self.listing objectForKey:@"multipleSizes"];

        if ([self.chooseCategroy.text isEqualToString:@"Tops"] || [self.chooseCategroy.text isEqualToString:@"Bottoms"] || [self.chooseCategroy.text isEqualToString:@"Outerwear"]) {
            self.multipleSizeAcronymArray = [self.listing objectForKey:@"sizeArray"];
        }
    }

    self.chooseSize.text = sizeLabel;
    
    //if gendersize required (if category is footwear) set variable
    if ([self.listing objectForKey:@"sizeGender"]) {
        self.genderSize = [self.listing objectForKey:@"sizeGender"];
    }
    
    if ([self.listing objectForKey:@"geopoint"]) {
        self.geopoint = [self.listing objectForKey:@"geopoint"];
    }
    
    //setup quantity available
    if ([self.listing objectForKey:@"quantity"]) {
        int quant = [[self.listing objectForKey:@"quantity"]intValue];
        
        //otherwise just use 1 as the placeholder so can change if user adds multiple sizes
        if (quant > 1) {
            self.quantityField.text = [NSString stringWithFormat:@"%@",[self.listing objectForKey:@"quantity"]];
        }
    }
    
    //check if should ignore 2 photos requirement
    NSDateComponents *components3 = [[NSDateComponents alloc] init];
    NSCalendar *theCalendar = [NSCalendar currentCalendar];

    [components3 setYear:2017];
    [components3 setMonth:8];
    [components3 setDay:15];
    [components3 setHour:00];
    
    //generate the start date of 2 pics required in listings
    NSDate * combinedDate = [theCalendar dateFromComponents:components3];
    
    if ([self.listing.createdAt compare:combinedDate]==NSOrderedAscending) {
        //createdAt is earlier than date 2 pic became mandatory, ignore requirements for them
        self.ignore2Pics = YES;
    }
}


-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if (self.banMode) {
            self.banMode = NO;
            
            [self dismissViewControllerAnimated:YES completion:^{
               //change to first tab to force a checkifbanned which will then log the user out
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                appDelegate.tabBarController.selectedIndex = 0;
            }];
        }
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
//        self.webViewController.infoMode = NO;
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

#pragma mark - collection view delegates

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    //setup to use pffile array as the cell source
    
    AddImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
//    cell.itemImageView.file = nil;
//    cell.itemImageView.image = nil;
    
    cell.delegate = self;
    
    if (indexPath.row == 0) {

        //check photos total to display correct stuff
        if (self.imagesArray.count == 0) {
            [cell.deleteButton setHidden:YES];
            [self.firstCam setEnabled:YES];
            [cell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else{
            [cell.deleteButton setHidden:NO];
            [self.firstCam setEnabled:NO];

            [cell.itemImageView setImage:self.imagesArray[indexPath.row]];
//            [cell.itemImageView setFile:self.filesArray[0]];
//            [cell.itemImageView loadInBackground];

        }
        
    }

    else if (indexPath.row == 1) {
        
        //check photos total to display correct stuff
        if (self.imagesArray.count < 1) {
            [cell.deleteButton setHidden:YES];
            [self.secondCam setEnabled:NO];
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.imagesArray.count == 1) {
            [cell.deleteButton setHidden:YES];
            [self.secondCam setEnabled:YES];
            [cell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else if (self.imagesArray.count > 1) {
            [cell.deleteButton setHidden:NO];
            [self.secondCam setEnabled:NO];
            
            [cell.itemImageView setImage:self.imagesArray[indexPath.row]];

//            [cell.itemImageView setFile:self.filesArray[1]];
//            [cell.itemImageView loadInBackground];
        }
        
    }
    else if (indexPath.row == 2) {
        
        //check photos total to display correct stuff
        if (self.imagesArray.count < 2) {
            [cell.deleteButton setHidden:YES];
            [self.thirdCam setEnabled:NO];
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.imagesArray.count == 2) {
            [cell.deleteButton setHidden:YES];
            [self.thirdCam setEnabled:YES];
            [cell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else if (self.imagesArray.count > 2) {
            [cell.deleteButton setHidden:NO];
            [self.thirdCam setEnabled:NO];
            
            [cell.itemImageView setImage:self.imagesArray[indexPath.row]];

//            [cell.itemImageView setFile:self.filesArray[2]];
//            [cell.itemImageView loadInBackground];
        }
        
    }
    else if (indexPath.row == 3) {
        
        //check photos total to display correct stuff
        if (self.imagesArray.count < 3) {
            [cell.deleteButton setHidden:YES];
            [self.fourthCam setEnabled:NO];
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.imagesArray.count == 3) {
            [cell.deleteButton setHidden:YES];
            [self.fourthCam setEnabled:YES];
            [cell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else if (self.imagesArray.count > 3) {
            [cell.deleteButton setHidden:NO];
            [self.fourthCam setEnabled:NO];
            
            [cell.itemImageView setImage:self.imagesArray[indexPath.row]];

//            [cell.itemImageView setFile:self.filesArray[3]];
//            [cell.itemImageView loadInBackground];
        }
    }
    else if (indexPath.row == 4) {
        
        //check photos total to display correct stuff
        if (self.imagesArray.count < 4) {
            [cell.deleteButton setHidden:YES];
            [self.fifthCam setEnabled:NO];
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.imagesArray.count == 4) {
            [cell.deleteButton setHidden:YES];
            [self.fifthCam setEnabled:YES];
            [cell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else if (self.imagesArray.count > 4) {
            [cell.deleteButton setHidden:NO];
            [self.fifthCam setEnabled:NO];
            
            [cell.itemImageView setImage:self.imagesArray[indexPath.row]];

//            [cell.itemImageView setFile:self.filesArray[4]];
//            [cell.itemImageView loadInBackground];
        }
    }
    else if (indexPath.row == 5) {
        
        //check photos total to display correct stuff
        if (self.imagesArray.count < 5) {
            [cell.deleteButton setHidden:YES];
            [self.sixthCam setEnabled:NO];
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.imagesArray.count == 5) {
            [cell.deleteButton setHidden:YES];
            [self.sixthCam setEnabled:YES];
            [cell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else if (self.imagesArray.count > 5) {
            [cell.deleteButton setHidden:NO];
            [self.sixthCam setEnabled:NO];
            
            [cell.itemImageView setImage:self.imagesArray[indexPath.row]];

//            [cell.itemImageView setFile:self.filesArray[5]];
//            [cell.itemImageView loadInBackground];
        }

    }
    else if (indexPath.row == 6) {
        
        //check photos total to display correct stuff
        if (self.imagesArray.count < 6) {
            [cell.deleteButton setHidden:YES];
            [self.sevenCam setEnabled:NO];
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.imagesArray.count == 6) {
            [cell.deleteButton setHidden:YES];
            [self.sevenCam setEnabled:YES];
            [cell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else if (self.imagesArray.count > 6) {
            [cell.deleteButton setHidden:NO];
            [self.sevenCam setEnabled:NO];
            
            [cell.itemImageView setImage:self.imagesArray[indexPath.row]];
        }
        
    }
    else if (indexPath.row == 7) {
        
        //check photos total to display correct stuff
        if (self.imagesArray.count < 7) {
            [cell.deleteButton setHidden:YES];
            [self.eightCam setEnabled:NO];
            [cell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
        }
        else if (self.imagesArray.count == 7) {
            [cell.deleteButton setHidden:YES];
            [self.eightCam setEnabled:YES];
            [cell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
        }
        else if (self.imagesArray.count > 7) {
            [cell.deleteButton setHidden:NO];
            [self.eightCam setEnabled:NO];

            [cell.itemImageView setImage:self.imagesArray[indexPath.row]];
        }
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
//    NSLog(@"SELECTED %ld", (long)indexPath.row);
    
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
    else if (indexPath.row == 4) {
        [self fifthCamPressed:self];
    }
    else if (indexPath.row == 5) {
        [self sixthCamPressed:self];
    }
    else if (indexPath.row == 6) {
        [self seventhCamPressed];
    }
    else if (indexPath.row == 7) {
        [self eightCamPressed];
    }
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (self.imagesArray.count < 8) {
        return self.imagesArray.count + 1;
    }
    else{
        return self.imagesArray.count;
    }
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
    
    PFFile *imageFile = [placeholder objectAtIndex:fromIndexPath.item];
    [placeholder removeObjectAtIndex:fromIndexPath.item];
    [placeholder insertObject:imageFile atIndex:toIndexPath.item];
    
    self.filesArray = placeholder;
    
    NSMutableArray *imagePlaceholder = [NSMutableArray arrayWithArray:self.imagesArray];
    
    UIImage *image = [imagePlaceholder objectAtIndex:fromIndexPath.item];
    [imagePlaceholder removeObjectAtIndex:fromIndexPath.item];
    [imagePlaceholder insertObject:image atIndex:toIndexPath.item];
    
    self.imagesArray = imagePlaceholder;
    
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
    
    int index = (int) indexPath.row;
    
    if (index < self.imagesArray.count && index < self.filesArray.count) {
        [self generalDeletePressedOnCell:index];
    }
    else{
        [Answers logCustomEventWithName:@"Delete Index Error in Create Sale Listing"
                       customAttributes:@{}];
        
        //index is too high, reload the CV to try again
        [self animateCVReload];

    }
}

-(void)generalDeletePressedOnCell:(int)index{
    //update CV array
    [self.imagesArray removeObjectAtIndex:index];
    [self.filesArray removeObjectAtIndex:index];
    self.photostotal--;
    
    if (self.photostotal == 0) {
        self.calledImgAnalyzer = NO;
    }
    
    if (self.photostotal >= 2) {
        self.imgFooterLabel.text = @"Pro tip: Hold down on images to rearrange";
        [self.imgFooterView setNeedsDisplay];
    }
    else{
        if ([self.chooseCategroy.text isEqualToString:@"Proxy"]) {
            self.imgFooterLabel.text = @"Photos: Max 8";
        }
        else{
            self.imgFooterLabel.text = @"Photos: Min 2 | Max 8";
        }
        [self.imgFooterView setNeedsDisplay];
    }
    
    //animate reload
    [self animateCVReload];
}

-(void)animateCVReload{
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.imgCollectionView.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [self.imgCollectionView reloadData];
                         [UIView animateWithDuration:0.3
                                               delay:0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              self.imgCollectionView.alpha = 1.0;
                                          }
                                          completion:^(BOOL finished) {
                                              self.imgCollectionView.alpha = 1.0;
                                          }];
                     }];
}

-(void)firstDeletePressedOnCell:(AddImageCell *)cell{
    
    NSIndexPath *indexPath = [self.imgCollectionView indexPathForCell:cell];
    
    NSIndexPath *secondIndexPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:0];
    AddImageCell *secondCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:secondIndexPath];
    
    NSIndexPath *thirdIndexPath = [NSIndexPath indexPathForRow:indexPath.row+2 inSection:0];
    AddImageCell *thirdCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:thirdIndexPath];
    
    NSIndexPath *fourthIndexPath = [NSIndexPath indexPathForRow:indexPath.row+3 inSection:0];
    AddImageCell *fourthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fourthIndexPath];
    
//    NSIndexPath *fifthIndexPath = [NSIndexPath indexPathForRow:4 inSection:0];
//    AddImageCell *fifthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fifthIndexPath];
//    
//    NSIndexPath *sixthIndexPath = [NSIndexPath indexPathForRow:5 inSection:0];
//    AddImageCell *sixthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:sixthIndexPath];
    
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
        
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:NO];
//                        }];
        
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
//    else if (self.photostotal ==5){
//        self.photostotal--;
//        
//        [UIView transitionWithView:cell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [cell.itemImageView setImage:secondCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.firstCam setEnabled:NO];
//                        }];
//        
//        [UIView transitionWithView:secondCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [secondCell.itemImageView setImage:thirdCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.secondCam setEnabled:NO];
//                        }];
//        
//        [UIView transitionWithView:thirdCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [thirdCell.itemImageView setImage:fourthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.thirdCam setEnabled:NO];
//                        }];
//        
//        [UIView transitionWithView:fourthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fourthCell.itemImageView setImage:fifthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.fourthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:YES];
//                        }];
//        [UIView transitionWithView:sixthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [sixthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
//                        } completion:^(BOOL finished) {
//                            [self.sixthCam setEnabled:NO];
//                        }];
//        
//        [UIView animateWithDuration:0.3
//                              delay:0
//                            options:UIViewAnimationOptionCurveEaseIn
//                         animations:^{
//                             [fifthCell.deleteButton setAlpha:0.0f];
//                         }
//                         completion:^(BOOL finished) {
//                             NSLog(@"finished animating deleteb");
//                             [fifthCell.deleteButton setHidden:YES];
//                             [fifthCell.deleteButton setAlpha:1.0f];
//                         }];
//    }
//    else if (self.photostotal ==6){
//        self.photostotal--;
//        
//        [UIView transitionWithView:cell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [cell.itemImageView setFile:self.filesArray[1]];
//                            [cell.itemImageView loadInBackground];
//                        } completion:^(BOOL finished) {
//                            [self.firstCam setEnabled:NO];
//                        }];
//        
//        [UIView transitionWithView:secondCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [secondCell.itemImageView setFile:self.filesArray[2]];
//                            [secondCell.itemImageView loadInBackground];
//                        } completion:^(BOOL finished) {
//                            [self.secondCam setEnabled:NO];
//                        }];
//        
//        [UIView transitionWithView:thirdCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [thirdCell.itemImageView setFile:self.filesArray[3]];
//                            [thirdCell.itemImageView loadInBackground];
//
//                        } completion:^(BOOL finished) {
//                            [self.thirdCam setEnabled:NO];
//                        }];
//        
//        [UIView transitionWithView:fourthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fourthCell.itemImageView setFile:self.filesArray[4]];
//                            [fourthCell.itemImageView loadInBackground];
//
//                        } completion:^(BOOL finished) {
//                            [self.fourthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setFile:self.filesArray[5]];
//                            [fifthCell.itemImageView loadInBackground];
//
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:sixthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [sixthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
//                        } completion:^(BOOL finished) {
//                            [self.sixthCam setEnabled:YES];
//                        }];
//        
//        [UIView animateWithDuration:0.3
//                              delay:0
//                            options:UIViewAnimationOptionCurveEaseIn
//                         animations:^{
//                             [sixthCell.deleteButton setAlpha:0.0f];
//                         }
//                         completion:^(BOOL finished) {
//                             NSLog(@"finished animating deleteb");
//                             [sixthCell.deleteButton setHidden:YES];
//                             [sixthCell.deleteButton setAlpha:1.0f];
//                         }];
//    }
}

-(void)secondDeletePressedOnCell:(AddImageCell *)cell{
    
    NSIndexPath *secondIndexPath = [self.imgCollectionView indexPathForCell:cell];
    AddImageCell *secondCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:secondIndexPath];
    
    NSIndexPath *thirdIndexPath = [NSIndexPath indexPathForRow:secondIndexPath.row+1 inSection:0];
    AddImageCell *thirdCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:thirdIndexPath];
    
    NSIndexPath *fourthIndexPath = [NSIndexPath indexPathForRow:secondIndexPath.row+2 inSection:0];
    AddImageCell *fourthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fourthIndexPath];
//    
//    NSIndexPath *fifthIndexPath = [NSIndexPath indexPathForRow:4 inSection:0];
//    AddImageCell *fifthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fifthIndexPath];
//    
//    NSIndexPath *sixthIndexPath = [NSIndexPath indexPathForRow:5 inSection:0];
//    AddImageCell *sixthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:sixthIndexPath];
    
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
        
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:NO];
//                        }];
        
        
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
//    else if (self.photostotal ==5){
//        self.photostotal--;
//        
//        [UIView transitionWithView:secondCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [secondCell.itemImageView setImage:thirdCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.secondCam setEnabled:NO];
//                        }];
//        
//        [UIView transitionWithView:thirdCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [thirdCell.itemImageView setImage:fourthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.thirdCam setEnabled:NO];
//                        }];
//        
//        [UIView transitionWithView:fourthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fourthCell.itemImageView setImage:fifthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.fourthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:YES];
//                        }];
//        [UIView transitionWithView:sixthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [sixthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
//                        } completion:^(BOOL finished) {
//                            [self.sixthCam setEnabled:NO];
//                        }];
//        
//        [UIView animateWithDuration:0.3
//                              delay:0
//                            options:UIViewAnimationOptionCurveEaseIn
//                         animations:^{
//                             [fifthCell.deleteButton setAlpha:0.0f];
//                         }
//                         completion:^(BOOL finished) {
//                             NSLog(@"finished animating deleteb");
//                             [fifthCell.deleteButton setHidden:YES];
//                             [fifthCell.deleteButton setAlpha:1.0f];
//                         }];
//    }
//    else if (self.photostotal ==6){
//        self.photostotal--;
//        
//        [UIView transitionWithView:secondCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [secondCell.itemImageView setImage:thirdCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.secondCam setEnabled:NO];
//                        }];
//        
//        [UIView transitionWithView:thirdCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [thirdCell.itemImageView setImage:fourthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.thirdCam setEnabled:NO];
//                        }];
//        
//        [UIView transitionWithView:fourthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fourthCell.itemImageView setImage:fifthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.fourthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setImage:sixthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:sixthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [sixthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
//                        } completion:^(BOOL finished) {
//                            [self.sixthCam setEnabled:YES];
//                        }];
//        
//        [UIView animateWithDuration:0.3
//                              delay:0
//                            options:UIViewAnimationOptionCurveEaseIn
//                         animations:^{
//                             [sixthCell.deleteButton setAlpha:0.0f];
//                         }
//                         completion:^(BOOL finished) {
//                             NSLog(@"finished animating deleteb");
//                             [sixthCell.deleteButton setHidden:YES];
//                             [sixthCell.deleteButton setAlpha:1.0f];
//                         }];
//    }
}

-(void)thirdDeletePressedOnCell:(AddImageCell *)cell{
    
    NSIndexPath *thirdIndexPath = [self.imgCollectionView indexPathForCell:cell];
    AddImageCell *thirdCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:thirdIndexPath];
    
    NSIndexPath *fourthIndexPath = [NSIndexPath indexPathForRow:thirdIndexPath.row+1 inSection:0];
    AddImageCell *fourthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fourthIndexPath];
    
//    NSIndexPath *fifthIndexPath = [NSIndexPath indexPathForRow:4 inSection:0];
//    AddImageCell *fifthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fifthIndexPath];
//    
//    NSIndexPath *sixthIndexPath = [NSIndexPath indexPathForRow:5 inSection:0];
//    AddImageCell *sixthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:sixthIndexPath];
    
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
        
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:NO];
//                        }];
        
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
//    else if (self.photostotal ==5){
//        self.photostotal--;
//        
//        [UIView transitionWithView:thirdCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [thirdCell.itemImageView setImage:fourthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.thirdCam setEnabled:NO];
//                        }];
//        
//        [UIView transitionWithView:fourthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fourthCell.itemImageView setImage:fifthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.fourthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:YES];
//                        }];
//        [UIView transitionWithView:sixthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [sixthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
//                        } completion:^(BOOL finished) {
//                            [self.sixthCam setEnabled:NO];
//                        }];
//        
//        [UIView animateWithDuration:0.3
//                              delay:0
//                            options:UIViewAnimationOptionCurveEaseIn
//                         animations:^{
//                             [fifthCell.deleteButton setAlpha:0.0f];
//                         }
//                         completion:^(BOOL finished) {
//                             NSLog(@"finished animating deleteb");
//                             [fifthCell.deleteButton setHidden:YES];
//                             [fifthCell.deleteButton setAlpha:1.0f];
//                         }];
//    }
//    else if (self.photostotal ==6){
//        self.photostotal--;
//        
//        [UIView transitionWithView:thirdCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [thirdCell.itemImageView setImage:fourthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.thirdCam setEnabled:NO];
//                        }];
//        
//        [UIView transitionWithView:fourthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fourthCell.itemImageView setImage:fifthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.fourthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setImage:sixthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:sixthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [sixthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
//                        } completion:^(BOOL finished) {
//                            [self.sixthCam setEnabled:YES];
//                        }];
//        
//        [UIView animateWithDuration:0.3
//                              delay:0
//                            options:UIViewAnimationOptionCurveEaseIn
//                         animations:^{
//                             [sixthCell.deleteButton setAlpha:0.0f];
//                         }
//                         completion:^(BOOL finished) {
//                             NSLog(@"finished animating deleteb");
//                             [sixthCell.deleteButton setHidden:YES];
//                             [sixthCell.deleteButton setAlpha:1.0f];
//                         }];
//    }
}

-(void)fourthDeletePressedOnCell:(AddImageCell *)cell{
    
    NSIndexPath *fourthIndexPath = [self.imgCollectionView indexPathForCell:cell];
    AddImageCell *fourthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fourthIndexPath];
    
    NSIndexPath *thirdIndexPath = [NSIndexPath indexPathForRow:fourthIndexPath.row-1 inSection:0];
    AddImageCell *thirdCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:thirdIndexPath];
    
//    NSIndexPath *fifthIndexPath = [NSIndexPath indexPathForRow:4 inSection:0];
//    AddImageCell *fifthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fifthIndexPath];
//    
//    NSIndexPath *sixthIndexPath = [NSIndexPath indexPathForRow:5 inSection:0];
//    AddImageCell *sixthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:sixthIndexPath];
    
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
        
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:NO];
//                        }];
        
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
//    else if (self.photostotal ==5){
//        self.photostotal--;
//        
//        [UIView transitionWithView:fourthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fourthCell.itemImageView setImage:fifthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.fourthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:YES];
//                        }];
//        [UIView transitionWithView:sixthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [sixthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
//                        } completion:^(BOOL finished) {
//                            [self.sixthCam setEnabled:NO];
//                        }];
//        
//        [UIView animateWithDuration:0.3
//                              delay:0
//                            options:UIViewAnimationOptionCurveEaseIn
//                         animations:^{
//                             [fifthCell.deleteButton setAlpha:0.0f];
//                         }
//                         completion:^(BOOL finished) {
//                             NSLog(@"finished animating deleteb");
//                             [fifthCell.deleteButton setHidden:YES];
//                             [fifthCell.deleteButton setAlpha:1.0f];
//                         }];
//    }
//    else if (self.photostotal ==6){
//        self.photostotal--;
//        
//        [UIView transitionWithView:fourthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fourthCell.itemImageView setImage:fifthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.fourthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setImage:sixthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:sixthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [sixthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
//                        } completion:^(BOOL finished) {
//                            [self.sixthCam setEnabled:YES];
//                        }];
//        
//        [UIView animateWithDuration:0.3
//                              delay:0
//                            options:UIViewAnimationOptionCurveEaseIn
//                         animations:^{
//                             [sixthCell.deleteButton setAlpha:0.0f];
//                         }
//                         completion:^(BOOL finished) {
//                             NSLog(@"finished animating deleteb");
//                             [sixthCell.deleteButton setHidden:YES];
//                             [sixthCell.deleteButton setAlpha:1.0f];
//                         }];
//    }
}
//
//-(void)fifthDeletePressedOnCell:(AddImageCell *)cell{
//    
//    NSIndexPath *fourthIndexPath = [self.imgCollectionView indexPathForCell:cell];
//    AddImageCell *fourthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fourthIndexPath];
//    
////    NSIndexPath *fifthIndexPath = [NSIndexPath indexPathForRow:4 inSection:0];
////    AddImageCell *fifthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fifthIndexPath];
////    
////    NSIndexPath *sixthIndexPath = [NSIndexPath indexPathForRow:5 inSection:0];
////    AddImageCell *sixthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:sixthIndexPath];
//    
//    //update CV array
//    [self.filesArray removeObjectAtIndex:4];
//    
//    if (self.photostotal ==5){
//        self.photostotal--;
//        
//        [UIView transitionWithView:fourthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fourthCell.itemImageView setImage:fifthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.fourthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:YES];
//                        }];
//        [UIView transitionWithView:sixthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [sixthCell.itemImageView setImage:[UIImage imageNamed:@"camHolder"]];
//                        } completion:^(BOOL finished) {
//                            [self.sixthCam setEnabled:NO];
//                        }];
//        
//        [UIView animateWithDuration:0.3
//                              delay:0
//                            options:UIViewAnimationOptionCurveEaseIn
//                         animations:^{
//                             [fifthCell.deleteButton setAlpha:0.0f];
//                         }
//                         completion:^(BOOL finished) {
//                             NSLog(@"finished animating deleteb");
//                             [fifthCell.deleteButton setHidden:YES];
//                             [fifthCell.deleteButton setAlpha:1.0f];
//                         }];
//    }
//    else if (self.photostotal ==6){
//        self.photostotal--;
//        
//        [UIView transitionWithView:fourthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fourthCell.itemImageView setImage:fifthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.fourthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setImage:sixthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:sixthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [sixthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
//                        } completion:^(BOOL finished) {
//                            [self.sixthCam setEnabled:YES];
//                        }];
//        
//        
//        [UIView animateWithDuration:0.3
//                              delay:0
//                            options:UIViewAnimationOptionCurveEaseIn
//                         animations:^{
//                             [sixthCell.deleteButton setAlpha:0.0f];
//                         }
//                         completion:^(BOOL finished) {
//                             NSLog(@"finished animating deleteb");
//                             [sixthCell.deleteButton setHidden:YES];
//                             [sixthCell.deleteButton setAlpha:1.0f];
//                         }];
//    }
//}
//
//-(void)sixthDeletePressedOnCell:(AddImageCell *)cell{
//    
//    NSIndexPath *fifthIndexPath = [NSIndexPath indexPathForRow:4 inSection:0];
//    AddImageCell *fifthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:fifthIndexPath];
//    
//    NSIndexPath *sixthIndexPath = [NSIndexPath indexPathForRow:5 inSection:0];
//    AddImageCell *sixthCell = (AddImageCell *)[self.imgCollectionView cellForItemAtIndexPath:sixthIndexPath];
//    
//    //update CV array
//    [self.filesArray removeObjectAtIndex:5];
//    
//    if (self.photostotal ==6){
//        self.photostotal--;
//
//        [UIView transitionWithView:fifthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [fifthCell.itemImageView setImage:sixthCell.itemImageView.image];
//                        } completion:^(BOOL finished) {
//                            [self.fifthCam setEnabled:NO];
//                        }];
//        [UIView transitionWithView:sixthCell.itemImageView
//                          duration:0.3f
//                           options:UIViewAnimationOptionTransitionCrossDissolve
//                        animations:^{
//                            [sixthCell.itemImageView setImage:[UIImage imageNamed:@"addImage"]];
//                        } completion:^(BOOL finished) {
//                            [self.sixthCam setEnabled:YES];
//                        }];
//        
//        [UIView animateWithDuration:0.3
//                              delay:0
//                            options:UIViewAnimationOptionCurveEaseIn
//                         animations:^{
//                             [sixthCell.deleteButton setAlpha:0.0f];
//                         }
//                         completion:^(BOOL finished) {
//                             NSLog(@"finished animating deleteb");
//                             [sixthCell.deleteButton setHidden:YES];
//                             [sixthCell.deleteButton setAlpha:1.0f];
//                         }];
//    }
//}

-(void)dismissColour{
    if (self.colourSwipeView.alpha == 1.0) {
        if ([self.chosenColourSArray containsObject:@"White"]) {
            if (self.chosenColourSArray.count < 2) {
                //got 1 colour
                [self setWhiteImageBorder:self.chosenColourImageView];
                [self setImageBorder:self.secondChosenColourImageView];
            }
            else{
                //got 2 colours
                if ([self.chosenColourSArray[0] isEqualToString:@"White"]) {
                    [self setWhiteImageBorder:self.secondChosenColourImageView];
                    [self setImageBorder:self.chosenColourImageView];
                }
                else{
                    [self setWhiteImageBorder:self.chosenColourImageView];
                    [self setImageBorder:self.secondChosenColourImageView];
                }
            }
        }
        else{
            [self setImageBorder:self.chosenColourImageView];
            [self setImageBorder:self.secondChosenColourImageView];
        }
        
        //swipe view showing so hide and show buttons, etc.
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.colourSwipeView.alpha = 0.0;
                             self.dismissColourButton.alpha = 0.0;
                             
                             self.colourLabel.alpha = 1.0;
                             self.chooseColourLabel.alpha = 0.0;
                             
                             if (self.chosenColourSArray.count == 0) {
                                 self.colourLabel.alpha = 1.0;
                                 self.chooseColourLabel.alpha = 1.0;
                                 self.chosenColourImageView.alpha = 0.0;
                             }
                             else if (self.chosenColourSArray.count == 1){
                                 
                                 self.chosenColourImageView.alpha = 1.0;
                                 self.secondChosenColourImageView.alpha = 0.0;
                                 
                                 if ([self.chosenColourSArray containsObject:@"Camo"] ) {
                                     [self.chosenColourImageView setImage:[UIImage imageNamed:@"camoColour"]];
                                 }
                                 else{
                                     self.chosenColourImageView.image = nil;
                                     [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[0]]]];
                                 }
                             }
                             else if (self.chosenColourSArray.count == 2){
                                 self.chosenColourImageView.alpha = 1.0;
                                 self.secondChosenColourImageView.alpha = 1.0;
                                 
                                 if ([self.chosenColourSArray containsObject:@"Camo"] ) {
                                     
                                     if ([self.chosenColourSArray[0] isEqualToString:@"Camo"]) {
                                         [self.secondChosenColourImageView setImage:[UIImage imageNamed:@"camoColour"]];
                                         self.chosenColourImageView.image = nil;
                                         [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[1]]]];
                                     }
                                     else{
                                         [self.chosenColourImageView setImage:[UIImage imageNamed:@"camoColour"]];
                                         self.secondChosenColourImageView.image = nil;
                                         [self.secondChosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[0]]]];
                                     }
                                 }
                                 else{
                                     self.chosenColourImageView.image = nil;
                                     [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[1]]]];
                                     
                                     self.secondChosenColourImageView.image = nil;
                                     [self.secondChosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[0]]]];
                                 }
                             }
                         }
                         completion:^(BOOL finished) {
                             
                         }];
    }
}
- (IBAction)addColourPressed:(id)sender {
    if (self.colourSwipeView.alpha == 0.0) {
        //button showing so hide main label, imageview and choice label, and show swipe view
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.colourSwipeView.alpha = 1.0;
                             self.dismissColourButton.alpha = 1.0;

                             self.chooseColourLabel.alpha = 0.0;
                             self.colourLabel.alpha = 0.0;
                             
                             self.chosenColourImageView.alpha = 0.0;
                             self.secondChosenColourImageView.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             
                         }];
    }
    else{
        if ([self.chosenColourSArray containsObject:@"White"]) {
            if (self.chosenColourSArray.count < 2) {
                //got 1 colour
                [self setWhiteImageBorder:self.chosenColourImageView];
                [self setImageBorder:self.secondChosenColourImageView];
            }
            else{
                //got 2 colours
                if ([self.chosenColourSArray[0] isEqualToString:@"White"]) {
                    [self setWhiteImageBorder:self.secondChosenColourImageView];
                    [self setImageBorder:self.chosenColourImageView];
                }
                else{
                    [self setWhiteImageBorder:self.chosenColourImageView];
                    [self setImageBorder:self.secondChosenColourImageView];
                }
            }
        }
        else{
            [self setImageBorder:self.chosenColourImageView];
            [self setImageBorder:self.secondChosenColourImageView];
        }
        
        //swipe view showing so hide and show buttons, etc.
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.colourSwipeView.alpha = 0.0;
                             self.dismissColourButton.alpha = 0.0;

                             self.colourLabel.alpha = 1.0;
                             self.chooseColourLabel.alpha = 0.0;
                             
                             if (self.chosenColourSArray.count == 0) {
                                 self.colourLabel.alpha = 1.0;
                                 self.chooseColourLabel.alpha = 1.0;
                                 self.chosenColourImageView.alpha = 0.0;
                             }
                             else if (self.chosenColourSArray.count == 1){
                                 
                                 self.chosenColourImageView.alpha = 1.0;
                                 self.secondChosenColourImageView.alpha = 0.0;

                                 if ([self.chosenColourSArray containsObject:@"Camo"] ) {
                                     [self.chosenColourImageView setImage:[UIImage imageNamed:@"camoColour"]];
                                 }
                                 else{
                                     self.chosenColourImageView.image = nil;
                                     [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[0]]]];
                                 }
                             }
                             else if (self.chosenColourSArray.count == 2){
                                 self.chosenColourImageView.alpha = 1.0;
                                 self.secondChosenColourImageView.alpha = 1.0;
                                 
                                 if ([self.chosenColourSArray containsObject:@"Camo"] ) {
                                     
                                     if ([self.chosenColourSArray[0] isEqualToString:@"Camo"]) {
                                         [self.secondChosenColourImageView setImage:[UIImage imageNamed:@"camoColour"]];
                                         self.chosenColourImageView.image = nil;
                                         [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[1]]]];
                                     }
                                     else{
                                         [self.chosenColourImageView setImage:[UIImage imageNamed:@"camoColour"]];
                                         self.secondChosenColourImageView.image = nil;
                                         [self.secondChosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[0]]]];
                                     }
                                 }
                                 else{
                                     self.chosenColourImageView.image = nil;
                                     [self.chosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[1]]]];
                                     
                                     self.secondChosenColourImageView.image = nil;
                                     [self.secondChosenColourImageView setBackgroundColor:[self.colourValuesArray objectAtIndex:[self.coloursArray indexOfObject:self.chosenColourSArray[0]]]];
                                 }
                             }
                         }
                         completion:^(BOOL finished) {
                             
                         }];
    }
}

#pragma mark - swipe view delegates

-(UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view{
    
    UIView *innerView = nil;
    UIImageView *imageView = nil;
    
    if (view == nil)
    {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30,30)];
        view.backgroundColor = [UIColor whiteColor];
        
        innerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 25,25)];
        imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0,0, 20, 20)];
        
        imageView.center = innerView.center;
        
        [innerView addSubview:imageView];
        [view addSubview:innerView];
        
        innerView.center = view.center;

        
        [self setImageBorder:imageView];
    }
    else
    {
        innerView = [[view subviews] lastObject];
        imageView =  [[innerView subviews] lastObject];
    }
    
    //reset
    imageView.image = nil;
    
    NSString *colour = [self.coloursArray objectAtIndex:index];
    
    if ([colour isEqualToString:@"White"]){
        [self setWhiteImageBorder:imageView];
        imageView.backgroundColor = [self.colourValuesArray objectAtIndex:index];
    }
    else if ([colour isEqualToString:@"Camo"]){
        [self setImageBorder:imageView];
        [imageView setImage:[UIImage imageNamed:@"camoColour"]];
    }
    else{
        [self setImageBorder:imageView];
        imageView.backgroundColor = [self.colourValuesArray objectAtIndex:index];
    }
    
    if ([self.chosenColourSArray containsObject:colour]) {
        if ([colour isEqualToString:@"White"]){
            [self setSelectedBorder:innerView withColor:[UIColor lightGrayColor]];
        }
        else{
            [self setSelectedBorder:innerView withColor:[self.colourValuesArray objectAtIndex:index]];
        }
    }
    else{
        [self setNormalBorder:innerView];
    }
    
    return view;
}

-(void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index{

    //get the colour
    NSString *colour = [self.coloursArray objectAtIndex:index];
    
    if ([self.chosenColourSArray containsObject:colour]) {
        
        //deselect this one
        [self.chosenColourSArray removeObject:colour];
        
        //put normal border on selected colour
        UIView *mainView = [self.colourSwipeView itemViewAtIndex:index];
        UIView *innerView = [[mainView subviews] lastObject];
        [self setNormalBorder:innerView];
    }
    else{
        //limit to 2 selected at once
        if (self.chosenColourSArray.count == 2) {
            //shake colour swipe view
            CABasicAnimation *animation =
            [CABasicAnimation animationWithKeyPath:@"position"];
            [animation setDuration:0.05];
            [animation setRepeatCount:3];
            [animation setAutoreverses:YES];
            [animation setFromValue:[NSValue valueWithCGPoint:
                                     CGPointMake([self.colourSwipeView center].x - 10.0f, [self.colourSwipeView center].y)]];
            [animation setToValue:[NSValue valueWithCGPoint:
                                   CGPointMake([self.colourSwipeView center].x + 10.0f, [self.colourSwipeView center].y)]];
            [[self.colourSwipeView layer] addAnimation:animation forKey:@"position"];
            
            NSLog(@"dismiss colour alpha %f", self.dismissColourButton.alpha);
            //animate dismiss button text change
            [UIView transitionWithView:self.dismissColourButton duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                
                [self.dismissColourButton setTitle:@"Max 2 colours!" forState:UIControlStateNormal];
                
            } completion:^(BOOL finished) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [UIView transitionWithView:self.dismissColourButton duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                        [self.dismissColourButton setTitle:@"Dismiss" forState:UIControlStateNormal];
                    } completion:nil];
                });
            }];
            
            return;
        }
        
        //select new chosen colour
        [self.chosenColourSArray addObject:colour];
        
        if (self.chosenColourSArray.count == 2) {
            [self addColourPressed:self];
        }
        
        //put border on selected colour
        UIView *mainView = [self.colourSwipeView itemViewAtIndex:index];
        UIView *innerView = [[mainView subviews] lastObject];
        
        NSString *itemColour = [self.coloursArray objectAtIndex:index];
        
        if ([self.chosenColourSArray containsObject:itemColour]) {
            //selected
            if ([colour isEqualToString:@"White"]){
                [self setSelectedBorder:innerView withColor:[UIColor lightGrayColor]];
            }
            else{
                [self setSelectedBorder:innerView withColor:[self.colourValuesArray objectAtIndex:index]];
            }
        }
        else{
            [self setNormalBorder:innerView];
        }
    }
}

-(NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView{
    
    return self.coloursArray.count;
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = 10;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [imageView.layer setBorderWidth: 0.0];
}
-(void)setSelectedBorder:(UIView *)view withColor:(UIColor *)color{
    view.layer.cornerRadius = 12.5;
    view.layer.masksToBounds = YES;
    view.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    view.contentMode = UIViewContentModeScaleAspectFill;
    [view.layer setBorderColor: [color CGColor]];
    [view.layer setBorderWidth: 1.0];
}
-(void)setNormalBorder:(UIView *)view{
    view.layer.cornerRadius = 12.5;
    view.layer.masksToBounds = YES;
    view.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    view.contentMode = UIViewContentModeScaleAspectFill;
    [view.layer setBorderWidth: 0.0];
}

-(void)setWhiteImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = 10;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [imageView.layer setBorderColor: [[UIColor lightGrayColor] CGColor]];
    [imageView.layer setBorderWidth: 1.0];
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
        [finalKeywordArray addObject:@"trifergs"];
    }
    else if ([finalKeywordArray containsObject:@"tri-ferg"]) {
        [finalKeywordArray addObject:@"triferg"];
        [finalKeywordArray addObject:@"tri"];
        [finalKeywordArray addObject:@"ferg"];
        [finalKeywordArray addObject:@"trifergs"];
    }
    else if ([finalKeywordArray containsObject:@"tri"] && [finalKeywordArray containsObject:@"ferg"]) {
        [finalKeywordArray addObject:@"triferg"];
        [finalKeywordArray addObject:@"tri-ferg"];
        [finalKeywordArray addObject:@"trifergs"];
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
        [finalKeywordArray addObject:@"longsleeved"];
    }
    else if ([finalKeywordArray containsObject:@"long-sleeve"]) {
        [finalKeywordArray addObject:@"longsleeve"];
        [finalKeywordArray addObject:@"long"];
        [finalKeywordArray addObject:@"sleeve"];
        [finalKeywordArray addObject:@"l/s"];
        [finalKeywordArray addObject:@"ls"];
        [finalKeywordArray addObject:@"longsleeved"];
    }
    else if ([finalKeywordArray containsObject:@"ls"]) {
        [finalKeywordArray addObject:@"longsleeve"];
        [finalKeywordArray addObject:@"long"];
        [finalKeywordArray addObject:@"sleeve"];
        [finalKeywordArray addObject:@"l/s"];
        [finalKeywordArray addObject:@"long-sleeve"];
        [finalKeywordArray addObject:@"longsleeved"];
    }
    else if ([finalKeywordArray containsObject:@"l/s"]) {
        [finalKeywordArray addObject:@"longsleeve"];
        [finalKeywordArray addObject:@"long"];
        [finalKeywordArray addObject:@"sleeve"];
        [finalKeywordArray addObject:@"ls"];
        [finalKeywordArray addObject:@"long-sleeve"];
        [finalKeywordArray addObject:@"longsleeved"];
    }
    else if ([finalKeywordArray containsObject:@"longsleeved"]) {
        [finalKeywordArray addObject:@"longsleeve"];
        [finalKeywordArray addObject:@"long"];
        [finalKeywordArray addObject:@"sleeve"];
        [finalKeywordArray addObject:@"ls"];
        [finalKeywordArray addObject:@"long-sleeve"];
        [finalKeywordArray addObject:@"l/s"];
    }
    
    //blue/navy
    if ([finalKeywordArray containsObject:@"blue"]) {
        [finalKeywordArray addObject:@"navy"];
        [finalKeywordArray addObject:@"navey"];
    }
    else if ([finalKeywordArray containsObject:@"navy"]){
        [finalKeywordArray addObject:@"blue"];
        [finalKeywordArray addObject:@"navey"];
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
    
    //places+faces
    if ([finalKeywordArray containsObject:@"places"] && [finalKeywordArray containsObject:@"faces"]) {
        [finalKeywordArray addObject:@"+"];
        [finalKeywordArray addObject:@"p+f"];
        [finalKeywordArray addObject:@"placesplusface"];
        [finalKeywordArray addObject:@"place"];
        [finalKeywordArray addObject:@"face"];
        [finalKeywordArray addObject:@"plus"];
    }
    else if ([finalKeywordArray containsObject:@"p+f"]) {
        [finalKeywordArray addObject:@"+"];
        [finalKeywordArray addObject:@"places"];
        [finalKeywordArray addObject:@"faces"];
        [finalKeywordArray addObject:@"placesplusface"];
        [finalKeywordArray addObject:@"place"];
        [finalKeywordArray addObject:@"face"];
        [finalKeywordArray addObject:@"plus"];
    }
    
    
    //remove duplications
    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:finalKeywordArray];
    NSArray *arrayWithoutDuplicates = [orderedSet array];
    
    [finalKeywordArray removeAllObjects];
    [finalKeywordArray addObjectsFromArray:arrayWithoutDuplicates];
    
    return finalKeywordArray;
}

-(void)showVerifyAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Verify Email 📩" message:@"To keep Bump safe we authenticate users via Facebook or Email.\n\nTo list your item either tap the link in the verification email we sent you or connect your Facebook account\n\nDon't forget to check your Junk Folder" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        //dismiss VC
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

#pragma mark - colour part of label

-(NSMutableAttributedString *)modifyString: (NSMutableAttributedString *)mainString setColorForText:(NSString*) textToFind withColor:(UIColor*) color
{
    NSRange range = [mainString.mutableString rangeOfString:textToFind options:NSCaseInsensitiveSearch];
    
    if (range.location != NSNotFound) {
        [mainString addAttribute:NSForegroundColorAttributeName value:color range:range];
    }
    
    return mainString;
}

-(void)taggedPressed{
    [Answers logCustomEventWithName:@"Viewed Tagged Pic Tutorial"
                   customAttributes:@{}];
    
    ExplainView *vc = [[ExplainView alloc]init];
    vc.picAndTextMode = YES;
    vc.heroImage = [UIImage imageNamed:@"taggedEg"];
    
    vc.titleString = @"T A G G E D  P H O T O S";
    vc.mainLabelText = @"To prove to buyers that you own the photographed item, simply place something to identify yourself in the photo\n\nThis could be your Bump username written on a piece of paper, an ID card with your name on it or anything that identifies yourself as the person that took the photo";
    [self presentViewController:vc animated:YES completion:nil];
}
@end
