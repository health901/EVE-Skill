//
//  NSString+VGEVE.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 01/09/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "NSString+VGEVE.h"

@implementation NSString (VGEVE)

+ (NSString *)timeRemainingStringFromDate:(NSDate *)fromDate
                                   toDate:(NSDate *)toDate
{
    return [NSString timeRemainingStringFromDate:fromDate toDate:toDate humanReadable:NO];
}

+ (NSString *)timeRemainingStringFromDate:(NSDate *)fromDate
                                   toDate:(NSDate *)toDate
                            humanReadable:(BOOL)humanReadable
{
    NSAssert(fromDate, @"fromDate must not be nil");
    NSAssert(toDate,   @"toDate must not be nil");
    
    unsigned int unitFlags = NSYearCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *dateComponents = [calendar components:unitFlags
                                                   fromDate:fromDate
                                                     toDate:toDate
                                                    options:0];
    
//    NSInteger year   = [dateComponents year];
    NSInteger month  = [dateComponents month];
    NSInteger day    = [dateComponents day];
    NSInteger hour   = [dateComponents hour];
    NSInteger minute = [dateComponents minute];
    NSInteger second = [dateComponents second];
    
    
    NSMutableString *result = [[NSMutableString alloc] init];
    
//    if (humanReadable) {
//        
//    } else {
    if (month > 0) {
        [result appendFormat:@"%ld %@ ", month, (month > 1 ? NSLocalizedString(@"months", nil) :
                                                 NSLocalizedString(@"month", nil))];
    }
    
    if (day > 0) {
        [result appendFormat:@"%ld %@ ", day, (day > 1 ? NSLocalizedString(@"days", nil) :
                                               NSLocalizedString(@"day", nil))];
    }
    
    if (hour > 0) {
        [result appendFormat:@"%ld %@ ", hour, (hour > 1 ? NSLocalizedString(@"hours", nil) :
                                                NSLocalizedString(@"hour", nil))];
    }
    
    if (minute > 0) {
        [result appendFormat:@"%ld %@ ", minute, (minute > 1 ? NSLocalizedString(@"minutes", nil) :
                                                  NSLocalizedString(@"minute", nil))];
    }
    
    if (month == 0) {
        [result appendFormat:@"%ld %@", second, (second > 1 ? NSLocalizedString(@"seconds", nil) :
                                                 NSLocalizedString(@"second", nil))];
    }
//    }
    
    return result;
}

@end
