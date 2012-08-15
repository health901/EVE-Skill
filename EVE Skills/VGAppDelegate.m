//
//  VGAppDelegate.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 02/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGAppDelegate.h"
#import "VGManagerWindowController.h"
#import "VGSkillQueueViewController.h"


//
#import "VGSkillTree.h"

// temp imports
#import "Character.h"

@interface VGAppDelegate () {
    // Window controllers
    VGManagerWindowController *_managerWindowController;
    
    // View controllers
    VGSkillQueueViewController *_skillQueueViewController;
    
    // Menu bar
    NSStatusItem *_statusItem;
    NSMenu *_menu;
    
    // Menu items
    NSMenuItem *_skillQueueMenuItem;
    NSMenuItem *_managerMenuItem;
    NSMenuItem *_quitMenuItem;
}

- (void)apiControllerContextDidSave:(NSNotification *)note;

// MenuBar
- (void)setupMenu;
- (void)refreshMenu;

// MenuBar actions
- (void)managerAction;
- (void)quitAction;

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
    
    // MenuBarController
    [self setupMenu];
    
    // Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(apiControllerContextDidSave:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:_apiController.apiControllerContext];
    
    // Character manager
    [self openManagerWindow];
    
    // Check if there are characters in the DB
    [_coreDataController.mainThreadContext performBlock:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Character" inManagedObjectContext:_coreDataController.mainThreadContext];
        [fetchRequest setEntity:entity];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [_coreDataController.mainThreadContext executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            NSLog(@"fetchedObjects == nil");
        } else if ([fetchedObjects count] > 0){
            for (Character *character in fetchedObjects) {
                NSLog(@"%@ | %@", character.characterName, ([character.enabled boolValue] ? @"YES" : @"NO"));
            }
        } else {
            NSLog(@"No characters in DB");
        }
    }];
    
    // load skill tree code
//    VGSkillTree *skillTree = [[VGSkillTree alloc] init];
//    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [skillTree downloadAndGenerateSkillTree:^(NSError *error) {
//            NSAlert *alert = nil;
//            if (error) {
//                alert = [NSAlert alertWithError:error];
//            } else {
//                alert = [NSAlert alertWithMessageText:@"Skill Tree loaded"
//                                        defaultButton:@"OK"
//                                      alternateButton:nil
//                                          otherButton:nil
//                            informativeTextWithFormat:@""];
//            }
//            [alert runModal];
//            exit(0);
//        }];
//    });

}

#pragma mark -
#pragma mark - Private methods

- (void)apiControllerContextDidSave:(NSNotification *)note
{
//    [_coreDataController saveMainThreadContext];
}

#pragma mark -
#pragma mark - Public methods

- (void)openManagerWindow
{
    if (!_managerWindowController) {
        _managerWindowController = [[VGManagerWindowController alloc] initWithWindowNibName:@"VGManagerWindowController"];
    }
    
    [_managerWindowController.window makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark - Menubar

- (void)setupMenu
{
    // status item
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setTitle:@"EVE"];
    [_statusItem setToolTip:@"EVE Skills"];
    [_statusItem setEnabled:YES];
    [_statusItem setHighlightMode:YES];
    [_statusItem setTarget:self];
    
    // menu
    _menu = [[NSMenu alloc] initWithTitle:@"EVE Skill"];
    [_statusItem setMenu:_menu];
    
    // skill queue
    _skillQueueViewController = [[VGSkillQueueViewController alloc] initWithNibName:@"VGSkillQueueViewController" bundle:nil];
    _skillQueueMenuItem = [[NSMenuItem alloc] initWithTitle:@"Skill queue"
                                                     action:NULL
                                              keyEquivalent:@""];
    _skillQueueMenuItem.view = _skillQueueViewController.view;
    
    // menu items
    _managerMenuItem = [[NSMenuItem alloc] initWithTitle:@"Character manager"
                                                  action:@selector(managerAction)
                                           keyEquivalent:@""];
    [_managerMenuItem setEnabled:YES];
    
    _quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit"
                                               action:@selector(quitAction)
                                        keyEquivalent:@""];
    [_quitMenuItem setEnabled:YES];
    
    [self refreshMenu];
}

- (void)refreshMenu
{
    // clear the menu
    [_menu removeAllItems];
    
    // Add the bottom items
    [_menu addItem:_skillQueueMenuItem];
    [_menu addItem:[NSMenuItem separatorItem]];
    [_menu addItem:_managerMenuItem];
    [_menu addItem:[NSMenuItem separatorItem]];
    [_menu addItem:_quitMenuItem];
}

- (void)managerAction
{
    NSLog(@"managerAction");
    [self openManagerWindow];
}

- (void)quitAction
{
    NSLog(@"quitAction");
    [(NSApplication *)NSApp terminate:self];
}

#pragma mark -
#pragma mark - Application lifecycle

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    __block int reply = NSTerminateNow;
    
    NSManagedObjectContext *moc = _coreDataController.mainThreadContext;
    [moc performBlockAndWait:^{
        NSError *error = nil;
        if ([moc commitEditing]) {
            if ([moc hasChanges]) {
                if (![moc save:&error]) {
                    
                    BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
                    
                    if (errorResult == YES) {
                        reply = NSTerminateCancel;
                    }  else {
                        NSInteger alertReturn = NSRunAlertPanel(nil,
                                                          @"Could not save changes while quitting. Quit anyway?",
                                                          @"Quit",
                                                          @"Cancel",
                                                          nil);
                        if (alertReturn == NSAlertAlternateReturn) {
                            reply = NSTerminateCancel;
                        }
                    }
                }
            }
        }
    }];
    
    return reply;
}

@end
