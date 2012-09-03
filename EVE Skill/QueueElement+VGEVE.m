//
//  QueueElement+VGEVE.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 16/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "QueueElement+VGEVE.h"
#import "NSString+VGEVE.h"

@implementation QueueElement (VGEVE)

- (NSString *)timeRemaining
{
    if (self.startTime == nil || self.endTime == nil) {
        return nil;
    }
    
    NSDate *fromDate = nil;
    if ([self.position intValue] == 0) {
        // Current skill in training
        fromDate = [NSDate date];
    } else {
        // Skill not in training
        fromDate = self.startTime;
    }
    NSDate *toDate = self.endTime;
    
    return [NSString timeRemainingStringFromDate:fromDate toDate:toDate];
}

@end
