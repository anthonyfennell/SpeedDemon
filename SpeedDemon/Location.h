//
//  Location.h
//  SpeedDemon
//
//  Created by Anthony Fennell on 1/26/15.
//  Copyright (c) 2015 Anthony Fennell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Location : NSManagedObject

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSManagedObject *drive;

@end
