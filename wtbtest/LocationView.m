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
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    [self.searchController.searchBar sizeToFit];
    self.definesPresentationContext = YES;
    self.searchController.searchBar.tintColor = [UIColor colorWithRed:0.525 green:0.745 blue:1 alpha:1];
    
    self.searchResults = [[NSMutableArray alloc] init];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        self.button = [[UIButton alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, (self.view.frame.size.height/2)+(self.view.frame.size.height/6), 204, 50)];
    }
    else{
        //everything else
        self.button = [[UIButton alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-102, (self.view.frame.size.height/2)+(self.view.frame.size.height/4), 204, 50)];
    }
    
    // current location button
    [self.button setImage:[UIImage imageNamed:@"currentButton"] forState:UIControlStateNormal];
    [self.button addTarget:self action:@selector(useCurrentLoc) forControlEvents:UIControlEventTouchUpInside];
    [[UIApplication sharedApplication].keyWindow addSubview:self.button];
    self.buttonShowing = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.button removeFromSuperview];
    self.buttonShowing = NO;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
//    [self.searchController setActive:YES];
    
    if (self.buttonShowing == NO) {
        [[UIApplication sharedApplication].keyWindow addSubview:self.button];
    }
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

- (void)showKeyboard
{
    [self.searchController.searchBar becomeFirstResponder];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *selectionString = [self.tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    CLLocationCoordinate2D selectedItem = [[[[self.searchResults objectAtIndex:indexPath.row] placemark]location]coordinate];
    [self.delegate addLocation:self didFinishEnteringItem:selectionString longi:selectedItem.longitude lati:selectedItem.latitude];
    [self.navigationController popViewControllerAnimated:YES];
    
}

-(void)useCurrentLoc{
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint * _Nullable geoPoint, NSError * _Nullable error) {
        if (!error) {
            double latitude = geoPoint.latitude;
            double longitude = geoPoint.longitude;
            
            CLLocation *loc = [[CLLocation alloc]initWithLatitude:latitude longitude:longitude];
            CLGeocoder *geocoder = [[CLGeocoder alloc]init];
            [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                if (placemarks) {
                    CLPlacemark *placemark = [placemarks lastObject];
                    NSString *titleString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.administrativeArea];
                    [self.delegate addCurrentLocation:self didPress:geoPoint title:titleString];
                    [self.navigationController popViewControllerAnimated:YES];
                }
                else{
                    NSLog(@"error %@", error);
                }
            }];
        }
        else{
            NSLog(@"error %@", error);
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

@end
