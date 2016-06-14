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
        self.title = @"Size UK";
    }
    else if ([self.setting isEqualToString:@"delivery"]){
        self.title = @"Delivery";
    }
    else{
        self.title = @"Select";
    }
    
    self.selectedSizes = [NSMutableArray array];
    
    if (self.holdingArray.count >0) {
        [self.selectedSizes addObjectsFromArray:self.holdingArray];
    }
    
    NSLog(@"holding %@ and selected %@", self.holdingArray, self.selectedSizes);
    
    self.conditionArray = [NSArray arrayWithObjects:@"BNWT",@"BNWOT", @"Used", @"Any",nil];
    self.categoryArray = [NSArray arrayWithObjects:@"Clothing",@"Footwear", nil];
    self.sizeArray = [NSArray arrayWithObjects:@"3", @"3.5",@"4", @"4.5", @"5", @"5.5", @"6",@"6.5",@"7", @"7.5", @"8",@"8.5",@"9", @"9.5", @"10",@"10.5",@"11", @"11.5", @"12",@"12.5",@"13", @"13.5", @"14", @"Any", nil];
    self.clothingyArray = [NSArray arrayWithObjects:@"XXS",@"XS", @"S", @"M", @"L", @"XL", @"XXL", @"OS", @"Any", nil];
    self.deliveryArray = [NSArray arrayWithObjects:@"Meetup",@"Courier", @"Any", nil];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"selectCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    self.menSelected = YES;
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
    
    //if self.offer == yes then user is making an offer. Encourage specificity so remove 'Any' options
    if ([self.setting isEqualToString:@"condition"]) {
        if (self.offer == YES) {
            return 3;
        }
        return 4;
    }
    else if ([self.setting isEqualToString:@"category"]){
        return 2;
    }
    else if ([self.setting isEqualToString:@"sizeclothing"]){
        if (self.offer == YES) {
            return 8;
        }
        return 9;
    }
    else if ([self.setting isEqualToString:@"sizefoot"]){
       
        if (![self.holdingGender isEqualToString:@""]) {
            self.genderSelected = self.holdingGender;
            NSLog(@"holding gender %@", self.holdingGender);
        }
        else{
            self.genderSelected = @"Mens";
        }
        
        if (self.offer == YES) {
            return 24;
        }
        return 25;
    }
    else if ([self.setting isEqualToString:@"delivery"]){
        if (self.offer == YES) {
            return 2;
        }
        return 3;
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
            self.cell.textLabel.text = [self.sizeArray objectAtIndex:indexPath.row-1];
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
            [self.selectedSizes removeObject:[self.sizeArray objectAtIndex:indexPath.row-1]];
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
        if (([self.setting isEqualToString:@"sizeclothing"]||[self.setting isEqualToString:@"sizefoot"])&& self.offer == NO) {
            
            // if selected index is last (='Any') then clear the array and removes all checkmarks
            if (indexPath == pathToLastRow) {
                //clear sizes array
                [self.selectedSizes removeAllObjects];
                [self.selectedSizes addObject:@"Any"];
                
                //remove all checkmarks in tableview
                for (UITableViewCell *cell in [tableView visibleCells]) {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
                
                //add checkmark
                UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
                currentCell.accessoryType = UITableViewCellAccessoryCheckmark;

                return;
            }

            if (self.selectedSizes.count <3) {
                
                if ([self.selectedSizes containsObject:@"Any"]) {
                    [self.selectedSizes removeObject:@"Any"];
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
                        [self.selectedSizes addObject:[self.sizeArray objectAtIndex:indexPath.row-1]];
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
    else if ([self.setting isEqualToString:@"sizefoot"] && self.offer == YES && indexPath != firstPath) {
        selectionString = [self.sizeArray objectAtIndex:indexPath.row-1];
    }
    else if ([self.setting isEqualToString:@"sizeclothing"] && self.offer == YES && indexPath != firstPath) {
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
    
     if ([self.setting isEqualToString:@"sizefoot"] && self.offer == NO && self.selectedSizes.count > 0 && ![self.selectedSizes containsObject:@"Any"]){
        
         //convert array strings into numbers to sort into ascending order
         NSArray *strings = [NSArray arrayWithArray:self.selectedSizes];
         [self.selectedSizes removeAllObjects];
         
         for (int i = 0; i<strings.count; i++) {
             double number = [[strings objectAtIndex:i]doubleValue];
             [self.selectedSizes addObject:@(number)];
         }
         
         // sort clothing sizes array in order of string length for appearance
         NSSortDescriptor *sortDescriptor;
         sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"floatValue"
                                                      ascending:YES];
         NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
         [self.selectedSizes sortUsingDescriptors:sortDescriptors];
    }
    
    else if ([self.setting isEqualToString:@"sizeclothing"] && self.offer == NO){
        
        // sort clothing sizes array in order of string length for appearance
        NSSortDescriptor *sortDescriptor;
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"length"
                                                      ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        [self.selectedSizes sortUsingDescriptors:sortDescriptors];
    }
    
    if (([self.setting isEqualToString:@"sizeclothing"]||[self.setting isEqualToString:@"sizefoot"]) && self.offer == NO) {
        NSArray *finalSelection = [NSArray arrayWithArray:self.selectedSizes];
        NSLog(@"final selection is %@", finalSelection);
        [self.delegate addItemViewController:self didFinishEnteringItem:nil withgender:self.genderSelected andsizes:finalSelection];
    }
}

-(void)genderSelected:(NSString *)gender{
    if (self.cell.firstSelected == YES) {
        self.genderSelected = @"Mens";
    }
    else{
        self.genderSelected = @"Womens";
    }
}

@end
