//
//  VGCharacterIDToTimeRemainingValueTransformer.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 20/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGCharacterIDToTimeRemainingValueTransformer.h"
#import "VGAppDelegate.h"

@interface VGCharacterIDToTimeRemainingValueTransformer () {
    // App delegate
    VGAppDelegate *_appDelegate;
    
    // Core Data
    NSManagedObjectContext *_moc;
    
    // QueueDictionary
}

@end

@implementation VGCharacterIDToTimeRemainingValueTransformer

#pragma mark -
#pragma mark - Static methods

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

#pragma mark -
#pragma mark - Initializations

- (id)init
{
    self = [super init];
    if (self) {
        _appDelegate = (VGAppDelegate *)[NSApp delegate];
        
        _moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_moc setParentContext:_appDelegate.coreDataController.mainThreadContext];
    }
    return self;
}

@end
