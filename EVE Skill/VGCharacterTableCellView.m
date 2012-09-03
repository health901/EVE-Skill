//
//  VGCharacterTableCellView.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 20/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGCharacterTableCellView.h"
#import "VGAppDelegate.h"
#import "Character.h"
#import "Queue+VGEVE.h"
#import "QueueElement+VGEVE.h"
#import "Skill.h"

@interface VGCharacterTableCellView () {
    
    // Managed Objects
    Character *_character;
    Queue *_queue;
    QueueElement *_currentQueueElement;
    Skill *_currentSkill;
}

@property (strong, nonatomic) VGAppDelegate *appDelegate;
@property (strong, nonatomic) NSManagedObjectContext *moc;

- (void)loadPortrait;
- (void)loadQueue;

@end

@implementation VGCharacterTableCellView

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

#pragma mark -
#pragma mark - View lifecycle

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    [super viewWillMoveToSuperview:newSuperview];
    
    // Notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:EVE_SKILLS_TIMER_TICK object:nil queue:nil usingBlock:^(NSNotification *note) {
        // Timer tick
        self.timeRemaining = [_queue timeRemaining];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:self.appDelegate.coreDataController.mainThreadContext queue:nil usingBlock:^(NSNotification *note) {
        // mainThreadContext did save, should we update ?
        
        [self loadPortrait];
        [self loadQueue];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:self.appDelegate.coreDataController.mainThreadContext queue:nil usingBlock:^(NSNotification *note) {
        // mainThreadContext did change, should we update ?
    }];
    
}

- (void)viewDidMoveToSuperview
{
    [super viewDidMoveToSuperview];
    
}

#pragma mark -
#pragma mark - KVO

- (void)setObjectValue:(id)objectValue
{
    [super setObjectValue:objectValue];
    
    if (objectValue != nil && objectValue != _character) {
        _character = objectValue;
        [self loadPortrait];
        [self loadQueue];
    }
}

#pragma mark -
#pragma mark - Core Data

- (VGAppDelegate *)appDelegate
{
    if (_appDelegate == nil) {
        _appDelegate = (VGAppDelegate *)[NSApp delegate];
    }
    
    return _appDelegate;
}

- (NSManagedObjectContext *)moc
{
    if (_moc == nil) {
        _moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_moc setParentContext:self.appDelegate.coreDataController.mainThreadContext];
    }
    
    return _moc;
}

- (void)loadPortrait
{
    if (_character == nil) return;
    
    // Fetch the Portrait associated with _character
    [self.moc performBlock:^{
        Portrait *portrait = [CoreDataController portraitWithCharacterID:_character.characterID
                                                               inContext:self.moc
                                                  notifyUserIfEmptyOrNil:NO];
        
        if (portrait == nil) {
            // No portrait in DB, download the portrait
            dispatch_async(_appDelegate.apiController.dispatchQueue, ^{
                [_appDelegate.apiController addPortraitForCharacterID:_character.characterID completionHandler:^(NSError *error, Portrait *portrait) {
                    self.portrait = portrait;
                }];
            });
        } else {
            // Portrait in the DB
            self.portrait = portrait;
        }
    }];
}

- (void)loadQueue
{
    if (_character == nil) return;
    
    // Fetch the Queue associated with _character
    [self.moc performBlock:^{
        _queue = [CoreDataController queueWithCharacterID:_character.characterID
                                                inContext:self.moc
                                   notifyUserIfEmptyOrNil:NO];
        
        if (_queue == nil) {
            // No queue in DB, download the queue
            dispatch_async(_appDelegate.apiController.dispatchQueue, ^{
                [_appDelegate.apiController addQueueWithCharacterID:_character.characterID];
            });
        } else {
            // Queue in the DB
            self.skillQueueView.queue = _queue;
            
            _currentQueueElement = nil;
            _currentSkill = nil;
            self.currentSkillName = nil;
            
            // Get the first QueueElement
            if (_queue.elements == nil) return;
            
            [_queue.elements enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                if ([((QueueElement *) obj).position intValue] == 0) {
                    _currentQueueElement = obj;
                    *stop = YES;
                }
            }];
            
            if (_currentQueueElement == nil) return;
            
            // Get the skill associated with the first element
            _currentSkill = [CoreDataController skillWithSkillID:_currentQueueElement.skillID
                                                       inContext:self.moc
                                          notifyUserIfEmptyOrNil:YES];
            
            self.currentSkillName = [NSString stringWithFormat:@"%@ %@",
                                     _currentSkill.skillName, _currentQueueElement.skillLevel.stringValue];
        }
    }];
}

#pragma mark -
#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    [super drawRect:dirtyRect];
}

@end
