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
#import "VGLoginStart.h"


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
    NSMenuItem *_refreshMenuItem;
    NSMenuItem *_startAtLoginMenuItem;
    NSMenuItem *_managerMenuItem;
    NSMenuItem *_aboutMenuItem;
    NSMenuItem *_quitMenuItem;
    
    // Timers
    NSTimer *_skillQueueReloadTimer;    // refresh characters skill queue
    NSTimer *_skillQueueTimeTimer;      // timer for the remaining time counter refresh
}

@property BOOL startAtLogin;

- (void)apiControllerContextDidSave:(NSNotification *)note;

// Preferences
- (void)loadAppDefaultPreferences;

// MenuBar
- (void)setupMenu;
- (void)refreshMenu;

// MenuBar actions
- (void)refreshAction;
- (void)managerAction;
- (void)quitAction;

// Timer actions
- (void)skillQueueTimeTimerAction:(NSTimer*)theTimer;
- (void)skillQueueReloadTimerAction:(NSTimer*)theTimer;

@end

@implementation VGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // App preferences
    [self loadAppDefaultPreferences];
    
    // Initializing Core Data
    _coreDataController = [[CoreDataController alloc] init];
    [_coreDataController loadPersistentStores:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // Initializing API Controller
            _apiController = [[VGAPIController alloc] init];
            dispatch_async(_apiController.dispatchQueue, ^{
                [_apiController initialize];
                
                
            });
            
            // Initializing user notification controller
            _userNotificationController = [[VGUserNotificationController alloc] init];
            
            // MenuBarController
            [self setupMenu];
            
            // Log some thing about the app
            
            // Start at login
            NSLog(@"appURL       = %@", [self appURL]);
            NSLog(@"startAtLogin = %@", [VGLoginStart willStartAtLogin:[self appURL]] ? @"YES" : @"NO");
            
            // Characters in DB
//            [_coreDataController.mainThreadContext performBlock:^{
//                NSArray *fetchedObjects = [CoreDataController characterEnabled:nil
//                                                                     inContext:_coreDataController.mainThreadContext
//                                                               notifyUserIfNil:NO];
//                if (fetchedObjects == nil) {
//                    NSLog(@"fetchedObjects == nil");
//                } else if ([fetchedObjects count] > 0){
//                    for (Character *character in fetchedObjects) {
//                        NSLog(@"%@ | %@", character.characterName, ([character.enabled boolValue] ? @"YES" : @"NO"));
//                    }
//                } else {
//                    NSLog(@"No characters in DB");
//                }
//            }];
            
            // If there is no enabled character in DB, open the character manager
            NSArray *fetchedObjects = [CoreDataController characterEnabled:@YES
                                                                 inContext:_coreDataController.mainThreadContext
                                                           notifyUserIfNil:NO];
            if (fetchedObjects.count == 0) {
                [self openManagerWindow];
            }
            
            // Timers
            _skillQueueReloadTimer = [NSTimer timerWithTimeInterval:1.0*60*60 target:self selector:@selector(skillQueueReloadTimerAction:) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:_skillQueueReloadTimer forMode:NSRunLoopCommonModes];
            
            _skillQueueTimeTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(skillQueueTimeTimerAction:) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:_skillQueueTimeTimer forMode:NSRunLoopCommonModes];
            
            [_skillQueueReloadTimer fire];
            [_skillQueueTimeTimer fire];
            
            // Notifications
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(apiControllerContextDidSave:)
                                                         name:NSManagedObjectContextDidSaveNotification
                                                       object:_apiController.apiControllerContext];
            
            [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreCoordinatorStoresDidChangeNotification object:_coreDataController.psc queue:nil usingBlock:^(NSNotification *note) {
                NSLog(@"NSPersistentStoreCoordinatorStoresDidChangeNotification");
            }];
            
            
        });
        
    }];
    
    
    
    // Character manager
//    [self openManagerWindow];
    
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
#pragma mark - Application defaults

- (void)loadAppDefaultPreferences
{
    NSDictionary *appDefaults = @{@"colorSkill1": [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:58.0/255 green:139.0/255 blue:176.0/255 alpha:1.0]],
                                 @"colorSkill2": [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:34.0/255 green:112.0/255 blue:157.0/255 alpha:1.0]],
                                 @"colorWarning": [NSArchiver archivedDataWithRootObject:[NSColor yellowColor]],
                                 @"colorError": [NSArchiver archivedDataWithRootObject:[NSColor redColor]]};
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
}

#pragma mark -
#pragma mark - Core Data notifications handler

- (void)apiControllerContextDidSave:(NSNotification *)note
{
//    [_coreDataController saveMainThreadContext];
}

#pragma mark -
#pragma mark - Window & Menu

