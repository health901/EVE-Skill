//
//  VGCharacterIDToImageValueTransformer.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 15/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGCharacterIDToImageValueTransformer.h"
#import "VGAppDelegate.h"
#import "VGAppNotifications.h"
#import "Portrait.h"

@interface VGCharacterIDToImageValueTransformer () {
    // App delegate
    VGAppDelegate *_appDelegate;
    
    // Core Data
    NSManagedObjectContext *_moc;
}

- (NSImage *)imageWithCharacterID:(NSString *)characterID;

@end

@implementation VGCharacterIDToImageValueTransformer

#pragma mark -
#pragma mark - Static methods

+ (Class)transformedValueClass
{
    return [NSImage class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

#pragma mark -
#pragma mark - Initialization

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

#pragma mark -
#pragma mark - Core Data stuff

- (NSImage *)imageWithCharacterID:(NSString *)characterID
{
    __block NSImage *_fetchedImage = nil;
    
    [_moc performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Portrait" inManagedObjectContext:_moc];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"characterID == %@", characterID];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [_moc executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Error while fetching Portrait with characterID = '%@' : %@, %@",
                      characterID, error, [error userInfo]);
                NSAlert *alert = [NSAlert alertWithError:error];
                [alert runModal];
            });
        }
        
        // Is there a portrait in the DB, if not we return nil
        if ([fetchedObjects count] > 0) {
            NSLog(@"Portrait for characterID '%@' in DB", characterID);
            _fetchedImage = ((Portrait *)[fetchedObjects lastObject]).image;
            
            // if _fetchedImage is nil, it will be downloaded again
        }
        
    }];
    
    return _fetchedImage;
}

#pragma mark -
#pragma mark - Value transformer

- (id)transformedValue:(id)value
{
    if (!value) {
        NSLog(@"VGCharacterIDToImageValueTransformer -transformedValue: Value is nil.");
        return [NSImage imageNamed:NSImageNameUserGuest];
    }
    
    if (![value isKindOfClass:[NSString class]]) {
        NSLog(@"VGCharacterIDToImageValueTransformer -transformedValue: Value is not an NSString but %@", [value class]);
        return [NSImage imageNamed:NSImageNameUserGuest];
    }
    
    NSLog(@"VGCharacterIDToImageValueTransformer searching for image with characterID = '%@'",
          value);
    
    NSImage *_image = [self imageWithCharacterID:(NSString *)value];
    
    if (!_image) {
        // Image is not in the DB, we have to download it
        NSLog(@"VGCharacterIDToImageValueTransformer image not in the DB for characterID = '%@'",
              value);
        
        // check if the dispatch group is nil
        if (!_appDelegate.apiController.portraitDispatchGroup) {
            NSLog(@"Creating portraitDispatchGroup");
            _appDelegate.apiController.portraitDispatchGroup = dispatch_group_create();
            
            // wait in another thread for the group to finish
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"Waiting for the end of portraitDispatchGroup...");
                dispatch_group_wait(_appDelegate.apiController.portraitDispatchGroup,
                                    DISPATCH_TIME_FOREVER);
                NSLog(@"portraitDispatchGroup ended !");
                _appDelegate.apiController.portraitDispatchGroup = nil;
                
                // post the notification for the character manager
                [[NSNotificationCenter defaultCenter] postNotificationName:MANAGER_SHOULD_RELOAD_DATA_NOTIFICATION
                                                                    object:self];
            });
        }
        
        dispatch_group_async(_appDelegate.apiController.portraitDispatchGroup,
                             _appDelegate.apiController.dispatchQueue,
                             ^{
            [_appDelegate.apiController addPortraitForCharacterID:(NSString *)value];
        });
        
        // Return a template image instead
        _image = [NSImage imageNamed:NSImageNameUserGuest];
    }
    
    return _image;
}

@end
