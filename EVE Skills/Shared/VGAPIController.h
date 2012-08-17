//
//  VGAPIController.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 04/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VGAPICall.h"

@interface VGAPIController : NSObject

@property (nonatomic, readonly) dispatch_queue_t dispatchQueue;
@property (strong) dispatch_group_t dispatchGroup;
@property (nonatomic, readonly) NSManagedObjectContext *apiControllerContext;

// this function must be called in the controller's dispatch queue
// it creates the MOC
- (void)initialize;

// Downloads and creates/replaces the API and Character associated with keyID and vCode
- (void)addAPIWithKeyID:(NSString *)keyID vCode:(NSString *)vCode;

// Downloads and creates/replaces the Queue and QueueElement associated with characterID
- (void)addQueueWithCharacterID:(NSString *)characterID;

// Downloads and creates/replaces the Portrait associated with characterID
- (void)addPortraitForCharacterID:(NSString *)characterID;

/* 
 Downloads and creates/replaces the Queue and QueueElement for all Character
    - If enabled == YES, then only Character with enabled attribute set to YES will have their
    associated Queue and QueueElement refreshed (ie created/replaced)
    - If enabled == NO, then all Character will have their associated Queue and QueueElement
    refreshed (ie created/replaced)
 */
- (void)refreshQueueForCharacterEnabled:(BOOL)enabled;

@end
