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

@interface VGAPIController () {
    BOOL _initialized;
    
    // AppDelegate
    VGAppDelegate *_appDelegate;
    
    VGAPICall *_apiCall;
}

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
#pragma mark - API calls

- (void)addAPIWithKeyID:(NSString *)keyID vCode:(NSString *)vCode
{
    // this must be called in com.vincentgarrigues.apiControllerQueue
    assert(dispatch_get_current_queue() == self.dispatchQueue);
    
    NSLog(@"apiKeyStart");
    
    // send the start notification
    [[NSNotificationCenter defaultCenter] postNotificationName:APICALL_QUERY_DID_START_NOTIFICATION
                                                        object:self];
    
    // create the variables dictionnary
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                keyID, @"keyID",
                                vCode, @"vCode",
                                API_KEYINFO_QUERY, @"apiURL", nil];
    
    // creating the handling blocks
    void (^keyInfoQueryHandler)(NSError*);
    
    keyInfoQueryHandler = ^(NSError *error) {
        // handle the returned NSError
        if (error) {
            NSLog(@"Error keyInfoQueryHandler : %@, %@", error, [error userInfo]);
            NSAlert *alert = [NSAlert alertWithError:error];
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
    
    // call the API synchronously with the already defined variables dictionnary and handler block
    NSError *apiCallError = nil;
    NSData *data = [_apiCall callAPIWithDictionarySync:dictionary
                                                 error:&apiCallError];
    
    // send the end notification
    [[NSNotificationCenter defaultCenter] postNotificationName:APICALL_QUERY_DID_END_NOTIFICATION
                                                        object:self];
        
    if (!data) {
        NSLog(@"Error : recieved data is nil : %@, %@", apiCallError, [apiCallError userInfo]);
        NSAlert *alert = [NSAlert alertWithError:apiCallError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert runModal];
        });
        return;
    }
    
    // Log dispatch
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"apiCallHandler data = '%@'", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    });
    
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
    
    // send the start notification
    [[NSNotificationCenter defaultCenter] postNotificationName:APICALL_QUERY_DID_START_NOTIFICATION
                                                        object:self];
    
    // create the variables dictionnary
    NSMutableString *urlString = [[NSMutableString alloc] init];
    [urlString appendString:API_IMAGE_QUERY];
    [urlString appendFormat:@"Character/%@_512.jpg", characterID];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                urlString, @"apiURL", nil];
    
    // call the API synchronously with the already defined variables dictionnary and handler block
    NSError *apiCallError = nil;
    NSData *data = [_apiCall callAPIWithDictionarySync:dictionary
                                                 error:&apiCallError];
    
    // send the end notification
    [[NSNotificationCenter defaultCenter] postNotificationName:APICALL_QUERY_DID_END_NOTIFICATION
                                                        object:self];
    
    // data check
    if (!data) {
        NSLog(@"Error : recieved data is nil : %@, %@", apiCallError, [apiCallError userInfo]);
        NSAlert *alert = [NSAlert alertWithError:apiCallError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert runModal];
        });
        return;
    }
    
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
    
    // set character portrait
    if (character) {
        NSImage *portrait = [[NSImage alloc] initWithData:data];
        character.image = portrait;
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
}

@end
