//
//  SPDAppModel.m
//  SpeedDemon
//
//  Created by Anthony Fennell on 1/24/15.
//  Copyright (c) 2015 Anthony Fennell. All rights reserved.
//

#import "SPDAppModel.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import "MulticolorPolylineSegment.h"

static BOOL const isMetric = YES;
static float const metersInKM = 1000;
static float const metersInMile = 1609.344;

@interface SPDAppModel ()
{
    NSManagedObjectContext *context;
    NSManagedObjectModel *model;
}

@end

@implementation SPDAppModel

+ (instancetype)sharedModel {
    static SPDAppModel *sharedModel;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedModel = [[self alloc] initPrivate];
    });
    return sharedModel;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        model = [NSManagedObjectModel mergedModelFromBundles:nil];
        
        NSPersistentStoreCoordinator *psc =
        [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        
        // Where does the SQLite file go?
        NSString *path = [self itemArchivePath];
        NSURL *storeURL = [NSURL fileURLWithPath:path];
        NSError *error;
        
        if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                               configuration:nil
                                         URL:storeURL
                                     options:nil
                                       error:&error]) {
            [NSException raise:@"Open Failure"
                        format:@"%@", [error localizedDescription]];
        }
        
        // Create the managed object context
        context = [[NSManagedObjectContext alloc] init];
        context.persistentStoreCoordinator = psc;
    }
    return self;
}

- (NSString *)itemArchivePath {
    // Make sure that the first argument is NSDocumentDirectory
    // and not NSDocumentationDirectory
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    // Get the one document directory from that list
    NSString *documentDirectory = [documentDirectories firstObject];
    
    return [documentDirectory stringByAppendingPathComponent:@"store.data"];
}

- (Drive *)saveDriveDistance:(float)distance duration:(int)duration locations:(NSArray *)locations
{
    Drive *drive = [NSEntityDescription insertNewObjectForEntityForName:@"Drive"
                                                inManagedObjectContext:context];
    drive.distance = [NSNumber numberWithFloat:distance];
    drive.duration = [NSNumber numberWithInt:duration];
    drive.timestamp = [NSDate date];
    
    NSMutableArray *locationsArray = [NSMutableArray array];
    for (CLLocation *location in locations) {
        Location *locationObject = [NSEntityDescription
                                    insertNewObjectForEntityForName:@"Location"
                                    inManagedObjectContext:context];
        locationObject.timestamp = location.timestamp;
        locationObject.latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
        locationObject.longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
    }
    
    drive.locations = [NSOrderedSet orderedSetWithArray:locationsArray];
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    return drive;
}










- (NSString *)stringifyDistance:(float)meters
{
    float unitDivider;
    NSString *unitName;
    
    // metric
    if (isMetric) {
        unitName = @"km";
        unitDivider = metersInKM;
    } else {
        unitName = @"mi";
        unitDivider = metersInMile;
    }
    return [NSString stringWithFormat:@"%.2f %@", (meters / unitDivider), unitName];
}

- (NSString *)stringifySecondCount:(int)seconds usingLongFormat:(BOOL)longFormat
{
    int remainingSeconds = seconds;
    int hours = remainingSeconds / 3600;
    remainingSeconds = remainingSeconds - hours * 3600;
    int minutes = remainingSeconds / 60;
    remainingSeconds = remainingSeconds - minutes * 60;
    
    if (longFormat) {
        if (hours > 0) {
            return [NSString stringWithFormat:@"%ihr %imin %isec", hours, minutes, remainingSeconds];
        } else if (minutes > 0) {
            return [NSString stringWithFormat:@"%imin %isec", minutes, remainingSeconds];
        } else {
            return [NSString stringWithFormat:@"%isec", remainingSeconds];
        }
    } else {
        if (hours > 0) {
            return [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, remainingSeconds];
        } else if (minutes > 0) {
            return [NSString stringWithFormat:@"%02i:%02i", minutes, remainingSeconds];
        } else {
            return [NSString stringWithFormat:@"%02i", remainingSeconds];
        }
    }
}

