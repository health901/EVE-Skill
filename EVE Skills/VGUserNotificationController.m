//
//  VGUserNotificationController.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 20/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGUserNotificationController.h"
#import "VGAppDelegate.h"
#import "Character.h"
#import "Skill.h"
#import "Queue+VGEVE.h"
#import "QueueElement+VGEVE.h"

@interface VGUserNotificationController () {
    NSUserNotificationCenter *_defaultCenter;
}

@property (strong, nonatomic) VGAppDelegate *appDelegate;
@property (strong, nonatomic) NSManagedObjectContext *moc;

// Dictionary containing a mutable array of NSUserNotification associated with a characterID
@property (strong, nonatomic) NSMutableDictionary *notificationDict;

// Notifications
- (void)removeAllNotifications;

- (void)addNotificationsWithQueue:(Queue *)queue;
- (void)removeNotificationsWithQueue:(Queue *)queue;
- (void)removeNotificationsWithCharacterID:(NSString *)characterID;

- (NSUserNotification *)userNotificationEmptyQueueWithCharacterID:(NSString *)characterID;
- (NSUserNotification *)userNotificationWithCharacterID:(NSString *)characterID queueElement:(QueueElement *)queueElement;

// Core Data
- (Queue *)queueWithCharacterIDSync:(NSString *)characterID;
- (Character *)fetchCharacterWithCharacterIDSync:(NSString *)characterID;
- (Skill *)fetchSkillWithSkillIDSync:(NSString *)skillID;

@end

@implementation VGUserNotificationController

static NSString *kUserNotificationCharacterID = @"kUserNotificationCharacterID";
static NSString *kUserNotificationIsSkillEnd = @"kUserNotificationIsSkillEnd";

#pragma mark -
#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        _dispatchQueue = dispatch_queue_create("com.vincentgarrigues.userNotificationControllerQueue",
                                               DISPATCH_QUEUE_SERIAL);
        
        _defaultCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
        _defaultCenter.delegate = self;
        
        // Notifications
        [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:self.appDelegate.coreDataController.mainThreadContext queue:nil usingBlock:^(NSNotification *note) {
//            NSLog(@"note.userInfo[NSInsertedObjectsKey] : %@", note.userInfo[NSInsertedObjectsKey]);
//            NSLog(@"note.userInfo[NSUpdatedObjectsKey] : %@", note.userInfo[NSUpdatedObjectsKey]);
//            NSLog(@"note.userInfo[NSDeletedObjectsKey] : %@", note.userInfo[NSDeletedObjectsKey]);
            dispatch_async(self.dispatchQueue, ^{
                // Find the modified Queue objects
                [(NSSet *)note.userInfo[NSInsertedObjectsKey] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                    if ([obj isKindOfClass:[Queue class]]) {
                        NSLog(@"Inserted : Queue %@", ((Queue *)obj).objectID);
                        dispatch_async(self.dispatchQueue, ^{
                            [self addNotificationsWithQueue:(Queue *)[self.moc objectWithID:((Queue *)obj).objectID]];
                        });
                    }
                }];
                
                [(NSSet *)note.userInfo[NSUpdatedObjectsKey] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                    if ([obj isKindOfClass:[Queue class]]) {
                        NSLog(@"Updated : Queue %@", ((Queue *)obj).objectID);
                        dispatch_async(self.dispatchQueue, ^{
                            [self addNotificationsWithQueue:(Queue *)[self.moc objectWithID:((Queue *)obj).objectID]];
                        });
                    }
                }];
                
                [(NSSet *)note.userInfo[NSDeletedObjectsKey] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                    if ([obj isKindOfClass:[Queue class]]) {
                        NSLog(@"Deleted : Queue %@", ((Queue *)obj).objectID);
                        dispatch_async(self.dispatchQueue, ^{
                            [self removeNotificationsWithQueue:(Queue *)[self.moc objectWithID:((Queue *)obj).objectID]];
                        });
                    }
                }];
            });
        }];
    }
    return self;
}

#pragma mark -
#pragma mark - Properties

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

