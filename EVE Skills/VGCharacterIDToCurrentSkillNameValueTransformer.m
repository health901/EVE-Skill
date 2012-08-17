//
//  VGCharacterIDToCurrentSkillNameValueTransformer.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 16/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGCharacterIDToCurrentSkillNameValueTransformer.h"
#import "VGAppDelegate.h"
#import "Skill.h"
#import "Queue+VGEVE.h"
#import "QueueElement+VGEVE.h"

@interface VGCharacterIDToCurrentSkillNameValueTransformer () {
    // App delegate
    VGAppDelegate *_appDelegate;
    
    // Core Data
    NSManagedObjectContext *_moc;
}

- (Queue *)queueForCharacterID:(NSString *)characterID;

@end

@implementation VGCharacterIDToCurrentSkillNameValueTransformer

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
#pragma mark - Core Data

- (Queue *)queueForCharacterID:(NSString *)characterID
{
    __block Queue *_fetchedQueue = nil;
    
    [_moc performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Queue" inManagedObjectContext:_moc];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"characterID == %@", characterID];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [_moc executeFetchRequest:fetchRequest error:&error];
        
        if (fetchedObjects == nil) {
            NSLog(@"Error while fetching Queue for characterID = '%@' : %@, %@",
                  characterID, error, [error userInfo]);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [NSAlert alertWithError:error];
                [alert runModal];
            });
        }
        
        // if the queue is not empty, return it
        if ([fetchedObjects count] > 0) {
            NSLog(@"Queue with characterID = '%@' in DB", characterID);
            _fetchedQueue = [fetchedObjects lastObject];
        }
        
    }];
    
    return _fetchedQueue;
}

#pragma mark -
#pragma mark - Value transformer

- (id)transformedValue:(id)value
{
    if (!value) {
        NSLog(@"characterIDToCurrentSkillName -transformedValue: Value is nil.");
        return NULL;
    }
    
    if (![value isKindOfClass:[NSString class]]) {
        NSLog(@"characterIDToCurrentSkillName -transformedValue: Value is not an NSString but %@", [value class]);
        return NULL;
    }
    
    NSLog(@"characterIDToCurrentSkillName searching for skill queue with characterID = '%@'",
          value);
    
    // the returned string
    __block NSString *_string = NULL;
    
    Queue *queue = [self queueForCharacterID:(NSString *)value];
    
    if (!queue) {
        // There is no skill queue, we have to check it online
        NSLog(@"characterIDToCurrentSkillName no Queue in the DB for characterID = '%@'",
              value);
        
        // check if the dispatch group is nil
        if (!_appDelegate.apiController.dispatchGroup) {
            NSLog(@"Creating dispatchGroup");
            _appDelegate.apiController.dispatchGroup = dispatch_group_create();
            
            // wait in another thread for the group to finish
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"Waiting for the end of dispatchGroup...");
                dispatch_group_wait(_appDelegate.apiController.dispatchGroup,
                                    DISPATCH_TIME_FOREVER);
                NSLog(@"dispatchGroup empty !");
                _appDelegate.apiController.dispatchGroup = nil;
                
                // post the notification for the skill queue
                [[NSNotificationCenter defaultCenter] postNotificationName:SKILL_QUEUE_SHOULD_RELOAD_DATA_NOTIFICATION
                                                                    object:self];
            });
        }
        
        
        // start the download
        dispatch_group_async(_appDelegate.apiController.dispatchGroup, _appDelegate.apiController.dispatchQueue, ^{
            [_appDelegate.apiController addQueueWithCharacterID:value];
        });
    }
    
    if (queue.elements) {
        // There is a queue, we find the first element of the queue
        __block QueueElement *firstQueueElement = nil;
        [queue.elements enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            if ([((QueueElement *)obj).position intValue] == 0) {
                firstQueueElement = obj;
                *stop = YES;
            }
        }];
        
        // If there is a first element in the queue, find the associated skill
        if (firstQueueElement) {
            // Fetch the skill
            [_moc performBlockAndWait:^{
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                NSEntityDescription *entity = [NSEntityDescription entityForName:@"Skill" inManagedObjectContext:_moc];
                [fetchRequest setEntity:entity];
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"skillID == %@", firstQueueElement.skillID];
                [fetchRequest setPredicate:predicate];
                
                NSError *error = nil;
                NSArray *fetchedObjects = [_moc executeFetchRequest:fetchRequest error:&error];
                
                if (fetchedObjects == nil) {
                    NSLog(@"Error while fetching Skill with skillID = '%@' : %@, %@",
                          firstQueueElement.skillID, error, [error userInfo]);
                }
                
                if ([fetchedObjects count] > 0) {
                    _string = [NSString stringWithFormat:@"%@ %@",
                               ((Skill *)[fetchedObjects lastObject]).skillName,
                               [firstQueueElement.skillLevel stringValue]];
                } else {
                    _string = [NSString stringWithFormat:@"No skill in DB with skillID = '%@'", firstQueueElement.skillID];
                }

            }];
            
        } else {
            // There is not first element, the queue is empty
            
            _string = @"Skill queue empty";
        }
    } else {
        _string = @"Fetching...";
        
    }
    
    return _string;
}

@end
