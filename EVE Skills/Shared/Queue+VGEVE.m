//
//  Queue+VGEVE.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 16/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "Queue+VGEVE.h"
#import "QueueElement+VGEVE.h"
#import "NSString+VGEVE.h"

@implementation Queue (VGEVE)

- (NSString *)timeRemaining
{
    // Is the skill queue empty
    if (self.elements.count == 0) {
        return nil;
    }
    
    // get the ordered array of skills in the training queue
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
    NSArray *queueElementArray = [self.elements.allObjects sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    NSDate *fromDate = [NSDate date];
    NSDate *toDate = ((QueueElement *)queueElementArray.lastObject).endTime;
    
    return [NSString timeRemainingStringFromDate:fromDate toDate:toDate];
}

@end