- (NSMutableDictionary *)notificationDict
{
    if (_notificationDict == nil) {
        _notificationDict = [[NSMutableDictionary alloc] init];
    }
    
    return _notificationDict;
}

#pragma mark -
#pragma mark - Notifications

- (void)reloadAllNotifications
{
    assert(dispatch_get_current_queue() == self.dispatchQueue);
    
    [self removeAllNotifications];
    
    __block NSArray *characterArray;
    
    // Fetch all enabled characters
    [self.moc performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Character" inManagedObjectContext:self.moc];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"enabled == %@", @YES];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [self.moc executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            NSLog(@"Error fetching enabled Character : %@, %@", error, [error userInfo]);
        }
        
        characterArray = fetchedObjects;
    }];
    
    for (Character *character in characterArray) {
        Queue *queue = [self queueWithCharacterIDSync:character.characterID];
//        NSLog(@"%@ : %@", character.characterName, queue);
        if (queue) {
            [self addNotificationsWithQueue:queue];
        }
    }
}

- (void)removeAllNotifications
{
    [_defaultCenter removeAllDeliveredNotifications];
    for (NSArray *notificationArray in self.notificationDict.allValues) {
        for (NSUserNotification *userNotification in notificationArray) {
            [_defaultCenter removeScheduledNotification:userNotification];
        }
    }
    
    self.notificationDict = nil;
}

- (void)addNotificationsWithQueue:(Queue *)queue
{
    assert(queue != nil);
    
    [self removeNotificationsWithQueue:queue];
    
    // If the queue is empty, add a queue empty notification
    if (queue.elements == nil || queue.elements.count == 0) {
        [self.notificationDict setObject:@[ [self userNotificationEmptyQueueWithCharacterID:queue.characterID] ]
                                  forKey:queue.characterID];
        return;
    }
    
    // If the queue is not empty, add a notification for each QueueElement
    NSMutableArray *notificationsArray = [[NSMutableArray alloc] initWithCapacity:queue.elements.count];
    
    for (QueueElement *queueElement in queue.elements) {
        [notificationsArray addObject:[self userNotificationWithCharacterID:queue.characterID
                                                               queueElement:queueElement]];
    }
    
    [self.notificationDict setObject:notificationsArray forKey:queue.characterID];
}

- (void)removeNotificationsWithQueue:(Queue *)queue
{
    [self removeNotificationsWithCharacterID:queue.characterID];
}

- (void)removeNotificationsWithCharacterID:(NSString *)characterID
{
    NSArray *notificationsArray = [self.notificationDict objectForKey:characterID];
    for (NSUserNotification *userNotification in notificationsArray) {
        [_defaultCenter removeScheduledNotification:userNotification];
    }
}

- (NSUserNotification *)userNotificationEmptyQueueWithCharacterID:(NSString *)characterID
{
    NSUserNotification *userNotification = [[NSUserNotification alloc] init];
    
    Character *character = [self fetchCharacterWithCharacterIDSync:characterID];
    
    if (character == nil) return nil;
    
    userNotification.title              = NSLocalizedString(@"notificationQueueEmptyTitle", nil);
    userNotification.subtitle           = character.characterName;
    userNotification.informativeText    = [NSString stringWithFormat:NSLocalizedString(@"notificationQueueEmptyInfo", nil), character.characterName];
    userNotification.deliveryDate       = [NSDate date];
    userNotification.soundName          = NSUserNotificationDefaultSoundName;
    userNotification.userInfo           = @{ kUserNotificationCharacterID : characterID,
                                             kUserNotificationIsSkillEnd  : @NO };
    
    [_defaultCenter scheduleNotification:userNotification];

    return userNotification;
}

