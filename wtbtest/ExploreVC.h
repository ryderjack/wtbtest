//
//  ExploreVC.h
//  
//
//  Created by Jack Ryder on 29/02/2016.
//
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>
#import "FilterVC.h"

@interface ExploreVC : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate, FilterDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *results;

//location
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) BOOL locationAllowed;
@property (nonatomic, strong) PFGeoPoint *currentLocation;

@property (nonatomic, strong) PFQuery *infiniteQuery;
@property (nonatomic, strong) PFQuery *pullQuery;
@property (nonatomic) int lastInfinSkipped;
@property (nonatomic) BOOL pullFinished;
@property (nonatomic) BOOL infinFinished;
@property (weak, nonatomic) IBOutlet UIButton *filterButton;

@property (nonatomic, strong) NSMutableArray *filtersArray;
@end
