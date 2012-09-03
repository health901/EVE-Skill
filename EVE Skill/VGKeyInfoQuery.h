//
//  VGKeyInfoQuery.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 04/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VGKeyInfoQuery : NSObject <NSXMLParserDelegate>

@property (strong) NSString *keyID;
@property (strong) NSString *vCode;

- (id)initWithData:(NSData *)data;

- (void)readAndInsertDataInContext:(NSManagedObjectContext *)context
                 completionHandler:(void (^)(NSError *error))completionHandler;

@end
