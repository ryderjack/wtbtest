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
    
    self.sizeScrollButton.backgroundColor = [UIColor clearColor];
    self.sizeLabels = [NSArray arrayWithObjects:@"XXS", @"XS", @"S", @"M", @"L", @"XL", @"XXL", @"OS", nil];
    
    self.shoesArray = [NSArray arrayWithObjects:@"3", @"3.5",@"4", @"4.5", @"5", @"5.5", @"6",@"6.5",@"7", @"7.5", @"8",@"8.5",@"9", @"9.5", @"10",@"10.5",@"11", @"11.5", @"12",@"12.5",@"13", @"13.5", @"14", nil];
    
    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.priceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.conditionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.categoryCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.sizeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.applyCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    //sendarray containts the filters selected last time. Use to select previous search buttons & relevant sizing buttons
    self.filtersArray = [NSMutableArray array];
    NSLog(@"self.send %@", self.sendArray);
    if (self.sendArray) {
        self.filtersArray = self.sendArray;
        
        //set up previous filters
        if (self.filtersArray.count > 0) {
            if ([self.filtersArray containsObject:@"hightolow"]) {
                [self.hightolowButton setSelected:YES];
            }
            if ([self.filtersArray containsObject:@"lowtohigh"]){
                [self.lowtoHighButton setSelected:YES];
            }
            if ([self.filtersArray containsObject:@"BNWT"]){
                [self.BNWTconditionButton setSelected:YES];
            }
            if ([self.filtersArray containsObject:@"used"]){
                [self.usedButton setSelected:YES];
            }
            if ([self.filtersArray containsObject:@"BNWOT"]){
                [self.BNWOTButton setSelected:YES];
            }
            
            if ([self.filtersArray containsObject:@"clothing"]){
                [self.clothingButton setSelected:YES];
                self.clothingEnabled = YES;
                [self setupclothingsizes];
            }
            else if ([self.filtersArray containsObject:@"footwear"]){
                [self.footButton setSelected:YES];
                self.clothingEnabled = NO;
                [self setupFootwearSizes];
            }
            else{
                self.clothingEnabled = YES;
                [self setupclothingsizes];
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
        self.clothingEnabled = YES;
        [self setupclothingsizes];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of BNWOT resources that can be recreated.
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
            return 59;
        }
        else if (indexPath.row == 1 || indexPath.row == 2 || indexPath.row == 3){
            return 101;
        }
        else if (indexPath.row == 4){
            return 182;
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
    if (self.filtersArray.count == 0) {
        [self.delegate filtersReturned:self.filtersArray];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)clearPressed:(id)sender {
    [self.hightolowButton setSelected:NO];
    [self.lowtoHighButton setSelected:NO];
    [self.BNWTconditionButton setSelected:NO];
    [self.usedButton setSelected:NO];
    [self.clothingButton setSelected:NO];
    [self.footButton setSelected:NO];
    [self.menButton setSelected:NO];
    [self.womenButton setSelected:NO];
    [self.lasttapped setSelected:NO];
    [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
    [self.BNWOTButton setSelected:NO];
    
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
        [self.lowtoHighButton setSelected:NO];
        [self.filtersArray removeObject:@"lowtohigh"];
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
        [self.hightolowButton setSelected:NO];
        [self.filtersArray removeObject:@"hightolow"];
    }
}
- (IBAction)BNWTPressed:(id)sender {
    if(self.BNWTconditionButton.selected == YES){
        [self.BNWTconditionButton setSelected:NO];
        [self.filtersArray removeObject:@"BNWT"];
    }
    else{
        [self.BNWTconditionButton setSelected:YES];
        [self.filtersArray addObject:@"BNWT"];
        [self.usedButton setSelected:NO];
        [self.filtersArray removeObject:@"used"];
        [self.BNWOTButton setSelected:NO];
        [self.filtersArray removeObject:@"BNWOT"];
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
        [self.BNWTconditionButton setSelected:NO];
        [self.filtersArray removeObject:@"BNWT"];
        [self.BNWOTButton setSelected:NO];
        [self.filtersArray removeObject:@"BNWOT"];
    }
}
- (IBAction)BNWOTPressed:(id)sender {
    if(self.BNWOTButton.selected == YES){
        [self.BNWOTButton setSelected:NO];
        [self.filtersArray removeObject:@"BNWOT"];
    }
    else{
        [self.BNWOTButton setSelected:YES];
        [self.filtersArray addObject:@"BNWOT"];
        [self.BNWTconditionButton setSelected:NO];
        [self.filtersArray removeObject:@"BNWT"];
        [self.usedButton setSelected:NO];
        [self.filtersArray removeObject:@"used"];
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
        [self.footButton setSelected:NO];
        [self.filtersArray removeObject:@"footwear"];
        
        [self setupclothingsizes];
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
        [self.clothingButton setSelected:NO];
        [self.filtersArray removeObject:@"clothing"];
        
        [self setupFootwearSizes];
    }
}
- (IBAction)applyPressed:(id)sender {
    NSLog(@"apply pressed %@", self.filtersArray);
    [self.delegate filtersReturned:self.filtersArray];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)sizeButtonClicked:(id) sender{
    if ([sender isMemberOfClass:[UIButton class]])
    {
        UIButton *btn = (UIButton *)sender;
        if(btn.tag == 0){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"XXS"];
                }
                else{
                    [self.filtersArray removeObject:@"3"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray addObject:@"XXS"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@", self.lasttapped.titleLabel.text]];
                }
                else{
                    [self.filtersArray addObject:@"3"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                
            }
        }
        else if(btn.tag == 1){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"XS"];
                }
                else{
                    [self.filtersArray removeObject:@"3.5"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray addObject:@"XS"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@", self.lasttapped.titleLabel.text]];
                }
                else{
                    [self.filtersArray addObject:@"3.5"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 2){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"S"];
                }
                else{
                    [self.filtersArray removeObject:@"4"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray addObject:@"S"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@", self.lasttapped.titleLabel.text]];
                }
                else{
                    [self.filtersArray addObject:@"4"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 3){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"M"];
                }
                else{
                    [self.filtersArray removeObject:@"4.5"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray addObject:@"M"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@", self.lasttapped.titleLabel.text]];
                }
                else{
                    [self.filtersArray addObject:@"4.5"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                
            }
        }
        else if(btn.tag == 4){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"L"];
                }
                else{
                    [self.filtersArray removeObject:@"5"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray addObject:@"L"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@", self.lasttapped.titleLabel.text]];
                }
                else{
                    [self.filtersArray addObject:@"5"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 5){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"XL"];
                }
                else{
                    [self.filtersArray removeObject:@"5.5"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray addObject:@"XL"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@", self.lasttapped.titleLabel.text]];
                }
                else{
                    [self.filtersArray addObject:@"5.5"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 6){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"XXL"];
                }
                else{
                    [self.filtersArray removeObject:@"6"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray addObject:@"XXL"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@", self.lasttapped.titleLabel.text]];
                }
                else{
                    [self.filtersArray addObject:@"6"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 7){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"OS"];
                }
                else{
                    [self.filtersArray removeObject:@"6.5"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray addObject:@"OS"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@", self.lasttapped.titleLabel.text]];
                }
                else{
                    [self.filtersArray addObject:@"6.5"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 8){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"7"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"7"];
            }
        }
        else if(btn.tag == 9){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"7.5"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"7.5"];
            }
        }
        else if(btn.tag == 10){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"8"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"8"];
            }
        }
        else if(btn.tag == 11){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"8.5"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"8.5"];
            }
        }
        else if(btn.tag == 12){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"9"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"9"];
            }
        }
        else if(btn.tag == 13){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"9.5"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"9.5"];
            }
        }
        else if(btn.tag == 14){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"10"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"10"];
            }
        }
        else if(btn.tag == 15){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"10.5"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"10.5"];
            }
        }
        else if(btn.tag == 16){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"11"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"11"];
            }
        }
        else if(btn.tag == 17){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"11.5"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"11.5"];
            }
        }
        else if(btn.tag == 18){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"12"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"12"];
            }
        }
        else if(btn.tag == 19){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"12.5"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"12.5"];
            }
        }
        else if(btn.tag == 20){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"13"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"13"];
            }
        }
        else if(btn.tag == 21){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"13.5"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"13.5"];
            }
        }
        else if(btn.tag == 22){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:@"14"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"14"];
            }
        }
    }
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
}

