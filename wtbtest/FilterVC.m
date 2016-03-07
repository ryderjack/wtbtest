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
            if ([self.filtersArray containsObject:@"new"]){
                [self.newconditionButton setSelected:YES];
            }
            if ([self.filtersArray containsObject:@"used"]){
                [self.usedButton setSelected:YES];
            }
            if ([self.filtersArray containsObject:@"any"]){
                [self.anyButton setSelected:YES];
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
            return 70;
        }
        else if (indexPath.row == 1 || indexPath.row == 2 || indexPath.row == 3){
            return 120;
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
    [self.newconditionButton setSelected:NO];
    [self.usedButton setSelected:NO];
    [self.clothingButton setSelected:NO];
    [self.footButton setSelected:NO];
    [self.menButton setSelected:NO];
    [self.womenButton setSelected:NO];
    [self.lasttapped setSelected:NO];
    [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
    [self.anyButton setSelected:NO];
    
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
- (IBAction)newPressed:(id)sender {
    if(self.newconditionButton.selected == YES){
        [self.newconditionButton setSelected:NO];
        [self.filtersArray removeObject:@"new"];
    }
    else{
        [self.newconditionButton setSelected:YES];
        [self.filtersArray addObject:@"new"];
        [self.usedButton setSelected:NO];
        [self.filtersArray removeObject:@"used"];
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
        [self.newconditionButton setSelected:NO];
        [self.filtersArray removeObject:@"new"];
    }
}
- (IBAction)anyPressed:(id)sender {
    if(self.anyButton.selected == YES){
        [self.usedButton setSelected:NO];
        [self.filtersArray removeObject:@"any"];
    }
    else{
        [self.anyButton setSelected:YES];
        [self.filtersArray addObject:@"any"];
        [self.newconditionButton setSelected:NO];
        [self.filtersArray removeObject:@"new"];
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
        
        //set up horizontal scroll view for clothing
        [self setupclothingsizes];
        //if filter array contains shoe sizes, remove these
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
            NSLog(@"2 pressed");
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"XXS"];
                }
                else{
                    [self.filtersArray removeObject:@"2"];
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
                    [self.filtersArray addObject:@"2"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                
            }
        }
        else if(btn.tag == 1){
            NSLog(@"3 pressed");
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"XS"];
                }
                else{
                    [self.filtersArray removeObject:@"3"];
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
                    [self.filtersArray addObject:@"3"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 2){
            NSLog(@"4 pressed");
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
            NSLog(@"5 pressed");
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"M"];
                }
                else{
                    [self.filtersArray removeObject:@"5"];
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
                    [self.filtersArray addObject:@"5"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
                
            }
        }
        else if(btn.tag == 4){
            NSLog(@"6 pressed");
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"L"];
                }
                else{
                    [self.filtersArray removeObject:@"6"];
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
                    [self.filtersArray addObject:@"6"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 5){
            NSLog(@"7 pressed");
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"XL"];
                }
                else{
                    [self.filtersArray removeObject:@"7"];
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
                    [self.filtersArray addObject:@"7"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 6){
            NSLog(@"8 pressed");
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"XXL"];
                }
                else{
                    [self.filtersArray removeObject:@"8"];
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
                    [self.filtersArray addObject:@"8"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 7){
            NSLog(@"9 pressed");
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"OS"];
                }
                else{
                    [self.filtersArray removeObject:@"9"];
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
                    [self.filtersArray addObject:@"9"];
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%ld",(long)self.lasttapped.tag+2]];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor colorWithRed:0.961 green:0.651 blue:0.137 alpha:1]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 8){
            NSLog(@"10 pressed");
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
        else if(btn.tag == 9){
            NSLog(@"11 pressed");
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
        else if(btn.tag == 10){
            NSLog(@"12 pressed");
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
        else if(btn.tag == 11){
            NSLog(@"13 pressed");
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
        else if(btn.tag == 12){
            NSLog(@"14 pressed");
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
    
    for (int k = 2; k<15; k++) {
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
    for (int i = 0; i < 13; i++) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        if (i == 0) {
            frame = CGRectMake(10, 10, 50, 50);
        } else {
            frame = CGRectMake((i * 50) + (i*20) + 10, 10, 50, 50);
        }
        
        button.frame = frame;
        [button setTitle:[NSString stringWithFormat:@"%d", i+2] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTag:i];
        [button setBackgroundColor:[UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1]];
        button.layer.borderWidth = 0.0;
        button.clipsToBounds = YES;
        
        //half of the width
        button.layer.cornerRadius = 50/2.0f;
        [button addTarget:self action:@selector(sizeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.sizeScrollButton addSubview:button];
        
        if (i == 12) {
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
