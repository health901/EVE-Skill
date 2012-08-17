//
//  Queue+VGEVE.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 16/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "Queue+VGEVE.h"
#import "QueueElement+VGEVE.h"

@implementation Queue (VGEVE)
//
//- (BOOL)isTraining
//{
//    if (self.elements == nil || self.elements.count == 0) {
//        return NO;
//    }
//    
//    // Get the first element
//    __block QueueElement *firstQueueElement = nil;
//    
//    [self.elements.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        if (((QueueElement *)obj).position == 0) {
//            firstQueueElement = obj;
//            *stop = YES;
//        }
//    }];
//    
//    
//    // The first element must have an endTime after the current date
//    return firstQueueElement != nil && [firstQueueElement.endTime compare:[NSDate date]] == NSOrderedDescending;
//}
//
//- (NSArray *)queueElementArray
//{
//    if ([self isTraining]) {
//        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"position"
//                                                                         ascending:YES];
//        return [self.elements.allObjects sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
//    }
//    return nil;
//}

- (NSString *)timeRemainingStringValue
{
    return @"NOT IMPLEMENTED";
}

@end
