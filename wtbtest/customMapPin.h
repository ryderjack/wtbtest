//
//  customMapPin.h
//  wtbtest
//
//  Created by Jack Ryder on 15/05/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface customMapPin : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;

-(id)initWithLocation:(CLLocationCoordinate2D)location;
- (MKAnnotationView *)annotationView;
@end
