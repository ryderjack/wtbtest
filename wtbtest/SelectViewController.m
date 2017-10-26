//
//  SelectViewController.m
//  
//
//  Created by Jack Ryder on 26/02/2016.
//
//

#import "SelectViewController.h"
#import "CategoryDetailCell.h"

@interface SelectViewController ()

@end

@implementation SelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];

    if (self.viewingMode) {
        self.title = @"S I Z E S";
        
    }
    else{
        if ([self.setting isEqualToString:@"condition"]) {
            self.title = @"C O N D I T I O N";
        }
        else if ([self.setting isEqualToString:@"category"]){
            self.title = @"C A T E G O R Y";
        }
        else if ([self.setting isEqualToString:@"sizeclothing"]||[self.setting isEqualToString:@"sizefoot"]){
            self.title = @"S I Z E";
        }
        else if ([self.setting isEqualToString:@"clothing"]){
            self.title = @"C L O T H I N G";
        }
        else{
            self.title = @"S E L E C T";
        }
        
        
        self.selectedSizes = [NSMutableArray array];
        
        if (self.holdingArray.count >0) {
            for (NSString *size in self.holdingArray) {
                if ([size containsString:@"UK "]) {
                    NSString *newString = [size stringByReplacingOccurrencesOfString:@"UK " withString:@""];
                    [self.selectedSizes addObject:newString];
                }
                else{
                    [self.selectedSizes addObject:size];
                }
            }
        }
        
        //    NSLog(@"holding %@ and selected %@", self.holdingArray, self.selectedSizes);
        
        self.categoryArray = [NSArray arrayWithObjects:@"Clothing",@"Footwear",@"Accessories",@"Proxy", nil];
        self.clothingCategoryArray = [NSArray arrayWithObjects:@"Tops",@"Bottoms",@"Outerwear", nil];
        self.clothingyDescriptionArray = [NSArray arrayWithObjects:@"Long/shortsleeve Tees, Polos, Shirts, Sweatshirts & Hoodies",@"Jeans, Shorts, Swimwear, Sweatpants & Joggers",@"Bombers, Coats, Jackets, Raincoats", nil];
        
        if (self.sellListing == YES) {
            self.mensSizeArray = [NSArray arrayWithObjects:@"UK 3", @"UK 3.5",@"UK 4", @"UK 4.5", @"UK 5", @"UK 5.5", @"UK 6",@"UK 6.5",@"UK 7", @"UK 7.5", @"UK 8",@"UK 8.5",@"UK 9", @"UK 9.5", @"UK 10",@"UK 10.5",@"UK 11", @"UK 11.5", @"UK 12",@"UK 12.5",@"UK 13", @"UK 13.5", @"UK 14",@"Other", nil];
            
            self.mensSizeUKArray = [NSArray arrayWithObjects:@"3", @"3.5",@"4", @"4.5", @"5", @"5.5", @"6",@"6.5",@"7", @"7.5", @"8",@"8.5",@"9", @"9.5", @"10",@"10.5",@"11", @"11.5", @"12",@"12.5",@"13", @"13.5", @"14",@"Other", nil];
            
            self.femaleSizeUKArray =[NSArray arrayWithObjects:@"1", @" 1.5",@"2", @"2.5", @"3", @"3.5", @"4",@"4.5",@"5", @"5.5", @"6",@"6.5",@"7", @"7.5", @"8",@"9",@"Other", nil];
            
            self.femaleSizeArray = [NSArray arrayWithObjects:@"UK 1", @"UK 1.5",@"UK 2", @"UK 2.5", @"UK 3", @"UK 3.5", @"UK 4",@"UK 4.5",@"UK 5", @"UK 5.5", @"UK 6",@"UK 6.5",@"UK 7", @"UK 7.5", @"UK 8",@"UK 9",@"Other", nil];
            
            self.clothingyArray = [NSArray arrayWithObjects:@"XXS",@"XS", @"S", @"M", @"L", @"XL", @"XXL",@"Other", nil];
        }
        else{
            self.mensSizeArray = [NSArray arrayWithObjects:@"UK 3", @"UK 3.5",@"UK 4", @"UK 4.5", @"UK 5", @"UK 5.5", @"UK 6",@"UK 6.5",@"UK 7", @"UK 7.5", @"UK 8",@"UK 8.5",@"UK 9", @"UK 9.5", @"UK 10",@"UK 10.5",@"UK 11", @"UK 11.5", @"UK 12",@"UK 12.5",@"UK 13", @"UK 13.5", @"UK 14",@"Any", nil];
            
            self.mensSizeUKArray = [NSArray arrayWithObjects:@"3", @"3.5",@"4", @"4.5", @"5", @"5.5", @"6",@"6.5",@"7", @"7.5", @"8",@"8.5",@"9", @"9.5", @"10",@"10.5",@"11", @"11.5", @"12",@"12.5",@"13", @"13.5", @"14", @"Any", nil];
            
            self.femaleSizeUKArray =[NSArray arrayWithObjects:@"1", @" 1.5",@"2", @"2.5", @"3", @"3.5", @"4",@"4.5",@"5", @"5.5", @"6",@"6.5",@"7", @"7.5", @"8",@"9", @"Any", nil];
            
            self.femaleSizeArray = [NSArray arrayWithObjects:@"UK 1", @"UK 1.5",@"UK 2", @"UK 2.5", @"UK 3", @"UK 3.5", @"UK 4",@"UK 4.5",@"UK 5", @"UK 5.5", @"UK 6",@"UK 6.5",@"UK 7", @"UK 7.5", @"UK 8",@"UK 9",@"Any", nil];
            
            self.clothingyArray = [NSArray arrayWithObjects:@"XXS",@"XS", @"S", @"M", @"L", @"XL", @"XXL", @"Any", nil];
            self.deliveryArray = [NSArray arrayWithObjects:@"Meetup",@"Courier", @"Any", nil];
            self.conditionArray = [NSArray arrayWithObjects:@"Brand New With Tags",@"Brand New Without Tags", @"Used", @"Any",nil];
        }
        //holding array is just if user has previously selected an option then is coming back to the VC
        if (![self.holdingGender isEqualToString:@""]) {
            self.genderSelected = self.holdingGender;
            //        NSLog(@"holding gender %@", self.holdingGender);
        }
        else{
            if ([[[PFUser currentUser]objectForKey:@"gender"]isEqualToString:@"male"]) {
                self.genderSelected = @"Mens";
            }
            else if ([[[PFUser currentUser]objectForKey:@"gender"]isEqualToString:@"female"]) {
                self.genderSelected = @"Womens";
            }
            else{
                self.genderSelected = @"Mens";
            }
        }
        
        [self.tableView registerNib:[UINib nibWithNibName:@"CategoryDetailCell" bundle:nil] forCellReuseIdentifier:@"catCell"];

    }

    [self.tableView registerNib:[UINib nibWithNibName:@"selectCell" bundle:nil] forCellReuseIdentifier:@"Cell"];

}

