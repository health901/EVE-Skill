//
//  Character.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 22/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class API;

@interface Character : NSManagedObject

@property (nonatomic, retain) NSString * characterID;
@property (nonatomic, retain) NSString * characterName;
@property (nonatomic, retain) NSNumber * enabled;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * corporationID;
@property (nonatomic, retain) API *api;

@end
