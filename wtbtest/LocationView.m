//
//  LocationView.m
//  
//
//  Created by Jack Ryder on 26/02/2016.
//
//

#import "LocationView.h"
#import <HNKGooglePlacesAutocomplete/HNKGooglePlacesAutocomplete.h>
#import "CLPlacemark+HNKAdditions.h"

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
    self.searchController.delegate = self;
    
    self.navigationItem.titleView = self.searchController.searchBar;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    [self.searchController.searchBar sizeToFit];
    
    self.searchController.definesPresentationContext = NO;
    self.definesPresentationContext = YES;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.extendedLayoutIncludesOpaqueBars = !self.navigationController.navigationBar.translucent;

    self.searchController.searchBar.tintColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
    self.searchResults = [[NSMutableArray alloc] init];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.searchController setActive:YES];
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
}

- (void)searchForText:(NSString*)searchText
{
    NSMutableArray *searchResults = [[NSMutableArray alloc] init];
    
    [[HNKGooglePlacesAutocompleteQuery sharedQuery] fetchPlacesForSearchQuery:searchText
                                                      configurationBlock:^(HNKGooglePlacesAutocompleteQueryConfig *config) {
                                                          config.language = @"EN";
                                                      } completion:^(NSArray *places, NSError *error)  {
                                                             if (error) {
                                                                 NSLog(@"ERROR: %@", error);
                                                                 //update table view
                                                                 [self.tableView reloadData];
                                                             } else {
                                                                 for (HNKGooglePlacesAutocompletePlace *place in places) {
                                                                     
                                                                     NSLog(@"PLACE %@", place);
                                                                     
                                                                     [searchResults addObject:place];
                                                                      self.searchResults = searchResults;
                                                                 }
                                                                 //update table view
                                                                 [self.tableView reloadData];
                                                             }
                                                         }
     ];
    
//    [[HNKGooglePlacesAutocompleteQuery sharedQuery] fetchPlacesForSearchQuery:searchText
//                                                                   completion:^(NSArray *places, NSError *error)  {
//                                                                       if (error) {
//                                                                           NSLog(@"ERROR: %@", error);
//                                                                           //update table view
//                                                                           [self.tableView reloadData];
//                                                                       } else {
//                                                                           for (HNKGooglePlacesAutocompletePlace *place in places) {
//                                                                               [searchResults addObject:place];
//                                                                                self.searchResults = searchResults;
//                                                                           }
//                                                                           //update table view
//                                                                           [self.tableView reloadData];
//                                                                       }
//                                                                   }
//     ];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    
    cell.textLabel.text = [[self.searchResults objectAtIndex:indexPath.row]valueForKey:@"name"];
    return cell;
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    [self.searchResults removeAllObjects];
}
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self updateSearchResultsForSearchController:self.searchController];
}
-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    [self updateSearchResultsForSearchController:self.searchController];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    [self updateSearchResultsForSearchController:self.searchController];
}

- (void)showKeyboard
{
    [self.searchController.searchBar becomeFirstResponder];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.tableView.userInteractionEnabled = NO;
    
    if (self.searchResults.count >0) {
        NSLog(@"SEARCH: %@",[self.searchResults objectAtIndex:indexPath.row]);
        
        [CLPlacemark hnk_placemarkFromGooglePlace:[self.searchResults objectAtIndex:indexPath.row]
                                           apiKey:@"AIzaSyC812pR1iegUl3UkzqY0rwYlRmrvAAUbgw"
                                       completion:^(CLPlacemark *placemark, NSString *addressString, NSError *error) {
                                           if(error) {
                                               NSLog(@"ERROR: %@", error);
                                               [self showError];
                                               self.tableView.userInteractionEnabled = YES;
                                           } else {
                                               NSLog(@"PLACEMARK %@", placemark);
                                               
                                               [self.delegate selectedPlacemark:placemark];
                                               self.tableView.userInteractionEnabled = YES;
                                               [self.navigationController popViewControllerAnimated:YES];
                                           }
                                       }
         ];
    } 
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
                    NSString *titleString = @"";
                    if (placemark.locality) {
                        titleString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                    }
                    else{
                        titleString = [NSString stringWithFormat:@"%@", placemark.country];
                    }
                    
                    [self.delegate addCurrentLocation:self didPress:geoPoint title:titleString];
                    [self.navigationController popViewControllerAnimated:YES];
                }
                else{
                    NSLog(@"error %@", error);
                    [self showError];
                }
            }];
        }
        else{
            NSLog(@"error %@", error);
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

-(void)showError{
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Location error"
                                  message:@"Make sure you're being specific, search for your nearest city!"
                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)didPresentSearchController:(UISearchController *)searchController
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [searchController.searchBar becomeFirstResponder];
    });
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
