//
//  FilterVC.m
//  wtbtest
//
//  Created by Jack Ryder on 01/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "FilterVC.h"
#import <Crashlytics/Crashlytics.h>
#import <Parse/Parse.h>

@interface FilterVC ()

@end

@implementation FilterVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:0.9];
    
    //hide first table view header
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
    
    self.sizeLabels = [NSArray arrayWithObjects:@"XXS", @"XS", @"S", @"M", @"L", @"XL", @"XXL", nil];
    
    self.shoesArray = [NSArray arrayWithObjects:@"1", @"1.5", @"2", @"2.5",@"3", @"3.5",@"4", @"4.5", @"5", @"5.5", @"6",@"6.5",@"7", @"7.5", @"8",@"8.5",@"9", @"9.5", @"10",@"10.5",@"11", @"11.5", @"12",@"12.5",@"13", @"13.5", @"14", nil];
    
    //brands
    self.brandArray = [NSArray arrayWithObjects:@"Supreme", @"Palace", @"Bape",@"Patta",@"Off White",@"Gosha", @"Stussy",@"Kith", @"Adidas", @"Stone Island", @"Nike", @"Ralph Lauren", @"Gucci",@"Champion",@"Jordan",@"Louis Vuitton",@"Vetements",@"Balenciaga",@"Vlone",@"ASSC",@"CDG",@"P+F",@"Raf Simons", nil];
    
    self.brandImagesArray = [NSArray arrayWithObjects:@"supremeNormal1", @"palaceNormal2", @"bapeNormal3",@"pattaNormal2",@"offWhiteNormal1",@"goshaNormal1", @"stussyNormal",@"kithNormal", @"adidasNormal2", @"stoneyNormal2", @"nikeNormal2", @"ralphNormal2", @"gucciNormal",@"championNormal",@"jordanNormal",@"LVNormal",@"veteNormal",@"balenNormal",@"vloneNormal",@"asscNormal",@"cdgNormal",@"placesNormal",@"rafNormal", nil];
    
    self.brandSelectedImagesArray = [NSArray arrayWithObjects:@"supremeSelected1", @"palaceSelected2", @"bapeSelected2",@"pattaSelected2",@"offWhiteSelected1",@"goshaSelected1", @"stussySelected",@"kithSelected", @"adidasSelected2", @"stoneySelected2", @"nikeSelected2", @"ralphSelected2", @"gucciSelected",@"championSelected",@"jordanSelected",@"LVSelected",@"veteSelected",@"balenSelected",@"vloneSelected",@"asscSelected",@"cdgSelected",@"placesSelected",@"rafSelected", nil];
    
    self.brandAcronymArray = [NSArray arrayWithObjects:@"supreme", @"palace", @"bape",@"patta",@"offwhite",@"gosha", @"stussy",@"kith",@"adidas", @"stoneisland", @"nike", @"ralph", @"gucci",@"champion",@"jordan",@"lv",@"vetements",@"balen",@"vlone",@"assc",@"cdg",@"pf",@"raf",nil];
    
    //categories
    self.chosenCategory = @"";
    
    self.categoryArray = [NSArray arrayWithObjects:@"Tops", @"Bottoms", @"Outerwear",@"Footwear",@"Accessories",@"Proxy", nil];
    
    self.categoryImagesArray = [NSArray arrayWithObjects:@"topsIcon",@"bottomsIcon",@"outIcon",@"footIcon",@"accIcon",@"proxyIcon", nil];
    
    self.categorySelectedImagesArray = [NSArray arrayWithObjects:@"topsSelected",@"bottomsSelected",@"outSelected",@"footSelected",@"accSelected",@"proxySelected", nil];
    
    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.priceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.conditionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.categoryCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.sizeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.distanceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.spaceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.brandCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.colourCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.categoryIconCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.priceSliderCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.locationContinentsCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    //category swipe view
    self.categorySwipeView.delegate = self;
    self.categorySwipeView.dataSource = self;
    self.categorySwipeView.clipsToBounds = YES;
    self.categorySwipeView.pagingEnabled = NO;
    self.categorySwipeView.truncateFinalPage = NO;
    [self.categorySwipeView setBackgroundColor:[UIColor clearColor]];
    self.categorySwipeView.alignment = SwipeViewAlignmentEdge;
    [self.categorySwipeView reloadData];
    
    //continents swipe view
    self.locationSwipeView.delegate = self;
    self.locationSwipeView.dataSource = self;
    self.locationSwipeView.clipsToBounds = YES;
    self.locationSwipeView.pagingEnabled = NO;
    self.locationSwipeView.truncateFinalPage = NO;
    [self.locationSwipeView setBackgroundColor:[UIColor clearColor]];
    self.locationSwipeView.alignment = SwipeViewAlignmentEdge;
    [self.locationSwipeView reloadData];
    
    self.continentsArray = [NSArray arrayWithObjects:@"Around me",@"America",@"Asia",@"Europe", nil];
    
    //setup sizes swipe view
    self.sizeMode = @"footwear";
    self.lastSelected = @"";
    
    //sizes swipe view
    self.swipeView.delegate = self;
    self.swipeView.dataSource = self;
    self.swipeView.clipsToBounds = YES;
    self.swipeView.pagingEnabled = NO;
    self.swipeView.truncateFinalPage = NO;
    [self.swipeView setBackgroundColor:[UIColor clearColor]];
    self.swipeView.alignment = SwipeViewAlignmentEdge;
    [self.swipeView reloadData];
    
    //setup colour swipe view
    self.colourSwipeView.delegate = self;
    self.colourSwipeView.dataSource = self;
    self.colourSwipeView.clipsToBounds = YES;
    self.colourSwipeView.pagingEnabled = NO;
    self.colourSwipeView.truncateFinalPage = NO;
    [self.colourSwipeView setBackgroundColor:[UIColor clearColor]];
    self.colourSwipeView.alignment = SwipeViewAlignmentEdge;
    [self.colourSwipeView reloadData];
    
    self.coloursArray = @[@"Black", @"White", @"Grey", @"Blue", @"Orange", @"Green", @"Red", @"Camo", @"Peach", @"Yellow", @"Purple", @"Pink"];
    self.chosenColourArray = [NSMutableArray array];
    self.colourValuesArray = @[[UIColor blackColor],[UIColor whiteColor],[UIColor lightGrayColor],[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0],[UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1.0],[UIColor colorWithRed:0.49 green:0.83 blue:0.13 alpha:1.0],[UIColor colorWithRed:0.95 green:0.20 blue:0.30 alpha:1.0],[UIColor brownColor],[UIColor colorWithRed:1.00 green:0.81 blue:0.50 alpha:1.0],[UIColor colorWithRed:0.97 green:0.91 blue:0.11 alpha:1.0],[UIColor colorWithRed:0.56 green:0.07 blue:1.00 alpha:1.0],[UIColor colorWithRed:0.93 green:0.58 blue:1.00 alpha:1.0]];
    
    //brand swipe view
    self.brandSwipeView.delegate = self;
    self.brandSwipeView.dataSource = self;
    self.brandSwipeView.clipsToBounds = YES;
    self.brandSwipeView.pagingEnabled = NO;
    self.brandSwipeView.truncateFinalPage = NO;
    [self.brandSwipeView setBackgroundColor:[UIColor clearColor]];
    self.brandSwipeView.alignment = SwipeViewAlignmentEdge;
    [self.brandSwipeView reloadData];
    
    //sendarray containts the filters selected last time. Use to select previous search buttons & relevant sizing buttons
    self.filtersArray = [NSMutableArray array];
    self.chosenSizesArray = [NSMutableArray array];
    self.chosenBrandsArray = [NSMutableArray array];
    self.chosenContinentsArray = [NSMutableArray array];

    //price slider
    self.doubleSlider.minimumRange = 50;
    
    self.doubleSlider.maximumValue = 1000;
    self.doubleSlider.minimumValue = 0;
    self.doubleSlider.upperValue = 1000;
    self.doubleSlider.lowerValue = 0;
    
    self.doubleSlider.stepValue = 10;
    self.doubleSlider.stepValueContinuously = YES;
    
    [self.doubleSlider addTarget:self action:@selector(priceValueChanged) forControlEvents:UIControlEventValueChanged];
    [self.doubleSlider setTintColor:[UIColor lightGrayColor]];

    if (self.sendArray) {
        [self.filtersArray addObjectsFromArray:self.sendArray];
        
        //set up previous filters
        if (self.filtersArray.count > 0) {
            
            [self updateTitle];
            
            if ([self.filtersArray containsObject:@"hightolow"]) {
                [self.hightolowButton setSelected:YES];
            }
            if ([self.filtersArray containsObject:@"lowtohigh"]){
                [self.lowtoHighButton setSelected:YES];
            }
            if ([self.filtersArray containsObject:@"new"]){
                [self.conditionNewButton setSelected:YES];
            }
            if ([self.filtersArray containsObject:@"used"]){
                [self.usedButton setSelected:YES];
            }
            
            for (NSString *continent in self.continentsArray) {
                if ([self.filtersArray containsObject:continent]) {
                    [self.chosenContinentsArray addObject:continent];
                }
            }
            if (self.chosenContinentsArray.count > 0) {
                [self.locationSwipeView reloadData];
            }
            
            if ([self.filtersArray containsObject:@"price"]) {
                self.doubleSlider.lowerValue = self.filterLower;
                self.doubleSlider.upperValue = self.filterUpper;
                [self updateSliderLabels];
            }
            
            //add brands
            for (NSString *brand in self.brandAcronymArray) {
                if ([self.filtersArray containsObject:brand]) {
                    [self.chosenBrandsArray addObject:brand];
                    
                    //add extra keywords if needed
                    if ([brand isEqualToString:@"offwhite"]) {
                        [self.chosenBrandsArray addObject:@"off-white"];
                    }
                    else if ([brand isEqualToString:@"stoneisland"]) {
                        [self.chosenBrandsArray addObject:@"stone"];
                        [self.chosenBrandsArray addObject:@"island"];
                    }
                    else if ([brand isEqualToString:@"vlone"]) {
                        [self.filtersArray addObject:@"vlone"];
                        [self.chosenBrandsArray addObject:@"vlone"];
                        [self.chosenBrandsArray addObject:@"v-lone"];
                    }
                    else if ([brand isEqualToString:@"assc"]) {
                        [self.chosenBrandsArray addObject:@"assc"];
                        [self.chosenBrandsArray addObject:@"antisocialclub"];
                        [self.chosenBrandsArray addObject:@"anti"];
                        [self.chosenBrandsArray addObject:@"social"];
                        [self.chosenBrandsArray addObject:@"club"];
                    }
                    else if ([brand isEqualToString:@"cdg"]) {
                        [self.chosenBrandsArray addObject:@"comme"];
                        [self.chosenBrandsArray addObject:@"des"];
                        [self.chosenBrandsArray addObject:@"garcons"];
                    }
                    else if ([brand isEqualToString:@"pf"]) {
                        [self.chosenBrandsArray addObject:@"places"];
                        [self.chosenBrandsArray addObject:@"faces"];
                    }
                    else if ([brand isEqualToString:@"raf"]) {
                        [self.chosenBrandsArray addObject:@"simons"];
                    }
                    else if ([brand isEqualToString:@"lv"]) {
                        [self.chosenBrandsArray addObject:@"louis"];
                        [self.chosenBrandsArray addObject:@"vuitton"];
                        [self.chosenBrandsArray addObject:@"vutton"];
                    }
                    else if ([brand isEqualToString:@"jordan"]) {
                        [self.chosenBrandsArray addObject:@"jordans"];
                    }
                }
            }
            
            if (self.chosenBrandsArray.count > 0) {
                [self.brandSwipeView reloadData];
            }
            
            //swipe to first selected brand
            if (self.chosenBrandsArray.count > 0) {
                NSUInteger selectedIndex = [self.brandAcronymArray indexOfObject:self.chosenBrandsArray[0]];
                self.brandSwipeView.currentItemIndex = selectedIndex;
            }
            
            //check for colours
            for (NSString *filter in self.filtersArray) {
                if ([self.coloursArray containsObject:filter]) {
                    [self.chosenColourArray addObject:filter];
                }
            }
            [self.colourSwipeView reloadData];
            
            if (self.chosenColourArray.count > 0) {
                //scroll swipeView to first selected colour
                NSUInteger selectedIndex = [self.coloursArray indexOfObject:self.chosenColourArray[0]];
                self.colourSwipeView.currentItemIndex = selectedIndex;
            }
            
            //check for categories
            for (NSString *category in self.filtersArray) {
                if ([self.categoryArray containsObject:category]) {
                    self.chosenCategory = category;
                    break;
                }
            }
            [self.categorySwipeView reloadData];
            
            if (![self.chosenCategory isEqualToString:@""]) {
                //scroll swipeView to first selected category
                NSUInteger selectedIndex = [self.categoryArray indexOfObject:self.chosenCategory];
                self.categorySwipeView.currentItemIndex = selectedIndex;
            }
            
            if ([self.filtersArray containsObject:@"Tops"] || [self.filtersArray containsObject:@"Bottoms"] || [self.filtersArray containsObject:@"Outerwear"]){
                //check if send array contains a size & set as last selected
                
                for (NSString *parameter in self.sendArray) {
                    if ([self.sizeLabels containsObject:parameter]) {
//                        self.lastSelected = parameter;
                        NSLog(@"last selected clothing size was %@", parameter);
//                        break;
                        [self.chosenSizesArray addObject:parameter];
                    }
                }
                
                self.sizeMode = @"clothing";
                [self.swipeView reloadData];
                
                if (self.chosenSizesArray.count > 0) {
                    //scroll swipeView to selected size
                    NSUInteger selectedIndex = [self.sizeLabels indexOfObject:self.chosenSizesArray[0]];
                    self.swipeView.currentItemIndex = selectedIndex;
                }

                
                [self.clothingButton setSelected:YES];
                [self.menButton setEnabled:NO];
                [self.womenButton setEnabled:NO];
            }
            else if ([self.filtersArray containsObject:@"Footwear"]){
                
                //check if send array contains a size & set as last selected
                for (NSString *parameter in self.sendArray) {
                    if ([self.shoesArray containsObject:parameter]) {
//                        self.lastSelected = parameter;
                        [self.chosenSizesArray addObject:parameter];
//                        NSLog(@"last selected shoe size was %@", parameter);
//                        break;
                    }
                }
                
                self.sizeMode = @"footwear";
                [self.swipeView reloadData];
                
                if (self.chosenSizesArray.count > 0) {
                    //scroll swipeView to selected size
                    NSUInteger selectedIndex = [self.shoesArray indexOfObject:self.chosenSizesArray[0]];
                    self.swipeView.currentItemIndex = selectedIndex;
                }
                
                [self.footButton setSelected:YES];
                [self.menButton setEnabled:YES];
                [self.womenButton setEnabled:YES];
                
            }
            else if ([self.filtersArray containsObject:@"Accessories"] || [self.filtersArray containsObject:@"Proxy"]){
                [self.accessoryButton setSelected:YES];
                [self setupFootwearSizes];
                [self setupAccessories];
                
                [self.menButton setEnabled:NO];
                [self.womenButton setEnabled:NO];
                
            }
            else{
                [self setupClothingSizes];
                [self.menButton setEnabled:NO];
                [self.womenButton setEnabled:NO];
            }
            
            if ([self.filtersArray containsObject:@"male"]){
                [self.menButton setSelected:YES];
            }
            if ([self.filtersArray containsObject:@"female"]){
                [self.womenButton setSelected:YES];
            }
        }
    }
    else{
        self.titleLabel.text = @"F I L T E R S";

        self.sizeMode = @"clothing";
        [self.swipeView reloadData];
        
        //scroll to user's selected size if they have one
        if ([[PFUser currentUser]objectForKey:@"clothingSizeArray"]) {
            
            NSArray *clothingSizeArray = [[PFUser currentUser]objectForKey:@"clothingSizeArray"];
            NSUInteger firstSize = [self.sizeLabels indexOfObject:clothingSizeArray[0]];
            self.swipeView.currentItemIndex = firstSize;
            
        }
        
        [self.menButton setEnabled:NO];
        [self.womenButton setEnabled:NO];
    }
    
    if (!self.applyButton) {
        self.applyButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-60, [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
        [self.applyButton setTitle:@"A P P L Y" forState:UIControlStateNormal];
        [self.applyButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
        [self.applyButton.titleLabel setTextAlignment: NSTextAlignmentCenter];
        [self.applyButton setBackgroundColor:[UIColor colorWithRed:0.31 green:0.89 blue:0.76 alpha:1.0]];
        [self.applyButton addTarget:self action:@selector(applyButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    self.applyButton.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:self.applyButton];

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.applyButton.alpha = 1.0f;
                     }
                     completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
        
    self.statusBarBGView = [[UIView alloc]init];
    self.statusBarBGView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIApplication sharedApplication].statusBarFrame.size.height);
    self.statusBarBGView.backgroundColor = [UIColor blackColor]; // your colour
    self.statusBarBGView.alpha = 0.0;
    [[UIApplication sharedApplication].keyWindow addSubview:self.statusBarBGView];

    [UIView animateWithDuration:0.4
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.statusBarBGView.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                     }];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.sellingSearch) {
        return 8;
    }
    else if (self.profileSearch){
        return 7;
    }
    else{
        return 6; //colour and price filters only exist when search through for sale listings
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.sellingSearch) {
        if (indexPath.section == 0){
            if (indexPath.row == 0){
                return 174;
            }
            else if (indexPath.row == 1){
                return 125;
            }
            else if (indexPath.row == 2){
                return 174;
            }
            else if (indexPath.row == 3){
                return 189;
            }
            else if (indexPath.row == 4){
                return 131;
            }
            else if (indexPath.row == 5){
                return 226;
            }
            else if (indexPath.row == 6){
                return 139;
            }
            else if (indexPath.row == 7){
                return 60;
            }
        }
        else{
            return 44;
        }
    }
    else if (self.profileSearch){
        if (indexPath.section == 0){
            if (indexPath.row == 0){
                return 174;
            }
            else if (indexPath.row == 1){
                return 125;
            }
            else if (indexPath.row == 2){
                return 174;
            }
            else if (indexPath.row == 3){
                return 189;
            }
            else if (indexPath.row == 4){
                return 131;
            }
            else if (indexPath.row == 5){
                return 226;
            }
            else if (indexPath.row == 6){
                return 60;
            }
        }
        else{
            return 44;
        }
    }
    else{
        if (indexPath.section == 0){
            if (indexPath.row == 0){
                return 174;
            }
            else if (indexPath.row == 1){
                return 174;
            }
            else if (indexPath.row == 2){
                return 189;
            }
            else if (indexPath.row == 3){
                return 131;
            }
            else if (indexPath.row == 4){
                return 139;
            }
            else if (indexPath.row == 5){
                return 60;
            }
        }
        else{
            return 44;
        }
    }
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.sellingSearch) {
        if (indexPath.section == 0){
            if (indexPath.row == 0){
                return self.brandCell;
            }
            else if (indexPath.row == 1){
                return self.colourCell;
            }
            else if (indexPath.row == 2){
                return self.categoryIconCell;
            }
            else if (indexPath.row == 3){
                return self.sizeCell;
            }
            else if (indexPath.row == 4){
                return self.conditionCell;
            }
            else if (indexPath.row == 5){
                return self.priceSliderCell;
            }
            else if (indexPath.row == 6){
                return self.locationContinentsCell;
            }
            else if (indexPath.row == 7){
                return self.spaceCell;
            }
        }
        else{
            return nil;
        }
    }
    else if (self.profileSearch){
        if (indexPath.section == 0){
            if (indexPath.row == 0){
                return self.brandCell;
            }
            else if (indexPath.row == 1){
                return self.colourCell;
            }
            else if (indexPath.row == 2){
                return self.categoryIconCell;
            }
            else if (indexPath.row == 3){
                return self.sizeCell;
            }
            else if (indexPath.row == 4){
                return self.conditionCell;
            }
            else if (indexPath.row == 5){
                return self.priceSliderCell;
            }
            else if (indexPath.row == 6){
                return self.spaceCell;
            }
        }
        else{
            return nil;
        }
    }
    else{
        if (indexPath.section == 0){
            if (indexPath.row == 0){
                return self.brandCell;
            }
            else if (indexPath.row == 1){
                return self.categoryIconCell;
            }
            else if (indexPath.row == 2){
                return self.sizeCell;
            }
            else if (indexPath.row == 3){
                return self.conditionCell;
            }
            else if (indexPath.row == 4){
                return self.locationContinentsCell;
            }
            else if (indexPath.row == 5){
                return self.spaceCell;
            }
        }
        else{
            return nil;
        }
    }

    return nil;
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

