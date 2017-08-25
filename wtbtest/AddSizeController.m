//
//  AddSizeController.m
//  wtbtest
//
//  Created by Jack Ryder on 01/04/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "AddSizeController.h"
#import <Crashlytics/Crashlytics.h>

@interface AddSizeController ()

@end

@implementation AddSizeController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.templateSwipeView setHidden:YES];
    
    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.sneakerCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.clothingCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.emptyCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.shoeSizesArray = [NSArray arrayWithObjects:@"2", @"2.5", @"3", @"3.5", @"4", @"4.5", @"5", @"5.5", @"6", @"6.5", @"7", @"7.5", @"8", @"8.5", @"9", @"9.5", @"10", @"10.5", @"11",@"11.5", @"12", @"12.5", @"13", @"13.5",@"14", @"14.5", @"15", nil];
    
    self.UKShoeSizes = [NSArray arrayWithObjects:@"2", @"2.5", @"3", @"3.5", @"4", @"4.5", @"5", @"5.5", @"6", @"6.5", @"7", @"7.5", @"8", @"8.5", @"9", @"9.5", @"10", @"10.5", @"11",@"11.5", @"12", @"12.5", @"13", @"13.5",@"14", @"14.5", @"15", nil];
    
    self.USShoeSizes = [NSArray arrayWithObjects:@"2.5",@"3",@"3.5",@"4", @"4.5", @"5", @"5.5", @"6", @"6.5", @"7", @"7.5", @"8", @"8.5", @"9", @"9.5", @"10", @"10.5", @"11",@"11.5", @"12", @"12.5", @"13", @"13.5",@"14", @"14.5",@"15", @"15.5", nil];
    
    self.EUShoeSizes = [NSArray arrayWithObjects:@"35", @"35-36", @"36", @"36-37", @"37", @"37-38", @"38", @"38-39", @"39", @"39-40", @"40", @"40-41", @"41", @"41-42",@"42", @"42-43", @"43", @"43-44", @"44",@"44-45", @"45",@"45-46", @"46",@"46-47",@"47", @"47-48", @"48", nil];
    
    self.clothingSizesArray = [NSArray arrayWithObjects:@"",@"XXS", @"XS", @"S", @"M", @"L", @"XL", @"XXL", @"",nil];
    
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    self.mainLabel.minimumScaleFactor=0.5;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    //setup swipe views
    self.sneakerSwipeView.delegate = self;
    self.sneakerSwipeView.dataSource = self;
    self.sneakerSwipeView.clipsToBounds = YES;
    self.sneakerSwipeView.pagingEnabled = YES;
    self.sneakerSwipeView.truncateFinalPage = YES;
    [self.sneakerSwipeView setBackgroundColor:[UIColor whiteColor]];
    self.sneakerSwipeView.alignment = SwipeViewAlignmentCenter;
    [self.sneakerSwipeView reloadData];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iPhone SE
        self.clothingSwipeView = [[SwipeView alloc]initWithFrame:CGRectMake(0, self.templateSwipeView.frame.origin.y, self.templateSwipeView.frame.size.width,  self.templateSwipeView.frame.size.height)];
    }
    else if([ [ UIScreen mainScreen ] bounds ].size.height == 736){
        //iPhone 6/7 Plus
        
        self.clothingSwipeView = [[SwipeView alloc]initWithFrame:CGRectMake(48, self.templateSwipeView.frame.origin.y, self.templateSwipeView.frame.size.width,  self.templateSwipeView.frame.size.height)];
    }
    else{
        //iPhone 6/7
        self.clothingSwipeView = [[SwipeView alloc]initWithFrame:CGRectMake(27, self.templateSwipeView.frame.origin.y, self.templateSwipeView.frame.size.width,  self.templateSwipeView.frame.size.height)];
    }
    
    self.clothingSwipeView.delegate = self;
    self.clothingSwipeView.dataSource = self;
    self.clothingSwipeView.clipsToBounds = YES;
    self.clothingSwipeView.pagingEnabled = YES;
    self.clothingSwipeView.truncateFinalPage = NO;
    [self.clothingSwipeView setBackgroundColor:[UIColor whiteColor]];
    self.clothingSwipeView.alignment = SwipeViewAlignmentEdge;
    
    [self.clothingCell addSubview:self.clothingSwipeView];
    
    [self.clothingSwipeView reloadData];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.editMode == YES && [[PFUser currentUser]objectForKey:@"sizeCountry"]) {
        
        //scroll to already selected sneaker sizes
        if ([[[PFUser currentUser]objectForKey:@"sizeCountry"]isEqualToString:@"UK"]) {
            [self.ukButton setSelected:YES];
            self.selectedCountry = @"UK";
            
            NSArray *shoeSizeArray = [[PFUser currentUser]objectForKey:@"UKShoeSizeArray"];
            if (shoeSizeArray.count>1) {
                NSString *middleSize = shoeSizeArray[1];
                
                for (int i = 0; i<self.UKShoeSizes.count; i++) {
                    NSString *size = [self.UKShoeSizes objectAtIndex:i];
                    if ([size isEqualToString:middleSize]) {
                        //scroll to this index
                        [self.sneakerSwipeView scrollByNumberOfItems:i duration:0.5];
                    }
                }
            }
        }
        else if ([[[PFUser currentUser]objectForKey:@"sizeCountry"]isEqualToString:@"US"]) {
            [self.usButton setSelected:YES];
            self.selectedCountry = @"US";
            
            NSArray *shoeSizeArray = [[PFUser currentUser]objectForKey:@"USShoeSizeArray"];
            if (shoeSizeArray.count>1) {
                NSString *middleSize = shoeSizeArray[1];
                
                for (int i = 0; i<self.USShoeSizes.count; i++) {
                    NSString *size = [self.USShoeSizes objectAtIndex:i];
                    if ([size isEqualToString:middleSize]) {
                        //scroll to this index
                        [self.sneakerSwipeView scrollByNumberOfItems:i duration:0.5];
                    }
                }
            }
        }
        else if ([[[PFUser currentUser]objectForKey:@"sizeCountry"]isEqualToString:@"EU"]) {
            [self.euButton setSelected:YES];
            self.selectedCountry = @"EU";
            
            NSArray *shoeSizeArray = [[PFUser currentUser]objectForKey:@"EUShoeSizeArray"];
            if (shoeSizeArray.count>1) {
                NSString *middleSize = shoeSizeArray[1];
                
                for (int i = 0; i<self.EUShoeSizes.count; i++) {
                    NSString *size = [self.EUShoeSizes objectAtIndex:i];
                    if ([size isEqualToString:middleSize]) {
                        //scroll to this index
                        [self.sneakerSwipeView scrollByNumberOfItems:i duration:0.5];
                    }
                }
            }
        }
        
        //scroll to clothing
        if ([[PFUser currentUser]objectForKey:@"clothingSizeArray"]) {
            
            NSArray *clothingSizeArray = [[PFUser currentUser]objectForKey:@"clothingSizeArray"];
            if (clothingSizeArray.count>0) {
                
                NSString *firstSize = clothingSizeArray[0];
                
                for (int i = 0; i<self.clothingSizesArray.count; i++) {
                    NSString *size = [self.clothingSizesArray objectAtIndex:i];
                   
                    if ([size isEqualToString:firstSize]) {
                        //scroll to this index
                        [self.clothingSwipeView scrollByNumberOfItems:i-1 duration:0.5];
                    }
                }
            }
            
        }
    }
    else{
        [self.ukButton setSelected:YES];
        self.selectedCountry = @"UK";
        
        //scroll to fix bug which populates swipeview with 1 item
        [self.sneakerSwipeView scrollByNumberOfItems:15 duration:0.5];
        [self.clothingSwipeView scrollByNumberOfItems:2 duration:0.5];
    }
    
    if (!self.longButton) {
        self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
        [self.longButton setTitle:@"D O N E" forState:UIControlStateNormal];
        [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
        [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
        [self.longButton addTarget:self action:@selector(donePressed) forControlEvents:UIControlEventTouchUpInside];
        self.longButton.alpha = 0.0f;
        [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
    }
    
    if (self.longShowing != YES) {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.longButton.alpha = 1.0f;
                         }
                         completion:^(BOOL finished) {
                             self.longShowing = YES;
                         }];
    }
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
        return self.titleCell;
    }
    else if(indexPath.row == 1){
        return self.sneakerCell;
    }
    else if(indexPath.row == 2){
        return self.clothingCell;
    }
    else if(indexPath.row == 3){
        return self.emptyCell;
    }
    else{
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 202;
        }
        else if(indexPath.row == 1){
            return 226;
        }
        else if(indexPath.row == 2){
            return 270;
        }
        else if(indexPath.row == 3){
            return 70;
        }
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
- (IBAction)ukPressed:(id)sender {
    
    if (self.ukButton.selected == YES) {
    }
    else{
        self.selectedCountry = @"UK";
        [self.ukButton setSelected:YES];
        [self.usButton setSelected:NO];
        [self.euButton setSelected:NO];

        //check if last pressed was eu, if so we need to refresh the swipe view numbers
        [self.sneakerSwipeView reloadData];
        [self performSelector:@selector(didChangeCountry) withObject:nil afterDelay:0.1];
    }
}
- (IBAction)usPressed:(id)sender {
    
    if (self.usButton.selected == YES) {
    }
    else{
        self.selectedCountry = @"US";
        [self.ukButton setSelected:NO];
        [self.usButton setSelected:YES];
        [self.euButton setSelected:NO];

        [self.sneakerSwipeView reloadData];
        [self performSelector:@selector(didChangeCountry) withObject:nil afterDelay:0.1];
    }
}
- (IBAction)euPressed:(id)sender {
    if (self.euButton.selected == YES) {
    }
    else{
        self.selectedCountry = @"EU";
        [self.ukButton setSelected:NO];
        [self.usButton setSelected:NO];
        [self.euButton setSelected:YES];
        
        [self.sneakerSwipeView reloadData];
        [self performSelector:@selector(didChangeCountry) withObject:nil afterDelay:0.1];
    }
}

