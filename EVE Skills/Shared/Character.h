//
//  Character.h
//  EVE Database
//
//  Created by Vincent Garrigues on 04/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class API, Corporation;

@interface Character : NSManagedObject

@property (nonatomic, retain) NSString * characterID;
@property (nonatomic, retain) NSNumber * enabled;
@property (nonatomic, retain) NSString * characterName;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) Corporation *corporation;
@property (nonatomic, retain) API *api;
@property (nonatomic, retain) NSSet *queue;
@end

@interface Character (CoreDataGeneratedAccessors)

- (void)addQueueObject:(NSManagedObject *)value;
- (void)removeQueueObject:(NSManagedObject *)value;
- (void)addQueue:(NSSet *)values;
- (void)removeQueue:(NSSet *)values;

@end
