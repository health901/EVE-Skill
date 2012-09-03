//
//  VGAPICall.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 03/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGAPICall.h"

@interface VGAPICall () {
    NSOperationQueue *_urlConnectionQueue;
}

@end

@implementation VGAPICall

#pragma mark -
#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        _dispatchQueue = dispatch_queue_create("com.vincentgarrigues.apiCallQueue",
                                               DISPATCH_QUEUE_SERIAL);
        _urlConnectionQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

#pragma mark - API Connection

- (void)callAPIWithDictionary:(NSDictionary *)dictionary
            completionHandler:(void (^)(NSURLResponse *urlResponse, NSData *data, NSError *error))handler {
    
    // Getting the apiUrl
    if (!dictionary[@"apiURL"]) {
        NSLog(@"threadedCallAPI : error, no 'apiURL' specified.");
        abort();
    }
    NSURL *url = [NSURL URLWithString:dictionary[@"apiURL"]];
    
    
    
    // setup request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    
    // set headers
    NSString *contentType = [NSString stringWithFormat:@"text/plain"];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    // POST variables
    NSMutableString *post = [[NSMutableString alloc] init];
    
    // If dictionary has more than one entry, it means there are variables
    if ([dictionary count] > 1) {
        
        // Getting all keys except 'apiUrl'
        NSArray *keys = [[dictionary keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
            return ![(NSString *)key isEqualToString:@"apiUrl"];
        }] allObjects];;
        
        for (int i = 0; i < [keys count]; i++) {
            NSString *key = keys[i];
            
            if (i > 0) {
                [post appendFormat:@"&%@=%@", key, dictionary[key]];
            } else {
                [post appendFormat:@"%@=%@", key, dictionary[key]];
            }
            
        }
    }
    
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];
    
    //NSLog(@"post : %@", post);
    
    // HTTP BODY
    [request setValue:@"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld", [postData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:_urlConnectionQueue
                           completionHandler:handler];
}

- (NSData *)callAPIWithDictionarySync:(NSDictionary *)dictionary
                             response:(NSHTTPURLResponse **)response
                                error:(NSError **)error
{
    // Getting the apiUrl
    if (!dictionary[@"apiURL"]) {
        NSLog(@"threadedCallAPI : error, no 'apiURL' specified.");
        abort();
    }
    NSURL *url = [NSURL URLWithString:dictionary[@"apiURL"]];
    
    
    
    // setup request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    
    // set headers
    NSString *contentType = [NSString stringWithFormat:@"text/plain"];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    // POST variables
    NSMutableString *post = [[NSMutableString alloc] init];
    
    // If dictionary has more than one entry, it means there are variables
    if ([dictionary count] > 1) {
        
        // Getting all keys except 'apiUrl'
        NSArray *keys = [[dictionary keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
            return ![(NSString *)key isEqualToString:@"apiUrl"];
        }] allObjects];;
        
        for (int i = 0; i < [keys count]; i++) {
            NSString *key = keys[i];
            
            if (i > 0) {
                [post appendFormat:@"&%@=%@", key, dictionary[key]];
            } else {
                [post appendFormat:@"%@=%@", key, dictionary[key]];
            }
            
        }
    }
    
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];
    
    //NSLog(@"post : %@", post);
    
    // HTTP BODY
    [request setValue:@"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld", [postData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    NSData *theData = nil;
    
    @try {
        theData = [NSURLConnection sendSynchronousRequest:request
                                        returningResponse:response
                                                    error:error];
    }
    @catch (NSException *exception) {
        NSLog(@"EXCEPTION !");
        NSLog(@"%@, %@", exception, [exception userInfo]);
    }
    @finally {
        return theData;
    }
}

@end
