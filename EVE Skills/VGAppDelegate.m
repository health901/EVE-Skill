//
//  VGAppDelegate.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 02/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGAppDelegate.h"
#import "VGManagerWindowController.h"

@interface VGAppDelegate () {
    VGManagerWindowController *_managerWC;
}

- (void)apiControllerContextDidSave:(NSNotification *)note;

@end

@implementation VGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Initializing Core Data
    _coreDataController = [[CoreDataController alloc] init];
    [_coreDataController loadPersistentStores];
    
    // Initializing API Call
    _apiController = [[VGAPIController alloc] init];
    dispatch_async(_apiController.dispatchQueue, ^{
        [_apiController initialize];
    });
    
    // Notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(apiControllerContextDidSave:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:_apiController.apiControllerContext];
    
    // Character manager
    _managerWC = [[VGManagerWindowController alloc] initWithWindowNibName:@"VGManagerWindowController"];
    [_managerWC.window makeKeyAndOrderFront:nil];
    
}

#pragma mark -
#pragma mark - Private methods

- (void)apiControllerContextDidSave:(NSNotification *)note
{
    [_coreDataController.mainThreadContext performBlock:^{
        [_coreDataController.mainThreadContext mergeChangesFromContextDidSaveNotification:note];
        
//        dispatch_sync(dispatch_get_current_queue(), ^{
//            NSError *saveError = nil;
//            if (![_coreDataController.mainThreadContext save:&saveError]) {
//                NSLog(@"Error saving mainThreadContext : %@, %@", saveError, [saveError userInfo]);
//            }
//        });
    }];
}

#pragma mark -
#pragma mark - Application lifecycle

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    __block int reply = NSTerminateNow;
    
    NSManagedObjectContext *moc = _coreDataController.mainThreadContext;
    [moc performBlockAndWait:^{
        NSError *error;
        if ([moc commitEditing]) {
            if ([moc hasChanges]) {
                if ([moc save:&error]) {
                    
                }
            }
        }
    }];
    
    return reply;
}

@end
