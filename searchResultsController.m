//
//  searchResultsController.m
//  wtbtest
//
//  Created by Jack Ryder on 06/04/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "searchResultsController.h"
#import "resultCell.h"
#import <Parse/Parse.h>

@interface searchResultsController ()
@end

@implementation searchResultsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"resultCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    self.visibleResults = [[NSMutableArray alloc]init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.allResults = [[[[PFUser currentUser]objectForKey:@"searches"] reverseObjectEnumerator] allObjects];
    [self.tableView reloadData];
}

#pragma mark - Property Overrides

- (void)setFilterString:(NSString *)filterString {
    
    if (!filterString || filterString.length <= 0) {
        self.visibleResults = [NSMutableArray arrayWithArray:self.allResults];
    }
    else {
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"self contains[c] %@", filterString];
        self.visibleResults = [NSMutableArray arrayWithArray:[self.allResults filteredArrayUsingPredicate:filterPredicate]];
    }
    
    [self.tableView reloadData];
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController{
    //implement filtering here of search terms?
    
    if ([searchController.searchBar.text isEqualToString:@""]) {
        self.filterEnabled = NO;
        [self.tableView reloadData];
    }
    else{
        self.filterEnabled = YES;
        [self setFilterString:searchController.searchBar.text];
    }
    
    // unhide table view when edits search text in searchController
    
    [self.view setHidden:NO];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.filterEnabled == YES) {
        return self.visibleResults.count;
    }
    else{
       return self.allResults.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    return [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.filterEnabled == YES) {
        cell.textLabel.text = self.visibleResults[indexPath.row];
    }
    else{
        cell.textLabel.text = self.allResults[indexPath.row];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSString *selected = [[NSString alloc]init];
    
    if (self.filterEnabled == YES) {
        selected = [self.visibleResults objectAtIndex:indexPath.row];
    }
    else{
        selected = [self.allResults objectAtIndex:indexPath.row];
    }
    [self.delegate favouriteTapped:selected];
    [self.tableView setHidden:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.delegate willdiss:YES];
}

@end
