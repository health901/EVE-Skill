//
//  VGSkillQueueQuery.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 16/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VGSkillQueueQuery : NSObject <NSXMLParserDelegate>

@property (strong) NSString *characterID;

- (id)initWithData:(NSData *)data;

- (void)readAndInsertDataInContext:(NSManagedObjectContext *)context
                 completionHandler:(void (^)(NSError *error))completionHandler;

@end
