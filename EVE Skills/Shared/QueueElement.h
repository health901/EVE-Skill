//
//  QueueElement.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 20/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Queue;

@interface QueueElement : NSManagedObject

@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSString * skillID;
@property (nonatomic, retain) NSNumber * skillLevel;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSString * timeRemaining;
@property (nonatomic, retain) Queue *queue;

@end
