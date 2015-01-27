//
//  SPDAppModel.h
//  SpeedDemon
//
//  Created by Anthony Fennell on 1/24/15.
//  Copyright (c) 2015 Anthony Fennell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Drive.h"
#import "Location.h"

@interface SPDAppModel : NSObject

+ (instancetype)sharedModel;

- (Drive *)saveDriveDistance:(float)distance duration:(int)duration locations:(NSArray *)locations;

- (NSString *)stringifyDistance:(float)meters;
- (NSString *)stringifySecondCount:(int)seconds usingLongFormat:(BOOL)longFormat;
- (NSString *)stringifyAvgPaceFromDist:(float)meters overTime:(int)seconds;

- (NSArray *)colorSegmentsForLocations:(NSArray *)locations;

@end
