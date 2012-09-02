//
//  VGLoginStart.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 02/09/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VGLoginStart : NSObject

// http://stackoverflow.com/a/2318004/515196

+ (BOOL) willStartAtLogin:(NSURL *)itemURL;

+ (void) setStartAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled;

@end
