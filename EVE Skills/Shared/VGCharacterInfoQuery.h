//
//  VGCharacterInfoQuery.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 22/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Corporation.h"

@interface VGCharacterInfoQuery : NSObject <NSXMLParserDelegate>

- (id)initWithData:(NSData *)data;

- (void)readAndInsertDataInContext:(NSManagedObjectContext *)context
                 completionHandler:(void (^)(NSError *error, Corporation *corporation))completionHandler;


@end
