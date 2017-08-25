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
    
    self.brandArray = [NSArray arrayWithObjects:@"Supreme", @"Palace", @"Bape",@"Patta",@"Off White",@"Gosha", @"Stussy",@"Kith", @"Adidas", @"Stone Island", @"Nike", @"Ralph Lauren", @"Gucci",@"Vetements",@"Balenciaga",@"Vlone",@"ASSC",@"CDG",@"P+F",@"Raf Simons",nil];
    
    self.brandAcronymArray = [NSArray arrayWithObjects:@"supreme", @"palace", @"bape",@"patta",@"offwhite",@"gosha", @"stussy",@"kith",@"adidas", @"stoneisland", @"nike", @"ralph", @"gucci",@"vetements",@"balen",@"vlone",@"assc",@"cdg",@"pf",@"raf",nil];
    
    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.priceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.conditionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.categoryCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.sizeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.applyCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.distanceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.spaceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.brandCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.colourCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
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

    if (self.sendArray) {
        [self.filtersArray addObjectsFromArray:self.sendArray];
        
        //set up previous filters
        if (self.filtersArray.count > 0) {
            
            self.titleLabel.text = [NSString stringWithFormat:@"F I L T E R S  %lu", self.filtersArray.count];
            
            //check for brands
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
            if ([self.filtersArray containsObject:@"deadstock"]){
                [self.deadstockButton setSelected:YES];
            }
            if ([self.filtersArray containsObject:@"aroundMe"]) {
                [self.distanceButton setSelected:YES];
            }
            if ([self.filtersArray containsObject:@"supreme"]) {
                [self.chosenBrandsArray addObject:@"supreme"];
            }
            if ([self.filtersArray containsObject:@"palace"]) {
                [self.chosenBrandsArray addObject:@"palace"];
            }
            if ([self.filtersArray containsObject:@"bape"]) {
                [self.chosenBrandsArray addObject:@"bape"];
            }
            if ([self.filtersArray containsObject:@"ralph"]) {
                [self.chosenBrandsArray addObject:@"ralph"];
            }
            if ([self.filtersArray containsObject:@"nike"]) {
                [self.chosenBrandsArray addObject:@"nike"];
            }
            if ([self.filtersArray containsObject:@"stoneisland"]) {
                [self.chosenBrandsArray addObject:@"stoneisland"];
            }
            if ([self.filtersArray containsObject:@"adidas"]) {
                [self.chosenBrandsArray addObject:@"adidas"];
            }
            if ([self.filtersArray containsObject:@"patta"]) {
                [self.chosenBrandsArray addObject:@"patta"];
            }
            if ([self.filtersArray containsObject:@"gosha"]) {
                [self.chosenBrandsArray addObject:@"gosha"];
            }
            if ([self.filtersArray containsObject:@"stussy"]) {
                [self.chosenBrandsArray addObject:@"stussy"];
            }
            if ([self.filtersArray containsObject:@"kith"]) {
                [self.chosenBrandsArray addObject:@"kith"];
            }
            if ([self.filtersArray containsObject:@"gucci"]) {
                [self.chosenBrandsArray addObject:@"gucci"];
            }
            if ([self.filtersArray containsObject:@"offwhite"]) {
                [self.chosenBrandsArray addObject:@"offwhite"];
            }
            if ([self.filtersArray containsObject:@"vetements"]) {
                [self.chosenBrandsArray addObject:@"vetements"];
            }
            if ([self.filtersArray containsObject:@"balen"]) {
                [self.chosenBrandsArray addObject:@"balen"];
            }
            if ([self.filtersArray containsObject:@"vlone"]) {
                [self.chosenBrandsArray addObject:@"vlone"];
            }
            if ([self.filtersArray containsObject:@"assc"]) {
                [self.chosenBrandsArray addObject:@"assc"];
            }
            if ([self.filtersArray containsObject:@"cdg"]) {
                [self.chosenBrandsArray addObject:@"cdg"];
            }
            if ([self.filtersArray containsObject:@"pf"]) {
                [self.chosenBrandsArray addObject:@"pf"];
            }
            if ([self.filtersArray containsObject:@"raf"]) {
                [self.chosenBrandsArray addObject:@"raf"];
            }
            
            [self.brandSwipeView reloadData];
            
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
            
            if ([self.filtersArray containsObject:@"clothing"]){
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
            else if ([self.filtersArray containsObject:@"footwear"]){
                
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
            else if ([self.filtersArray containsObject:@"accessory"]){
                [self.accessoryButton setSelected:YES];
                [self setupFootwearSizes];
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
                return 120;
            }
            else if (indexPath.row == 3){
                return 178;
            }
            else if (indexPath.row == 4){
                return 120;
            }
            else if (indexPath.row == 5){
                return 120;
            }
            else if (indexPath.row == 6){
                return 120;
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
                return 120;
            }
            else if (indexPath.row == 3){
                return 178;
            }
            else if (indexPath.row == 4){
                return 120;
            }
            else if (indexPath.row == 5){
                return 120;
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
                return 120;
            }
            else if (indexPath.row == 2){
                return 178;
            }
            else if (indexPath.row == 3){
                return 120;
            }
            else if (indexPath.row == 4){
                return 220;
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
                return self.categoryCell;
            }
            else if (indexPath.row == 3){
                return self.sizeCell;
            }
            else if (indexPath.row == 4){
                return self.conditionCell;
            }
            else if (indexPath.row == 5){
                return self.priceCell;
            }
            else if (indexPath.row == 6){
                return self.distanceCell;
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
                return self.categoryCell;
            }
            else if (indexPath.row == 3){
                return self.sizeCell;
            }
            else if (indexPath.row == 4){
                return self.conditionCell;
            }
            else if (indexPath.row == 5){
                return self.priceCell;
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
                return self.categoryCell;
            }
            else if (indexPath.row == 2){
                return self.sizeCell;
            }
            else if (indexPath.row == 3){
                return self.conditionCell;
            }
            else if (indexPath.row == 4){
                return self.distanceCell;
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
        self.titleLabel.text = [NSString stringWithFormat:@"F I L T E R S  %lu", self.filtersArray.count];
    }
    else{
        self.titleLabel.text = @"F I L T E R S";
        
    }
}
- (IBAction)dismissPressed:(id)sender {
    
    //if tap cross and just pressed clear then we should clear, otherwise forget the changes - revert back to filters selected when last hit apply
    if (self.filtersArray.count == 0 && self.sendArray.count != 0) {
        [self.delegate filtersReturned:self.filtersArray withSizesArray:self.chosenSizesArray andBrandsArray:self.chosenBrandsArray andColours:self.chosenColourArray];
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
    [self.deadstockButton setSelected:NO];

    [self.clothingButton setSelected:NO];
    [self.accessoryButton setSelected:NO];
    [self.footButton setSelected:NO];
    
    [self.menButton setSelected:NO];
    [self.womenButton setSelected:NO];
    
    [self.distanceButton setSelected:NO];
    
    [self.filtersArray removeAllObjects];
    [self.chosenBrandsArray removeAllObjects];
    [self.chosenSizesArray removeAllObjects];
    [self.chosenColourArray removeAllObjects];
    
    self.lastSelected = @"";
    [self.swipeView reloadData];
    [self.brandSwipeView reloadData];
    [self.colourSwipeView reloadData];
    
    [self updateTitle];
}
- (IBAction)hightolowPressed:(id)sender {
    if(self.hightolowButton.selected == YES){
        [self.hightolowButton setSelected:NO];
        [self.filtersArray removeObject:@"hightolow"];
    }
    else{
        [Answers logCustomEventWithName:@"Filters enabled"
                       customAttributes:@{
                                          @"filter":@"hightolow"
                                          }];
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
        [Answers logCustomEventWithName:@"Filters enabled"
                       customAttributes:@{
                                          @"filter":@"lowtohigh"
                                          }];
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
        [Answers logCustomEventWithName:@"Filters enabled"
                       customAttributes:@{
                                          @"filter":@"new"
                                          }];
        [self.conditionNewButton setSelected:YES];
        [self.filtersArray addObject:@"new"];
        [self.usedButton setSelected:NO];
        [self.filtersArray removeObject:@"used"];
        [self.deadstockButton setSelected:NO];
        [self.filtersArray removeObject:@"deadstock"];
    }
    [self updateTitle];
}


- (IBAction)usedPressed:(id)sender {
    if(self.usedButton.selected == YES){
        [self.usedButton setSelected:NO];
        [self.filtersArray removeObject:@"used"];
    }
    else{
        [Answers logCustomEventWithName:@"Filters enabled"
                       customAttributes:@{
                                          @"filter":@"used"
                                          }];
        [self.usedButton setSelected:YES];
        [self.filtersArray addObject:@"used"];
        [self.conditionNewButton setSelected:NO];
        [self.filtersArray removeObject:@"deadstock"];
        [self.deadstockButton setSelected:NO];
        
        [self.filtersArray removeObject:@"new"];
    }
    [self updateTitle];
}
- (IBAction)deadstockPressed:(id)sender {
    if(self.deadstockButton.selected == YES){
        [self.deadstockButton setSelected:NO];
        [self.filtersArray removeObject:@"deadstock"];
    }
    else{
        [Answers logCustomEventWithName:@"Filters enabled"
                       customAttributes:@{
                                          @"filter":@"deadstock"
                                          }];
        [self.deadstockButton setSelected:YES];
        [self.filtersArray addObject:@"deadstock"];
        [self.conditionNewButton setSelected:NO];
        [self.filtersArray removeObject:@"new"];
        [self.usedButton setSelected:NO];
        [self.filtersArray removeObject:@"used"];
    }
    [self updateTitle];
}

- (IBAction)clothingPressed:(id)sender {
    if(self.clothingButton.selected == YES){
        [self.clothingButton setSelected:NO];
        [self.filtersArray removeObject:@"clothing"];
    }
    else{
        [Answers logCustomEventWithName:@"Filters enabled"
                       customAttributes:@{
                                          @"filter":@"clothing"
                                          }];
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
        [Answers logCustomEventWithName:@"Filters enabled"
                       customAttributes:@{
                                          @"filter":@"footwear"
                                          }];
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
        [Answers logCustomEventWithName:@"Filters enabled"
                       customAttributes:@{
                                          @"filter":@"accessories"
                                          }];
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
    
    [self.delegate filtersReturned:noduplicates withSizesArray:self.chosenSizesArray andBrandsArray:self.chosenBrandsArray andColours:self.chosenColourArray];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)menPressed:(id)sender {
    if (self.menButton.selected == YES) {
        [self.menButton setSelected:NO];
        [self.filtersArray removeObject:@"male"];
    }
    else{
        [Answers logCustomEventWithName:@"Filters enabled"
                       customAttributes:@{
                                          @"filter":@"men"
                                          }];
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
        [Answers logCustomEventWithName:@"Filters enabled"
                       customAttributes:@{
                                          @"filter":@"women"
                                          }];
        
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
        [Answers logCustomEventWithName:@"Filters enabled"
                       customAttributes:@{
                                          @"filter":@"aroundme"
                                          }];
        [self.distanceButton setSelected:YES];
        [self.filtersArray addObject:@"aroundMe"];
    }
    [self updateTitle];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self.applyButton removeFromSuperview];
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
        
        if (index == 0) {

            //supreme
            if ([self.chosenBrandsArray containsObject:@"supreme"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"supremeSelected1"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"supremeNormal1"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 1){
            //palace
            if ([self.chosenBrandsArray containsObject:@"palace"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"palaceSelected2"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"palaceNormal2"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 3){
            //patta
            if ([self.chosenBrandsArray containsObject:@"patta"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"pattaSelected2"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"pattaNormal2"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 4){
            //offwhite
            if ([self.chosenBrandsArray containsObject:@"offwhite"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"offWhiteSelected1"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"offWhiteNormal1"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 5){
            //gosha
            if ([self.chosenBrandsArray containsObject:@"gosha"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"goshaSelected1"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"goshaNormal1"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 6){
            //stussy
            if ([self.chosenBrandsArray containsObject:@"stussy"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"stussySelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"stussyNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 7){
            //kith
            if ([self.chosenBrandsArray containsObject:@"kith"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"kithSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"kithNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 2){
            //bape
            if ([self.chosenBrandsArray containsObject:@"bape"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"bapeSelected2"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"bapeNormal3"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 8){
            //adidas
            if ([self.chosenBrandsArray containsObject:@"adidas"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"adidasSelected2"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"adidasNormal2"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 9){
            //Stone Island
            if ([self.chosenBrandsArray containsObject:@"stoneisland"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"stoneySelected2"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"stoneyNormal2"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 10){
            //Nike
            if ([self.chosenBrandsArray containsObject:@"nike"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"nikeSelected2"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"nikeNormal2"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 11){
            //Ralph Lauren
            if ([self.chosenBrandsArray containsObject:@"ralph"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"ralphSelected2"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"ralphNormal2"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 12){
            //Gucci
            if ([self.chosenBrandsArray containsObject:@"gucci"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"gucciSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"gucciNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 13){
            //Vetements
            if ([self.chosenBrandsArray containsObject:@"vetements"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"veteSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"veteNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 14){
            //Balenciaga
            if ([self.chosenBrandsArray containsObject:@"balen"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"balenSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"balenNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 15){
            //Vlone
            if ([self.chosenBrandsArray containsObject:@"vlone"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"vloneSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"vloneNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 16){
            //ASSC
            if ([self.chosenBrandsArray containsObject:@"assc"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"asscSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"asscNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 17){
            //CDG
            if ([self.chosenBrandsArray containsObject:@"cdg"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"cdgSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"cdgNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 18){
            //Places+Faces
            if ([self.chosenBrandsArray containsObject:@"pf"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"placesSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"placesNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else if(index == 19){
            //Raf Simons
            if ([self.chosenBrandsArray containsObject:@"raf"]) {
                //selected img
                [imageView setImage:[UIImage imageNamed:@"rafSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
            else{
                //default img
                [imageView setImage:[UIImage imageNamed:@"rafNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
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
    
    if (swipeView == self.brandSwipeView || swipeView == self.colourSwipeView) {
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
        
        if (index == 0) {
            //supreme
            if ([self.chosenBrandsArray containsObject:@"supreme"]) {
                //deselect supreme
                [self.filtersArray removeObject:@"supreme"];
                [self.chosenBrandsArray removeObject:@"supreme"];
                [imageView setImage:[UIImage imageNamed:@"supremeNormal1"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"supreme"];
                [self.chosenBrandsArray addObject:@"supreme"];
                [imageView setImage:[UIImage imageNamed:@"supremeSelected1"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 1){
            //palace
            if ([self.chosenBrandsArray containsObject:@"palace"]) {
                //deselect
                [self.filtersArray removeObject:@"palace"];
                [self.chosenBrandsArray removeObject:@"palace"];
                [imageView setImage:[UIImage imageNamed:@"palaceNormal2"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"palace"];
                [self.chosenBrandsArray addObject:@"palace"];
                [imageView setImage:[UIImage imageNamed:@"palaceSelected2"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 2){
            //bape
            if ([self.chosenBrandsArray containsObject:@"bape"]) {
                //deselect
                [self.filtersArray removeObject:@"bape"];
                [self.chosenBrandsArray removeObject:@"bape"];
                [imageView setImage:[UIImage imageNamed:@"bapeNormal3"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"bape"];
                [self.chosenBrandsArray addObject:@"bape"];
                [imageView setImage:[UIImage imageNamed:@"bapeSelected2"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 3){
            //patta
            if ([self.chosenBrandsArray containsObject:@"patta"]) {
                //deselect
                [self.filtersArray removeObject:@"patta"];
                [self.chosenBrandsArray removeObject:@"patta"];
                [imageView setImage:[UIImage imageNamed:@"pattaNormal2"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"patta"];
                [self.chosenBrandsArray addObject:@"patta"];
                [imageView setImage:[UIImage imageNamed:@"pattaSelected2"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 4){
            //offwhite
            if ([self.chosenBrandsArray containsObject:@"offwhite"]) {
                //deselect
                [self.filtersArray removeObject:@"offwhite"];
                [self.chosenBrandsArray removeObject:@"offwhite"];
                [self.chosenBrandsArray removeObject:@"off-white"];
                [imageView setImage:[UIImage imageNamed:@"offWhiteNormal1"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"offwhite"];
                [self.chosenBrandsArray addObject:@"offwhite"];
                [self.chosenBrandsArray addObject:@"off-white"];
                [imageView setImage:[UIImage imageNamed:@"offWhiteSelected1"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 5){
            //gosha
            if ([self.chosenBrandsArray containsObject:@"gosha"]) {
                //deselect
                [self.filtersArray removeObject:@"gosha"];
                [self.chosenBrandsArray removeObject:@"gosha"];
                [imageView setImage:[UIImage imageNamed:@"goshaNormal1"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"gosha"];
                [self.chosenBrandsArray addObject:@"gosha"];
                [imageView setImage:[UIImage imageNamed:@"goshaSelected1"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 6){
            //stussy
            if ([self.chosenBrandsArray containsObject:@"stussy"]) {
                //deselect
                [self.filtersArray removeObject:@"stussy"];
                [self.chosenBrandsArray removeObject:@"stussy"];
                [imageView setImage:[UIImage imageNamed:@"stussyNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"stussy"];
                [self.chosenBrandsArray addObject:@"stussy"];
                [imageView setImage:[UIImage imageNamed:@"stussySelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 7){
            //kith
            if ([self.chosenBrandsArray containsObject:@"kith"]) {
                //deselect
                [self.filtersArray removeObject:@"kith"];
                [self.chosenBrandsArray removeObject:@"kith"];
                [imageView setImage:[UIImage imageNamed:@"kithNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"kith"];
                [self.chosenBrandsArray addObject:@"kith"];
                [imageView setImage:[UIImage imageNamed:@"kithSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 8){
            //adidas
            if ([self.chosenBrandsArray containsObject:@"adidas"]) {
                //deselect
                [self.filtersArray removeObject:@"adidas"];
                [self.chosenBrandsArray removeObject:@"adidas"];
                [imageView setImage:[UIImage imageNamed:@"adidasNormal2"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"adidas"];
                [self.chosenBrandsArray addObject:@"adidas"];
                [imageView setImage:[UIImage imageNamed:@"adidasSelected2"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 9){
            //Stone Island
            if ([self.chosenBrandsArray containsObject:@"stoneisland"]) {
                //deselect
                [self.filtersArray removeObject:@"stoneisland"];
                
                [self.chosenBrandsArray removeObject:@"stoneisland"];
                [self.chosenBrandsArray removeObject:@"stone"];
                [self.chosenBrandsArray removeObject:@"island"];
                
                [imageView setImage:[UIImage imageNamed:@"stoneyNormal2"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"stoneisland"];
                [self.chosenBrandsArray addObject:@"stoneisland"];
                [self.chosenBrandsArray addObject:@"stone"];
                [self.chosenBrandsArray addObject:@"island"];
                
                [imageView setImage:[UIImage imageNamed:@"stoneySelected2"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 10){
            //Nike
            if ([self.chosenBrandsArray containsObject:@"nike"]) {
                //deselect
                [self.filtersArray removeObject:@"nike"];
                [self.chosenBrandsArray removeObject:@"nike"];
                [imageView setImage:[UIImage imageNamed:@"nikeNormal2"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"nike"];
                [self.chosenBrandsArray addObject:@"nike"];
                [imageView setImage:[UIImage imageNamed:@"nikeSelected2"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 11){
            //Ralph Lauren
            if ([self.chosenBrandsArray containsObject:@"ralph"]) {
                //deselect
                [self.filtersArray removeObject:@"ralph"];
                [self.chosenBrandsArray removeObject:@"ralph"];
                [imageView setImage:[UIImage imageNamed:@"ralphNormal2"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"ralph"];
                [self.chosenBrandsArray addObject:@"ralph"];
                [imageView setImage:[UIImage imageNamed:@"ralphSelected2"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 12){
            //Gucci
            if ([self.chosenBrandsArray containsObject:@"gucci"]) {
                //deselect
                [self.filtersArray removeObject:@"gucci"];
                [self.chosenBrandsArray removeObject:@"gucci"];
                [imageView setImage:[UIImage imageNamed:@"gucciNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"gucci"];
                [self.chosenBrandsArray addObject:@"gucci"];
                [imageView setImage:[UIImage imageNamed:@"gucciSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 13){
            //Vetements
            if ([self.chosenBrandsArray containsObject:@"vetements"]) {
                //deselect
                [self.filtersArray removeObject:@"vetements"];
                [self.chosenBrandsArray removeObject:@"vetements"];
                [imageView setImage:[UIImage imageNamed:@"veteNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"vetements"];
                [self.chosenBrandsArray addObject:@"vetements"];
                [imageView setImage:[UIImage imageNamed:@"veteSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 14){
            //Balenciaga
            if ([self.chosenBrandsArray containsObject:@"balen"]) {
                //deselect
                [self.filtersArray removeObject:@"balen"];
                [self.chosenBrandsArray removeObject:@"balenciaga"];
                [imageView setImage:[UIImage imageNamed:@"balenNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"balen"];
                [self.chosenBrandsArray addObject:@"balenciaga"];
                [imageView setImage:[UIImage imageNamed:@"balenSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 15){
            //Vlone
            if ([self.chosenBrandsArray containsObject:@"vlone"]) {
                //deselect
                [self.filtersArray removeObject:@"vlone"];
                [self.chosenBrandsArray removeObject:@"vlone"];
                [self.chosenBrandsArray removeObject:@"v-lone"];

                [imageView setImage:[UIImage imageNamed:@"vloneNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"vlone"];
                [self.chosenBrandsArray addObject:@"vlone"];
                [self.chosenBrandsArray addObject:@"v-lone"];
                [imageView setImage:[UIImage imageNamed:@"vloneSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 16){
            //ASSC
            if ([self.chosenBrandsArray containsObject:@"assc"]) {
                //deselect
                [self.filtersArray removeObject:@"assc"];
                [self.chosenBrandsArray removeObject:@"assc"];
                [self.chosenBrandsArray removeObject:@"antisocialclub"];
                [self.chosenBrandsArray removeObject:@"anti"];
                [self.chosenBrandsArray removeObject:@"social"];
                [self.chosenBrandsArray removeObject:@"club"];

                [imageView setImage:[UIImage imageNamed:@"asscNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"assc"];
                [self.chosenBrandsArray addObject:@"assc"];
                [self.chosenBrandsArray addObject:@"antisocialclub"];
                [self.chosenBrandsArray addObject:@"anti"];
                [self.chosenBrandsArray addObject:@"social"];
                [self.chosenBrandsArray addObject:@"club"];
                
                [imageView setImage:[UIImage imageNamed:@"asscSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 17){
            //CDG
            if ([self.chosenBrandsArray containsObject:@"cdg"]) {
                //deselect
                [self.filtersArray removeObject:@"cdg"];
                [self.chosenBrandsArray removeObject:@"cdg"];
                [self.chosenBrandsArray removeObject:@"comme"];
                [self.chosenBrandsArray removeObject:@"des"];
                [self.chosenBrandsArray removeObject:@"garcons"];

                [imageView setImage:[UIImage imageNamed:@"cdgNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"cdg"];
                [self.chosenBrandsArray addObject:@"cdg"];
                [self.chosenBrandsArray addObject:@"comme"];
                [self.chosenBrandsArray addObject:@"des"];
                [self.chosenBrandsArray addObject:@"garcons"];
                
                [imageView setImage:[UIImage imageNamed:@"cdgSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 18){
            //Places+Faces
            if ([self.chosenBrandsArray containsObject:@"pf"]) {
                //deselect
                [self.filtersArray removeObject:@"pf"];
                [self.chosenBrandsArray removeObject:@"pf"];
                [self.chosenBrandsArray removeObject:@"places"];
                [self.chosenBrandsArray removeObject:@"faces"];
                
                [imageView setImage:[UIImage imageNamed:@"placesNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"pf"];
                [self.chosenBrandsArray addObject:@"pf"];
                [self.chosenBrandsArray addObject:@"places"];
                [self.chosenBrandsArray addObject:@"faces"];

                [imageView setImage:[UIImage imageNamed:@"placesSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
            }
        }
        else if(index == 19){
            //Raf Simons
            if ([self.chosenBrandsArray containsObject:@"raf"]) {
                //deselect
                [self.filtersArray removeObject:@"raf"];
                [self.chosenBrandsArray removeObject:@"raf"];
                [self.chosenBrandsArray removeObject:@"simons"];

                [imageView setImage:[UIImage imageNamed:@"rafNormal"]];
                [brandLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                //select
                [self.filtersArray addObject:@"raf"];
                [self.chosenBrandsArray addObject:@"raf"];
                [self.chosenBrandsArray addObject:@"simons"];

                [imageView setImage:[UIImage imageNamed:@"rafSelected"]];
                [brandLabel setTextColor:[UIColor whiteColor]];
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
            if (![self.filtersArray containsObject:@"clothing"] && ![self.filtersArray containsObject:@"footwear"] && ![self.filtersArray containsObject:@"accessory"]) {
                //no cat has been previously selected but user has tapped a size, can presume its a clothing size!
                //so select clothing category too
                [self.clothingButton setSelected:YES];
                [self.footButton setSelected:NO];
                [self.accessoryButton setSelected:NO];
                
                [self.filtersArray addObject:@"clothing"];
                [self.filtersArray removeObject:@"footwear"];
                [self.filtersArray removeObject:@"accessory"];
                
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
                //        self.lastSelected = messageLabel.text;
            }
        }
    }
    [self updateTitle];
}

-(NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView{
    
    if (swipeView == self.brandSwipeView) {
        return self.brandArray.count;
    }
    else if (swipeView == self.colourSwipeView){
        return self.coloursArray.count;
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

@end
