//
//  SPDAppModel.m
//  SpeedDemon
//
//  Created by Anthony Fennell on 1/24/15.
//  Copyright (c) 2015 Anthony Fennell. All rights reserved.
//

#import "SPDAppModel.h"

@interface SPDAppModel ()

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

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
    }
    return self;
}

- (CLLocationManager *)locationManager
{
    return _locationManager;
}

- (void)askForPermissionForUse
{

}

@end