#pragma mark - swipe view delegates

-(UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view{
    
    UILabel *messageLabel = nil;
    
    if (view == nil)
    {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80,35)];
        messageLabel = [[UILabel alloc]initWithFrame:CGRectMake(5,0, 70, 35)];
        messageLabel.layer.cornerRadius = 7;
        messageLabel.layer.masksToBounds = YES;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        [messageLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:13]];
        messageLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
        messageLabel.backgroundColor = [UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0];
        [view setAlpha:1.0];
        [view addSubview:messageLabel];
    }
    else
    {
        messageLabel = [[view subviews] lastObject];
        messageLabel.backgroundColor = [UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0];
    }
    
    //check if clothing or shoes
    if (swipeView == self.sneakerSwipeView) {
        
        if (self.euButton.selected == YES) {
            messageLabel.text = [self.EUShoeSizes objectAtIndex:index];
        }
        else if (self.usButton.selected == YES){
            messageLabel.text = [self.USShoeSizes objectAtIndex:index];
        }
        else{
            messageLabel.text = [self.UKShoeSizes objectAtIndex:index];
        }

    }
    else{
        messageLabel.text = [self.clothingSizesArray objectAtIndex:index];
        
        //check if last index
        if (index == self.clothingSizesArray.count-1) {
            messageLabel.backgroundColor = [UIColor whiteColor];
        }
        
        //check if first index
        if (index == 0) {
            messageLabel.backgroundColor = [UIColor whiteColor];
        }
    }
    return view;
}

