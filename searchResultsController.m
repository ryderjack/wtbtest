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

@property (nonatomic, strong) NSArray *allResults;

@end

@implementation searchResultsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"resultCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    self.allResults = [[[[PFUser currentUser]objectForKey:@"searches"] reverseObjectEnumerator] allObjects];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Property Overrides

- (void)setFilterString:(NSString *)filterString {
//    _filterString = filterString;
//    
//    if (!filterString || filterString.length <= 0) {
//        self.visibleResults = self.allResults;
//    }
//    else {
//        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"self contains[c] %@", filterString];
//        self.visibleResults = [self.allResults filteredArrayUsingPredicate:filterPredicate];
//    }
    
//    [self.tableView reloadData];
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController{
    //implement filtering here of search terms?
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.allResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    return [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.textLabel.text = self.allResults[indexPath.row];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSString *selected =[self.allResults objectAtIndex:indexPath.row];
    [self.delegate favouriteTapped:selected];
    
    [self.tableView setHidden:YES];
}


@end
