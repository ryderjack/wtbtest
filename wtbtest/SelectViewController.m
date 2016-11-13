//
//  SelectViewController.m
//  
//
//  Created by Jack Ryder on 26/02/2016.
//
//

#import "SelectViewController.h"

@interface SelectViewController ()

@end

@implementation SelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self.setting isEqualToString:@"condition"]) {
        self.title = @"Condition";
    }
    else if ([self.setting isEqualToString:@"category"]){
        self.title = @"Category";
    }
    else if ([self.setting isEqualToString:@"sizeclothing"]||[self.setting isEqualToString:@"sizefoot"]){
        self.title = @"Size";
    }
    else if ([self.setting isEqualToString:@"delivery"]){
        self.title = @"Delivery";
    }
    else{
        self.title = @"Select";
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
    
    self.categoryArray = [NSArray arrayWithObjects:@"Clothing",@"Footwear", nil];
    
    if (self.sellListing == YES) {
        self.mensSizeArray = [NSArray arrayWithObjects:@"UK 3 | US 3.5", @"UK 3.5 | US 4",@"UK 4 | US 4.5", @"UK 4.5 | US 5", @"UK 5 | US 5.5", @"UK 5.5 | US 6", @"UK 6 | US 6.5",@"UK 6.5 | US 7",@"UK 7 | US 7.5", @"UK 7.5 | US 8", @"UK 8 | US 8.5",@"UK 8.5 | US 9",@"UK 9 | US 9.5", @"UK 9.5 | US 10", @"UK 10 | US 10.5",@"UK 10.5 | US 11",@"UK 11 | US 11.5", @"UK 11.5 | US 12", @"UK 12 | US 12.5",@"UK 12.5 | US 13",@"UK 13 | US 13.5", @"UK 13.5 | US 14", @"UK 14 | US 14.5",@"Other", nil];
        
        self.mensSizeUKArray = [NSArray arrayWithObjects:@"3", @"3.5",@"4", @"4.5", @"5", @"5.5", @"6",@"6.5",@"7", @"7.5", @"8",@"8.5",@"9", @"9.5", @"10",@"10.5",@"11", @"11.5", @"12",@"12.5",@"13", @"13.5", @"14",@"Other", nil];
        
        self.femaleSizeUKArray =[NSArray arrayWithObjects:@"1", @" 1.5",@"2", @"2.5", @"3", @"3.5", @"4",@"4.5",@"5", @"5.5", @"6",@"6.5",@"7", @"7.5", @"8",@"9",@"Other", nil];
        
        self.femaleSizeArray = [NSArray arrayWithObjects:@"UK 1 | US 3", @"UK 1.5 | US 3.5",@"UK 2 | US 4", @"UK 2.5 | US 4.5", @"UK 3 | US 5", @"UK 3.5 | US 5.5", @"UK 4 | US 6",@"UK 4.5 | US 6.5",@"UK 5 | US 7", @"UK 5.5 | US 7.5", @"UK 6 | US 8",@"UK 6.5 | US 8.5",@"UK 7 | US 9", @"UK 7.5 | US 9.5", @"UK 8 | US 10",@"UK 9 | US 11",@"Other", nil];
        
        self.clothingyArray = [NSArray arrayWithObjects:@"XXS",@"XS", @"S", @"M", @"L", @"XL", @"XXL",@"Other", nil];
        
        self.conditionArray = [NSArray arrayWithObjects:@"Brand New With Tags",@"Brand New Without Tags", @"Used", @"Other",nil];
    }
    else{
        self.mensSizeArray = [NSArray arrayWithObjects:@"UK 3 | US 3.5", @"UK 3.5 | US 4",@"UK 4 | US 4.5", @"UK 4.5 | US 5", @"UK 5 | US 5.5", @"UK 5.5 | US 6", @"UK 6 | US 6.5",@"UK 6.5 | US 7",@"UK 7 | US 7.5", @"UK 7.5 | US 8", @"UK 8 | US 8.5",@"UK 8.5 | US 9",@"UK 9 | US 9.5", @"UK 9.5 | US 10", @"UK 10 | US 10.5",@"UK 10.5 | US 11",@"UK 11 | US 11.5", @"UK 11.5 | US 12", @"UK 12 | US 12.5",@"UK 12.5 | US 13",@"UK 13 | US 13.5", @"UK 13.5 | US 14", @"UK 14 | US 14.5", @"Any", nil];
        
        self.mensSizeUKArray = [NSArray arrayWithObjects:@"3", @"3.5",@"4", @"4.5", @"5", @"5.5", @"6",@"6.5",@"7", @"7.5", @"8",@"8.5",@"9", @"9.5", @"10",@"10.5",@"11", @"11.5", @"12",@"12.5",@"13", @"13.5", @"14", @"Any", nil];
        
        self.femaleSizeUKArray =[NSArray arrayWithObjects:@"1", @" 1.5",@"2", @"2.5", @"3", @"3.5", @"4",@"4.5",@"5", @"5.5", @"6",@"6.5",@"7", @"7.5", @"8",@"9", @"Any", nil];
        
        self.femaleSizeArray = [NSArray arrayWithObjects:@"UK 1 | US 3", @"UK 1.5 | US 3.5",@"UK 2 | US 4", @"UK 2.5 | US 4.5", @"UK 3 | US 5", @"UK 3.5 | US 5.5", @"UK 4 | US 6",@"UK 4.5 | US 6.5",@"UK 5 | US 7", @"UK 5.5 | US 7.5", @"UK 6 | US 8",@"UK 6.5 | US 8.5",@"UK 7 | US 9", @"UK 7.5 | US 9.5", @"UK 8 | US 10",@"UK 9 | US 11", @"Any", nil];
        
        self.clothingyArray = [NSArray arrayWithObjects:@"XXS",@"XS", @"S", @"M", @"L", @"XL", @"XXL", @"Any", nil];
        self.deliveryArray = [NSArray arrayWithObjects:@"Meetup",@"Courier", @"Any", nil];
        self.conditionArray = [NSArray arrayWithObjects:@"Brand New With Tags",@"Brand New Without Tags", @"Used", @"Any",nil];
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"selectCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    //holding array is just if user has previously selected an option then is coming back to the VC
    if (![self.holdingGender isEqualToString:@""]) {
        self.genderSelected = self.holdingGender;
//        NSLog(@"holding gender %@", self.holdingGender);
    }
    else{
        if ([[[PFUser currentUser]objectForKey:@"gender"]isEqualToString:@"male"]) {
            self.genderSelected = @"Mens";
        }
        else{
            self.genderSelected = @"Womens";
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
    
    if ([self.setting isEqualToString:@"condition"]) {
        return self.conditionArray.count;
    }
    else if ([self.setting isEqualToString:@"category"]){
        return self.categoryArray.count;
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
    self.cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    self.cell.delegate = self;
    
    if (!self.cell) {
        self.cell = [[selectCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    if ([self.setting isEqualToString:@"condition"]) {
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
        self.cell.textLabel.text = [self.categoryArray objectAtIndex:indexPath.row];
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
    else if ([self.setting isEqualToString:@"delivery"]){
        self.cell.textLabel.text = [self.deliveryArray objectAtIndex:indexPath.row];
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
    
    return self.cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    selectCell *selected = [tableView cellForRowAtIndexPath:indexPath];
    
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
                NSLog(@"removing mens size %@ and array %@", [self.mensSizeUKArray objectAtIndex:indexPath.row-1], self.selectedSizes);
                [self.selectedSizes removeObject:[self.mensSizeUKArray objectAtIndex:indexPath.row-1]];
                
                NSLog(@"new array %@", self.selectedSizes);
            }
            else{
                NSLog(@"removing female size %@",[self.femaleSizeUKArray objectAtIndex:indexPath.row-1] );
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
            
            if (self.sellListing == YES) {
                //put the pop logic here
                [self.selectedSizes removeAllObjects];
                
                if ([self.setting isEqualToString:@"sizefoot"]) {
                    if (indexPath.row == 0) {
                        //segment control so don't add anything
                    }
                    else{
                        //add adjusted index path (due to segment control at 0
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
                
                self.lastSelectedPath = indexPath;
                
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
            else{
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
                
                if (self.sellListing == YES) {
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
                    NSLog(@"got space in the array, add a checkmark!");
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
            }
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
    NSLog(@"selected: %@", selectionString);
    
    if (![selectionString isEqualToString:@""]) {
            [self.delegate addItemViewController:self didFinishEnteringItem:selectionString withgender:self.genderSelected andsizes:nil];
            [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
     if ([self.setting isEqualToString:@"sizefoot"] && self.selectedSizes.count > 0 && ![self.selectedSizes containsObject:@"Any"] && ![self.selectedSizes containsObject:@"Other"]){
        
         //convert array strings into numbers to sort into ascending order
         NSArray *sizeStrings = [NSArray arrayWithArray:self.selectedSizes];
         [self.selectedSizes removeAllObjects];
         
         NSMutableArray *numbersArray = [NSMutableArray array];
         
         for (NSString *size in sizeStrings) {
             //split string to get first part before |
             NSArray *strings = [size componentsSeparatedByString:@"|"];
             
             //get only number from that initial part of the string
             
             NSString *numberString = [strings[0] stringByReplacingOccurrencesOfString:@"UK" withString:@""];
             NSString *finalNumberString = [numberString stringByReplacingOccurrencesOfString:@" " withString:@""];
             NSLog(@"number string %@", finalNumberString);
             
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
        NSLog(@"final selection is %@", finalSelection);
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

@end
