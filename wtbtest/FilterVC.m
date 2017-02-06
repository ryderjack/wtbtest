//
//  FilterVC.m
//  wtbtest
//
//  Created by Jack Ryder on 01/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "FilterVC.h"
#import "brandObject.h"
#import <Crashlytics/Crashlytics.h>

@interface FilterVC ()

@end

@implementation FilterVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:0.9];
    
    //hide first table view header
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
    
    self.sizeScrollButton.backgroundColor = [UIColor clearColor];
    self.brandScrollView.backgroundColor = [UIColor clearColor];
    
    self.sizeLabels = [NSArray arrayWithObjects:@"XXS", @"XS", @"S", @"M", @"L", @"XL", @"XXL", nil];
    
    self.shoesArray = [NSArray arrayWithObjects:@"3", @"3.5",@"4", @"4.5", @"5", @"5.5", @"6",@"6.5",@"7", @"7.5", @"8",@"8.5",@"9", @"9.5", @"10",@"10.5",@"11", @"11.5", @"12",@"12.5",@"13", @"13.5", @"14", nil];
    
    self.brandImageArray = [NSArray arrayWithObjects:@"adidas", @"nike",@"palace", @"stoney", @"supreme", @"ralph",nil];
    self.brandNamesArray = [NSArray arrayWithObjects:@"Adidas",@"Nike",@"Palace", @"Stone Island", @"Supreme", @"Ralph Lauren",nil];
    
    self.titleCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.priceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.conditionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.categoryCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.sizeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.applyCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.brandCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.distanceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.sizeScrollButton.frame = CGRectMake(0, 0, self.view.frame.size.width, 67);

    //sendarray containts the filters selected last time. Use to select previous search buttons & relevant sizing buttons
    self.filtersArray = [NSMutableArray array];
    if (self.sendArray) {
        self.filtersArray = self.sendArray;
        
        //set up previous filters
        if (self.filtersArray.count > 0) {
            
            self.titleLabel.text = [NSString stringWithFormat:@"F I L T E R S  %lu", self.filtersArray.count];
            
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
            if ([self.filtersArray containsObject:@"aroundMe"]) {
                [self.distanceButton setSelected:YES];
            }
            
            if ([self.filtersArray containsObject:@"clothing"]){
                [self.clothingButton setSelected:YES];
                self.clothingEnabled = YES;
                [self setupclothingsizes];
                
                [self.menButton setEnabled:NO];
                [self.womenButton setEnabled:NO];
            }
            else if ([self.filtersArray containsObject:@"footwear"]){
                [self.footButton setSelected:YES];
                self.clothingEnabled = NO;
                [self setupFootwearSizes];
                [self.menButton setEnabled:YES];
                [self.womenButton setEnabled:YES];
                
            }
            else if ([self.filtersArray containsObject:@"accessory"]){
                [self.accessoryButton setSelected:YES];
                self.clothingEnabled = NO;
                [self setupFootwearSizes];
                [self.menButton setEnabled:NO];
                [self.womenButton setEnabled:NO];
                
            }
            else{
                self.clothingEnabled = YES;
                [self setupclothingsizes];
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

        self.clothingEnabled = YES;
        [self setupclothingsizes];
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
    

    
//    self.tableView.tableFooterView = footerView;
    
//    [self setupBrandButtons];
//    self.adidasImageView  = [[UIImageView alloc]init];
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
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
//        if (indexPath.row == 0) {
//            return 59;
//        }
        if (indexPath.row == 0){
            return 101;
        }
        else if (indexPath.row == 1){
            return 88;
        }
        else if (indexPath.row == 2){
            return 122;
        }
        else if (indexPath.row == 3){
            return 122;
        }
//        else if (indexPath.row == 4){ UNCOMMENT FOR BRANDS
//            return 159;
//        }
        else if (indexPath.row == 4){
            return 230;
        }
//        else if (indexPath.row == 5){
//            return 100;
//        }
    }
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.titleCell;
        }
//        else if (indexPath.row == 1){
//            return self.priceCell;
//        }
        else if (indexPath.row == 1){
            return self.distanceCell;
        }
        else if (indexPath.row == 2){
            return self.conditionCell;
        }
        else if (indexPath.row == 3){
            return self.categoryCell;
        }
//        else if (indexPath.row == 4){
//            return self.brandCell;
//        }
        else if (indexPath.row == 4){
            return self.sizeCell;
        }
//        else if (indexPath.row == 5){
//            return self.applyCell;
//        }
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

-(void)updateTitle{
    if (self.filtersArray.count > 0) {
        self.titleLabel.text = [NSString stringWithFormat:@"F I L T E R S  %lu", self.filtersArray.count];
    }
    else{
        self.titleLabel.text = @"F I L T E R S";
        
    }
}
- (IBAction)dismissPressed:(id)sender {
    if (self.filtersArray.count == 0) {
        [self.delegate filtersReturned:self.filtersArray];
    }
    else{
        [self.delegate noChange];
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
    [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
    [self.BNWOTButton setSelected:NO];
    [self.distanceButton setSelected:NO];
    [self.accessoryButton setSelected:NO];
    
    [self.filtersArray removeAllObjects];
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
- (IBAction)BNWTPressed:(id)sender {
    if(self.BNWTconditionButton.selected == YES){
        [self.BNWTconditionButton setSelected:NO];
        [self.filtersArray removeObject:@"BNWT"];
    }
    else{
        [Answers logCustomEventWithName:@"Filters enabled"
                       customAttributes:@{
                                          @"filter":@"BNWT"
                                          }];
        [self.BNWTconditionButton setSelected:YES];
        [self.filtersArray addObject:@"BNWT"];
        [self.usedButton setSelected:NO];
        [self.filtersArray removeObject:@"used"];
        [self.BNWOTButton setSelected:NO];
        [self.filtersArray removeObject:@"BNWOT"];
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
        [self.BNWTconditionButton setSelected:NO];
        [self.filtersArray removeObject:@"BNWT"];
        [self.BNWOTButton setSelected:NO];
        [self.filtersArray removeObject:@"BNWOT"];
    }
    [self updateTitle];
}
- (IBAction)BNWOTPressed:(id)sender {
    if(self.BNWOTButton.selected == YES){
        [self.BNWOTButton setSelected:NO];
        [self.filtersArray removeObject:@"BNWOT"];
    }
    else{
        [Answers logCustomEventWithName:@"Filters enabled"
                       customAttributes:@{
                                          @"filter":@"BNWOT"
                                          }];
        [self.BNWOTButton setSelected:YES];
        [self.filtersArray addObject:@"BNWOT"];
        [self.BNWTconditionButton setSelected:NO];
        [self.filtersArray removeObject:@"BNWT"];
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
        
        [self setupclothingsizes];
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
        
        [self setupclothingsizes];
    }
    else{
        [Answers logCustomEventWithName:@"Filters enabled"
                       customAttributes:@{
                                          @"filter":@"accessories"
                                          }];
        [self.accessoryButton setSelected:YES];
        [self.filtersArray addObject:@"accessory"];
        
        [[self.sizeScrollButton subviews]
         makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        [[self.sizeScrollButton subviews]
         makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        [self.clothingButton setSelected:NO];
        [self.filtersArray removeObject:@"clothing"];
        
        [self.footButton setSelected:NO];
        [self.filtersArray removeObject:@"footwear"];
        
        [self.menButton setEnabled:NO];
        [self.womenButton setEnabled:NO];
        
    }
    [self updateTitle];
}

-(void)applyButtonPressed{
    [Answers logCustomEventWithName:@"Filters applied"
                   customAttributes:@{}];
    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:self.filtersArray];
    NSArray *arrayWithoutDuplicates = [orderedSet array];
    NSMutableArray *noduplicates = [NSMutableArray arrayWithArray:arrayWithoutDuplicates];
    NSLog(@"without duplicates %@", noduplicates);
    [self.delegate filtersReturned:noduplicates];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)sizeButtonClicked:(id) sender{
    [Answers logCustomEventWithName:@"Filters enabled"
                   customAttributes:@{
                                      @"filter":@"size chosen"
                                      }];
    if ([sender isMemberOfClass:[UIButton class]])
    {
        UIButton *btn = (UIButton *)sender;
        if(btn.tag == 0){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"XXS"];
                }
                else{
                    [self.filtersArray removeObject:@"3"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@", self.lasttapped.titleLabel.text]];
                    [self.filtersArray addObject:@"XXS"];
                }
                else{
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                    [self.filtersArray addObject:@"3"];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 1){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"XS"];
                }
                else{
                    [self.filtersArray removeObject:@"3.5"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@", self.lasttapped.titleLabel.text]];
                    [self.filtersArray addObject:@"XS"];
                }
                else{
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                    [self.filtersArray addObject:@"3.5"];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 2){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"S"];
                }
                else{
                    [self.filtersArray removeObject:@"4"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                    [self.filtersArray addObject:@"S"];
                }
                else{
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                    [self.filtersArray addObject:@"4"];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 3){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"M"];
                }
                else{
                    [self.filtersArray removeObject:@"4.5"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                    [self.filtersArray addObject:@"M"];
                }
                else{
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                    [self.filtersArray addObject:@"4.5"];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 4){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"L"];
                }
                else{
                    [self.filtersArray removeObject:@"5"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@", self.lasttapped.titleLabel.text]];
                    [self.filtersArray addObject:@"L"];
                }
                else{
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                    [self.filtersArray addObject:@"5"];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 5){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"XL"];
                }
                else{
                    [self.filtersArray removeObject:@"5.5"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@", self.lasttapped.titleLabel.text]];
                    [self.filtersArray addObject:@"XL"];
                }
                else{
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                    [self.filtersArray addObject:@"5.5"];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 6){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:@"XXL"];
                }
                else{
                    [self.filtersArray removeObject:@"6"];
                }
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                if (self.clothingEnabled == YES) {
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@", self.lasttapped.titleLabel.text]];
                    [self.filtersArray addObject:@"XXL"];
                }
                else{
                    [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                    [self.filtersArray addObject:@"6"];
                }
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
            }
        }
        else if(btn.tag == 7){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"6.5"];
                NSLog(@"removing");

            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [self.filtersArray addObject:@"6.5"];

                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                NSLog(@"adding");
            }
        }
        else if(btn.tag == 8){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"7"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"7"];
            }
        }
        else if(btn.tag == 9){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"7.5"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"7.5"];
            }
        }
        else if(btn.tag == 10){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"8"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"8"];
            }
        }
        else if(btn.tag == 11){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"8.5"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"8.5"];
            }
        }
        else if(btn.tag == 12){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"9"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"9"];
            }
        }
        else if(btn.tag == 13){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"9.5"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"9.5"];
            }
        }
        else if(btn.tag == 14){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"10"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"10"];
            }
        }
        else if(btn.tag == 15){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"10.5"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"10.5"];
            }
        }
        else if(btn.tag == 16){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"11"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"11"];
            }
        }
        else if(btn.tag == 17){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"11.5"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"11.5"];
            }
        }
        else if(btn.tag == 18){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"12"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"12"];
            }
        }
        else if(btn.tag == 19){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"12.5"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"12.5"];
            }
        }
        else if(btn.tag == 20){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"13"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"13"];
            }
        }
        else if(btn.tag == 21){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"13.5"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"13.5"];
            }
        }
        else if(btn.tag == 22){
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [btn setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:@"14"];
            }
            else{
                [self.lasttapped setSelected:NO];
                [self.lasttapped setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
                [self.filtersArray removeObject:[NSString stringWithFormat:@"%@",self.lasttapped.titleLabel.text]];
                [btn setSelected:YES];
                [btn setBackgroundColor:[UIColor whiteColor]];
                self.lasttapped = btn;
                [self.filtersArray addObject:@"14"];
            }
        }
    }
    [self updateTitle];
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

