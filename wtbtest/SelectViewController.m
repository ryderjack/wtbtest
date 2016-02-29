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
        return 2;
    }
    else if ([self.setting isEqualToString:@"category"]){
        return 2;
    }
    else if ([self.setting isEqualToString:@"sizeclothing"]){
        return 9;
    }
    else if ([self.setting isEqualToString:@"sizefoot"]){
        return 10;
    }
    else if ([self.setting isEqualToString:@"delivery"]){
        return 2;
    }
    else{
        return 1;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.setting isEqualToString:@"condition"]) {
        if (indexPath.row == 0){
            self.firstLabel.text = @"New";
            return self.oneCell;
        }
        else if (indexPath.row ==1){
            self.secondLabel.text = @"Used";
            return self.twoCell;
        }
    }
    else if ([self.setting isEqualToString:@"category"]){
        if (indexPath.row == 0){
            self.firstLabel.text = @"Clothing";
            return self.oneCell;
        }
        else if (indexPath.row ==1){
            self.secondLabel.text = @"Footwear";
            return self.twoCell;
        }
    }
    else if ([self.setting isEqualToString:@"sizeclothing"]){
        if (indexPath.row == 0){
            self.firstLabel.text = @"XXS";
            return self.oneCell;
        }
        else if (indexPath.row ==1){
            self.secondLabel.text = @"XS";
            return self.twoCell;
        }
        else if (indexPath.row ==2){
            self.thirdLabel.text = @"S";
            return self.threeCell;
        }
        else if (indexPath.row ==3){
            self.fourthLabel.text = @"M";
            return self.fourCell;
        }
        else if (indexPath.row ==4){
            self.fifthLabel.text = @"L";
            return self.fiveCell;
        }
        else if (indexPath.row ==5){
            self.sixthLabel.text = @"XL";
            return self.sixCell;
        }
        else if (indexPath.row ==6){
            self.seventhLabel.text = @"XXL";
            return self.sevenCell;
        }
        else if (indexPath.row ==7){
            self.eigthLabel.text = @"One size";
            return self.eightCell;
        }
        else if (indexPath.row ==8){
            self.ninthLabel.text = @"Other";
            return self.nineCell;
        }
    }
    else if ([self.setting isEqualToString:@"sizefoot"]){
        
        if (self.segmentContro.selectedSegmentIndex == 0) {
            //men selected
            if (indexPath.row == 0){
                return self.selectCell;
            }
            else if (indexPath.row ==1){
                self.firstLabel.text = @"UK 6";
                return self.oneCell;
            }
            else if (indexPath.row ==2){
                self.secondLabel.text = @"UK 7";
                return self.twoCell;
            }
            else if (indexPath.row ==3){
                self.thirdLabel.text = @"UK 8";
                return self.threeCell;
            }
            else if (indexPath.row ==4){
                self.fourthLabel.text = @"UK 9";
                return self.fourCell;
            }
            else if (indexPath.row ==5){
                self.fifthLabel.text = @"UK 10";
                return self.fiveCell;
            }
            else if (indexPath.row ==6){
                self.sixthLabel.text = @"UK 11";
                return self.sixCell;
            }
            else if (indexPath.row ==7){
                self.seventhLabel.text = @"UK 12";
                return self.sevenCell;
            }
            else if (indexPath.row ==8){
                self.eigthLabel.text = @"UK 13";
                return self.eightCell;
            }
            else if (indexPath.row ==9){
                self.ninthLabel.text = @"UK 14";
                return self.nineCell;
            }
        }
        else{
            //women selected
            if (indexPath.row == 0){
                return self.selectCell;
            }
            else if (indexPath.row ==1){
                self.firstLabel.text = @"UK 2";
                return self.oneCell;
            }
            else if (indexPath.row ==2){
                self.secondLabel.text = @"UK 3";
                return self.twoCell;
            }
            else if (indexPath.row ==3){
                self.thirdLabel.text = @"UK 4";
                return self.threeCell;
            }
            else if (indexPath.row ==4){
                self.fourthLabel.text = @"UK 5";
                return self.fourCell;
            }
            else if (indexPath.row ==5){
                self.fifthLabel.text = @"UK 6";
                return self.fiveCell;
            }
            else if (indexPath.row ==6){
                self.sixthLabel.text = @"UK 7";
                return self.sixCell;
            }
            else if (indexPath.row ==7){
                self.seventhLabel.text = @"UK 8";
                return self.sevenCell;
            }
            else if (indexPath.row ==8){
                self.eigthLabel.text = @"UK 9";
                return self.eightCell;
            }
            else if (indexPath.row ==9){
                self.ninthLabel.text = @"UK 10";
                return self.nineCell;
            }
        }
    }
    else if ([self.setting isEqualToString:@"delivery"]){
        if (indexPath.row == 0){
            self.firstLabel.text = @"Meetup";
            return self.oneCell;
        }
        else if (indexPath.row ==1){
            self.secondLabel.text = @"Courier";
            return self.twoCell;
        }
    }
    
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
- (IBAction)genderSwitchChanged:(id)sender {
    if (self.segmentContro.selectedSegmentIndex == 0) {
        //men selected
        self.firstLabel.text = @"UK 6";
        self.secondLabel.text = @"UK 7";
        self.thirdLabel.text = @"UK 8";
        self.fourthLabel.text = @"UK 9";
        self.fifthLabel.text = @"UK 10";
        self.sixthLabel.text = @"UK 11";
        self.seventhLabel.text = @"UK 12";
        self.eigthLabel.text = @"UK 13";
        self.ninthLabel.text = @"UK 14";
    }
    else{
        //women selected
        self.firstLabel.text = @"UK 2";
        self.secondLabel.text = @"UK 3";
        self.thirdLabel.text = @"UK 4";
        self.fourthLabel.text = @"UK 5";
        self.fifthLabel.text = @"UK 6";
        self.sixthLabel.text = @"UK 7";
        self.seventhLabel.text = @"UK 8";
        self.eigthLabel.text = @"UK 9";
        self.ninthLabel.text = @"UK 10";
    }
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if ([self.tableView cellForRowAtIndexPath:indexPath] == self.selectCell) {
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
    
    if (indexPath.row == 0) {
        if ([self.tableView cellForRowAtIndexPath:indexPath] == self.selectCell) {
        }
        else{
            selectionString = self.firstLabel.text;
        }
    }
    else if (indexPath.row ==1){
        if ([self.setting isEqualToString:@"sizefoot"]) {
            selectionString = self.firstLabel.text;
        }
        else{
            selectionString = self.secondLabel.text;
        }
    }
    else if (indexPath.row ==2){
        if ([self.setting isEqualToString:@"sizefoot"]) {
            selectionString = self.secondLabel.text;
        }
        else{
            selectionString = self.thirdLabel.text;
        }
    }
    else if (indexPath.row ==3){
        if ([self.setting isEqualToString:@"sizefoot"]) {
            selectionString = self.thirdLabel.text;
        }
        else{
            selectionString = self.fourthLabel.text;
        }
    }
    else if (indexPath.row ==4){
        if ([self.setting isEqualToString:@"sizefoot"]) {
            selectionString = self.fourthLabel.text;
        }
        else{
            selectionString = self.fifthLabel.text;
        }
    }
    else if (indexPath.row ==5){
        if ([self.setting isEqualToString:@"sizefoot"]) {
            selectionString = self.fifthLabel.text;
        }
        else{
            selectionString = self.sixthLabel.text;
        }
    }
    else if (indexPath.row ==6){
        if ([self.setting isEqualToString:@"sizefoot"]) {
            selectionString = self.sixthLabel.text;
        }
        else{
            selectionString = self.seventhLabel.text;
        }
    }
    else if (indexPath.row ==7){
        if ([self.setting isEqualToString:@"sizefoot"]) {
            selectionString = self.seventhLabel.text;
        }
        else{
            selectionString = self.eigthLabel.text;
        }
    }
    else if (indexPath.row ==8){
        if ([self.setting isEqualToString:@"sizefoot"]) {
            selectionString = self.eigthLabel.text;
        }
        else{
            selectionString = self.ninthLabel.text;
        }
    }
    else if (indexPath.row ==9){
        if ([self.setting isEqualToString:@"sizefoot"]) {
            selectionString = self.ninthLabel.text;
        }
        else{
            selectionString = self.tenthLabel.text;
        }
    }
    else if (indexPath.row ==10){
        if ([self.setting isEqualToString:@"sizefoot"]) {
            selectionString = self.tenthLabel.text;
        }
        else{
            selectionString = self.eleventhLabel.text;
        }
    }
    //if not nothing (coz of selection cell in sizes) proceed..
    NSLog(@"selected %@", selectionString);
    
    if (![selectionString isEqualToString:@""]) {
        [self.delegate addItemViewController:self didFinishEnteringItem:selectionString];
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
}

@end
