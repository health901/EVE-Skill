//
//  VGSkillQueueViewController.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 15/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGSkillQueueViewController.h"

#define QUEUE_CELL_DEFAULT_WIDTH 300
#define QUEUE_CELL_DEFAULT_HEIGHT 66

@interface VGSkillQueueViewController () {
    // App Delegate
    VGAppDelegate *_appDelegate;
}

- (void)resizeToFitEnabledCharacters;

@end

@implementation VGSkillQueueViewController
@synthesize characterTableView = _characterTableView;
@synthesize coreDataController = _coreDataController;
@synthesize tableSortDescriptors = _tableSortDescriptors;

#pragma mark -
#pragma mark - Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _appDelegate = (VGAppDelegate *)[NSApp delegate];
    }
    
    return self;
}

#pragma mark -
#pragma mark - Private Methods

- (void)logRect:(NSRect)rect string:(NSString *)string
{
    NSLog(@"{(%f,%f),(%f,%f)}", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

- (void)resizeToFitEnabledCharacters
{
    // First get the number of enabled characters
    [_appDelegate.coreDataController.mainThreadContext performBlock:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Character" inManagedObjectContext:_appDelegate.coreDataController.mainThreadContext];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"enabled == %@", [NSNumber numberWithBool:YES]];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [_appDelegate.coreDataController.mainThreadContext executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            NSLog(@"Error fetching enabled Characters: %@, %@", error, [error userInfo]);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [NSAlert alertWithError:error];
                [alert runModal];
            });
        }
        
        NSUInteger characterCount = [fetchedObjects count];
        
        NSLog(@"characterCount = %lu", characterCount);
        
        // Compute the new frame's size
        NSRect newFrame;
        
        if (characterCount > 0) {
            newFrame.origin.x       = 0;
            newFrame.origin.y       = 0;
            newFrame.size.width     = QUEUE_CELL_DEFAULT_WIDTH + 3;
            newFrame.size.height    = characterCount * (QUEUE_CELL_DEFAULT_HEIGHT + 2);
        } else {
            newFrame.origin.x       = 0;
            newFrame.origin.y       = 0;
            newFrame.size.width     = QUEUE_CELL_DEFAULT_WIDTH + 3;
            newFrame.size.height    = 1;
        }
        
        [self.view setFrame:newFrame];
    }];
}

#pragma mark -
#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    // resize to fit the number of characters
    [self resizeToFitEnabledCharacters];
    
    // Notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:_appDelegate.coreDataController.mainThreadContext queue:nil usingBlock:^(NSNotification *note) {
        [self resizeToFitEnabledCharacters];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:SKILL_QUEUE_SHOULD_RELOAD_DATA_NOTIFICATION
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
        [self.characterTableView reloadData];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:MANAGER_SHOULD_RELOAD_DATA_NOTIFICATION
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self.characterTableView reloadData];
                                                  }];
}

#pragma mark -
#pragma mark - NSTableViewDelegate

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    // Disable row selection
    return NO;
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
    
    _tableSortDescriptors = [NSArray arrayWithObjects:
                             [NSSortDescriptor sortDescriptorWithKey:@"api.keyID" ascending:YES],
                             [NSSortDescriptor sortDescriptorWithKey:@"characterName" ascending:YES], nil];
    
    return _tableSortDescriptors;
}

@end
