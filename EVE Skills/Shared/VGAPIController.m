//
//  VGAPIController.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 04/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGAPIController.h"
#import "VGAppDelegate.h"
#import "VGKeyInfoQuery.h"

#import "Character.h"
#import "Portrait.h"

@interface VGAPIController () {
    BOOL _initialized;
    
    // AppDelegate
    VGAppDelegate *_appDelegate;
    
    VGAPICall *_apiCall;
}

- (NSData *)callAPIWithDictionaryAsync:(NSDictionary *)dict;

@end

@implementation VGAPIController

#pragma mark -
#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        _dispatchQueue = dispatch_queue_create("com.vincentgarrigues.apiControllerQueue",
                                               DISPATCH_QUEUE_SERIAL);
        _appDelegate = (VGAppDelegate *)[NSApp delegate];
        _initialized = NO;
    }
    return self;
}

- (void)initialize
{
    // this must be called in com.vincentgarrigues.apiControllerQueue
    assert(dispatch_get_current_queue() == self.dispatchQueue);
    
    // MOC
    _apiControllerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_apiControllerContext setPersistentStoreCoordinator:_appDelegate.coreDataController.psc];
    
    // API call
    _apiCall = [[VGAPICall alloc] init];
    
    
    _initialized = YES;
}

#pragma mark -
#pragma mark - Private methods

- (NSData *)callAPIWithDictionaryAsync:(NSDictionary *)dict
{
    // send the start notification
    [[NSNotificationCenter defaultCenter] postNotificationName:APICALL_QUERY_DID_START_NOTIFICATION
                                                        object:self];
    
    // call the API synchronously with the already defined variables dictionnary and handler block
    NSError *apiCallError = nil;
    NSHTTPURLResponse *response = nil;
    NSData *data = [_apiCall callAPIWithDictionarySync:dict
                                              response:&response
                                                 error:&apiCallError];
    
    if (!data) {
        NSLog(@"Error : recieved data is nil : %@, %@", apiCallError, [apiCallError userInfo]);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [NSAlert alertWithError:apiCallError];
            [alert runModal];
        });
        return nil;
    }
    
    if ([response statusCode] != 200) {
        NSLog(@"[response statusCode] = %lu", [response statusCode]);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [NSAlert alertWithMessageText:@"Server error"
                                             defaultButton:@"OK"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"HTML status code %lu", [response statusCode]];
            [alert runModal];
        });
        return nil;
    }
    
    // send the end notification
    [[NSNotificationCenter defaultCenter] postNotificationName:APICALL_QUERY_DID_END_NOTIFICATION
                                                        object:self];
    
    return data;
}

#pragma mark -
#pragma mark - API calls

- (void)addAPIWithKeyID:(NSString *)keyID vCode:(NSString *)vCode
{
    // this must be called in com.vincentgarrigues.apiControllerQueue
    assert(dispatch_get_current_queue() == self.dispatchQueue);
    
    NSLog(@"apiKeyStart");
    
    // create the variables dictionnary
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                keyID, @"keyID",
                                vCode, @"vCode",
                                API_KEYINFO_QUERY, @"apiURL", nil];
    
    NSData *data = [self callAPIWithDictionaryAsync:dictionary];
    
    if (!data) return;
    
    // Log dispatch
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"apiCallHandler data = '%@'", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    });
    
    // creating the handling block
    void (^keyInfoQueryHandler)(NSError*);
    
    keyInfoQueryHandler = ^(NSError *error) {
        // handle the returned NSError
        if (error) {
            NSLog(@"Error keyInfoQueryHandler : %@, %@", error, [error userInfo]);
            NSAlert *alert = nil;
            
            if (data) {
                alert = [NSAlert alertWithMessageText:@"API Call error"
                                        defaultButton:@"OK"
                                      alternateButton:nil
                                          otherButton:nil
                            informativeTextWithFormat:@"%@",
                         [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
            } else {
                alert = [NSAlert alertWithError:error];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert runModal];
            });
        }
        
        // save the MOC
        [_apiControllerContext performBlock:^{
            NSError *saveError = nil;
            if (![_apiControllerContext save:&saveError]) {
                NSLog(@"Error saving context : %@, %@", saveError, [saveError userInfo]);
                NSAlert *alert = [NSAlert alertWithError:saveError];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alert runModal];
                });
            }
        }];
    };
    
    dispatch_async(self.dispatchQueue, ^{
        VGKeyInfoQuery *keyInfoQuery = [[VGKeyInfoQuery alloc] initWithData:data];
        
        keyInfoQuery.keyID = keyID;
        keyInfoQuery.vCode = vCode;
        
        [keyInfoQuery readAndInsertDataInContext:_apiControllerContext
                               completionHandler:keyInfoQueryHandler];
    });
}

- (void)addPortraitForCharacterID:(NSString *)characterID
{
    // this must be called in com.vincentgarrigues.apiControllerQueue
    assert(dispatch_get_current_queue() == self.dispatchQueue);
    
    NSLog(@"addPortraitForCharacterID:%@", characterID);
    
    // create the variables dictionnary
    NSMutableString *urlString = [[NSMutableString alloc] init];
    [urlString appendString:API_IMAGE_QUERY];
    [urlString appendFormat:@"Character/%@_512.jpg", characterID];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                urlString, @"apiURL", nil];
    
    NSData *data = [self callAPIWithDictionaryAsync:dictionary];
    
    if (!data) return;
    
    // get Character managed object
    __block Character *character = nil;
    [_apiControllerContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Character" inManagedObjectContext:_apiControllerContext];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"characterID == %@", characterID];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [_apiControllerContext executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            NSLog(@"Error while fetching Character with characterID = '%@' : %@, %@", characterID, error, [error userInfo]);
        }
        
        character = [fetchedObjects lastObject];
    }];
    
    // add character portrait to the DB
    if (character) {
        Portrait *portrait = nil;
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Portrait" inManagedObjectContext:_apiControllerContext];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"characterID == %@", character.characterID];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [_apiControllerContext executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            NSLog(@"Error while fetching portrait for characterID = '%@' : %@, %@", characterID, error, [error userInfo]);
        }
        
        // Is there a portrait in the DB, if not we create a new one
        if ([fetchedObjects count] > 0) {
            NSLog(@"Portrait already in DB");
            portrait = [fetchedObjects lastObject];
        } else {
            portrait = [NSEntityDescription insertNewObjectForEntityForName:@"Portrait"
                                                     inManagedObjectContext:self.apiControllerContext];
        }
        
        // Set image for portrait
        NSImage *image = [[NSImage alloc] initWithData:data];
        portrait.image = image;
        portrait.characterID = character.characterID;
    }
    
    // save the MOC
    [_apiControllerContext performBlockAndWait:^{
        NSError *saveError = nil;
        if (![_apiControllerContext save:&saveError]) {
            NSLog(@"Error saving context : %@, %@", saveError, [saveError userInfo]);
            NSAlert *alert = [NSAlert alertWithError:saveError];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert runModal];
            });
        }
    }];
}

@end