//hide the first header in table view
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 75.0f;
    return 0.0f;
}

- (NSString*) tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

-(void)updateTitle{
    if (self.filtersArray.count > 0) {
//        self.titleLabel.text = [NSString stringWithFormat:@"F I L T E R S  %lu", self.filtersArray.count];
        
        //change colour of filter number
        NSMutableAttributedString *filterString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"F I L T E R S  %lu",self.filtersArray.count]];
        [self modifyString:filterString setColorForText:[NSString stringWithFormat:@"%lu",self.filtersArray.count] withColor:[UIColor colorWithRed:0.31 green:0.89 blue:0.76 alpha:1.0]];
        [self.titleLabel setAttributedText:filterString];
    }
    else{
        self.titleLabel.text = @"F I L T E R S";
        
    }
}
- (IBAction)dismissPressed:(id)sender {
    
    //if tap cross and just pressed clear then we should clear, otherwise forget the changes - revert back to filters selected when last hit apply
    if (self.filtersArray.count == 0 && self.sendArray.count != 0) {
        float upp = self.doubleSlider.upperValue;
        
        if (upp == 1000) {
            upp = 100000;
        }
        
        [self.delegate filtersReturned:self.filtersArray withSizesArray:self.chosenSizesArray andBrandsArray:self.chosenBrandsArray andColours:self.chosenColourArray andCategories:self.chosenCategory andPricLower:self.doubleSlider.lowerValue andPriceUpper:upp andContinents:self.chosenContinentsArray];
    
    }
    else{
        [self.delegate noChange];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)clearPressed:(id)sender {
    [self.hightolowButton setSelected:NO];
    [self.lowtoHighButton setSelected:NO];
    
    [self.conditionNewButton setSelected:NO];
    [self.usedButton setSelected:NO];
    
    [self.menButton setSelected:NO];
    [self.womenButton setSelected:NO];
    
    [self.distanceButton setSelected:NO];
    
    [self.filtersArray removeAllObjects];
    [self.chosenBrandsArray removeAllObjects];
    [self.chosenSizesArray removeAllObjects];
    [self.chosenColourArray removeAllObjects];
    [self.chosenContinentsArray removeAllObjects];
    
    self.chosenCategory = @"";
    self.lastSelected = @"";

    [self.swipeView reloadData];
    [self.brandSwipeView reloadData];
    [self.colourSwipeView reloadData];
    [self.categorySwipeView reloadData];
    [self.locationSwipeView reloadData];
    
    [self setupClothingSizes];
    
    self.doubleSlider.upperValue = 1000;
    self.doubleSlider.lowerValue = 0;
    [self updateSliderLabels];
    
    [self updateTitle];
}
- (IBAction)hightolowPressed:(id)sender {
    if(self.hightolowButton.selected == YES){
        NSLog(@"remove selected ");

        [self.hightolowButton setSelected:NO];
        [self.filtersArray removeObject:@"hightolow"];
    }
    else{
        NSLog(@"add selected ");

        [self.hightolowButton setSelected:YES];
        [self.filtersArray addObject:@"hightolow"];
        [self.lowtoHighButton setSelected:NO];
        [self.filtersArray removeObject:@"lowtohigh"];
    }
    [self updateTitle];
}
- (IBAction)lowtohighPressed:(id)sender {
    if(self.lowtoHighButton.selected == YES){
        [self.lowtoHighButton setSelected:NO];
        [self.filtersArray removeObject:@"lowtohigh"];
    }
    else{

        [self.lowtoHighButton setSelected:YES];
        [self.filtersArray addObject:@"lowtohigh"];
        [self.hightolowButton setSelected:NO];
        [self.filtersArray removeObject:@"hightolow"];
    }
    [self updateTitle];
}

- (IBAction)newPressed:(id)sender {
    if(self.conditionNewButton.selected == YES){
        [self.conditionNewButton setSelected:NO];
        [self.filtersArray removeObject:@"new"];
    }
    else{

        [self.conditionNewButton setSelected:YES];
        [self.filtersArray addObject:@"new"];
        [self.usedButton setSelected:NO];
        [self.filtersArray removeObject:@"used"];
    }
    [self updateTitle];
}


- (IBAction)usedPressed:(id)sender {
    if(self.usedButton.selected == YES){
        [self.usedButton setSelected:NO];
        [self.filtersArray removeObject:@"used"];
    }
    else{

        [self.usedButton setSelected:YES];
        [self.filtersArray addObject:@"used"];
        [self.conditionNewButton setSelected:NO];
        [self.filtersArray removeObject:@"new"];
    }
    [self updateTitle];
}

- (IBAction)clothingPressed:(id)sender {
    if(self.clothingButton.selected == YES){
        [self.clothingButton setSelected:NO];
        [self.filtersArray removeObject:@"clothing"];
    }
    else{

        [self.clothingButton setSelected:YES];
        [self.filtersArray addObject:@"clothing"];
        [self.footButton setSelected:NO];
        [self.filtersArray removeObject:@"footwear"];
        [self.menButton setEnabled:NO];
        [self.womenButton setEnabled:NO];
        [self.filtersArray removeObject:@"male"];
        [self.filtersArray removeObject:@"female"];
        
        [self.accessoryButton setSelected:NO];
        [self.filtersArray removeObject:@"accessory"];
        
        [self setupClothingSizes];
    }
    [self updateTitle];
}
- (IBAction)footwearPressed:(id)sender {
    if(self.footButton.selected == YES){
        [self.footButton setSelected:NO];
        [self.filtersArray removeObject:@"footwear"];
    }
    else{

        [self.footButton setSelected:YES];
        [self.filtersArray addObject:@"footwear"];
        [self.clothingButton setSelected:NO];
        [self.filtersArray removeObject:@"clothing"];
        [self.menButton setEnabled:YES];
        [self.womenButton setEnabled:YES];
        
        [self.accessoryButton setSelected:NO];
        [self.filtersArray removeObject:@"accessory"];
        
        [self setupFootwearSizes];
    }
    [self updateTitle];
}
- (IBAction)accessoryPressed:(id)sender {
    if(self.accessoryButton.selected == YES){
        [self.accessoryButton setSelected:NO];
        [self.filtersArray removeObject:@"accessory"];
        
    }
    else{

        [self.accessoryButton setSelected:YES];
        [self.filtersArray addObject:@"accessory"];
        
        [self.clothingButton setSelected:NO];
        [self.filtersArray removeObject:@"clothing"];
        
        [self.footButton setSelected:NO];
        [self.filtersArray removeObject:@"footwear"];
        
        [self.menButton setEnabled:NO];
        [self.womenButton setEnabled:NO];
        
        [self setupAccessories];
        
    }
    [self updateTitle];
}

-(void)applyButtonPressed{
    [Answers logCustomEventWithName:@"Filters applied"
                   customAttributes:@{}];
    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:self.filtersArray];
    NSArray *arrayWithoutDuplicates = [orderedSet array];
    NSMutableArray *noduplicates = [NSMutableArray arrayWithArray:arrayWithoutDuplicates];
//    NSLog(@"without duplicates %@", noduplicates);
    
    //track what people are searching for!
    for (NSString *size in self.chosenSizesArray) {
        [Answers logCustomEventWithName:@"Size searched"
                       customAttributes:@{
                                          @"size":size
                                          }];
    }
    for (NSString *brand in self.chosenBrandsArray) {
        [Answers logCustomEventWithName:@"Brand searched"
                       customAttributes:@{
                                          @"brand":brand
                                          }];
    }
    for (NSString *colour in self.chosenColourArray) {
        [Answers logCustomEventWithName:@"Colour searched"
                       customAttributes:@{
                                          @"Colour":colour
                                          }];
    }
    for (NSString *filter in self.filtersArray) {
        [Answers logCustomEventWithName:@"Filter searched"
                       customAttributes:@{
                                          @"filter":filter
                                          }];
    }
    float upp = self.doubleSlider.upperValue;
    
    if (upp == 1000) {
        upp = 100000;
    }
    
    [self.delegate filtersReturned:self.filtersArray withSizesArray:self.chosenSizesArray andBrandsArray:self.chosenBrandsArray andColours:self.chosenColourArray andCategories:self.chosenCategory andPricLower:self.doubleSlider.lowerValue andPriceUpper:upp andContinents:self.chosenContinentsArray];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)menPressed:(id)sender {
    if (self.menButton.selected == YES) {
        [self.menButton setSelected:NO];
        [self.filtersArray removeObject:@"male"];
    }
    else{

        [self.menButton setSelected:YES];
        [self.filtersArray addObject:@"male"];
        [self.womenButton setSelected:NO];
        [self.filtersArray removeObject:@"female"];
    }
    [self updateTitle];
}
- (IBAction)womenPressed:(id)sender {
    if (self.womenButton.selected == YES) {
        [self.womenButton setSelected:NO];
        [self.filtersArray removeObject:@"female"];
    }
    else{

        
        [self.womenButton setSelected:YES];
        [self.filtersArray addObject:@"female"];
        [self.menButton setSelected:NO];
        [self.filtersArray removeObject:@"male"];
    }
    [self updateTitle];
}

