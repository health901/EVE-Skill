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

- (NSString *)timeRemaining
{
    // Is the skill queue empty
    if (self.elements.count == 0) {
        return @"Skill queue empty !";
    }
    
    // get the ordered array of skills in the training queue
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
    NSArray *queueElementArray = [self.elements.allObjects sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    NSDate *date1 = [NSDate date];
    NSDate *date2 = ((QueueElement *)queueElementArray.lastObject).endTime;
    
    unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSSecondCalendarUnit;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *dateComponents = [calendar components:unitFlags fromDate:date1  toDate:date2  options:0];
    
    NSInteger month = [dateComponents month];
    NSInteger day = [dateComponents day];
    NSInteger hour = [dateComponents hour];
    NSInteger minute = [dateComponents minute];
    NSInteger second = [dateComponents second];
    
    
    NSMutableString *result = [[NSMutableString alloc] init];
    
    if (month > 0) {
        [result appendFormat:@"%ld %@, ", month, (month > 1 ? @"months" : @"month")];
    }
    
    if (day > 0) {
        [result appendFormat:@"%ld %@, ", day, (day > 1 ? @"days" : @"day")];
    }
    
    if (hour > 0) {
        [result appendFormat:@"%ld %@, ", hour, (hour > 1 ? @"hours" : @"hour")];
    }
    
    if (minute > 0) {
        [result appendFormat:@"%ld %@, ", minute, (minute > 1 ? @"minutes" : @"minute")];
    }
    
    if (month == 0) {
        [result appendFormat:@"%ld %@", second, (second > 1 ? @"seconds" : @"second")];
    }
    
    return result;
}

@end
