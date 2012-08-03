//
//  VGAppDelegate.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 02/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGAppDelegate.h"

@implementation VGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Initializing Core Data
    _coreDataController = [[CoreDataController alloc] init];
    [_coreDataController loadPersistentStores];
    
}

@end
