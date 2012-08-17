//
//  VGCurrentSkillTextField.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 16/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGCurrentSkillTextField.h"
#import "VGAppDelegate.h"
#import "Queue+VGEVE.h"
#import "QueueElement+VGEVE.h"
#import "Skill.h"

@interface VGCurrentSkillTextField () {
    // App delegate
    VGAppDelegate *_appDelegate;
    
    // Core Data
    NSManagedObjectContext *_moc;
    
    Queue *_queue;
    QueueElement *_queueElement;
    Skill *_skill;
}

- (void)fetchCurrentSkillAsync;

@end

@implementation VGCurrentSkillTextField

#pragma mark -
#pragma mark - Initialization

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
        
    }
    
    return self;
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    [super viewWillMoveToSuperview:newSuperview];
    
    _appDelegate = (VGAppDelegate *)[NSApp delegate];
    
    _moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_moc setParentContext:_appDelegate.coreDataController.mainThreadContext];
    
    _queue = nil;
    _queueElement = nil;
    _skill = nil;
    
    // Add observer for events
    [[NSNotificationCenter defaultCenter] addObserverForName:SKILL_QUEUE_SHOULD_RELOAD_DATA_NOTIFICATION object:nil queue:nil usingBlock:^(NSNotification *note) {
        
    }];
}

#pragma mark -
#pragma mark - Core Data

- (void)fetchCurrentSkillAsync
{
    _skill = nil;
    _queue = nil;
    _queueElement = nil;
    
    [_moc performBlock:^{
        // If objectValue is nil or not an NSString, return immediately
        if (self.objectValue == nil || ![self.objectValue isKindOfClass:[NSString class]]) {
            return;
        }
        
        // objectValue is an NSString and not nil, we create a MOC and fetch the character's Queue
        
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Queue" inManagedObjectContext:_moc];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"characterID == %@", self.objectValue];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [_moc executeFetchRequest:fetchRequest error:&error];
        
        if (fetchedObjects == nil) {
            NSLog(@"Error fetching Queue with characterID = '%@' : %@, %@",
                  self.objectValue, error, [error userInfo]);
        }
        
        // If there is no Queue object, we call the API
        if (fetchedObjects.count == 0) {
            NSLog(@"NOT IMPLEMENTED");
            abort();
        }
        
        // We found the queue object
        _queue = fetchedObjects.lastObject;
        
        // Find the current skill in training
        
        // If the queue is nil or empty, we call the API
        if (_queue.elements == nil || _queue.elements.count == 0) {
            NSLog(@"NOT IMPLEMENTED");
            abort();
        }
        
        // The queue is not nil and not empty, we find the current skill in training
        for (QueueElement *queueElement in [_queue.elements allObjects]) {
            // The current skill in training has position == 0
            if ([queueElement.position intValue] == 0) {
                _queueElement = queueElement;
                break;
            }
        }
        
        // If _queueElement is nil, then there is a problem in the database, we call the API
        if (_queueElement == nil) {
            NSLog(@"NOT IMPLEMENTED");
            abort();
        }
        
        // _queueElement is not nil, we fetch the associated Skill
        fetchRequest = [[NSFetchRequest alloc] init];
        entity = [NSEntityDescription entityForName:@"Skill" inManagedObjectContext:_moc];
        [fetchRequest setEntity:entity];
        
        predicate = [NSPredicate predicateWithFormat:@"skillID == %@", _queueElement.skillID];
        [fetchRequest setPredicate:predicate];
        
        error = nil;
        fetchedObjects = [_moc executeFetchRequest:fetchRequest error:&error];
        
        if (fetchedObjects == nil) {
            NSLog(@"Error fetching Skill with skillID = '%@' : %@, %@",
                  _queueElement.skillID, error, [error userInfo]);
        }
        
        // If there is no such skill in the DB, that's VERY BAD
        if (fetchedObjects.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [NSAlert alertWithMessageText:@"Skill not found"
                                                 defaultButton:@"OK"
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"skillID = '%@'", _queueElement.skillID];
                [alert runModal];
            });
            return;
        }
        
        // We found the skill in the DB, lets reload the view
        _skill = fetchedObjects.lastObject;
        
        // Reload the view
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self setNeedsDisplayInRect:[self visibleRect]];
        });
    }];
}

#pragma mark -
#pragma mark - objectValue

- (void)setObjectValue:(id<NSCopying>)obj
{
    [super setObjectValue:obj];
    [self fetchCurrentSkillAsync];
}

#pragma mark -
#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    // The objective is to set the right stringValue for the textfield
    if (self.objectValue == nil || ![self.objectValue isKindOfClass:[NSString class]]) {
        self.stringValue = nil;
    } else if (_queue == nil) {
        // _queue is nil -> DB problem
        self.stringValue = nil;
        
    } else if (_queueElement == nil) {
        // _queueElement is nil -> No skill in training
        self.stringValue = @"No skill in training";
        
    } else if (_skill == nil) {
        // _skill is nil - > DB problem
        self.stringValue = @"_skill == nil";
        
    } else {
        // All is good, give the skill name
        self.stringValue = _skill.skillName;
    }
    
    
    
    
    [super drawRect:dirtyRect];
}

@end