- (IBAction)aroundMeSelected:(id)sender {
    if (self.distanceButton.selected == YES) {
        [self.distanceButton setSelected:NO];
        [self.filtersArray removeObject:@"aroundMe"];
    }
    else{

        [self.distanceButton setSelected:YES];
        [self.filtersArray addObject:@"aroundMe"];
    }
    [self updateTitle];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.applyButton removeFromSuperview];
    
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.statusBarBGView.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         self.statusBarBGView = nil;
                     }];
}

#pragma mark - swipe view delegates

-(UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view{
    
    if (swipeView == self.brandSwipeView) {
        UIImageView *imageView = nil;
        UILabel *brandLabel = nil;
        
        if (view == nil)
        {
            view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80,90)];
            imageView = [[UIImageView alloc]initWithFrame:CGRectMake(5,5, 50, 50)];
            brandLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 65, 60, 20)];
            brandLabel.numberOfLines = 0;
            brandLabel.textAlignment = NSTextAlignmentCenter;
            brandLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:9];
            [brandLabel setTextColor:[UIColor lightGrayColor]];
            [view setAlpha:1.0];
            [view addSubview:brandLabel];
            [view addSubview:imageView];
        }
        else
        {
            imageView = [[view subviews] lastObject];
            brandLabel = [[view subviews] objectAtIndex:0];
        }
        
        //set brand label
        brandLabel.text = [self.brandArray objectAtIndex:index];
        NSString *selected = [self.brandAcronymArray objectAtIndex:index];
        
        //set image
        if ([self.chosenBrandsArray containsObject:selected]) {
            //set selected
            [brandLabel setTextColor:[UIColor whiteColor]];
            [imageView setImage:[UIImage imageNamed:self.brandSelectedImagesArray[index]]];

        }
        else{
            //set unselected
            [brandLabel setTextColor:[UIColor lightGrayColor]];
            [imageView setImage:[UIImage imageNamed:self.brandImagesArray[index]]];
        }
        return view;
    }
    else if (swipeView == self.categorySwipeView) {
        UIImageView *imageView = nil;
        UILabel *categoryLabel = nil;
        
        if (view == nil)
        {
            view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80,90)];
            imageView = [[UIImageView alloc]initWithFrame:CGRectMake(5,5, 50, 50)];
            categoryLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 65, 60, 20)];
            categoryLabel.numberOfLines = 0;
            categoryLabel.textAlignment = NSTextAlignmentCenter;
            categoryLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:9];
            [categoryLabel setTextColor:[UIColor lightGrayColor]];
            [view setAlpha:1.0];
            [view addSubview:categoryLabel];
            [view addSubview:imageView];
        }
        else
        {
            imageView = [[view subviews] lastObject];
            categoryLabel = [[view subviews] objectAtIndex:0];
        }
        
        //set brand label
        categoryLabel.text = [self.categoryArray objectAtIndex:index];
        
        //set image
        if ([self.chosenCategory isEqualToString:categoryLabel.text]) {
            //set selected
            [categoryLabel setTextColor:[UIColor whiteColor]];
            [imageView setImage:[UIImage imageNamed:self.categorySelectedImagesArray[index]]];
            
        }
        else{
            //set unselected
            [categoryLabel setTextColor:[UIColor lightGrayColor]];
            [imageView setImage:[UIImage imageNamed:self.categoryImagesArray[index]]];
        }
        return view;
    }
    else if (swipeView == self.colourSwipeView){
        
        UIView *innerView = nil;
        UIImageView *imageView = nil;
        
        if (view == nil)
        {
            view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50,50)];
            view.backgroundColor = [UIColor clearColor];
            
            innerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40,40)];
            imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0,0, 30, 30)];
            
            imageView.center = innerView.center;
            
            [innerView addSubview:imageView];
            [view addSubview:innerView];
            
            innerView.center = view.center;
        }
        else
        {
            innerView = [[view subviews] lastObject];
            imageView =  [[innerView subviews] lastObject];
        }
        
        //reset image
        imageView.image = nil;
        
        NSString *colour = [self.coloursArray objectAtIndex:index];
        
        if ([colour isEqualToString:@"Black"]) {
            [self setBlackImageBorder:imageView];
        }
        else{
            [self setImageBorder:imageView];
        }
        
        if ([colour isEqualToString:@"Camo"]) {
            [imageView setImage:[UIImage imageNamed:@"camoColour"]];
        }
        else{
            imageView.image = nil;
            imageView.backgroundColor = [self.colourValuesArray objectAtIndex:index];
        }
        
        if ([self.chosenColourArray containsObject:colour]) {
            
            if ([colour isEqualToString:@"Black"]) {
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
    else if (swipeView == self.locationSwipeView){
        //continents swipe view
        UILabel *messageLabel = nil;
        
        if (view == nil)
        {
            view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100,35)];
            messageLabel = [[UILabel alloc]initWithFrame:CGRectMake(5,0, 90, 35)];
            messageLabel.layer.cornerRadius = 6;
            messageLabel.layer.masksToBounds = YES;
            messageLabel.textAlignment = NSTextAlignmentCenter;
            [messageLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:13]];
            messageLabel.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
            
            [view setAlpha:1.0];
            [view addSubview:messageLabel];
        }
        else
        {
            messageLabel = [[view subviews] lastObject];
        }
        
        messageLabel.text = [self.continentsArray objectAtIndex:index];
        
        if ([self.chosenContinentsArray containsObject: messageLabel.text]) {
            //selected
            messageLabel.backgroundColor = [UIColor whiteColor];
        }
        else{
            messageLabel.backgroundColor = [UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0];
        }
        
        return view;
    }
    else{
        //sizes swipe view
        UILabel *messageLabel = nil;
        
        if (view == nil)
        {
            view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80,35)];
            messageLabel = [[UILabel alloc]initWithFrame:CGRectMake(5,0, 70, 35)];
            messageLabel.layer.cornerRadius = 6;
            messageLabel.layer.masksToBounds = YES;
            messageLabel.textAlignment = NSTextAlignmentCenter;
            [messageLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:13]];
            messageLabel.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
            
            [view setAlpha:1.0];
            [view addSubview:messageLabel];
        }
        else
        {
            messageLabel = [[view subviews] lastObject];
        }
        
        if ([self.sizeMode isEqualToString:@"clothing"]) {
            messageLabel.text = [self.sizeLabels objectAtIndex:index];
        }
        else{
            messageLabel.text = [self.shoesArray objectAtIndex:index];
        }
        
        if ([self.chosenSizesArray containsObject: messageLabel.text]) {
            //selected
            messageLabel.backgroundColor = [UIColor whiteColor];
        }
        else{
            messageLabel.backgroundColor = [UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0];
        }
        
        return view;
    }
}