-(void)setupclothingsizes{
    [Answers logCustomEventWithName:@"Filters enabled"
                   customAttributes:@{
                                      @"filter":@"setupclothing"
                                      }];
    [[self.sizeScrollButton subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.clothingEnabled = YES;
    
    int x = 0;
    CGRect frame;
    for (int i = 0; i <7; i++) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        if (i == 0) {
            frame = CGRectMake(10, 10, 50, 50);
        } else {
            frame = CGRectMake((i * 50) + (i*20) + 10, 10, 50, 50);
        }
        
        button.frame = frame;
        [button setTitle:[NSString stringWithFormat:@"%@", self.sizeLabels[i]] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0] forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:12]];
        [button setTag:i];
        [button setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
        button.layer.borderWidth = 0.0;
        //Clip/Clear the other pieces whichever outside the rounded corner
        button.clipsToBounds = YES;
        
        //half of the width
        button.layer.cornerRadius = 50/2.0f;
        [button addTarget:self action:@selector(sizeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.sizeScrollButton addSubview:button];
        
        if (i == 6) {
            x = CGRectGetMaxX(button.frame);
        }
        
        if ([self.filtersArray containsObject:button.titleLabel.text]){
            [button setSelected:YES];
            [button setBackgroundColor:[UIColor whiteColor]];
            self.lasttapped = button;
            NSLog(@"just set last tapped setting up clothing %@", self.lasttapped.titleLabel.text);
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
    [Answers logCustomEventWithName:@"Filters enabled"
                   customAttributes:@{
                                      @"filter":@"setupfootwear"
                                      }];
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
        [button setTitleColor:[UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0] forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:12]];
        [button setTag:i];
        [button setBackgroundColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
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
            [button setBackgroundColor:[UIColor whiteColor]];
            self.lasttapped = button;
            NSLog(@"just set last tapped setting up shoes %@", self.lasttapped.titleLabel.text);
        }
    }
    self.sizeScrollButton.contentSize = CGSizeMake(x, self.sizeScrollButton.frame.size.height);
    
    for (int k = 0; k<7; k++) {
        if ([self.filtersArray containsObject:self.sizeLabels[k]]) {
            [self.filtersArray removeObject:self.sizeLabels[k]];
        }
    }
}

-(void)setupBrandButtons{
    int x = 0;
    CGRect frame;
    for (int i = 0; i < self.brandImageArray.count; i++) {
        UIView *view = [[UIView alloc]init];
        
        if (i == 0) {
            frame = CGRectMake(10, 5, 70, 100);
        } else {
            frame = CGRectMake((i * 50) + (i*50) + 20, 5, 70, 100);
        }
        
        view.frame = frame;
        
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake((view.frame.size.width/2)-33, 0, 66, 66)];
        imageView.backgroundColor = [UIColor blackColor];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [view addSubview:imageView];
        [imageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@", self.brandImageArray[i]]]];
        
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake((view.frame.size.width/2)-30, 70, 60, 20)];
        label.backgroundColor = [UIColor blackColor];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:12]];
        label.textColor = [UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor=0.5;
        [view addSubview:label];
        label.text = [NSString stringWithFormat:@"%@", self.brandNamesArray[i]];
        
        [view setBackgroundColor:[UIColor blackColor]];
        [self.brandScrollView addSubview:view];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
//        button.backgroundColor = [UIColor greenColor];
        button.frame = imageView.frame;
        [button setTag:i];
        [button addTarget:self action:@selector(brandClicked:) forControlEvents:UIControlEventTouchUpInside];
        [view insertSubview:button aboveSubview:imageView];
        
        if (i == 0) {
            self.adidas = [[brandObject alloc]init];
            self.adidas.imageView = imageView;
            self.adidas.name = @"adidas";
            self.adidas.button = button;
            self.adidas.label = label;
        }
        else if (i == 1){
            self.nike = [[brandObject alloc]init];
            self.nike.imageView = imageView;
            self.nike.name = @"nike";
            self.nike.button = button;
            self.nike.label = label;
        }
        else if (i == 2){
            self.palace = [[brandObject alloc]init];
            self.palace.imageView = imageView;
            self.palace.name = @"palace";
            self.palace.button = button;
            self.palace.label = label;
        }
        else if (i == 3){
            self.stoney = [[brandObject alloc]init];
            self.stoney.imageView = imageView;
            self.stoney.name = @"stoney";
            self.stoney.button = button;
            self.stoney.label = label;
        }
        else if (i == 4){
            self.supreme = [[brandObject alloc]init];
            self.supreme.imageView = imageView;
            self.supreme.name = @"supreme";
            self.supreme.button = button;
            self.supreme.label = label;
        }
        else if (i == 5){
            self.ralph = [[brandObject alloc]init];
            self.ralph.imageView = imageView;
            self.ralph.name = @"ralph";
            self.ralph.button = button;
            self.ralph.label = label;
        }
        
        if (i == self.brandImageArray.count-1) {
            x = CGRectGetMaxX(view.frame);
        }
        
        if ([self.filtersArray containsObject:label.text]){
            [button setSelected:YES];
            [button setBackgroundColor:[UIColor whiteColor]];
            self.lastBrandTapped = label.text;
        }
    }
    self.brandScrollView.contentSize = CGSizeMake(x, self.brandScrollView.frame.size.height);
}