- (void)openManagerWindow
{
    if (!_managerWindowController) {
        _managerWindowController = [[VGManagerWindowController alloc] initWithWindowNibName:@"VGManagerWindowController"];
    }
    [NSApp activateIgnoringOtherApps:YES];
    [_managerWindowController.window makeKeyAndOrderFront:nil];
}

- (void)openAboutWindow
{
    [NSApp orderFrontStandardAboutPanel:self];
}

- (void)showMenuBarMenu
{
    if (_statusItem != nil) {
        [_statusItem popUpStatusItemMenu:_menu];
    }
}

#pragma mark -
#pragma mark - Timer actions

- (void)skillQueueTimeTimerAction:(NSTimer*)theTimer
{
    // Send the notification
    [[NSNotificationCenter defaultCenter] postNotificationName:EVE_SKILLS_TIMER_TICK
                                                        object:self];
}

- (void)skillQueueReloadTimerAction:(NSTimer*)theTimer
{
    dispatch_async(_apiController.dispatchQueue, ^{
        NSLog(@"Refreshing skill queue...");
        [_apiController refreshQueueForCharacterEnabled:YES completionBlock:^{
            NSLog(@"Refreshing skill queue... DONE");
        }];
    });
}

#pragma mark -
#pragma mark - Menubar

- (void)setupMenu
{
    // status item
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"menu_bar_icon"
                                                     ofType:@"tiff"];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
    _statusItem.image = image;
    [_statusItem setToolTip:NSLocalizedString(@"menuTooltipTitle", nil)];
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
    _refreshMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"menuRefresh", nil)
                                                  action:@selector(refreshAction)
                                           keyEquivalent:@""];
    
    _startAtLoginMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"menuStartAtLogin", nil)
                                                       action:@selector(startAtLoginAction)
                                                keyEquivalent:@""];
    _startAtLoginMenuItem.title = ([VGLoginStart willStartAtLogin:[self appURL]] ? NSLocalizedString(@"menuStartAtLoginYES", nil) : NSLocalizedString(@"menuStartAtLoginNO", nil));
    
    _managerMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"menuCharacterManager", nil)
                                                  action:@selector(managerAction)
                                           keyEquivalent:@""];
    
    _aboutMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"menuAbout", nil)
                                                action:@selector(aboutAction)
                                         keyEquivalent:@""];
    
    _quitMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"menuQuit", nil)
                                               action:@selector(quitAction)
                                        keyEquivalent:@""];
    
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
    [_menu addItem:_startAtLoginMenuItem];
//    [_menu addItem:_refreshMenuItem];
    [_menu addItem:[NSMenuItem separatorItem]];
    [_menu addItem:_aboutMenuItem];
    [_menu addItem:[NSMenuItem separatorItem]];
    [_menu addItem:_quitMenuItem];
}

- (void)refreshAction
{
    NSLog(@"refreshAction");
//    [_coreDataController deleteLocalStore:^{
//        NSLog(@"refreshAction - DONE");
//        [_apiController refreshQueueForCharacterEnabled:YES completionBlock:^{
//            
//        }];
//    }];
}

- (void)managerAction
{
    NSLog(@"managerAction");
    [self openManagerWindow];
}

- (void)startAtLoginAction
{
    NSLog(@"startAtLoginAction");
    
    // Add/Remove the app from the login start list
    [VGLoginStart setStartAtLogin:[self appURL] enabled:![VGLoginStart willStartAtLogin:[self appURL]]];
    
    // Update the UI
    _startAtLoginMenuItem.title = ([VGLoginStart willStartAtLogin:[self appURL]] ? NSLocalizedString(@"menuStartAtLoginYES", nil) : NSLocalizedString(@"menuStartAtLoginNO", nil));
}

- (void)aboutAction
{
    NSLog(@"aboutAction");
    [self openAboutWindow];
}

- (void)quitAction
{
    NSLog(@"quitAction");
    [(NSApplication *)NSApp terminate:self];
}

#pragma mark -
#pragma mark - Application lifecycle

- (void)applicationWillBecomeActive:(NSNotification *)notification
{
    NSLog(@"applicationWillBecomeActive");
}

- (void)applicationDidResignActive:(NSNotification *)notification
{
    NSLog(@"applicationDidResignActive");
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    __block int reply = NSTerminateNow;
    
    // Save the main thread context to disk
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
                                                          NSLocalizedString(@"savingErrorMessage", nil),
                                                          NSLocalizedString(@"Quit", nil),
                                                          NSLocalizedString(@"Cancel", nil),
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

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [_coreDataController applicationResumed];
}

#pragma mark -
#pragma mark - Misc.

- (NSURL *)appURL
{
    return [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
}

@end
