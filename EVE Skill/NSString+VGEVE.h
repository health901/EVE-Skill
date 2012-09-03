//
//  NSString+VGEVE.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 01/09/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (VGEVE)

+ (NSString *)timeRemainingStringFromDate:(NSDate *)fromDate
                                   toDate:(NSDate *)toDate;

+ (NSString *)timeRemainingStringFromDate:(NSDate *)fromDate
                                   toDate:(NSDate *)toDate
                            humanReadable:(BOOL)humanReadable;

@end