-(void)brandClicked:(id) sender{
    if ([sender isMemberOfClass:[UIButton class]])
    {
        UIButton *btn = (UIButton *)sender;
        NSLog(@"brand tapped %li with current filters %@", (long)btn.tag, self.filtersArray);
        
        if (btn.tag == 0) {
            //adidas tapped
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [self.filtersArray removeObject:@"adidas"];
                
                //change image back to grey
                [self.adidas.imageView setImage:[UIImage imageNamed:@"adidas"]];
                [self.adidas.label setTextColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
            }
            else{
                
                //deselect last button/reset its imageView/remove from filters
                [self.lastBrandButtonTapped setSelected:NO];
                [self.filtersArray removeObject:self.lastBrandTapped];
                [self.lastBrandImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@", self.lastBrandTapped]]];
                [self.lastLabelTapped setTextColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];

                //set this brand as selected
                [btn setSelected:YES];
                [self.adidas.imageView setImage:[UIImage imageNamed:@"adidasSelected"]];
                [self.adidas.label setTextColor:[UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1.0]];
                
                self.lastBrandTapped = @"adidas";
                self.lastBrandButtonTapped = btn;
                self.lastBrandImageView = self.adidas.imageView;
                self.lastLabelTapped = self.adidas.label;
                
                [self.filtersArray addObject:@"adidas"];
            }
        }
        else if (btn.tag == 1) {
            //nike
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [self.filtersArray removeObject:@"nike"];
                
                //change image back to grey
                [self.nike.imageView setImage:[UIImage imageNamed:@"nike"]];
                [self.nike.label setTextColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
            }
            else{
                
                //deselect last button/reset its imageView/remove from filters
                [self.lastBrandButtonTapped setSelected:NO];
                [self.filtersArray removeObject:self.lastBrandTapped];
                [self.lastBrandImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@", self.lastBrandTapped]]];
                [self.lastLabelTapped setTextColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];

                //set this brand as selected
                [btn setSelected:YES];
                [self.nike.imageView setImage:[UIImage imageNamed:@"nikeSelected"]];
                [self.nike.label setTextColor:[UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1.0]];
                
                self.lastBrandTapped = @"nike";
                self.lastBrandButtonTapped = btn;
                self.lastBrandImageView = self.nike.imageView;
                self.lastLabelTapped = self.nike.label;
                
                [self.filtersArray addObject:@"nike"];
            }
        }
        else if (btn.tag == 2) {
            //palace
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [self.filtersArray removeObject:@"palace"];
                
                //change image back to grey
                [self.palace.imageView setImage:[UIImage imageNamed:@"palace"]];
                [self.palace.label setTextColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
            }
            else{
                
                //deselect last button/reset its imageView/remove from filters
                [self.lastBrandButtonTapped setSelected:NO];
                [self.filtersArray removeObject:self.lastBrandTapped];
                [self.lastBrandImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@", self.lastBrandTapped]]];
                [self.lastLabelTapped setTextColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];

                //set this brand as selected
                [btn setSelected:YES];
                [self.palace.imageView setImage:[UIImage imageNamed:@"palaceSelected"]];
                [self.palace.label setTextColor:[UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1.0]];
                
                self.lastBrandTapped = @"palace";
                self.lastBrandButtonTapped = btn;
                self.lastBrandImageView = self.palace.imageView;
                self.lastLabelTapped = self.palace.label;
                
                [self.filtersArray addObject:@"palace"];
            }
        }
        else if (btn.tag == 3) {
            //Stone Island
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [self.filtersArray removeObject:@"stoney"];
                
                //change image back to grey
                [self.stoney.imageView setImage:[UIImage imageNamed:@"stoney"]];
                [self.stoney.label setTextColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
            }
            else{
                //deselect last button/reset its imageView/remove from filters
                [self.lastBrandButtonTapped setSelected:NO];
                [self.filtersArray removeObject:self.lastBrandTapped];
                [self.lastBrandImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@", self.lastBrandTapped]]];
                [self.lastLabelTapped setTextColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];

                //set this brand as selected
                [btn setSelected:YES];
                [self.stoney.imageView setImage:[UIImage imageNamed:@"stoneySelected"]];
                [self.stoney.label setTextColor:[UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1.0]];
                
                self.lastBrandTapped = @"stoney";
                self.lastBrandButtonTapped = btn;
                self.lastBrandImageView = self.stoney.imageView;
                self.lastLabelTapped = self.stoney.label;
                
                [self.filtersArray addObject:@"stoney"];
            }
        }
        else if (btn.tag == 4) {
            //Supreme
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [self.filtersArray removeObject:@"supreme"];
                
                //change image back to grey
                [self.supreme.imageView setImage:[UIImage imageNamed:@"supreme"]];
                [self.supreme.label setTextColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
            }
            else{
                
                //deselect last button/reset its imageView/remove from filters
                [self.lastBrandButtonTapped setSelected:NO];
                [self.filtersArray removeObject:self.lastBrandTapped];
                [self.lastBrandImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@", self.lastBrandTapped]]];
                [self.lastLabelTapped setTextColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];

                //set this brand as selected
                [btn setSelected:YES];
                [self.supreme.imageView setImage:[UIImage imageNamed:@"supremeSelected"]];
                [self.supreme.label setTextColor:[UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1.0]];
                
                self.lastBrandTapped = @"supreme";
                self.lastBrandButtonTapped = btn;
                self.lastBrandImageView = self.supreme.imageView;
                self.lastLabelTapped = self.supreme.label;
                
                [self.filtersArray addObject:@"supreme"];
            }
        }
        else if (btn.tag == 5) {
            //Ralphy
            if (btn.selected == YES) {
                [btn setSelected:NO];
                [self.filtersArray removeObject:@"ralph"];
                
                //change image back to grey
                [self.ralph.imageView setImage:[UIImage imageNamed:@"ralph"]];
                [self.ralph.label setTextColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];
            }
            else{
                
                //deselect last button/reset its imageView/remove from filters
                [self.lastBrandButtonTapped setSelected:NO];
                [self.filtersArray removeObject:self.lastBrandTapped];
                [self.lastBrandImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@", self.lastBrandTapped]]];
                [self.lastLabelTapped setTextColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1.0]];

                //set this brand as selected
                [btn setSelected:YES];
                [self.ralph.imageView setImage:[UIImage imageNamed:@"ralphSelected"]];
                [self.ralph.label setTextColor:[UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1.0]];
                
                self.lastBrandTapped = @"ralph";
                self.lastBrandButtonTapped = btn;
                self.lastBrandImageView = self.ralph.imageView;
                self.lastLabelTapped = self.ralph.label;
                
                [self.filtersArray addObject:@"ralph"];
            }
        }
    }
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

@end