-(void)setupclothingsizes{
    [[self.sizeScrollButton subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.clothingEnabled = YES;
    
    int x = 0;
    CGRect frame;
    for (int i = 0; i <8; i++) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        if (i == 0) {
            frame = CGRectMake(10, 10, 50, 50);
        } else {
            frame = CGRectMake((i * 50) + (i*20) + 10, 10, 50, 50);
        }
        
        button.frame = frame;
        [button setTitle:[NSString stringWithFormat:@"%@", self.sizeLabels[i]] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTag:i];
        [button setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
        button.layer.borderWidth = 0.0;
        //Clip/Clear the other pieces whichever outside the rounded corner
        button.clipsToBounds = YES;
        
        //half of the width
        button.layer.cornerRadius = 50/2.0f;
        [button addTarget:self action:@selector(sizeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.sizeScrollButton addSubview:button];
        
        if (i == 7) {
            x = CGRectGetMaxX(button.frame);
        }
        
        if ([self.filtersArray containsObject:button.titleLabel.text]){
            [button setSelected:YES];
            [button setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
            self.lasttapped = button;
        }
    }
    self.sizeScrollButton.contentSize = CGSizeMake(x, self.sizeScrollButton.frame.size.height);
    
    for (int k = 2; k<23; k++) {
        if ([self.filtersArray containsObject:[NSString stringWithFormat:@"%d", k]]) {
            [self.filtersArray removeObject:[NSString stringWithFormat:@"%d", k]];
        }
    }
}

-(void)setupFootwearSizes{
    [[self.sizeScrollButton subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.clothingEnabled = NO;
    
    int x = 0;
    CGRect frame;
    for (int i = 0; i < 23; i++) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        if (i == 0) {
            frame = CGRectMake(10, 10, 50, 50);
        } else {
            frame = CGRectMake((i * 50) + (i*20) + 10, 10, 50, 50);
        }
        
        button.frame = frame;
        [button setTitle:[NSString stringWithFormat:@"%@", self.shoesArray[i]] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTag:i];
        [button setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
        button.layer.borderWidth = 0.0;
        button.clipsToBounds = YES;
        
        //half of the width to get circles
        button.layer.cornerRadius = 50/2.0f;
        [button addTarget:self action:@selector(sizeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.sizeScrollButton addSubview:button];
        
        if (i == 22) {
            x = CGRectGetMaxX(button.frame);
        }
        
        if ([self.filtersArray containsObject:button.titleLabel.text]){
            [button setSelected:YES];
            [button setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
            self.lasttapped = button;
        }
    }
    self.sizeScrollButton.contentSize = CGSizeMake(x, self.sizeScrollButton.frame.size.height);
    
    for (int k = 0; k<8; k++) {
        if ([self.filtersArray containsObject:self.sizeLabels[k]]) {
            [self.filtersArray removeObject:self.sizeLabels[k]];
        }
    }
}

@end
