//
//  customMapPin.m
//  wtbtest
//
//  Created by Jack Ryder on 15/05/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "customMapPin.h"


@implementation customMapPin

-(id)initWithLocation:(CLLocationCoordinate2D)location{
    
    self = [super init];
    
    if (self) {
        _coordinate = location;
    }
    
    return self;
}

-(MKAnnotationView *)annotationView{
    
    MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:@"custom"];
    annotationView.enabled = YES;
    annotationView.canShowCallout = NO;
    annotationView.image = [UIImage imageNamed:@"ccMapPin"];
    return annotationView;
}

@end