-(void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView{
    
    if (swipeView == self.brandSwipeView || swipeView == self.colourSwipeView || swipeView == self.categorySwipeView) {
        //do nothing
    }
    else{
        //reset all to grey and highlight if needed
        NSArray *visible = self.swipeView.visibleItemViews;
        
        for (UIView *item in visible) {
            UILabel *messageLabel = [[item subviews] lastObject];
            if ([self.chosenSizesArray containsObject: messageLabel.text]) {
                //selected
                messageLabel.backgroundColor = [UIColor whiteColor];
            }
            else{
                messageLabel.backgroundColor = [UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0];
            }
        }
    }
}
-(void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index{

    if (swipeView == self.brandSwipeView) {
        UIImageView *imageView = [[[self.brandSwipeView itemViewAtIndex:index] subviews] lastObject];
        UILabel *brandLabel = [[[self.brandSwipeView itemViewAtIndex:index] subviews] objectAtIndex:0];
        
        NSString *selected = [self.brandAcronymArray objectAtIndex:index];
        
        //enable/disable image & label
        if ([self.chosenBrandsArray containsObject:selected]) {
            //deselect
            [brandLabel setTextColor:[UIColor lightGrayColor]];
            [imageView setImage:[UIImage imageNamed:self.brandImagesArray[index]]];
            
            [self.filtersArray removeObject:selected];
            [self.chosenBrandsArray removeObject:selected];
            
            //remove additional keywords for specific brands
            if ([selected isEqualToString:@"offwhite"]) {
                [self.chosenBrandsArray removeObject:@"off-white"];
            }
            else if ([selected isEqualToString:@"stoneisland"]) {
                [self.chosenBrandsArray removeObject:@"stone"];
                [self.chosenBrandsArray removeObject:@"island"];
            }
            else if ([selected isEqualToString:@"vlone"]) {
                [self.filtersArray removeObject:@"vlone"];
                [self.chosenBrandsArray removeObject:@"vlone"];
                [self.chosenBrandsArray removeObject:@"v-lone"];
            }
            else if ([selected isEqualToString:@"assc"]) {
                [self.chosenBrandsArray removeObject:@"assc"];
                [self.chosenBrandsArray removeObject:@"antisocialclub"];
                [self.chosenBrandsArray removeObject:@"anti"];
                [self.chosenBrandsArray removeObject:@"social"];
                [self.chosenBrandsArray removeObject:@"club"];
            }
            else if ([selected isEqualToString:@"cdg"]) {
                [self.chosenBrandsArray removeObject:@"comme"];
                [self.chosenBrandsArray removeObject:@"des"];
                [self.chosenBrandsArray removeObject:@"garcons"];
            }
            else if ([selected isEqualToString:@"pf"]) {
                [self.chosenBrandsArray removeObject:@"places"];
                [self.chosenBrandsArray removeObject:@"faces"];
            }
            else if ([selected isEqualToString:@"raf"]) {
                [self.chosenBrandsArray removeObject:@"simons"];
            }
            else if ([selected isEqualToString:@"lv"]) {
                [self.chosenBrandsArray removeObject:@"louis"];
                [self.chosenBrandsArray removeObject:@"vuitton"];
                [self.chosenBrandsArray removeObject:@"vutton"];
            }
            else if ([selected isEqualToString:@"jordan"]) {
                [self.chosenBrandsArray removeObject:@"jordans"];
            }
        }
        else{
            //select
            [brandLabel setTextColor:[UIColor whiteColor]];
            [imageView setImage:[UIImage imageNamed:self.brandSelectedImagesArray[index]]];
            
            [self.filtersArray addObject:selected];
            [self.chosenBrandsArray addObject:selected];
            
            //add additional keywords for specific brands
            if ([selected isEqualToString:@"offwhite"]) {
                [self.chosenBrandsArray addObject:@"off-white"];
            }
            else if ([selected isEqualToString:@"stoneisland"]) {
                [self.chosenBrandsArray addObject:@"stone"];
                [self.chosenBrandsArray addObject:@"island"];
            }
            else if ([selected isEqualToString:@"vlone"]) {
                [self.filtersArray addObject:@"vlone"];
                [self.chosenBrandsArray addObject:@"vlone"];
                [self.chosenBrandsArray addObject:@"v-lone"];
            }
            else if ([selected isEqualToString:@"assc"]) {
                [self.chosenBrandsArray addObject:@"assc"];
                [self.chosenBrandsArray addObject:@"antisocialclub"];
                [self.chosenBrandsArray addObject:@"anti"];
                [self.chosenBrandsArray addObject:@"social"];
                [self.chosenBrandsArray addObject:@"club"];
            }
            else if ([selected isEqualToString:@"cdg"]) {
                [self.chosenBrandsArray addObject:@"comme"];
                [self.chosenBrandsArray addObject:@"des"];
                [self.chosenBrandsArray addObject:@"garcons"];
            }
            else if ([selected isEqualToString:@"pf"]) {
                [self.chosenBrandsArray addObject:@"places"];
                [self.chosenBrandsArray addObject:@"faces"];
            }
            else if ([selected isEqualToString:@"raf"]) {
                [self.chosenBrandsArray addObject:@"simons"];
            }
            else if ([selected isEqualToString:@"lv"]) {
                [self.chosenBrandsArray addObject:@"louis"];
                [self.chosenBrandsArray addObject:@"vuitton"];
                [self.chosenBrandsArray addObject:@"vutton"];
            }
            else if ([selected isEqualToString:@"jordan"]) {
                [self.chosenBrandsArray addObject:@"jordans"];
            }
        }
    }
    else if (swipeView == self.categorySwipeView) {
        UIImageView *imageView = [[[self.categorySwipeView itemViewAtIndex:index] subviews] lastObject];
        UILabel *catLabel = [[[self.categorySwipeView itemViewAtIndex:index] subviews] objectAtIndex:0];
        
        //deselect all categories
        
        if ([self.chosenCategory isEqualToString:catLabel.text]) {
            //deselect the one tapped
            [catLabel setTextColor:[UIColor lightGrayColor]];
            [imageView setImage:[UIImage imageNamed:self.categoryImagesArray[index]]];
            
            [self.filtersArray removeObject:catLabel.text];
            self.chosenCategory = @"";
            
            if ([catLabel.text isEqualToString:@"Accessories"] || [catLabel.text isEqualToString:@"Proxy"]) {
                //setup clothing sizes so can just tap one
                [self setupClothingSizes];
            }
        }
        else{
            //select as new chosen category
            
            //first deselect previous if exists
            if (![self.chosenCategory isEqualToString:@""]) {
                UIImageView *imageView1 = [[[self.categorySwipeView itemViewAtIndex:[self.categoryArray indexOfObject:self.chosenCategory]] subviews] lastObject];
                UILabel *catLabel1 = [[[self.categorySwipeView itemViewAtIndex:[self.categoryArray indexOfObject:self.chosenCategory]] subviews] objectAtIndex:0];
                
                [catLabel1 setTextColor:[UIColor lightGrayColor]];
                [imageView1 setImage:[UIImage imageNamed:[self.categoryImagesArray objectAtIndex:[self.categoryArray indexOfObject:self.chosenCategory]]]];
                
                [self.filtersArray removeObject:self.chosenCategory];

            }
            
            //select new category
            [catLabel setTextColor:[UIColor whiteColor]];
            [imageView setImage:[UIImage imageNamed:self.categorySelectedImagesArray[index]]];
            
            [self.filtersArray addObject:catLabel.text];
            self.chosenCategory = catLabel.text;
            
            if ([catLabel.text isEqualToString:@"Footwear"]) {
                [self setupFootwearSizes];
            }
            else if ([catLabel.text isEqualToString:@"Tops"] || [catLabel.text isEqualToString:@"Bottoms"] || [catLabel.text isEqualToString:@"Outerwear"]) {
                [self setupClothingSizes];
            }
            else if ([catLabel.text isEqualToString:@"Accessories"] || [catLabel.text isEqualToString:@"Proxy"]) {
                [self setupAccessories];
            }
            
        }
    }
    else if (swipeView == self.colourSwipeView){
        //get the colour
        NSString *colour = [self.coloursArray objectAtIndex:index];
//        NSArray *visible = self.colourSwipeView.visibleItemViews;
        
        if ([self.chosenColourArray containsObject:colour]) {
            
            //deselect and set all as unselected
            [self.chosenColourArray removeObject:colour];
            [self.filtersArray removeObject:colour];
            
            UIView *mainView = [self.colourSwipeView itemViewAtIndex:index];
            UIView *innerView = [[mainView subviews] lastObject];
            [self setNormalBorder:innerView];
            
//            for (UIView *item in visible) {
//                UIView *innerView = [[item subviews] lastObject];
//                [self setNormalBorder:innerView];
//            }
        }
        else{
            //select as new chosen colour
            [self.chosenColourArray addObject:colour];
            [self.filtersArray addObject:colour];
            
            //set all borders to normal
//            for (UIView *item in visible) {
//                
//                UIView *innerView = [[item subviews] lastObject];
//                [self setNormalBorder:innerView];
//            }
            
            //put border on selected colour
            UIView *mainView = [self.colourSwipeView itemViewAtIndex:index];
            UIView *innerView = [[mainView subviews] lastObject];
            
            if ([self.chosenColourArray containsObject:colour]) {
                //selected
                if ([colour isEqualToString:@"Black"]) {
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
    else if (swipeView == self.locationSwipeView){
        //highlight
        UILabel *messageLabel = [[[self.locationSwipeView itemViewAtIndex:index] subviews] lastObject];
        
        if ([self.chosenContinentsArray containsObject: messageLabel.text]) {
            //deselect
            [self.filtersArray removeObject:messageLabel.text];
            [self.chosenContinentsArray removeObject:messageLabel.text];
            [self updateTitle];
            messageLabel.backgroundColor = [UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0];
        }
        else{

            //if selects around me, deselect all others
            if ([messageLabel.text isEqualToString:@"Around me"] || [self.chosenContinentsArray containsObject:@"Around me"]) {
                for (NSString *continent in self.chosenContinentsArray) {
                    if ([self.filtersArray containsObject:continent]) {
                        [self.filtersArray removeObject:continent];
                    }
                }
                
                [self.chosenContinentsArray removeAllObjects];
            }
            
            [self.filtersArray addObject:messageLabel.text];
            [self.chosenContinentsArray addObject:messageLabel.text];
            
            [self.locationSwipeView reloadData];
        }

    }
    else{
        //highlight
        UILabel *messageLabel = [[[self.swipeView itemViewAtIndex:index] subviews] lastObject];
        
        if ([self.chosenSizesArray containsObject: messageLabel.text]) {
            //deselect
            [self.filtersArray removeObject:messageLabel.text];
            [self.chosenSizesArray removeObject:messageLabel.text];
            
            //        self.lastSelected = @"";
            [self updateTitle];
            messageLabel.backgroundColor = [UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0];
        }
        else{
            //if user hasn't selected a category then check what mode swipe view is in and add to filters array
            if (![self.filtersArray containsObject:@"Tops"] && ![self.filtersArray containsObject:@"Bottoms"] && ![self.filtersArray containsObject:@"Outerwear"] && ![self.filtersArray containsObject:@"Footwear"] && ![self.filtersArray containsObject:@"Accessories"] && ![self.filtersArray containsObject:@"Proxy"]) {
                //no cat has been previously selected but user has tapped a size, can presume its a clothing size!
                //so select clothing category too
                
                [self.filtersArray addObject:@"Tops"];
                self.chosenCategory = @"Tops";
                [self.categorySwipeView reloadData];
                
                //scroll to Tops category icon so its deffs seen
                NSUInteger selectedIndex = [self.categoryArray indexOfObject:self.chosenCategory];
                [self.categorySwipeView scrollToItemAtIndex:selectedIndex duration:0.2];
                
                [self.menButton setEnabled:NO];
                [self.womenButton setEnabled:NO];
                
                [self.filtersArray removeObject:@"male"];
                [self.filtersArray removeObject:@"female"];
                
            }
            
            //remove old last selected from filterArray & add new selected size
            //        [self.filtersArray removeObject:self.lastSelected];
            
            if (self.chosenSizesArray.count < 5) { //limit user to 5 sizes at once
                [self.filtersArray addObject:messageLabel.text];
                [self.chosenSizesArray addObject:messageLabel.text];
                
                //select
                messageLabel.backgroundColor = [UIColor whiteColor];
            }
        }
    }
    [self updateTitle];
}

-(NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView{
    
    if (swipeView == self.brandSwipeView) {
        return self.brandArray.count;
    }
    else if (swipeView == self.categorySwipeView){
        return self.categoryArray.count;
    }
    else if (swipeView == self.colourSwipeView){
        return self.coloursArray.count;
    }
    else if (swipeView == self.locationSwipeView){
        return self.continentsArray.count;
    }
    else{
        if ([self.sizeMode isEqualToString:@"clothing"]) {
            return self.sizeLabels.count;
        }
        else{
            return self.shoesArray.count;
        }
    }
}

-(void)setupFootwearSizes{
    [self.menButton setEnabled:YES];
    [self.womenButton setEnabled:YES];
    
    self.sizeMode = @"footwear";
    self.swipeView.alpha = 1.0;
    self.swipeView.userInteractionEnabled = YES;
    
//    [self.filtersArray removeObject:self.lastSelected];
    [self.filtersArray removeObjectsInArray:self.chosenSizesArray];
    [self.chosenSizesArray removeAllObjects];
    
    self.lastSelected = @"";
    [self updateTitle];

    [self.swipeView reloadData];
    
    //swipe to their size
    NSArray *shoeSizeArray = [[PFUser currentUser]objectForKey:@"UKShoeSizeArray"];
    if (shoeSizeArray.count > 0) {
        NSUInteger firstSize = [self.shoesArray indexOfObject:shoeSizeArray[0]];
        self.swipeView.currentItemIndex = firstSize;
    }
}

-(void)setupClothingSizes{
    [self.filtersArray removeObject:@"male"];
    [self.filtersArray removeObject:@"female"];

    [self.menButton setSelected:NO];
    [self.womenButton setSelected:NO];
    
    [self.menButton setEnabled:NO];
    [self.womenButton setEnabled:NO];
    
    self.sizeMode = @"clothing";
    self.swipeView.alpha = 1.0;
    self.swipeView.userInteractionEnabled = YES;
    
//    [self.filtersArray removeObject:self.lastSelected];
    [self.filtersArray removeObjectsInArray:self.chosenSizesArray];
    [self.chosenSizesArray removeAllObjects];
    
    self.lastSelected = @"";
    [self updateTitle];
    
    [self.swipeView reloadData];
}

-(void)setupAccessories{
    [self.filtersArray removeObject:@"male"];
    [self.filtersArray removeObject:@"female"];
    
    [self.menButton setSelected:NO];
    [self.womenButton setSelected:NO];
    
    [self.menButton setEnabled:NO];
    [self.womenButton setEnabled:NO];
    
    self.sizeMode = @"accessories";
    
//    [self.filtersArray removeObject:self.lastSelected];
    [self.filtersArray removeObjectsInArray:self.chosenSizesArray];
    [self.chosenSizesArray removeAllObjects];
    
    
    
    self.lastSelected = @"";
    [self updateTitle];

    [self.swipeView reloadData];
    self.swipeView.userInteractionEnabled = NO;
    self.swipeView.alpha = 0.5;
}

#pragma mark - header

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return self.titleCell;
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = 15;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [imageView.layer setBorderWidth: 0.0];
}
-(void)setSelectedBorder:(UIView *)view withColor:(UIColor *)color{
    view.layer.cornerRadius = 20;
    view.layer.masksToBounds = YES;
    view.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    view.contentMode = UIViewContentModeScaleAspectFill;
    [view.layer setBorderColor: [color CGColor]];
    [view.layer setBorderWidth: 1.0];
}
-(void)setNormalBorder:(UIView *)view{
    view.layer.cornerRadius = 20;
    view.layer.masksToBounds = YES;
    view.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    view.contentMode = UIViewContentModeScaleAspectFill;
    [view.layer setBorderWidth: 0.0];
}
-(void)setBlackImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = 15;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [imageView.layer setBorderColor: [[UIColor lightGrayColor] CGColor]];
    [imageView.layer setBorderWidth: 1.0];
}

-(void)priceValueChanged{
    [self updateSliderLabels];
}
- (void) updateSliderLabels
{
    if (self.doubleSlider.lowerValue == 0 && self.doubleSlider.upperValue == 1000) {
        [self.filtersArray removeObject:@"price"];
        [self.doubleSlider setTintColor:[UIColor lightGrayColor]];

        self.sliderLabel.text = @"Any";
        self.sliderLabel.textColor = [UIColor lightGrayColor];
    }
    else if (self.doubleSlider.lowerValue == 0 && self.doubleSlider.upperValue != 1000){
        if (![self.filtersArray containsObject:@"price"]) {
            [self.filtersArray addObject:@"price"];
        }
        [self.doubleSlider setTintColor:[UIColor whiteColor]];
        self.sliderLabel.textColor = [UIColor whiteColor];

        self.sliderLabel.text = [NSString stringWithFormat:@"up to %@%.0f",self.currencySymbol,self.doubleSlider.upperValue];
    }
    else if (self.doubleSlider.lowerValue != 0 && self.doubleSlider.upperValue == 1000){
        if (![self.filtersArray containsObject:@"price"]) {
            [self.filtersArray addObject:@"price"];
        }
        
        [self.doubleSlider setTintColor:[UIColor whiteColor]];
        self.sliderLabel.textColor = [UIColor whiteColor];

        self.sliderLabel.text = [NSString stringWithFormat:@"%@%.0f+",self.currencySymbol,self.doubleSlider.lowerValue];
    }
    else{
        if (![self.filtersArray containsObject:@"price"]) {
            [self.filtersArray addObject:@"price"];
        }
        
        [self.doubleSlider setTintColor:[UIColor whiteColor]];
        self.sliderLabel.textColor = [UIColor whiteColor];

        self.sliderLabel.text = [NSString stringWithFormat:@"%@%.0f to %@%.0f", self.currencySymbol,self.doubleSlider.lowerValue,self.currencySymbol,self.doubleSlider.upperValue];
    }
    
    [self updateTitle];
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

@end
