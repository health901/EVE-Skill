//
//  VGAPICall.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 03/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>

// API Notifications
#define APICALL_QUERY_DID_START_NOTIFICATION    @"apiCallQueryDidStartNotification"
#define APICALL_QUERY_DID_END_NOTIFICATION      @"apiCallQueryDidEndNotification"

// API URLs
#define API_KEYINFO_QUERY       @"https://api.eveonline.com/account/APIKeyInfo.xml.aspx"
#define API_SKILLQUEUE_QUERY    @"https://api.eveonline.com/char/SkillQueue.xml.aspx"
#define API_CHARACTERINFO_QUERY @"https://api.eveonline.com/eve/CharacterInfo.xml.aspx"
#define API_IMAGE_QUERY         @"http://image.eveonline.com/"

@interface VGAPICall : NSObject

@property (strong, readonly) dispatch_queue_t dispatchQueue;

// Variables: apiURL, keyID, vCode, characterID
- (void)callAPIWithDictionary:(NSDictionary *)dictionary
            completionHandler:(void (^)(NSURLResponse *urlResponse, NSData *data, NSError *error))handler;

- (NSData *)callAPIWithDictionarySync:(NSDictionary *)dictionary
                             response:(NSHTTPURLResponse **)response
                                error:(NSError **)error;

@end
