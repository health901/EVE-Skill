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
    
    // send the start notification
    [[NSNotificationCenter defaultCenter] postNotificationName:APICALL_QUERY_DID_START_NOTIFICATION
                                                        object:self];
    
    // create the variables dictionnary
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                keyID, @"keyID",
                                vCode, @"vCode",
                                API_KEYINFO_QUERY, @"apiURL", nil];
    
    // creating the handling blocks
    void (^apiCallHandler)(NSURLResponse*, NSData*, NSError*);
    void (^keyInfoQueryHandler)(NSError*);
    
    keyInfoQueryHandler = ^(NSError *error) {
        // TODO handle the returned NSError
        
        // save the MOC
        [_apiControllerContext performBlock:^{
            NSError *saveError = nil;
            if (![_apiControllerContext save:&saveError]) {
                NSLog(@"Error saving context : %@, %@", saveError, [saveError userInfo]);
            }
        }];
        
        // send the end notification
        [[NSNotificationCenter defaultCenter] postNotificationName:APICALL_QUERY_DID_END_NOTIFICATION
                                                            object:self];
    };
    
    apiCallHandler = ^(NSURLResponse *urlResponse,
                       NSData *data,
                       NSError *error) {        
        if (!data) {
            NSLog(@"Error : recieved data is nil : %@, %@", error, [error userInfo]);
            abort();
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
    };
    
    // call the API with the already defined variables dictionnary and handler block
    [_apiCall callAPIWithDictionary:dictionary
                  completionHandler:apiCallHandler];
}

@end
