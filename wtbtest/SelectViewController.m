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
    else if ([self.setting isEqualToString:@"sizeclothing"]||[self.setting isEqualToString:@"sizefoot"] ){
        self.title = @"Size UK";
    }
    else if ([self.setting isEqualToString:@"delivery"]){
        self.title = @"Delivery";
    }
    else{
        self.title = @"Select";
    }
    
    self.conditionArray = [NSArray arrayWithObjects:@"New w/ tags",@"New no tags", @"Used", @"Any",nil];
    self.categoryArray = [NSArray arrayWithObjects:@"Clothing",@"Footwear", nil];
    self.sizeArray = [NSArray arrayWithObjects:@"3", @"3.5",@"4", @"4.5", @"5", @"5.5", @"6",@"6.5",@"7", @"7.5", @"8",@"8.5",@"9", @"9.5", @"10",@"10.5",@"11", @"11.5", @"12",@"12.5",@"13", @"13.5", @"14", @"Any", nil];
    self.clothingyArray = [NSArray arrayWithObjects:@"XXS",@"XS", @"S", @"M", @"L", @"XL", @"XXL", @"OS", @"Any", nil];
    self.deliveryArray = [NSArray arrayWithObjects:@"Meetup",@"Courier", @"Any", nil];
    
    
    [self.tableView registerNib:[UINib nibWithNibName:@"selectCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
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
        self.genderSelected = @"Mens";
        if (self.offer == YES) {
            return 23;
        }
        return 24;
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
    [self.cell.segmentControl setHidden:YES];
    
    if ([self.setting isEqualToString:@"condition"]) {
        self.cell.textLabel.text = [self.conditionArray objectAtIndex:indexPath.row];
    }
    else if ([self.setting isEqualToString:@"category"]){
        self.cell.textLabel.text = [self.categoryArray objectAtIndex:indexPath.row];
    }
    else if ([self.setting isEqualToString:@"sizeclothing"]){
        self.cell.textLabel.text = [self.clothingyArray objectAtIndex:indexPath.row];
    }
    else if ([self.setting isEqualToString:@"sizefoot"]){
        if (indexPath.row == 0) {
            [self.cell.segmentControl setHidden:NO];
        }
        else{
            self.cell.textLabel.text = [self.sizeArray objectAtIndex:indexPath.row-1];
            
        }
    }
    else if ([self.setting isEqualToString:@"delivery"]){
        self.cell.textLabel.text = [self.deliveryArray objectAtIndex:indexPath.row];
    }
    return self.cell;
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
- (IBAction)genderSwitchChanged:(id)sender {
    if (self.cell.segmentControl.selectedSegmentIndex == 0) {
        //male
        self.genderSelected = @"Mens";
    }
    else{
        self.genderSelected = @"Womens";
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    selectCell *selected = [tableView cellForRowAtIndexPath:indexPath];
    
    if (selected.segmentControl.isHidden == NO) {
    }
    else{
        if(self.lastSelectedPath) {
            
            UITableViewCell *lastCell = [tableView cellForRowAtIndexPath:self.lastSelectedPath];
            lastCell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
        currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        self.lastSelectedPath = indexPath;
    }
    
    NSString *selectionString = [[NSString alloc]init];
    
    if ([self.setting isEqualToString:@"sizefoot"]) {
        if (indexPath.row == 0) {
            //segment control
            selectionString = @"";
        }
        else{
            selectionString = [self.sizeArray objectAtIndex:indexPath.row-1];
        }
    }
    else if ([self.setting isEqualToString:@"sizeclothing"]) {
        selectionString = [self.clothingyArray objectAtIndex:indexPath.row];
    }
    else if ([self.setting isEqualToString:@"category"]) {
        selectionString = [self.categoryArray objectAtIndex:indexPath.row];
    }
    else if ([self.setting isEqualToString:@"condition"]) {
        selectionString = [self.conditionArray objectAtIndex:indexPath.row];
    }
    else if ([self.setting isEqualToString:@"delivery"]) {
        selectionString = [self.deliveryArray objectAtIndex:indexPath.row];
    }
    
    //if not nothing (coz of selection cell in sizes) proceed..
    NSLog(@"selected: %@", selectionString);
    
    if (![selectionString isEqualToString:@""]) {
        if ([self.setting isEqualToString:@"sizefoot"]) {
            [self.delegate addItemViewController:self didFinishEnteringItem:selectionString withitem:self.genderSelected];
        }
        else{
            [self.delegate addItemViewController:self didFinishEnteringItem:selectionString withitem:nil];
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
}

@end
