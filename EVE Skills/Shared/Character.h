//
//  Character.h
//  EVE Skills_old
//
//  Created by Vincent Garrigues on 14/08/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class API, Corporation;

@interface Character : NSManagedObject

@property (nonatomic, retain) NSString * characterID;
@property (nonatomic, retain) NSNumber * enabled;
@property (nonatomic, retain) NSString * characterName;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) Corporation *corporation;
@property (nonatomic, retain) API *api;

@end