-(void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index{

    NSInteger selectedIndex;

    //check what collection view
    if (swipeView == self.sneakerSwipeView) {
        
        selectedIndex = self.sneakerSwipeView.currentItemIndex;
        
        if (index == selectedIndex || index == selectedIndex+1 || index == selectedIndex-1) {
//            NSLog(@"don't scroll, selected an already highlighted index");
        }
        else{
//            NSLog(@"selected an index outside the selection bounds!");
            if (index > selectedIndex) {
                //scroll right by 1
                [self.sneakerSwipeView scrollByNumberOfItems:1 duration:0.2];
            }
            else{
                //scroll left by 1
                [self.sneakerSwipeView scrollByNumberOfItems:-1 duration:0.2];
            }
        }
    }
    else{
        selectedIndex = self.clothingSwipeView.currentItemIndex;
        
        if (index == selectedIndex+1 || index == selectedIndex+2) {
//            NSLog(@"don't scroll, selected an already highlighted index");
        }
        else{
//            NSLog(@"selected an index outside the selection bounds!");
            
            //need to do a final check here for clothing swipe view to ensure 2 sizes remain selected
            if (index > selectedIndex) {
                if (self.clothingSizesArray.count-1 == index) {
//                    NSLog(@"don't scroll");
                }
                else{
                    //scroll right by 1
                    [self.clothingSwipeView scrollByNumberOfItems:1 duration:0.2];
                }
            }
            else{
                if (index == 0) {
//                    NSLog(@"don't scroll");
                }
                else{
                    //scroll left by 1
                    [self.clothingSwipeView scrollByNumberOfItems:-1 duration:0.2];
                }
            }
        }
    }
}

-(void)didChangeCountry{
    
    NSArray *visible = self.sneakerSwipeView.visibleItemViews;
    NSInteger index =  self.sneakerSwipeView.currentItemIndex;
    
    for (UIView *item in visible) {
        [item setAlpha:0.5];
        UILabel *messageLabel = [[item subviews] lastObject];
        
        if ([messageLabel.text isEqualToString:@""]) {
            messageLabel.backgroundColor = [UIColor whiteColor];
        }
        else{
            messageLabel.backgroundColor = [UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0];
        }
        messageLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
    }
    
        //set alpha of centered index to .5
        [[self.sneakerSwipeView itemViewAtIndex:index] setAlpha:1.0];
        
        UILabel *messageLabel = [[[self.sneakerSwipeView itemViewAtIndex:index] subviews] lastObject];
        messageLabel.backgroundColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
        messageLabel.textColor = [UIColor whiteColor];
        
        //and alpha of indexes before & after to .5
        if (self.sneakerSwipeView.numberOfItems >= index+1) {
            [[self.sneakerSwipeView itemViewAtIndex:index+1] setAlpha:1.0];
            UILabel *messageLabel = [[[self.sneakerSwipeView itemViewAtIndex:index+1] subviews] lastObject];
            messageLabel.backgroundColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
            messageLabel.textColor = [UIColor whiteColor];
        }
        
        if (self.sneakerSwipeView.numberOfItems >= index-1) {
            [[self.sneakerSwipeView itemViewAtIndex:index-1] setAlpha:1.0];
            UILabel *messageLabel = [[[self.sneakerSwipeView itemViewAtIndex:index-1] subviews] lastObject];
            messageLabel.backgroundColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
            messageLabel.textColor = [UIColor whiteColor];
        }
    

}

-(void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView{
    NSArray *visible;
    NSInteger index = 0;
    
    if (swipeView == self.sneakerSwipeView) {
        visible = self.sneakerSwipeView.visibleItemViews;
        index = self.sneakerSwipeView.currentItemIndex;
        
        if (index == 0) {
            //scroll right by 1 so we have 3 selected
            self.sneakerSwipeView.currentItemIndex = 1;
            return;
        }
        else if (index == self.shoeSizesArray.count-1){
            //scroll left by 1 so we have 3 selected
            self.sneakerSwipeView.currentItemIndex = self.shoeSizesArray.count-2;
            return;
        }
    }
    else{
        visible = self.clothingSwipeView.visibleItemViews;
        index = self.clothingSwipeView.currentItemIndex;
    }
    
    //set all to 0.5
    for (UIView *item in visible) {
        [item setAlpha:0.5];
        UILabel *messageLabel = [[item subviews] lastObject];
        
        if ([messageLabel.text isEqualToString:@""]) {
            messageLabel.backgroundColor = [UIColor whiteColor];
        }
        else{
            messageLabel.backgroundColor = [UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0];
        }
        messageLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
    }
    
    if (swipeView == self.sneakerSwipeView) {
        //set alpha of centered index to .5
        [[swipeView itemViewAtIndex:index] setAlpha:1.0];
        
        UILabel *messageLabel = [[[swipeView itemViewAtIndex:index] subviews] lastObject];
        messageLabel.backgroundColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
        messageLabel.textColor = [UIColor whiteColor];
        
        //and alpha of indexes before & after to .5
        if (swipeView.numberOfItems >= index+1) {
            [[swipeView itemViewAtIndex:index+1] setAlpha:1.0];
            UILabel *messageLabel = [[[swipeView itemViewAtIndex:index+1] subviews] lastObject];
            messageLabel.backgroundColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
            messageLabel.textColor = [UIColor whiteColor];
        }
        
        if (swipeView.numberOfItems >= index-1) {
            [[swipeView itemViewAtIndex:index-1] setAlpha:1.0];
            UILabel *messageLabel = [[[swipeView itemViewAtIndex:index-1] subviews] lastObject];
            messageLabel.backgroundColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
            messageLabel.textColor = [UIColor whiteColor];
        }
    }
    else{
        //clothing swipe view
        if (swipeView.numberOfItems >= index+1 && index+1 != self.clothingSizesArray.count-1) {
            [[swipeView itemViewAtIndex:index+1] setAlpha:1.0];
            UILabel *messageLabel = [[[swipeView itemViewAtIndex:index+1] subviews] lastObject];
            messageLabel.backgroundColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
            messageLabel.textColor = [UIColor whiteColor];
        }
        
        if (swipeView.numberOfItems >= index+2 && index+2 != self.clothingSizesArray.count-1) {
            [[swipeView itemViewAtIndex:index+2] setAlpha:1.0];
            UILabel *messageLabel = [[[swipeView itemViewAtIndex:index+2] subviews] lastObject];
            messageLabel.backgroundColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
            messageLabel.textColor = [UIColor whiteColor];
        }
    }
}


-(NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView{
    if (swipeView == self.sneakerSwipeView) {
        return self.shoeSizesArray.count;
    }
    else{
        return self.clothingSizesArray.count;
    }
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    if (!self.spinner) {
        self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    }
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                         self.longShowing = NO;
                     }];
}

-(void)donePressed{
    [self showHUD];
    
    PFUser *current = [PFUser currentUser];
    
    //footwear
    
//    NSLog(@"CURRENT %ld",self.sneakerSwipeView.currentItemIndex);
    
    //setCountry
    current[@"sizeCountry"] = self.selectedCountry;
    
    //UK
    NSString *UKsneakerSizeOne = [self.UKShoeSizes objectAtIndex:self.sneakerSwipeView.currentItemIndex-1];
    NSString *UKsneakerSizeTwo = [self.UKShoeSizes objectAtIndex:self.sneakerSwipeView.currentItemIndex];
    NSString *UKsneakerSizeThree = [self.UKShoeSizes objectAtIndex:self.sneakerSwipeView.currentItemIndex+1];
    
    NSArray *UKArray = @[UKsneakerSizeOne,UKsneakerSizeTwo,UKsneakerSizeThree];
    current[@"UKShoeSizeArray"] = UKArray;
    
    //US
    NSString *USsneakerSizeOne = [self.USShoeSizes objectAtIndex:self.sneakerSwipeView.currentItemIndex-1];
    NSString *USsneakerSizeTwo = [self.USShoeSizes objectAtIndex:self.sneakerSwipeView.currentItemIndex];
    NSString *USsneakerSizeThree = [self.USShoeSizes objectAtIndex:self.sneakerSwipeView.currentItemIndex+1];
    
    NSArray *USArray = @[USsneakerSizeOne,USsneakerSizeTwo,USsneakerSizeThree];
    current[@"USShoeSizeArray"] = USArray;
    
    //EU
    NSString *EUsneakerSizeOne = [self.EUShoeSizes objectAtIndex:self.sneakerSwipeView.currentItemIndex-1];
    NSString *EUsneakerSizeTwo = [self.EUShoeSizes objectAtIndex:self.sneakerSwipeView.currentItemIndex];
    NSString *EUsneakerSizeThree = [self.EUShoeSizes objectAtIndex:self.sneakerSwipeView.currentItemIndex+1];
    
    NSArray *EUArray = @[EUsneakerSizeOne,EUsneakerSizeTwo,EUsneakerSizeThree];
    current[@"EUShoeSizeArray"] = EUArray;
    
//    NSLog(@"UK: %@    US:%@     EU:%@",UKArray, USArray, EUArray);
    
    //clothing
    
    NSString *clothingSizeOne = [self.clothingSizesArray objectAtIndex:self.clothingSwipeView.currentItemIndex+1];
    NSString *clothingSizeTwo = [self.clothingSizesArray objectAtIndex:self.clothingSwipeView.currentItemIndex+2];

    NSArray *clothingArray = @[clothingSizeOne,clothingSizeTwo];
    current[@"clothingSizeArray"] = clothingArray;
    
//    NSLog(@"clothing: %@",clothingArray);
    
    [current saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            
        }
        else{
            [Answers logCustomEventWithName:@"Deafult Sizes Save Error"
                           customAttributes:@{
                                              @"error":error,
                                              @"where": @"Reg"
                                              }];
        }
        [self hideHUD];
        [self.delegate addSizeDismissed];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

@end