- (NSUserNotification *)userNotificationWithCharacterID:(NSString *)characterID queueElement:(QueueElement *)queueElement
{
    NSUserNotification *userNotification = [[NSUserNotification alloc] init];
    
    // Fetch the associated Character
    Character *character = [self fetchCharacterWithCharacterIDSync:characterID];
    
    // Fetch the associated skill
    Skill *skill = [self fetchSkillWithSkillIDSync:queueElement.skillID];
    
    if (character == nil || skill == nil) return nil;
    
    userNotification.title              = [NSString stringWithFormat:NSLocalizedString(@"notificationSkillTitle", nil), skill.skillName, queueElement.skillLevel];
    userNotification.subtitle           = character.characterName;
    userNotification.informativeText    = [NSString stringWithFormat:NSLocalizedString(@"notificationSkillInfo", nil), character.characterName, skill.skillName, queueElement.skillLevel];
    userNotification.deliveryDate       = queueElement.endTime;
    userNotification.soundName          = NSUserNotificationDefaultSoundName;
    userNotification.userInfo           = @{ kUserNotificationCharacterID : characterID,
                                             kUserNotificationIsSkillEnd  : @YES };
    
    [_defaultCenter scheduleNotification:userNotification];
    
    return userNotification;
}

#pragma mark -
#pragma mark - Core Data

- (Queue *)queueWithCharacterIDSync:(NSString *)characterID
{
    __block Queue *queue = nil;
    
    [self.moc performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Queue" inManagedObjectContext:self.moc];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"characterID == %@", characterID];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [self.moc executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            NSLog(@"Error fetching Queue with characterID = '%@' : %@, %@",
                  characterID, error, [error userInfo]);
        }
        
        if (fetchedObjects.count == 0) {
            // Not important
        } else {
            queue = fetchedObjects.lastObject;
        }
        
    }];
    
    return queue;
}

- (Character *)fetchCharacterWithCharacterIDSync:(NSString *)characterID
{
    __block Character *character = nil;
    
    [self.moc performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Character" inManagedObjectContext:self.moc];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"characterID == %@", characterID];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [self.moc executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            NSLog(@"Error fetching Character with characterID = '%@' : %@, %@",
                  characterID, error, [error userInfo]);
        }
        
        if (fetchedObjects.count == 0) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"characterNotFoundError", nil)
                                                 defaultButton:NSLocalizedString(@"OK", nil)
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:NSLocalizedString(@"characterNotFoundErrorMessage", nil), characterID];
                [alert runModal];
            });
        } else {
            character = fetchedObjects.lastObject;
        }
        
    }];
    
    return character;
}

- (Skill *)fetchSkillWithSkillIDSync:(NSString *)skillID
{
    __block Skill *skill = nil;
    
    [self.moc performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Skill" inManagedObjectContext:self.moc];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"skillID == %@", skillID];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [self.moc executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            NSLog(@"Error fetching Skill with skillID = '%@' : %@, %@",
                  skillID, error, [error userInfo]);
        }
        
        if (fetchedObjects.count == 0) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"skillNotFoundError", nil)
                                                 defaultButton:NSLocalizedString(@"OK", nil)
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:NSLocalizedString(@"skillNotFoundErrorMessage", nil), skillID];
                [alert runModal];
            });
        } else {
            skill = fetchedObjects.lastObject;
        }
        
    }];
    
    return skill;
}

#pragma mark -
#pragma mark - NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
        didDeliverNotification:(NSUserNotification *)notification
{
    NSLog(@"userNotificationCenter:didDeliverNotification:");
    NSLog(@"%@, %@, %@", notification.title, notification.subtitle, notification.informativeText);
    NSLog(@"%@", notification.deliveryDate);
    
    if (notification.userInfo[kUserNotificationIsSkillEnd] == @YES) {
        // Reload the skill queue of the character
        dispatch_async(_appDelegate.apiController.dispatchQueue, ^{
            [_appDelegate.apiController addQueueWithCharacterID:notification.userInfo[kUserNotificationCharacterID]];
        });
    }
}


- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification
{
    NSLog(@"userNotificationCenter:didActivateNotification:");
    
    // Opens the menu
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.appDelegate showMenuBarMenu];
    });
    
    // Not sure if I should dismiss the notification.
//    [_defaultCenter removeDeliveredNotification:notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

@end