-(void)viewWillAppear:(BOOL)animated{
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, [UIColor blackColor], NSForegroundColorAttributeName,  nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
}

-(void)viewDidAppear:(BOOL)animated{
    if ([self.setting isEqualToString:@"sizeclothing"]||[self.setting isEqualToString:@"sizefoot"]){
        if (self.sellListing == YES) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"seenMultipleSellPrompt1"] != YES) {
                [self showMultipleALert];
            }
        }
        else{
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"seenMultipleWantPrompt"] != YES) {
                [self showMultipleALert];
            }
        }
    }
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
    
    if (self.viewingMode) {
        return self.viewingArray.count;
    }
    else if ([self.setting isEqualToString:@"condition"]) {
        return self.conditionArray.count;
    }
    else if ([self.setting isEqualToString:@"category"]){
        return self.categoryArray.count;
    }
    else if ([self.setting isEqualToString:@"clothing"]){
        return self.clothingCategoryArray.count;
    }
    else if ([self.setting isEqualToString:@"sizeclothing"]){
        return self.clothingyArray.count;
    }
    else if ([self.setting isEqualToString:@"sizefoot"]){
       
        if ([self.genderSelected isEqualToString:@"Mens"]) {
            return self.mensSizeArray.count+1;
        }
        else{
            return self.femaleSizeArray.count+1;
        }
    }
    else if ([self.setting isEqualToString:@"delivery"]){
        return self.deliveryArray.count;
    }
    else{
        return 1;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.setting isEqualToString:@"clothing"]) {
        CategoryDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:@"catCell" forIndexPath:indexPath];
        cell.categoryLabel.text = [self.clothingCategoryArray objectAtIndex:indexPath.row];
        cell.lowerLabel.text = [self.clothingyDescriptionArray objectAtIndex:indexPath.row];
        
        if ([self.selectedSizes containsObject:cell.categoryLabel.text]) {
            //already been selected, show checkmark
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else{
            //hasnt already been selected
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        return cell;
    }
    else{
        self.cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
        
        self.cell.delegate = self;
        [self.cell.proxyExplainButton setHidden:YES];
        self.cell.mainLabel.text = @"";
        
        if (!self.cell) {
            self.cell = [[selectCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        }
        
        if (self.viewingMode) {
            self.cell.textLabel.text = [self.viewingArray objectAtIndex:indexPath.row];
            [self.cell.segmentControl setHidden:YES];
            self.cell.accessoryType = UITableViewCellAccessoryNone;
        }
        else if ([self.setting isEqualToString:@"condition"]) {
            self.cell.textLabel.text = [self.conditionArray objectAtIndex:indexPath.row];
            [self.cell.segmentControl setHidden:YES];
            
            if ([self.selectedSizes containsObject:self.cell.textLabel.text]) {
                //already been selected, show checkmark
                self.cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                //hasnt already been selected
                self.cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if ([self.setting isEqualToString:@"category"]){
            self.cell.mainLabel.text = [self.categoryArray objectAtIndex:indexPath.row];
            
            [self.cell.segmentControl setHidden:YES];
            
            if ([self.cell.mainLabel.text isEqualToString:@"Proxy"]) {
                [self.cell.proxyExplainButton setHidden:NO];
            }
            
            if ([self.cell.mainLabel.text isEqualToString:@"Clothing"]) {
                self.cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else if ([self.selectedSizes containsObject:self.cell.mainLabel.text]) {
                //already been selected, show checkmark
                self.cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                //hasnt already been selected
                self.cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if ([self.setting isEqualToString:@"clothing"]){
            self.cell.textLabel.text = [self.clothingCategoryArray objectAtIndex:indexPath.row];
            
            [self.cell.segmentControl setHidden:YES];
            
            if ([self.selectedSizes containsObject:self.cell.textLabel.text]) {
                //already been selected, show checkmark
                self.cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                //hasnt already been selected
                self.cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if ([self.setting isEqualToString:@"sizeclothing"]){
            self.cell.textLabel.text = [self.clothingyArray objectAtIndex:indexPath.row];
            [self.cell.segmentControl setHidden:YES];
            
            if ([self.selectedSizes containsObject:self.cell.textLabel.text]) {
                //already been selected, show checkmark
                self.cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                //hasnt already been selected
                self.cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
        }
        else if ([self.setting isEqualToString:@"sizefoot"]){
            if (indexPath.row == 0) {
                [self.cell.segmentControl setHidden:NO];
                [self.cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                self.cell.accessoryType = UITableViewCellAccessoryNone;
                self.cell.textLabel.text = @"";
                
                //update selected index
                if ([self.genderSelected isEqualToString:@"Mens"]) {
                    self.cell.segmentControl.selectedSegmentIndex = 0;
                }
                else{
                    self.cell.segmentControl.selectedSegmentIndex = 1;
                }
            }
            else{
                if ([self.genderSelected isEqualToString:@"Mens"]) {
                    self.cell.textLabel.text = [self.mensSizeArray objectAtIndex:indexPath.row-1];
                }
                else{
                    self.cell.textLabel.text = [self.femaleSizeArray objectAtIndex:indexPath.row-1];
                }
                
                [self.cell.segmentControl setHidden:YES];
                
                if ([self.holdingGender isEqualToString:self.genderSelected]) {
                    
                    //highlight previously chosen sizes
                    
                    for (NSString *size in self.selectedSizes) {
                        
                        if ([self.genderSelected isEqualToString:@"Mens"]) {
                            //mens
                            if ([[self.mensSizeUKArray objectAtIndex:indexPath.row-1] isEqualToString:size]) {
                                self.cell.accessoryType = UITableViewCellAccessoryCheckmark;
                                break;
                            }
                            else{
                                self.cell.accessoryType = UITableViewCellAccessoryNone;
                            }
                        }
                        else{
                            //womens
                            if ([[self.femaleSizeUKArray objectAtIndex:indexPath.row-1] isEqualToString:size]) {
                                self.cell.accessoryType = UITableViewCellAccessoryCheckmark;
                                break;
                            }
                            else{
                                self.cell.accessoryType = UITableViewCellAccessoryNone;
                            }
                        }
                    }
                }
                else{
                    self.cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
        }
        
        return self.cell;
    }

}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([self.setting isEqualToString:@"clothing"]) {
        return 88;
    }
    else{
        return 44;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (self.viewingMode) {
        return;
    }
    else if ([self.setting isEqualToString:@"clothing"]) {
        
        NSString *selectionString = [self.clothingCategoryArray objectAtIndex:indexPath.row];
        [self.delegate addItemViewController:self didFinishEnteringItem:selectionString withgender:self.genderSelected andsizes:nil];
        [self.navigationController popToRootViewControllerAnimated:YES];

        return;
    }

    
    selectCell *selected = [tableView cellForRowAtIndexPath:indexPath];
    
    //check if category & Clothing pressed then push another select VC on top
    if ([self.setting isEqualToString:@"category"] && [selected.mainLabel.text isEqualToString:@"Clothing"]) {
        SelectViewController *vc = [[SelectViewController alloc]init];
        vc.setting = @"clothing";
        vc.holdingArray = self.selectedSizes;
        vc.delegate = self;
        self.pushingClothing = YES;
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    
    // First figure out how many sections there are
    NSInteger lastSectionIndex = [tableView numberOfSections] - 1;
    
    // Then grab the number of rows in the last section
    NSInteger lastRowIndex = [tableView numberOfRowsInSection:lastSectionIndex] - 1;
    
    // Now just construct the index path
    NSIndexPath *pathToLastRow = [NSIndexPath indexPathForRow:lastRowIndex inSection:lastSectionIndex];
    
    //check if cell previously been selected
    if (selected.accessoryType == UITableViewCellAccessoryCheckmark) {
        //remove the checkmark and reset the selection values
        selected.accessoryType = UITableViewCellAccessoryNone;
        
        if ([self.setting isEqualToString:@"sizefoot"]) {
            if ([self.genderSelected isEqualToString:@"Mens"]) {
                [self.selectedSizes removeObject:[self.mensSizeUKArray objectAtIndex:indexPath.row-1]];
            }
            else{
                [self.selectedSizes removeObject:[self.femaleSizeUKArray objectAtIndex:indexPath.row-1]];
            }
        }
        else if ([self.setting isEqualToString:@"sizeclothing"]) {
            [self.selectedSizes removeObject:[self.clothingyArray objectAtIndex:indexPath.row]];
        }
        return;
    }
    
    if (selected.segmentControl.isHidden == NO) {
        // that means its the segment control cell, do nothing!
    }
    else{
        if(self.lastSelectedPath) {
            
            //if setting is size then don't deselect last cell
            if ([self.setting isEqualToString:@"sizeclothing"]||[self.setting isEqualToString:@"sizefoot"]) {
            }
            else{
                //deselect last selected cell
                UITableViewCell *lastCell = [tableView cellForRowAtIndexPath:self.lastSelectedPath];
                lastCell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        
        //if setting is size add a checkmark if array is < 3
        if (([self.setting isEqualToString:@"sizeclothing"]||[self.setting isEqualToString:@"sizefoot"])) {
            
//            if (self.sellListing == YES) {
//                //put the pop logic here
//                [self.selectedSizes removeAllObjects];
//                
//                if ([self.setting isEqualToString:@"sizefoot"]) {
//                    if (indexPath.row == 0) {
//                        //segment control so don't add anything
//                    }
//                    else{
//                        //add adjusted index path (due to segment control at 0
//                        if ([self.genderSelected isEqualToString:@"Mens"]) {
//                            [self.selectedSizes addObject:[self.mensSizeUKArray objectAtIndex:indexPath.row-1]];
//                        }
//                        else{
//                            [self.selectedSizes addObject:[self.femaleSizeUKArray objectAtIndex:indexPath.row-1]];
//                        }
//                    }
//                }
//                else if ([self.setting isEqualToString:@"sizeclothing"]) {
//                    [self.selectedSizes addObject:[self.clothingyArray objectAtIndex:indexPath.row]];
//                }
//                
//                self.lastSelectedPath = indexPath;
//                
//                //remove all checkmarks in tableview
//                for (UITableViewCell *cell in [tableView visibleCells]) {
//                    cell.accessoryType = UITableViewCellAccessoryNone;
//                }
//                
//                //add checkmark
//                UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
//                currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
//                
//                [self.navigationController popViewControllerAnimated:YES];
//                
//                return;
//            }
//            else{
                // if selected index is last (='Any' or 'Other') then clear the array and remove all checkmarks
                if (indexPath == pathToLastRow) {
                    //clear sizes array
                    [self.selectedSizes removeAllObjects];
                    if (self.sellListing == YES) {
                        [self.selectedSizes addObject:@"Other"];
                        [self.delegate addItemViewController:self didFinishEnteringItem:@"Other" withgender:self.genderSelected andsizes:nil];
                    }
                    else{
                        [self.selectedSizes addObject:@"Any"];
                        [self.delegate addItemViewController:self didFinishEnteringItem:@"Any" withgender:self.genderSelected andsizes:nil];
                    }
                    
                    //remove all checkmarks in tableview
                    for (UITableViewCell *cell in [tableView visibleCells]) {
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    
                    //add checkmark
                    UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
                    currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
                    
                    [self.navigationController popViewControllerAnimated:YES];
                    
                    return;
                }
                
                int limit = 0;
                
                if (self.multipleAllowed == YES) {
                    limit = 10;
                }
                else if (self.sellListing == YES){
                    limit = 1;
                }
                else{
                    limit = 3;
                }
                
                if (self.selectedSizes.count <limit) {
                    
                    if ([self.selectedSizes containsObject:@"Any"]) {
                        [self.selectedSizes removeObject:@"Any"];
                        UITableViewCell *anyCell = [tableView cellForRowAtIndexPath:pathToLastRow];
                        anyCell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    else if ([self.selectedSizes containsObject:@"Other"]) {
                        [self.selectedSizes removeObject:@"Other"];
                        UITableViewCell *anyCell = [tableView cellForRowAtIndexPath:pathToLastRow];
                        anyCell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    
                    //select cell, got space left in the selection array
                    UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
                    currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
                    
                    //update selected sizes array
                    
                    if ([self.setting isEqualToString:@"sizefoot"]) {
                        if (indexPath.row == 0) {
                            //segment control so don't add anything
                        }
                        else{
                            //add adjusted index path (due to segment control at 0 ^
                            if ([self.genderSelected isEqualToString:@"Mens"]) {
                                [self.selectedSizes addObject:[self.mensSizeUKArray objectAtIndex:indexPath.row-1]];
                            }
                            else{
                                [self.selectedSizes addObject:[self.femaleSizeUKArray objectAtIndex:indexPath.row-1]];
                            }
                        }
                    }
                    else if ([self.setting isEqualToString:@"sizeclothing"]) {
                        [self.selectedSizes addObject:[self.clothingyArray objectAtIndex:indexPath.row]];
                    }
                    
                    NSLog(@"updated selected sizes array %@", self.selectedSizes);
                    
                    self.lastSelectedPath = indexPath;
                }
                else{
                    //don't select the cell, already reached the max selection
                    NSLog(@"array is full! need to deselect something");
                }
                
                //can return beacuse other code is for other settings
                return;
//            }
        }
        else{
            //add a checkmark to latest cell because its not a size selection VC
            UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
            currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
            self.lastSelectedPath = indexPath;
        }
    }
    
    NSString *selectionString = [[NSString alloc]init];
    
    //first index path
    
    NSIndexPath *firstPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
    if ([self.setting isEqualToString:@"category"]) {
        selectionString = [self.categoryArray objectAtIndex:indexPath.row];
    }
    else if ([self.setting isEqualToString:@"clothing"]) {
        selectionString = [self.clothingCategoryArray objectAtIndex:indexPath.row];
    }
    else if ([self.setting isEqualToString:@"condition"]) {
        selectionString = [self.conditionArray objectAtIndex:indexPath.row];
    }
    else if ([self.setting isEqualToString:@"delivery"]) {
        selectionString = [self.deliveryArray objectAtIndex:indexPath.row];
    }
    else if ([self.setting isEqualToString:@"sizefoot"] && indexPath != firstPath) {
        if ([self.genderSelected isEqualToString:@"Mens"]) {
            selectionString = [self.mensSizeArray objectAtIndex:indexPath.row-1];
        }
        else{
            selectionString = [self.femaleSizeArray objectAtIndex:indexPath.row-1];
        }
    }
    else if ([self.setting isEqualToString:@"sizeclothing"] && indexPath != firstPath) {
        selectionString = [self.clothingyArray objectAtIndex:indexPath.row];
    }
    
    //if not nothing (coz of selection cell in sizes) proceed..
//    NSLog(@"selected: %@", selectionString);
    
    if (![selectionString isEqualToString:@""]) {
            [self.delegate addItemViewController:self didFinishEnteringItem:selectionString withgender:self.genderSelected andsizes:nil];
        
        if ([self.setting isEqualToString:@"clothing"]) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
        else{
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    if (self.pushingClothing) {
        self.pushingClothing = NO;
        return;
    }
    
    if ([self.setting isEqualToString:@"sizefoot"] && self.selectedSizes.count > 0 && ![self.selectedSizes containsObject:@"Any"] && ![self.selectedSizes containsObject:@"Other"]){
        
         //convert array strings into numbers to sort into ascending order
         NSArray *sizeStrings = [NSArray arrayWithArray:self.selectedSizes];
         [self.selectedSizes removeAllObjects];
         
         NSMutableArray *numbersArray = [NSMutableArray array];
         
         for (NSString *size in sizeStrings) {
             
             //ensure its actually a string (was crashing when had a number here
             NSString *stringCheck = [NSString stringWithFormat:@"%@",size];
             
             //split string to get first part before |
             NSArray *strings = [stringCheck componentsSeparatedByString:@"|"];
             //get only number from that initial part of the string
             
             NSString *numberString = [strings[0] stringByReplacingOccurrencesOfString:@"UK" withString:@""];
             NSString *finalNumberString = [numberString stringByReplacingOccurrencesOfString:@" " withString:@""];
             
             //save that number as a string to the array
             [numbersArray addObject:finalNumberString];
         }
         
         //convert each number string into a double for comparison
         for (int i = 0; i<numbersArray.count; i++) {
             double number = [[numbersArray objectAtIndex:i]doubleValue];
             [self.selectedSizes addObject:@(number)];
         }
         
         // sort numbers
         NSSortDescriptor *sortDescriptor;
         sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"floatValue"
                                                      ascending:YES];
         NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
         [self.selectedSizes sortUsingDescriptors:sortDescriptors];
    }
    
    else if ([self.setting isEqualToString:@"sizeclothing"]){
        
        // sort clothing sizes array in order of string length for appearance
        NSSortDescriptor *sortDescriptor;
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"length"
                                                      ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        [self.selectedSizes sortUsingDescriptors:sortDescriptors];
    }
    
    if (([self.setting isEqualToString:@"sizeclothing"]||[self.setting isEqualToString:@"sizefoot"])) {
        NSArray *finalSelection = [NSArray arrayWithArray:self.selectedSizes];
//        NSLog(@"final selection is %@", finalSelection);
        [self.delegate addItemViewController:self didFinishEnteringItem:nil withgender:self.genderSelected andsizes:finalSelection];
    }
}

-(void)genderSelected:(NSString *)gender{

    //different segment tapped
    self.genderSelected = gender;
    [self.tableView reloadData];
    
    //remove all checkmarks in tableview
    for (UITableViewCell *cell in [self.tableView visibleCells]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    [self.selectedSizes removeAllObjects];
}

-(void)showMultipleALert{
    
    self.searchBgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.searchBgView.alpha = 0.0;
    [self.searchBgView setBackgroundColor:[UIColor blackColor]];
    [[UIApplication sharedApplication].keyWindow addSubview:self.searchBgView];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.searchBgView.alpha = 0.6f;
                     }
                     completion:nil];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"customAlertView" owner:self options:nil];
    self.customAlert = (customAlertViewClass *)[nib objectAtIndex:0];
    self.customAlert.delegate = self;
    
    self.customAlert.titleLabel.text = @"UK Sizes";
    
    //prompt user that multiple sizes can be selected
    if (self.sellListing == YES) {
        self.customAlert.messageLabel.text = @"We use UK sizing as standard on BUMP so more buyers can easily find your listing\n\nTap all the UK sizes you're selling!";
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"seenMultipleSellPrompt1"];
    }
    else{
        self.customAlert.messageLabel.text = @"Tap all the sizes you're interested in buying!";
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"seenMultipleWantPrompt"];
    }
    

    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, -157, 250, 157)];
    }
    else{
        [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, -188, 300, 188)]; //iPhone 6/7 specific
    }
    
    self.customAlert.layer.cornerRadius = 10;
    self.customAlert.layer.masksToBounds = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.customAlert];
    
    [UIView animateWithDuration:0.5
                          delay:0.2
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, 100, 250, 157)];
                            }
                            else{
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, 100, 300, 188)]; //iPhone 6/7 specific
                            }
                            self.customAlert.center = self.view.center;
                        }
                     completion:^(BOOL finished) {
                         
                     }];
}


-(void)donePressed{
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.searchBgView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         self.searchBgView = nil;
                     }];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, 1000, 250, 157)];
                            }
                            else{
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, 1000, 300, 188)]; //iPhone 6/7 specific
                            }
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         [self.customAlert setAlpha:0.0];
                         self.customAlert = nil;
                     }];
}

-(void)firstPressed{
}

-(void)secondPressed{
}

#pragma mark - second level category delegates
-(void)addItemViewController:(SelectViewController *)controller didFinishEnteringItem:(NSString *)selectionString withgender:(NSString *)genderString andsizes:(NSArray *)array{
    if (selectionString) {
        [self.delegate addItemViewController:self didFinishEnteringItem:selectionString withgender:nil andsizes:nil];
        
    }
}

-(void)proxyExplainPressed{
    [self showAlertWithTitle:@"What's a proxy?" andMsg:@"A proxy is when someone is willing to queue up for a drop on your behalf. It's almost like a preorder for items that are yet to be released. Usually you will pay someone proxying for you the retail price of the item plus a fee for the service."];
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}
@end
