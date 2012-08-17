//
//  Queue+VGEVE.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 16/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "Queue.h"

@interface Queue (VGEVE)

// Returns YES only if the first skill in the queue is training
//- (BOOL)isTraining;
//
// Returns an ordered by 'position' array of QueueElement if -isTraining returns YES
//- (NSArray *)queueElementArray;

- (NSString *)timeRemainingStringValue;

@end
