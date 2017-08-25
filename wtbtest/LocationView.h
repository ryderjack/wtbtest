//
//  LocationView.h
//  
//
//  Created by Jack Ryder on 26/02/2016.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@class LocationView;

@protocol LocationViewControllerDelegate <NSObject>
- (void)addLocation:(LocationView *)controller didFinishEnteringItem:(NSString *)item longi:(CLLocationDegrees )item1 lati:(CLLocationDegrees )item2;
- (void)selectedPlacemark:(CLPlacemark *)placemark;
- (void)addCurrentLocation:(LocationView *)controller didPress:(PFGeoPoint *)geoPoint title: (NSString *)placemark;
@end

@interface LocationView : UITableViewController <UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate>

@property (nonatomic, weak) id <LocationViewControllerDelegate> delegate;

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSMutableArray *searchResults;
@property (nonatomic, strong) UIButton *button;

@property (nonatomic) BOOL buttonShowing;


@end
