//
//  LocationView.m
//  
//
//  Created by Jack Ryder on 26/02/2016.
//
//

#import "LocationView.h"

@interface LocationView ()

@end

@implementation LocationView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set up search
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    [self.searchController.searchBar sizeToFit];
    self.definesPresentationContext = YES;

    self.searchResults = [[NSMutableArray alloc] init];
    
    self.button = [[UIButton alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-102, (self.view.frame.size.height/2)+(self.view.frame.size.height/4), 204, 50)];
    [self.button setImage:[UIImage imageNamed:@"currentButton"] forState:UIControlStateNormal];
    [self.button addTarget:self action:@selector(useCurrentLoc) forControlEvents:UIControlEventTouchUpInside];
    [[UIApplication sharedApplication].keyWindow addSubview:self.button];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self.button removeFromSuperview];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self.searchController setActive:YES];
    [self.searchController.searchBar becomeFirstResponder];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.searchResults count];
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    [self searchForText:searchString];
    
    //update table view
    [self.tableView reloadData];
}

- (void)searchForText:(NSString*)searchText
{
    NSMutableArray *searchResults = [[NSMutableArray alloc] init];

    // Create a search request with a string
    MKLocalSearchRequest *searchRequest = [[MKLocalSearchRequest alloc] init];
    [searchRequest setNaturalLanguageQuery:searchText];
    
    CLLocationCoordinate2D ukCenter = CLLocationCoordinate2DMake(53.323536, -1.488300);
    MKCoordinateRegion uk = MKCoordinateRegionMakeWithDistance(ukCenter, 10000, 10000);
    [searchRequest setRegion:uk];
    
    // Create the local search to perform the search
    MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:searchRequest];
    
    [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        if (!error) {
            for (MKMapItem *mapItem in [response mapItems]) {
                [searchResults addObject:mapItem];
                self.searchResults = searchResults;
            }
        } else {
            NSLog(@"Search Request Error: %@", [error localizedDescription]);
        }
    }];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    cell.textLabel.text = [[[self.searchResults objectAtIndex:indexPath.row] placemark] title];
    return cell;
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
}
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self updateSearchResultsForSearchController:self.searchController];
}
-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    [self updateSearchResultsForSearchController:self.searchController];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *selectionString = [self.tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    NSLog(@"selection string location %@", selectionString);
    CLLocationCoordinate2D selectedItem = [[[[self.searchResults objectAtIndex:indexPath.row] placemark]location]coordinate];
    [self.delegate addLocation:self didFinishEnteringItem:selectionString longi:selectedItem.longitude lati:selectedItem.longitude];
    [self.navigationController popViewControllerAnimated:YES];
    
}

-(void)useCurrentLoc{
    [self.delegate addCurrentLocation:self didPress:YES];
    [self.navigationController popViewControllerAnimated:YES];
}
@end
