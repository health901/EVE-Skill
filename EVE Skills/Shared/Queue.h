//
//  Queue.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 16/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class QueueElement;

@interface Queue : NSManagedObject

@property (nonatomic, retain) NSString * characterID;
@property (nonatomic, retain) NSDate * cachedUntil;
@property (nonatomic, retain) NSSet *elements;
@end

@interface Queue (CoreDataGeneratedAccessors)

- (void)addElementsObject:(QueueElement *)value;
- (void)removeElementsObject:(QueueElement *)value;
- (void)addElements:(NSSet *)values;
- (void)removeElements:(NSSet *)values;

@end
