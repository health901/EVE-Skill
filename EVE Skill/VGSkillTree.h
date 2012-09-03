//
//  VGSkillTree.h
//  EVE Database
//
//  Created by Vincent Garrigues on 03/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VGSkillTree : NSObject <NSXMLParserDelegate>

- (void)downloadAndGenerateSkillTree:(void (^)(NSError *error))completionHandler;

@end
