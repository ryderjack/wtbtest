//
//  searchResultsController.m
//  wtbtest
//
//  Created by Jack Ryder on 06/04/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "searchResultsController.h"

@interface searchResultsController ()
@end

@implementation searchResultsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.visibleResults = [[NSMutableArray alloc]init];
//    self.userResults = [NSArray array];
//    self.itemResults = [NSArray array];
//    self.userSearch = NO;
    //nslog(@"VDL");
    //nslog(self.userSearch ? @"USER MODE in VDL" : @"ITEM MODE in VDL");

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (self.userSearch == YES) {
        //nslog(@"user search IS ON in appear");

    }
    else if (self.userSearch == NO){
        //nslog(@"user search is OFF in appear");
    }
    else{
        //nslog(@"NONE IN APPEAR");
    }
    
    self.userResults = @[];
    self.itemResults = [[[[PFUser currentUser]objectForKey:@"searches"] reverseObjectEnumerator] allObjects];
}

#pragma mark - Property Overrides

- (void)setFilterString:(NSString *)filterString {
    //nslog(@"setting filter string");
    
    if (!filterString || filterString.length <= 0) {
        self.visibleResults = [NSMutableArray arrayWithArray:self.itemResults];
    }
    else {
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"self contains[c] %@", filterString];
        self.visibleResults = [NSMutableArray arrayWithArray:[self.itemResults filteredArrayUsingPredicate:filterPredicate]];
    }
    
    //nslog(@"reloading 5");
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
        //nslog(@"reloading 1");
        self.itemResults = [[[[PFUser currentUser]objectForKey:@"searches"] reverseObjectEnumerator] allObjects];
        self.userSearch = NO;
        [self.tableView reloadData];
        //nslog(@"items selected in RC");

        if ([searchMinusSpaces isEqualToString:@""]) {
            //nslog(@"items is selected but no text entered in search bar");
            self.filterEnabled = NO;
        }
        else{
            NSLog(@"filtering here");
            self.filterEnabled = NO;
            //[self setFilterString:searchController.searchBar.text];
        }
    }
    else{
        //nslog(@"updating search controller with user results");
        self.userSearch = YES;
        self.filterEnabled = NO;
        [self.tableView reloadData];
    }

    // unhide table view when edits search text in searchController
    
    [self.view setHidden:NO];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //filter always NO atm
    //nslog(self.userSearch ? @"USER MODE in ROWS" : @"ITEM MODE in ROWS");
    
    if (self.userSearch == YES) {
        //nslog(@"returning user rows %lu", self.userResults.count);
        return self.userResults.count;
    }
    else{
        if (self.filterEnabled == YES) {
            //nslog(@"returning visivle rows %lu", self.visibleResults.count);

            return self.visibleResults.count;
        }
        else{
            //nslog(@"returning item rows %lu", self.itemResults.count);
            return self.itemResults.count;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //nslog(self.userSearch ? @"USER MODE in CFI" : @"ITEM MODE in CFI");
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.textLabel.text = @"";
    
    if (self.userSearch == YES) {
        //nslog(@"user search ON %lu", self.userResults.count);
        if (self.userResults.count >=indexPath.row+1) {
            PFUser *user = self.userResults[indexPath.row];
            cell.textLabel.text = user.username;
        }
    }
    else{
        if (self.filterEnabled == YES) {
            //nslog(@"filter is ON & user search OFF");
            cell.textLabel.text = self.visibleResults[indexPath.row];
        }
        else{
            //nslog(@"user search OFF w/ %lu", self.itemResults.count);
            cell.textLabel.text = self.itemResults[indexPath.row];
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //nslog(@"will display cell");
//    cell.textLabel.text = @"";
//    
//    if (self.userSearch == YES) {
//        //nslog(@"user search ON %lu", self.userResults.count);
//        PFUser *user = self.userResults[indexPath.row];
//        cell.textLabel.text = user.username;
//    }
//    else{
//        if (self.filterEnabled == YES) {
//            //nslog(@"filter is ON & user search OFF");
//            cell.textLabel.text = self.visibleResults[indexPath.row];
//        }
//        else{
//            //nslog(@"user search OFF w/ %lu", self.itemResults.count);
//            cell.textLabel.text = self.itemResults[indexPath.row];
//        }
//    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSString *selected = [[NSString alloc]init];
    
    if (self.userSearch == YES) {
        //nslog(@"user selected");
        PFUser *user = [self.userResults objectAtIndex:indexPath.row];
        [self.delegate userTapped:user];
    }
    else{
        //nslog(@"item selected");
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
    //nslog(@"dis called");
//    self.userSearch = NO;
}

@end
