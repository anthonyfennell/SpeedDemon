//
//  SPDAppModel.h
//  SpeedDemon
//
//  Created by Anthony Fennell on 1/24/15.
//  Copyright (c) 2015 Anthony Fennell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface SPDAppModel : NSObject

@property (nonatomic, strong) CLLocationManager *locationManager;

+ (instancetype)sharedModel;

- (void)askForPermissionForUse;

@end
