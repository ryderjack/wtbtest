//
//  ConditionsOptionsTableView.m
//  wtbtest
//
//  Created by Jack Ryder on 09/07/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "ConditionsOptionsTableView.h"

@interface ConditionsOptionsTableView ()

@end

@implementation ConditionsOptionsTableView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    self.title = @"C O N D I T I O N";
    
    self.firstBody.adjustsFontSizeToFitWidth = YES;
    self.firstBody.minimumScaleFactor=0.5;
    
    self.secondBody.adjustsFontSizeToFitWidth = YES;
    self.secondBody.minimumScaleFactor=0.5;
    
    self.thirdBody.adjustsFontSizeToFitWidth = YES;
    self.thirdBody.minimumScaleFactor=0.5;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    //setup already selected condition
    if ([self.selection isEqualToString:@"Deadstock"]) {
        [self.firstLabel setTextColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
    }
    else if ([self.selection isEqualToString:@"New"]) {
        [self.secondLabel setTextColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];

    }
    else if ([self.selection isEqualToString:@"Used"]) {
        [self.thirdLabel setTextColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
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
    return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return self.secondCell;
    }
    else if (indexPath.row == 1) {
        return self.thirdCell;
    }
    else if (indexPath.row == 2) {
        return self.thirdCell;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return 122;
    }
    else{
        return 139;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];

    if (indexPath.row == 0) {
        [self.delegate secondConditionPressed];
    }
    else if (indexPath.row == 1) {
        [self.delegate thirdConditionPressed];
    }
    else if (indexPath.row == 2) {
        [self.delegate thirdConditionPressed];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
