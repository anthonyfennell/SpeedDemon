//
//  ViewController.m
//  SpeedDemon
//
//  Created by Anthony Fennell on 1/24/15.
//  Copyright (c) 2015 Anthony Fennell. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "SPDAppModel.h"

#define MILES_IN_A_METER 0.0006214
#define SECONDS_IN_AN_HOUR 360
#define FEET_IN_A_METER 3.281

@interface ViewController () <CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;

@property (strong, nonatomic) CLLocation *currentLocation;
@property (strong, nonatomic) CLLocation *previousLocation;

@property (nonatomic) BOOL isFirstLocation;

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isFirstLocation = YES;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager startUpdatingLocation];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    
    if (self.isFirstLocation) {
        self.isFirstLocation = NO;
        self.currentLocation = [locations lastObject];
        self.previousLocation = self.currentLocation;
    } else {
        CLLocation *location = [locations lastObject];
        if ([location distanceFromLocation:self.currentLocation] == 0) {
            self.currentLocation = location;
        } else {
            self.previousLocation = self.currentLocation;
            self.currentLocation = location;
        }
    }
    
    
    float distanceInFeet = 0;
    float distanceInMeters = 0;
    NSLog(@"Location count: %ld", [locations count]);
    distanceInMeters = [self.currentLocation distanceFromLocation:self.previousLocation];
    distanceInFeet = distanceInMeters * FEET_IN_A_METER;
    self.speedLabel.text = [NSString stringWithFormat:@"%.1fmph", (self.currentLocation.speed * MILES_IN_A_METER * SECONDS_IN_AN_HOUR)];
    self.textView.text = [NSString stringWithFormat:@"Latitude: %.1f\nLongitude: %.1f\nDistance: %.2f feet\nDistance: %.2f meters\nLocations: %ld",
                        self.currentLocation.coordinate.latitude,
                        self.currentLocation.coordinate.longitude,
                        distanceInFeet,
                        distanceInMeters,
                        [locations count]];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    if (error.code == kCLErrorDenied) {
        NSLog(@"Error : Denied");
        [self.locationManager stopUpdatingLocation];
    } else if (error.code == kCLErrorLocationUnknown) {
        NSLog(@"Error: Location Unknown");
    } else {
        NSLog(@"Location Manager failed with error: %@", [error description]);
    }
}

@end
