- (NSString *)stringifyAvgPaceFromDist:(float)meters overTime:(int)seconds
{
    if (seconds == 0 || meters == 0) {
        return @"0";
    }
    
    float avgPaceSecMeters = seconds / meters;
    
    float unitMultiplier;
    NSString *unitName;
    
    // metric
    if (isMetric) {
        unitName = @"min/km";
        unitMultiplier = metersInKM;
        // U.S.
    } else {
        unitName = @"min/mi";
        unitMultiplier = metersInMile;
    }
    
    int paceMin = (int) ((avgPaceSecMeters * unitMultiplier) / 60);
    int paceSec = (int) (avgPaceSecMeters * unitMultiplier - (paceMin*60));
    
    return [NSString stringWithFormat:@"%i:%02i %@", paceMin, paceSec, unitName];
}

- (NSArray *)colorSegmentsForLocations:(NSArray *)locations
{
    // make array of all speeds, find slowest+fastest
    NSMutableArray *speeds = [NSMutableArray array];
    double slowestSpeed = DBL_MAX;
    double fastestSpeed = 0.0;
    
    for (int i = 1; i < locations.count; i++) {
        Location *firstLoc = [locations objectAtIndex:(i-1)];
        Location *secondLoc = [locations objectAtIndex:i];
        
        CLLocation *firstLocCL = [[CLLocation alloc]
                                  initWithLatitude:firstLoc.latitude.doubleValue
                                  longitude:firstLoc.longitude.doubleValue];
        CLLocation *secondLocCL = [[CLLocation alloc]
                                   initWithLatitude:secondLoc.latitude.doubleValue
                                   longitude:secondLoc.longitude.doubleValue];
        
        double distance = [secondLocCL distanceFromLocation:firstLocCL];
        double time = [secondLoc.timestamp timeIntervalSinceDate:firstLoc.timestamp];
        double speed = distance/time;
        
        slowestSpeed = speed < slowestSpeed ? speed : slowestSpeed;
        fastestSpeed = speed > fastestSpeed ? speed : fastestSpeed;
        [speeds addObject:@(speed)];
    }
    
    double meanSpeed = (slowestSpeed + fastestSpeed) / 2;
    
    // RGB for red (slowest)
    CGFloat r_red = 1.0f;
    CGFloat r_green = 20.0/255.0f;
    CGFloat r_blue = 44.0/255.0f;
    
    // RGB for yellow (middle)
    CGFloat y_red = 1.0f;
    CGFloat y_green = 215/255.0f;
    CGFloat y_blue = 0.0f;
    
    // RGB for green (fastest)
    CGFloat g_red = 0.0f;
    CGFloat g_green = 146.0/255.0f;
    CGFloat g_blue = 78.0/255.0f;
    
    NSMutableArray *colorSegments = [NSMutableArray array];
    
    for (int i = 1; i < locations.count; i++) {
        Location *firstLoc = [locations objectAtIndex:(i-1)];
        Location *secondLoc = [locations objectAtIndex:i];
        
        CLLocationCoordinate2D coords[2];
        coords[0].latitude = firstLoc.latitude.doubleValue;
        coords[0].longitude = firstLoc.longitude.doubleValue;
        
        coords[1].latitude = secondLoc.latitude.doubleValue;
        coords[1].longitude = secondLoc.longitude.doubleValue;
        
        NSNumber *speed = [speeds objectAtIndex:(i-1)];
        UIColor *color = [UIColor blackColor];
        
        // Between red and yellow
        if (speed.doubleValue < meanSpeed) {
            double ratio = (speed.doubleValue - slowestSpeed) / (meanSpeed - slowestSpeed);
            CGFloat red     = r_red + ratio * (y_red - r_red);
            CGFloat green   = r_green + ratio * (y_green - r_green);
            CGFloat blue    = r_blue + ratio * (y_blue - r_blue);
            color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
            // Between yellow and green
        } else {
            double ratio = (speed.doubleValue - meanSpeed) / (fastestSpeed - meanSpeed);
            CGFloat red     = y_red + ratio * (g_red - y_red);
            CGFloat green   = y_green + ratio * (g_green - y_green);
            CGFloat blue    = y_blue + ratio * (g_blue - y_blue);
            color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
        }
        
        MulticolorPolylineSegment *segment = [MulticolorPolylineSegment
                                              polylineWithCoordinates:coords count:2];
        [colorSegments addObject:segment];
    }
    
    return colorSegments;
}



@end
