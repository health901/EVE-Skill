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
@property (strong) dispatch_group_t portraitDispatchGroup;
@property (nonatomic, readonly) NSManagedObjectContext *apiControllerContext;

// this function must be called in the controller's dispatch queue
// it creates the MOC
- (void)initialize;

- (void)addAPIWithKeyID:(NSString *)keyID vCode:(NSString *)vCode;

- (void)addPortraitForCharacterID:(NSString *)characterID;

@end
