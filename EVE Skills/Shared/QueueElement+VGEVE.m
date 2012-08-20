//
//  QueueElement+VGEVE.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 16/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "QueueElement+VGEVE.h"

@implementation QueueElement (VGEVE)

- (NSString *)timeRemaining
{
    if (self.startTime == nil || self.endTime == nil) {
        return @"self.startTime == nil || self.endTime == nil";
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *date1 = nil;
    if ([self.position intValue] == 0) {
        // Current skill in training
        date1 = [NSDate date];
    } else {
        // Skill not in training
        date1 = self.startTime;
    }
    NSDate *date2 = self.endTime;
    
    unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSSecondCalendarUnit;
    
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
