//
//  FilterVC.m
//  wtbtest
//
//  Created by Jack Ryder on 01/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "FilterVC.h"

@interface FilterVC ()

@end

@implementation FilterVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //hide first table view header
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
    
    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.priceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.conditionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.categoryCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.sizeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.applyCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.filtersArray = [NSMutableArray array];
    NSLog(@"self.send %@", self.sendArray);
    if (self.sendArray) {
        self.filtersArray = self.sendArray;
        NSLog(@"self after %@", self.filtersArray);
        
        //set up previous filters
        if (self.filtersArray.count > 0) {
            if ([self.filtersArray containsObject:@"hightolow"]) {
                [self.hightolowButton setSelected:YES];
            }
            else if ([self.filtersArray containsObject:@"lowtohigh"]){
                [self.lowtoHighButton setSelected:YES];
            }
            else if ([self.filtersArray containsObject:@"new"]){
                [self.newconditionButton setSelected:YES];
            }
            else if ([self.filtersArray containsObject:@"used"]){
                [self.usedButton setSelected:YES];
            }
            else if ([self.filtersArray containsObject:@"clothing"]){
                [self.clothingButton setSelected:YES];
            }
            else if ([self.filtersArray containsObject:@"footwear"]){
                [self.footButton setSelected:YES];
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
    return 6;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 81;
        }
        else if (indexPath.row == 1 || indexPath.row == 2 || indexPath.row == 3){
            return 120;
        }
        else if (indexPath.row == 4){
            return 168;
        }
        else if (indexPath.row == 5){
            return 100;
        }
    }
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.titleCell;
        }
        else if (indexPath.row == 1){
            return self.priceCell;
        }
        else if (indexPath.row == 2){
            return self.conditionCell;
        }
        else if (indexPath.row == 3){
            return self.categoryCell;
        }
        else if (indexPath.row == 4){
            return self.sizeCell;
        }
        else if (indexPath.row == 5){
            return self.applyCell;
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
        return 1.0f;
    return 32.0f;
}

- (NSString*) tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}
- (IBAction)dismissPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)clearPressed:(id)sender {
    [self.hightolowButton setSelected:NO];
    [self.lowtoHighButton setSelected:NO];
    [self.newconditionButton setSelected:NO];
    [self.usedButton setSelected:NO];
    [self.clothingButton setSelected:NO];
    [self.footButton setSelected:NO];
    
    [self.filtersArray removeAllObjects];
}
- (IBAction)hightolowPressed:(id)sender {
    if(self.hightolowButton.selected == YES){
        [self.hightolowButton setSelected:NO];
        [self.filtersArray removeObject:@"hightolow"];
    }
    else{
        [self.hightolowButton setSelected:YES];
        [self.filtersArray addObject:@"hightolow"];
    }
}
- (IBAction)lowtohighPressed:(id)sender {
    if(self.lowtoHighButton.selected == YES){
        [self.lowtoHighButton setSelected:NO];
        [self.filtersArray removeObject:@"lowtohigh"];
    }
    else{
        [self.lowtoHighButton setSelected:YES];
        [self.filtersArray addObject:@"lowtohigh"];
    }
}
- (IBAction)newPressed:(id)sender {
    if(self.newconditionButton.selected == YES){
        [self.newconditionButton setSelected:NO];
        [self.filtersArray removeObject:@"new"];
    }
    else{
        [self.newconditionButton setSelected:YES];
        [self.filtersArray addObject:@"new"];
    }
}
- (IBAction)usedPressed:(id)sender {
    if(self.usedButton.selected == YES){
        [self.usedButton setSelected:NO];
        [self.filtersArray removeObject:@"used"];
    }
    else{
        [self.usedButton setSelected:YES];
        [self.filtersArray addObject:@"used"];
    }
}
- (IBAction)clothingPressed:(id)sender {
    if(self.clothingButton.selected == YES){
        [self.clothingButton setSelected:NO];
        [self.filtersArray removeObject:@"clothing"];
    }
    else{
        [self.clothingButton setSelected:YES];
        [self.filtersArray addObject:@"clothing"];
    }
}
- (IBAction)footwearPressed:(id)sender {
    if(self.footButton.selected == YES){
        [self.footButton setSelected:NO];
        [self.filtersArray removeObject:@"footwear"];
    }
    else{
        [self.footButton setSelected:YES];
        [self.filtersArray addObject:@"footwear"];
    }
}
- (IBAction)applyPressed:(id)sender {
    NSLog(@"apply pressed %@", self.filtersArray);
    [self.delegate filtersReturned:self.filtersArray];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
