//
//  searchResultsController.m
//  wtbtest
//
//  Created by Jack Ryder on 06/04/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "searchResultsController.h"
#import "resultCell.h"

@interface searchResultsController ()
@end

@implementation searchResultsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"resultCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    self.visibleResults = [[NSMutableArray alloc]init];
//    self.userResults = [NSArray array];
//    self.itemResults = [NSArray array];
//    self.userSearch = NO;
    NSLog(@"VDL");
    NSLog(self.userSearch ? @"USER MODE in VDL" : @"ITEM MODE in VDL");

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (self.userSearch == YES) {
        NSLog(@"user search IS ON in appear");

    }
    else if (self.userSearch == NO){
        NSLog(@"user search is OFF in appear");
    }
    else{
        NSLog(@"NONE IN APPEAR");
    }
    
    self.userResults = @[];
    self.itemResults = [[[[PFUser currentUser]objectForKey:@"searches"] reverseObjectEnumerator] allObjects];
}

#pragma mark - Property Overrides

- (void)setFilterString:(NSString *)filterString {
    NSLog(@"setting filter string");
    
    if (!filterString || filterString.length <= 0) {
        self.visibleResults = [NSMutableArray arrayWithArray:self.itemResults];
    }
    else {
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"self contains[c] %@", filterString];
        self.visibleResults = [NSMutableArray arrayWithArray:[self.itemResults filteredArrayUsingPredicate:filterPredicate]];
    }
    
    NSLog(@"reloading 5");
    [self.tableView reloadData];
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController{
    //implement filtering here of search terms?
    NSLog(@"updating search results for search controller");
    
    if (self.cancelClicked == YES) {
        NSLog(@"cancel clicked so do nothing");
        self.cancelClicked = NO;
        return;
    }
    
    NSString *searchMinusSpaces = [searchController.searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (searchController.searchBar.selectedScopeButtonIndex == 0) {
        NSLog(@"reloading 1");
        self.itemResults = [[[[PFUser currentUser]objectForKey:@"searches"] reverseObjectEnumerator] allObjects];
        self.userSearch = NO;
        [self.tableView reloadData];
        NSLog(@"items selected in RC");

        if ([searchMinusSpaces isEqualToString:@""]) {
            NSLog(@"items is selected but no text entered in search bar");
            self.filterEnabled = NO;
            NSLog(@"reloading 2");
//            [self.tableView reloadData];
        }
        else{
            NSLog(@"items is selected so filter through searches");
            self.filterEnabled = YES;
            [self setFilterString:searchController.searchBar.text];
        }
    }
    else{
        NSLog(@"updating search controller with user results");
        self.userSearch = YES;
        self.filterEnabled = NO;
        [self.tableView reloadData];
        
//        NSString *searchText = searchController.searchBar.text;
//        NSLog(@"users selected in RC with searchstring %@",searchText);
//        
////        self.userResults = @[];
////        NSLog(@"reloading 3");
//        self.userSearch = YES;
//        self.filterEnabled = NO;
//        
//        if ([searchMinusSpaces isEqualToString:@""] || self.queryAllowed != YES) {
//            NSLog(@"not allowed");
//            return;
//        }
//        NSLog(@"allowed");
//        self.queryAllowed = NO;
//
//        PFQuery *userQueryForRand = [PFUser query];
//        [userQueryForRand whereKey:@"username" containsString:searchText];
//        [userQueryForRand findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//            if (objects) {
//                NSLog(@"users in results %lu", objects.count);
//
//                self.userResults = objects;
//                NSLog(@"reloading 4");
//                self.userSearch = YES;
//                [self.tableView reloadData];
//            }
//            else{
//                NSLog(@"error getting users %@", error);
//            }
//        }];
    }

    // unhide table view when edits search text in searchController
    
    [self.view setHidden:NO];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //filter always NO atm
    NSLog(self.userSearch ? @"USER MODE in ROWS" : @"ITEM MODE in ROWS");
    
    if (self.userSearch == YES) {
        NSLog(@"returning user rows %lu", self.userResults.count);
        return self.userResults.count;
    }
    else{
        if (self.filterEnabled == YES) {
            NSLog(@"returning visivle rows %lu", self.visibleResults.count);

            return self.visibleResults.count;
        }
        else{
            NSLog(@"returning item rows %lu", self.itemResults.count);
            return self.itemResults.count;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(self.userSearch ? @"USER MODE in CFI" : @"ITEM MODE in CFI");
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.textLabel.text = @"";
    
    if (self.userSearch == YES) {
        NSLog(@"user search ON %lu", self.userResults.count);
        if (self.userResults.count >=indexPath.row+1) {
            PFUser *user = self.userResults[indexPath.row];
            cell.textLabel.text = user.username;
        }
    }
    else{
        if (self.filterEnabled == YES) {
            NSLog(@"filter is ON & user search OFF");
            cell.textLabel.text = self.visibleResults[indexPath.row];
        }
        else{
            NSLog(@"user search OFF w/ %lu", self.itemResults.count);
            cell.textLabel.text = self.itemResults[indexPath.row];
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"will display cell");
//    cell.textLabel.text = @"";
//    
//    if (self.userSearch == YES) {
//        NSLog(@"user search ON %lu", self.userResults.count);
//        PFUser *user = self.userResults[indexPath.row];
//        cell.textLabel.text = user.username;
//    }
//    else{
//        if (self.filterEnabled == YES) {
//            NSLog(@"filter is ON & user search OFF");
//            cell.textLabel.text = self.visibleResults[indexPath.row];
//        }
//        else{
//            NSLog(@"user search OFF w/ %lu", self.itemResults.count);
//            cell.textLabel.text = self.itemResults[indexPath.row];
//        }
//    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSString *selected = [[NSString alloc]init];
    
    if (self.userSearch == YES) {
        NSLog(@"user selected");
        PFUser *user = [self.userResults objectAtIndex:indexPath.row];
        [self.delegate userTapped:user];
    }
    else{
        NSLog(@"item selected");
        if (self.filterEnabled == YES) {
            selected = [self.visibleResults objectAtIndex:indexPath.row];
        }
        else{
            selected = [self.itemResults objectAtIndex:indexPath.row];
            [self.delegate favouriteTapped:selected];
        }
        [self.tableView setHidden:YES];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.delegate willdiss:YES];
    NSLog(@"dis called");
//    self.userSearch = NO;
}

@end
