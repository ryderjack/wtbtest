//
//  LocationView.h
//  
//
//  Created by Jack Ryder on 26/02/2016.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class LocationView;

@protocol LocationViewControllerDelegate <NSObject>
- (void)addLocation:(LocationView *)controller didFinishEnteringItem:(NSString *)item longi:(CLLocationDegrees )item1 lati:(CLLocationDegrees )item2;
- (void)addCurrentLocation:(LocationView *)controller didPress:(BOOL)decision;
@end

@interface LocationView : UITableViewController <UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate>

@property (nonatomic, weak) id <LocationViewControllerDelegate> delegate;

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSMutableArray *searchResults;
@property (nonatomic, strong) UIButton *button;


@end
