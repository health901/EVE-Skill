//
//  VGManagerWindowController.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 03/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGManagerWindowController.h"
#import "VGAppDelegate.h"
#import "VGAppNotifications.h"

@interface VGManagerWindowController () {
    VGAppDelegate *_appDelegate;
}

@end

@implementation VGManagerWindowController
@synthesize characterTableView = _characterTableView;
@synthesize coreDataController = _coreDataController;
@synthesize tableSortDescriptors = _tableSortDescriptors;
@synthesize keyID = _keyID;
@synthesize vCode = _vCode;
@synthesize animateProgress = _animateProgress;
@synthesize authErrorHidden = _authErrorHidden;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // AppDelegate
    _appDelegate = (VGAppDelegate *)[NSApp delegate];
    
    // UI defaults
    self.authErrorHidden = YES;
    
    // Notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:APICALL_QUERY_DID_START_NOTIFICATION
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
        self.animateProgress = YES;
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:APICALL_QUERY_DID_END_NOTIFICATION
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
        self.animateProgress = NO;
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification
                                                      object:_appDelegate.apiController.apiControllerContext
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
        [self.characterTableView reloadData];
    }];
}

#pragma mark -
#pragma mark - Core Data

- (CoreDataController *)coreDataController
{
    if (!_coreDataController) {
        _coreDataController = ((VGAppDelegate *)[NSApp delegate]).coreDataController;
    }
    return _coreDataController;
}

- (NSArray *)tableSortDescriptors
{
    if (_tableSortDescriptors) {
        return _tableSortDescriptors;
    }
    
    _tableSortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"api.keyID" ascending:YES],
                             [NSSortDescriptor sortDescriptorWithKey:@"characterName" ascending:YES]];
    
    return _tableSortDescriptors;
}

#pragma mark -
#pragma mark - Key shortcuts

- (void)keyDown:(NSEvent *)theEvent
{
    // If the delete key is pressed, we remove the selected characters
    unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if(key == NSDeleteCharacter) {
        NSLog(@"keyDown | key == NSDeleteCharacter");
        
        [self deleteAction:nil];
    } else {
        [super keyDown:theEvent];
    }
}

#pragma mark -
#pragma mark - IBActions

- (IBAction)deleteAction:(id)sender
{
    // If rows are selected in the table view, we delete them
    if ([[self.characterTableView selectedRowIndexes] count] > 0) {
        [self.characterArrayController removeObjectsAtArrangedObjectIndexes:[self.characterTableView selectedRowIndexes]];
    }
}

- (void)queryAction:(id)sender
{
    dispatch_async(_appDelegate.apiController.dispatchQueue, ^{
        [_appDelegate.apiController addAPIWithKeyID:self.keyID vCode:self.vCode];
    });
}

- (IBAction)applyAction:(id)sender
{
    [_coreDataController saveMainThreadContext];
    [self.window performClose:self];
}

@end
