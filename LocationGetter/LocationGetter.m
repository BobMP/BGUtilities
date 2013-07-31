//  LocationGetter.m
//  Created by Bob de Graaf on 01-10-12.
//  Copyright GraafICT 2010. All rights reserved.

#import "LocationGetter.h"
#import <CoreLocation/CoreLocation.h>

@implementation LocationGetter
@synthesize locationManager, gpsLoc, delegate;

+(id)sharedLocationGetter
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(void)dealloc
{
    self.locationManager = nil;
    locationManager = nil;
    gpsLoc = nil;   
}

#pragma mark initialize

-(id)init
{
    self = [super init];
    if(self)
    {
        NSLog(@"GPS: Initializing...");
        locationManager = [[CLLocationManager alloc] init];
        locationManager.distanceFilter = 1;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.delegate = self;
        
#if TARGET_IPHONE_SIMULATOR
        //DLog(@"Setting simulator gps");
        gpsLoc = [[CLLocation alloc] initWithLatitude:51.0405 longitude:3.77699];
#endif
    }
    return self;    
}

-(void)updateLocation
{
    if(![CLLocationManager locationServicesEnabled])
    {
        NSLog(@"GPS: Disabled");
        if([self.delegate respondsToSelector:@selector(locationGPSOff)])
        {
            [self.delegate performSelector:@selector(locationGPSOff)];
        }
    }
    else
    {
        NSLog(@"GPS: Enabled");
        [locationManager startUpdatingLocation];        
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"GPS: Authorization changed: %d", status);
    if([self.delegate respondsToSelector:@selector(locationDidChangeAuthorizationStatus:)])
    {
        [self.delegate locationDidChangeAuthorizationStatus:status];
    }    
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"GPS: Error: %@",[error localizedDescription]);
    switch([error code])
    {
        case kCLErrorDenied:
            //Access denied by user            
            if([self.delegate respondsToSelector:@selector(locationNotAllowed)])
            {
                [self.delegate performSelector:@selector(locationNotAllowed)];
            }
            break;
        case kCLErrorLocationUnknown:
            //Hopefully temporary...            
            if([self.delegate respondsToSelector:@selector(locationFail)])
            {
                [self.delegate performSelector:@selector(locationFail)];
            }
            break;
        default:
            //Unknown error
            if([self.delegate respondsToSelector:@selector(locationFail)])
            {
                [self.delegate performSelector:@selector(locationFail)];
            }
            break;
    }
    
    if(self.stopUpdatingImmediately)
    {
        [locationManager stopUpdatingLocation];
    }
}

-(void)locationManager:(CLLocationManager *)manage didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{    	
    //NSLog(@"Location update: %f,%f, time: %@, speed: %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.timestamp, newLocation.speed);
    //NSLog(@"HAccuracy = %.0f", newLocation.horizontalAccuracy);    
    NSDate* newLocationeventDate = newLocation.timestamp;
    NSTimeInterval howRecentNewLocation = [newLocationeventDate timeIntervalSinceNow];
    NSLog(@"Got location, recent-ness: %f", howRecentNewLocation);
    if(howRecentNewLocation < -0.0 && howRecentNewLocation > -10.0)
    {
        NSLog(@"GPS: Location updated");
        [self setGpsLoc:newLocation];
        if([self.delegate respondsToSelector:@selector(locationUpdated:)])
        {
            [self.delegate performSelector:@selector(locationUpdated:) withObject:self.gpsLoc];
        }
        if(self.stopUpdatingImmediately)
        {
            [locationManager stopUpdatingLocation];
        }
    }
}

@end



























